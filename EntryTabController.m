//
//  EntryTabController.m
//  Journler
//
//  Created by Philip Dow on 11/9/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import "EntryTabController.h"
#import "TabController.h"

#import "Definitions.h"
#import "JournlerApplicationDelegate.h"

#import "NSAlert+JournlerAdditions.h"

#import "JournlerJournal.h"
#import "JournlerEntry.h"
#import "JournlerResource.h"

#import "JournlerWindowController.h"
#import "EntryWindowController.h"

#import "ResourceController.h"

#import "EntryCellController.h"
#import "ResourceCellController.h"

#import "LinksOnlyNSTextView.h"
#import "WebViewController.h"
#import "JournlerMediaViewer.h"


typedef enum {
	kResourceRequestAudio = 0,
	kResourceRequestPhoto = 1,
	kResourceRequestMovie = 2,
	kResourceRequestBookmark = 3,
	kResourceRequestContact = 4,
	kResourceRequestFile = 5,
	kResourceRequestEntry = 6
} NewResourceRequest;

static NSSortDescriptor *ResourceByTitleSortPrototype()
{
	static NSSortDescriptor *descriptor = nil;
	if ( descriptor == nil )
	{
		descriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
	}
	return descriptor;
}

static NSSortDescriptor *ResourceByRankSortPrototype()
{
	static NSSortDescriptor *descriptor = nil;
	if ( descriptor == nil )
	{
		descriptor = [[NSSortDescriptor alloc] initWithKey:@"relevance" ascending:NO selector:@selector(compare:)];
	}
	return descriptor;
}

@implementation EntryTabController

- (id) initWithOwner:(JournlerWindowController*)anObject 
{	
	if ( self = [super initWithOwner:anObject] ) 
	{
		// prepare the cell controllers
		entryCellController = [[EntryCellController alloc] init];
		resourceCellController = [[ResourceCellController alloc] init];
		
		[entryCellController setJournal:[self journal]];
		[entryCellController setDelegate:self];
		[resourceCellController setDelegate:self];
		
		// prepare a popupbutton cell for the folders and resources worktool
		resourceWorktoolPopCell = [[NSPopUpButtonCell alloc] initTextCell:[NSString string] pullsDown:YES];
		newResourcePopCell = [[NSPopUpButtonCell alloc] initTextCell:[NSString string] pullsDown:YES];
		
		// load the associated bundle
		[NSBundle loadNibNamed:@"EntryTab" owner:self];
	}
	return self;	
}

- (void) awakeFromNib 
{	
	// set up the temporary content, to be immediately replaced by a selection
	activeContentView = contentPlaceholder;
	
	// set the default active content view
	[self setActiveContentView:[entryCellController contentView]];
	
	// header contextual
	[resourceTable sizeToFit];
	
	//[resourceInNewTabItem setKeyEquivalent:@"\r"];
	//[resourceInNewTabItem setKeyEquivalentModifierMask:NSShiftKeyMask];
	
	//[resourceInNewTabItemB setKeyEquivalent:@"\r"];
	//[resourceInNewTabItemB setKeyEquivalentModifierMask:NSShiftKeyMask];
	
	[resourceWorktoolPopCell setMenu:resourceWorktoolMenu];
	[resourceWorktoolPopCell selectItemAtIndex:0];
	[resourceWorktoolPopCell setPullsDown:YES];
	
	[newResourcePopCell setMenu:newResourceMenu];
	[newResourcePopCell selectItemAtIndex:0];
	[newResourcePopCell setPullsDown:YES];
	
	
	// set the sort descriptors for the resource table
	//[resourceController setSortDescriptors:[NSArray arrayWithObject:ResourceByTitleSortPrototype()]];
	
	// hook up the resource controller appropriately
	[resourceController bind:@"resources" 
			toObject:self 
			withKeyPath:@"selectedEntry.resources" 
			options:nil];
			
	[resourceController bind:@"folders" 
			toObject:self 
			withKeyPath:@"selectedEntry.collections" 
			options:nil];
	
	// bind ourselves to the folder and entry selection
	[self bind:@"selectedResources" 
			toObject:resourceController 
			withKeyPath:@"selectedResources" 
			options:nil];
	
}

- (void) dealloc
{
	// local objects
	[selectedEntry release];
	[entryCellController release];
	[resourceCellController release];
	
	// top level nib ojects
	[resourceController release];
	[referenceMenu release];
	[resourceWorktoolMenu release];
	
	[resourceWorktoolPopCell release];
	[newResourcePopCell release];
	
	[super dealloc];
}

- (void) ownerWillClose 
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	[super ownerWillClose];
	
	// commit editing
	if ( ![entryCellController commitEditing] )
		NSLog(@"%s - problem with committing changes with the entries cell controller", __PRETTY_FUNCTION__);
		
	if ( ![resourceController commitEditing] )
		NSLog(@"%s - problem with committing changes with the folders controller", __PRETTY_FUNCTION__);

	
	[self unbind:@"selectedResources"];
	
	[resourceController unbind:@"resources"];
	[resourceController unbind:@"folders"];
	[resourceController unbind:@"contentArray"];
	[resourceController setContent:nil];
		
	[entryCellController ownerWillClose];
	[resourceCellController ownerWillClose];
}

#pragma mark -

