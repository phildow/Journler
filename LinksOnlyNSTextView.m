#import "LinksOnlyNSTextView.h"

#import "JournlerApplicationDelegate.h"
#import "Definitions.h"

#import "JournlerJournal.h"
#import "JournlerEntry.h"
#import "JournlerJournal.h"
#import "JournlerResource.h"
#import "JournlerCollection.h"
#import "JournlerSearchManager.h"
#import "JournlerIndexServer.h"
#import "IndexNode.h"

#import "PDStylesBar.h"

#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>

#import "NSURL+JournlerAdditions.h"
#import "NSAttributedString+JournlerAdditions.h"
#import "NSAlert+JournlerAdditions.h"

static NSString *selectionIDsSource = @"tell application \"Mail\"\nset mailSelection to the selection\nset allIDs to {}\nrepeat with aMail in mailSelection\nset allIDs to allIDs & {{the id of aMail, the subject of aMail}}\nend repeat\nreturn allIDs\nend tell";
static NSString *mailSelectionPathInfoSource = @"tell application \"Mail\"\nset theMessages to {}\nset selectedMessages to the selection\nrepeat with aMail in selectedMessages\nif exists (name of account of mailbox of aMail) then\nset aRecord to {the id of aMail, subject of aMail, name of mailbox of aMail, account directory of account of mailbox of aMail}\nelse\nset aRecord to {the id of aMail, subject of aMail, name of mailbox of aMail}\nend if\nset theMessages to theMessages & {aRecord}\nend repeat\nreturn theMessages\nend tell";


@implementation LinksOnlyNSTextView

- (void) awakeFromNib 
{	
	NSLog(@"%s", __PRETTY_FUNCTION__);
	[self doSetup];
}

- (void) doSetup
{
	inFullScreen = NO;
	
	// fix the linked text attributes - rdar://4394344 rdar://4401697
	NSMutableDictionary *linkAttributes = [[[self linkTextAttributes] mutableCopyWithZone:[self zone]] autorelease];
	if ( linkAttributes == nil ) linkAttributes = [NSMutableDictionary dictionary];
	[linkAttributes setObject:[NSCursor pointingHandCursor] forKey:NSCursorAttributeName];
	[self setLinkTextAttributes:linkAttributes];
	
	//give us some space
	[self setTextContainerInset:NSMakeSize(3,3)];
	
	//register acceptable drag types
	[self handleRegisterDragTypes];
		
	//initialize the space string and url object - why I can't do this in init I have no idea
	_space = [[NSAttributedString alloc] initWithString:@" "];
	lastURL = [[NSURL URLWithString:@""] retain];
	
	_lastScale = 1.0;
	modifierFlags = 0;
	
	dragProducedEntry = NO;
	
	// establish a few bindings to user defaults
	[self bind:@"continuousSpellCheckingEnabled" 
			toObject:[NSUserDefaultsController sharedUserDefaultsController] 
			withKeyPath:@"values.EntryTextEnableSpellChecking" 
			options:[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithBool:YES], NSNullPlaceholderBindingOption, nil]];
	
	[self bind:@"continuouslyPostsSelectionNotification" 
			toObject:[NSUserDefaultsController sharedUserDefaultsController] 
			withKeyPath:@"values.EntryTextShowWordCount" 
			options:[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithBool:YES], NSNullPlaceholderBindingOption, nil]];
	
	[self bind:@"linkColor"	
			toObject:[NSUserDefaultsController sharedUserDefaultsController]
			withKeyPath:@"values.EntryTextLinkColor" 
			options:[NSDictionary dictionaryWithObjectsAndKeys:
					@"NSUnarchiveFromData", NSValueTransformerNameBindingOption,
					[NSColor blueColor], NSNullPlaceholderBindingOption, nil]];
			
	[self bind:@"linkUnderlined" 
			toObject:[NSUserDefaultsController sharedUserDefaultsController]
			withKeyPath:@"values.EntryTextLinkUnderlined" 
			options:[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithBool:YES], NSNullPlaceholderBindingOption, nil]];
			
	[self bind:@"horizontalInset" 
			toObject:[NSUserDefaultsController sharedUserDefaultsController]
			withKeyPath:@"values.EntryTextHorizontalInset" 
			options:[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInteger:0], NSNullPlaceholderBindingOption, nil]];
			
	[self bind:@"horizontalInsetFullscreen" 
			toObject:[NSUserDefaultsController sharedUserDefaultsController]
			withKeyPath:@"values.EntryTextHorizontalInsetFullscreen" 
			options:[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInteger:100], NSNullPlaceholderBindingOption, nil]];
	
	// reset the cursor rects for this view
	[[self window] invalidateCursorRectsForView:self];
}

- (void) ownerWillClose:(NSNotification*)aNotification
{
	[self unbind:@"continuousSpellCheckingEnabled"];
	[self unbind:@"continuouslyPostsSelectionNotification"];
	[self unbind:@"linkColor"];
	[self unbind:@"linkUnderlined"];
	[self unbind:@"horizontalInset"];
	[self unbind:@"horizontalInsetFullscreen"];
}

- (void) handleRegisterDragTypes
{
	//static NSString *kAppleVCardPasteboardType = @"Apple VCard pasteboard type";
	
	[self registerForDraggedTypes:[NSArray arrayWithObjects:
			kABPeopleUIDsPboardType, kMailMessagePboardType, 
			NSFilenamesPboardType, WebURLsWithTitlesPboardType, 
			NSURLPboardType, NSRTFDPboardType, 
			NSRTFPboardType, NSStringPboardType, 
			NSTIFFPboardType, NSPICTPboardType,
			PDFolderIDPboardType, PDEntryIDPboardType, 
			PDResourceIDPboardType, nil]];
}

- (void) handleDeregisterDragTypes 
{
	[self unregisterDraggedTypes];
}

-(void) dealloc 
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	[[self undoManager] removeAllActions];
	[self unregisterDraggedTypes];
	
	[_space release];
	[lastURL release];
	[_entry release];
	
	[super dealloc];
	
	#ifdef __DEBUG__
	NSLog(@"textview dealloc - ending");
	#endif
}

#pragma mark -

- (JournlerEntry*) entry 
{ 
	return _entry; 
}

- (void) setEntry:(JournlerEntry*)anEntry 
{
	if ( _entry != anEntry )
	{
		[_entry releaseContent];
		[_entry release];
		
		_entry = [anEntry retain];
		[_entry retainContent];
		
		if ( [[_entry attributedContent] length] == 0 )
		{
			// if the entry doesn't have any content, reset the typing attriubutes to default
			[self setFont:[[JournlerEntry defaultTextAttributes] objectForKey:NSFontAttributeName]];
			[self setTextColor:[[JournlerEntry defaultTextAttributes] objectForKey:NSForegroundColorAttributeName]];
			[self setTypingAttributes:[JournlerEntry defaultTextAttributes]];
		}
	}
}

- (float) lastScale 
{ 
	return _lastScale; 
}

- (void) setLastScale:(float)scaleValue 
{
	_lastScale = scaleValue;
}

- (NSUInteger) modifierFlags
{
	return modifierFlags;
}

- (void) setModifierFlags:(NSUInteger)flags
{
	modifierFlags = flags;
}

- (BOOL) continuouslyPostsSelectionNotification
{
	return continuouslyPostsSelectionNotification;
}

- (void) setContinuouslyPostsSelectionNotification:(BOOL)continuous
{
	continuouslyPostsSelectionNotification = continuous;
}

- (NSColor*) linkColor
{
	return [[self linkTextAttributes] objectForKey:NSForegroundColorAttributeName];
}

- (void) setLinkColor:(NSColor*)aColor
{
	NSMutableDictionary *attributes = [[[self linkTextAttributes] mutableCopyWithZone:[self zone]] autorelease];
	if ( attributes == nil ) attributes = [NSMutableDictionary dictionary];
	[attributes setObject:aColor forKey:NSForegroundColorAttributeName];
	[self setLinkTextAttributes:attributes];
}

- (BOOL) linkUnderlined
{
	return [[[self linkTextAttributes] objectForKey:NSUnderlineStyleAttributeName] boolValue];
}

- (void) setLinkUnderlined:(BOOL)underline
{
	NSMutableDictionary *attributes = [[[self linkTextAttributes] mutableCopyWithZone:[self zone]] autorelease];
	if ( attributes == nil ) attributes = [NSMutableDictionary dictionary];
	[attributes setObject:[NSNumber numberWithBool:underline] forKey:NSUnderlineStyleAttributeName];
	[self setLinkTextAttributes:attributes];
}

#pragma mark -

- (NSInteger) actualMargin
{
	return actualMargin;
}

- (void) setActualMargin:(NSInteger)inset
{
	actualMargin = inset;
	[self setTextContainerInset:NSMakeSize(( inset > 3 ? inset : 3 ), 3)];
}

- (NSInteger) horizontalInset
{
	return horizontalInset;
}

- (void) setHorizontalInset:(NSInteger)inset
{
	horizontalInset = inset;
	[self setActualMargin:( inFullScreen ? [self horizontalInsetFullscreen] : [self horizontalInset] )];
}

- (NSInteger) horizontalInsetFullscreen
{
	return horizontalInsetFullscreen;
}

- (void) setHorizontalInsetFullscreen:(NSInteger)inset
{
	horizontalInsetFullscreen = inset;
	[self setActualMargin:( inFullScreen ? [self horizontalInsetFullscreen] : [self horizontalInset] )];
}

- (void) setFullScreen:(BOOL)isFullScreen
{
	[self setInFullScreen:isFullScreen];
}

- (BOOL) inFullScreen
{
	return inFullScreen;
}

- (void) setInFullScreen:(BOOL)fullscreen
{
	inFullScreen = fullscreen;
	[self setActualMargin:( inFullScreen ? [self horizontalInsetFullscreen] : [self horizontalInset] )];
}

#pragma mark -

- (NSURL*) lastURL 
{ 
	return lastURL; 
}

- (void) setLastURL:(NSURL*)newURL 
{
	if ( lastURL != newURL ) 
	{
		[lastURL release];
		lastURL = [newURL copyWithZone:[self zone]];
	}
}

#pragma mark -
#pragma mark Overriding toggles

- (void)toggleAutomaticQuoteSubstitution:(id)sender
{
	NSLog(@"%s",__PRETTY_FUNCTION__);
	//EntryTextUseSmartQuotes
	BOOL aqsEnabled = [self isAutomaticQuoteSubstitutionEnabled];
	[[NSUserDefaults standardUserDefaults] setBool:!aqsEnabled forKey:@"EntryTextUseSmartQuotes"];

	//[super toggleAutomaticQuoteSubstitution:sender];
}

- (void)toggleAutomaticLinkDetection:(id)sender
{
	NSLog(@"%s",__PRETTY_FUNCTION__);
	//EntryTextRecognizeURLs
	BOOL aldEnabled = [self isAutomaticLinkDetectionEnabled];
	[[NSUserDefaults standardUserDefaults] setBool:!aldEnabled forKey:@"EntryTextUseSmartQuotes"];
	
	//[super toggleAutomaticLinkDetection:sender];
}

#pragma mark -
#pragma mark Pasting into the Text

- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard type:(NSString *)type {
	//intercept picture pastes so we can resize them
	
	//a list of types that we can accept
	
	//NSArray *types = [NSArray arrayWithObjects:
	//		NSFilenamesPboardType, WebURLsWithTitlesPboardType, NSURLPboardType,
	//		NSRTFDPboardType, NSRTFPboardType, NSTIFFPboardType, NSPICTPboardType, NSStringPboardType, nil];
	//NSString *desiredType = [pboard availableTypeFromArray:types];
	
		
	BOOL success = YES;
	
	if ( [type isEqualToString:NSPICTPboardType] || [type isEqualToString:NSTIFFPboardType] ) 
	{
		success = [self addImageDataToText:[pboard dataForType:type] dataType:type fileName:nil];
	}
	
	else if ( [type isEqualToString:NSFilenamesPboardType] ) 
	{
		success = YES;
		NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		
		NSInteger j;
		for ( j = 0; j < [files count]; j++ ) 
		{
			NSString *fileLoc = [files objectAtIndex:j];
			success = ( [self addFileToText:fileLoc fileName:nil forceTitle:NO resourceCommand:kNewResourceUseDefaults] && success );
			
			if ( j < [files count] - 1 )
				[self insertText:@" | "];
		}
	}
	
	else if ( [type isEqualToString:PDResourceIDPboardType] || [type isEqualToString:PDEntryIDPboardType] 
			|| [type isEqualToString:PDFolderIDPboardType] )
	{
		
        for ( NSString *aURIString in [pboard propertyListForType:type] )
			success = ( [self addJournlerObjectWithURIToText:[NSURL URLWithString:aURIString]] && success );
	}
	
	else if ( [type isEqualToString:WebURLsWithTitlesPboardType] )
	{
		// iterate through each of the items, forcing a link
		NSArray *webURLs = [pboard propertyListForType:WebURLsWithTitlesPboardType];
		NSArray *urls = [webURLs objectAtIndex:0];
		NSArray *titles = [webURLs objectAtIndex:1];
		
		NSInteger i;
		for ( i = 0; i < [urls count]; i++ )
		{
			success = ( [self addURLToText:[urls objectAtIndex:0] title:[titles objectAtIndex:0]] && success );
				
			if ( i < [urls count] - 1 )
				[self insertText:@" | "];
		}
	}
	
	else if ( [type isEqualToString:NSURLPboardType] )
	{
		success = [self addURLToText:[[NSURL URLFromPasteboard:pboard] absoluteString] title:[[NSURL URLFromPasteboard:pboard] absoluteString]];
	}
	
	else if ( [[pboard types] containsObject:@"LibraryIDPboardType"] )
	{
		NSArray *msgArray = [pboard propertyListForType:@"LibraryIDPboardType"];
		if ( msgArray != nil ) 
			success = [self addMailMessagesToText:msgArray];
		else
			success = NO;
			
		#ifdef __DEBUG__
		NSLog([msgArray description]);
		#endif
	}
	
	else
	{
		success = [super readSelectionFromPasteboard:pboard type:type];
	}
		
	// put up an error if necessary
	if ( success == NO )
	{
		NSBeep();
		[[NSAlert resourceToEntryError] runModal];
	}
		
	return success;
}


