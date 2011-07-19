#import "ImportReviewController.h"
#import "JournlerApplicationDelegate.h"

#import <SproutedUtilities/SproutedUtilities.h>

#import "JournlerEntry.h"
#import "JournlerCollection.h"
#import "JournlerJournal.h"
#import "JournlerSearchManager.h"

#import "ImportReviewTable.h"
#import "ImportReviewSourceList.h"
#import "BrowseTableFieldEditor.h"


#import "Definitions.h"

#define kSourceListSmallHeight		20.0
#define kSourceListSeparatorHeight	10.0

@implementation ImportReviewController

- (id) init
{
	return [self initWithJournal:nil folders:nil entries:nil];
}

- (id) initWithJournal:(JournlerJournal*)aJournal folders:(NSArray*)theFolders entries:(NSArray*)theEntries
{
	// designated initializer
	if ( self = [self initWithWindowNibName:@"BulkImportReview"] ) 
	{
		_importHasBegun = NO;
		_continuing = YES;
		_finishedImport = NO;
		
		_entries = [theEntries retain];
		folders = [theFolders retain];
		journal = [aJournal retain];
		
		[[NSApp delegate] prepareLabelMenu:&labelMenu];
		
		[self retain];
	}
	
	return self;
}

- (void) windowDidLoad 
{	
	
	[foldersOutline setIntercellSpacing:NSMakeSize(0.0,0.0)];
	[foldersController setSelectionIndexPath:[NSIndexPath indexPathWithIndex:0]];
	
	// the custom field editor
	[browseTableFieldEditor retain];
	[browseTableFieldEditor setFieldEditor:YES];
	
	NSInteger borders[4] = {0,0,0,0};
	[gradient setBorders:borders];
	[gradient setBordered:NO];
	
	// tags token field cell
	PDTokenFieldCell *tokenCell = [[[PDTokenFieldCell alloc] init] autorelease];
	
	[tokenCell setFont:[NSFont controlContentFontOfSize:11]];
	[tokenCell setControlSize:NSSmallControlSize];
	[tokenCell setDelegate:self];
	[tokenCell setBezeled:NO];
	[tokenCell setBordered:NO];
	
	[[entriesTable tableColumnWithIdentifier:@"tags"] setDataCell:tokenCell];
	
	[foldersOutline bind:@"font" toObject:[NSUserDefaultsController sharedUserDefaultsController] 
	withKeyPath:@"values.FoldersTableFont" options:[NSDictionary dictionaryWithObjectsAndKeys:
	@"NSUnarchiveFromData", NSValueTransformerNameBindingOption,
	[NSFont controlContentFontOfSize:11], NSNullPlaceholderBindingOption, nil]];
			
	[foldersOutline bind:@"backgroundColor" toObject:[NSUserDefaultsController sharedUserDefaultsController] 
	withKeyPath:@"values.FolderBackgroundColor" options:[NSDictionary dictionaryWithObjectsAndKeys:
	@"NSUnarchiveFromData", NSValueTransformerNameBindingOption,
	[NSColor colorWithCalibratedHue:234.0/400.0 saturation:1.0/100.0 brightness:97.0/100.0 alpha:1.0], NSNullPlaceholderBindingOption, nil]];
	
	[foldersOutline sizeToFit];
	
	//import review note
	//import review target folder
	
	NSMutableString *tip = [NSMutableString string];
	[tip appendString:NSLocalizedString(@"import review note",@"")];
	[tipField setStringValue:tip];
}

- (void) dealloc 
{	
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	[_entries release];
	[journal release];
	[folders release];
	[browseTableFieldEditor release];
	
	[super dealloc];
}

- (void)windowWillClose:(NSNotification *)aNotification 
{	
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	if ( [aNotification object] == [self window] )
	{
		//[entriesController unbind:@"contentArray"];
		//[entriesController unbind:@"contentArrayForMultipleSelection"];
		//[entriesController setContent:nil];

		//[foldersController unbind:@"contentArray"];
		//[foldersController setContent:nil];
		
		[foldersOutline setDelegate:nil];
		[objectController unbind:@"contentObject"];
		[objectController setContent:nil];
	}
	
	[self autorelease];
}

