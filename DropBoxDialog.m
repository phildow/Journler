#import "DropBoxDialog.h"

#import "JournlerJournal.h"
#import "JournlerEntry.h"

#import "FoldersController.h"
#import "CollectionsSourceList.h"

#import "DropBoxFoldersController.h"
#import "DropBoxSourceList.h"

#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>

typedef void (*DropBoxDidEndIMP)(id, SEL, id, int, id);

static NSSortDescriptor *FoldersByIndexSortPrototype()
{
	static NSSortDescriptor *descriptor = nil;
	if ( descriptor == nil )
	{
		descriptor = [[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES selector:@selector(compare:)];
	}
	return descriptor;
}

@implementation DropBoxDialog

- (id) initWithJournal:(JournlerJournal*)aJournal delegate:(id)aDelegate mode:(int)dropboxMode didEndSelector:(SEL)aSelector
{
	if ( self = [super initWithWindowNibName:@"DropBoxDialog"] )
	{
		didEndSelector = aSelector;
		journal = [aJournal retain];
		delegate = aDelegate;
		
		mode = dropboxMode;
		canCancelImport = YES;
		
		[self retain];
	}
	
	return self;
}

- (void) windowDidLoad
{
	NSString *defaultCategory;
	
	// visual goodness
	[[self window] setMovableByWindowBackground:NO];
	//[gradientBackground setControlTint:NSGraphiteControlTint];
	
	if ( ![gradientBackground respondsToSelector:@selector(addTrackingArea:)] )
	{
		// on 10.4 change the appearance of the buttons and window
		static NSInteger kBottomBarHeight = 42;
		static NSInteger kMinButtonWidth = 96;
		[[self window] setBackgroundColor:[NSColor colorWithCalibratedWhite:0.98 alpha:0.98]];
		
		[returnButton setBezelStyle:NSRoundedBezelStyle]; //NSRegularSquareBezelStyle
		[cancelButton setBezelStyle:NSRoundedBezelStyle];
		
		[returnButton setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]]];
		[cancelButton setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]]];
		
		[returnButton sizeToFit];
		[cancelButton sizeToFit];
		
		[[rememberFolderSelectionCheckbox cell] setControlSize:NSRegularControlSize];
		[rememberFolderSelectionCheckbox setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]]];
		[rememberFolderSelectionCheckbox sizeToFit];
		
		NSRect aFrame = [returnButton frame];
		NSRect superBounds = [[returnButton superview] bounds];
		
		aFrame.size.width += 18;
		if ( aFrame.size.width < kMinButtonWidth ) kMinButtonWidth = kMinButtonWidth;
		aFrame.origin.x = superBounds.size.width - 16 - aFrame.size.width;
		aFrame.origin.y = kBottomBarHeight/2 - aFrame.size.height/2 - 1;
		
		[returnButton setFrame:aFrame];
		
		aFrame = [cancelButton frame];
		
		aFrame.size.width += 18;
		if ( aFrame.size.width < kMinButtonWidth ) kMinButtonWidth = kMinButtonWidth;
		aFrame.origin.x = [returnButton frame].origin.x - aFrame.size.width;
		aFrame.origin.y = kBottomBarHeight/2 - aFrame.size.height/2 - 1;
		
		[cancelButton setFrame:aFrame];
		
		
	}
	
	//if ( [[self window] respondsToSelector:@selector(contentBorderThicknessForEdge:)] )
	//	[[self window] setContentBorderThickness:43.0 forEdge:NSMinYEdge];
	
	// the folders controller must know the actual root (vs. the roots children)
	[sourceController setRootCollection:[[self journal] valueForKey:@"rootCollection"]];
	
	// populate the list with regular, smart folders and the journal
	NSPredicate *folderFilter = [NSPredicate predicateWithFormat:@"isRegularFolder == YES OR isSmartFolder == YES"];
	NSArray *filteredFolders = [[[self journal] rootFolders] filteredArrayUsingPredicate:folderFilter];
	[sourceController setContent:filteredFolders];
	
	// set the sort descriptors on the source list
	[sourceController setSortDescriptors:[NSArray arrayWithObject:FoldersByIndexSortPrototype()]];
	
	// prepare the categories and select the default
	NSArray *categoriesList = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Journler Categories List"];
	[categoryField addItemsWithObjectValues: [categoriesList sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] ];
	
	// category
	defaultCategory = [JournlerEntry dropBoxCategory];
	if ( defaultCategory != nil )
	{
		[categoryField addItemWithObjectValue:defaultCategory];
		[categoryField selectItemWithObjectValue:defaultCategory];
	}
	
	if ( [categoryField numberOfVisibleItems] > [categoryField numberOfItems] )
		[categoryField setNumberOfVisibleItems:[categoryField numberOfItems]];
	
	// content appearance
	[[[filesTable enclosingScrollView] verticalScroller] setControlTint:NSGraphiteControlTint];
	[[[sourceList enclosingScrollView] verticalScroller] setControlTint:NSGraphiteControlTint];
	
	[[tagsField cell] setControlTint:NSGraphiteControlTint];
	[[categoryField cell] setControlTint:NSGraphiteControlTint];
	
	[[tagsField cell] setFocusRingType:NSFocusRingTypeNone];
	[[categoryField cell] setFocusRingType:NSFocusRingTypeNone];
	
	[[self window] setDefaultButtonCell:[returnButton cell]];
	
	// source list state
	NSArray *sourceListState;
	NSData *sourceListStateData;
	if ( ( sourceListStateData = [[NSUserDefaults standardUserDefaults] dataForKey:@"DropBoxSourceListState"] ) != nil 
		&& ( sourceListState = [NSKeyedUnarchiver unarchiveObjectWithData:sourceListStateData] ) != nil )
		[sourceList restoreStateFromArray:sourceListState];
	
	// maintains the drop box selection
	NSArray *indexPaths;
	NSData *indexPathsData;
	
	if ( ( indexPathsData = [[NSUserDefaults standardUserDefaults] dataForKey:@"DropBoxSourceListSelection"] ) != nil 
				&& ( indexPaths = [NSKeyedUnarchiver unarchiveObjectWithData:indexPathsData] ) != nil
				&& [[NSUserDefaults standardUserDefaults] boolForKey:@"DropBoxSourceListRememberSelection"] )
	{
		[sourceController setSelectionIndexPaths:indexPaths];
		if ( [sourceList selectedRow] != -1 ) [sourceList scrollRowToVisible:[sourceList selectedRow]];
	}
	
	if ( tags != nil ) [tagsField setObjectValue:tags];
	if ( category != nil ) [categoryField setStringValue:category];
}