#pragma mark -
#pragma mark Dragging

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	BOOL success;
	static NSString *http_string = @"http://";
	static NSString *secure_http_string = @"https://";
	
	NSPasteboard *pboard = [sender draggingPasteboard];
	
	// why am I putting the pic & rtf types before the filenames type?
    NSArray *types = [NSArray arrayWithObjects:
			PDEntryIDPboardType, PDFolderIDPboardType, 
			PDResourceIDPboardType, kABPeopleUIDsPboardType, 
			kMailMessagePboardType, NSFilenamesPboardType,
			NSTIFFPboardType, NSPICTPboardType, 
			NSRTFDPboardType, NSRTFPboardType, 
			WebURLsWithTitlesPboardType, NSURLPboardType, 
			NSStringPboardType, nil];
	
	id source = [sender draggingSource];
	NSUInteger operation = _dragOperation;
    NSString *desiredType = [pboard availableTypeFromArray:types];
	NSArray *availableTypes = [pboard types];
	
	if ( source == self )
	{
		success = [super performDragOperation:sender];
	}

	else 
	{
		
		// add people to the text
		if ( [desiredType isEqualToString:kABPeopleUIDsPboardType] ) 
		{
			NSUInteger charIndex = [self _charIndexForDraggingLoc:[sender draggingLocation]];
			[self setSelectedRange:NSMakeRange(charIndex,0)];
			
			NSInteger i;
			NSArray *uids = [pboard propertyListForType:kABPeopleUIDsPboardType];
			for ( i = 0; i < [uids count]; i++ ) 
			{
				ABPerson *person = (ABPerson*)[[ABAddressBook sharedAddressBook] recordForUniqueId:[uids objectAtIndex:i]];
				success = [self addPersonToText:person];
				
				if ( i != [uids count] - 1 )
					[self insertText:@" | "];
			}
		}
		
		// add a message to the text
		else if ( [desiredType isEqualToString:kMailMessagePboardType] )
		{
			success = YES;
			NSUInteger charIndex = [self _charIndexForDraggingLoc:[sender draggingLocation]];
			[self setSelectedRange:NSMakeRange(charIndex,0)];

			// this takes a long time, so return and perform the copy after a short delay
			[self performSelector:@selector(addMailMessageToText:) withObject:[(id)sender retain] afterDelay:0.1];
		}
		
		// add files to the text
		else if ( [desiredType isEqualToString:NSFilenamesPboardType] ) 
		{
			success = YES;
			NSUInteger charIndex = [self _charIndexForDraggingLoc:[sender draggingLocation]];
			[self setSelectedRange:NSMakeRange(charIndex,0)];
			
			NSInteger j;
			NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
			for ( j = 0; j < [files count]; j++ ) 
			{
				NSString *fileLoc = [files objectAtIndex:j];
				success = ( [self addFileToText:fileLoc fileName:nil forceTitle:NO resourceCommand:operation] && success );
				if ( j != [files count] - 1 ) 
					[self insertText:@" | "];
			}
		}
		
		// add a web url to the text
		else if ( [desiredType isEqualToString:WebURLsWithTitlesPboardType] ) 
		{
			// iMBNativePasteboardFlavor iMBNativePasteboardFlavor
			BOOL iIntegration = NO;
			
			if ( [availableTypes containsObjects:[NSArray arrayWithObjects:kiLifeIntegrationPboardType, NSFilenamesPboardType, nil]]  ) 
				iIntegration = YES;

			// iterate through each of the items, forcing a link
			NSArray *pbArray = [pboard propertyListForType:WebURLsWithTitlesPboardType];
			NSArray *URLArray = [pbArray objectAtIndex:0];
			NSArray *titleArray = [pbArray objectAtIndex:1];
			
			if ( !URLArray || !titleArray || [URLArray count] != [titleArray count] ) 
			{
				NSLog(@"%s - malformed WebURLsWithTitlesPboardType data", __PRETTY_FUNCTION__);
				success = NO;
			}
			else 
			{
				success = YES;
				NSUInteger charIndex = [self _charIndexForDraggingLoc:[sender draggingLocation]];
				[self setSelectedRange:NSMakeRange(charIndex,0)];
				
				NSInteger i;
				for ( i = 0; i < [URLArray count]; i++ ) 
				{
					if ( iIntegration)
					{
						// coming from iIntegration, link the file
						//NSLog(@"iIntegration");
						success = ( [self addFileToText:[[NSURL URLWithString:[URLArray objectAtIndex:i]] path]
								fileName:[titleArray objectAtIndex:i] forceTitle:NO resourceCommand:operation] && success );
					}
					else
					{
						// if we have web urls, the operation is copy, and http:// is in the string, download an archive
						if ( operation == NSDragOperationCopy 
							&& ( [[URLArray objectAtIndex:i] rangeOfString:http_string].location == 0 
							|| [[URLArray objectAtIndex:i] rangeOfString:secure_http_string].location == 0 ) )
							success = [self addWebArchiveToTextFromURL:[NSURL URLWithString:[URLArray objectAtIndex:i]] title:[titleArray objectAtIndex:i]];
						
						// add a url to the text if we don't want to copy the site as an archive
						else
							success = ( [self addURLToText:[URLArray objectAtIndex:i] title:[titleArray objectAtIndex:i]] && success );
					}
					
					// add some space if necessary
					if ( i != [URLArray count] - 1 ) 
						[self insertText:@" | "];
				}
			}
		}
		
		// add a url to the text
		else if ( [desiredType isEqualToString:NSURLPboardType] ) 
		{
			if ( operation == NSDragOperationCopy && [[NSURL URLFromPasteboard:pboard] isHTTP] )
				success = [self addWebArchiveToTextFromURL:[NSURL URLFromPasteboard:pboard] title:nil];
			else
			{
				NSDictionary *attributes = [self typingAttributes];
				success = [super performDragOperation:sender];
				[self setTypingAttributes:attributes];
			}
		}
		
		// add an image to the text, producing a hard copy of the image while I'm at it
		else if ( [desiredType isEqualToString:NSTIFFPboardType] || [desiredType isEqualToString:NSPICTPboardType] ) 
		{
			NSUInteger charIndex = [self _charIndexForDraggingLoc:[sender draggingLocation]];
			[self setSelectedRange:NSMakeRange(charIndex,0)];
			
			success = [self addImageDataToText:[pboard dataForType:desiredType] dataType:desiredType fileName:nil];
		}
		
		// add a journler object to the text
		else if ( [desiredType isEqualToString:PDEntryIDPboardType] || [desiredType isEqualToString:PDFolderIDPboardType] ||
				[desiredType isEqualToString:PDResourceIDPboardType] )
		{
			success = YES;
			NSUInteger charIndex = [self _charIndexForDraggingLoc:[sender draggingLocation]];
			[self setSelectedRange:NSMakeRange(charIndex,0)];
			
			NSInteger i;
			NSArray *URIs = [pboard propertyListForType:desiredType];
			
			for ( i = 0; i < [URIs count]; i++ )
			{
				success = ( [self addJournlerObjectWithURIToText:[NSURL URLWithString:[URIs objectAtIndex:i]]] && success );
				if ( i != [URIs count] - 1 )
					[self insertText:@" | "];
			}
		}
		
		// add rich text to the entry
		else if ( [desiredType isEqualToString:NSRTFPboardType] ) 
		{
			NSData *data = [pboard dataForType:NSRTFPboardType];
			NSAttributedString *attr_str = [[[NSAttributedString alloc] initWithRTF:data documentAttributes:nil] autorelease];
			if ( attr_str ) 
			{
				success = [self addPreparedStringToText:attr_str];
				//success = YES;
			}
			else 
			{
				success = [super performDragOperation:sender];
			}
		}
		
		// add anything else to the entry
		else 
		{
			NSDictionary *attributes = [self typingAttributes];
			success = [super performDragOperation:sender];
			[self setTypingAttributes:attributes];
			
		}
	}
	
	// put up an error if necessary
	if ( success == NO )
	{
		NSBeep();
		[[NSAlert resourceToEntryError] runModal];
	}
	
	dragProducedEntry = NO;
	return success;
}

- (NSUInteger)dragOperationForDraggingInfo:(id <NSDraggingInfo>)dragInfo type:(NSString *)type 
{
	
	NSUInteger operation;
	_dragOperation = NSDragOperationNone;
	id source = [dragInfo draggingSource];
	
    NSArray *types = [NSArray arrayWithObjects:
			PDEntryIDPboardType, PDFolderIDPboardType, 
			PDResourceIDPboardType, kABPeopleUIDsPboardType, 
			kMailMessagePboardType, 
			NSTIFFPboardType, NSPICTPboardType,
			NSRTFDPboardType, NSRTFPboardType, 
			WebURLsWithTitlesPboardType, NSFilenamesPboardType,
			NSURLPboardType, NSStringPboardType, nil];
	
	NSPasteboard *pboard = [dragInfo draggingPasteboard];
    NSString *desiredType = [pboard availableTypeFromArray:types];
	NSArray *availableTypes = [pboard types];
	
	//if ( ![self isEditable] )
	//{
	//	operation = NSDragOperationGeneric;
	//}
	//else {
		
		//NSUInteger sourceOperation = [dragInfo draggingSourceOperationMask];
		operation = [super dragOperationForDraggingInfo:dragInfo type:type];
		
		if ( source == self )
			operation = [super dragOperationForDraggingInfo:dragInfo type:type];
		
		 // address record are always linked to text
		else if ( [kABPeopleUIDsPboardType isEqualToString:desiredType] )
			operation = NSDragOperationLink;
		
		// images are always copied to text
		else if ( [NSTIFFPboardType isEqualToString:desiredType] || [NSPICTPboardType isEqualToString:desiredType] )
			operation = NSDragOperationCopy;
			
		// journler objects are always linked
		else if ( [PDEntryIDPboardType isEqualToString:desiredType] || [PDFolderIDPboardType isEqualToString:desiredType]
				|| [PDResourceIDPboardType isEqualToString:desiredType] )
			operation = NSDragOperationLink;
		
		// mail messages directly from mail may be linked or copied
		else if ( [kMailMessagePboardType isEqualToString:desiredType] )
		{
			//if ( GetCurrentKeyModifiers() & optionKey )
				operation = NSDragOperationCopy;
			//else
			//	operation = NSDragOperationLink;
		}
		
		// urls are linked but may be copied as web archives
		else if ( [NSURLPboardType isEqualToString:desiredType] ) 
		{
			if ( GetCurrentKeyModifiers() & optionKey )
				operation = NSDragOperationCopy;
			else
				operation = NSDragOperationLink; 
		}
		
		// web urls require special attention
		else if ( [WebURLsWithTitlesPboardType isEqualToString:desiredType] ) 
		{
			if ( [availableTypes containsObjects:[NSArray arrayWithObjects:kiLifeIntegrationPboardType, NSFilenamesPboardType, nil]]  )
			{
				// iLife integration links by default, copy if the user really wants it
				if ( GetCurrentKeyModifiers() & optionKey )
					operation = NSDragOperationCopy;
				else
					operation = NSDragOperationLink;
			}
			else if ( GetCurrentKeyModifiers() & optionKey )
				operation = NSDragOperationCopy;
			else
				operation = NSDragOperationLink;
		}
		
		// filenames require special attention
		else if ( [NSFilenamesPboardType isEqualToString:desiredType] ) 
		{
			// default to generic
			operation = NSDragOperationGeneric;
			
			if ( [availableTypes containsObject:kMVMessageContentsPboardType] )
				operation = NSDragOperationCopy; // force a copy if there is message contents data on the pasteboard
			else if ( GetCurrentKeyModifiers() & optionKey )
				operation = NSDragOperationCopy;
			else if ( GetCurrentKeyModifiers() & controlKey )
				operation = NSDragOperationLink;
			else
			{
				// requires a little more care - examine what is being dragged, determine from there, keep operation generic though
				
				BOOL dir, package;
				NSString *appName = nil, *fileType = nil;
				NSString *path = [[pboard propertyListForType:NSFilenamesPboardType] objectAtIndex:0];
				
				// determine directory, type and package information
				if ( ! [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&dir] )
					goto bail;
				
				if ( ! [[NSWorkspace sharedWorkspace] getInfoForFile:path application:&appName type:&fileType] )
					goto bail;
					
				package = [[NSWorkspace sharedWorkspace] isFilePackageAtPath:path];
				
				_dragOperation = NSDragOperationGeneric;
				operation = [self _commandForCurrentCommand:NSDragOperationNone fileType:fileType directory:dir package:package];
			}
		}
	//}
	
bail:
	
	if ( _dragOperation == NSDragOperationNone )
		_dragOperation = operation;
	
	return operation;
}

#pragma mark -

- (NSArray *)acceptableDragTypes 
{
	 NSArray *types = [NSArray arrayWithObjects:
			PDEntryIDPboardType, PDFolderIDPboardType, 
			PDResourceIDPboardType, kABPeopleUIDsPboardType, 
			kMailMessagePboardType, NSTIFFPboardType, 
			NSPICTPboardType, NSRTFDPboardType, 
			NSRTFPboardType, WebURLsWithTitlesPboardType, 
			NSFilenamesPboardType, NSURLPboardType, 
			NSStringPboardType, nil];
	
	return [[super acceptableDragTypes] arrayByAddingObjectsFromArray:types];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	NSDragOperation operation;
	
	// Hack to enable mail message and address book drags and non-editable drags
	// super's draggingEntered: method doesn't call dragOperationForDraggingInfo:type:
	// if the options include kMailMessagePboardType or kABPeopleUIDsPboardType
	// I don't know why.
	
	if ( ![self isEditable] )
		operation = [self dragOperationForDraggingInfo:sender type:nil];
	else if ( [[[sender draggingPasteboard] types] containsObject:kMailMessagePboardType] )
		operation = [self dragOperationForDraggingInfo:sender type:nil];
	else if ( [[[sender draggingPasteboard] types] containsObject:kABPeopleUIDsPboardType] )
		operation = [self dragOperationForDraggingInfo:sender type:nil];
	else
		operation = [super draggingEntered:sender];
	
	return operation;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	NSDragOperation operation;
	
	if ( ![self isEditable] )
		operation = [self dragOperationForDraggingInfo:sender type:nil];
	else if ( [[[sender draggingPasteboard] types] containsObject:kMailMessagePboardType] )
		operation = [self dragOperationForDraggingInfo:sender type:nil];
	else if ( [[[sender draggingPasteboard] types] containsObject:kABPeopleUIDsPboardType] )
		operation = [self dragOperationForDraggingInfo:sender type:nil];
	else
		operation = [super draggingUpdated:sender];
	
	return operation;
}


- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	if ( ![self isEditable] ) 
	{
		if ( [[self delegate] respondsToSelector:@selector(textView:newDefaultEntry:)] )
		{
			// create a new entry if no entry is selected and immediately save it
			dragProducedEntry = YES;
			return [[self delegate] textView:self newDefaultEntry:nil];
		}
		else
		{
			return NO;
		}
	}
	else
	{
		return YES;
	}
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
   dragProducedEntry = NO;
}

- (BOOL)ignoreModifierKeysWhileDragging 
{
	return NO;
}

#pragma mark -

- (NSUInteger) _charIndexForDraggingLoc:(NSPoint)point 
{
	NSUInteger charIndex;
	NSPoint localPoint = [self convertPoint:point fromView:nil];
	
	// leopard/tiger fork
	if ( [self respondsToSelector:@selector(characterIndexForInsertionAtPoint:)] )
		charIndex = [self characterIndexForInsertionAtPoint:localPoint];
	else
	{
	
		// Convert view coordinates to container coordinates
		localPoint.x -= [self textContainerOrigin].x;
		localPoint.y -= [self textContainerOrigin].y;
		
		// Convert those coordinates to the nearest glyph index
		NSUInteger glyphIndex = [[self layoutManager] glyphIndexForPoint:localPoint inTextContainer:[self textContainer]];
		
		// Check to see whether the mouse actually lies over the glyph it is nearest to
		NSRect glyphRect = [[self layoutManager] boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1) inTextContainer:[self textContainer]];
		
		// Convert the glyph index to a character index
		charIndex = [[self layoutManager] characterIndexForGlyphAtIndex:glyphIndex];
		
		// make sure the char index is not beyond what is available to the text view
		// and fix the last char index problem
		if ( charIndex == NSNotFound || charIndex > [[self textStorage] length] || ( ! NSPointInRect(localPoint,glyphRect) && charIndex >= [[self textStorage] length] - 1 ) )
			charIndex = [[self textStorage] length];
	}
	
	return charIndex;
}

- (NSUInteger) _commandForCurrentCommand:(NSUInteger)dragOperation fileType:(NSString*)type directory:(BOOL)dir package:(BOOL)package
{
	NSInteger actualCommand = kNewResourceForceLink;
	
	// determine the actual command, copy or link the file, depending on type, media policy and caller's demands
	if ( dragOperation == kNewResourceForceLink ) 
	{
		actualCommand = kNewResourceForceLink;
	}
	
	else if ( dragOperation == kNewResourceForceCopy ) 
	{
		actualCommand = kNewResourceForceCopy;
	}
	
	else 
	{
		if ( [NSApplicationFileType isEqualToString:type] || [NSShellCommandFileType isEqualToString:type] ) 
		{
			// always link applications
			actualCommand = kNewResourceForceLink;
		}
		
		else if ( [NSDirectoryFileType isEqualToString:type] || ( dir && !package)  ) 
		{
			if ( [[NSUserDefaults standardUserDefaults] integerForKey:@"MediaPolicyDirectories"] == 0 )
			{
				// link directory with policy = 0
				actualCommand = kNewResourceForceLink;
			}
			
			else 
			{
				// copy if otherwise
				actualCommand = kNewResourceForceCopy;
			}
		}
		
		else if ( [NSFilesystemFileType isEqualToString:type] ) 
		{
			// always link mount points
			actualCommand = kNewResourceForceLink;
		}
		
		else 
		{
			if ( [[NSUserDefaults standardUserDefaults] integerForKey:@"MediaPolicyFiles"] == 0 )
			{
				// link file with policy = 0
				actualCommand = kNewResourceForceLink;
			}
			
			else 
			{
				// copy otherwise
				actualCommand = kNewResourceForceCopy;
			}
		}
	}
	
	return actualCommand;
} 