- (void) selectDate:(NSDate*)date folders:(NSArray*)folders entries:(NSArray*)entries resources:(NSArray*)resources 
{	
	
	if (  ( [entries isEqual:[self selectedEntries]] || entries == [self selectedEntries] ) 
		&& ( [resources isEqual:[self selectedResources]] || resources == [self selectedResources]) )
		return;
	
	// register a single, all encomposing undo call while disabling individual undo calls
	recordNavigationEvent = NO;
	[[navigationManager prepareWithInvocationTarget:self]
				selectDate:[self selectedDate] folders:[self selectedFolders] 
				entries:[self selectedEntries] resources:[self selectedResources]];
	
	if ( ![entries isEqualToArray:[self selectedEntries]] && !( entries==nil && [self selectedEntries] == nil) ) 
	{
		// next adjust the entry to match the selection
		[self setSelectedEntries:entries];
	}
	
	if ( ![resources isEqualToArray:[self selectedResources]] && !( resources==nil && [self selectedResources]==nil) ) 
	{
		// clear the current selection and force a selection on the new objects
		[resourceTable deselectAll:self];
		
        for ( JournlerResource *aResource in resources )
			[resourceController selectResource:aResource byExtendingSelection:YES];
	}

	// if no reference is selected, force this entry's content to load
	if ( ( resources == nil || [resources count] == 0 ) && !( [entries count] == 1 && [[entries objectAtIndex:0] selectedResource] != nil ) )
		[self setActiveContentView:[entryCellController contentView]];
	
	recordNavigationEvent = YES;
}

- (BOOL) selectResources:(NSArray*)anArray
{	
	[resourceTable deselectAll:self];
	
    for ( JournlerResource *aResource in anArray )
		[resourceController selectResource:aResource byExtendingSelection:NO];
		
	return YES;
}

- (BOOL) selectEntries:(NSArray*)anArray
{
	[self setSelectedEntries:anArray];
	return YES;
}

- (BOOL) selectFolders:(NSArray*)anArray
{
	NSBeep();
	return NO;
}

#pragma mark -

- (JournlerEntry*)selectedEntry
{
	return selectedEntry;
}

- (void) setSelectedEntry:(JournlerEntry*)anEntry
{
	if ( selectedEntry != anEntry )
	{
		[selectedEntry release];
		selectedEntry = [anEntry retain];
	}
}

- (void) setSelectedEntries:(NSArray*)anArray 
{	
	
	// autosave - could lead to redundancy, but only dirty objects are saved anyway
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithArray:[self selectedEntries]], @"entries", nil];
	NSNotification *aNotification = [NSNotification notificationWithName:@"JournlerAutosaveNotification" object:self userInfo:userInfo];
	
	[self performSelector:@selector(performAutosave:) withObject:aNotification afterDelay:0.1];
	
	// keep track of the single selected entry as well
	if ( [anArray count] > 0 )
	{
		// call super's implementation, forcing it to take only the single entry
		[super setSelectedEntries:[NSArray arrayWithObject:[anArray objectAtIndex:0]]];
		
		[self setSelectedEntry:[anArray objectAtIndex:0]];
		[entryCellController setSelectedEntries:[NSArray arrayWithObject:[anArray objectAtIndex:0]]];
	}
	else
	{
		[super setSelectedEntries:nil];
		[self setSelectedEntry:nil];
		[entryCellController setSelectedEntries:nil];
	}
	
	// make sure the entry cell is the active view
	[self setActiveContentView:[entryCellController contentView]];
	
	// restore the resource table state
	[resourceController restoreStateFromDictionary:[resourceController stateDictionary]];

}

- (void) setSelectedResources:(NSArray*)anArray 
{	
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	// call super's implementation
	[super setSelectedResources:anArray];
			
	// make sure the appropriate cell is the active view
	if ( anArray != nil && [anArray count] != 0 )
		[self setActiveContentView:[resourceCellController contentView]];
	else
		[self setActiveContentView:[entryCellController contentView]];
	
	// pass the resources to the reference cell
	[resourceCellController setSelectedResources:anArray];
}

#pragma mark -

- (NSView*) activeContentView 
{
	return activeContentView;
}

- (void) setActiveContentView:(NSView*)aView 
{
	if ( activeContentView == aView || aView == nil )
		return;
	
	// if the current active view is the resource view, we're switch out, so stop whatever it's doing
	if ( activeContentView == [resourceCellController contentView] )
		[resourceCellController stopContent];
	
	// if switching to text view, disable custom find panel action, otherwise, update
	if ( aView == [entryCellController contentView] )
	{
		//[[NSApp delegate] performSelector:@selector(setFindPanelPerformsCustomAction:) withObject:[NSNumber numberWithBool:NO]];
		//[[NSApp delegate] performSelector:@selector(setTextSizePerformsCustomAction:) withObject:[NSNumber numberWithBool:NO]];
	}
	else
	{
		//[resourceCellController checkCustomFindPanelAction];
		//[resourceCellController checkCustomTextSizeAction];
	}
	
	[aView setFrame:[activeContentView frame]];
	[[activeContentView superview] replaceSubview:activeContentView with:aView];
	
	activeContentView = aView;
}

- (NSDictionary*) localStateDictionary
{
	NSMutableDictionary *stateDictionary = [NSMutableDictionary dictionary];
	
	// splitview dimension
	NSNumber *resourceDimension = [NSNumber numberWithFloat:[[contentResourceSplit subviewAtPosition:1] dimension]];
	// is the resource view collapsed
	NSNumber *resourceCollapsed = [NSNumber numberWithBool:[[contentResourceSplit subviewAtPosition:1] isHidden]];
	
	[stateDictionary setValue:resourceDimension forKey:@"resourceDimension"];
	[stateDictionary setValue:resourceCollapsed forKey:@"resourceCollapsed"];
	
	// the entry cell's footer and header
	[stateDictionary setValue:[NSNumber numberWithBool:[entryCellController headerHidden]] forKey:@"headerHidden"];
	[stateDictionary setValue:[NSNumber numberWithBool:[entryCellController footerHidden]] forKey:@"footerHidden"];
	
	// the resource table state
	NSDictionary *resourceTableState = [stateDictionary valueForKey:@"resourceTableState"];
	if ( resourceTableState != nil )
		[resourceController restoreStateFromDictionary:resourceTableState];

	
	// get on outa here
	return stateDictionary;
}