- (void) dealloc
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	[activeApplication release];
	[journal release];
	[content release];
	[representedObject release];
	[tagCompletions release];
	
	[super dealloc];
}

- (void) windowWillClose:(NSNotification*)aNotification
{
	if ( [self window] == [aNotification object] )
	{
		NSArray *sourceListState = [sourceList stateArray];
		NSData *sourceListStateData = [NSKeyedArchiver archivedDataWithRootObject:sourceListState];
		[[NSUserDefaults standardUserDefaults] setObject:sourceListStateData forKey:@"DropBoxSourceListState"];
		
		// maintains the drop box selection
		NSArray *indexPaths = [sourceController selectionIndexPaths];
		NSData *indexPathsData = [NSKeyedArchiver archivedDataWithRootObject:indexPaths];
		[[NSUserDefaults standardUserDefaults] setObject:indexPathsData forKey:@"DropBoxSourceListSelection"];
		
		[sourceList setDelegate:nil];
		[sourceController unbind:@"contentArray"];
		[sourceController setContent:nil];

		[cancelButton unbind:@"hidden"];
		
		[self autorelease];
	}
}

#pragma mark -

+ (NSArray*) contentForFilenames:(NSArray*)filenames
{
	// load the files
	NSMutableArray *fileObjects = [NSMutableArray arrayWithCapacity:[filenames count]];

    for ( NSString *aFilename in filenames )
	{
	// keys: title, filename, icon, description
		NSMutableDictionary *objectDictionary = [NSMutableDictionary dictionary];
		
		NSString *title = [[aFilename lastPathComponent] stringByDeletingPathExtension];
		NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:aFilename];
		[icon setSize:NSMakeSize(32,32)];
		
		[objectDictionary setValue:icon forKey:@"icon"];
		[objectDictionary setValue:title forKey:@"title"];
		[objectDictionary setValue:aFilename forKey:@"filename"];
		[objectDictionary setValue:aFilename forKey:@"representedObject"];
		
		[fileObjects addObject:objectDictionary];
	}
	
	return fileObjects;
}