#pragma mark -

- (NSImage *)dragImageForSelectionWithEvent:(NSEvent *)event origin:(NSPointPointer)origin
{
	//NSLog(@"%s",__PRETTY_FUNCTION__);
	//return [super dragImageForSelectionWithEvent:event origin:origin];
	
	NSImage *returnImage = nil;
	
	if ( [[self delegate] respondsToSelector:@selector(textView:dragImageForSelectionWithEvent:origin:)] )
		returnImage = [[self delegate] textView:self dragImageForSelectionWithEvent:event origin:origin];
	
	if ( returnImage == nil )
		returnImage = [super dragImageForSelectionWithEvent:event origin:origin];
	
	return returnImage;
}

#pragma mark -
#pragma First Responder Handling

- (void) performCustomTextSizeAction:(id)sender
{
	/*
	if ( [sender tag] != 5 )
	{
		NSBeep(); return;
	}
	
	// iterate through each font, resizing to default font size
	float fontSize = [[[NSUserDefaults standardUserDefaults] fontForKey:@"DefaultEntryFont"] pointSize];
	*/
	// #warning implement performCustomTextSizeAction
	return;
}

- (IBAction) pasteAndMatchStyle:(id)sender {
	
	NSString *desiredType = [[NSPasteboard generalPasteboard]
			availableTypeFromArray:[NSArray arrayWithObjects:NSStringPboardType, nil]];
	
	NSString *to_insert = nil;
	
	if ( desiredType /*[desiredType isEqualToString:NSStringPboardType]*/ ) {
		
		to_insert = [[NSPasteboard generalPasteboard] stringForType:desiredType];
		
	}
	
	if ( to_insert == nil || ![self shouldChangeTextInRanges:[self rangesForUserTextChange] replacementStrings:[NSArray arrayWithObject:to_insert]] ) 
	{
		// make sure we're allowed to change and alert the system that a change is coming
		NSBeep();
	}
	else
	{
		NSDictionary *attrs = [self typingAttributes];
		NSAttributedString *matchedString = [[NSAttributedString alloc] initWithString:to_insert attributes:attrs];
		
		[[self textStorage] beginEditing];
		[[self textStorage] replaceCharactersInRange:[self rangeForUserTextChange] withAttributedString:matchedString];
		[[self textStorage] endEditing];
		
		[self didChangeText];
		
		[matchedString release];
	}
}

- (IBAction) copyAsHTML:(id)sender
{
	// #warning inline style definitions
	NSAttributedString *attrSelection = [[self textStorage] attributedSubstringFromRange:[self rangeForUserTextChange]];
	
	NSString *htmlString;
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"CopyingUseAdvancedHTMLGeneration"] )
		htmlString = [attrSelection attributedStringAsHTML:kUseSystemHTMLConversion|kUseInlineStyleDefinitions|kConvertSmartQuotesToRegularQuotes documentAttributes:nil 
				avoidStyleAttributes:[[NSUserDefaults standardUserDefaults] stringForKey:@"CopyingNoAttributeList"]];
	else
		htmlString = [attrSelection attributedStringAsHTML:kUseJournlerHTMLConversion|kConvertSmartQuotesToRegularQuotes documentAttributes:nil avoidStyleAttributes:nil];
	
	//NSData *htmlData = [attrSelection htmlRepresentation:YES documentAttributes:nil];
	//NSString *htmlString = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
	
	[[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	[[NSPasteboard generalPasteboard] setString:htmlString forType:NSStringPboardType];
}

#pragma mark -

- (IBAction) insertCheckbox:(id) sender {
	
	//NSMutableDictionary *attributes;
	NSFileWrapper *pngFileWrapper;
	
	NSImage *tempImage;
	NSBitmapImageRep *bitmapRep;
	
	NSMutableAttributedString *addText = [[NSMutableAttributedString alloc] init];
	
	//NSDictionary *attributes = [self attributesAtRangeForUserTextChange];
	
	//just need the image and bitmap rep
	tempImage = [NSImage imageNamed:@"checkboxunchecked.tif"];
	bitmapRep = [[NSBitmapImageRep alloc] initWithData:[tempImage TIFFRepresentation]];
	
	// -- Undo / Redo --------------------
	
	//now load this into an attributed string via a file wrapper, mind the quality preferences
	pngFileWrapper = [[NSFileWrapper alloc]
			initRegularFileWithContents:[bitmapRep representationUsingType:NSPNGFileType properties:nil]];
	[pngFileWrapper setPreferredFilename:@"PDCheckboxUnchecked.png"];
		
	NSTextAttachment *pngAttachment = [[NSTextAttachment alloc] initWithFileWrapper:pngFileWrapper];
		
	NSAttributedString *picAsAttrStr = [NSAttributedString attributedStringWithAttachment:pngAttachment];
	
	// -- Undo / Redo --------------------

	//add a blank space to
	//[addText appendAttributedString:_space];
	//insert the document icon
	[addText appendAttributedString:picAsAttrStr];
	//add a blank space between then
	//[addText appendAttributedString:_space];
	
	// add set our attributes for this string
	//[addText addAttributes:attributes range:NSMakeRange(0, [addText length])];
	
	//and send the text on its way
	[self addPreparedStringToText:addText];
	
	//clean up
	[addText release];
	[pngAttachment release];
	[pngFileWrapper release];
	[bitmapRep release];
	
}

- (IBAction) insertDateTime:(id)sender {
	
	id anItem = ( [sender isKindOfClass:[NSPopUpButton class]] ? [sender selectedItem] : nil );
	
	//what will our text look like?
	NSDateFormatter *date_formatter = [[NSDateFormatter alloc] init];
	NSString *insertText;
	switch ( ( anItem == nil ? [sender tag] : [anItem tag] ) ) {
		case 120: // date
			[date_formatter setDateStyle:NSDateFormatterLongStyle];
			[date_formatter setTimeStyle:NSDateFormatterNoStyle];
			break;
		case 121: // time
			[date_formatter setDateStyle:NSDateFormatterNoStyle];
			[date_formatter setTimeStyle:NSDateFormatterShortStyle];
			break;
		case 122: // date and time
			[date_formatter setDateStyle:NSDateFormatterLongStyle];
			[date_formatter setTimeStyle:NSDateFormatterShortStyle];
			break;
		default:
			[date_formatter setDateStyle:NSDateFormatterLongStyle];
			[date_formatter setTimeStyle:NSDateFormatterShortStyle];
			break;
	}
	
	insertText = [date_formatter stringFromDate:[NSDate date]];
	
	if ( insertText == nil || ![self shouldChangeTextInRanges:[self rangesForUserTextChange] replacementStrings:[NSArray arrayWithObject:insertText]] ) 
	{
		NSBeep();
	}
	else
	{
		[[self textStorage] beginEditing];
		[[self textStorage] replaceCharactersInRange:[self rangeForUserTextChange] withString:insertText];
		[[self textStorage] endEditing];
		
		[self didChangeText];
	}
}

- (IBAction) highlightSelection:(id) sender {
	
	//
	// takes the selected range and adds a background color to it
	//
	
	NSColor *highlightColor;
	NSUserDefaults *myDefaults = [NSUserDefaults standardUserDefaults];
	
	// make sure we're allowed to change and alert the system that a change is coming
	if ( ![self shouldChangeTextInRanges:[self rangesForUserTextChange] replacementStrings:nil] ) {
		NSBeep();
		return;
	}
	
	NSData *dataYellow = [myDefaults dataForKey:@"highlightYellow"];
	NSData *dataBlue = [myDefaults dataForKey:@"highlightBlue"];
	NSData *dataGreen = [myDefaults dataForKey:@"highlightGreen"];
	NSData *dataOrange = [myDefaults dataForKey:@"highlightOrange"];
	NSData *dataRed = [myDefaults dataForKey:@"highlightRed"];
	
	NSColor *colorYellow = ( dataYellow ? (NSColor *)[NSUnarchiver unarchiveObjectWithData:dataYellow] : 
			[NSColor yellowColor] );
	NSColor *colorBlue = ( dataBlue ? (NSColor *)[NSUnarchiver unarchiveObjectWithData:dataBlue] : 
			[NSColor blueColor] );
	NSColor *colorGreen = ( dataGreen ? (NSColor *)[NSUnarchiver unarchiveObjectWithData:dataGreen] : 
			[NSColor greenColor] );
	NSColor *colorOrange = ( dataOrange ? (NSColor *)[NSUnarchiver unarchiveObjectWithData:dataOrange] : 
			[NSColor orangeColor] );
	NSColor *colorRed = ( dataRed ? (NSColor *)[NSUnarchiver unarchiveObjectWithData:dataRed] : 
			[NSColor redColor] );
	
	NSRange changeRange = [self rangeForUserTextChange];
	
	//
	// find out if the text already has highlight and it's the toolbar item
	if ( [sender isKindOfClass:[NSToolbarItem class]] && [[self textStorage] attribute:NSBackgroundColorAttributeName 
				atIndex:changeRange.location effectiveRange:nil] ) {
		
		[[self textStorage] beginEditing];
		[[self textStorage] removeAttribute:NSBackgroundColorAttributeName ranges:[self rangesForUserTextChange]];
		[[self textStorage] endEditing];
	
		// undo management
		[[self undoManager] setActionName:NSLocalizedString(@"undo highlight", @"")];
	
		//let super know that we've changed
		[self didChangeText];
		
		return;
		
	}
	
	id anItem = ( [sender isKindOfClass:[NSPopUpButton class]] ? [sender selectedItem] : nil );
	NSInteger theTag =  ( anItem == nil ? [sender tag] : [anItem tag] );
	
	switch ( theTag ) {
		
		case 351:
			highlightColor = colorYellow;
			break;
		case 352:
			highlightColor = colorBlue;
			break;
		case 353:
			highlightColor = colorGreen;
			break;
		case 354:
			highlightColor = colorOrange;
			break;
		case 355:
			highlightColor = colorRed;
			break;
		default:
			highlightColor = colorYellow;
			break;
	
	}

	[[self textStorage] beginEditing];
	
	if ( theTag != 356 ) 
	{
		[[self textStorage] addAttribute:NSBackgroundColorAttributeName value:highlightColor ranges:[self rangesForUserTextChange]];
	}
	else 
	{
		[[self textStorage] removeAttribute:NSBackgroundColorAttributeName ranges:[self rangesForUserTextChange]];
	}
	
	[[self textStorage] endEditing];
	
	// undo management
	[[self undoManager] setActionName:NSLocalizedString(@"undo highlight", @"")];
	
	//let super know that we've changed
	[self didChangeText];
}

- (IBAction) strikeSelection:(id)sender
{
	NSRange aRange = [self rangeForUserTextChange];
	if ( aRange.location == NSNotFound )
	{
		NSBeep();
		return;
	}
	
	BOOL isStruck = ( [[[self textStorage] attribute:NSStrikethroughStyleAttributeName atIndex:aRange.location effectiveRange:nil] integerValue] != 0 );
	[self strikeSelection:nil styleMask:( isStruck ? 0 : NSUnderlineStyleSingle )];
}

- (void) strikeSelection:(NSColor*)aColor styleMask:(NSInteger)mask
{
	// make sure we're allowed to change and alert the system that a change is coming
	if ( ![self shouldChangeTextInRanges:[self rangesForUserTextChange] replacementStrings:nil] ) {
		NSBeep();
		return;
	}
		
	[[self textStorage] beginEditing];
	
	if ( aColor == nil )
		[[self textStorage] removeAttribute:NSStrikethroughColorAttributeName 
		ranges:[self rangesForUserTextChange]];
	else
		[[self textStorage] addAttribute:NSStrikethroughColorAttributeName value:aColor 
		ranges:[self rangesForUserTextChange]];
	
	if ( mask == 0 )
		[[self textStorage] removeAttribute:NSStrikethroughStyleAttributeName 
		ranges:[self rangesForUserTextChange]];
	else
		[[self textStorage] addAttribute:NSStrikethroughStyleAttributeName value:[NSNumber numberWithInteger:mask] 
		ranges:[self rangesForUserTextChange]];
		
	[[self textStorage] endEditing];
	
	// undo management
	//[[self undoManager] setActionName:NSLocalizedString(@"undo highlight", @"")];
	
	//let super know that we've changed
	[self didChangeText];

}

#pragma mark -
#pragma mark Adding Mail Messages to Text

- (BOOL) addMailMessagesToText:(NSArray*)messageIDs
{
	// for now the message ids are ignored and the selection is used
	// user must have message actually selected
	
	BOOL success = YES;
	NSAppleScript *script = nil;
	NSDictionary *errorInfo = nil;
	NSString *scriptPath = [[NSBundle mainBundle] pathForResource:@"GetMailSelectionPathDictionaries" ofType:@"scpt"];
	
	if ( scriptPath == nil )
		script = [[[NSAppleScript alloc] initWithSource:mailSelectionPathInfoSource] autorelease];
	else
	{
		script = [[[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:scriptPath] error:&errorInfo] autorelease];
		if ( script == nil )
		{
			NSLog(@"%s - error creating script from path %@, error: %@", __PRETTY_FUNCTION__, scriptPath, errorInfo);
			script = [[[NSAppleScript alloc] initWithSource:mailSelectionPathInfoSource] autorelease];
		}
	}
	
	if ( script == nil )
	{
		NSLog(@"%s - unable to create applscript, bailing", __PRETTY_FUNCTION__);
		success = NO;
		goto bail;
	}
	
	NSAppleEventDescriptor *eventDescriptor = [script executeAndReturnError:&errorInfo];
	if (eventDescriptor == nil && [[errorInfo objectForKey:NSAppleScriptErrorNumber] integerValue] != kScriptWasCancelledError )
	{
		NSLog(@"%s - problem running script, bailing: %@", __PRETTY_FUNCTION__, errorInfo);
		
		id theSource = [script richTextSource];
		if ( theSource == nil ) theSource = [script source];
		AppleScriptAlert *scriptAlert = [[[AppleScriptAlert alloc] initWithSource:theSource error:errorInfo] autorelease];
			
		NSBeep();
		[scriptAlert showWindow:self];
		
		success = NO;
		goto bail;
	}
	
	NSInteger i, totalCount = [eventDescriptor numberOfItems];
	
	if ( totalCount == 0 )
	{
		NSLog(@"%s - the returned event descriptor does not contain any items, is there a selection in mail?", __PRETTY_FUNCTION__);
		success = NO;
		goto bail;
	}
	
	NSString *mailRootFolder = [@"~/Library/Mail/" stringByExpandingTildeInPath];
	BOOL dir;
	if ( ![[NSFileManager defaultManager] fileExistsAtPath:mailRootFolder isDirectory:&dir] || !dir )
	{
		NSLog(@"%s - no mailboxes root exists at path %@", __PRETTY_FUNCTION__, mailRootFolder);
		success = NO;
		goto bail;
	}
	
	for ( i = 1; i <= totalCount; i++ )
	{
		// iterate through each descriptor, which should be another list descriptor
		NSAppleEventDescriptor *aPathInfoDescriptor = [eventDescriptor descriptorAtIndex:i];
		
		// path information depends on the count of the descriptor
		NSInteger pathInfoCount = [aPathInfoDescriptor numberOfItems];
		
		if ( pathInfoCount == 3 )
		{
			// the message is stored in a mailbox folder and not one of the account folders
			
			NSAppleEventDescriptor *idDescriptor = [aPathInfoDescriptor descriptorAtIndex:1];
			NSAppleEventDescriptor *mailSubjectDescriptor = [aPathInfoDescriptor descriptorAtIndex:2];
			NSAppleEventDescriptor *mailboxDescriptor = [aPathInfoDescriptor descriptorAtIndex:3];
			
			NSInteger idInt = [idDescriptor int32Value];
			NSString *mailboxName = [mailboxDescriptor stringValue];
			NSString *mailSubject = [mailSubjectDescriptor stringValue];
			
			NSString *mailboxFilename = [mailboxName stringByAppendingPathExtension:@"mbox"];
			NSString *messageFilename = [[NSString stringWithFormat:@"%i",idInt] stringByAppendingPathExtension:@"emlx"];
			
			// check for pop then imap accounts
			NSString *pathToMailbox = [[mailRootFolder stringByAppendingPathComponent:@"Mailboxes"]
					stringByAppendingPathComponent:mailboxFilename];
			
			if ( ![[NSFileManager defaultManager] fileExistsAtPath:pathToMailbox] ) 
				mailboxFilename = [mailboxName stringByAppendingPathExtension:@"imapmbox"];
			
			NSString *completePathToMessage = [[[[mailRootFolder stringByAppendingPathComponent:@"Mailboxes"] 
					stringByAppendingPathComponent:mailboxFilename] 
					stringByAppendingPathComponent:@"Messages"] 
					stringByAppendingPathComponent:messageFilename];
			
			#ifdef __DEBUG__
			NSLog(@"%s - message path: %@", __PRETTY_FUNCTION__, completePathToMessage);
			#endif
			
			if ( ![[NSFileManager defaultManager] fileExistsAtPath:completePathToMessage])
			{
				// stupid that I'm checking for this each time?
				// try with the partial extension
				
				messageFilename = [[NSString stringWithFormat:@"%i",idInt] stringByAppendingPathExtension:@"partial.emlx"];
				completePathToMessage = [[[[mailRootFolder stringByAppendingPathComponent:@"Mailboxes"] 
					stringByAppendingPathComponent:mailboxFilename] 
					stringByAppendingPathComponent:@"Messages"] 
					stringByAppendingPathComponent:messageFilename];
				
				if ( ![[NSFileManager defaultManager] fileExistsAtPath:completePathToMessage])
				{
					NSLog(@"%s - no message at derived path %@", __PRETTY_FUNCTION__, completePathToMessage);
					success = NO;
					continue;
				}
			}
			
			#ifdef __DEBUG__
			NSLog(@"%i %@ %@", idInt, mailSubject, mailboxName);
			NSLog(completePathToMessage);
			#endif
			
			success = ( [self addFileToText:completePathToMessage fileName:mailSubject forceTitle:NO resourceCommand:kNewResourceForceCopy] && success );
			if ( i != totalCount ) [self insertText:@"\n"];
				
		}
		
		else if ( pathInfoCount == 4 )
		{
			// the message is stored in an account folder, including subfolder such as inbox or outbox
			
			NSAppleEventDescriptor *idDescriptor = [aPathInfoDescriptor descriptorAtIndex:1];
			NSAppleEventDescriptor *mailSubjectDescriptor = [aPathInfoDescriptor descriptorAtIndex:2];
			NSAppleEventDescriptor *mailboxDescriptor = [aPathInfoDescriptor descriptorAtIndex:3];
			NSAppleEventDescriptor *accountPathDescriptor = [aPathInfoDescriptor descriptorAtIndex:4];
			
			NSInteger idInt = [idDescriptor int32Value];
			NSString *mailboxName = [mailboxDescriptor stringValue];
			NSString *mailSubject = [mailSubjectDescriptor stringValue];
			NSString *accountPath = [accountPathDescriptor stringValue];
			
			NSString *mailboxFilename = [mailboxName stringByAppendingPathExtension:@"mbox"];
			NSString *messageFilename = [[NSString stringWithFormat:@"%i",idInt] stringByAppendingPathExtension:@"emlx"];
			
			// check for pop then imap accounts
			NSString *pathToMailbox = [accountPath stringByAppendingPathComponent:mailboxFilename];
			
			if ( ![[NSFileManager defaultManager] fileExistsAtPath:pathToMailbox] ) 
				mailboxFilename = [mailboxName stringByAppendingPathExtension:@"imapmbox"];
			
			NSString *completePathToMessage = [[[accountPath stringByAppendingPathComponent:mailboxFilename] 
					stringByAppendingPathComponent:@"Messages"]
					stringByAppendingPathComponent:messageFilename];
		
			#ifdef __DEBUG__
			NSLog(@"%s - message path: %@", __PRETTY_FUNCTION__, completePathToMessage);
			#endif
		
			if ( ![[NSFileManager defaultManager] fileExistsAtPath:completePathToMessage])
			{
				// stupid that I'm checking for this each time?
				// try with the partial extension
				
				messageFilename = [[NSString stringWithFormat:@"%i",idInt] stringByAppendingPathExtension:@"partial.emlx"];
				completePathToMessage = [[[accountPath stringByAppendingPathComponent:mailboxFilename] 
					stringByAppendingPathComponent:@"Messages"]
					stringByAppendingPathComponent:messageFilename];
				
				if ( ![[NSFileManager defaultManager] fileExistsAtPath:completePathToMessage])
				{
					NSLog(@"%s - no message at derived path %@", __PRETTY_FUNCTION__, completePathToMessage);
					success = NO;
					continue;
				}
			}
			
			#ifdef __DEBUG__
			NSLog(@"%i %@ %@ %@", idInt, mailSubject, mailboxName, accountPath);
			NSLog(completePathToMessage);
			#endif
			
			success = ( [self addFileToText:completePathToMessage
			fileName:( [mailSubject length] > 0 ? mailSubject : NSLocalizedString(@"untitled title",@"") ) forceTitle:NO
			resourceCommand:kNewResourceForceCopy] && success );
			 
			if ( i != totalCount ) [self insertText:@"\n"];
			
		}
		
		else
		{
			NSLog(@"%s - invalid descriptor for mail message path information, must contain 3 or 4 items, %@", __PRETTY_FUNCTION__, aPathInfoDescriptor);
			success = NO;
		}
	}
	
bail:
	
	// put up an alert if necessary
	if ( success == NO )
	{
		NSBeep();
		[[NSAlert resourceToEntryError] runModal];
	}
	
	return success;
}

- (BOOL) addMailMessageToText:(id <NSDraggingInfo>)sender
{
	// YOU MUST RETAIN sender BEFORE CALLING THIS METHOD
	
	IntegrationCopyFiles *notice = [[IntegrationCopyFiles alloc] init];
	[notice setNoticeText:NSLocalizedString(@"integration reading messages",@"")];
	[notice runNotice];
	
	BOOL success = YES;
	NSUInteger operation = _dragOperation;
	NSPasteboard *pboard = [sender draggingPasteboard];
	
	// get the path, get the selection via applescript, build the full paths
	
	//NSUInteger charIndex = [self _charIndexForDraggingLoc:[sender draggingLocation]];
	//[self setSelectedRange:NSMakeRange(charIndex,0)];
	
	NSString *mboxPath = [pboard stringForType:kMailMessagePboardType];
	
	#ifdef __DEBUG__
	NSLog(mboxPath);
	#endif
	
	NSDictionary *errorDictionary = nil;
	NSAppleEventDescriptor *eventDescriptor;
	NSAppleScript *script;
	NSString *scriptPath = [[NSBundle mainBundle] pathForResource:@"GetMailSelection" ofType:@"scpt"];
	
	if (scriptPath == nil )
		script = [[[NSAppleScript alloc] initWithSource:selectionIDsSource] autorelease];
	else
		script = [[[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:scriptPath] error:&errorDictionary] autorelease];
	
	if ( script == nil )
	{
		NSLog(@"%s - unable to initialize the mail message script: %@", __PRETTY_FUNCTION__, errorDictionary);
		success = NO;
		goto bail;
	}
	else
	{
	
		eventDescriptor = [script executeAndReturnError:&errorDictionary];
		if ( eventDescriptor == nil && [[errorDictionary objectForKey:NSAppleScriptErrorNumber] integerValue] != kScriptWasCancelledError )
		{
			NSLog(@"%s - problem compiling mail message selection script: %@", __PRETTY_FUNCTION__, errorDictionary);
			
			id theSource = [script richTextSource];
			if ( theSource == nil ) theSource = [script source];
			AppleScriptAlert *scriptAlert = [[[AppleScriptAlert alloc] initWithSource:theSource error:errorDictionary] autorelease];
			
			NSBeep();
			[scriptAlert showWindow:self];
			
			success = NO;
			goto bail;
		}
		else if ( [eventDescriptor numberOfItems] == 0 )
		{
			NSLog(@"%s - mail messasge drag, the return event descriptor contains no items: %@", __PRETTY_FUNCTION__, eventDescriptor);
			success = NO;
			goto bail;
		}
		else
		{
			#ifdef __DEBUG__
			NSLog([eventDescriptor description]);
			#endif
			
			NSInteger i, totalItems = [eventDescriptor numberOfItems];
			for ( i = 1; i <= totalItems; i++ )
			{
				NSAppleEventDescriptor *itemDescriptor = [eventDescriptor descriptorAtIndex:i];
				
				#ifdef __DEBUG__
				NSLog([itemDescriptor description]);
				#endif
				
				if ( [itemDescriptor numberOfItems] != 2 )
				{
					success = NO;
					continue;
				}
				
				// each event descriptor is itself an array of two items: id, subject
				NSInteger anID = [[itemDescriptor descriptorAtIndex:1] int32Value];
				NSString *aSubject = [[itemDescriptor descriptorAtIndex:2] stringValue];
				
				NSString *aMessagePath = [[mboxPath stringByAppendingPathComponent:@"Messages"] 
						stringByAppendingPathComponent:[NSString stringWithFormat:@"%i.emlx", anID]];
				
				#ifdef __DEBUG__
				NSLog(@"%s - message path: %@", __PRETTY_FUNCTION__, aMessagePath);
				#endif
				
				if ( ![[NSFileManager defaultManager] fileExistsAtPath:aMessagePath] )
				{
					// try with the partial extension
					aMessagePath = [[mboxPath stringByAppendingPathComponent:@"Messages"] 
						stringByAppendingPathComponent:[NSString stringWithFormat:@"%i.partial.emlx", anID]];
				}
				
				success = ( [self addFileToText:aMessagePath fileName:( [aSubject length] > 0 ? aSubject : NSLocalizedString(@"untitled title", @"") ) 
				forceTitle:NO resourceCommand:operation] && success );
						
				if ( i != totalItems ) [self insertText:@"\n"];
			}
		}
	}
	
bail:
	
	[notice endNotice];
	[notice release];
	
	// sender was retained before it was sent
	[(id)sender release];
	
	// put up an alert if necessary
	if ( success == NO )
	{
		NSBeep();
		[[NSAlert resourceToEntryError] runModal];
	}
	
	return success;
}

#pragma mark -
#pragma mark Adding Media to Text

- (BOOL) addPersonToText:(ABPerson*)aPerson 
{
	BOOL success;
	JournlerResource *resource = [[self entry] resourceForABPerson:aPerson];
	if ( resource == nil )
	{
		NSLog(@"%s - unable to create resource for ABPerson %@", __PRETTY_FUNCTION__, [aPerson uniqueId]);
		return NO;
	}
	
	NSURL *url = [resource URIRepresentation];
	NSString *title = [resource valueForKey:@"title"];
	NSImage *icon = [[resource valueForKey:@"icon"] imageWithWidth:32 height:32];
	
	// the attributes which will be used
	NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:url, NSLinkAttributeName, nil];
	
	// insert the text and image with the attributes
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"NewMediaLinkIncludeIcon"] )
		success = [self insertText:title image:icon attributes:attributes];
	else
		success = [self insertText:title image:nil attributes:attributes];
		
	return success;	
}

