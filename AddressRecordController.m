#import "AddressRecordController.h"
#import "Definitions.h"

//#import "JUtility.h"
#import "JournlerApplicationDelegate.h"

#import "NSAlert+JournlerAdditions.h"
#import "JournlerMediaViewer.h"
#import "PDPersonViewer.h"
#import "PDPersonPropertyField.h"

#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>
/*
#import "ABRecord_PDAdditions.h"
#import "TransparentWindow.h"
#import "RoundedViewWhiteText.h"
#import "JournlerGradientView.h"
#import "AppleScriptAlert.h"
#import "PDMediaBar.h"
#import "PDMediabarItem.h"
*/

static NSString *kMediabarItemOpenInAddressBook = @"kMediabarItemOpenInAddressBook";
static NSString *kMediabarItemBeginEmail = @"kMediabarItemBeginEmail";
static NSString *kMediabarItemOpenHomepage = @"kMediabarItemOpenHomepage";

@implementation AddressRecordController

- (id) init
{
	if ( self = [super init] )
	{
		[NSBundle loadNibNamed:@"AddressRecordView" owner:self];
	}
	
	return self;
}

- (void) awakeFromNib
{
	[personViewer setTarget:self];
	[personViewer setAction:@selector(showFieldMenu:)];
	
	[super awakeFromNib];

}

- (void) dealloc 
{
	[phoneMenu release];
	[emailMenu release];
	[websiteMenu release];
	[addressMenu release];
	
	[defaultEmail release];
	[defaultHomepage release];
	
	[objectController release];
	
	[super dealloc];
}

#pragma mark -

- (BOOL) loadURL:(NSURL*)aURL 
{
	
	NSString *uid = [aURL absoluteString];
	ABPerson *aPerson = (ABPerson*)[[ABAddressBook sharedAddressBook] recordForUniqueId:uid];
	
	if ( aPerson == nil ) {
		NSLog(@"AddressRecordController updateContent - Unable to derive record from uid %@", uid);
		NSBeep();
		[[NSAlert mediaError] runModal];
		return NO;
	}
	
	// use the record to populate my various fields
	[personViewer setPerson:aPerson];
	
	[self setPerson:aPerson];
	[self setDefaultEmail:[aPerson emailAddress]];
	[self setDefaultHomepage:[aPerson website]];
	
	[super loadURL:aURL];
	return YES;
}

- (IBAction) printDocument:(id)sender {
	
	NSPrintingOrientation orientation = NSPortraitOrientation;
	NSPrintInfo *modifiedInfo = [[[NSPrintInfo sharedPrintInfo] copyWithZone:[self zone]] autorelease];
	
	[modifiedInfo setOrientation:orientation];
	
	[modifiedInfo setHorizontalPagination:NSFitPagination];
	[modifiedInfo setVerticalPagination:NSAutoPagination];
    [modifiedInfo setHorizontallyCentered:NO];
    [modifiedInfo setVerticallyCentered:NO];
	[[modifiedInfo dictionary] setValue:[NSNumber numberWithBool:NO] forKey:NSPrintHeaderAndFooter];
	
	//should give me the width and height
	int width = [modifiedInfo paperSize].width - ( [modifiedInfo rightMargin] + [modifiedInfo leftMargin] );
	int height = [modifiedInfo paperSize].height - ( [modifiedInfo topMargin] + [modifiedInfo bottomMargin] );
	
	PDPersonViewer *printViewer = [[[PDPersonViewer alloc] initWithFrame:NSMakeRect(0,0,width,height)] autorelease];
	[printViewer setPerson:[self person]];
	
	[[NSPrintOperation printOperationWithView:printViewer printInfo:modifiedInfo] runOperation];

}

- (IBAction) exportSelection:(id)sender
{
	// export the vcf representation of the data
	
	NSString *uid = [[self URL] absoluteString];
	ABPerson *aPerson = (ABPerson*)[[ABAddressBook sharedAddressBook] recordForUniqueId:uid];
	
	if ( aPerson == nil )
	{
		NSBeep();
		NSLog(@"%@ %s - unable to get address record for unique id", [self className], _cmd, uid);
		return;
	}
	
	NSData *vcfData = [aPerson vCardRepresentation];
	if ( vcfData == nil )
	{
		NSBeep();
		NSLog(@"%@ %s - unable to get vcf data from address record with uinque id", [self className], _cmd, uid);
		return;
	}
	
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setRequiredFileType:@"vcf"];
	[savePanel setCanSelectHiddenExtension:YES];

	if ( [savePanel runModalForDirectory:nil file:[aPerson fullname]] == NSOKButton )
	{
		NSError *writeError;
		NSString *filename = [savePanel filename];
		
		if ( ![vcfData writeToFile:filename options:NSAtomicWrite error:&writeError] )
		{
			NSBeep();
			[NSApp presentError:writeError];
			//[[NSAlert alertWithError:writeError] beginSheetModalForWindow:[[self contentView] window] 
			//		modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
		}
		else
		{
			NSDictionary *fileAttributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:[savePanel isExtensionHidden]] forKey:NSFileExtensionHidden];
			[[NSFileManager defaultManager] changeFileAttributes:fileAttributes atPath:[savePanel filename]];
		}
	}
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[[alert window] orderOut:self];
}