+ (NSArray*) contentForEntries:(NSArray*)entries
{
	NSMutableArray *entryObjects = [NSMutableArray arrayWithCapacity:[entries count]];
    
    for ( JournlerEntry *anEntry in entries )
	{
		// keys: title, filename, icon, description
		NSMutableDictionary *objectDictionary = [NSMutableDictionary dictionary];
		
		//NSString *title = [[aFilename lastPathComponent] stringByDeletingPathExtension];
		NSImage *icon = nil;
		if ( [[anEntry resources] count] == 0 )
			icon = [anEntry icon];
		else
			icon = [[[anEntry resources] objectAtIndex:0] icon];
		
		// readjust the size
		icon = [icon imageWithWidth:32 height:32];
		
		[objectDictionary setValue:icon forKey:@"icon"];
		[objectDictionary setValue:[anEntry title] forKey:@"title"];
		[objectDictionary setValue:anEntry forKey:@"representedObject"];
		//[objectDictionary setValue:aFilename forKey:@"filename"];
		
		[entryObjects addObject:objectDictionary];
	}
	
	return entryObjects;
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

- (NSDictionary*) activeApplication
{
	return activeApplication;
}

- (void) setActiveApplication:(NSDictionary*)aDictionary
{
	if ( activeApplication != aDictionary )
	{
		[activeApplication release];
		activeApplication = [aDictionary copyWithZone:[self zone]];
	}
}

- (NSArray*)content
{
	return content;
}

- (void) setContent:(NSArray*)anArray
{
	if ( content != anArray )
	{
		[content release];
		content = [anArray copyWithZone:[self zone]];
		
		[self setMultipleFiles:([anArray count] > 0)];
	}
}

- (id) representedObject
{
	return representedObject;
}

- (void) setRepresentedObject:(id)anObject
{
	if ( representedObject != anObject )
	{
		[representedObject release];
		representedObject = [anObject retain];
	}
}

- (BOOL) multipleFiles
{
	return multipleFiles;
}

- (void) setMultipleFiles:(BOOL)multiple
{
	multipleFiles = multiple;
	if ( multipleFiles == YES ) [noteField setStringValue:NSLocalizedString(@"dropbox note singular",@"")];
	else [noteField setStringValue:NSLocalizedString(@"dropbox note plural",@"")];
}

- (BOOL) canCancelImport
{
	return canCancelImport;
}

- (void) setCanCancelImport:(BOOL)canCancel
{
	canCancelImport = canCancel;
}

- (BOOL) shouldDeleteOriginal
{
	return shouldDeleteOriginal;
}

- (void) setShouldDeleteOriginal:(BOOL)deletesOriginal
{
	shouldDeleteOriginal = deletesOriginal;
}

- (NSArray*) tagCompletions
{
	return tagCompletions;
}

- (void) setTagCompletions:(NSArray*)anArray
{
	if ( tagCompletions != anArray )
	{
		[tagCompletions release];
		tagCompletions = [anArray copyWithZone:[self zone]];
	}
}

#pragma mark -

- (IBAction) runClose:(id)sender
{
	//[delegate dropBox:self didDenyContent:[self content]];
	[self _endWithCode:NSRunAbortedResponse];
}

- (IBAction) doImport:(id)sender
{
	//[delegate dropBox:self didAcceptContent:[self content]];
	[self _endWithCode:NSRunStoppedResponse];
}

- (void) _endWithCode:(int)code
{
	DropBoxDidEndIMP didEnd;
	didEnd = (DropBoxDidEndIMP)[delegate methodForSelector:didEndSelector];
	didEnd(delegate, didEndSelector, self, code, [self content]); 
}

#pragma mark -

- (IBAction) showWindow:(id)sender
{
	NSDictionary *theActiveApplication = [[NSWorkspace sharedWorkspace] activeApplication];
	
	[self setActiveApplication:theActiveApplication];
	[[self window] center];
	
	// activate ourselves
	[NSApp activateIgnoringOtherApps:YES];
	
	// fade all our windows out
	//[self fadeOutAllWindows:[NSArray arrayWithObject:[dropBoxDialog window]]];
	
	//[dropBoxDialog fadeWindowIn:self];
	//result = [NSApp runModalForWindow:[dropBoxDialog window]];
	
	[[self window] setLevel:NSModalPanelWindowLevel];
	[super showWindow:self];
	//[[dropBoxDialog window] orderFront:self];
	//[[dropBoxDialog window] center];
	//[[dropBoxDialog window] orderFrontRegardless];
	[[self window] makeKeyAndOrderFront:self];
}

- (IBAction) changeFolderSelectionMemory:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setBool:( [sender state] == NSOnState ) forKey:@"DropBoxSourceListRememberSelection"];
	
	if ( [sender state] == NSOffState )
	{
		[sourceList deselectAll:self];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"DropBoxSourceListSelection"];
		
	}
}