- (BOOL) addURLToText:(NSString*)urlString title:(NSString*)aTitle
{	
	NSURL *url = [NSURL URLWithString:urlString];
	
	if ( [url isFileURL] )
	{
		return [self addFileToText:[url path] fileName:aTitle forceTitle:NO resourceCommand:kNewResourceForceLink];
	}
	
	else if ( [url isJournlerURI] )
	{
		return [self addJournlerObjectWithURIToText:url];
	}
	
	else
	{
		BOOL success;
		JournlerResource *resource = [[self entry] resourceForURL:urlString title:aTitle];
		if ( resource == nil )
		{
			NSLog(@"%s - unable to create resource for url %@", __PRETTY_FUNCTION__, urlString);
			return NO;
		}
		
		// a resource is added to the entry, but the actual url is inserted into the text
		NSURL *url = [NSURL URLWithString:urlString];
		NSString *title = [resource valueForKey:@"title"];
		
		// the attributes which will be used
		NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys: url, NSLinkAttributeName, nil];
		
		// insert the text and image with the attributes
		success = [self insertText:title image:nil attributes:attributes];
		return success;	
	}
}

- (BOOL) addURLLocToText:(NSString*)urlString http:(NSString*)httpString 
{
	NSString *text;
	NSDictionary *attrs = nil;
		
	//build the URL
	if ( httpString && [httpString length] != 0 ) 
	{
		NSURL *fileURL = [NSURL URLWithString:httpString];
		attrs = [NSDictionary dictionaryWithObjectsAndKeys: fileURL, NSLinkAttributeName, nil];
		
		if ( urlString && [urlString length] != 0 ) 
		{
			text = urlString;
		}
		else 
		{
			// use the current selection
			text = [[self string] substringWithRange:[self rangeForUserTextChange]];
		}
	}
	else 
	{
		attrs = nil;
		text = urlString;
	}
	
	return [self insertText:text image:nil attributes:attrs];
}

- (BOOL) addWebArchiveToTextFromURL:(NSURL*)url title:(NSString*)sitename
{
	// attempst to save the specified address as a webarchive and copy it to the entry
	
	IntegrationCopyFiles *notice = [[IntegrationCopyFiles alloc] init];
	[notice setNoticeText:NSLocalizedString(@"integration creating archive",@"")];
	[notice runNotice];
	
	NSString *destinationPath, *destinationFolder = TempDirectory();
	NSURLRequest *url_request = [[NSURLRequest alloc] initWithURL:url];
	WebView *web_view = [[WebView alloc] initWithFrame:NSMakeRect(0,0,100,100)];
	PDWebDelegate *web_delegate = [[PDWebDelegate alloc] initWithWebView:web_view];
	
	[[web_view mainFrame] loadRequest:url_request];
	[web_delegate waitForView:15.0];
	
	[notice endNotice];
	[notice release];
	
	if ( [[[web_view mainFrame] dataSource] isLoading] )
	{
		[[web_view mainFrame] stopLoading];
		NSLog(@"%s - operation timed out loading url %@", __PRETTY_FUNCTION__, [url absoluteString] );
		destinationPath = nil;
		goto bail;
	}
	
	WebArchive *services_archive = [[[web_view mainFrame] DOMDocument] webArchive];
	if ( sitename == nil ) sitename = [[[web_view mainFrame] dataSource] pageTitle];
	if ( sitename == nil || [sitename length] == 0 ) sitename = NSLocalizedString(@"untitled title", @"");
	
	if ( services_archive == nil ) 
	{
		NSLog(@"%s - unable to derive webarchive from url %@", __PRETTY_FUNCTION__, [url absoluteString] );
		destinationPath = nil;
		goto bail;
	}
	
	destinationPath = [[destinationFolder 
	 stringByAppendingPathComponent:[sitename pathSafeString]] stringByAppendingPathExtension:@"webarchive"];
	
	if ( ![[services_archive data] writeToFile:destinationPath options:NSAtomicWrite error:nil]	) 
	{
		NSLog(@"%s - unable to write webarchive to %@", __PRETTY_FUNCTION__, destinationPath);
		destinationPath = nil;
		goto bail;
	}

bail:
	
	if ( destinationPath == nil )
		return NO;
	else
		return [self addFileToText:destinationPath fileName:( sitename ? sitename : [url absoluteString] ) forceTitle:YES resourceCommand:kNewResourceForceCopy];
}