- (void) restoreLocalStateWithDictionary:(NSDictionary*)stateDictionary
{
		
	NSNumber *resourceDimension = [stateDictionary valueForKey:@"resourceDimension"];
	if ( resourceDimension != nil )
		[[contentResourceSplit subviewAtPosition:1] setDimension:[resourceDimension floatValue]];
	
	// collapse the resources if necesary
	if ( [[stateDictionary valueForKey:@"resourceCollapsed"] boolValue] )
		[[contentResourceSplit subviewAtPosition:1] setHidden:YES];
	
	// collapse the entry cell's header and footer if necessary
	if ( [[stateDictionary valueForKey:@"headerHidden"] boolValue] )
		[entryCellController setHeaderHidden:YES];
	if ( [[stateDictionary valueForKey:@"footerHidden"] boolValue] )
		[entryCellController setFooterHidden:YES];
	
	// visible ruler
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryTextShowRuler"] && ![[entryCellController textView] isRulerVisible] )
		[[entryCellController textView] toggleRuler:self];
	
	// resource toggle image
	[self _updateResourceToggleImage];
}

- (void) appropriateFirstResponder:(NSWindow*)aWindow
{
	if ( [self activeContentView] == [entryCellController contentView] )
		[entryCellController appropriateFirstResponder:aWindow];
	else if ( [self activeContentView] == [resourceCellController contentView] )
		[resourceCellController appropriateFirstResponder:aWindow];
}

- (void) appropriateFirstResponderForNewEntry:(NSWindow*)aWindow
{
	if ( [self activeContentView] == [entryCellController contentView] )
		[entryCellController appropriateFirstResponderForNewEntry:aWindow];
	else if ( [self activeContentView] == [resourceCellController contentView] )
		[resourceCellController appropriateFirstResponder:aWindow];
}

- (BOOL) highlightString:(NSString*)aString
{
	if ( [self activeContentView] == [entryCellController contentView] )
		return [entryCellController highlightString:aString];
	
	else if ( [self activeContentView] == [resourceCellController contentView] )
		return [resourceCellController highlightString:aString];
	
	else
		return NO;
}

#pragma mark -

- (BOOL) textViewIsInFullscreenMode:(LinksOnlyNSTextView*)aTextView
{
	// pass it up the chain if the chain respects it, otherwise definitely not fullscreen
	if ( [[self owner] respondsToSelector:@selector(textViewIsInFullscreenMode:)] )
		return [[self owner] textViewIsInFullscreenMode:aTextView];
	else
		return NO;
}

- (IBAction) exportResource:(id)sender
{
	// override if there's a single selection and the resource view is active, otherwise pass to super
	if ( [self activeContentView] == [resourceCellController contentView] && [[self selectedResources] count] == 1 )
		[resourceCellController exportResource:sender];
	else
		[super exportResource:sender];
}

- (void) maximizeViewingArea
{
	[resourceWorktool setHidden:YES];
	[newResourceButton setHidden:YES];
	[toggleResourcesButton setHidden:YES];
	
	[resourceWorktool setEnabled:NO];
	[newResourceButton setEnabled:NO];
	[toggleResourcesButton setEnabled:NO];
	
	NSRect contentFrame = [[self tabContent] frame];
	[contentResourceSplit setFrame:contentFrame];
	
	[[self tabContent] setNeedsDisplay:YES];
}

- (void) setFullScreen:(BOOL)inFullScreen
{
	[entryCellController setFullScreen:inFullScreen];
}

#pragma mark -
#pragma mark RBSplitView Delegation

- (void)splitView:(RBSplitView*)sender willDrawSubview:(RBSplitSubview*)subview inRect:(NSRect)rect
{
	[[NSColor darkGrayColor] set];
	NSFrameRect(rect);
}

// This makes it possible to drag the divider around by the dragView.
- (unsigned int)splitView:(RBSplitView*)sender 
		dividerForPoint:(NSPoint)point inSubview:(RBSplitSubview*)subview
{
	if ( [sender tag] == 2 && subview == [sender subviewAtPosition:1] ) 
	{
		if ([resourcesDragView mouse:[resourcesDragView convertPoint:point fromView:sender] inRect:[resourcesDragView bounds]])
			return 0;
	}
	
	return NSNotFound;
}

// This changes the cursor when it's over the dragView.
- (NSRect)splitView:(RBSplitView*)sender cursorRect:(NSRect)rect forDivider:(unsigned int)divider 
{
	if ( [sender tag] == 2 && divider == 0 )
		[sender addCursorRect:[resourcesDragView convertRect:[resourcesDragView bounds] toView:sender]
				cursor:[RBSplitView cursor:RBSVVerticalCursor]];
	
	return rect;
}

// this prevents a subview from resizing while the others around it do
- (void)splitView:(RBSplitView*)sender wasResizedFrom:(float)oldDimension to:(float)newDimension 
{
	if ( [sender tag] == 2 )
		[sender adjustSubviewsExcepting:[sender subviewAtPosition:1]];
}

- (void)splitView:(RBSplitView*)sender didCollapse:(RBSplitSubview*)subview
{
	if ( [sender tag] == 2 && subview == [sender subviewAtPosition:1] )
	{
		[self _updateResourceToggleImage];
		[self performSelector:@selector(_hideResourcesSubview:) withObject:self afterDelay:0.1];
	}
}

- (void)splitView:(RBSplitView*)sender didExpand:(RBSplitSubview*)subview
{
	if ( [sender tag] == 2 && subview == [sender subviewAtPosition:1] )
		[self _updateResourceToggleImage];
}


#pragma mark -

- (void) _hideResourcesSubview:(id)anObject
{
	[[contentResourceSplit subviewAtPosition:1] setHidden:YES];
}

- (void) _updateResourceToggleImage
{
	//NSLog(@"%s",__PRETTY_FUNCTION__);
	
	if ( [[contentResourceSplit subviewAtPosition:1] isHidden] )
	{
		[resourceToggle setImage:[NSImage imageNamed:@"HideResourcesEnabled.png"]];
		[resourceToggle setAlternateImage:[NSImage imageNamed:@"HideResourcesPressed.png"]];
	}
	else
	{
		[resourceToggle setImage:[NSImage imageNamed:@"ShowResourcesEnabled.png"]];
		[resourceToggle setAlternateImage:[NSImage imageNamed:@"ShowResourcesPressed.png"]];
	}
}