- (void) ownerWillClose:(NSNotification*)aNotification
{
	[objectController unbind:@"contentObject"];
	[objectController setContent:nil];
}

- (void) setWindowTitleFromURL:(NSURL*)aURL
{
	// orverridden
	ABPerson *aPerson = [personViewer person];
	if ( aPerson != nil ) [[[self contentView] window] setTitle:[aPerson fullname]];
}

- (NSResponder*) preferredResponder
{
	return personViewer;
}

- (void) appropriateFirstResponder:(NSWindow*)window 
{
	[window makeFirstResponder:personViewer];
}

#pragma mark -

- (ABPerson*) person
{
	return person;
}

- (void) setPerson:(ABPerson*)aPerson
{
	if ( person != aPerson )
	{
		[person release];
		person = [aPerson retain];
	}
}

- (NSString*) defaultEmail
{
	return defaultEmail;
}

- (void) setDefaultEmail:(NSString*)aString
{
	if ( defaultEmail != aString )
	{
		[defaultEmail release];
		defaultEmail = [aString copyWithZone:[self zone]];
	}
}

- (NSString*) defaultHomepage
{
	return defaultHomepage;
}

- (void) setDefaultHomepage:(NSString*)aString
{
	if ( defaultHomepage != aString )
	{
		[defaultHomepage release];
		defaultHomepage = [aString copyWithZone:[self zone]];
	}
}

#pragma mark -

- (IBAction) showFieldMenu:(id)sender 
{	
	// having the person viewer's target pop the menu allows it to customize the menu
	// pass the property field's content value as the menu item's represented object to ensure it gets through
	
	NSMenu *popping = nil;
	NSString *property = [sender property];
	NSString *content = [sender content];
	
	if ( [property isEqualToString:kABPhoneProperty] )
		popping = phoneMenu;
		
	else if ( [property isEqualToString:kABEmailProperty] )
		popping = emailMenu;
		
	else if ( [property isEqualToString:kABAddressProperty] )
		popping = addressMenu;
	
	else if ( [property isEqualToString:kABURLsProperty] )
		popping = websiteMenu;
		
	if ( popping != nil )
	{
		[[popping itemArray] makeObjectsPerformSelector:@selector(setRepresentedObject:) withObject:content];
		[NSMenu popUpContextMenu:popping withEvent:[sender menuEvent] forView:personViewer];
	}
}

#pragma mark -

- (IBAction) openRecordInNewWindow:(id)sender 
{
	JournlerMediaViewer *mediaViewer = [[[JournlerMediaViewer alloc] initWithURL:[self URL] uti:(NSString*)kUTTypePDF] autorelease];
	if ( mediaViewer == nil )
	{
		NSLog(@"%@ %s - problem allocating media viewer for url %@", [self className], _cmd, [self URL]);
		[[NSWorkspace sharedWorkspace] openURL:[self URL]];
	}
	else
	{
		[mediaViewer setRepresentedObject:[self representedObject]];
		[mediaViewer showWindow:self];
	}
}

- (IBAction) openRecordInAddressBook:(id)sender 
{
	NSString *uid = [[self URL] absoluteString];
	ABRecord *record = [[ABAddressBook sharedAddressBook] recordForUniqueId:uid];
	
	if ( record == nil ) 
	{
		NSLog(@"AddressRecordController openRecordInAddressBook: - Unable to derive record from uid %@", uid);
		NSBeep();
		return;
	}
	
	ABPeoplePickerView *peoplePicker = [[[ABPeoplePickerView alloc] initWithFrame:NSMakeRect(0,0,100,100)] autorelease];
	[peoplePicker selectRecord:record byExtendingSelection:NO];
	[peoplePicker selectInAddressBook:self];
}

#pragma mark -

- (IBAction) viewNumberWithLargeType:(id)sender {
	
	NSString *content = [sender representedObject];
	
	TransparentWindow *win = [[TransparentWindow alloc] init]; // the window will release itself when closed
	RoundedViewWhiteText *view = [[[RoundedViewWhiteText alloc] initWithFrame:NSMakeRect(0,0,100,100)] autorelease];
	
	[view setTitle:content];
	
	[win setClosesOnEvent:YES];
	[win setContentView:view];
	[win fillScreenHorizontallyAndCenter];
	[win makeKeyAndOrderFront:self];
}