- (BOOL) addJournlerObjectWithURIToText:(NSURL*)aURI
{
	
	if ( [aURI isJournlerResource] )
	{
		// drop in a link to the resource, unless the resource is a webpage or another journler object
		JournlerResource *theResource = [[self valueForKeyPath:@"delegate.journal"] objectForURIRepresentation:aURI];
		if ( theResource == nil )
		{
			NSLog(@"%s - unable to produce object for resource uri %@", __PRETTY_FUNCTION__, [aURI absoluteString]);
			return NO;
		}
		
		// add the resource to the entry
		[[self entry] addResource:theResource];
		
		NSURL *url = nil;
		NSDictionary *attrs = nil;
		
		NSImage *theImage = nil;
		NSString *title = [theResource valueForKey:@"title"];
		
		if ( title == nil || [title length] == 0 )
			title = [aURI absoluteString];
		
		if ( [theResource representsJournlerObject] )
		{
			url = [NSURL URLWithString:[theResource valueForKey:@"uriString"]];
			theImage = [[theResource valueForKey:@"icon"] imageWithWidth:32 height:32];
		}
		else if ( [theResource representsURL] )
		{
			url = [NSURL URLWithString:[theResource valueForKey:@"urlString"]];
			theImage = [[theResource valueForKey:@"icon"] imageWithWidth:32 height:32];
		}
		else
		{
			url = [theResource URIRepresentation];
			
			// associate an image with the resource as necessary
			if ( [theResource representsFile] && [NSImage canInitWithFile:[theResource originalPath]] )
			{
				NSInteger kMaxWidth = ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EmbeddedImageUseFullSize"] ? 0
				: [[NSUserDefaults standardUserDefaults] integerForKey:@"EmbeddedImageMaxWidth"] );
				
				NSImage *filesImage = [[[NSImage alloc] initWithContentsOfFile:[theResource originalPath]] autorelease];
				
				if ( kMaxWidth != 0 && [filesImage size].width > kMaxWidth )
					theImage = [filesImage imageWithWidth:kMaxWidth height:((kMaxWidth*[filesImage size].height)/[filesImage size].width)];
				else
					theImage = filesImage;
				
				title = nil;
			}
			else
			{
				theImage = [[theResource valueForKey:@"icon"] imageWithWidth:32 height:32];
			}
		}
		
		// build the attrs to be used
		if ( url != nil )
			attrs = [NSDictionary dictionaryWithObject:url forKey:NSLinkAttributeName];

		// send the text on its way
		BOOL success;
		
		if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"NewMediaLinkIncludeIcon"] )
			success = [self insertText:title image:theImage attributes:attrs];
		else
			success = [self insertText:title image:nil attributes:attrs];
			
		return success;

	}
	else
	{
		id theObject = [[self valueForKeyPath:@"delegate.journal"] objectForURIRepresentation:aURI];
		if ( theObject == nil )
		{
			NSLog(@"%s - unable to produce object for uri %@", __PRETTY_FUNCTION__, [aURI absoluteString]);
			return NO;
		}
		
		// establish the relationship with the entry - note I don't actually use this resource for anything
		JournlerResource *resource = [[self entry] resourceForJournlerObject:theObject];
		if ( resource == nil )
		{
			NSLog(@"%s - unable to produce new resource for uri %@", __PRETTY_FUNCTION__, [aURI absoluteString]);
			return NO;
		}
		
		//NSImage *icon = [[theObject valueForKey:@"icon"] imageWithWidth:32 height:32];
		NSString *title = [theObject valueForKey:@"title"];
		if ( title == nil || [title length] == 0 )
			title = [aURI absoluteString];
		
		// build the attrs to be used
		NSDictionary *attrs = [NSDictionary dictionaryWithObject:aURI forKey:NSLinkAttributeName];

		// send the text on its way
		//if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"NewMediaLinkIncludeIcon"] )
		//	return [self insertText:title image:icon attributes:attrs];
		//else	
		return [self insertText:title image:nil attributes:attrs];
	}
}

- (BOOL) addImageDataToText:(NSData*)data dataType:(NSString*)type fileName:(NSString*)name 
{
	NSInteger kMaxWidth = ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EmbeddedImageUseFullSize"] ? 0
	: [[NSUserDefaults standardUserDefaults] integerForKey:@"EmbeddedImageMaxWidth"] );

	// copy the image data to the entry
	NSImage *image = [[NSImage alloc] initWithData:data];
	if ( !image ) 
	{
		NSLog(@"%s - unable to create image from data", __PRETTY_FUNCTION__);
		return NO;
	}
	
	NSData *tiffData = [image TIFFRepresentation];
	if ( !tiffData ) 
	{
		NSLog(@"%s - unable to create get tiff representation for image", __PRETTY_FUNCTION__);
		return NO;
	}
	
	NSString *temppath = [NSString stringWithFormat:@"/tmp/%@.tif", 
			(name?name:[[NSNumber numberWithDouble:[[NSDate date] timeIntervalSinceReferenceDate]] stringValue])];
	
	NSError *error;
	if ( ![tiffData writeToFile:temppath options:NSAtomicWrite error:&error] ) 
	{
		NSLog(@"%s error writing tiff data to path %@", __PRETTY_FUNCTION__, [error localizedDescription]);
		return NO;
	}
	
	NSURL *urlpath = [NSURL fileURLWithPath:temppath];
	if ( !urlpath ) 
	{
		NSLog(@"%s - unable to create url for image path", __PRETTY_FUNCTION__);
		return NO;
	}
	
	JournlerResource *resource = [[self entry] resourceForFile:temppath operation:kNewResourceForceCopy];
	
	if ( resource == nil ) 
	{
		NSLog(@"%s - unable to create resource for file at path %@", __PRETTY_FUNCTION__, temppath);
		return NO;
	}
	
	// set the resources title if requested
	if ( name != nil )
		[resource setValue:[temppath lastPathComponent] forKey:@"title"];
	
	// prepare the attribute dictionary for this link
	NSURL *resourceURL = [resource URIRepresentation];
	NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:resourceURL, NSLinkAttributeName, nil];
	
	// prepare the image that will be inserted in the entry
	NSImage *resizedImage;
	if ( kMaxWidth != 0 && [image size].width > kMaxWidth )
		resizedImage = [image imageWithWidth:kMaxWidth height:((kMaxWidth*[image size].height)/[image size].width)];
	else
		resizedImage = image;	
	
	// insert the image and the link
	[self insertText:nil image:resizedImage attributes:attrs];
	
	return YES;
}

- (BOOL) addFileToText:(NSString*)path fileName:(NSString*)title forceTitle:(BOOL)forceTitle resourceCommand:(NSInteger)command {
	
	//
	// insert the specified file, linking or copying, displaying icon or image as appropriate
	//NSInteger kMaxWidth = ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EmbeddedImageUseFullSize"] ? 0
	//: [[NSUserDefaults standardUserDefaults] integerForKey:@"EmbeddedImageMaxWidth"] );
	
	BOOL forceImage = NO, dir = NO, package = NO, success = NO;
	NSInteger actualCommand = kNewResourceForceLink;
	NSString *displayName;
	NSString *appName = nil, *fileType = nil;
	
	// make sure the file exists at this path
	if ( ![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&dir] ) 
	{
		NSLog(@"%s - file does not exist at path %@", __PRETTY_FUNCTION__, path);
		return NO;
	}
	
	// get the file's type
	if ( ![[NSWorkspace sharedWorkspace] getInfoForFile:path application:&appName type:&fileType] ) 
	{
		NSLog(@"%s - unable to get file type at path %@", __PRETTY_FUNCTION__, path);
		//return NO;
	}
	
	// is the file a package?
	package = [[NSWorkspace sharedWorkspace] isFilePackageAtPath:path];
	
	// determine the actual command, copy or link the file, depending on type, media policy and caller's demands
	actualCommand = [self _commandForCurrentCommand:command fileType:fileType directory:dir package:package];
	
	// having determined the actual command, perform the copy or link
	JournlerResource *resource;
	if ( actualCommand == kNewResourceForceLink ) 
	{
		resource = [[self entry] resourceForFile:path operation:actualCommand];
	}
	
	else if ( actualCommand == kNewResourceForceCopy ) 
	{
		IntegrationCopyFiles *notice = [[IntegrationCopyFiles alloc] init];
		[notice runNotice];
		
		resource = [[self entry] resourceForFile:path operation:actualCommand];
		
		[notice endNotice];
		[notice release];
	}

	if ( resource == nil ) 
	{
		NSLog(@"%s - unable to create resource for file at path %@", __PRETTY_FUNCTION__, path);
		return NO;
	}
	
	// set the resources title if requested
	if ( title != nil )
		[resource setValue:( [title length] != 0 ? title : NSLocalizedString(@"untitled title",@"") ) forKey:@"title"];
	
	// prepare the attribute dictionary for this link
	NSURL *resourceURL = [resource URIRepresentation];
	NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:resourceURL, NSLinkAttributeName, nil];
	
	// prepare the image - depends on whether the file can be displayed or not
	NSImage *image = nil, *resizedImage = nil;
	NSInteger kMaxWidth = ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EmbeddedImageUseFullSize"] ? 0
	: [[NSUserDefaults standardUserDefaults] integerForKey:@"EmbeddedImageMaxWidth"] );
		
	if ( [NSImage canInitWithFile:path] )
	{
		displayName = nil;
		image = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
		if ( image != nil )
		{
			forceImage = YES;
			
			if ( kMaxWidth != 0 && [image size].width > kMaxWidth )
				resizedImage = [image imageWithWidth:kMaxWidth height:((kMaxWidth*[image size].height)/[image size].width)];
			else
				resizedImage = image;	
		}
		else 
		{
			NSLog(@"%s - unable to init image from path %@", __PRETTY_FUNCTION__, path);
		}
	}
	else 
	{
		if ( forceTitle == NO && ( [[NSWorkspace sharedWorkspace] canPlayFile:path] 
			|| [[NSWorkspace sharedWorkspace] canWatchFile:path] || [[NSWorkspace sharedWorkspace] canViewFile:path] ) )
		{
			if ( [[NSWorkspace sharedWorkspace] canPlayFile:path] )
				displayName = [self _linkedTextForAudioFile:path];
			else if ( [[NSWorkspace sharedWorkspace] canWatchFile:path] || [[NSWorkspace sharedWorkspace] canViewFile:path] )
				displayName = [[NSWorkspace sharedWorkspace] mdTitleForFile:path];
			
			NSString *displayTitle = [[NSWorkspace sharedWorkspace] mdTitleForFile:path];
			if ( displayTitle != nil ) [resource setValue:displayTitle forKey:@"title"];
		}
		else
			displayName = ( title != nil && [title length] != 0 ? title : [resource valueForKey:@"title"] );
		
		image = [[NSWorkspace sharedWorkspace] iconForFile:path];
		[image setSize:NSMakeSize(128,128)];
		resizedImage = [image imageWithWidth:32 height:32 inset:0];
	}
	
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"NewMediaLinkIncludeIcon"] || forceImage )
		success = [self insertText:displayName image:resizedImage attributes:attrs];
	else
		success = [self insertText:displayName image:nil attributes:attrs];
		
	return success;
}

#pragma mark -


- (BOOL) insertText:(NSString*)linkedText image:(NSImage*)linkedImage attributes:(NSDictionary*)attr 
{
	// inserts the linkedText and linkedImage pointing at the url
	
	NSMutableDictionary *these_attrs = [[[self attributesAtRangeForUserTextChange] mutableCopyWithZone:[self zone]] autorelease];
	
	[these_attrs removeObjectForKey:NSAttachmentAttributeName];
	[these_attrs addEntriesFromDictionary:attr];
	
	NSMutableAttributedString *insertString = [[[NSMutableAttributedString alloc] 
			initWithString:[NSString string] attributes:these_attrs] autorelease];
	
	// prepare the image if one is available
	if ( linkedImage != nil ) 
	{
		NSBitmapImageRep *bitmapRep = [[[NSBitmapImageRep alloc] initWithData:[linkedImage TIFFRepresentation]] autorelease];
		if ( bitmapRep == nil )
		{
			NSLog(@"%s - unable to create bitmap rep from image", __PRETTY_FUNCTION__);
		}
		else 
		{
			NSFileWrapper *iconWrapper = [[[NSFileWrapper alloc] 
					initRegularFileWithContents:[bitmapRep representationUsingType:NSPNGFileType 
					properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor]]] autorelease];
					
			if ( iconWrapper == nil )
			{
				NSLog(@"%s - unable to create icon file wrapper from bitmap", __PRETTY_FUNCTION__);
			}
			else 
			{
				if ( linkedText != nil )
					[iconWrapper setPreferredFilename:[linkedText stringByAppendingPathExtension:@"png"]];
				else
					[iconWrapper setPreferredFilename:@"iconimage.png"];
				
				NSTextAttachment *iconAttachment = [[[NSTextAttachment alloc] initWithFileWrapper:iconWrapper] autorelease];
				if ( iconAttachment == nil )
				{
					NSLog(@"%s - unable to create icon text attachment from file wrapper", __PRETTY_FUNCTION__);
				}
				else 
				{
					NSMutableAttributedString *imgStr = [[[NSAttributedString 
							attributedStringWithAttachment:iconAttachment] mutableCopyWithZone:[self zone]] autorelease];
					
					if ( these_attrs != nil ) 
						[imgStr addAttributes:these_attrs range:NSMakeRange(0,[imgStr length])];
				
					// actually add the image to our final string
					[insertString appendAttributedString:imgStr];
				}
			}
		}
	}
	
	// add a space!
	if ( linkedImage != nil && linkedText != nil )
		[insertString appendAttributedString:_space];
	
	// prepare the text if text is available
	if ( linkedText != nil ) 
	{
		NSAttributedString *textStr = [[[NSAttributedString alloc] initWithString:linkedText attributes:these_attrs] autorelease];
		// add the text to the final string
		[insertString appendAttributedString:textStr];
	}
	
	if (  dragProducedEntry == YES )
	{
		// set the title on the entry if this is the first chance for it
		if ( linkedText != nil ) [[self entry] setValue:linkedText forKey:@"title"];
		 dragProducedEntry = NO;
	}
	
	// send the final string off to be inserted!
	[self addPreparedStringToText:insertString];
	
	return YES;
}

#pragma mark -

- (BOOL) addPreparedStringToText:(NSAttributedString*)preparedText 
{	
	BOOL success = NO;
	
	// make sure we're allowed to change and alert the system that a change is coming
	if ( preparedText == nil || ![self shouldChangeTextInRanges:[self rangesForUserTextChange] replacementStrings:[NSArray arrayWithObject:[preparedText string]]] ) 
	{
		NSBeep();
		success = NO;
	}
	else
	{
		NSDictionary *attributes = [self typingAttributes];
		
		[[self textStorage] beginEditing];
		[[self textStorage] replaceCharactersInRange:[self rangeForUserTextChange] withAttributedString:preparedText];
		[[self textStorage] endEditing];
		
		[self setTypingAttributes:attributes];
		
		//let super know that we've changed
		[self didChangeText];
		success = YES;
	}

	return success;
}

- (NSDictionary*) attributesAtRangeForUserTextChange {
	
	//
	// Grabs the attributes of the currently selected text 
	// or default attributes if there is no text
	//
	
	if ( [[self string] length] == 0 )
		return [JournlerEntry defaultTextAttributes];
	else
		return [self typingAttributes];
		
	
}

#pragma mark -

- (void)mouseDown:(NSEvent *)theEvent {
	
	//
	// intercept mouse down only to check the modifier flags
	//
	
	if ( ![self isEditable] && [theEvent clickCount] == 2 )
	{
		if ( [[self delegate] respondsToSelector:@selector(textView:newDefaultEntry:)] )
			[[self delegate] textView:self newDefaultEntry:nil];
	}
	else 
	{
		[self setModifierFlags:[theEvent modifierFlags]];
		[super mouseDown:theEvent];
		[self setModifierFlags:0];
	}
}

#pragma mark -

- (void)toggleRuler:(id)sender 
{
	[super toggleRuler:self];
	if ( [[self delegate] respondsToSelector:@selector(textView:rulerToggling:)] )
		[[self delegate] textView:self rulerToggling:nil];
}

- (IBAction) showStats:(id)sender {
	
	NSInteger paragraph_count, word_count;
	NSString *selected_text;
	NSMutableString *paragraph_text;
	
	StatsController *stats;
	
	selected_text = [[self string] substringWithRange:[self rangeForUserTextChange]];
	if ( !selected_text || [selected_text length] == 0 ) selected_text = [self string];
	
	paragraph_text = [selected_text mutableCopyWithZone:[self zone]];
	
	[paragraph_text replaceOccurrencesOfString:@"\r" withString:@"\n" options:NSLiteralSearch range:NSMakeRange(0,[paragraph_text length])];
	[paragraph_text replaceOccurrencesOfString:@"\n\n" withString:@"\n" options:NSLiteralSearch range:NSMakeRange(0,[paragraph_text length])];
	
	paragraph_count = [[paragraph_text componentsSeparatedByString:@"\n"] count];
	word_count = [[NSSpellChecker sharedSpellChecker] countWordsInString:selected_text language:nil];
	
	stats = [[StatsController alloc] init];
	
	[stats runAsSheetForWindow:[self window] attached:YES 
			chars:[selected_text length] words:word_count pars:paragraph_count];
	
	[stats release];
	[paragraph_text release];
		
}