#pragma mark -

- (JournlerJournal*) journal
{
	return journal;
}

- (void) setJournal:(JournlerJournal*)aJournal
{
	if ( journal != aJournal )
	{
		[journal release];
		journal = [aJournal retain];
	}
}

- (NSArray*) entries 
{ 
	return _entries; 
}

- (void) setEntries:(NSArray*)entryContent 
{	
	if ( _entries != entryContent )
	{
		[_entries release];
		_entries = [entryContent retain];
	}
}

- (NSArray*) folders
{
	return folders;
}

- (void) setFolders:(NSArray*)theFolders
{
	if ( folders != theFolders )
	{
		[folders release];
		folders = [theFolders retain];
	}
}

- (BOOL) userInteraction 
{ 
	return _userInteraction; 
}

- (void) setUserInteraction:(BOOL)visual 
{ 
	_userInteraction = visual; 
}

- (BOOL) preserveModificationDate
{
	return _preserveModificationDate;
}

- (void) setPreserveModificationDate:(BOOL)preserve
{
	_preserveModificationDate = preserve;
}

#pragma mark -

- (NSInteger) runAsSheetForWindow:(NSWindow*)window attached:(BOOL)sheet targetCollection:(JournlerCollection*)aFolder 
{
	NSInteger result = NSRunStoppedResponse;
	_targetFolder = aFolder;
	
	if ( _userInteraction ) 
	{
		
		if ( sheet )
			[NSApp beginSheet: [self window] modalForWindow: window modalDelegate: nil
					didEndSelector: nil contextInfo: nil];
		
		NSModalSession session = [NSApp beginModalSessionForWindow:[self window]];
		
		// change the tip
		NSMutableString *tip = [NSMutableString string];
		[tip appendString:NSLocalizedString(@"import review note",@"")];
		if ( aFolder == nil || [aFolder isLibrary] )
			[tipField setStringValue:tip];
		else
		{
			NSString *targetString = [NSString stringWithFormat:NSLocalizedString(@"import review target folder",@""), [aFolder title]];
			[tip appendFormat:@" %@", targetString];
			[tipField setStringValue:tip];
		}
		
		for (;;) 
		{
			result = [NSApp runModalSession:session];
			if ( result != NSRunContinuesResponse || _continuing == NO || _finishedImport == YES )
				break;
			
			[[NSRunLoop currentRunLoop] runMode:NSModalPanelRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		}
			
		[NSApp endModalSession:session];
		if ( sheet ) 
			[NSApp endSheet: [self window]];
		
		
		/*
		result = [NSApp runModalForWindow:[self window]];
		if ( result == NSRunStoppedResponse )
		{
			[self _performImport:nil];
		}
		*/
		
		[self close];
		//[[self window] orderOut:self];
		//[[self window] close];
		return result;
	}
	else 
	{
		[self performImport:NO];
		return NSRunStoppedResponse;
	}
}

#pragma mark -

- (IBAction)cancel:(id)sender
{
	_continuing = NO;
	//[NSApp abortModal];
}

- (IBAction)okay:(id)sender
{
	if ( _importHasBegun ) 
		NSBeep();
	else 
	{
		if ( ![objectController commitEditing] )
			NSLog(@"%s - unable to commit editing", __PRETTY_FUNCTION__);
		
		_importHasBegun = YES;
		[tipField setHidden:YES];
		//[self performImport:YES];
		[self performImport:NO];
		//[NSApp stopModal];
	}
}

- (IBAction)help:(id)sender
{
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"JournlerImporting" inBook:@"JournlerHelp"];
}

- (IBAction)log:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:@"/tmp/jrlrbulkimportlog.txt"]];
}

#pragma mark -

- (BOOL)windowShouldClose:(id)sender 
{
	//if ( sender == previewWin )
	//	[NSApp stopModal];
		
	return YES;
}

