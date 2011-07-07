//
//  MailMessageController.m
//  Journler
//
//  Created by Phil Dow on 1/12/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MailMessageController.h"
#import "JournlerApplicationDelegate.h"
#import "NSAlert+JournlerAdditions.h"

#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>

#warning convert links in emails to clickable links

static NSString *kMediabarItemComposeMessage = @"kMediabarItemComposeMessage";

@implementation MailMessageController

- (id) init 
{
	if ( self = [super init] )
	{
		[NSBundle loadNibNamed:@"MailMessageView" owner:self];
	}
	return self;
}

- (void) dealloc
{
	[emailTokenMenu release];
	[webviewFindPanel release];
	
	[objectController release];
	
	[super dealloc];
}

- (void) awakeFromNib
{
	[fromToken setBezeled:NO];
	[fromToken setBordered:NO];
	[fromToken setEditable:NO];
	
	[toToken setBezeled:NO];
	[toToken setBordered:NO];
	[toToken setEditable:NO];
	
	[super awakeFromNib];
}

#pragma mark -

- (NSString*) defaultSender
{
	return defaultSender;
}

- (void) setDefaultSender:(id)sender
{
	if ( defaultSender != sender )
	{
		[defaultSender release];
		defaultSender = [sender copyWithZone:[self zone]];
	}
}

#pragma mark -

- (BOOL) loadURL:(NSURL*)aURL 
{
	if ( ![aURL isFileURL] )
	{
		NSLog(@"%s - cannot load mail message from remote location %@", __PRETTY_FUNCTION__, aURL);
		NSBeep();
		[[NSAlert mediaError] runModal];
		return NO;
	}
	
	NSString *path = [aURL path];
	if ( ![[NSFileManager defaultManager] fileExistsAtPath:path] )
	{
		NSLog(@"%s - no message appears to exist for the specified file %@", __PRETTY_FUNCTION__, path);
		NSBeep();
		[[NSAlert mediaError] runModal];
		return NO;
	}
	
	MailMessageParser *parser = [[[MailMessageParser alloc] initWithFile:path] autorelease];
	if ( parser == nil )
	{
		NSLog(@"%s - unable to initialize parser for file at path %@", __PRETTY_FUNCTION__, path);
		NSBeep();
		[[NSAlert mediaError] runModal]; 
		return NO;
	}
	
	// grab header info
	NSString *subject = [[parser message] subject];
	NSString *from = [[[parser message] from] stringValue];
	NSArray *recipients = [[[parser message] recipients] valueForKey:@"stringValue"];
	
	NSString *dateString = nil;
	NSDate *date = [[parser message] receivedDate];
	if ( date != nil )
	{
		NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
		[formatter setDateStyle:NSDateFormatterLongStyle];
		[formatter setTimeStyle:NSDateFormatterMediumStyle];
		
		dateString = [formatter stringFromDate:date];
	}
	
	[subjectField setStringValue:( subject != nil ? subject : [NSString string] )];
	[dateField setStringValue:( dateString != nil ? dateString : [NSString string] )];
	
	[fromToken setObjectValue:( from != nil ? [NSArray arrayWithObject:from] : nil )];
	[toToken setObjectValue:( recipients != nil ? recipients : nil )];
	
	[self setDefaultSender:from];
	
	// create an html version
	if ( [parser hasHTMLBody] )
	{
		NSString *html = [parser body:YES];
		[[webView mainFrame] loadHTMLString:html baseURL:nil];
	}
	else if ( [parser hasPlainTextBody] )
	{
		NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSFont systemFontOfSize:11], NSFontAttributeName, nil];
			
		NSAttributedString *attrString = [[[NSAttributedString alloc] initWithString:[parser body:NO] attributes:attrs] autorelease];
		
		NSDictionary *docAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
			NSHTMLTextDocumentType, NSDocumentTypeDocumentAttribute, nil];
			
		NSData *htmlData = [attrString dataFromRange:NSMakeRange(0,[attrString length]) documentAttributes:docAttrs error:nil];
		NSString *html = [[[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding] autorelease];
		
		[[webView mainFrame] loadHTMLString:html baseURL:nil];
	}
	else
	{
		NSString *errorMsgPath = [[NSBundle mainBundle] pathForResource:@"MailMessageError" ofType:@"html"];
		if ( errorMsgPath != nil )
		{
			NSURL *errorMsgURL = [NSURL fileURLWithPath:errorMsgPath];
			NSURLRequest *errorMsgReqeust = [NSURLRequest requestWithURL:errorMsgURL];
			
			[[webView mainFrame] loadRequest:errorMsgReqeust];
		}
		
		NSLog(@"%s - unable to derive message body for email at path %@", __PRETTY_FUNCTION__, path);
		NSBeep(); return NO;
	}	
	
	[super loadURL:aURL];
	return YES;
}