/*
- (IBAction) showInvisibles:(id)sender {
	
	if ( [[self layoutManager] showsControlCharacters] ) {
		
		//[[self layoutManager] setShowsInvisibleCharacters:NO];
		[[self layoutManager] setShowsControlCharacters:NO];
		
	}
	
	else {
		
		//[[self layoutManager] setShowsInvisibleCharacters:YES];
		[[self layoutManager] setShowsControlCharacters:YES];
		
	}
	
	[self setNeedsDisplay:YES];
	
}
*/

- (void) insertLink:(NSString*)url title:(NSString*)text {
	
	//
	// used when dealing with a known url and title, pasteboard type WebURLsWithTitlesPboardType
	
	//
	// intercept this to check for a modifier key, present link dialog if down
	
	[self addURLLocToText:text http:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	
}

- (IBAction) insertLink:(id)sender {
	
	NSInteger result;
	LinkController *insertLink;
	
	NSString *linkString, *urlString, *encodedURL;
	
	if ( sender == self )
		insertLink = [[LinkController alloc] initWithLink:[lastURL absoluteString] URL:[lastURL absoluteString]];
	else
		insertLink = [[LinkController alloc] initWithLink:[[self string] substringWithRange:[self rangeForUserTextChange]] URL:nil];
	
	result = [insertLink runAsSheetForWindow:[self window] attached:YES];
	
	if ( result != NSRunStoppedResponse ) {
		[insertLink release];
		return;
	}
		
	//encodedURL = ( [insertLink URLString] ? [[insertLink URLString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] : @"" );
	encodedURL = ( [insertLink URLString] ? [insertLink URLString] : [NSString string] );
	if ( !encodedURL ) encodedURL = [NSString string];
	
	linkString = ( [insertLink linkString] ? [insertLink linkString] : [NSString string] );
	if ( [encodedURL isEqualToString:[NSString string]] )
		urlString = nil;
	else
		urlString = encodedURL;
	
	[self addURLLocToText:linkString http:urlString];
	
	// clean up
	[insertLink release];
	
}

#pragma mark -
#pragma mark Menus

- (NSMenu *)menuForEvent:(NSEvent *)theEvent 
{	
	// the menu we will return
	NSInteger item_index;
	NSMenu *returnMenu = [super menuForEvent:theEvent];
	
	// go ahead and get out of here if this menu is already built
	if ( [returnMenu itemWithTag:10000] )
		return returnMenu;

	// find the speaking item and take it out
	NSInteger speaking_item_index = -1;
	
	for ( item_index = 0; item_index < [returnMenu numberOfItems]; item_index++ ) 
	{
		if ( ![[returnMenu itemAtIndex:item_index] hasSubmenu] ) 
			continue;
		
		NSMenu *sub_menu = [[returnMenu itemAtIndex:item_index] submenu];
		
		if ( [sub_menu indexOfItemWithTarget:nil andAction:@selector(startSpeaking:)] != -1 ) 
		{
			speaking_item_index = item_index;
			break;
		}
	}

	NSMenuItem *speaking_item = nil;
	if ( speaking_item_index != -1 ) 
	{
		speaking_item = [[returnMenu itemAtIndex:speaking_item_index] retain];
		[returnMenu removeItem:speaking_item];
	}

	// find the spelling item
	NSInteger spelling_item_index = -1;
	
	for ( item_index = 0; item_index < [returnMenu numberOfItems]; item_index++ ) 
	{
		if ( ![[returnMenu itemAtIndex:item_index] hasSubmenu] ) 
			continue;
		
		NSMenu *sub_menu = [[returnMenu itemAtIndex:item_index] submenu];
		if ( [sub_menu indexOfItemWithTarget:nil andAction:@selector(showGuessPanel:)] != -1 ) 
		{
			spelling_item_index = item_index;
			break;
		}
	}
	
	// add the speaking item back after it along with a separator
	if ( spelling_item_index != -1 && speaking_item != nil ) 
	{
		[returnMenu insertItem:speaking_item atIndex:spelling_item_index+1];
		[returnMenu insertItem:[NSMenuItem separatorItem] atIndex:spelling_item_index+2];
	}

	// add the clear format item after spelling with a separator
	[returnMenu insertItemWithTitle:NSLocalizedString(@"menuitem remove formatting", @"") 
			action:@selector(removeFormatting:) keyEquivalent:@"" atIndex:spelling_item_index+3];
	[returnMenu insertItem:[NSMenuItem separatorItem] atIndex:spelling_item_index+4];
	
	// find out where this event occurred to add 
	NSUInteger char_index = [self _charIndexForDraggingLoc:[theEvent locationInWindow]];
	if ( char_index < [[self textStorage] length] ) 
	{
		// add some context sensitive menu action
		id link_attribute = [[self textStorage] attribute:NSLinkAttributeName atIndex:char_index effectiveRange:nil];
		if ( link_attribute != nil ) 
		{
			// link related action
			NSInteger edit_link_index = [returnMenu indexOfItemWithTarget:nil andAction:@selector(_openLinkFromMenu:)];
			if ( edit_link_index != -1 && ( [link_attribute isKindOfClass:[NSURL class]] /* && [link_attribute isJournlerResource] */ ) ) 
			{
				NSMenu *open_sub_menu = [[[NSMenu alloc] initWithTitle:NSLocalizedString(@"menuitem open link",@"")] autorelease];
				
				[open_sub_menu addItemWithTitle:NSLocalizedString(@"menuitem open tab",@"") 
						action:@selector(_openLinkFromMenu:) 
						keyEquivalent:@""];
				
				[open_sub_menu addItemWithTitle:NSLocalizedString(@"menuitem open new tab",@"") 
						action:@selector(openLinkInNewTab:)
						keyEquivalent:@""];
				
				[open_sub_menu addItemWithTitle:NSLocalizedString(@"menuitem open window",@"") 
						action:@selector(openLinkInNewWindow:) 
						keyEquivalent:@""];
						
				[open_sub_menu addItem:[NSMenuItem separatorItem]];
				
				[open_sub_menu addItemWithTitle:NSLocalizedString(@"menuitem finder reveal",@"") 
						action:@selector(revealLinkInFinder:) 
						keyEquivalent:@""];
				
				[open_sub_menu addItemWithTitle:NSLocalizedString(@"menuitem finder open",@"") 
						action:@selector(openLinkWithFinder:) 
						keyEquivalent:@""];
				
				NSMenuItem *open_sub_item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"menuitem open link",@"")
						action:@selector(_openLinkFromMenu:) 
						keyEquivalent:@""] autorelease];
				
				[[open_sub_menu itemArray] setValue:link_attribute forKey:@"representedObject"];
				
				[open_sub_item setSubmenu:open_sub_menu];
				
				[returnMenu removeItemAtIndex:edit_link_index];
				[returnMenu insertItem:open_sub_item atIndex:edit_link_index];
			}
		}
	}
	
	// add the insert menu after the paste menu
	NSInteger paste_link_index = [returnMenu indexOfItemWithTarget:nil andAction:@selector(paste:)];
	if ( paste_link_index != -1 )
	{
		// the insert menu
		NSMenu *insertMenu = [[[NSMenu alloc] initWithTitle:NSLocalizedString(@"menuitem insert", @"")] autorelease];
		
		NSMenuItem *insertMenuItem = [[[NSMenuItem alloc] 
				initWithTitle:NSLocalizedString(@"menuitem insert", @"") 
				action:nil 
				keyEquivalent:@""] autorelease];
	
		NSMenuItem *insertDate = [[[NSMenuItem alloc] 
				initWithTitle:NSLocalizedString(@"menuitem insert date", @"") 
				action:@selector(insertDateTime:) 
				keyEquivalent:@""] autorelease];
				
		NSMenuItem *insertTime = [[[NSMenuItem alloc] 
				initWithTitle:NSLocalizedString(@"menuitem insert time", @"") 
				action:@selector(insertDateTime:) 
				keyEquivalent:@""] autorelease];
				
		NSMenuItem *insertDateAndTime = [[[NSMenuItem alloc] 
				initWithTitle:NSLocalizedString(@"menuitem insert datetime", @"") 
				action:@selector(insertDateTime:) 
				keyEquivalent:@""] autorelease];
		
		[insertDate setTag:120];
		[insertTime setTag:121];
		[insertDateAndTime setTag:122];
		
		[insertMenu addItem:insertDate];
		[insertMenu addItem:insertTime];
		[insertMenu addItem:insertDateAndTime];
		[insertMenu addItem:[NSMenuItem separatorItem]];
		
		// add linebreak and paragraph break support
		[insertMenu addItemWithTitle:NSLocalizedString(@"menuitem insert linebreak", @"") 
				action:@selector(insertLineBreak:) 
				keyEquivalent:@""];
				
		[insertMenu addItemWithTitle:NSLocalizedString(@"menuitem insert paragraphbreak", @"") 
				action:@selector(insertNewline:) 
				keyEquivalent:@""];
				
		[insertMenu addItem:[NSMenuItem separatorItem]];
		
		// add list and table insert to the insert menu if 10.4
		[insertMenu addItemWithTitle:NSLocalizedString(@"menuitem table", @"") 
				action:@selector(orderFrontTablePanel:) 
				keyEquivalent:@""];
				
		[insertMenu addItemWithTitle:NSLocalizedString(@"menuitem list", @"") 
				action:@selector(orderFrontListPanel:) 
				keyEquivalent:@""];
				
		// add the insert url to the insert menu
		[insertMenu addItemWithTitle:NSLocalizedString(@"menuitem url", @"") 
				action:@selector(insertLink:) 
				keyEquivalent:@""];
		
		// add the checkbox item to the insert menu
		[insertMenu addItemWithTitle:NSLocalizedString(@"menuitem checkbox", @"") 
				action:@selector(insertCheckbox:) 
				keyEquivalent:@""];
				
		// add the insert menu as a submenu to the insert menu item
		[insertMenuItem setSubmenu:insertMenu];
		[insertMenuItem setTag:10000];

		[returnMenu insertItem:insertMenuItem atIndex:paste_link_index+1];
	}
	
	// find the font item and put highlight after it
	NSInteger font_item_index = -1;
	for ( item_index = 0; item_index < [returnMenu numberOfItems]; item_index++ ) 
	{
		if ( ![[returnMenu itemAtIndex:item_index] hasSubmenu] ) 
			continue;
		
		NSMenu *sub_menu = [[returnMenu itemAtIndex:item_index] submenu];
		if ( [sub_menu indexOfItemWithTarget:[NSFontManager sharedFontManager] andAction:@selector(orderFrontFontPanel:)] != -1 )
		{
			font_item_index = item_index;
			break;
		}
	}
	
	if ( font_item_index != -1 ) 
	{
		// highlight menu
		NSMenuItem *highlightItem = [LinksOnlyNSTextView highlightMenuItem];
		
		[highlightItem setAction:@selector(highlightSelection:)];
		[highlightItem setTarget:self];
		
		[returnMenu insertItem:highlightItem atIndex:font_item_index+1];
		
		// strike menu
		NSMenuItem *strikeItem = [[[NSMenuItem alloc] 
				initWithTitle:NSLocalizedString(@"menuitem strike", @"")
				action:@selector(strikeSelection:) 
				keyEquivalent:@""] autorelease];
				
		[strikeItem setTarget:self];
		[returnMenu insertItem:strikeItem atIndex:font_item_index];
	}
	
	// spacing
	NSMenu *spacing_sub = [[[NSMenu alloc] init] autorelease];
	
	NSMenuItem *spacing_item = [[[NSMenuItem alloc] 
			initWithTitle:NSLocalizedString(@"menuitem spacing no ellipse", @"") 
			action:@selector(orderFrontSpacingPanel:) 
			keyEquivalent:@""] autorelease];
	
	NSMenuItem *spacing_single = [[[NSMenuItem alloc] 
			initWithTitle:NSLocalizedString(@"menuitem space single",@"") 
			action:@selector(setSpacing:) 
			keyEquivalent:@""] autorelease];
	
	NSMenuItem *spacing_half = [[[NSMenuItem alloc] 
			initWithTitle:NSLocalizedString(@"menuitem space single half",@"") 
			action:@selector(setSpacing:) 
			keyEquivalent:@""] autorelease];
	
	NSMenuItem *double_half = [[[NSMenuItem alloc] 
			initWithTitle:NSLocalizedString(@"menuitem space double",@"") 
			action:@selector(setSpacing:) 
			keyEquivalent:@""] autorelease];
	
	[spacing_single setTag:621];
	[spacing_half setTag:622];
	[double_half setTag:623];
	
	[spacing_sub addItem:spacing_single];
	[spacing_sub addItem:spacing_half];
	[spacing_sub addItem:double_half];
	
	[spacing_sub addItem:[NSMenuItem separatorItem]];
	[spacing_sub addItemWithTitle:NSLocalizedString(@"menuitem spacing", @"") action:@selector(orderFrontSpacingPanel:) keyEquivalent:@""];
	
	[spacing_item setSubmenu:spacing_sub];
	
	[returnMenu addItem:spacing_item];
	
	// a separator
	[returnMenu addItem:[NSMenuItem separatorItem]];
	
	// the tag entry menu
	NSMenuItem *tagEntryItem = [[[NSMenuItem alloc] 
			initWithTitle:NSLocalizedString(@"menuitem tag entry",@"") 
			action:@selector(tagEntryWithSelection:) 
			keyEquivalent:@""] autorelease];
	
	[tagEntryItem setTarget:self];
	[returnMenu addItem:tagEntryItem];
	
	// the scripts menu
	NSMenu *scriptsMMSubmenu = nil;
	NSMenuItem *scriptsMMItem = [[NSApp mainMenu] itemWithTag:99];
	if ( scriptsMMItem )
		scriptsMMSubmenu = [scriptsMMItem submenu];
	
	if ( scriptsMMSubmenu ) 
	{
		// build the scripts menu if one is available
		NSMenuItem *insertMenuItem = [[[NSMenuItem alloc] 
				initWithTitle:NSLocalizedString(@"menuitem scripts", @"") 
				action:nil 
				keyEquivalent:@""] autorelease];
				
		[insertMenuItem setSubmenu:[[scriptsMMSubmenu copyWithZone:[self zone]] autorelease]];
		
		// inser the item into the menu
		[returnMenu addItem:insertMenuItem];
	}
	
	// the link menu
	NSMenu *linkToSubMenu = [(JournlerCollection*)[self valueForKeyPath:@"entry.journal.rootCollection"] 
			menuRepresentation:self 
			action:@selector(linkToEntryFromMenu:) 
			smallImages:YES 
			includeEntries:YES];
	
	NSMenuItem *linkToMenuItem = [[[NSMenuItem alloc] 
			initWithTitle:NSLocalizedString(@"menuitem linkto", @"") 
			action:@selector(linkToEntryFromMenu:) 
			keyEquivalent:@""] autorelease];
	
	[linkToMenuItem setTarget:self];
	[linkToMenuItem setAction:@selector(linkToEntryFromMenu:)];
	[linkToMenuItem setRepresentedObject:nil];
	
	//[linkToMenuItem setTag:kLexiconMenuItemTag];
	//[linkToMenuItem setRepresentedObject:selection];
	
	[linkToMenuItem setSubmenu:linkToSubMenu];
	[returnMenu addItem:linkToMenuItem];
	
	// the lexicon menu, but only if a single term is selected
	if ( [self selectedRange].length > 0 && [[self delegate] respondsToSelector:@selector(textView:showLexiconSelection:term:)] )
	{
		NSString *selection = [[self string] substringWithRange:[self selectedRange]];
		if ( [selection rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location == NSNotFound )
		{
			NSMenu *lexiconMenu = [[[NSMenu alloc] initWithTitle:NSLocalizedString(@"menuitem lexicon", @"")] autorelease];
			[lexiconMenu setDelegate:[self valueForKeyPath:@"entry.journal.indexServer"]];
			
			NSMenuItem *lexiconMenuItem = [[[NSMenuItem alloc] 
					initWithTitle:NSLocalizedString(@"menuitem lexicon", @"") 
					action:nil 
					keyEquivalent:@""] autorelease];
			
			[lexiconMenuItem setTag:kLexiconMenuItemTag];
			[lexiconMenuItem setTarget:self];
			[lexiconMenuItem setAction:@selector(_showObjectFromLexicon:)];
			[lexiconMenuItem setRepresentedObject:selection];
			
			[lexiconMenuItem setSubmenu:lexiconMenu];
			[returnMenu addItem:lexiconMenuItem];
		}
	}
	
	return returnMenu;
}