- (IBAction)preview:(id)sender 
{
	if ( [[entriesController selectedObjects] count] != 1 )
	{
		NSBeep(); return;
	}
	
	NSAttributedString *attr = [[[entriesController selectedObjects] objectAtIndex:0] attributedContent];
	if ( !attr )
		return;
	
	[[previewText textStorage] beginEditing];
	[[previewText textStorage] setAttributedString:attr];
	[[previewText textStorage] endEditing];
	
	[previewWin makeKeyAndOrderFront:self];
	
	//[NSApp runModalForWindow:previewWin];
	//[previewWin orderOut:self];
}

- (IBAction) editEntryLabel:(id)sender
{
	NSArray *theEntries;
	
	// grab the available entries from the controller
	theEntries = [entriesController selectedObjects];
	if ( theEntries == nil || [theEntries count] == 0 ) {
		NSBeep(); return;
	}
	
	[theEntries setValue:[NSNumber numberWithInteger:[sender tag]] forKey:@"label"];
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem 
{
	BOOL enabled = NO;
	
	if ( [menuItem tag] == 841 && [[entriesController selectedObjects] count] == 1)
		enabled = YES;
	
	return enabled;
}

#pragma mark -
#pragma mark Performing the Import

- (void) performImport:(BOOL)threaded {
	
	if ( threaded ) 
		[NSThread detachNewThreadSelector:@selector(_performImport:) toTarget:self withObject:nil];
	else
		[self _performImport:nil];
}

- (void) _performImport:(id)anObject {
	
	NSInteger i;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if ( _userInteraction ) {
		[progress setHidden:NO];
		[progress setMaxValue:[_entries count]];
		[okayButton setEnabled:NO];
		[[self window] display];
	}
	
	NSInteger entryImportOptions = 0;
	NSInteger kMaxWidth = ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EmbeddedImageUseFullSize"] ? 0
	: [[NSUserDefaults standardUserDefaults] integerForKey:@"EmbeddedImageMaxWidth"] );
	
	NSSize maxPreviewSize = NSMakeSize(kMaxWidth,kMaxWidth);
	
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"NewMediaLinkIncludeIcon"] )
		entryImportOptions |= kEntryImportIncludeIcon;
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryImportSetDefaultResource"] )
		entryImportOptions |= kEntryImportSetDefaultResource;
	if ( _preserveModificationDate )
		entryImportOptions |= kEntryImportPreserveDateModified;

	NSArray *theEntries = [self entries];
	NSArray *theFolders = [self folders];
	
	// disabled threaded indexing during the import
	BOOL wasThreaded = [[[self journal] searchManager] indexesOnSeparateThread];
	[[[self journal] searchManager] setIndexesOnSeparateThread:NO];
	
	// iterate through the entries, adding them to the journal
	for ( i = 0; i < [theEntries count]; i++ ) 
	{
		NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
		
		BOOL err = NO, addToTargetFolder = NO;
		JournlerEntry *anEntry = [theEntries objectAtIndex:i];
		
		if ( !_continuing ) 
		{
			[innerPool release];
			break;
		}
		
		// if the entry is not already in any of the preserved folders, add it to the target folder
		if ( _targetFolder != nil && ( [anEntry collections] == nil || [[anEntry collections] count] == 0 ) )
			addToTargetFolder = YES;
		
		// temporarily disable searching and indexing
		[[self journal] setSaveEntryOptions:kEntrySaveDoNotIndex|kEntrySaveDoNotCollect];
		
		// add the import to the journal
		[[self journal] addEntry:anEntry];
		
		// save the entry to guarantee a file location
		if ( ![[self journal] saveEntry:anEntry] ) 
		{
			// error
			err = YES;
		}
		else
		{
			// complete the import
			if ( ![anEntry completeImport:entryImportOptions operation:kNewResourceForceCopy maxPreviewSize:maxPreviewSize] ) 
			{
				// error
				err = YES;
			}
			else
			{
				// save the entry once more, indexing and collecting
				[[self journal] setSaveEntryOptions:kEntrySaveIndexAndCollect];
				if ( ![[self journal] saveEntry:anEntry] )
				{
					// error
					err = YES;
				}
				
				// mark the entry's resources as no longer dirty
				[[anEntry valueForKey:@"resources"] setValue:[NSNumber numberWithBool:NO] forKey:@"dirty"];
				
				// add the entry to the target folder
				if ( addToTargetFolder )
				{
					if ( [_targetFolder isRegularFolder] )
						[_targetFolder addEntry:anEntry];
					else if ( [_targetFolder isSmartFolder] )
						[_targetFolder autotagEntry:anEntry add:YES];
				}
			}
		}
		
		
		// handle the folders
		/*
		if ( _targetFolder ) {
		
			if ( [[_targetFolder valueForKey:@"tagID"] integerValue] == PDCollectionTypeIDTrash ) 
				[[self journal] markEntryForTrash:anEntry];
			else
				[_targetFolder addEntry:anEntry];
		 
		  
		}
		*/
		
		if ( _userInteraction ) 
		{ 
			// updateh the progres indicator if user interaction
			[progress incrementBy:1];
			[progress performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:YES];
		}
		
		// let go of the autoreleased objects
		[innerPool release];
		
	}
	
	if ( _continuing )
	{
		// iterate through the folders, adding them to the journal (only regular folders)
		JournlerCollection *folderParent = ( _targetFolder == nil ? [[self journal] rootCollection] : _targetFolder );
		for ( i = 0; i < [theFolders count]; i++ )
		{
			if ( [[theFolders objectAtIndex:i] isRegularFolder] )
			{
				[self addFolderToJournal:[theFolders objectAtIndex:i]];
				[folderParent addChild:[theFolders objectAtIndex:i]];
			}
		}
		
		// reload root list
		[[self journal] setRootFolders:nil];
	}
	
	// double check to ensure the journal is indexing and collecting
	[[self journal] setSaveEntryOptions:kEntrySaveIndexAndCollect];
	
	// reset threaded indexing state
	[[[self journal] searchManager] setIndexesOnSeparateThread:wasThreaded];
	
	_finishedImport = YES;
	[pool release];
}