#pragma mark -
#pragma mark Fading

- (void) fadeWindowOut:(id)sender
{
	NSDictionary *aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
	 [self window], NSViewAnimationTargetKey,
	 NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey, nil];
		
	NSViewAnimation *animation = [[[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:aDictionary]] autorelease];
	
	[animation setDelegate:self];
	[animation setDuration:0.15];
	[animation startAnimation];

}

- (void) fadeWindowIn:(id)sender
{
	[[self window] setAlphaValue:0];
	
	NSDictionary *aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
	 [self window], NSViewAnimationTargetKey,
	 NSViewAnimationFadeInEffect, NSViewAnimationEffectKey, nil];
	 	
	NSViewAnimation *animation = [[[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:aDictionary]] autorelease];
	[animation setDuration:0.15];
	[animation startAnimation];
}

- (void)animationDidEnd:(NSAnimation*)animation
{
	[[self window] close];
}

#pragma mark -
#pragma mark Table View Delegation

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
{
	return YES;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	// keys: title, filename, icon, description
	[(ImageAndTextCell*)aCell setImageSize:NSMakeSize(32,32)];
	[(ImageAndTextCell*)aCell setImage:[[[filesController arrangedObjects] objectAtIndex:rowIndex] valueForKey:@"icon"]];
	
	// selection (so color can determine colors, font, etc)
	[(ImageAndTextCell*)aCell setSelected:( [[aTableView selectedRowIndexes] containsIndex:rowIndex] )];
}

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell 
			rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(int)row mouseLocation:(NSPoint)mouseLocation
{
	NSString *tooltip;
	NSString *description = [[[filesController arrangedObjects] objectAtIndex:row] valueForKey:@"description"];
	if ( description != nil )
		tooltip = description;
	else
		tooltip = [[[filesController arrangedObjects] objectAtIndex:row] valueForKey:@"title"];
	
	return tooltip;
}

#pragma mark -
#pragma mark JournlerConditionController Delegate (NSTokenField)

- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring 
	indexOfToken:(NSInteger)tokenIndex indexOfSelectedItem:(NSInteger *)selectedIndex
{
	//NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self beginswith[cd] %@", substring];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self beginswith %@", substring];
	NSArray *completions = [[self tagCompletions] filteredArrayUsingPredicate:predicate];
	return completions;
}

#pragma mark -

- (NSArray*) tags
{
	/*
	NSString *theTags = [tagsField stringValue];
	if ( [theTags length] == 0 )
		return nil;
	else
		return theTags;
	*/
	
	NSArray *theTags = [tagsField objectValue];
	if ( [theTags count] == 0 )
		return nil;
	else
		return theTags;
}

- (void) setTags:(NSArray*)anArray
{
	if ( anArray != nil )
	{
		if ( [self isWindowLoaded] )
			[tagsField setObjectValue:anArray];
		else
			tags = [anArray copyWithZone:[self zone]];
	}
}

- (NSString*) category
{
	NSString *theCategory = [categoryField stringValue];
	if ( [theCategory length] == 0 )
		return nil;
	else
		return theCategory;
}

- (void) setCategory:(NSString*)aCategory
{
	if ( aCategory != nil )
	{
		if ( [self isWindowLoaded] )
			[categoryField setStringValue:aCategory];
		else
			category = [aCategory copyWithZone:[self zone]];
	}
}

#pragma mark -

- (JournlerCollection*) selectedFolder
{
	NSArray *selectedObjects = [sourceController selectedObjects];
	if ( [selectedObjects count] == 0 )
		return nil;
	else
		return [selectedObjects objectAtIndex:0];
}

- (NSArray*) selectedFolders
{
	NSArray *selectedObjects = [sourceController selectedObjects];
	if ( [selectedObjects count] == 0 )
		return nil;
	else return selectedObjects; 
}

@end