+ (NSMenuItem*) highlightMenuItem
{
	// once the individual highlight items have been built, create the actual menu item and its submenu
	NSMenu *highlightMenu = [[[NSMenu alloc] initWithTitle:NSLocalizedString(@"menuitem highlight", @"")] autorelease];
	NSMenuItem *highlightItem = [[[NSMenuItem alloc] 
			initWithTitle:NSLocalizedString(@"menuitem highlight", @"") 
			action:nil 
			keyEquivalent:@""] autorelease];
	
	NSMenuItem *highlightYellow = [[[NSMenuItem alloc] 
			initWithTitle:NSLocalizedString(@"menuitem yellow", @"") 
			action:@selector(highlightSelection:) 
			keyEquivalent:@""] autorelease];
			
	[highlightYellow setTag:351];
	[highlightMenu addItem:highlightYellow];
		
	NSMenuItem *highlightBlue = [[[NSMenuItem alloc] 
			initWithTitle:NSLocalizedString(@"menuitem blue", @"") 
			action:@selector(highlightSelection:) 
			keyEquivalent:@""] autorelease];
			
	[highlightBlue setTag:352];
	[highlightMenu addItem:highlightBlue];
	
	NSMenuItem *highlightGreen = [[[NSMenuItem alloc] 
			initWithTitle:NSLocalizedString(@"menuitem green", @"") 
			action:@selector(highlightSelection:) 
			keyEquivalent:@""] autorelease];
			
	[highlightGreen setTag:353];
	[highlightMenu addItem:highlightGreen];
	
	NSMenuItem *highlightOrange = [[[NSMenuItem alloc] 
			initWithTitle:NSLocalizedString(@"menuitem orange", @"") 
			action:@selector(highlightSelection:) 
			keyEquivalent:@""] autorelease];
			
	[highlightOrange setTag:354];
	[highlightMenu addItem:highlightOrange];
	
	NSMenuItem *highlightRed = [[[NSMenuItem alloc] 
			initWithTitle:NSLocalizedString(@"menuitem red", @"") 
			action:@selector(highlightSelection:) 
			keyEquivalent:@""] autorelease];
			
	[highlightRed setTag:355];
	[highlightMenu addItem:highlightRed];
	
	[highlightMenu addItem:[NSMenuItem separatorItem]];
		
	NSMenuItem *highlightClear = [[[NSMenuItem alloc] 
			initWithTitle:NSLocalizedString(@"menuitem clear", @"") 
			action:@selector(highlightSelection:) 
			keyEquivalent:@""] autorelease];
			
	[highlightClear setTag:356];
	[highlightMenu addItem:highlightClear];

	[[NSApp delegate] prepareHighlightMenu:&highlightMenu];
	[highlightItem setSubmenu:highlightMenu];
	
	return highlightItem;
}