- (IBAction) printDocument:(id)sender {
	
	NSPrintInfo *modifiedInfo = [[[NSPrintInfo sharedPrintInfo] copyWithZone:[self zone]] autorelease];
	
	[modifiedInfo setHorizontalPagination:NSFitPagination];
    [modifiedInfo setHorizontallyCentered:NO];
    [modifiedInfo setVerticallyCentered:NO];
	[[modifiedInfo dictionary] setValue:[NSNumber numberWithBool:NO] forKey:NSPrintHeaderAndFooter];

    NSRect imageableBounds = [modifiedInfo imageablePageBounds];
    NSSize paperSize = [modifiedInfo paperSize];
    if (NSWidth(imageableBounds) > paperSize.width) {
        imageableBounds.origin.x = 0;
        imageableBounds.size.width = paperSize.width;
    }
    if (NSHeight(imageableBounds) > paperSize.height) {
        imageableBounds.origin.y = 0;
        imageableBounds.size.height = paperSize.height;
    }

	[modifiedInfo setBottomMargin:NSMinY(imageableBounds)];
	[modifiedInfo setTopMargin:paperSize.height - NSMinY(imageableBounds) - NSHeight(imageableBounds)];
	[modifiedInfo setLeftMargin:NSMinX(imageableBounds)];
	[modifiedInfo setRightMargin:paperSize.width - NSMinX(imageableBounds) - NSWidth(imageableBounds)];
	
	[[NSPrintOperation printOperationWithView:[[[webView mainFrame] frameView] documentView] printInfo:modifiedInfo] runOperation];
	
	//[NSPrintInfo setSharedPrintInfo:modifiedInfo];
	//[[[[webView mainFrame] frameView] documentView] print:sender];
	//[NSPrintInfo setSharedPrintInfo:currentInfo];
}


- (void) stopContent 
{
	[webView stopLoading:self];
	[webviewFindPanel orderOut:self];
}

- (void) ownerWillClose:(NSNotification*)aNotification
{
	[webView stopLoading:self];
	[webView setFrameLoadDelegate:nil];
	[webView setUIDelegate:nil];
	
	[webviewFindPanel orderOut:self];
	
	[objectController unbind:@"contentObject"];
	[objectController setContent:nil];
}

- (void) setWindowTitleFromURL:(NSURL*)aURL
{
	// orverridden
	[[[self contentView] window] setTitle:[subjectField stringValue]];
}

#pragma mark -

- (NSResponder*) preferredResponder
{
	return webView;
}

- (void) appropriateFirstResponder:(NSWindow*)window 
{
	[window makeFirstResponder:webView];
}

#pragma mark -

- (BOOL) handlesFindCommand
{
	// retargets the find panel action because WebKit's WebView doesn't support it
	return YES;
}

- (void) performCustomFindPanelAction:(id)sender
{
	[self performWebViewFindPanelAction:sender];
}

- (IBAction)performWebViewFindPanelAction:(id)sender
{	
	if ( [sender tag] == 1 )
		[webviewFindPanel makeKeyAndOrderFront:sender];
	else if ( [sender tag] == 2 || [sender tag] == 3 )
	{
		BOOL next = ( [sender tag] == 2 ? YES : NO );
		NSString *query = [webviewFindQueryField stringValue];
		
		if ( ![webView searchFor:query direction:next 
				caseSensitive:![[NSUserDefaults standardUserDefaults] boolForKey:@"WebViewFindIgnoreCase"] wrap:YES] )
			NSBeep();
	}
	else
		NSBeep();
}