- (void) addFolderToJournal:(JournlerCollection*)aFolder
{
	if ( ![aFolder isRegularFolder] )
		return;
	
	// add this folder to the journal and save it
	[[self journal] addCollection:aFolder];
	[[self journal] saveCollection:aFolder];
	
	// do the same for the folder's children
	NSInteger i;
	NSArray *kids = [aFolder children];
	for ( i = 0; i < [kids count]; i++ )
		[self addFolderToJournal:[kids objectAtIndex:i]];
	
}

#pragma mark -
#pragma mark Window Delegation

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject 
{	
	if ( [self window] != sender ) 
		return nil;
			
	if ( [anObject isKindOfClass:[ImportReviewTable class]] && [(ImportReviewTable*)anObject editingCategory] )
	{
		[browseTableFieldEditor setCompletions:[[NSUserDefaults standardUserDefaults] arrayForKey:@"Journler Categories List"]];
		[browseTableFieldEditor setCompletes:YES];
		return browseTableFieldEditor;
	}
	else
	{
		return nil;
	}
}


#pragma mark -
#pragma mark OutlineView Delegation

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	JournlerCollection *actualItem; 
	// necessary hack to get around NSTreeController proxy object, 10.5 compatible
	if ( [item respondsToSelector:@selector(representedObject)] )
		actualItem = [item representedObject];
	else if ( [item respondsToSelector:@selector(observedObject)] )
		actualItem = [item observedObject];
	else
		actualItem = item;
	
	return ![actualItem isSeparatorFolder];
}