- (IBAction) _showObjectFromLexicon:(id)sender
{
	JournlerObject *anObject = [sender representedObject];
	
	// modifiers should support opening the item in windows, tabs, etc
	// the item should be opened and the terms highlighted and located
	
	if ( anObject == nil || ![[self delegate] respondsToSelector:@selector(textView:showLexiconSelection:term:)] )
	{
		NSBeep();
	}
	else
	{
		[[self delegate] textView:self showLexiconSelection:anObject term:[self valueForKeyPath:@"entry.journal.indexServer.lexiconMenuRepresentedTerm"]];
	}
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem 
{
	NSInteger theTag = [menuItem tag];
	SEL action = [menuItem action];
	BOOL enabled = YES;
	
	if ( action == @selector(copyAsHTML:) )
		enabled = [self rangeForUserTextChange].length != 0;
		
	else if ( action == @selector(performCustomTextSizeAction:) )
	{
		if ( theTag == 99 )
			enabled = NO;
	}
	
	else if ( action == @selector(changeFont:) )
	{
		if ( theTag == 5 )
			enabled = NO;
		else
			enabled = [super validateMenuItem:menuItem];
	}
	
	else if ( action == @selector(revealLinkInFinder:) || action == @selector(openLinkWithFinder:) )
	{
		NSURL *link_attribute = [menuItem representedObject];
		if ( link_attribute == nil ) 
			enabled = NO;
		else if ( [link_attribute isKindOfClass:[NSURL class]] )
		{
			enabled = YES;
			
			if ( action == @selector(revealLinkInFinder:) )
				enabled = ( [link_attribute isJournlerResource] || [link_attribute isFileURL] );
			
			else if ( action == @selector(openLinkWithFinder:) )
				enabled = ( ![link_attribute isJournlerEntry] && ![link_attribute isJournlerFolder] );
			
		}
	}
	
	else if ( action == @selector(tagEntryWithSelection:) )
		enabled = ( [self selectedRange].length != 0 );
	
	else if ( action == @selector(startSpeaking:) )
		enabled = ![highlightSpeechSynthesizer isSpeaking];
		
	else if ( action == @selector(stopSpeaking:) )
		enabled = [highlightSpeechSynthesizer isSpeaking];
	
	else
		enabled = [super validateMenuItem:menuItem];
		
	return ( enabled && [self isEditable] );
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem 
{	
	BOOL enabled = YES;
	return ( enabled && [self isEditable] );
}

#pragma mark -

- (IBAction) modifyingAttributes:(NSDictionary*)attributes 
{	
	[[self textStorage] beginEditing];
	[[self textStorage] setAttributes:attributes range:[self rangeForUserTextChange]];
	[[self textStorage] endEditing];	
}

//
// 1.1.5 addition

- (void) applyDefaultStyleAndRuler {
	
	if ( [self rangeForUserTextChange].length == 0 )
		[self setTypingAttributes:[JournlerEntry defaultTextAttributes]];
	else {
		[self applyDefaultStyle:self];
		[self applyDefaultRuler:self];
	}
}

- (IBAction) applyDefaultStyle:(id)sender {
	
	//
	// build the font characteristics from the user defaults, apply them to the selection
	
	NSDictionary *defaultStyle = [JournlerEntry defaultTextAttributes];
		
	//
	// make sure we're allowed to change and alert the system that a change is coming
	if ( ![self shouldChangeTextInRanges:[self rangesForUserCharacterAttributeChange] replacementStrings:nil] ) {
		BeepAndBail();
	}
	
	//
	// set the font for the appropriate range
	if ( [self rangeForUserTextChange].length == 0 ) {
		NSMutableDictionary *attrs = [[self typingAttributes] mutableCopyWithZone:[self zone]];
		[attrs setObject:[defaultStyle objectForKey:NSFontAttributeName] forKey:NSFontAttributeName];
		[attrs setObject:[defaultStyle objectForKey:NSForegroundColorAttributeName] forKey:NSForegroundColorAttributeName];
		[self setTypingAttributes:attrs];
		[attrs release];
	}
	else {	
		[self setFont:[defaultStyle objectForKey:NSFontAttributeName] ranges:[self rangesForUserCharacterAttributeChange]];
		[self setTextColor:[defaultStyle objectForKey:NSForegroundColorAttributeName] ranges:[self rangesForUserCharacterAttributeChange]];
	}
	
	//
	// let folks know what's happened
	[self didChangeText];
	
}

- (IBAction) applyDefaultRuler:(id)sender {
	
	
	NSDictionary *defaultStyle = [[NSUserDefaults standardUserDefaults] defaultEntryAttributes];
	NSParagraphStyle *defaultParagraph = [defaultStyle objectForKey:NSParagraphStyleAttributeName];
	if ( !defaultParagraph ) {
		BeepAndBail();
	}
	
	//
	// make sure we're allowed to change and alert the system that a change is coming
	if ( ![self shouldChangeTextInRanges:[self rangesForUserParagraphAttributeChange] replacementStrings:nil] ) 
	{
		NSBeep();
	}
	else
	{
		if ( [self rangeForUserTextChange].length == 0 ) 
		{
			NSMutableDictionary *attrs = [[self typingAttributes] mutableCopyWithZone:[self zone]];
			[attrs setObject:defaultParagraph forKey:NSParagraphStyleAttributeName];
			[self setTypingAttributes:attrs];
			[attrs release];
		}
		else 
		{
			[[self textStorage] beginEditing];
			[[self textStorage] addAttribute:NSParagraphStyleAttributeName value:defaultParagraph ranges:[self rangesForUserParagraphAttributeChange]];
			[[self textStorage] endEditing];
		}
	
		// let folks know what's happened
		[self didChangeText];
	}
}

#pragma mark -

- (void)setFont:(NSFont *)aFont
{
	// overridden to check for nil font and defaults to system font if that's the case
	[super setFont:( aFont != nil ? aFont : [NSFont systemFontOfSize:[NSFont systemFontSize]] )];
}

#pragma mark -

- (IBAction) setDefaultRuler:(id) sender {
	
	//
	// take the current paragraph and make it the default paragraph
	NSParagraphStyle *currentParagraph = [[self textStorage] attribute:NSParagraphStyleAttributeName 
			atIndex:[self rangeForUserParagraphAttributeChange].location effectiveRange:nil];
	if ( currentParagraph == nil ) {
		BeepAndBail();
	}
	
	NSData *paragraphData = [NSArchiver archivedDataWithRootObject:currentParagraph];
	if ( paragraphData == nil ) {
		BeepAndBail();
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:paragraphData forKey:@"DefaultEntryParagraphStyle"];
	
}

- (IBAction) setDefaultFont:(id) sender {
	
	//
	// take the current font and make it the default font
	NSFont *currentFont = [[self attributesAtRangeForUserTextChange] 
			objectForKey:NSFontAttributeName];
	if ( currentFont == nil ) {
		BeepAndBail();
	}
	
	NSData *fontData = [NSArchiver archivedDataWithRootObject:currentFont];
	if ( fontData == nil ) {
		BeepAndBail();
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:fontData forKey:@"DefaultEntryFont"];
	
	//
	// take the current color and make it the default color
	NSFont *currentColor = [[self attributesAtRangeForUserTextChange]
			objectForKey:NSForegroundColorAttributeName];
	if ( currentColor == nil ) {
		BeepAndBail();
	}
	
	NSData *colorData = [NSArchiver archivedDataWithRootObject:currentColor];
	if ( colorData == nil ) {
		BeepAndBail();
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:colorData forKey:@"Entry Text Color"];
	
}

#pragma mark -

- (IBAction) openLinkInNewTab:(id)sender
{
	NSInteger char_index = [self rangeForUserTextChange].location;
	NSUInteger lastModifiers = [self modifierFlags];
		
	[self setModifierFlags:(NSCommandKeyMask)];
	[self clickedOnLink:[[self textStorage] attribute:NSLinkAttributeName atIndex:char_index effectiveRange:nil] atIndex:char_index];
	[self setModifierFlags:lastModifiers];

}

- (IBAction) openLinkInNewWindow:(id)sender 
{	
	NSInteger char_index = [self rangeForUserTextChange].location;
	NSUInteger lastModifiers = [self modifierFlags];
		
	[self setModifierFlags:(NSAlternateKeyMask|NSCommandKeyMask)];
	[self clickedOnLink:[[self textStorage] attribute:NSLinkAttributeName atIndex:char_index effectiveRange:nil] atIndex:char_index];
	[self setModifierFlags:lastModifiers];
}

- (IBAction) revealLinkInFinder:(id)sender 
{
	
	id link = [[self textStorage] attribute:NSLinkAttributeName atIndex:[self rangeForUserTextChange].location effectiveRange:nil];
	
	if ( !link || ![link isKindOfClass:[NSURL class]] )
	{ 
		NSBeep(); 
		NSLog(@"%s - do not understand link %@", __PRETTY_FUNCTION__, link);
		return;
	}
	
	if ( [link isJournlerResource] )
	{
		JournlerResource *aResource = [[self valueForKeyPath:@"entry.journal"] objectForURIRepresentation:link];
		if ( aResource == nil )
		{
			NSBeep(); 
			NSLog(@"%s - unable to derive resoure for link %@", __PRETTY_FUNCTION__, [(NSURL*)link absoluteString]);
			return;
		}
		
		// the resource knows how to handle itself
		[aResource revealInFinder];
	}
	else
	{
		// just send it to the workspace, depending on path status
		if ( [link isFileURL] )
			[[NSWorkspace sharedWorkspace] selectFile:[link path] inFileViewerRootedAtPath:[[link path] stringByDeletingLastPathComponent]];
		else
			[[NSWorkspace sharedWorkspace] openURL:link];
	}
}

- (IBAction) openLinkWithFinder:(id)sender 
{	
	id link = [[self textStorage] attribute:NSLinkAttributeName atIndex:[self rangeForUserTextChange].location effectiveRange:nil];
	
	if ( !link || ![link isKindOfClass:[NSURL class]] )
	{ 
		NSBeep(); 
		NSLog(@"%s - do not understand link %@", __PRETTY_FUNCTION__, link);
		return;
	}
	
	if ( [link isJournlerResource] )
	{
		JournlerResource *aResource = [[self valueForKeyPath:@"entry.journal"] objectForURIRepresentation:link];
		if ( aResource == nil )
		{
			NSBeep(); 
			NSLog(@"%s - unable to derive resoure for link %@", __PRETTY_FUNCTION__, [(NSURL*)link absoluteString]);
			return;
		}
	
		// the resource knows how to open itself
		[aResource openWithFinder];
	}
	
	else
	{
		// just send it to the workspace
		[[NSWorkspace sharedWorkspace] openURL:link];
	}
}

#pragma mark -

- (IBAction) removeFormatting:(id)sender {
	
	//
	// make sure we're allowed to change and alert the system that a change is coming
	if ( ![self shouldChangeTextInRanges:[self rangesForUserCharacterAttributeChange] replacementStrings:nil] || [self rangeForUserTextChange].length == 0 ) 
	{
		NSBeep();
	}
	else 
	{
		NSFont *original_font = [[self textStorage] attribute:NSFontAttributeName 
				atIndex:[self rangeForUserTextChange].location effectiveRange:nil];
		
		NSFont *stripped_font = [[NSFontManager sharedFontManager] 
				convertFont:original_font toNotHaveTrait:(NSItalicFontMask|NSBoldFontMask)];
		
		NSParagraphStyle *paragraph = [NSParagraphStyle defaultParagraphStyle];
		
		NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
				stripped_font, NSFontAttributeName, paragraph, NSParagraphStyleAttributeName, nil];
		
		[[self textStorage] beginEditing];
		
		NSInteger i;
		NSArray *ranges = [self rangesForUserTextChange];
		for ( i = 0; i < [ranges count]; i++ ) 
		{
			NSRange aRange = [[ranges objectAtIndex:i] rangeValue];
			
			NSString *selected_text = [[[self textStorage] string] substringWithRange:aRange];
			NSAttributedString *attr_string = [[[NSAttributedString alloc] initWithString:selected_text attributes:attrs] autorelease];
			
			[[self textStorage] replaceCharactersInRange:aRange withAttributedString:attr_string];
		}
		
		[[self textStorage] endEditing];
		[self didChangeText];
	}
}

- (IBAction) setSpacing:(id)sender {
	
	//
	// make sure we're allowed to change and alert the system that a change is coming
	if ( ![self shouldChangeTextInRanges:[self rangesForUserParagraphAttributeChange] replacementStrings:nil] ) {
		BeepAndBail();
	}
	
	float multiple = 1.0;
	
	switch ( [sender tag] ) {
	
	case 621:
		multiple = 1.0;
		break;
	
	case 622:
		multiple = 1.5;
		break;
	
	case 623:
		multiple = 2.0;
		break;
	
	}
	
	NSParagraphStyle *original_style = [[self textStorage] attribute:NSParagraphStyleAttributeName 
	atIndex:[self rangeForUserParagraphAttributeChange].location effectiveRange:nil];
	
	if ( original_style == nil ) original_style = [NSParagraphStyle defaultParagraphStyle];
	
	NSMutableParagraphStyle *new_style = [[original_style mutableCopyWithZone:[self zone]] autorelease];
	[new_style setLineHeightMultiple:multiple];
	
	[[self textStorage] beginEditing];
	[[self textStorage] addAttribute:NSParagraphStyleAttributeName value:new_style ranges:[self rangesForUserParagraphAttributeChange]];
	[[self textStorage] endEditing];
	
	[self didChangeText];
	
}

- (NSString*) _linkedTextForAudioFile:(NSString*)fullpath {
	
	//
	// have a look at the metadata for the file, author and name, or use display name
	
	NSMutableString *return_string = [[NSMutableString allocWithZone:[self zone]] init];
	
	MDItemRef meta_data = MDItemCreate(NULL,(CFStringRef)fullpath);
	if ( meta_data != NULL ) {
		
		NSString *title = (NSString*)MDItemCopyAttribute(meta_data,kMDItemTitle);
		NSArray *authors = (NSArray*)MDItemCopyAttribute(meta_data,kMDItemAuthors);
		NSString *composer = (NSString*)MDItemCopyAttribute(meta_data,kMDItemComposer);
		
		if ( title != nil ) {
			
			if ( authors != nil )
				[return_string appendFormat:@"%@ - ", [authors componentsJoinedByString:@", "]];
			else if ( composer != nil )
				[return_string appendFormat:@"%@ - ", composer];
			
			[return_string appendString:title];
			
		}
		else {
			
			// use the display name no path
			[return_string appendString:[[fullpath lastPathComponent] stringByDeletingPathExtension]];
			
		}
		
		//
		// clean up
		CFRelease(meta_data);
		
	}
	else {
		
		//
		// use the display name no path
		[return_string appendString:[[fullpath lastPathComponent] stringByDeletingPathExtension]];
		
	}
	
	return [return_string autorelease];
}

- (NSString*) _mdTitleFoFileAtPath:(NSString*)fullpath {
	
	//
	// have a look at the metadata for the file, author and name, or use display name
	
	NSString *title = nil;
	
	MDItemRef meta_data = MDItemCreate(NULL,(CFStringRef)fullpath);
	if ( meta_data != NULL ) 
	{
		// grab the title
		title = [(NSString*)MDItemCopyAttribute(meta_data,kMDItemTitle) autorelease];
		// clean up
		CFRelease(meta_data);
	}
	else 
	{
		// use the display name no path
		title = [[fullpath lastPathComponent] stringByDeletingPathExtension];
	}
	
	return title;
}

- (IBAction) scaleText:(id)sender 
{	
	float scaleValue = ((float)[sender tag])/100.00;
	float correctedScale = scaleValue / [self lastScale];
	
	[self scaleUnitSquareToSize:NSMakeSize(correctedScale,correctedScale)];
	[[NSNotificationCenter defaultCenter] postNotificationName:NSViewFrameDidChangeNotification object:self];
	[[self enclosingScrollView] setNeedsDisplay:YES];
	
	[self setLastScale:scaleValue];
}

#pragma mark -


- (IBAction) makeBlockQuote:(id)sender 
{	
	if ( ![self shouldChangeTextInRange:[self rangeForUserParagraphAttributeChange] replacementString:nil] )
	{
		NSBeep(); return;
	}

	NSParagraphStyle *original_paragraph_style = [[self textStorage] attribute:NSParagraphStyleAttributeName 
			atIndex:[self rangeForUserParagraphAttributeChange].location effectiveRange:nil];
			
	if ( !original_paragraph_style ) 
		original_paragraph_style = [[JournlerEntry defaultTextAttributes] objectForKey:NSParagraphStyleAttributeName];
	
	NSMutableParagraphStyle *edited_paragraph_style = [[original_paragraph_style mutableCopyWithZone:[self zone]] autorelease];
	
	float head_indent;
	float tail_indent;
	
	head_indent=30.0;
	tail_indent=-30.0;
	
	[edited_paragraph_style setHeadIndent:head_indent];
	[edited_paragraph_style setFirstLineHeadIndent:head_indent];
	[edited_paragraph_style setTailIndent:tail_indent];

	[[self textStorage] beginEditing];
	[[self textStorage] addAttribute:NSParagraphStyleAttributeName value:edited_paragraph_style range:[self rangeForUserParagraphAttributeChange]];
	[[self textStorage] endEditing];
	
	[self didChangeText];
	
}

- (IBAction) modifyCharacterCase:(id)sender
{
	if ( ![self shouldChangeTextInRanges:[self rangesForUserTextChange] replacementStrings:[[self string] substringsWithRanges:[self rangesForUserTextChange]]] )
	{
		NSBeep(); return;
	}
	
	NSInteger operation = [sender tag];
	
    [[self textStorage] beginEditing];
    
    for ( NSValue *rangeValue in [self rangesForUserTextChange] )
	{
		NSRange aRange = [rangeValue rangeValue];
		
		NSString *replacementString = nil;
		NSString *aString = [[self string] substringWithRange:aRange];
		
		if ( operation == 1 )
			replacementString = [aString uppercaseString];
		else if ( operation == 2 )
			replacementString = [aString lowercaseString];
		
		if ( replacementString != nil )
			[[self textStorage] replaceCharactersInRange:aRange withString:replacementString];
	}
	
	[[self textStorage] endEditing];
	[self didChangeText];
	
	//[self setSelectedRanges:ranges];
}

- (IBAction) modifyCharacterSpacing:(id)sender
{
	if ( ![self shouldChangeTextInRange:[self rangeForUserCharacterAttributeChange] replacementString:nil] ) {
		NSBeep();
		return;
	}
	
	NSInteger operation = [sender tag];
		
	NSNumber *newExpansion;
	NSNumber *originalExpansion = [[self textStorage] attribute:NSExpansionAttributeName 
			atIndex:[self rangeForUserTextChange].location effectiveRange:nil];
	
	if ( !originalExpansion )
		originalExpansion = [NSNumber numberWithFloat:0.0];
	
	if ( operation == 1 )
		newExpansion = [NSNumber numberWithFloat:[originalExpansion floatValue] + 0.1];
	else if ( operation == 2 )
		newExpansion = [NSNumber numberWithFloat:[originalExpansion floatValue] - 0.1];
	
	[[self textStorage] beginEditing];
	[[self textStorage] addAttribute:NSExpansionAttributeName value:newExpansion range:[self rangeForUserCharacterAttributeChange]];	
	[[self textStorage] endEditing];
	
	[self didChangeText];
}

- (IBAction) linkToEntryFromMenu:(id)sender
{
	// grab the uri representation and add it to the selected text
	
	id theObject = [sender representedObject];
	NSURL *uri = [[sender representedObject] URIRepresentation];
	
	if ( theObject == nil || uri == nil )
	{
		NSBeep();
		NSLog(@"%s - unable to derive uri from menu's represented object", __PRETTY_FUNCTION__ );
		return;
	}
	
	if ( [self rangeForUserCharacterAttributeChange].length != 0 )
	{
		if ( ![self shouldChangeTextInRange:[self rangeForUserCharacterAttributeChange] replacementString:nil] )
		{
			NSBeep();
			return;
		}
	
		[[self textStorage] beginEditing];
		[[self textStorage] addAttribute:NSLinkAttributeName value:uri range:[self rangeForUserCharacterAttributeChange]];	
		[[self textStorage] endEditing];
		
		[self didChangeText];
	}
	else
	{
		NSDictionary *attributes = [NSDictionary dictionaryWithObject:uri forKey:NSLinkAttributeName];
		[self insertText:[theObject valueForKey:@"title"] image:nil attributes:attributes];
	}
	
	// establish a link & reverse link to the item if this is an entry or a resource, note the resource is not actually used
	JournlerResource *resource = [[self entry] resourceForJournlerObject:theObject];
	if ( resource == nil )
	{
		NSLog(@"%s - unable to produce new resource for uri %@", __PRETTY_FUNCTION__, [uri absoluteString]);
		return;
	}
}

#pragma mark -

- (void)setSelectedRange:(NSRange)charRange affinity:(NSSelectionAffinity)affinity stillSelecting:(BOOL)flag
{
	if ( [self continuouslyPostsSelectionNotification] && flag )
	{
		NSDictionary *userInfo = [NSDictionary 
				dictionaryWithObject:[NSValue valueWithRange:[self selectedRange]] forKey:@"NSOldSelectedCharacterRange"];
		NSNotification *aNotification = [NSNotification 
				notificationWithName:NSTextViewDidChangeSelectionNotification object:self userInfo:userInfo];
		
		if ( [[self delegate] respondsToSelector:@selector(textViewDidChangeSelection:)] )
			[[self delegate] textViewDidChangeSelection:aNotification];
	}
	
	[super setSelectedRange:charRange affinity:affinity stillSelecting:flag];
}

- (void)setSelectedRanges:(NSArray *)ranges affinity:(NSSelectionAffinity)affinity stillSelecting:(BOOL)stillSelectingFlag
{
	if ( [self continuouslyPostsSelectionNotification] && stillSelectingFlag )
	{
		NSDictionary *userInfo = [NSDictionary 
				dictionaryWithObject:[NSValue valueWithRange:[self selectedRange]] forKey:@"NSOldSelectedCharacterRange"];
		NSNotification *aNotification = [NSNotification 
				notificationWithName:NSTextViewDidChangeSelectionNotification object:self userInfo:userInfo];
		
		if ( [[self delegate] respondsToSelector:@selector(textViewDidChangeSelection:)] )
			[[self delegate] textViewDidChangeSelection:aNotification];
	}

	[super setSelectedRanges:ranges affinity:affinity stillSelecting:stillSelectingFlag];
}

- (NSInteger)spellCheckerDocumentTag
{
	return [[NSApp delegate] spellDocumentTag];
}

#pragma mark -

- (void)setTypingAttributes:(NSDictionary *)attributes
{
	// a fix for the re-set typing attributes problem when new-lining or tabbing during lists
	// is it possible this is causing problems?
	
	//#ifdef __DEBUG__
	//NSLog(@"old attributes: %@", [[self typingAttributes] description]);
	//NSLog(@"");
	//NSLog(@"new attributes: %@", [attributes description]);
	//#endif
	
	BOOL overrideAttributes = NO;
	NSParagraphStyle *paragraphStyle = [attributes objectForKey:NSParagraphStyleAttributeName];
	
	if ( paragraphStyle != nil )
	{
		NSArray *textLists = [paragraphStyle textLists];
		if ( [textLists count] != 0 )
		{
			NSRange theSelectionRange = [self selectedRange];
			if ( theSelectionRange.location >= 1 )
			{
				unichar aChar = [[self string] characterAtIndex:theSelectionRange.location-1];
				if ( aChar == NSTabCharacter ) // -- and it seems to always be the case for the bug we're dealing with
				{
					NSFont *previousFont = [[self typingAttributes] objectForKey:NSFontAttributeName];
					if ( previousFont != nil )
					{
						overrideAttributes = YES;
						NSMutableDictionary *betterAttributes = [[attributes mutableCopyWithZone:[self zone]] autorelease];
						[betterAttributes setObject:previousFont forKey:NSFontAttributeName];
						[super setTypingAttributes:betterAttributes];
					}
				}
				
				#ifdef __DEBUG__
				//NSTabCharacter NSNewlineCharacter NSCarriageReturnCharacter NSEnterCharacter
				switch ( aChar )
				{
				case NSTabCharacter:
					NSLog(@"%s - NSTabCharacter", __PRETTY_FUNCTION__);
					break;
				case NSNewlineCharacter:
					NSLog(@"%s - NSNewlineCharacter", __PRETTY_FUNCTION__);
					break;
				case NSCarriageReturnCharacter:
					NSLog(@"%s - NSCarriageReturnCharacter", __PRETTY_FUNCTION__);
					break;
				case NSEnterCharacter:
					NSLog(@"%s - NSEnterCharacter", __PRETTY_FUNCTION__);
					break;
				}
				#endif
			}
		}
	}
	
	if ( overrideAttributes == NO )
		[super setTypingAttributes:attributes];
}

#pragma mark -

- (IBAction) tagEntryWithSelection:(id)sender
{
	JournlerEntry *theEntry = [self entry];
	NSRange selectionRange = [self rangeForUserTextChange];
	
	if ( theEntry == nil || selectionRange.length == 0 )
		NSBeep();
	else
	{
		NSString *theTag = [[self string] substringWithRange:selectionRange];
		if ( ![[theEntry tags] containsObject:theTag] )
		{	
			NSMutableArray *entryTags = [[theEntry valueForKey:@"tags"] mutableCopyWithZone:[self zone]];
			[entryTags addObject:theTag];
			[theEntry setValue:entryTags forKey:@"tags"];
		}
	}
}


#pragma mark
#pragma mark Speech Services

- (IBAction) startSpeaking:(id)sender
{
	if ( [NSSpeechSynthesizer isAnyApplicationSpeaking] )
		NSBeep();
	else
	{
		NSString *spokenText = nil;
		highlightSpeechSynthesizer = [[NSSpeechSynthesizer alloc] initWithVoice:[NSSpeechSynthesizer defaultVoice]];
		
		// save the old selection attributes and set new ones
		if ( selectedRangeAttributes != nil )
		{
			[selectedRangeAttributes release];
			selectedRangeAttributes = nil;
		}
		
		selectedRangeAttributes = [[self selectedTextAttributes] copyWithZone:[self zone]];
			
		NSDictionary *spokenAttributes = [NSMutableDictionary dictionaryWithDictionary:selectedRangeAttributes];
		[(NSMutableDictionary*)spokenAttributes setObject:[NSColor yellowColor] forKey:NSBackgroundColorAttributeName];
		[self setSelectedTextAttributes:spokenAttributes];
		
		// get the range
		if ( [self selectedRange].length != 0 )
		{
			spokenRange = [self selectedRange];
			spokenText = [[self string] substringWithRange:spokenRange];
		}
		else
		{
			spokenText = [self string];
			spokenRange = NSMakeRange(0,[spokenText length]);
		}
		
		// begin speaking
		[highlightSpeechSynthesizer setDelegate:self];
		[highlightSpeechSynthesizer startSpeakingString:spokenText];
	}
}

- (IBAction) stopSpeaking:(id)sender
{
	if ( highlightSpeechSynthesizer != nil )
	{
		[highlightSpeechSynthesizer stopSpeaking];
		[highlightSpeechSynthesizer release];
		highlightSpeechSynthesizer = nil;
		
		[self setSelectedTextAttributes:selectedRangeAttributes];
		[selectedRangeAttributes release];
		selectedRangeAttributes = nil;
		
		NSRange selectedRange = [self selectedRange];
		selectedRange.location += selectedRange.length;
		selectedRange.length = 0;
		[self setSelectedRange:selectedRange];
	}
}

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)success
{
	if ( highlightSpeechSynthesizer != nil )
	{
		[highlightSpeechSynthesizer release];
		highlightSpeechSynthesizer = nil;
		
		[self setSelectedTextAttributes:selectedRangeAttributes];
		[selectedRangeAttributes release];
		selectedRangeAttributes = nil;
		
		NSRange selectedRange = [self selectedRange];
		selectedRange.location += selectedRange.length;
		selectedRange.length = 0;
		[self setSelectedRange:selectedRange];
	}
}

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender willSpeakWord:(NSRange)wordToSpeak ofString:(NSString *)text
{
	NSRange highlightedRange = NSMakeRange( spokenRange.location + wordToSpeak.location, wordToSpeak.length );
	[self setSelectedRange:highlightedRange];
	
	//if ( [self respondsToSelector:@selector(showFindIndicatorForRange:)] )
	//	[self showFindIndicatorForRange:highlightedRange];
	//else
	//	[self setSelectedRange:highlightedRange];
}

@end