- (IBAction) callWithSkype:(id)sender 
{
	static NSString *scriptFormat = @"tell application \"Skype\"\nsend command \"CALL %@\" script name \"Untitled\"\nend tell";
	
	NSString *content = [sender representedObject];
	NSMutableString *number = [[content mutableCopyWithZone:[self zone]] autorelease];
	[number replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:NSMakeRange(0,[number length])];
	
	NSString *script_source = [NSString stringWithFormat:scriptFormat,number];
	
	NSDictionary *error_dic;
	NSAppleScript *apple_script = [[NSAppleScript alloc] initWithSource:script_source];
	if ( !apple_script ) 
	{
		NSLog(@"AddressRecordController callWithSkype: unable to initialize script from source %@", script_source);
		
		AppleScriptAlert *scriptAlert = [[[AppleScriptAlert alloc] initWithSource:script_source error:nil] autorelease];
			
		NSBeep();
		[scriptAlert showWindow:self];
		
		return;
	}
	
	if ( ![apple_script compileAndReturnError:&error_dic] ) 
	{
		NSLog(@"AddressRecordController callWithSkype: error compiling script %@", [error_dic description]);
		
		id theSource = [apple_script richTextSource];
		if ( theSource == nil ) theSource = [apple_script source];
		AppleScriptAlert *scriptAlert = [[[AppleScriptAlert alloc] initWithSource:theSource error:error_dic] autorelease];
			
		NSBeep();
		[scriptAlert showWindow:self];
		
		return;
	}
	
	NSAppleEventDescriptor *script_result = [apple_script executeAndReturnError:&error_dic];
	if ( script_result == nil && [[error_dic objectForKey:NSAppleScriptErrorNumber] intValue] != kScriptWasCancelledError )
	{
		NSLog(@"AddressRecordController callWithSkype: error executing script %@", [error_dic description]);
		
		id theSource = [apple_script richTextSource];
		if ( theSource == nil ) theSource = [apple_script source];
		AppleScriptAlert *scriptAlert = [[[AppleScriptAlert alloc] initWithSource:theSource error:error_dic] autorelease];
			
		NSBeep();
		[scriptAlert showWindow:self];
		
		return;
	}
}

#pragma mark -

- (IBAction) sendEmail:(id)sender 
{
	NSString *content = [sender representedObject];
	//[JUtility sendRichMail:[[[NSAttributedString alloc] initWithString:@""] autorelease] to:content subject:@"" isMIME:NO withNSMail:NO];
	[JournlerApplicationDelegate sendRichMail:[[[NSAttributedString alloc] initWithString:@""] autorelease] to:content subject:@"" isMIME:NO withNSMail:NO];
}

- (IBAction) searchEmailInSpotlight:(id)sender 
{
	OSStatus resultCode;
	NSString *content = [sender representedObject];
	resultCode = HISearchWindowShow((CFStringRef)content,kNilOptions);
	
	if ( resultCode != noErr ) 
	{
		NSBeep();
		NSLog(@"AddressRecordController searchEmailInSpotlight: unable to bring up Spotlight interface");
	}
}

#pragma mark -

- (IBAction) showInFinder:(id)sender 
{
	[self openRecordInAddressBook:sender];
}

- (IBAction) openInFinder:(id)sender 
{
	[self openRecordInAddressBook:sender];
}

- (IBAction) sendMailToDefaultAddress:(id)sender
{
	NSString *content = [self defaultEmail];
	if ( content == nil )
	{
		NSBeep(); return;
	}
	
	//[JUtility sendRichMail:[[[NSAttributedString alloc] initWithString:@""] autorelease] to:content subject:@"" isMIME:NO withNSMail:NO];
	[JournlerApplicationDelegate sendRichMail:[[[NSAttributedString alloc] initWithString:@""] autorelease] to:content subject:@"" isMIME:NO withNSMail:NO];
}

- (IBAction) browseDefaultHomepage:(id)sender
{
	NSString *content = [self defaultHomepage];
	if ( content == nil )
	{
		NSBeep(); return;
	}
	
	NSURL *url = [NSURL URLWithString:content];
	
	if ( GetCurrentKeyModifiers() & cmdKey )
	{
		// open it in a new ...
	}
	else
	{
		if ( [self delegate] != nil && [[self delegate] respondsToSelector:@selector(addressRecordController:displayURL:)] )
			[[self delegate] addressRecordController:self displayURL:url];
		else
			NSBeep();
	}
	
	/*
	JournlerMediaViewer *new_viewer = [[JournlerMediaViewer alloc] initWithURL:url];
	if ( !new_viewer ) 
	{
		NSBeep();
		[[NSAlert mediaUnreadable] runModal];
		return;
	}
	
	[new_viewer setRepresentedObject:[self representedObject]];
	[new_viewer showWindow:self];
	[new_viewer release];
	
	[[NSWorkspace sharedWorkspace] openURL:url];
	*/
}