#pragma mark -
#pragma mark Entry Cell Delegation

- (void) entryCellController:(EntryCellController*)aController 
		clickedOnEntry:(JournlerEntry*)anEntry 
		modifierFlags:(unsigned int)flags 
		highlight:(NSString*)aTerm
{
	if ( flags & NSCommandKeyMask )
	{
		if ( flags & NSAlternateKeyMask )
		{
			// select the entry in a new window
			EntryWindowController *entryWindow = [[[EntryWindowController alloc] initWithJournal:[self journal]] autorelease];
			[entryWindow showWindow:self];
		
			// set it's selection to our current selection
			[[entryWindow selectedTab] selectDate:nil folders:nil entries:[NSArray arrayWithObject:anEntry] resources:nil];
			[[entryWindow selectedTab] appropriateFirstResponder:[entryWindow window]];
			[[entryWindow selectedTab] highlightString:aTerm];
		}
		else
		{
			// select the entry in a new tab
			[[self valueForKey:@"owner"] newTab:self];
			TabController *theTab = [[self valueForKeyPath:@"owner.tabControllers"] lastObject];
			[theTab selectDate:[anEntry valueForKey:@"calDate"] folders:nil entries:[NSArray arrayWithObject:anEntry] resources:nil];
			[theTab highlightString:aTerm];
			
			// select the tab if the shift key is down
			if ( flags & NSShiftKeyMask )
				[[self valueForKey:@"owner"] selectTabAtIndex:-1 force:NO];
		}
	}
	else
	{
		// select the entry ourselves
		[self setSelectedEntries:[NSArray arrayWithObject:anEntry]];
		[self highlightString:aTerm];
	}
}

- (void) entryCellController:(EntryCellController*)aController 
		clickedOnResource:(JournlerResource*)aResource 
		modifierFlags:(unsigned int)flags 
		highlight:(NSString*)aTerm
{
		
	if ( flags & NSCommandKeyMask )
	{
		if ( flags & NSAlternateKeyMask )
		{
			EntryWindowController *aWindow = [[[EntryWindowController alloc] initWithJournal:[self journal]] autorelease];
			[aWindow showWindow:self];
	
			[[aWindow selectedTab] selectDate:nil 
					folders:nil 
					entries:[NSArray arrayWithObject:[aResource valueForKey:@"entry"]] 
				resources:[NSArray arrayWithObject:aResource]];
			 
			[[aWindow selectedTab] appropriateFirstResponder:[aWindow window]];
			[[aWindow selectedTab] highlightString:aTerm];
		}
		else
		{
			// select the resource in a new tab
			[[self valueForKey:@"owner"] newTab:self];
			TabController *theTab = [[self valueForKeyPath:@"owner.tabControllers"] lastObject];
			[theTab selectDate:[aResource valueForKeyPath:@"entry.calDate"] 
					folders:nil 
					entries:[NSArray arrayWithObject:[aResource valueForKey:@"entry"]] 
					resources:[NSArray arrayWithObject:aResource]];
			[theTab highlightString:aTerm];
			
			// select the tab if the shift key is down
			if ( flags & NSShiftKeyMask )
				[[self valueForKey:@"owner"] selectTabAtIndex:-1 force:NO];
		}
	}
	
	else if ( flags & NSAlternateKeyMask )
	{
		// open the link in the default application
		[aResource openWithFinder];
	}
	
	else
	{
		if ( [aResource representsFile] 
			&& ( ( [aResource isAppleScript] || [aResource isApplication] ) 
			&& [[NSUserDefaults standardUserDefaults] boolForKey:@"ExecuteAppAndScriptLinks"] ) )
		{
			// override default behavior if the resources is an exectuable and the user has specified it
			
			NSString *resourcePath;
			if ( [aResource isApplication] )
			{
				resourcePath = [aResource originalPath];
				if ( resourcePath != nil )
					[[NSWorkspace sharedWorkspace] openFile:resourcePath];
				else
					NSBeep();
			}
			else if ( [aResource isAppleScript] )
			{
				NSString *scriptPath = [aResource originalPath];
				if ( scriptPath == nil )
				{
					NSBeep();
					[[NSAlert resourceNotFound] runModal];
				}
				else
				{
					[[NSApp delegate] runAppleScriptAtPath:scriptPath showErrors:YES];
				}
			}
		}
		
		else if ( [aResource representsFile] 
				&& [aResource isDirectory] && ![aResource isFilePackage]
				&& [[NSUserDefaults standardUserDefaults] boolForKey:@"OpenFolderLinksInFinder"] )
		{
			NSString *folderPath = [aResource originalPath];
			if ( folderPath == nil )
			{
				NSBeep();
				[[NSAlert resourceNotFound] runModal];
			}
			else
			{
				// reveal the folder
				// [[NSWorkspace sharedWorkspace] selectFile:folderPath inFileViewerRootedAtPath:[folderPath stringByDeletingLastPathComponent]];
				
				// open the folder
				[[NSWorkspace sharedWorkspace] openFile:folderPath];
			}
		}
		
		else
		{
		
			// locate the resource
			// action depends on the user's preferences
			NSInteger mediaAction = [[NSUserDefaults standardUserDefaults] integerForKey:@"OpenMediaInto"];
			
			if ( mediaAction == kOpenMediaIntoWindow )
			{
				EntryWindowController *aWindow = [[[EntryWindowController alloc] initWithJournal:[self journal]] autorelease];
				[aWindow showWindow:self];
	
				[[aWindow selectedTab] selectDate:nil 
						folders:nil 
						entries:[NSArray arrayWithObject:[aResource valueForKey:@"entry"]] 
						resources:[NSArray arrayWithObject:aResource]];
				
				[[aWindow selectedTab] appropriateFirstResponder:[aWindow window]];
				[[aWindow selectedTab] highlightString:aTerm];

			}
			
			else if ( mediaAction == kOpenMediaIntoFinder )
			{
				// open the resource in its own application
				[aResource openWithFinder];
			}
			
			else /* if ( mediaAction == kOpenMediaIntoTab ) */
			{
				// open the resource in the selectd tab
				if ( [[resourceController resources] indexOfObjectIdenticalTo:aResource] == NSNotFound )
				{
					// locate the resource's entry
					JournlerEntry *anEntry = [aResource valueForKey:@"entry"];
					[self setSelectedEntries:[NSArray arrayWithObject:anEntry]];
				}
				
				// select the resource
				[resourceController selectResource:aResource byExtendingSelection:YES];
				[self highlightString:aTerm];
			}
		}
	}
}