- (float)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item 
{
	JournlerCollection *actualItem; 
	// necessary hack to get around NSTreeController proxy object, 10.5 compatible
	if ( [item respondsToSelector:@selector(representedObject)] )
		actualItem = [item representedObject];
	else if ( [item respondsToSelector:@selector(observedObject)] )
		actualItem = [item observedObject];
	else
		actualItem = item;

	if ( [actualItem isSeparatorFolder] )
		return kSourceListSeparatorHeight;
	else
		return kSourceListSmallHeight;
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item 
{
	if ([[tableColumn identifier] isEqualToString: @"title"]) 
	{
		// Set the image here since the value returned from 
		// outlineView:objectValueForTableColumn:... didn't specify the image part...
		
		JournlerCollection *actualItem; 
		// necessary hack to get around NSTreeController proxy object, 10.5 compatile
		if ( [item respondsToSelector:@selector(representedObject)] )
			actualItem = [item representedObject];
		else if ( [item respondsToSelector:@selector(observedObject)] )
			actualItem = [item observedObject];
		else
			actualItem = item;
		
		// separator?
		[(ImageAndTextCell*)cell setIsSeparatorCell:[actualItem isSeparatorFolder]];
		
		// set the image
		[(ImageAndTextCell*)cell setImage:[actualItem valueForKey:@"icon"]];
		
		// let the cell know what size of image to use
		[(ImageAndTextCell*)cell setImageSize:NSMakeSize(kSourceListSmallHeight,kSourceListSmallHeight)];
		
		// show the count
		[(ImageAndTextCell*)cell setContentCount:[[actualItem entries] count]];
		
		// set selected
		[(ImageAndTextCell*)cell setSelected:( [[outlineView selectedRowIndexes] containsIndex:[outlineView rowForItem:item]] )];
	}
}


- (void) importReviewSourceList:(ImportReviewSourceList*)aSourceList deleteFolders:(NSNotification*)aNotification
{
	// #warning doesn't work, causes crash
    
    for ( id anObject in [foldersController selectedObjects] )
	{
		JournlerCollection *aFolder;
		// necessary hack, 10.5 compatible
		if ( [anObject respondsToSelector:@selector(representedObject)] )
			aFolder = [anObject representedObject];
		else if ( [anObject respondsToSelector:@selector(observedObject)] )
			aFolder = [anObject observedObject];
		else
			aFolder = anObject;
		
		if ( [aFolder isLibrary] )
			NSBeep();
		else
			[self deleteFolder:aFolder];
	}
}

#pragma mark -
#pragma mark TableView Delegation

- (void) importReviewTable:(ImportReviewTable*)aTable deleteEntries:(NSNotification*)aNotification
{
	NSArray *theEntries = [entriesController selectedObjects];
	[self deleteEntries:theEntries];
}

#pragma mark -
#pragma mark NSTokenFieldCell Delegation

- (NSArray *)tokenFieldCell:(NSTokenFieldCell *)tokenFieldCell completionsForSubstring:(NSString *)substring 
	indexOfToken:(NSInteger )tokenIndex indexOfSelectedItem:(NSInteger *)selectedIndex
{
	//NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self beginswith[cd] %@", substring];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self beginswith %@", substring];
	NSArray *completions = [[[[self journal] entryTags] allObjects] filteredArrayUsingPredicate:predicate];
	return completions;
}

#pragma mark -
#pragma mark Deleting Entries and Folders

- (void) deleteEntries:(NSArray*)theEntries
{
	for ( JournlerCollection *aFolder in [self folders] )
	{
		for ( JournlerEntry *anEntry in theEntries )
			[aFolder removeEntry:anEntry];
	}
	
	// remove the entries from the main entries list
	NSMutableArray *myEntries = [[[self entries] mutableCopyWithZone:[self zone]] autorelease];
	[myEntries removeObjectsInArray:theEntries];
	[self setEntries:myEntries];

}

- (void) deleteFolder:(JournlerCollection*)aFolder
{
	// delete all the entries contained in the folder
	NSArray *entries = [aFolder entries];
	[self deleteEntries:entries];
	
	// remove the folder from its parent, or from the main array if the parent is nil
	if ( [aFolder parent] == nil )
	{
		NSMutableArray *myFolders = [[[self folders] mutableCopyWithZone:[self zone]] autorelease];
		[myFolders removeObject:aFolder];
		[self setFolders:myFolders];
	}
	else
	{
		[[aFolder parent] removeChild:aFolder recursively:YES];
	}
}

@end