#pragma mark -

- (IBAction) openURL:(id)sender 
{
	NSString *content = [sender representedObject];
	NSURL *url = [NSURL URLWithString:content];
	
	if ( [self delegate] != nil && [[self delegate] respondsToSelector:@selector(addressRecordController:displayURL:)] )
		[[self delegate] addressRecordController:self displayURL:url];
}

- (IBAction) openURLInWindow:(id)sender {
		
	NSString *content = [sender representedObject];
	NSURL *url = [NSURL URLWithString:content];
	
	JournlerMediaViewer *new_viewer = [[JournlerMediaViewer alloc] initWithURL:url uti:(NSString*)kUTTypeURL];
	if ( !new_viewer ) 
	{
		NSBeep();
		[[NSAlert mediaUnreadable] runModal];
		return;
	}
	
	[new_viewer showWindow:self];
	[new_viewer release];
}

- (IBAction) openURLInFinder:(id)sender 
{
	NSString *content = [sender representedObject];
	NSURL *url = [NSURL URLWithString:content];
	
	[[NSWorkspace sharedWorkspace] openURL:url];
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
	return [NSArray arrayWithObjects:PDMediaBarItemGetInfo, kMediabarItemOpenInAddressBook, 
	kMediabarItemBeginEmail, kMediabarItemOpenHomepage, nil];
}

- (PDMediabarItem*) mediabar:(PDMediaBar *)mediabar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoMediabar:(BOOL)flag
{
	PDMediabarItem *anItem = nil;
	NSBundle *sproutedInterfaceBundle = [NSBundle bundleWithIdentifier:@"com.sprouted.interface"];
	
	if ( [itemIdentifier isEqualToString:kMediabarItemOpenInAddressBook] )
	{
		anItem = [[[PDMediabarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];

		[anItem setTitle:NSLocalizedStringFromTableInBundle(@"address record show title",@"Mediabar",sproutedInterfaceBundle,@"")];
		[anItem setToolTip:NSLocalizedStringFromTableInBundle(@"address record show tip",@"Mediabar",sproutedInterfaceBundle,@"")];
		[anItem setTag:0];
		[anItem setTypeIdentifier:[NSNumber numberWithInt:kMenubarItemDefault]];
		
		NSImage *theImage = BundledImageWithName(@"ABBarSmall.png", @"com.sprouted.interface");
		[anItem setImage:theImage];
		
		[anItem setTarget:self];
		[anItem setAction:@selector(openRecordInAddressBook:)];
	}
	
	else if ( [itemIdentifier isEqualToString:kMediabarItemBeginEmail] )
	{
		anItem = [[[PDMediabarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
		
		[anItem setTitle:NSLocalizedStringFromTableInBundle(@"address record email title",@"Mediabar",sproutedInterfaceBundle,@"")];
		[anItem setToolTip:NSLocalizedStringFromTableInBundle(@"address record email tip",@"Mediabar",sproutedInterfaceBundle,@"")];
		[anItem setTag:1];
		[anItem setTypeIdentifier:[NSNumber numberWithInt:kMenubarItemDefault]];
		
		NSImage *theImage = BundledImageWithName(@"ComposeMailBarSmall.png", @"com.sprouted.interface");
		[anItem setImage:theImage];
		
		[anItem setTarget:self];
		[anItem setAction:@selector(sendMailToDefaultAddress:)];
	}

	else if ( [itemIdentifier isEqualToString:kMediabarItemOpenHomepage] )
	{
		anItem = [[[PDMediabarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
		
		[anItem setTitle:NSLocalizedStringFromTableInBundle(@"address record browse title",@"Mediabar",sproutedInterfaceBundle,@"")];
		[anItem setToolTip:NSLocalizedStringFromTableInBundle(@"address record browse tip",@"Mediabar",sproutedInterfaceBundle,@"")];
		[anItem setTag:2];
		[anItem setTypeIdentifier:[NSNumber numberWithInt:kMenubarItemDefault]];
		
		NSImage *theImage = BundledImageWithName(@"SafariBarSmall.png", @"com.sprouted.interface");
		[anItem setImage:theImage];
		
		[anItem setTarget:self];
		[anItem setAction:@selector(browseDefaultHomepage:)];
	}

	
	else
	{
		// call super's implementation to get custom support for a number of our items
		anItem = [super mediabar:mediabar itemForItemIdentifier:itemIdentifier willBeInsertedIntoMediabar:flag];
	}
	
	return anItem;
}

@end