- (void) entryCellController:(EntryCellController*)aController clickedOnFolder:(JournlerCollection*)aFolder modifierFlags:(unsigned int)flags
{
	NSBeep();
	return;
}


- (void) entryCellController:(EntryCellController*)aController clickedOnURL:(NSURL*)aURL modifierFlags:(unsigned int)flags
{
	// the url must be located in the list of available resources. 
	// If it isn't there, it must be added to the selected entry
	
	NSArray *theResources = [resourceController resources];
	JournlerResource *theResource = nil;
    
    for ( JournlerResource *aResource in theResources )
	{
		if ( [aResource representsURL] && [[aResource valueForKey:@"urlString"] isEqualToString:[aURL absoluteString]] )
		{
			theResource = aResource;
			break;
		}
	}
	
	// create the url resource if no resource was found
	if ( theResource == nil )
		theResource = [[aController selectedEntry] resourceForURL:[aURL absoluteString] title:nil];
	
	// open the resource according to the available flags
	if ( flags & NSCommandKeyMask )
	{
		// open the resource in a new window if possible
		if ( flags & NSAlternateKeyMask )
		{
			EntryWindowController *aWindow = [[[EntryWindowController alloc] initWithJournal:[self journal]] autorelease];
			[aWindow showWindow:self];
	
			[[aWindow selectedTab] selectDate:nil folders:nil entries:[NSArray arrayWithObject:[theResource valueForKey:@"entry"]] 
			 resources:[NSArray arrayWithObject:theResource]];
			
			[[aWindow selectedTab] appropriateFirstResponder:[aWindow window]];

			/*
			NSURL *mediaURL = aURL;
			JournlerMediaViewer *mediaViewer = [[[JournlerMediaViewer alloc] initWithURL:mediaURL uti:(NSString*)kUTTypeURL] autorelease];
			if ( mediaViewer == nil )
			{
				NSLog(@"%s - problem allocating media viewer for url %@", __PRETTY_FUNCTION__, mediaURL);
				[[NSWorkspace sharedWorkspace] openURL:mediaURL];
			}
			else
			{
				[mediaViewer setRepresentedObject:theResource];
				[mediaViewer showWindow:self];
			}
			*/
		}
		else
		{
			// select the resource in a new tab
			[[self valueForKey:@"owner"] newTab:self];
			TabController *theTab = [[self valueForKeyPath:@"owner.tabControllers"] lastObject];
			[theTab selectDate:[theResource valueForKeyPath:@"entry.calDate"] folders:nil 
					entries:[NSArray arrayWithObject:[theResource valueForKey:@"entry"]] resources:[NSArray arrayWithObject:theResource]];
			
			// select the tab if the shift key is down
			if ( flags & NSShiftKeyMask )
				[[self valueForKey:@"owner"] selectTabAtIndex:-1 force:NO];
		}
	}
	
	else if ( flags & NSAlternateKeyMask )
	{
		// open the link in the default application
		[theResource openWithFinder];
	}
	
	else
	{
		// act according to the user's media preference
		
		NSInteger mediaAction = [[NSUserDefaults standardUserDefaults] integerForKey:@"OpenMediaInto"];
		
		if ( mediaAction == kOpenMediaIntoWindow )
		{
			EntryWindowController *aWindow = [[[EntryWindowController alloc] initWithJournal:[self journal]] autorelease];
			[aWindow showWindow:self];
	
			[[aWindow selectedTab] selectDate:nil folders:nil entries:[NSArray arrayWithObject:[theResource valueForKey:@"entry"]] 
			 resources:[NSArray arrayWithObject:theResource]];
			
			[[aWindow selectedTab] appropriateFirstResponder:[aWindow window]];
			
			/*
			NSURL *mediaURL = aURL;
			JournlerMediaViewer *mediaViewer = [[[JournlerMediaViewer alloc] initWithURL:mediaURL uti:(NSString*)kUTTypeURL] autorelease];
			if ( mediaViewer == nil )
			{
				NSLog(@"%s - problem allocating media viewer for url %@", __PRETTY_FUNCTION__, mediaURL);
				[[NSWorkspace sharedWorkspace] openURL:mediaURL];
			}
			else
			{
				[mediaViewer setRepresentedObject:theResource];
				[mediaViewer showWindow:self];
			}
			*/
		}
		
		else if ( mediaAction == kOpenMediaIntoFinder )
		{
			// open the resource in its own application
			[theResource openWithFinder];
		}
		
		else /* if ( mediaAction == kOpenMediaIntoTab ) */
		{
			// simply select the resource
			[resourceController selectResource:theResource byExtendingSelection:NO];
		}
	}
}

#pragma mark -
#pragma mark Resource Cell Delegation

- (void) resourceCellController:(ResourceCellController*)aController didChangeTitle:(NSString*)newTitle
{
	if ( [[self owner] respondsToSelector:@selector(tabController:didChangeTitle:)] )
		[[self owner] tabController:self didChangeTitle:newTitle];
}

- (void) resourceCellController:(ResourceCellController*)aController didChangePreviewIcon:(NSImage*)icon forResource:(JournlerResource*)aResource
{
	// update the resource pane
	[resourceTable setNeedsDisplayInRect:[resourceTable rectOfRow:[resourceTable selectedRow]]];
}

- (void) webViewController:(WebViewController*)aController appendPasteboardLink:(NSPasteboard*)pboard 
{
	[entryCellController webViewController:aController appendPasteboardLink:pboard];
}