- (BOOL) highlightString:(NSString*)aString
{
	if ( aString == nil || [aString length] == 0 )
		return NO;
	
	// put the string on the find pasteboard
	NSPasteboard *findBoard = [NSPasteboard pasteboardWithName:NSFindPboard];
	[findBoard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
	[findBoard setString:aString forType:NSStringPboardType];
	
	[self setSearchString:aString];
	
	NSString *aComponent;
	NSEnumerator *enumerator = [[aString componentsSeparatedByString:@" "] objectEnumerator];
	
	while ( aComponent = [enumerator nextObject] )
	{
		// find the occurrence of this string and break if it's available - thus iterating through all the strings
		if ( [webView searchFor:aComponent direction:YES caseSensitive:NO wrap:YES] )
		{
			[webviewFindQueryField setStringValue:aString];
			break;
		}
	}
	
	if ( [[webviewFindQueryField stringValue] length] == 0 )
		[webviewFindQueryField setStringValue:aString];
	
	return YES;
}


#pragma mark -

- (BOOL) handlesTextSizeCommand
{
	return YES;
}

- (void) performCustomTextSizeAction:(id)sender
{
	if ( [sender tag] == 3 )
		[webView makeTextLarger:sender];
	else if ( [sender tag] == 4 )
		[webView makeTextSmaller:sender];
	else if ( [sender tag] == 99 )
		[webView setTextSizeMultiplier:1.0];
}

#pragma mark -

- (IBAction)sendEmailMessage:(id)sender
{
	NSString *parsedAddress = nil;
	NSString *toAddress = [sender representedObject];
	if ( toAddress == nil )
	{
		NSLog(@"%s - no represented object associated with sender", __PRETTY_FUNCTION__);
		NSBeep(); return;
	}
	
	if ( [toAddress rangeOfString:@"<"].location != NSNotFound )
	{
		// parse the string
		NSScanner *scanner = [NSScanner scannerWithString:toAddress];
		[scanner scanUpToString:@"<" intoString:nil];
		[scanner scanString:@"<" intoString:nil];
		[scanner scanUpToString:@">" intoString:&parsedAddress];
		
		if ( parsedAddress == nil )
		{
			NSLog(@"%s - unable to parse provided email address %@", __PRETTY_FUNCTION__, toAddress);
			NSBeep(); return;
		}
	}
	else 
	{
		parsedAddress = toAddress;
	}
	
	//if ( ![JUtility sendRichMail:[[[NSAttributedString alloc] initWithString:[NSString string] attributes:nil] autorelease] 
	//		to:parsedAddress subject:[NSString string] isMIME:NO withNSMail:NO] )
		
	if ( ![JournlerApplicationDelegate sendRichMail:[[[NSAttributedString alloc] initWithString:[NSString string] attributes:nil] autorelease] 
			to:parsedAddress subject:[NSString string] isMIME:NO withNSMail:NO] )
	{
		NSLog(@"%s - unable to send email message", __PRETTY_FUNCTION__);
		NSBeep(); return;
	}
}

- (IBAction) sendEmailToDefaultSender:(id)sender
{
	NSString *parsedAddress = nil;
	NSString *toAddress = [self defaultSender];
	if ( toAddress == nil )
	{
		NSLog(@"%s - no represented object associated with sender", __PRETTY_FUNCTION__);
		NSBeep(); return;
	}
	
	if ( [toAddress rangeOfString:@"<"].location != NSNotFound )
	{
		// parse the string
		NSScanner *scanner = [NSScanner scannerWithString:toAddress];
		[scanner scanUpToString:@"<" intoString:nil];
		[scanner scanString:@"<" intoString:nil];
		[scanner scanUpToString:@">" intoString:&parsedAddress];
		
		if ( parsedAddress == nil )
		{
			NSLog(@"%s - unable to parse provided email address %@", __PRETTY_FUNCTION__, toAddress);
			NSBeep(); return;
		}
	}
	else 
	{
		parsedAddress = toAddress;
	}
	
	//if ( ![JUtility sendRichMail:[[[NSAttributedString alloc] initWithString:[NSString string] attributes:nil] autorelease] 
	//		to:parsedAddress subject:[NSString string] isMIME:NO withNSMail:NO] )
	
	if ( ![JournlerApplicationDelegate sendRichMail:[[[NSAttributedString alloc] initWithString:[NSString string] attributes:nil] autorelease] 
			to:parsedAddress subject:[NSString string] isMIME:NO withNSMail:NO] )
	{
		NSLog(@"%s - unable to send email message", __PRETTY_FUNCTION__);
		NSBeep(); return;
	}
}

#pragma mark -
#pragma mark WebView Delegation

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame 
{
	if (frame != [sender mainFrame])
		return;
	
	if ( [self searchString] != nil )
		[self highlightString:[self searchString]];
}

- (NSArray *)webView:(WebView *)sender 
		contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems {

	// copy our additional items to the default items
	NSMutableArray *items = [[defaultMenuItems mutableCopyWithZone:[self zone]] autorelease];
	
	if ( [[element objectForKey:WebElementIsSelectedKey] boolValue] 
		&& [[[self representedObject] className] isEqualToString:@"JournlerResource"]
		&& [[self delegate] respondsToSelector:@selector(contentController:showLexiconSelection:term:)] )
	{
		// we have a text selection
		NSString *selection = [[sender selectedDOMRange] toString];
		
		if ( [selection rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location == NSNotFound )
		{
			NSMenu *lexiconMenu = [[[NSMenu alloc] initWithTitle:NSLocalizedString(@"menuitem lexicon", @"")] autorelease];
			[lexiconMenu setDelegate:[self valueForKeyPath:@"representedObject.journal.indexServer"]];
			
			NSMenuItem *lexiconMenuItem = [[[NSMenuItem alloc] 
					initWithTitle:NSLocalizedString(@"menuitem lexicon", @"") 
					action:nil 
					keyEquivalent:@""] autorelease];
			
			[lexiconMenuItem setTag:10746];
			[lexiconMenuItem setTarget:self];
			[lexiconMenuItem setAction:@selector(_showObjectFromLexicon:)];
			[lexiconMenuItem setRepresentedObject:selection];
			
			[lexiconMenuItem setSubmenu:lexiconMenu];
			[items addObject:lexiconMenuItem];
		}
	}
	
	return items;
}

- (IBAction) _showObjectFromLexicon:(id)sender
{
	id anObject = [sender representedObject];
	
	// modifiers should support opening the item in windows, tabs, etc
	// the item should be opened and the terms highlighted and located
	
	if ( anObject == nil || ![[self delegate] respondsToSelector:@selector(contentController:showLexiconSelection:term:)] )
	{
		NSBeep();
	}
	else
	{
		[[self delegate] contentController:self showLexiconSelection:anObject 
		term:[self valueForKeyPath:@"representedObject.journal.indexServer.lexiconMenuRepresentedTerm"]];
	}
}

#pragma mark -
#pragma mark Token Field Delegation

- (BOOL)tokenField:(NSTokenField *)tokenField hasMenuForRepresentedObject:(id)anRepresentedObject
{
	return YES;
}

- (NSMenu *)tokenField:(NSTokenField *)tokenField menuForRepresentedObject:(id)anRepresentedObject
{
	[emailMenuItem setRepresentedObject:anRepresentedObject];
	return emailTokenMenu;
}

- (NSTokenStyle)tokenField:(NSTokenField *)tokenField styleForRepresentedObject:(id)anRepresentedObject
{
	return NSDefaultTokenStyle;
}

#pragma mark -
#pragma mark The Media Bar

- (BOOL) canCustomizeMediabar:(PDMediaBar*)aMediabar
{
	return YES;
}

- (NSImage*) defaultOpenWithFinderImage:(PDMediaBar*)aMediabar
{
	return BundledImageWithName(@"EmailBarSmall.png", @"com.sprouted.interface");
}

- (NSArray*) mediabarDefaultItemIdentifiers:(PDMediaBar *)mediabar
{
	return [NSArray arrayWithObjects:PDMediaBarItemGetInfo, PDMediabarItemShowInFinder, 
	PDMediabarItemOpenWithFinder, kMediabarItemComposeMessage, nil];
}

- (PDMediabarItem*) mediabar:(PDMediaBar *)mediabar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoMediabar:(BOOL)flag
{
	PDMediabarItem *anItem = nil;
	NSBundle *sproutedInterfaceBundle = [NSBundle bundleWithIdentifier:@"com.sprouted.interface"];
	
	if ( [itemIdentifier isEqualToString:kMediabarItemComposeMessage] )
	{
		anItem = [[[PDMediabarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
		
		[anItem setTitle:NSLocalizedStringFromTableInBundle(@"mail message compose title",@"Mediabar",sproutedInterfaceBundle,@"")];
		[anItem setToolTip:NSLocalizedStringFromTableInBundle(@"mail message compose tip",@"Mediabar",sproutedInterfaceBundle,@"")];
		
		NSImage *theImage = [[[NSImage alloc] initWithContentsOfFile:[sproutedInterfaceBundle pathForImageResource:@"ComposeMailBarSmall.png"]] autorelease];
		[anItem setImage:theImage];
		
		[anItem setTag:0];
		[anItem setTypeIdentifier:[NSNumber numberWithInt:kMenubarItemDefault]];
		
		[anItem setTarget:self];
		[anItem setAction:@selector(sendEmailToDefaultSender:)];
		
	}
	else
	{
		// call super's implementation to get custom support for a number of our items
		anItem = [super mediabar:mediabar itemForItemIdentifier:itemIdentifier willBeInsertedIntoMediabar:flag];
	}
	
	return anItem;
}

@end