- (void) webViewController:(WebViewController*)aController appendPasteboardContents:(NSPasteboard*)pboard 
{
	[entryCellController webViewController:aController appendPasteboardContents:pboard];
}

- (void) webViewController:(WebViewController*)aController appendPasetboardWebArchive:(NSPasteboard*)pboard
{
	[entryCellController webViewController:aController appendPasetboardWebArchive:pboard];
}

#pragma mark -
#pragma mark Token Menu Actions

- (void) selectEntryFromTokenMenu:(NSMenuItem*)aMenuItem
{
	JournlerObject *anObject = [aMenuItem representedObject];
	
	NSInteger eventModifiers = 0;
	NSInteger modifiers = GetCurrentKeyModifiers();
	
	if ( modifiers & shiftKey ) eventModifiers |= NSShiftKeyMask;
	if ( modifiers & optionKey ) eventModifiers |= NSAlternateKeyMask;
	if ( modifiers & cmdKey ) eventModifiers |= NSCommandKeyMask;
	if ( modifiers & controlKey ) eventModifiers |= NSControlKeyMask;
	
	if ( [anObject isKindOfClass:[JournlerEntry class]] )
	{
		JournlerEntry *theEntry = (JournlerEntry*)anObject;
		[self entryCellController:entryCellController clickedOnEntry:theEntry modifierFlags:eventModifiers highlight:nil];
		//[self highlightString:aTerm];
	}
	
	else if ( [anObject isKindOfClass:[JournlerResource class]] )
	{
		JournlerResource *theResource = (JournlerResource*)anObject;
		[self entryCellController:entryCellController clickedOnResource:theResource modifierFlags:eventModifiers highlight:nil];
		//[self highlightString:aTerm];
	}
	
	else
	{
		NSBeep();
	}

}

#pragma mark -
#pragma mark Audio/Video Recording

- (void) sproutedVideoRecorder:(SproutedRecorder*)recorder insertRecording:(NSString*)path title:(NSString*)title
{
	#ifdef __DEBUG__
	NSLog(@"%s %@",__PRETTY_FUNCTION__,path);
	#endif
	
	NSArray *theEntries = [self selectedEntries];
	if ( theEntries == nil || [theEntries count] != 1 )
	{
		NSBeep(); return;
	}
	
	// pass the message to the cell controller
	[entryCellController sproutedVideoRecorder:recorder insertRecording:path title:title];
}

- (void) sproutedAudioRecorder:(SproutedRecorder*)recorder insertRecording:(NSString*)path title:(NSString*)title
{
	#ifdef __DEBUG__
	NSLog(@"%s %@",__PRETTY_FUNCTION__,path);
	#endif
	
	NSArray *theEntries = [self selectedEntries];
	if ( theEntries == nil || [theEntries count] != 1 )
	{
		NSBeep(); return;
	}
	
	// pass the message to the cell controller
	[entryCellController sproutedAudioRecorder:recorder insertRecording:path title:title];
}

- (void) sproutedSnapshot:(SproutedRecorder*)recorder insertRecording:(NSString*)path title:(NSString*)title
{
	#ifdef __DEBUG__
	NSLog(@"%s %@",__PRETTY_FUNCTION__,path);
	#endif
	
	NSArray *theEntries = [self selectedEntries];
	if ( theEntries == nil || [theEntries count] != 1 )
	{
		NSBeep(); return;
	}
	
	// pass the message to the cell controller
	[entryCellController sproutedSnapshot:recorder insertRecording:path title:title];
}

#pragma mark -

- (IBAction) insertContact:(id)sender
{
	if ( ![sender respondsToSelector:@selector(cell)] || ![[sender cell] respondsToSelector:@selector(representedObject)] )
		NSBeep();
	else if ( [self activeContentView] != [entryCellController contentView] )
		NSBeep();
	else
	{
		// grab the contacts from the cell's represented object
		NSArray *contacts = [[sender cell] representedObject];
		if ( [contacts count] == 0 )
			NSBeep();
		else
		{
			// create and select a new default entry if necessary
			if ( [entryCellController selectedEntry] == nil )
				[self entryCellController:entryCellController newDefaultEntry:nil];
			
			// if that still didn't work, bail
			if ( [entryCellController selectedEntry] == nil )
				NSBeep();
			else
			{
				NSInteger i;
				
				for ( i = 0; i < [contacts count]; i++ )
				{
					id aContact = [contacts objectAtIndex:i];
					
					if ( [aContact isKindOfClass:[ABPerson class]] )
						[[entryCellController textView] addPersonToText:(ABPerson*)aContact];
					
					if ( i != [contacts count] - 1 )
						[[entryCellController textView] insertText:@" | "];
				}
			}
		}
	}
}


#pragma mark -
#pragma mark Working with entries

- (IBAction) printDocument:(id)sender
{
	// dispatch the print request to the appropriate view controller
	if ( [resourceCellController trumpsPrint] )
	{
		// print whatever the resource view shows (is browsing)
		[resourceCellController printDocument:sender];
	}
	else if ( [[self selectedResources] count] > 0 )
	{
		// print whatever the resource view shows
		[resourceCellController printDocument:sender];
	}
	else if ( [[self selectedEntries] count] > 0 )
	{	
		// print the selected entries
		NSArray *printArray = [[[NSArray alloc] initWithArray:[self selectedEntries]] autorelease];
		NSDictionary *printDict = [NSDictionary dictionaryWithObjectsAndKeys: printArray, @"entries", nil];
	
		[self printEntries:printDict];
	}
	else
	{
		// nothing to print
		NSBeep();
	}
}

- (IBAction) emailEntrySelection:(id)sender
{
	// grab the available entries from the controller
	NSArray *theEntries = [self selectedEntries];
	if ( theEntries == nil || [theEntries count] == 0 ) {
		NSBeep(); return;
	}
	
	// determine whether to email a single entry or multiple entries
	if ( [theEntries count] == 1 && [entryCellController hasSelectedText] ) 
	{
		// would be neat to include attachments in the selection only
		
		// special case when dealing with a single entry - may be selection only
		NSAttributedString *content = [entryCellController selectedText];
		//[JUtility sendRichMail:content to:@"" subject:[[theEntries objectAtIndex:0] valueForKey:@"title"] isMIME:YES withNSMail:NO];
		[JournlerApplicationDelegate sendRichMail:content to:@"" subject:[[theEntries objectAtIndex:0] valueForKey:@"title"] isMIME:YES withNSMail:NO];
	}
	
	else 
	{
		[super emailEntrySelection:sender];
	}
}

- (void) servicesMenuAppendSelection:(NSPasteboard*)pboard desiredType:(NSString*)type
{
	// pass the message to the cell controller
	[entryCellController servicesMenuAppendSelection:pboard desiredType:type];
}

#pragma mark -
#pragma mark Working with Resources

- (IBAction) showEntryForSelectedResource:(id)sender
{
	NSArray *theResourceSelection = [self selectedResources];
	[self _showEntryForSelectedResources:theResourceSelection];
}

- (BOOL) _showEntryForSelectedResources:(NSArray*)anArray
{
	// jumps to the entry for the resource
	// used to select the owning entry, now prefers an entry that is already selected if possible
	
	if ( anArray == nil || [anArray count] == 0 )
	{
		NSBeep();
		return NO;
	}
	
	JournlerEntry *theEntry;
	JournlerResource *aResource = [anArray objectAtIndex:0];
	
	// maybe this resource encompasse a temporary entry
	if ( [aResource representsJournlerObject] )
	{
		if ( ( theEntry = [aResource journlerObject] ) == nil )
		{
			NSBeep(); return NO;
		}
	}
	else
	{
		NSArray *allEntries = [aResource entries];
		theEntry = [[self selectedEntries] firstObjectCommonWithArray:allEntries];
		
		if ( theEntry == nil )
			theEntry = [aResource entry];
	}

	[resourceTable deselectAll:self];
	[self setSelectedEntries:[NSArray arrayWithObject:theEntry]];
	
	// in the entry tab the entry must be available if the resource is available
	[resourceTable deselectAll:self];
	return YES;
	
	/*
	JournlerEntry *anEntry = [[anArray objectAtIndex:0] valueForKey:@"entry"];
	
	if ( anEntry == nil )
	{
		// maybe this resource encompasse a temporary entry
		JournlerResource *aResource = [anArray objectAtIndex:0];
		if ( ![aResource representsJournlerObject] || ( anEntry = [aResource journlerObject] ) == nil )
		{
			// if it's still nil get the hell out of here
			NSBeep(); return NO;
		}
	}
	
	[resourceTable deselectAll:self];
	[self setSelectedEntries:[NSArray arrayWithObject:anEntry]];
	
	// in the entry tab the entry must be available if the resource is available
	[resourceTable deselectAll:self];
	return YES;
	*/
}

- (IBAction) deleteSelectedResources:(id)sender
{	
	
	NSArray *theResources = [NSArray arrayWithArray:[self selectedResources]];
	NSArray *theEntries = [NSArray arrayWithArray:[self selectedEntries]];
	
	if ( theResources == nil || [theResources count] == 0 || theEntries == nil || [theEntries count] == 0 )
	{
		NSBeep(); return;
	}
	
	NSBeep();
	if ( [[NSAlert confirmResourceDelete] runModal] != NSAlertFirstButtonReturn )
		return;
		
	// deselect
	[resourceTable deselectAll:self];
	
	BOOL success;
	NSArray *errors = nil;
	success = [[self journal] removeResources:theResources fromEntries:theEntries errors:&errors];
	
	if ( !success )
	{
		NSBeep();
		NSLog(@"%s - problems removing the resources { %@ } from the entries { %@ }, errors: %@",
              __PRETTY_FUNCTION__, [theResources valueForKey:@"tagID"], 
              [theEntries valueForKey:@"tagID"], errors);
	}
}


#pragma mark -
#pragma mark Appearance

- (IBAction) toggleHeader:(id)sender
{
	// just pass it to the cell controller
	[entryCellController setHeaderHidden:![entryCellController headerHidden]];
}

- (IBAction) toggleFooter:(id)sender
{
	// just pass it to the cell controller
	[entryCellController setFooterHidden:![entryCellController footerHidden]];
}

- (IBAction) toggleResources:(id)sender
{
	if ( [[contentResourceSplit subviewAtPosition:1] isHidden] ) 
	{
		[[contentResourceSplit subviewAtPosition:1] setHidden:NO];
		
		if ( [[contentResourceSplit subviewAtPosition:1] isCollapsed] )
		{
			// would be nice to return to last size, but last size is size right before collapse and hide
			[[contentResourceSplit subviewAtPosition:1] setDimension:150];
			[[contentResourceSplit subviewAtPosition:1] expand];
		}
	}
	else
		[[contentResourceSplit subviewAtPosition:1] setHidden:YES];
	
	// update the image
	[self _updateResourceToggleImage];
	
}

- (IBAction) showResourceWorktoolContextual:(id)sender
{
	[resourceWorktoolPopCell performClickWithFrame:[resourceWorktool bounds] inView:resourceWorktool];
}

- (IBAction) showNewResourceSheet:(id)sender
{
	// simulates a popup button but with a sheet-like window
	// switched to menu
	
	[newResourcePopCell performClickWithFrame:[newResourceButton bounds] inView:newResourceButton];
}

- (IBAction) insertNewResource:(id)sender
{
	#ifdef __DEBUG__
	NSLog(@"%s - %i",__PRETTY_FUNCTION__,[sender tag]);
	#endif
	
	switch ( [sender tag] )
	{
	case kResourceRequestContact:
		[NSApp sendAction:@selector(showContactsBrowser:) to:nil from:self];
		break;
	case kResourceRequestEntry:
		[NSApp sendAction:@selector(showEntryBrowser:) to:nil from:self];
		break;
	case kResourceRequestFile:
		[self addFileFromFinder:self];
		break;
	case kResourceRequestPhoto:
		[[iMediaBrowser sharedBrowserWithDelegate:[NSApp delegate]] showWindow:self];
		[[iMediaBrowser sharedBrowserWithDelegate:[NSApp delegate]] performSelector:@selector(showMediaBrowser:) withObject:@"iMBPhotosController" afterDelay:0.3];
		break;
	case kResourceRequestAudio:
		[[iMediaBrowser sharedBrowserWithDelegate:[NSApp delegate]] showWindow:self];
		[[iMediaBrowser sharedBrowserWithDelegate:[NSApp delegate]] performSelector:@selector(showMediaBrowser:) withObject:@"iMBMusicController" afterDelay:0.3];
		break;
	case kResourceRequestMovie:
		[[iMediaBrowser sharedBrowserWithDelegate:[NSApp delegate]] showWindow:self];
		[[iMediaBrowser sharedBrowserWithDelegate:[NSApp delegate]] performSelector:@selector(showMediaBrowser:) withObject:@"iMBMoviesController" afterDelay:0.3];
		break;
	case kResourceRequestBookmark:
		[[iMediaBrowser sharedBrowserWithDelegate:[NSApp delegate]] showWindow:self];
		[[iMediaBrowser sharedBrowserWithDelegate:[NSApp delegate]] performSelector:@selector(showMediaBrowser:) withObject:@"iMBLinksController" afterDelay:0.3];
		break;
	}
}

- (IBAction) addFileFromFinder:(id)sender 
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	NSInteger result;
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	
	[oPanel setAllowsMultipleSelection:YES];
	[oPanel setCanChooseDirectories:YES];
	[oPanel setCanChooseFiles:YES];
	[oPanel setCanCreateDirectories:YES];
	[oPanel setTitle:NSLocalizedString(@"word insert", @"")];
	[oPanel setPrompt:NSLocalizedString(@"word insert", @"")];
	
	result = [oPanel runModalForDirectory:nil file:nil types:nil];
    if (result == NSOKButton) 
	{
        // create and select a new default entry if necessary
		if ( [entryCellController selectedEntry] == nil )
			[self entryCellController:entryCellController newDefaultEntry:nil];
	
		// if that still didn't work, bail
		if ( [entryCellController selectedEntry] == nil )
			NSBeep();
		else
		{
			NSInteger j;
			NSArray *files = [oPanel filenames];
			
			// add the files to the entry
			for ( j = 0; j < [files count]; j++ ) {
				[[entryCellController textView] addFileToText:[files objectAtIndex:j] fileName:nil forceTitle:NO resourceCommand:kNewResourceUseDefaults];
			}
		}
    }
}

#pragma mark -

- (BOOL) handlesFindCommand
{
	return ( [self activeContentView] == [entryCellController contentView] 
			|| ( [self activeContentView] == [resourceCellController contentView] && [resourceCellController handlesFindCommand] ) );
}

- (void)performCustomFindPanelAction:(id)sender
{
	if ( [self activeContentView] == [entryCellController contentView] )
		[entryCellController performFindPanelAction:sender];
		
	else if ( [self activeContentView] == [resourceCellController contentView] && [resourceCellController handlesFindCommand] )
		[resourceCellController performSelector:@selector(performCustomFindPanelAction:) withObject:sender];
}

- (BOOL) handlesTextSizeCommand
{
	return ( [self activeContentView] == [resourceCellController contentView] && [resourceCellController handlesTextSizeCommand] );
}

- (void) performCustomTextSizeAction:(id)sender
{
	if ( [self activeContentView] == [resourceCellController contentView] && [resourceCellController handlesTextSizeCommand] )
		[resourceCellController performSelector:@selector(performCustomTextSizeAction:) withObject:sender];
}

- (IBAction) performFindPanelAction:(id)sender
{
	if ( [self activeContentView] == [entryCellController contentView] )
		[entryCellController performFindPanelAction:sender];
	else
		NSBeep();
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	BOOL enabled = YES;
	//NSInteger tag = [menuItem tag];
	SEL action = [menuItem action];
	
	if ( action == @selector(toggleHeader:) )
		[menuItem setState:![entryCellController headerHidden]];
		
	else if ( action == @selector(toggleFooter:) )
		[menuItem setState:![entryCellController footerHidden]];
	
	else if ( action == @selector(showEntryForSelectedResource:) )
		enabled = [resourceController validateMenuItem:menuItem];
	
	else if ( action == @selector(toggleResources:) )
	{
		NSString *title = ( [[contentResourceSplit subviewAtPosition:1] isHidden] ? NSLocalizedString(@"show resources",@"") : NSLocalizedString(@"hide resources",@"") );
		[menuItem setTitle:title];
	}
		
	else if ( action == @selector(toggleRuler:) )
	{
		enabled = ( [self activeContentView] == [entryCellController contentView] );
		[menuItem setState:( [[entryCellController textView] isRulerVisible] ? NSOnState : NSOffState )];
	}
	
	else if ( action == @selector(performCustomFindPanelAction:) )
	{
		if ( [self activeContentView] == [entryCellController contentView] )
			enabled = YES;
		else if ( [resourceCellController handlesFindCommand] )
			enabled = [resourceCellController validateMenuItem:menuItem];
	}
	
	/*
	else if ( action == @selector(performFindPanelAction:) )
	{
		if ( [self activeContentView] == [entryCellController contentView] )
			enabled = YES;
		else
			enabled = NO;
	}
	*/
	
	else
	{
		enabled = [super validateMenuItem:menuItem];
	}
	
	return enabled;
}

- (IBAction) newWebBrower:(id)sender
{
	[self setActiveContentView:[resourceCellController contentView]];
	[resourceCellController openURL:nil];
}

#pragma mark -

- (NSArray*) scriptVisibleEntries
{
	// subclasses should override to return the list of entries currently visible in the tab
	return [self selectedEntries];
}



@end
