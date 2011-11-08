//
//  JournalTabController.m
//  Journler
//
//  Created by Philip Dow on 10/24/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

/*
 Redistribution and use in source and binary forms, with or without modification, are permitted
 provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions
 and the following disclaimer in the documentation and/or other materials provided with the
 distribution.
 
 * Neither the name of the author nor the names of its contributors may be used to endorse or
 promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// Basically, you can use the code in your free, commercial, private and public projects
// as long as you include the above notice and attribute the code to Philip Dow / Sprouted
// If you use this code in an app send me a note. I'd love to know how the code is used.

// Please also note that this copyright does not supersede any other copyrights applicable to
// open source code used herein. While explicit credit has been given in the Journler about box,
// it may be lacking in some instances in the source code. I will remedy this in future commits,
// and if you notice any please point them out.

#import "JournalTabController.h"
#import "JournlerWindowController.h"
#import "Definitions.h"

#import "JournlerApplicationDelegate.h"

#import "JournlerEntry.h"
#import "JournlerCollection.h"
#import "JournlerJournal.h"
#import "JournlerSearchManager.h"

#import "FoldersController.h"
#import "DatesController.h"
#import "EntriesController.h"
#import "ResourceController.h"

#import "Calendar.h"
#import "EntryCellController.h"
#import "ResourceCellController.h"
#import "EntryFilterController.h"

#import <SproutedUtilities/SproutedUtilities.h>

#import "PDBorderedFill.h"
#import "NSAttributedString+JournlerAdditions.h"
#import "NSAlert+JournlerAdditions.h"

#import "EntriesTableView.h"
#import "ResourceTableView.h"
#import "CollectionsSourceList.h"
#import "LinksOnlyNSTextView.h"
#import "CalendarController.h"

#import "EntryWindowController.h"

#import "IntelligentCollectionController.h"
#import "FolderInfoController.h"
#import "NewEntryController.h"
#import "EntryInfoController.h"
#import "MultipleEntryInfoController.h"
#import "ResourceInfoController.h"

#import "JournlerMediaViewer.h"
#import "WebViewController.h"

typedef enum {
	kResourceRequestAudio = 0,
	kResourceRequestPhoto = 1,
	kResourceRequestMovie = 2,
	kResourceRequestBookmark = 3,
	kResourceRequestContact = 4,
	kResourceRequestFile = 5,
	kResourceRequestEntry = 6
} NewResourceRequest;

static NSDictionary* StatusBarTextAttributes()
{
	static NSDictionary *textAttributes = nil;
	if ( textAttributes == nil )
	{
		NSShadow *textShadow;
		NSMutableParagraphStyle *paragraphStyle;
		
		textShadow = [[NSShadow alloc] init];
		[textShadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.6]];
		[textShadow setShadowOffset:NSMakeSize(0,-1)];
		
		paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[paragraphStyle setAlignment:NSCenterTextAlignment];
		[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
		
		textAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
				textShadow, NSShadowAttributeName, 
				[NSFont boldSystemFontOfSize:11], NSFontAttributeName,
				[NSColor blackColor], NSForegroundColorAttributeName,
				paragraphStyle, NSParagraphStyleAttributeName, nil];
		
		[textShadow release];
		[paragraphStyle release];
	}
	return textAttributes;
}

static NSArray* EntrySearchDescriptors()
{
	static NSArray *descriptors = nil;
	if ( descriptors == nil )
	{
		NSSortDescriptor *searchSort = [[NSSortDescriptor alloc] initWithKey:@"relevanceNumber" 
				ascending:NO selector:@selector(compare:)];
		descriptors = [[NSArray alloc] initWithObjects:searchSort,nil];
		
		[searchSort release];
	}
	return descriptors;
}

static NSSortDescriptor *FoldersByIndexSortPrototype()
{
	static NSSortDescriptor *descriptor = nil;
	if ( descriptor == nil )
	{
		descriptor = [[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES selector:@selector(compare:)];
	}
	return descriptor;
}

#pragma mark -

@implementation JournalTabController

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
		worktoolPopCell = [[NSPopUpButtonCell alloc] initTextCell:[NSString string] pullsDown:YES];
		resourceWorktoolPopCell = [[NSPopUpButtonCell alloc] initTextCell:[NSString string] pullsDown:YES];
		newResourcePopCell = [[NSPopUpButtonCell alloc] initTextCell:[NSString string] pullsDown:YES];
		
		usesSmallCalendar = NO; // to be explicit about it
		
		// load the associated bundle
		[NSBundle loadNibNamed:@"JournalTab" owner:self];
	}
	return self;	
}

- (void) awakeFromNib 
{	
	// set up the temporary content, to be immediately replaced by a selection
	activeContentView = contentPlaceholder;
	
	// set the default active content view
	[self setActiveContentView:[entryCellController contentView]];
	
	// the folders controller must know the actual root (vs. the roots children)
	[sourceListController setRootCollection:[[self journal] valueForKey:@"rootCollection"]];	
	
	// set the sort descriptors on the source list
	[sourceListController setSortDescriptors:[NSArray arrayWithObject:FoldersByIndexSortPrototype()]];
	
	// set the header menu for the entry table and the reference table
	[[entriesTable headerView] setMenu:columnsMenu];
	[entriesTable setCornerView:aCornerView];
	
	// size the folder list to fit
	[sourceList sizeToFit];
	
	// prepare the label menu's colors
	[[NSApp delegate] prepareLabelMenu:&labelMenu];
	[[NSApp delegate] prepareLabelMenu:&resourceLabelMenu];
	[[NSApp delegate] prepareLabelMenu:&folderLableMenu];
	[[NSApp delegate] prepareLabelMenu:&folderWorktoolLabelMenu];
	[[NSApp delegate] prepareLabelMenu:&resourceWorktoolLabelMenu];
	
	// prepare the worktool button and associated popup button cell
	[folderWorktool sendActionOn:NSLeftMouseDownMask];
	[resourceWorktool sendActionOn:NSLeftMouseDownMask];
	[newResourceButton sendActionOn:NSLeftMouseDownMask];
	
	[worktoolPopCell setMenu:foldersWorktoolMenu];
	[worktoolPopCell selectItemAtIndex:0];
	[worktoolPopCell setPullsDown:YES];
	
	[resourceWorktoolPopCell setMenu:resourceWorktoolMenu];
	[resourceWorktoolPopCell selectItemAtIndex:0];
	[resourceWorktoolPopCell setPullsDown:YES];
	
	[newResourcePopCell setMenu:newResourceMenu];
	[newResourcePopCell selectItemAtIndex:0];
	[newResourcePopCell setPullsDown:YES];
	
	[emptyTrashItem setKeyEquivalent:[NSString stringWithCharacters:(const unichar[]){NSBackspaceCharacter} length:1]];
	[emptyTrashItem setKeyEquivalentModifierMask:(NSCommandKeyMask|NSShiftKeyMask)];
	
	//[entryInNewTabItem setKeyEquivalent:@"\r"];
	//[entryInNewTabItem setKeyEquivalentModifierMask:NSShiftKeyMask];
	
	//[resourceInNewTabItem setKeyEquivalent:@"\r"];
	//[resourceInNewTabItem setKeyEquivalentModifierMask:NSShiftKeyMask];
	
	//[resourceInNewTabItemB setKeyEquivalent:@"\r"];
	//[resourceInNewTabItemB setKeyEquivalentModifierMask:NSShiftKeyMask];
	
	// prepare the calendar and controller
	calController = [[CalendarController alloc] init];
	
	calendar = [calController calendar];
	[calendar setDelegate:self];
	
	[calendar bind:@"content" 
			toObject:datesController 
			withKeyPath:@"arrangedObjects" 
			options:nil];
			
	[datesController bind:@"selectedDate"
			toObject:calendar 
			withKeyPath:@"selectedDate" 
			options:nil];
	
	// go ahead and add the calendar to the window
	[calendar setFrame:NSMakeRect(0,0,172,170)];
	[calContainer addSubview:calendar];
	
	// then set the variable (use a binding)
	[self bind:@"usesSmallCalendar" 
			toObject:[NSUserDefaultsController sharedUserDefaultsController] 
			withKeyPath:@"values.CalendarUseButton" 
			options:[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithBool:YES], NSNullPlaceholderBindingOption, nil]];
	
	// hook up the resource controller appropriately
	[resourceController bind:@"resources" 
			toObject:entriesController 
			withKeyPath:@"selection.@distinctUnionOfArrays.resources" 
			options:nil];
			
	[resourceController bind:@"folders" 
			toObject:entriesController 
			withKeyPath:@"selection.@distinctUnionOfArrays.collections" 
			options:nil];
	
	// hook up the entry table state to the folders selection (already the case with sort descriptors)
	//[entriesController bind:@"stateArray" toObject:sourceListController withKeyPath:@"selection.entryTableState" options:nil];
	
	// bind ourselves to the folder and entry selection
	[self bind:@"selectedEntries" 
			toObject:entriesController 
			withKeyPath:@"selectedObjects" 
			options:nil];
			
	[self bind:@"selectedFolders" 
			toObject:sourceListController 
			withKeyPath:@"selectedObjects" 
			options:nil];
	
	[self bind:@"selectedResources" 
			toObject:resourceController 
			withKeyPath:@"selectedResources" 
			options:nil];
	
	[self bind:@"selectedDate" 
			toObject:datesController 
			withKeyPath:@"selectedDate" 
			options:nil];
	
	// watch for an entry being trashed to adjust entry selection
	[[NSNotificationCenter defaultCenter] addObserver:self 
			selector:@selector(_journalWillChangeEntrysTrashStatus:) 
			name:JournalWillTrashEntryNotification 
			object:[self journal]];
			
	[[NSNotificationCenter defaultCenter] addObserver:self 
			selector:@selector(_journalWillChangeEntrysTrashStatus:) 
			name:JournalWillUntrashEntryNotification 
			object:[self journal]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
			selector:@selector(_journalDidChangeEntrysTrashStatus:) 
			name:JournalDidTrashEntryNotification 
			object:[self journal]];
		
	[[NSNotificationCenter defaultCenter] addObserver:self 
			selector:@selector(_journalDidChangeEntrysTrashStatus:) 
			name:JournalDidUntrashEntryNotification 
			object:[self journal]];
	
	// watch for completed imports so as to update the calendar
	[[NSNotificationCenter defaultCenter] addObserver:self 
			selector:@selector(_journlerDidFinishImport:) 
			name:JournlerDidFinishImportNotification 
			object:nil];
}

- (void) dealloc
{
#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
#endif
	
	[entryMenu release];
	[foldersMenu release];
	[referenceMenu release];
	[columnsMenu release];
	
	[worktoolPopCell release];
	[newResourcePopCell release];
	[resourceWorktoolPopCell release];
	
	[resourceWorktoolMenu release];
	[foldersWorktoolMenu release];
	[newResourceMenu release];
	
	[calController release];
	[resourceCellController release];
	[entryCellController release];
	
	[searchString release];
	[preSearchDescriptors release];
	
	[sourceListController release];
	[datesController release];
	[entriesController release];
	[resourceController release];
	
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
	
	if ( ![entriesController commitEditing] )
		NSLog(@"%s - problem with committing changes with the entries controller", __PRETTY_FUNCTION__);
	
	if ( ![sourceListController commitEditing] )
		NSLog(@"%s - problem with committing changes with the folders controller", __PRETTY_FUNCTION__);
	
	if ( ![resourceController commitEditing] )
		NSLog(@"%s - problem with committing changes with the folders controller", __PRETTY_FUNCTION__);

	
	// if searching, restore the last sort descriptor and hide the rank column
	if ( [searchString length] != 0 )
	{
		NSLog(@"%s - still searching, fixing table", __PRETTY_FUNCTION__);
		
		[entriesTable setColumnWithIdentifier:@"relevanceNumber" hidden:YES];
		[entriesController setSortDescriptors:preSearchDescriptors];
		
		if ( preSearchTableState != nil )
		{
			[entriesTable restoreStateWithArray:preSearchTableState];
			[preSearchTableState release];
			preSearchTableState = nil;
		}
	}
	
	// unbind our values
	[self unbind:@"selectedEntries"];
	[self unbind:@"selectedFolders"];
	[self unbind:@"selectedResources"];
	[self unbind:@"selectedDate"];
	
	//
	// Note that's its necessary to unbind the interface first
	// I believe I had a problem where unbindinding the controllers first
	// was causing one of my custom delegate methods to be called, which
	// rebound the controller
	
	// unbind the interface: calendar
	[calendar unbind:@"content"];
	
	// unbind the interface: entries table
	[entriesTable unbind:@"stateArray"];
	[entriesTable unbind:@"content"];
	[entriesTable unbind:@"selectionIndexes"];
	[entriesTable unbind:@"sortDescriptors"];
	
	// unbind the interface: source list
	[sourceList unbind:@"content"];
	[sourceList unbind:@"selectionIndexes"];
	[sourceList unbind:@"sortDescriptors"];
	
	// unbind the controllers: dates
	[datesController unbind:@"selectedDate"];
	[datesController unbind:@"contentArray"];
	[datesController setContent:nil];
	
	// unbind the controllers: entries
	[entriesController unbind:@"contentArrayForMultipleSelection"];
	[entriesController unbind:@"contentArray"];
	[entriesController unbind:@"sortDescriptors"];
	[entriesController setContent:nil];

	// unbind the controllers: folder
	[sourceListController unbind:@"contentArray"];
	[sourceListController setContent:nil];

	// unbind the controllers: resources
	[resourceController unbind:@"resources"];
	[resourceController unbind:@"folders"];
	[resourceController setContent:nil];
	
	// notify objects that we're closing
	[entryCellController ownerWillClose];
	[resourceCellController ownerWillClose];
	[calController ownerWillClose:nil];
	[calendar ownerWillClose:nil];
	
	// remove the observers we're responsible for
	[[NSNotificationCenter defaultCenter] removeObserver:self 
			name:JournalWillTrashEntryNotification 
			object:[self journal]];
			
	[[NSNotificationCenter defaultCenter] removeObserver:self 
			name:JournalDidTrashEntryNotification 
			object:[self journal]];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
			name:JournalWillUntrashEntryNotification 
			object:[self journal]];
			
	[[NSNotificationCenter defaultCenter] removeObserver:self 
			name:JournalDidUntrashEntryNotification 
			object:[self journal]];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
			name:JournlerDidFinishImportNotification 
			object:nil];
		
	#ifdef __DEBUG__
	NSLog(@"%s - ending",__PRETTY_FUNCTION__);
	#endif
}

#pragma mark -

- (NSString*) searchString
{
	return searchString;
}

- (void) setSearchString:(NSString*)aString
{
	if ( searchString != aString )
	{
		[searchString release];
		searchString = [aString retain];
	}
}

#pragma mark -

- (void) selectDate:(NSDate*)date folders:(NSArray*)folders entries:(NSArray*)entries resources:(NSArray*)resources 
{
	if ( [date fallsOnSameDay:[self selectedDate]] 
		&& ( [folders isEqual:[self selectedFolders]] || folders == [self selectedFolders] ) 
		&& ( [entries isEqual:[self selectedEntries]] || entries == [self selectedEntries] ) 
		&& ( [resources isEqual:[self selectedResources]] || resources == [self selectedResources]) )
		return;
	
	// #warning check for objects that have been deleted?
	/*
	NSLog(@"%s - date: %@ ; folders : %@ ; entries: %@ ; resources : %@", __PRETTY_FUNCTION__,
			( date ? date : @"none" ), 
			( folders ? [folders valueForKey:@"title"] : @"none" ),
			( entries ? [entries valueForKey:@"title"] : @"none" ),
			( resources ? [resources valueForKey:@"title"] : @"none" ) );
	*/
	
	// register a single, all encomposing undo call while disabling individual undo calls
	recordNavigationEvent = NO;
	[[navigationManager prepareWithInvocationTarget:self]
				selectDate:[self selectedDate] folders:[self selectedFolders] 
				entries:[self selectedEntries] resources:[self selectedResources]];
	
	BOOL forced = NO;
	
	// if only one item has been specified, give it priority, working backwards
	if ( resources != nil && [resources count] != 0 && entries == nil && folders == nil && date == nil )
	{
		// try to select the resource
		if ( [[resourceController resources] containsObjects:resources] )
		{
			forced = YES;
			[resourceTable deselectAll:self];
			
            for ( JournlerResource *aResource in resources )
				[resourceController selectResource:aResource byExtendingSelection:YES];
		}
	}
	
	else if ( entries != nil && [entries count] != 0 && resources == nil && folders == nil && date == nil )
	{
		// try to select the entry
		if ( [[entriesController arrangedObjects] containsObjects:entries] )
		{
			forced = YES;
			[entriesController setSelectedObjects:entries];
		}
	}
	
	else if ( folders != nil && [folders count] != 0 && resources == nil && entries == nil && date == nil )
	{
		// force the folder selection
		
		forced = YES;
		[sourceList deselectAll:self];
		
        for ( JournlerCollection *aFolder in folders )
			[sourceListController selectCollection:aFolder byExtendingSelection:YES];

	}
	
	else if ( date != nil && folders == nil && resources == nil && entries == nil )
	{
		// force the date selection
		forced = YES;
		[calendar setSelectedDate:[date dateWithCalendarFormat:nil timeZone:nil]];
	}
	
	
	// bail if we successfully forced
	if ( forced ) goto bail;
	
	
	// note change here: checking for selected folders is not nil
	if ( ( folders == nil || [folders count] == 0 ) && ( [self selectedFolders] == nil && !(entries == nil || [entries count] == 0) ) ) 
	{
		// checking for a nil or empty folder selection is equivalent to checking for the date
		[calendar setSelectedDate:[date dateWithCalendarFormat:nil timeZone:nil]];
	}
	
	else if ( ![folders isEqualToArray:[self selectedFolders]] && !( folders==nil && [self selectedFolders] == nil) ) 
	{
		// adjust the folders to match the selection but only if no date has been selected
		
		// clear the current selection and force a selection on the new objects
		[sourceList deselectAll:self];
		
        for ( JournlerCollection *aFolder in folders )
			[sourceListController selectCollection:aFolder byExtendingSelection:YES];
	}
	
	
	if ( ![entries isEqualToArray:[self selectedEntries]] && !( entries==nil && [self selectedEntries] == nil) ) 
	{
		// if the folder does not contain the entries, switch to the journal
		if ( ![[entriesController arrangedObjects] containsObjects:entries] && entries != nil )
		{
			[sourceList deselectAll:self];
			[sourceListController selectCollection:[self valueForKeyPath:@"journal.libraryCollection"] byExtendingSelection:NO];
		}
		
		// next adjust the entry to match the selection
		[entriesController setSelectedObjects:entries];
	}
	
	if ( ![resources isEqualToArray:[self selectedResources]] && !( resources==nil && [self selectedResources]==nil) ) 
	{
		// finally adjust the reference to match the selection
		
		if ( ![[resourceController resources] containsObjects:resources] && resources != nil )
		{
			// select the library
			[sourceList deselectAll:self];
			[sourceListController selectCollection:[self valueForKeyPath:@"journal.libraryCollection"] byExtendingSelection:NO];
			
			// select each of the resources's entries
			[entriesController setSelectedObjects:[resources valueForKey:@"entry"]];
		}

		// clear the current selection and force a selection on the new objects
		
		[resourceTable deselectAll:self];
		
        for ( JournlerResource *aResource in resources )
			[resourceController selectResource:aResource byExtendingSelection:YES];
	}
	
bail:
	
	// if no reference is selected, force this entry's content to load
	if ( (resources == nil || [resources count] == 0) && !( [entries count] == 1 && [[entries objectAtIndex:0] selectedResource] != nil ) )
		[self setActiveContentView:[entryCellController contentView]];
	
	recordNavigationEvent = YES;
}

#pragma mark -

- (BOOL) selectResources:(NSArray*)anArray
{	
	// clear the search and filter if there is one
	if ( !( GetCurrentKeyModifiers() & optionKey ) )
		[self clearSearchAndFilter:self];
	
	if ( anArray == nil )
		[resourceTable deselectAll:self];
	else
	{
		// ensure the appropriate entries are selected
		
		// 1. select the library if necessary
		NSArray *resourceEntries = [anArray valueForKey:@"entry"];
		if ( ![[entriesController arrangedObjects] containsObjects:resourceEntries] )
			[sourceListController selectCollection:[[self journal] libraryCollection] byExtendingSelection:NO];
		
		// 2. select those entries
		[self selectEntries:resourceEntries];
		
		// and finally select the resources
		[resourceTable deselectAll:self];
		
        for ( JournlerResource *aResource in anArray )
			[resourceController selectResource:aResource byExtendingSelection:YES];
	}
	
	return YES;
}

- (BOOL) selectFolders:(NSArray*)anArray
{	
	// clear the search and filter if there is one
	if ( !( GetCurrentKeyModifiers() & optionKey ) )
		[self clearSearchAndFilter:self];
	
	if ( anArray == nil )
		[sourceList deselectAll:self];
	else
	{
		[sourceList deselectAll:self];
       
        for ( JournlerCollection *aFolder in anArray )
			[sourceListController selectCollection:aFolder byExtendingSelection:YES];
	}
	
	return YES;
}

- (BOOL) selectEntries:(NSArray*)anArray
{
	// clear the search and filter if there is one
	if ( !( GetCurrentKeyModifiers() & optionKey ) )
		[self clearSearchAndFilter:self];
	
	if ( anArray == nil )
		[entriesTable deselectAll:self];
	else
	{
		// ensure the entries are available for selection
		if ( ![[entriesController arrangedObjects] containsObjects:anArray] )
			[sourceListController selectCollection:[[self journal] libraryCollection] byExtendingSelection:NO];
		
		[entriesController setSelectedObjects:anArray];
	}
	
	return YES;
}

- (BOOL) selectDate:(NSDate*)aDate
{
	// clear the search and filter if there is one
	if ( !( GetCurrentKeyModifiers() & optionKey ) )
		[self clearSearchAndFilter:self];
	
	[calendar setSelectedDate:[aDate dateWithCalendarFormat:nil timeZone:nil]];
	return YES;
}

#pragma mark -

- (void) setSelectedFolders:(NSArray*)anArray
{
	// call super's implementation
	[super setSelectedFolders:anArray];
	
	// clear the search and filter if there is one
	if ( keepSearching == NO && !( GetCurrentKeyModifiers() & optionKey ) )
		[self clearSearchAndFilter:self];

}

- (void) setSelectedEntries:(NSArray*)anArray 
{	
	// call super's implementation
	[super setSelectedEntries:anArray];
	
	// everything should be deselected in the resource table
	recordNavigationEvent = NO;
	[resourceTable deselectAll:self];
	recordNavigationEvent = YES;
	
	// if a single entry is being selected and it holds a last selected resource property, select the resource instead
	if ( [anArray count] == 1 && [[anArray objectAtIndex:0] valueForKey:@"selectedResource"] != nil )
	{
		[resourceController selectResource:[[anArray objectAtIndex:0] valueForKey:@"selectedResource"] byExtendingSelection:NO];
		
		// pass the entries to the cell controller anyway
		[entryCellController setSelectedEntries:anArray];
	}
	else
	{
		// make sure the entry cell is the active view
		[self setActiveContentView:[entryCellController contentView]];	
		
		// pass the entries to the cell controller
		[entryCellController setSelectedEntries:anArray];
		
		// set the highlight
		if ( [[self searchString] length] > 0 )
			[self highlightString:[self searchString]];
	}
	
	// restore the resource table state
	[resourceController restoreStateFromDictionary:[resourceController stateDictionary]];
}

- (void) setSelectedResources:(NSArray*)anArray 
{	
	// call super's implementation
	[super setSelectedResources:anArray];
			
	// make sure the appropriate cell is the active view
	if ( anArray != nil && [anArray count] != 0 )
		[self setActiveContentView:[resourceCellController contentView]];
	else
		[self setActiveContentView:[entryCellController contentView]];
	
	// pass the resources to the reference cell
	[resourceCellController setSelectedResources:anArray];
	
	// set the highlight
	if ( [[self searchString] length] > 0 )
		[self highlightString:[self searchString]];
}

- (void) setSelectedDate:(NSDate*)aDate 
{	
	// call super's implementation
	[super setSelectedDate:aDate];
	
	// clear the search and filter if there is one
	if ( !( GetCurrentKeyModifiers() & optionKey ) )
		[self clearSearchAndFilter:self];
	
	// whenever the date is selected, immediately deselect the folders
	recordNavigationEvent = NO;
	[sourceList selectRowIndexes:nil byExtendingSelection:NO];
	recordNavigationEvent = YES;
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
	
	//[activeContentView retain];
	[aView setFrame:[activeContentView frame]];
	[[activeContentView superview] replaceSubview:activeContentView with:aView];
	
	// rebuild the keyview loop
	/*
	if ( [[self owner] searchOutlet] != nil )
	{
		[sourceList setNextKeyView:[[self owner] searchOutlet]];
		[[[self owner] searchOutlet] setNextKeyView:entriesTable];
	}
	else
	{
		[sourceList setNextKeyView:entriesTable];
	}
	
	if ( [contentResourceSplit isCollapsed] )
	{
		if ( aView == [resourceCellController contentView] )
			[resourceCellController establishKeyViews:entriesTable nextKeyView:sourceList];
		else if ( aView == [entryCellController contentView] )
			[entryCellController establishKeyViews:entriesTable nextKeyView:sourceList];
	}
	else
	{
		[resourceTable setNextKeyView:sourceList];
		if ( aView == [resourceCellController contentView] )
			[resourceCellController establishKeyViews:entriesTable nextKeyView:resourceTable];
		else if ( aView == [entryCellController contentView] )
			[entryCellController establishKeyViews:entriesTable nextKeyView:resourceTable];
	}
	*/
	
	activeContentView = aView;
}

#pragma mark -

- (BOOL) usesSmallCalendar
{
	return usesSmallCalendar;
}

- (void) setUsesSmallCalendar:(BOOL)smallCalendar
{
	if ( usesSmallCalendar != smallCalendar )
	{
		usesSmallCalendar = smallCalendar;
		[calController setUsesSmallCalendar:usesSmallCalendar];
		
		if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"CalendarUseButton"] )
		{
			NSView *datePickerView = [calController datePickerContainer];
			NSInteger datePickerHeight = [datePickerView frame].size.height;
			
			NSRect calendarContainerFrame = [calContainer frame];
			NSRect sourceListContainerFrame = [[sourceList enclosingScrollView] frame];
			
			NSInteger originalHeight = calendarContainerFrame.size.height;
			NSInteger originalWidth = calendarContainerFrame.size.width;
			
			calendarContainerFrame.size.height = datePickerHeight;
			calendarContainerFrame.origin.y = calendarContainerFrame.origin.y + originalHeight - datePickerHeight;
			sourceListContainerFrame.size.height += ( originalHeight - datePickerHeight );
			
			[datePickerView setFrame:NSMakeRect(0,0,originalWidth,datePickerHeight)];
			[calContainer setFrame:calendarContainerFrame];
			[[sourceList enclosingScrollView] setFrame:sourceListContainerFrame];
			
			[calContainer setFill:[NSColor colorWithCalibratedRed:200.0/255.0 green:205.0/255.0 blue:212.0/255.0 alpha:1.0]];
			[calContainer addSubview:datePickerView];
		}
		else
		{
			static NSInteger kCalRequiredHeight = 170;
			
			NSRect calendarContainerFrame = [calContainer frame];
			NSRect sourceListContainerFrame = [[sourceList enclosingScrollView] frame];
			
			NSInteger originalWidth = calendarContainerFrame.size.width;
			NSInteger originalHeight = calendarContainerFrame.size.height;
			
			calendarContainerFrame.size.height = kCalRequiredHeight;
			calendarContainerFrame.origin.y = calendarContainerFrame.origin.y + originalHeight - kCalRequiredHeight;
			sourceListContainerFrame.size.height -= ( kCalRequiredHeight - originalHeight );
			
			[calContainer setFrame:calendarContainerFrame];
			[calendar setFrame:NSMakeRect(0, 0, originalWidth, kCalRequiredHeight )];
			[[sourceList enclosingScrollView] setFrame:sourceListContainerFrame];
			
			[calContainer setFill:[NSColor whiteColor]];
			[calContainer addSubview:calendar];
		}
		
		//[calController finalizeCalendarSizeChange:usesSmallCalendar];
	}
}

#pragma mark -

- (NSString*) title 
{
	NSString *theTitle = nil;
	if ( [resourceCellController isWebBrowsing] )
	{
		theTitle = [resourceCellController documentTitle];
		if ( theTitle == nil )
			theTitle = [super title];
	}
	else
	{
		theTitle = [super title];
	}
	
	return theTitle;
}

#pragma mark -
#pragma mark Saving and Restoring the Tab's State

- (NSDictionary*) stateDictionary 
{	
	// grab a mutable copy of super's dictionary, storing selection info
	NSMutableDictionary *stateDictionary = [[[super stateDictionary] mutableCopyWithZone:[self zone]] autorelease];
	[stateDictionary addEntriesFromDictionary:[self localStateDictionary]];
	return stateDictionary;
}

- (void) restoreStateWithDictionary:(NSDictionary*)stateDictionary 
{	
	[self restoreLocalStateWithDictionary:stateDictionary];
	
	// allow super to handle the rest (ie entry, folder selection)
	[super restoreStateWithDictionary:stateDictionary];
}

- (NSDictionary*) localStateDictionary
{
	NSMutableDictionary *stateDictionary = [NSMutableDictionary dictionary];
	
	// add the state of the entry table
	NSArray *entryTableState = [entriesTable stateArray];
	if ( entryTableState != nil )
		[stateDictionary setValue:entryTableState forKey:@"entryTableState"];
		
	// add the state of the folders table
	NSArray *folderTableState = [sourceList stateArray];
	if ( folderTableState != nil )
		[stateDictionary setValue:folderTableState forKey:@"folderTableState"];
		
	// the resource table state
	NSDictionary *resourceTableState = [resourceController stateDictionary];
	if ( resourceTableState != nil )
		[stateDictionary setValue:resourceTableState forKey:@"resourceTableState"];
	
	// inclue the splitview dimensions 
	NSNumber *browserDimension = [NSNumber numberWithFloat:[[browserContentSplit subviewAtPosition:0] dimension]];
	NSNumber *resourceDimension = [NSNumber numberWithFloat:[[contentResourceSplit subviewAtPosition:1] dimension]];
	NSNumber *folderDimension = [NSNumber numberWithFloat:[[foldersEntriesSplit subviewAtPosition:0] dimension]];
	
	// is the resource view collapsed
	NSNumber *resourceCollapsed = [NSNumber numberWithBool:[[contentResourceSplit subviewAtPosition:1] isHidden]];
	
	[stateDictionary setValue:browserDimension forKey:@"browserDimension"];
	[stateDictionary setValue:resourceDimension forKey:@"resourceDimension"];
	[stateDictionary setValue:folderDimension forKey:@"folderDimension"];
	
	[stateDictionary setValue:resourceCollapsed forKey:@"resourceCollapsed"];
	
	// the entry cell's footer and header
	[stateDictionary setValue:[NSNumber numberWithBool:[entryCellController headerHidden]] forKey:@"headerHidden"];
	[stateDictionary setValue:[NSNumber numberWithBool:[entryCellController footerHidden]] forKey:@"footerHidden"];
	
	// get on outa here
	return stateDictionary;
}

- (void) restoreLocalStateWithDictionary:(NSDictionary*)stateDictionary
{
	// restore the state of the entry table
	NSArray *entryTableState = [stateDictionary valueForKey:@"entryTableState"];
	if ( entryTableState != nil )
		[entriesTable restoreStateWithArray:entryTableState];
	
	// clear the entry table of the rank column though
	[entriesTable setColumnWithIdentifier:@"relevanceNumber" hidden:YES];
	
	// restore the collection state
	NSArray *folderTableState = [stateDictionary valueForKey:@"folderTableState"];
	if ( folderTableState != nil )
		[sourceList restoreStateFromArray:folderTableState];
	
	// the resource table state
	NSDictionary *resourceTableState = [stateDictionary valueForKey:@"resourceTableState"];
	if ( resourceTableState != nil )
		[resourceController restoreStateFromDictionary:resourceTableState];
	
	// restore the splitview dimension
	NSNumber *browserDimension = [stateDictionary valueForKey:@"browserDimension"];
	if ( browserDimension != nil )
		[[browserContentSplit subviewAtPosition:0] setDimension:[browserDimension floatValue]];
	
	NSNumber *resourceDimension = [stateDictionary valueForKey:@"resourceDimension"];
	if ( resourceDimension != nil )
		[[contentResourceSplit subviewAtPosition:1] setDimension:[resourceDimension floatValue]];
	
	NSNumber *folderDimension = [stateDictionary valueForKey:@"folderDimension"];
	if ( folderDimension != nil )
		[[foldersEntriesSplit subviewAtPosition:0] setDimension:[folderDimension floatValue]];
	
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

- (BOOL) performCustomKeyEquivalent:(NSEvent *)theEvent
{
	// hidden keyboard shortcuts baby!
	// NSLog(@"%s",__PRETTY_FUNCTION__);
	
	BOOL handled = NO;
	
	SEL action = nil;
	NSMenuItem *menuItem = nil;
	
	NSUInteger modifierFlags = [theEvent modifierFlags];
	NSString *characters = [theEvent charactersIgnoringModifiers];
	
	if ( [characters length] == 1 )
	{
		unichar theCharacter = [characters characterAtIndex:0];
		BOOL shiftDown = ( (modifierFlags & NSShiftKeyMask) == NSShiftKeyMask );
		BOOL controlDown = ( (modifierFlags & NSControlKeyMask) == NSControlKeyMask );
		BOOL altDown = ( (modifierFlags & NSAlternateKeyMask) == NSAlternateKeyMask );
		
		if ( ( theCharacter == NSEnterCharacter || theCharacter == NSCarriageReturnCharacter ) && !shiftDown && !controlDown && !altDown )
			// cmd-enter = to today
			action = @selector(toToday:);
			
		else if ( ( theCharacter == NSEnterCharacter || theCharacter == NSCarriageReturnCharacter ) && !shiftDown && controlDown && !altDown )
			// cmd-ctrl-enter = to entry's caldate
			action = @selector(gotoEntryDateInCalendar:);

		else if ( ( theCharacter == NSEnterCharacter || theCharacter == NSCarriageReturnCharacter ) && !shiftDown && !controlDown && altDown )
			// cmd-alt-enter = to journal
			action = @selector(selectJournal:);


		else if ( theCharacter == NSDeleteCharacter && !shiftDown && !controlDown && !altDown )
			// cmd-del = empty trash
			action = @selector(performDelete:);
	
		else if ( theCharacter == NSDeleteCharacter && shiftDown && !controlDown && !altDown )
			// cmd-shift-del = empty trash
			action = @selector(emptyTrash:);

		
		else if ( ( theCharacter == 'R' ) && shiftDown && !controlDown && altDown )
			// cmd-alt-shift-R = goto random entry
			action = @selector(gotoRandomEntry:);

		
		else if ( theCharacter == NSUpArrowFunctionKey && !shiftDown && !controlDown && altDown )
			// cmd-alt-up = previous folder
			action = @selector(selectPreviousFolder:);

		else if ( theCharacter == NSDownArrowFunctionKey && !shiftDown && !controlDown && altDown )
			// cmd-alt-down = next folder
			action = @selector(selectNextFolder:);

		//#warning these two crash Journler on Tiger
		else if ( theCharacter == NSUpArrowFunctionKey && shiftDown && controlDown && !altDown && [characters respondsToSelector:@selector(componentsSeparatedByCharactersInSet:)] )
			// cmd-ctrl-up = previous entry
			action = @selector(selectPreviousEntry:);
			
		else if ( theCharacter == NSDownArrowFunctionKey && shiftDown && controlDown && !altDown && [characters respondsToSelector:@selector(componentsSeparatedByCharactersInSet:)] )
			// cmd-ctrl-down = next entry
			action = @selector(selectNextEntry:);

		else if ( theCharacter == NSLeftArrowFunctionKey && !shiftDown && !controlDown && altDown )
			// cmd-alt-left = previous day
			action = @selector(dayToLeft:);
	
		else if ( theCharacter == NSRightArrowFunctionKey && !shiftDown && !controlDown && altDown )
			// cmd-alt-right = next day
			action = @selector(dayToRight:);
	
		
		else if ( theCharacter == NSLeftArrowFunctionKey && !shiftDown && controlDown && !altDown )
			// cmd-ctrl-left = previous day with entries
			action = @selector(previousDayWithEntries:);
	
		else if ( theCharacter == NSRightArrowFunctionKey && !shiftDown && controlDown && !altDown )
			// cmd-ctrl-right = next day with entries
			action = @selector(nextDayWithEntries:);


		else if ( theCharacter == NSLeftArrowFunctionKey && !shiftDown && controlDown && altDown )
			// cmd-ctrl-alt-left = previous month
			action = @selector(monthToLeft:);
	
		else if ( theCharacter == NSRightArrowFunctionKey && !shiftDown && controlDown && altDown )
			// cmd-ctrl-alt-right = next month
			action = @selector(monthToRight:);
	
		
		else if ( theCharacter == '6' && !shiftDown && !controlDown && !altDown )
			// cmd-6 = focus source list
			action = @selector(makeSourceListFirstResponder:);

		else if ( theCharacter == '7' && !shiftDown && !controlDown && !altDown )
			// cmd-7 = focus entries list
			action = @selector(makeEntriesTableFirstResponder:);

		else if ( theCharacter == '8' && !shiftDown && !controlDown && !altDown )
			// cmd-8 = focus entry text
			action = @selector(makeEntryTextFirstResponder:);

		else if ( theCharacter == '9' && !shiftDown && !controlDown && !altDown )
			// cmd-9 = focus resource list
			action = @selector(makeResourceTableFirstResponder:);

	}
	
	if ( action != nil )
	{
		menuItem = [[[NSMenuItem alloc] initWithTitle:@"" action:action keyEquivalent:@""] autorelease];
		[menuItem setTarget:self];
		
		if ( [self validateMenuItem:menuItem] )
		{
			[self performSelector:action withObject:menuItem];
			handled = YES;
		}
		else
		{
			NSBeep();
		}
	}
	
	return handled;
}

#pragma mark -
#pragma mark Overriding WillDelete Notifications

- (void) willDeleteEntry:(NSNotification*)aNotification
{	
	JournlerEntry *theEntry = [[aNotification userInfo] objectForKey:@"entry"];
	if ( [[self selectedEntries] containsObject:theEntry] )
	{
		NSMutableArray *mySelectedEntries = [[[self selectedEntries] mutableCopyWithZone:[self zone]] autorelease];
		[entriesTable deselectAll:self];
		[mySelectedEntries removeObject:theEntry];
		[self setSelectedEntries:mySelectedEntries];
	}
}

- (void) willDeleteResource:(NSNotification*)aNotification
{
	JournlerResource *theResource = [[aNotification userInfo] objectForKey:@"resource"];
	if ( [[self selectedResources] containsObject:theResource] )
	{
		NSMutableArray *mySelectedResources = [[[self selectedResources] mutableCopyWithZone:[self zone]] autorelease];
		[resourceTable deselectAll:self];
		[mySelectedResources removeObject:theResource];
		[self setSelectedResources:mySelectedResources];
	}
}


#pragma mark -
#pragma mark Autosaving When Changing the Folder, Date or Entry Selection

- (void) foldersController:(FoldersController*)aFoldersController willChangeSelection:(NSArray*)currentSelection
{
	#ifdef __DEBUG__
	NSLog(@"%s", __PRETTY_FUNCTION__);
	#endif
	
	// commit editing
	if ( ![entryCellController commitEditing] )
		NSLog(@"%s - problem with committing changes with the entries cell controller", __PRETTY_FUNCTION__);
		
	if ( ![entriesController commitEditing] )
		NSLog(@"%s - problem with committing changes with the entries controller", __PRETTY_FUNCTION__);
	
	if ( ![sourceListController commitEditing] )
		NSLog(@"%s - problem with committing changes with the folders controller", __PRETTY_FUNCTION__);
	
	if ( ![resourceController commitEditing] )
		NSLog(@"%s - problem with committing changes with the folders controller", __PRETTY_FUNCTION__);
	
	// autosave - could lead to redundancy, but only dirty objects are saved anyway
	
	NSArray *entrySelection = [self selectedEntries];
	NSArray *resourceSelection = [self selectedResources];
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
	
	if ( currentSelection != nil )
		[userInfo setObject:currentSelection forKey:@"folders"];
	if ( entrySelection != nil )
		[userInfo setObject:entrySelection forKey:@"entries"];
	if ( resourceSelection != nil )
		[userInfo setObject:resourceSelection forKey:@"resources"];
	
	NSNotification *aNotification = [NSNotification notificationWithName:@"JournlerAutosaveNotification" object:self userInfo:userInfo];
	[self performSelector:@selector(performAutosave:) withObject:aNotification afterDelay:0.1];
}

- (void) entryController:(EntriesController*)anEntriesController willChangeSelection:(NSArray*)currentSelection
{
	#ifdef __DEBUG__
	NSLog(@"%s", __PRETTY_FUNCTION__);
	#endif
	
	// commit editing
	if ( ![entryCellController commitEditing] )
		NSLog(@"%s - problem with committing changes with the entries cell controller", __PRETTY_FUNCTION__);
		
	if ( ![entriesController commitEditing] )
		NSLog(@"%s - problem with committing changes with the entries controller", __PRETTY_FUNCTION__);
	
	if ( ![sourceListController commitEditing] )
		NSLog(@"%s - problem with committing changes with the folders controller", __PRETTY_FUNCTION__);
	
	if ( ![resourceController commitEditing] )
		NSLog(@"%s - problem with committing changes with the folders controller", __PRETTY_FUNCTION__);
	
	// autosave - could lead to redundancy, but only dirty objects are saved anyway
	
	NSArray *folderSelection = [self selectedFolders];
	NSArray *resourceSelection = [self selectedResources];
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
	
	if ( currentSelection != nil )
		[userInfo setObject:currentSelection forKey:@"entries"];
	if ( folderSelection != nil )
		[userInfo setObject:folderSelection forKey:@"folders"];
	if ( resourceSelection != nil )
		[userInfo setObject:resourceSelection forKey:@"resources"];
			
	NSNotification *aNotification = [NSNotification notificationWithName:@"JournlerAutosaveNotification" object:self userInfo:userInfo];
	[self performSelector:@selector(performAutosave:) withObject:aNotification afterDelay:0.1];
}

- (void) resourceController:(ResourceController*)aController willChangeSelection:(NSArray*)currentSelection
{
	#ifdef __DEBUG__
	NSLog(@"%s", __PRETTY_FUNCTION__);
	#endif
	
	// commit editing
	if ( ![entryCellController commitEditing] )
		NSLog(@"%s - problem with committing changes with the entries cell controller", __PRETTY_FUNCTION__);
		
	if ( ![entriesController commitEditing] )
		NSLog(@"%s - problem with committing changes with the entries controller", __PRETTY_FUNCTION__);
	
	if ( ![sourceListController commitEditing] )
		NSLog(@"%s - problem with committing changes with the folders controller", __PRETTY_FUNCTION__);
	
	if ( ![resourceController commitEditing] )
		NSLog(@"%s - problem with committing changes with the folders controller", __PRETTY_FUNCTION__);
	
	NSArray *folderSelection = [self selectedFolders];
	NSArray *entrySelection = [self selectedEntries];
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
	
	if ( currentSelection != nil )
		[userInfo setObject:currentSelection forKey:@"resources"];
	if ( entrySelection != nil )
		[userInfo setObject:folderSelection forKey:@"folders"];
	if ( entrySelection != nil )
		[userInfo setObject:entrySelection forKey:@"entries"];
	
	NSNotification *aNotification = [NSNotification notificationWithName:@"JournlerAutosaveNotification" object:self userInfo:userInfo];
	[self performSelector:@selector(performAutosave:) withObject:aNotification afterDelay:0.1];
}

- (void) datesController:(DatesController*)aDatesController willChangeDate:(NSDate*)aDate
{
	#ifdef __DEBUG__
	NSLog(@"%s", __PRETTY_FUNCTION__);
	#endif
	
	// commit editing
	if ( ![entryCellController commitEditing] )
		NSLog(@"%s - problem with committing changes with the entries cell controller", __PRETTY_FUNCTION__);
		
	if ( ![entriesController commitEditing] )
		NSLog(@"%s - problem with committing changes with the entries controller", __PRETTY_FUNCTION__);
	
	if ( ![sourceListController commitEditing] )
		NSLog(@"%s - problem with committing changes with the folders controller", __PRETTY_FUNCTION__);
	
	if ( ![resourceController commitEditing] )
		NSLog(@"%s - problem with committing changes with the folders controller", __PRETTY_FUNCTION__);
	
	// autosave - could lead to redundancy, but only dirty objects are saved anyway
	[self performAutosave:nil];
}

#pragma mark -
#pragma mark Rebinding When Changing Folder / Date Source

- (void) datesController:(DatesController*)aDatesController didChangeDate:(NSCalendarDate*)aDate 
{
	#ifdef __DEBUG__
	NSLog(@"%s", __PRETTY_FUNCTION__);
	#endif
	
	id observed = [[entriesController infoForBinding:@"contentArray"] valueForKey:NSObservedObjectKey];
	if ( observed != datesController ) 
	{
		#ifdef __DEBUG__
		NSLog(@"%s - inside", __PRETTY_FUNCTION__);
		#endif
		
		NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
				@"NSUnarchiveFromData", NSValueTransformerNameBindingOption, nil];
		
		[entriesController unbind:@"contentArrayForMultipleSelection"];
		[entriesController unbind:@"contentArray"];
		[entriesController unbind:@"sortDescriptors"];
		
		//[entriesController setContent:nil];
		
		[entriesController bind:@"contentArray" toObject:datesController 
		withKeyPath:@"selectedObjects" options:nil];
				
		[entriesController bind:@"sortDescriptors" toObject:[NSUserDefaultsController sharedUserDefaultsController]
		withKeyPath:@"values.CalendarSortDescriptors" options:options];
		
		[entriesController rearrangeObjects];
		
		[calController setHighlighted:YES];
	}
}

- (void) foldersController:(FoldersController*)aFoldersController didChangeSelection:(NSArray*)newSelection 
{
	#ifdef __DEBUG__
	NSLog(@"%s", __PRETTY_FUNCTION__);
	#endif

	id observed = [[entriesController infoForBinding:@"contentArray"] valueForKey:NSObservedObjectKey];
	if ( observed != sourceListController && ( newSelection != nil && [newSelection count] != 0 ) ) 
	{
		// #warning don't like the newSelection check, bit of a hack - why in the fist place?
	
		#ifdef __DEBUG__
		NSLog(@"%s - inside", __PRETTY_FUNCTION__);
		#endif
		
		[entriesController unbind:@"contentArray"];
		[entriesController unbind:@"sortDescriptors"];
		
		//[entriesController setContent:nil];
		
		[entriesController bind:@"contentArray" toObject:sourceListController 
		withKeyPath:@"selection.entries" options:nil];
				
		[entriesController bind:@"contentArrayForMultipleSelection" toObject:sourceListController 
		withKeyPath:@"selection.@distinctUnionOfArrays.entries" options:nil];
				
		[entriesController bind:@"sortDescriptors" toObject:sourceListController 
		withKeyPath:@"selection.sortDescriptors" options:nil];
		
		[entriesController rearrangeObjects];
		
		[calController setHighlighted:NO];
	}
}

#pragma mark -
#pragma mark RBSplitView Delegation

// This makes it possible to drag the divider around by the dragView.
- (NSUInteger)splitView:(RBSplitView*)sender dividerForPoint:(NSPoint)point inSubview:(RBSplitSubview*)subview
{
	if ( [sender tag] == 0 && subview == [sender subviewAtPosition:0] ) 
	{
		if ([foldersDragView mouse:[foldersDragView convertPoint:point fromView:sender] inRect:[foldersDragView bounds]])
			return 0;
	}
		
	else if ( [sender tag] == 2 && subview == [sender subviewAtPosition:1] ) 
	{
		if ([resourcesDragView mouse:[resourcesDragView convertPoint:point fromView:sender] inRect:[resourcesDragView bounds]])
			return 0;
	}
	
	return NSNotFound;
}

// This changes the cursor when it's over the dragView.
- (NSRect)splitView:(RBSplitView*)sender cursorRect:(NSRect)rect forDivider:(NSUInteger)divider 
{
	if ( [sender tag] == 0 && divider== 0 )
		[sender addCursorRect:[foldersDragView convertRect:[foldersDragView bounds] toView:sender]
				cursor:[RBSplitView cursor:RBSVVerticalCursor]];
	
	else if ( [sender tag] == 2 && divider == 0 )
		[sender addCursorRect:[resourcesDragView convertRect:[resourcesDragView bounds] toView:sender]
				cursor:[RBSplitView cursor:RBSVVerticalCursor]];
	
	return rect;
}

// this prevents a subview from resizing while the others around it do
- (void)splitView:(RBSplitView*)sender wasResizedFrom:(float)oldDimension to:(float)newDimension 
{
	if ( [sender tag] == 0 )
		[sender adjustSubviewsExcepting:[sender subviewAtPosition:0]];
	
	else if ( [sender tag] == 1 )
		[sender adjustSubviewsExcepting:[sender subviewAtPosition:0]];
	
	else if ( [sender tag] == 2 )
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

- (void)splitView:(RBSplitView*)sender willDrawSubview:(RBSplitSubview*)subview inRect:(NSRect)rect
{
	[[NSColor darkGrayColor] set];
	NSFrameRect(rect);
}

- (NSRect)splitView:(RBSplitView*)sender willDrawDividerInRect:(NSRect)dividerRect 
		betweenView:(RBSplitSubview*)leading andView:(RBSplitSubview*)trailing withProposedRect:(NSRect)imageRect
{
	if ( [sender tag] == 1 )
	{
		NSColor *gradientStart = [NSColor colorWithCalibratedRed:254.0/255.0 green:254.0/255.0 blue:254.0/255.0 alpha:1.0];
		NSColor *gradientEnd = [NSColor colorWithCalibratedRed:235.0/255.0 green:235.0/255.0 blue:235.0/255.0 alpha:1.0];
		
		[[NSBezierPath bezierPathWithRect:dividerRect] 
				linearGradientFillWithStartColor:gradientStart endColor:gradientEnd];
		
		if ( [trailing isCollapsed] )
		{
			[[NSColor darkGrayColor] set];
			NSBezierPath *strongLine = [NSBezierPath bezierPathWithLineFrom:NSMakePoint(dividerRect.origin.x, dividerRect.origin.y + dividerRect.size.height )
			 to:NSMakePoint(dividerRect.origin.x + dividerRect.size.width, dividerRect.origin.y + dividerRect.size.height ) lineWidth:1.0];
			
			[[NSGraphicsContext currentContext] saveGraphicsState];
			[[NSGraphicsContext currentContext] setShouldAntialias:NO];
			[strongLine stroke];
			[[NSGraphicsContext currentContext] restoreGraphicsState];
		}
		//[[NSColor darkGrayColor] set];
		//NSFrameRect(NSInsetRect(dividerRect,-1,-1));
	}
	else
	{
		[[NSColor darkGrayColor] set];
		NSRectFill(dividerRect);
	}
	
	return imageRect;
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

// subclasses way want to override to provide more specialized handling

- (void) entryCellController:(EntryCellController*)aController 
		clickedOnEntry:(JournlerEntry*)anEntry 
		modifierFlags:(NSUInteger)flags 
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
		// clear the search and filter if there is one
		[self clearSearchAndFilter:self];
		
		// locate the entry
		if ( [[entriesController arrangedObjects] indexOfObjectIdenticalTo:anEntry] == NSNotFound )
		{
			// select the entry's date
			NSCalendarDate *date = [anEntry valueForKey:@"calDate"];
			[calendar setValue:date forKey:@"selectedDate"];
		}
		
		// select the entry
		[entriesController setSelectedObjects:[NSArray arrayWithObject:anEntry]];
		
		// highlight the term
		[self highlightString:aTerm];
	}
}

- (void) entryCellController:(EntryCellController*)aController 
		clickedOnResource:(JournlerResource*)aResource
		modifierFlags:(NSUInteger)flags 
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
					// clear the search and filter if there is one
					[self clearSearchAndFilter:self];
					
					// locate the resource's entry
					JournlerEntry *anEntry = [aResource valueForKey:@"entry"];
					if ( [[entriesController arrangedObjects] indexOfObjectIdenticalTo:anEntry] == NSNotFound )
					{
						// select the entry's date
						NSCalendarDate *date = [anEntry valueForKey:@"calDate"];
						[calendar setValue:date forKey:@"selectedDate"];
					}
					
					// select the resource's entry
					[entriesController setSelectedObjects:[NSArray arrayWithObject:anEntry]];
				}
				
				// select the resource
				[resourceController selectResource:aResource byExtendingSelection:YES];
				[self highlightString:aTerm];
			}
		}
	}
}

- (void) entryCellController:(EntryCellController*)aController clickedOnFolder:(JournlerCollection*)aFolder modifierFlags:(NSUInteger)flags
{
	if ( flags & NSCommandKeyMask )
	{
		// select the folder in a new tab
		[[self valueForKey:@"owner"] newTab:self];
		TabController *theTab = [[self valueForKeyPath:@"owner.tabControllers"] lastObject];
		[theTab selectDate:nil folders:[NSArray arrayWithObject:aFolder] entries:nil resources:nil];
		
		// select the tab if the shift key is down
		if ( flags & NSShiftKeyMask )
			[[self valueForKey:@"owner"] selectTabAtIndex:-1 force:NO];
	}
	else
	{
		// select the folder
		[sourceListController selectCollection:aFolder byExtendingSelection:NO];
	}
}

- (void) entryCellController:(EntryCellController*)aController clickedOnURL:(NSURL*)aURL modifierFlags:(NSUInteger)flags
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

- (BOOL) entryCellController:(EntryCellController*)aController newDefaultEntry:(NSNotification*)aNotification
{
	// no dialog or nuthin, just create a new entry and select it
	JournlerEntry *newEntry = [self newDefaultEntryWithSelectedDate:[calendar valueForKey:@"selectedDate"] overridePreference:NO];
	
	// update the calendar and select the entry, watching out for default content
	//[datesController updateSelectedObjects:self];
	
	// clear the search and filter if there is one
	[self clearSearchAndFilter:self];
	
	// add the entry to the selected folder(s)
	BOOL alreadyAutotagged = NO;
	
    for ( JournlerCollection *aFolder in [self selectedFolders] )
	{
		if ( [aFolder isRegularFolder] )
			[aFolder addEntry:newEntry];
		else if ( [aFolder isSmartFolder] && [aFolder canAutotag:newEntry] )
		{
			if ( alreadyAutotagged == NO )
			{
				[newEntry setValue:[NSString string] forKey:@"category"];
				alreadyAutotagged = YES;
			}
				
			[aFolder autotagEntry:newEntry add:YES];
		}
	}
	
	// save the entry once more now that it's been autotagged
	[[self journal] saveEntry:newEntry];

	// select the entry, locating it if necessary
	if ( [[entriesController arrangedObjects] indexOfObjectIdenticalTo:newEntry] == NSNotFound )
	{
		// select the entry's date
		NSCalendarDate *date = [newEntry valueForKey:@"calDate"];
		[calendar setValue:date forKey:@"selectedDate"];
	}
	
	// select the entry and focus the user's input
	[entriesController setSelectedObjects:[NSArray arrayWithObject:newEntry]];
	[entriesController rearrangeObjects];
	
	[[[self owner] window] makeFirstResponder:[entryCellController textView]];
	
	return YES;
}

- (BOOL) entryController:(EntriesController*)anEntriesController tableDidSelectRowAlreadySelected:(NSInteger)aRow event:(NSEvent*)mouseEvent
{
	BOOL handled = NO;
	
	if ( [[anEntriesController selectedObjects] count] == 1 && [[self selectedResources] count] > 0 )
	{
		// deselect the resources
		handled = YES;
		[resourceTable deselectAll:self];
	}
	/*
	else if ( [[anEntriesController selectedObjects] count] == 1 && [[self selectedResources] count] == 0 )
	{
		// edit the row/column
		NSPoint tablePoint = [entriesTable convertPoint:[mouseEvent locationInWindow] fromView:nil];
		NSInteger targetColumn = [entriesTable columnAtPoint:tablePoint];
		
		if ( targetColumn != -1 && [[[entriesTable tableColumns] objectAtIndex:targetColumn] isEditable] )
		{
			handled = YES;
			[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.33]];
			[entriesTable editColumn:targetColumn row:aRow withEvent:mouseEvent select:YES];
		}
	}
	*/
	
	return handled;
}

#pragma mark -
#pragma mark Folder Controller Delegation

- (BOOL) sourceList:(CollectionsSourceList*)aSourceList didSelectRowAlreadySelected:(NSInteger)aRow event:(NSEvent*)mouseEvent
{
	BOOL handled = NO;
	
	if ( [[sourceListController selectedObjects] count] == 1 )
	{
		// edit the row/column
		NSPoint tablePoint = [aSourceList convertPoint:[mouseEvent locationInWindow] fromView:nil];
		NSInteger targetColumn = [aSourceList columnAtPoint:tablePoint];
		
		if ( targetColumn != -1 && [[[aSourceList tableColumns] objectAtIndex:targetColumn] isEditable] )
		{
			handled = YES;
			[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.33]];
			[aSourceList editColumn:targetColumn row:aRow withEvent:mouseEvent select:YES];
		}
	}
	
	return handled;
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

#pragma mark -

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

- (BOOL) resourceController:(ResourceController*)aController newDefaultEntry:(NSNotification*)aNotification
{
	// no dialog or nuthin, just create a new entry and select it
	JournlerEntry *newEntry = [self newDefaultEntryWithSelectedDate:[calendar valueForKey:@"selectedDate"] overridePreference:NO];
	
	// update the calendar and select the entry, watching out for default content
	//[datesController updateSelectedObjects:self];
	
	// clear the search and filter if there is one
	[self clearSearchAndFilter:self];
	
	// add the entry to the selected folder(s)
	BOOL alreadyAutotagged;
	
    for ( JournlerCollection *aFolder in [self selectedFolders] )
	{
		if ( [aFolder isRegularFolder] )
			[aFolder addEntry:newEntry];
		else if ( [aFolder isSmartFolder] && [aFolder canAutotag:newEntry] )
		{
			if ( alreadyAutotagged == NO )
			{
				[newEntry setValue:[NSString string] forKey:@"category"];
				alreadyAutotagged = YES;
			}
				
			[aFolder autotagEntry:newEntry add:YES];
		}
	}
	
	// save the entry once more now that it's been autotagged
	[[self journal] saveEntry:newEntry];
	
	// select the entry, locating it if necessary
	if ( [[entriesController arrangedObjects] indexOfObjectIdenticalTo:newEntry] == NSNotFound )
	{
		// select the entry's date
		NSCalendarDate *date = [newEntry valueForKey:@"calDate"];
		[calendar setValue:date forKey:@"selectedDate"];
	}
	
	// select the entry and focus the user's input
	[entriesController setSelectedObjects:[NSArray arrayWithObject:newEntry]];
	[entriesController rearrangeObjects];
	
	[[[self owner] window] makeFirstResponder:[entryCellController textView]];
	
	return YES;
}

#pragma mark -
#pragma mark Cell Lexicon Delegation

- (void) contentController:(id)aController showLexiconSelection:(id)anObject term:(NSString*)aTerm
{
	// route to the "entry cell" delegation - a perhaps unwise re-use of object specific delegation
	[self showLexiconSelection:anObject forTerm:aTerm];
}

- (void) showLexiconSelection:(JournlerObject*)anObject forTerm:(NSString*)aTerm
{
	NSInteger eventModifiers = 0;
	NSInteger modifiers = GetCurrentKeyModifiers();
	
	if ( modifiers & shiftKey ) eventModifiers |= NSShiftKeyMask;
	if ( modifiers & optionKey ) eventModifiers |= NSAlternateKeyMask;
	if ( modifiers & cmdKey ) eventModifiers |= NSCommandKeyMask;
	if ( modifiers & controlKey ) eventModifiers |= NSControlKeyMask;
	
	if ( [anObject isKindOfClass:[JournlerEntry class]] )
	{
		JournlerEntry *theEntry = (JournlerEntry*)anObject;
		[self entryCellController:entryCellController clickedOnEntry:theEntry modifierFlags:eventModifiers highlight:aTerm];
		//[self highlightString:aTerm];
	}
	
	else if ( [anObject isKindOfClass:[JournlerResource class]] )
	{
		JournlerResource *theResource = (JournlerResource*)anObject;
		[self entryCellController:entryCellController clickedOnResource:theResource modifierFlags:eventModifiers highlight:aTerm];
		[self highlightString:aTerm];
	}
	
	else
	{
		NSBeep();
	}
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
#pragma mark Calendar Delegate

- (void) calendar:(Calendar*)aCalendar requestsNewEntryForDate:(NSCalendarDate*)aCalendarDate
{
	// no dialog or nuthin, just create a new entry and select it
	JournlerEntry *newEntry = [self newDefaultEntryWithSelectedDate:aCalendarDate overridePreference:YES];
	
	// update the calendar and select the entry, watching out for default content
	//[datesController updateSelectedObjects:self];
	
	// clear the search and filter if there is one
	[self clearSearchAndFilter:self];
	
	// select the entry, locating it if necessary
	if ( [[entriesController arrangedObjects] indexOfObjectIdenticalTo:newEntry] == NSNotFound )
	{
		// select the entry's date
		NSCalendarDate *date = [newEntry valueForKey:@"calDate"];
		[calendar setValue:date forKey:@"selectedDate"];
	}
	
	// select the entry and focus the user's input
	[entriesController setSelectedObjects:[NSArray arrayWithObject:newEntry]];
	[entriesController rearrangeObjects];
	
	[[[self owner] window] makeFirstResponder:[entryCellController textView]];
}

- (void) calendarWantsToJumpToDayOfSelectedEntry:(Calendar*)aCalendar
{
	[self gotoEntryDateInCalendar:self];
}

#pragma mark -
#pragma mark Navigation Events

- (void) tableView:(NSTableView*)aTableView leftNavigationEvent:(NSEvent*)anEvent
{
	#ifdef __DEBUG__
	NSLog(@"%s", __PRETTY_FUNCTION__);
	#endif
	
	if ( aTableView == entriesTable )
		[[[self tabContent] window] makeFirstResponder:sourceList];
}

- (void) tableView:(NSTableView*)aTableView rightNavigationEvent:(NSEvent*)anEvent
{
	#ifdef __DEBUG__
	NSLog(@"%s", __PRETTY_FUNCTION__);
	#endif
	
	if ( aTableView == entriesTable )
		[[[self tabContent] window] makeFirstResponder:resourceTable];
}

- (void) outlineView:(NSOutlineView*)anOutlineView leftNavigationEvent:(NSEvent*)anEvent
{
	#ifdef __DEBUG__
	NSLog(@"%s", __PRETTY_FUNCTION__);
	#endif

	if ( anOutlineView == resourceTable )
		[[[self tabContent] window] makeFirstResponder:entriesTable];
}

- (void) outlineView:(NSOutlineView*)anOutlineView rightNavigationEvent:(NSEvent*)anEvent
{
	#ifdef __DEBUG__
	NSLog(@"%s", __PRETTY_FUNCTION__);
	#endif
	
	if ( anOutlineView == sourceList )
		[[[self tabContent] window] makeFirstResponder:entriesTable];

}

#pragma mark -
#pragma mark Filtering and Searching

- (IBAction) performToolbarSearch:(id)sender
{
	static NSInteger kMinTermLength = 0;
	
	NSSet *entries = nil, *references = nil;
	NSString *preSearchString = [sender stringValue];
	
	[self setSearchString:preSearchString];
	
	if ( !preSearchString || [preSearchString length] <= kMinTermLength ) 
	{
		// clear the search
		entries = nil;
		references = nil;
		keepSearching = NO;
		
		// hide the rank column
		[entriesTable setColumnWithIdentifier:@"relevanceNumber" hidden:YES];
		
		if ( preSearchTableState != nil )
		{
			[entriesTable restoreStateWithArray:preSearchTableState];
			[preSearchTableState release];
			preSearchTableState = nil;
		}
		
		// return the entry and resource sorts back to the pre-search state
		[entriesController setSortDescriptors:preSearchDescriptors];
		[resourceController sortBy:kSortResourcesByTitle];
		
		//#warning clear rank values
		[[entriesController intersectSet] setValue:[NSNumber numberWithInteger:0] forKey:@"relevance"];
		[[resourceController intersectSet] setValue:[NSNumber numberWithInteger:0] forKey:@"relevance"];
		
		// intersect the search results and rearrange
		[entriesController setIntersectSet:entries];
		[resourceController setShowingSearchResults:NO];
		[resourceController rearrangeObjects];
		
	}
	else 
	{
		// perform the search
		SKSearchOptions searchOptions;
		NSInteger entryHits, referenceHits;
		BOOL success;
			
		// change the string for searching - put an asterisk after any space and at the end
		NSMutableString *mySearchString = [[preSearchString mutableCopyWithZone:[self zone]] autorelease];
		
		if ( [mySearchString rangeOfString:@"\"" options:NSLiteralSearch range:NSMakeRange(0,[mySearchString length])].location != NSNotFound )
		{
			// leave the string as it is - phrasal searching
			#ifdef __DEBUG__
			NSLog(mySearchString);
			#endif
			
			searchOptions = kSKSearchOptionDefault;
		}
		
		else if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"AutoEnablePrefixSearching"] )
		{
			// append an asterisk to the end of a word
			[mySearchString replaceOccurrencesOfString:@" " withString:@"* " 
					options:NSCaseInsensitiveSearch range:NSMakeRange(0,[mySearchString length])];
			
			if ( [mySearchString length] > 0 && [mySearchString characterAtIndex:[mySearchString length]-1] != '*' )
				[mySearchString appendString:@"*"];
		}
		
		BOOL spaceMeansOr = [[NSUserDefaults standardUserDefaults] boolForKey:@"SearchSpaceMeansOr"];
		searchOptions = ( spaceMeansOr ? kSKSearchOptionSpaceMeansOR : kSKSearchOptionDefault );
		
		// if a valid search string has been established, perform the search
		if ( mySearchString != nil ) 
		{
			
			// ensure that the journal is selected if no folder is selected
			if ( [self selectedFolders] == nil || [[self selectedFolders] count] == 0 )
			{
				keepSearching = YES;
				[sourceListController selectCollection:[self valueForKeyPath:@"journal.libraryCollection"] byExtendingSelection:NO];
				keepSearching = NO;
			}
			
			if ( preSearchTableState == nil )
			{
				preSearchTableState = [[entriesTable stateArray] retain];
			}
			
			JournlerSearchOptions journlerOptions = kSearchEntries | kSearchResources;

			success = [[[self journal] searchManager] performSearch:mySearchString 
					options:searchOptions journlerSearchOptions:journlerOptions
					maximumTime:10 maximumHits:1000 
					entries:&entries resources:&references entryHits:&entryHits referenceHits:&referenceHits];
			
			// show the search column
			[entriesTable setColumnWithIdentifier:@"relevanceNumber" hidden:NO];
			NSInteger relevanceIndex = [entriesTable columnWithIdentifier:@"relevanceNumber"];
			[entriesTable moveColumn:relevanceIndex toColumn:0];
			
			// ensure that the entries table is sorting by rank
			if ( ![[entriesController sortDescriptors] isEqualToArray:EntrySearchDescriptors()] )
			{
				[preSearchDescriptors release];
				preSearchDescriptors = [[NSArray alloc] initWithArray:[entriesController sortDescriptors]];
				
				[entriesController setSortDescriptors:EntrySearchDescriptors()];
			}
			
			// ensure that the resource table is sorting by rank
			//if ( ![[[resourceTable titleColumn] sortDescriptorPrototype] isEqual:ResourceByRankSortPrototype()] )
			//{
				[resourceController sortBy:kSortResourcesByRank];
			//}
			
			[self highlightString:[self searchString]];

		}
		
		// intersect the search results and rearrange
		[entriesController setIntersectSet:entries];
		[resourceController setShowingSearchResults:YES];
		[resourceController rearrangeObjects];
	}
	
	// scroll to the top of the table whatever happens
	[entriesTable scrollRowToVisible:0];
}

- (BOOL) isFiltering
{
	return (entryFilter != nil );
}

- (IBAction) filterEntries:(id)sender 
{	
	if ( entryFilter == nil ) 
	{
		entryFilter = [[EntryFilterController alloc] initWithDelegate:self];
		[[browserContentSplit subviewAtPosition:0] addSubview:[entryFilter contentView]];
		[self entryFilterController:entryFilter frameDidChange:[[entryFilter contentView] frame]];
		[entryFilter appropriateFirstResponder:[[self tabContent] window]];
	}
	else 
	{
		// save the search as a smart folder if the alt key is down
		if ( [[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask )
			[self saveFilterResults:sender];
		
		// recalculate the split's dimension
		float dimension = [[browserContentSplit subviewAtPosition:0] dimension] - [[entryFilter contentView] frame].size.height - 1;
		
		// hide the filter
		[[entryFilter contentView] removeFromSuperviewWithoutNeedingDisplay];
		[entryFilter release];
		entryFilter = nil;
		
		// reset the predicate filter on the entries controller
		[entriesController setFilterPredicate:nil];

		// resize the views
		NSRect browserBounds = [[browserContentSplit subviewAtPosition:0] bounds];
		
		browserBounds.origin.x = -1;
		browserBounds.size.width += 2;
		browserBounds.origin.y = 0;
		//browserBounds.size.height -= 1;
		
		[[entriesTable enclosingScrollView] setFrame:browserBounds];
		[[browserContentSplit subviewAtPosition:0] setDimension:dimension];
	}
}

- (void) entryFilterController:(EntryFilterController*)filterController predicateDidChange:(NSPredicate*)filterPredicate
{	
	[entriesController setFilterPredicate:filterPredicate];	
}

- (void) entryFilterController:(EntryFilterController*)filterController frameDidChange:(NSRect)filterFrame 
{
	// the search bar frame changed because of filtering, so change the browse frame
	NSInteger kDeltaHeight = filterFrame.size.height;
	
	// calculate the frame for the entries table
	NSRect entriesTableFrame = [[entriesTable enclosingScrollView] frame];
	NSRect entriesTableSubviewFrame = [[browserContentSplit subviewAtPosition:0] frame];
	
	// dimension for the split's subview which contains the browser
	float dimension = entriesTableFrame.size.height + kDeltaHeight + 1;
	
	entriesTableFrame.size.height = entriesTableSubviewFrame.size.height - ( kDeltaHeight + 1 );
		
	[[entriesTable enclosingScrollView] setFrame:entriesTableFrame];
	
	// calculate the frame for the filters
	NSRect searchRect;
	searchRect = NSMakeRect(0, entriesTableSubviewFrame.size.height - ( kDeltaHeight + 1 ), 
			entriesTableSubviewFrame.size.width, kDeltaHeight);
	
	[[filterController contentView] setFrame:searchRect];
	
	[[browserContentSplit subviewAtPosition:0] setDimension:dimension];

}

- (NSArray *)tokenField:(NSTokenField *)tokenField 
		completionsForSubstring:(NSString *)substring 
		indexOfToken:(NSInteger )tokenIndex 
		indexOfSelectedItem:(NSInteger *)selectedIndex
{
	//NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self beginswith[cd] %@", substring];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self beginswith %@", substring];
	NSArray *completions = [[[[self journal] entryTags] allObjects] filteredArrayUsingPredicate:predicate];
	return completions;
}


#pragma mark -

- (IBAction) saveSearchResults:(id)sender
{
	// create a regular folder under the selected folder
	
	JournlerCollection *newFolder;
	JournlerCollection *targetFolder;
	NSArray *selectedObjects = [sourceListController selectedObjects];
	
	// determine how the folder will be added to the list
	if ( [selectedObjects count] == 1 )	
	{
		targetFolder = [selectedObjects objectAtIndex:0];
		NSInteger type = [[targetFolder valueForKey:@"typeID"] integerValue];
		if ( type == PDCollectionTypeIDLibrary || type == PDCollectionTypeIDTrash )
			targetFolder = [[self journal] rootCollection];
	}
	else
	{
		targetFolder = [[self journal] rootCollection];
	}
	
	newFolder = [[[JournlerCollection alloc] init] autorelease];
	[newFolder setValue:[sender stringValue] forKey:@"title"];
	[newFolder setValue:[NSNumber numberWithInteger:[[self journal] newFolderTag]] forKey:@"tagID"];
	[newFolder setValue:[NSNumber numberWithInteger:PDCollectionTypeIDFolder] forKey:@"typeID"];
	
	[newFolder determineIcon];
	[newFolder setValue:[NSArray arrayWithArray:[entriesController arrangedObjects]] forKey:@"entries"];
	
	[[self journal] addCollection:newFolder];
	[targetFolder addChild:newFolder atIndex:-1];
	
	// write the new folder and target immediately to disk
	[[self journal] saveCollection:newFolder];
	[[self journal] saveCollection:targetFolder];
	
	// reload the list and select the folder
	[[self journal] setRootFolders:nil];
	[sourceListController selectCollection:newFolder byExtendingSelection:NO];
	[sourceList editColumn:0 row:[sourceList rowForOriginalItem:newFolder] withEvent:nil select:YES];
}

- (IBAction) saveFilterResults:(id)sender
{
	// make sure the filter is active
	if ( entryFilter == nil )
	{
		NSBeep(); return;
	}
	
	// grab the current conditions and the current folder, make a new smart folder!
	NSArray *conditions = [entryFilter conditions];
	if ( conditions == nil || [conditions count] == 0 ) 
	{
		NSBeep(); return;
	}
	
	// grab the style and predicates for the folder's title
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setDateStyle:NSDateFormatterMediumStyle];
	[formatter setTimeStyle:NSDateFormatterNoStyle];
	
	NSString *dateString = [formatter stringFromDate:[NSDate date]];
	NSString *smartTitle = [NSString stringWithFormat:NSLocalizedString(@"dated untitled title", @""), dateString];
	
	// determine how the folder will be added to the list
	JournlerCollection *targetFolder;
	NSArray *selectedObjects = [self selectedFolders];
	
	if ( [selectedObjects count] == 1 )	
	{
		targetFolder = [selectedObjects objectAtIndex:0];
		NSInteger type = [[targetFolder valueForKey:@"typeID"] integerValue];
		if ( type == PDCollectionTypeIDLibrary || type == PDCollectionTypeIDTrash )
			targetFolder = [[self journal] rootCollection];
	}
	else
	{
		targetFolder = [[self journal] rootCollection];
	}	
	
	// create the smart folder and set its properties
	JournlerCollection *newFolder = [[[JournlerCollection alloc] init] autorelease];
	
	[newFolder setValue:[NSNumber numberWithInteger:[[self journal] newFolderTag]] forKey:@"tagID"];
	[newFolder setValue:[NSNumber numberWithInteger:PDCollectionTypeIDSmart] forKey:@"typeID"];
	[newFolder setValue:smartTitle forKey:@"title"];
	[newFolder setValue:[NSNumber numberWithInteger:1] forKey:@"combinationStyle"];
	[newFolder setValue:conditions forKey:@"conditions"];
	
	[newFolder determineIcon];
	
	// add the folder to the target folder
	[[self journal] addCollection:newFolder];
	[targetFolder addChild:newFolder atIndex:-1];
	
	// collect the folder's entries - could take a while now that entries are loading lazily
	[newFolder evaluateAndAct:[[self journal] valueForKey:@"entries"] considerChildren:NO];
	
	// write the new folder immediately to disk
	[[self journal] saveCollection:newFolder];
	[[self journal] saveCollection:targetFolder];
	
	// reload the list
	[[self journal] setRootFolders:nil];
	// select the new folder
	[sourceListController selectCollection:newFolder byExtendingSelection:NO];
	[sourceList editColumn:0 row:[sourceList rowForOriginalItem:newFolder] withEvent:nil select:YES];
}

- (IBAction) clearSearchAndFilter:(id)sender
{
	// clear the filter if there is one
	if ( [self isFiltering] ) [self filterEntries:self];
	if ( [[self owner] respondsToSelector:@selector(clearSearch:)] )
		[[self owner] performSelector:@selector(clearSearch:) withObject:sender];
}

#pragma mark -

- (IBAction) exportResource:(id)sender
{
	// override if there's a single selection and the resource view is active, otherwise pass to super
	if ( [self activeContentView] == [resourceCellController contentView] && [[self selectedResources] count] == 1 )
		[resourceCellController exportResource:sender];
	else
		[super exportResource:sender];
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
	
	// and update the image no matter what
	[self _updateResourceToggleImage];
}

- (IBAction) showFolderWorktoolContextual:(id)sender
{
	[worktoolPopCell performClickWithFrame:[folderWorktool bounds] inView:folderWorktool];
}

- (IBAction) showResourceWorktoolContextual:(id)sender
{
	[resourceWorktoolPopCell performClickWithFrame:[resourceWorktool bounds] inView:resourceWorktool];
}

- (IBAction) toggleRuler:(id)sender
{
	if ( [self activeContentView] != [entryCellController contentView] )
	{
		NSBeep(); return;
	}
	else
	{
		[[entryCellController textView] toggleRuler:sender];
	}
}

#pragma mark -

- (IBAction) getInfo:(id)sender
{
	NSResponder *focusedResponder = [[[self tabContent] window] firstResponder];
	
	if ( focusedResponder == resourceTable && [[self selectedResources] count] != 0 )
		[self getResourceInfo:sender];
	else if ( focusedResponder == entriesTable && [[self selectedEntries] count] != 0 )
		[self getEntryInfo:sender];
	else if ( focusedResponder == sourceList && [[self selectedFolders] count] != 0 )
		[self getFolderInfo:sender];
	else
		[super getInfo:sender];
}

#pragma mark -
#pragma mark Creating New Entries and Folders

- (IBAction) newEntry:(id)sender
{
	JournlerEntry *newEntry;
	NSArray *targetFolders = nil;
	
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"QuickEntryCreation"] )
	{
		// quickly create a new entry if the user wishes it
		newEntry = [self newDefaultEntryWithSelectedDate:[calendar valueForKey:@"selectedDate"] overridePreference:NO];
		targetFolders = [self selectedFolders];
	}
	else
	{
		NSInteger result;
		NewEntryController *entryCreator = [[[NewEntryController alloc] initWithJournal:[self valueForKey:@"journal"]] autorelease];
		
		// the date depends on the preference
		if ( [[NSUserDefaults standardUserDefaults] integerForKey:@"DateForNewEntry"] == 0 )
			[entryCreator setValue:[NSCalendarDate calendarDate] forKey:@"date"];
		else
			[entryCreator setValue:[calendar valueForKey:@"selectedDate"] forKey:@"date"];
		
		// is there a selected folder?
		[entryCreator setSelectedFolders:[self selectedFolders]];
		
		// tag completions
		[entryCreator setTagCompletions:[[[self journal] entryTags] allObjects]];
				
		// run the entry builder
		result = [entryCreator runAsSheetForWindow:[tabContent window] attached:[[tabContent window] isMainWindow]];
		if ( result != NSRunStoppedResponse )
		{
			_didCreateNewEntry = NO;
			return;
		}
		
		// prepare the new entry
		newEntry = [[[JournlerEntry alloc] init] autorelease];
		[newEntry setJournal:[self journal]];
		
		[newEntry setValue:[NSNumber numberWithInteger:[[self journal] newEntryTag]] forKey:@"tagID"];
		[newEntry setValue:[NSCalendarDate calendarDate] forKey:@"calDateModified"];
		[newEntry setValue:[entryCreator valueForKey:@"category"] forKey:@"category"];
		[newEntry setValue:[entryCreator valueForKey:@"tags"] forKey:@"tags"];
		[newEntry setValue:[[entryCreator valueForKey:@"date"] dateWithCalendarFormat:nil timeZone:nil] forKey:@"calDate"];
		[newEntry setValue:[entryCreator valueForKey:@"labelValue"] forKey:@"label"];
		[newEntry setValue:[entryCreator valueForKey:@"marking"] forKey:@"marked"];
		
		// date due
		if ( [entryCreator includeDateDue] )
			[newEntry setValue:[[entryCreator valueForKey:@"dateDue"] dateWithCalendarFormat:nil timeZone:nil] forKey:@"calDateDue"];
		
		// ensure a title
		NSString *title = [entryCreator valueForKey:@"title"];
		if ( title == nil || [title length] == 0 )
		{
			NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
			[formatter setDateStyle:NSDateFormatterLongStyle];
			[formatter setTimeStyle:NSDateFormatterNoStyle];
			
			NSString *dateString = [formatter stringFromDate:[entryCreator valueForKey:@"date"]];
			title = [NSString stringWithFormat:NSLocalizedString(@"dated untitled title", @""), dateString];
		}
		
		// default attributed content
		NSAttributedString *attributedContent = [[[NSAttributedString alloc] 
				initWithString:[NSString string] attributes:[JournlerEntry defaultTextAttributes]] autorelease];
		
		[newEntry setValue:title forKey:@"title"];
		[newEntry setValue:attributedContent forKey:@"attributedContent"];
		
		// add the entry to the journal and save it
		[[self journal] addEntry:newEntry];
		[[self journal] saveEntry:newEntry];
		
		// add the entry to the folder selected in the entry creator
		targetFolders = [entryCreator selectedFolders];
		//JournlerCollection *theTargetFolder = [entryCreator selectedCollection];
		//if ( theTargetFolder != nil )
		//	targetFolders = [NSArray arrayWithObject:theTargetFolder];
	}
	
	
	// add the entry to the selected folder(s)
   
    for ( JournlerCollection *aFolder in targetFolders )
	{
		if ( [aFolder isRegularFolder] )
			[aFolder addEntry:newEntry];
		else if ( [aFolder isSmartFolder] && [aFolder canAutotag:newEntry] )
			[aFolder autotagEntry:newEntry add:YES];
	}
	
	// save the entry once more now that it's been autotagged
	[[self journal] saveEntry:newEntry];
	
	// update the calendar and select the entry, watching out for default content
	//[datesController updateSelectedObjects:self];
	
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"NewEntryNewWindow"] && !_forceNewEntryToMainWindow )
	{
		// put up an entry window for this resource
		EntryWindowController *entryWindow = [[[EntryWindowController alloc] initWithJournal:[self journal]] autorelease];
		[entryWindow showWindow:self];
		
		// select the resource in the window
		[[entryWindow selectedTab] selectDate:nil folders:nil entries:[NSArray arrayWithObject:newEntry] resources:nil];
		[[entryWindow selectedTab] appropriateFirstResponderForNewEntry:[entryWindow window]];
	}
	else
	{
		// clear the search and filter if there is one
		[self clearSearchAndFilter:self];
		
		// select the entry, locating it if necessary
		if ( [[entriesController arrangedObjects] indexOfObjectIdenticalTo:newEntry] == NSNotFound )
		{
			// select the entry's date
			NSCalendarDate *date = [newEntry valueForKey:@"calDate"];
			[calendar setValue:date forKey:@"selectedDate"];
		}
		
		// select the entry and focus the user's input
		[entriesController setSelectedObjects:[NSArray arrayWithObject:newEntry]];
		[entriesController rearrangeObjects];
		
		// fork the first repsonder based on preferece
		if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"QuickEntryFocusesTitle"] && [entryCellController headerHidden] == NO )
			[[[self owner] window] makeFirstResponder:[entryCellController titleField]];
		else
			[[[self owner] window] makeFirstResponder:[entryCellController textView]];
	}
	
	//[entryCellController appropriateFirstResponder:[[self owner] window]];
	
	_didCreateNewEntry = YES;
}

- (IBAction) newEntryWithClipboardContents:(id)sender
{
	NSArray *pasteboardEntries = [[NSApp delegate] entriesForPasteboardData:[NSPasteboard generalPasteboard] visual:NO preferredTypes:nil];
	if ( pasteboardEntries == nil )
	{
		NSBeep();
		[[NSAlert pasteboardImportFailure] runModal];
	}
	else
	{
		
		if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"NewEntryNewWindow"] && !_forceNewEntryToMainWindow )
		{
            for ( JournlerEntry *anEntry in pasteboardEntries )
			{
			
				// put up an entry window for this resource
				EntryWindowController *entryWindow = [[[EntryWindowController alloc] initWithJournal:[self journal]] autorelease];
				[entryWindow showWindow:self];
				
				// select the resource in the window
				[[entryWindow selectedTab] selectDate:nil folders:nil entries:[NSArray arrayWithObject:anEntry] resources:nil];
				[[entryWindow selectedTab] appropriateFirstResponder:[entryWindow window]];
			
			}
		}
		else
		{
			JournlerEntry *anEntry = [pasteboardEntries objectAtIndex:0];
			
			// clear the search and filter if there is one
			[self clearSearchAndFilter:self];
			
			// select the first entry, locating it if necessary
			if ( [[entriesController arrangedObjects] indexOfObjectIdenticalTo:anEntry] == NSNotFound )
			{
				// select the entry's date
				NSCalendarDate *date = [anEntry valueForKey:@"calDate"];
				[calendar setValue:date forKey:@"selectedDate"];
			}
			
			// select the entry and focus the user's input
			[entriesController setSelectedObjects:[NSArray arrayWithObject:anEntry]];
			[entriesController rearrangeObjects];
			
			[[[self owner] window] makeFirstResponder:[entryCellController textView]];
		}
	}
}

- (IBAction) newFolder:(id)sender
{
	JournlerCollection *newFolder;
	JournlerCollection *targetFolder;
	NSArray *selectedObjects = [sourceListController selectedObjects];
	
	// determine how the folder will be added to the list
	if ( [selectedObjects count] == 1 )	
	{
		targetFolder = [selectedObjects objectAtIndex:0];
		NSInteger type = [[targetFolder valueForKey:@"typeID"] integerValue];
		if ( type == PDCollectionTypeIDLibrary || type == PDCollectionTypeIDTrash )
			targetFolder = [[self journal] rootCollection];
	}
	else
	{
		targetFolder = [[self journal] rootCollection];
	}
	
	newFolder = [[[JournlerCollection alloc] init] autorelease];
	[newFolder setValue:NSLocalizedString(@"untitled title",@"") forKey:@"title"];
	[newFolder setValue:[NSNumber numberWithInteger:[[self journal] newFolderTag]] forKey:@"tagID"];
	[newFolder setValue:[NSNumber numberWithInteger:PDCollectionTypeIDFolder] forKey:@"typeID"];
	
	[newFolder determineIcon];
	
	// add the selected entries to the folder if more than one entry is selected
	NSArray *theSelectedEntries = [self selectedEntries];
	if ( [theSelectedEntries count] > 1 )
	{
        for ( JournlerEntry *anEntry in theSelectedEntries )
			[newFolder addEntry:anEntry];
	}
	
	[[self journal] addCollection:newFolder];
	[targetFolder addChild:newFolder atIndex:-1];
	
	// write the new folder and target immediately to disk
	[[self journal] saveCollection:newFolder];
	[[self journal] saveCollection:targetFolder];
	
	// reload the list and select the folder
	[[self journal] setRootFolders:nil];
	[sourceListController selectCollection:newFolder byExtendingSelection:NO];
	[sourceList editColumn:0 row:[sourceList rowForOriginalItem:newFolder] withEvent:nil select:YES];
}

- (IBAction) newSmartFolder:(id)sender
{
	//NSLog(@"%s - beginning",__PRETTY_FUNCTION__);
	
	NSInteger result;
	
	//NSLog(@"[IntelligentCollectionController alloc]");
	IntelligentCollectionController *smartCreator = [[[IntelligentCollectionController alloc] init] autorelease];
	
	//NSLog(@"[smartCreator setTagCompletions:...]");
	[smartCreator setTagCompletions:[[[self journal] entryTags] allObjects]];
	
	// run the smart folder creator
	//NSLog(@"[smartCreator runAsSheetForWindow:...]");
	result = [smartCreator runAsSheetForWindow:[tabContent window] attached:[[tabContent window] isMainWindow]];
	if ( result != NSRunStoppedResponse )
	{
		//NSLog(@"if ( result != NSRunStoppedResponse ) -- user cancelled");
		return;
	}
	
	// determine how this folder will be added to the list
	JournlerCollection *newFolder;
	JournlerCollection *targetFolder;
	
	//NSLog(@"[sourceListController selectedObjects]");
	NSArray *selectedObjects = [sourceListController selectedObjects];
	
	// determine how the folder will be added to the list
	if ( [selectedObjects count] == 1 )	
	{
		//NSLog(@"if ( [selectedObjects count] == 1 )	-- beginning");
		
		targetFolder = [selectedObjects objectAtIndex:0];
		NSInteger type = [[targetFolder valueForKey:@"typeID"] integerValue];
		if ( type == PDCollectionTypeIDLibrary || type == PDCollectionTypeIDTrash )
			targetFolder = [[self journal] rootCollection];
		
		//NSLog(@"if ( [selectedObjects count] == 1 )	-- ending");
	}
	else
	{
		//NSLog(@"if ( [selectedObjects count] == 1 )	-- else");
		targetFolder = [[self journal] rootCollection];
	}	
	
	// create the smart folder and set its properties
	//NSLog(@"[[[JournlerCollection alloc] init] autorelease]");
	newFolder = [[[JournlerCollection alloc] init] autorelease];
	
	[newFolder setValue:[NSNumber numberWithInteger:[[self journal] newFolderTag]] forKey:@"tagID"];
	[newFolder setValue:[NSNumber numberWithInteger:PDCollectionTypeIDSmart] forKey:@"typeID"];
	[newFolder setValue:[smartCreator valueForKey:@"combinationStyle"] forKey:@"combinationStyle"];
	[newFolder setValue:[smartCreator valueForKey:@"conditions"] forKey:@"conditions"];
	
	// folder title
	NSString *folderTitle = [smartCreator valueForKey:@"folderTitle"];
	if ( folderTitle == nil || [folderTitle length] == 0 )
		folderTitle = NSLocalizedString(@"untitled title",@"");
	
	[newFolder setValue:folderTitle forKey:@"title"];
	
	[newFolder determineIcon];
	[newFolder generateDynamicDatePredicates:NO];
	
	// add the folder to the target folder
	[[self journal] addCollection:newFolder];
	[targetFolder addChild:newFolder atIndex:-1];
	
	// collect the folder's entries - could take a while now that entries are loading lazily
	[newFolder evaluateAndAct:[[self journal] valueForKey:@"entries"] considerChildren:NO];
	
	// write the new folder immediately to disk
	[[self journal] saveCollection:newFolder];
	[[self journal] saveCollection:targetFolder];
	
	// reload the list
	[[self journal] setRootFolders:nil];
	// select the new folder
	[sourceListController selectCollection:newFolder byExtendingSelection:NO];
	
	//NSLog(@"%s - ending",__PRETTY_FUNCTION__);
}

#pragma mark -
#pragma mark Deleting Objects

- (IBAction) performDelete:(id)sender
{
	// route the operation according to the selection
	if ( [[[self owner] window] firstResponder] == resourceTable )
		[self deleteSelectedResources:sender];
	else if ( [[[self owner] window] firstResponder] == entriesTable || [entryCellController textView] )
		[self deleteSelectedEntries:sender];
	else if ( [[[self owner] window] firstResponder] == sourceList )
		[self deleteSelectedFolder:sender];
	else
		NSBeep();
}

- (IBAction) deleteSelectedFolder:(id)sender
{
	if ( [sourceList selectedRow] == -1 )
	{
		NSBeep(); return;
	}
	
    // make sure the trash and the library aren't selected
    
    NSArray *theSelectedFolders = [[[sourceListController selectedObjects] copy] autorelease];
    
    for ( JournlerCollection *aFolder in [theSelectedFolders reverseObjectEnumerator] )
	{
		if ( [aFolder isLibrary] || [aFolder isTrash] )
		{
			NSBeep(); return;
		}
	}
	
	NSBeep();
	if ( [[NSAlert confirmFolderDelete] runModal] != NSAlertFirstButtonReturn )
		return;
	
	// deselect
	[sourceList deselectAll:sender];
	
	recordNavigationEvent = NO;
	[sourceListController remove:self];
	
    /*
    // reset the enumerator
	enumerator = [[sourceListController selectedObjects] reverseObjectEnumerator];
	while ( aFolder = [enumerator nextObject] )
     */
    for ( JournlerCollection *aFolder in [theSelectedFolders reverseObjectEnumerator] )
	{
		if ( ![aFolder isLibrary] && ![aFolder isTrash] )
			[[self journal] deleteCollection:aFolder deleteChildren:YES];
		
		// reload the root list each round
		//[[self journal] setRootFolders:nil];
	}
	
	recordNavigationEvent = YES;
}

- (IBAction) deleteSelectedEntries:(id)sender
{	
	//
	// a distribution point to determine how the delete command is to be handled
	// a) send to trash b) delete from trash c) remove from folder

	NSArray *theSelectedFolders = [self valueForKey:@"selectedFolders"];
	
	if ( ( [sender isKindOfClass:[NSMenuItem class]] && [sender tag] == 10020 ) || [sender isKindOfClass:[NSToolbarItem class]] )
	{
		// the reqest is coming from the delete menu or the delete toolbar item - force trash or completely remove entries
		if ( [theSelectedFolders count] == 1 && [[theSelectedFolders objectAtIndex:0] isTrash] )
		{
			// if the trash is selected, delete the entries from the journal
			[self removeSelectedEntriesFromJournal:sender];
		}
		else
		{
			// if any folder is selected, force a trashing
			[self trashSelectedEntries:sender];
		}
	}
	else
	{
		if ( [theSelectedFolders count] == 0 )
		{
			if ( GetCurrentEventKeyModifiers() & cmdKey )
				// a date is selected, send to trash
				[self trashSelectedEntries:sender];
			else
				NSBeep();
		}
		else
		{
			// a folder is selected, determine how best to act
			if ( [theSelectedFolders count] != 1 )
			{
				NSBeep();
			}
			else if ( [[theSelectedFolders objectAtIndex:0] isTrash] )
			{
				if ( GetCurrentEventKeyModifiers() & cmdKey )
					// the trash is selected, delete the entries
					[self removeSelectedEntriesFromJournal:sender];
				else
					NSBeep();
			}
			else
			{
				if ( GetCurrentEventKeyModifiers() & cmdKey )
				//if ( [[NSApp currentEvent] modifierFlags] & NSCommandKeyMask )
				{
					// the command key is down, send entries to trash no matter the selection
					[self trashSelectedEntries:sender];
				}
				else if ( [theSelectedFolders count] == 1 && [[theSelectedFolders objectAtIndex:0] isRegularFolder] )
				{
					// remove the entries from the folders, but only if all the folders are regular folders
					[self removeSelectedEntriesFromFolder:sender];
				}
				else
				{
					// operation not allowed
					NSBeep();
				}
			}
		}
	}
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
		__PRETTY_FUNCTION__, [theResources valueForKey:@"tagID"], [theEntries valueForKey:@"tagID"], errors);
	}
	
	// save the changes
	[[self journal] setSaveEntryOptions:(kEntrySaveDoNotIndex|kEntrySaveDoNotCollect)];
	[[NSApp delegate] performSelector:@selector(save:) withObject:self];
	[[self journal] setSaveEntryOptions:kEntrySaveIndexAndCollect];
}

#pragma mark -
#pragma mark Trashing, Removing, Deleting Entries

- (IBAction) trashSelectedEntries:(id)sender
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	// make sure entries are selected to be deleted
	NSArray *theSelectedEntries = [NSArray arrayWithArray:[self valueForKey:@"selectedEntries"]];
	if ( theSelectedEntries == nil || [theSelectedEntries count] == 0 )
	{
		NSBeep(); return;
	}
	
	// deselect
	[entriesTable deselectAll:self];
	
	// peform the trashing
  
    for ( JournlerEntry *anEntry in theSelectedEntries )
		[[self valueForKey:@"journal"] markEntryForTrash:anEntry];
	
	[datesController updateSelectedObjects:self];
	
	// save the changes
	//[[self journal] setSaveEntryOptions:(kEntrySaveDoNotIndex|kEntrySaveDoNotCollect)];
	//[[NSApp delegate] performSelector:@selector(save:) withObject:self];
	//[[self journal] setSaveEntryOptions:kEntrySaveIndexAndCollect];
}

- (IBAction) removeSelectedEntriesFromFolder:(id)sender
{	
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	// make sure entries are selected to be deleted
	NSArray *theSelectedEntries = [NSArray arrayWithArray:[self valueForKey:@"selectedEntries"]];
	if ( theSelectedEntries == nil || [theSelectedEntries count] == 0 )
	{
		NSBeep(); return;
	}
	
	NSArray *theSelectedFolders = [self valueForKey:@"selectedFolders"];
	if ( theSelectedFolders == nil || [theSelectedFolders count] == 0 )
	{
		// do not remove from the folders if no folders are selected
		NSBeep(); return;
	}
	else
	{
		// make sure the folders selected are all normal folders, otherwise bail
        for ( JournlerCollection *aFolder in theSelectedFolders )
		{
			if ( [[aFolder valueForKey:@"typeID"] integerValue] != PDCollectionTypeIDFolder )
			{
				NSBeep(); return;
			}
		}
		
		// deselect
		[entriesTable deselectAll:self];
		
        // iterate through each selected folder, removing the selected entries
        /*
        // re-establish the enumerator
		enumerator = [theSelectedFolders objectEnumerator];
		while ( aFolder = [enumerator nextObject] )
         */
        for ( JournlerCollection *aFolder in theSelectedFolders )
		{
			for ( JournlerEntry *anEntry in theSelectedEntries )
			{
				//#warning this is slow! could be faster removing the entries as an array at one go
				[aFolder removeEntry:anEntry];
			}
		}
	}
	
	//[datesController updateSelectedObjects:self];
	
	// save the changes
	[[self journal] setSaveEntryOptions:(kEntrySaveDoNotIndex|kEntrySaveDoNotCollect)];
	[[NSApp delegate] performSelector:@selector(save:) withObject:self];
	[[self journal] setSaveEntryOptions:kEntrySaveIndexAndCollect];
}

- (IBAction) removeSelectedEntriesFromJournal:(id)sender
{
	NSBeep();
	if ( [[NSAlert confirmEntryDelete] runModal] != NSAlertFirstButtonReturn )
		return;
	
	// make sure entries are selected to be deleted
	NSArray *theSelectedEntries = [NSArray arrayWithArray:[self valueForKey:@"selectedEntries"]];
	if ( theSelectedEntries == nil || [theSelectedEntries count] == 0 )
	{
		NSBeep(); return;
	}
	
	// deselect
	[entriesTable deselectAll:self];
	
	// perform the deletion
    for ( JournlerEntry *anEntry in theSelectedEntries )
		[[self valueForKey:@"journal"] deleteEntry:anEntry];
	
	//[datesController updateSelectedObjects:self];
	
	// save the changes
	[[self journal] setSaveEntryOptions:(kEntrySaveDoNotIndex|kEntrySaveDoNotCollect)];
	[[NSApp delegate] performSelector:@selector(save:) withObject:self];
	[[self journal] setSaveEntryOptions:kEntrySaveIndexAndCollect];
}

- (IBAction) untrashSelectedEntries:(id)sender
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	// make sure entries are selected to be deleted
	NSArray *theSelectedEntries = [NSArray arrayWithArray:[self valueForKey:@"selectedEntries"]];
	if ( theSelectedEntries == nil || [theSelectedEntries count] == 0 )
	{
		NSBeep(); return;
	}
	
	// deselect
	[entriesTable deselectAll:self];
	
	// perform the untrashing
    for ( JournlerEntry *anEntry in theSelectedEntries )
	{
		[[self valueForKey:@"journal"] unmarkEntryForTrash:anEntry];
		[[self valueForKey:@"journal"] updateIndexAndCollections:anEntry];
	}
	
	[datesController updateSelectedObjects:self];
	
	// save the changes
	//[[self journal] setSaveEntryOptions:(kEntrySaveDoNotIndex|kEntrySaveDoNotCollect)];
	//[[NSApp delegate] performSelector:@selector(save:) withObject:self];
	//[[self journal] setSaveEntryOptions:kEntrySaveIndexAndCollect];
}

- (void) _journalWillChangeEntrysTrashStatus:(NSNotification*)aNotification
{
	// modify the entry selection if the trashed/untrashed entry is included
	JournlerEntry *anEntry = [[aNotification userInfo] objectForKey:@"entry"];
	if ( anEntry != nil ) [entriesController removeSelectedObjects:[NSArray arrayWithObject:anEntry]];
}

- (void) _journalDidChangeEntrysTrashStatus:(NSNotification*)aNotification
{
	// update the dates controller if a date is selected (there is no folder selection)
	if ( [self selectedFolders] == nil || [[self selectedFolders] count] == 0 )
	[datesController updateSelectedObjects:self];
	
	// also update the calendar
	[calendar updateDaysWithEntries];
	if ( [[self tabContent] window] != nil )
		[calendar setNeedsDisplay:YES];
}

#pragma mark -

- (void) _journlerDidFinishImport:(NSNotification*)aNotification
{
	// update the calendar
	[calendar updateDaysWithEntries];
	if ( [[self tabContent] window] != nil )
		[calendar setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark Working with Folders

- (IBAction) renameFolder:(id)sender
{
	if ( [sourceList selectedRow] == -1 )
	{
		NSBeep(); return;
	}
	
	[sourceList editColumn:0 row:[sourceList selectedRow] withEvent:nil select:YES];
}

- (IBAction) editSmartFolder:(id)sender
{
	NSArray *theFolders = [self valueForKey:@"selectedFolders"];
	if ( theFolders == nil || [theFolders count] != 1 )
	{
		NSBeep(); return;
	}
	
	NSInteger result;
	JournlerCollection *aFolder = [theFolders objectAtIndex:0];
	IntelligentCollectionController *smartCreator = [[[IntelligentCollectionController alloc] init] autorelease];
	
	[smartCreator setTagCompletions:[[[self journal] entryTags] allObjects]];
	[smartCreator setInitialFolderTitle:[aFolder valueForKey:@"title"]];
	[smartCreator setInitialConditions:[aFolder valueForKey:@"conditions"]];
	[smartCreator setInitialCombinationStyle:[aFolder valueForKey:@"combinationStyle"]];
	
	result = [smartCreator runAsSheetForWindow:[sourceList window] attached:[[sourceList window] isMainWindow]];
	
	if ( result == NSRunStoppedResponse ) 
	{
		// grab the style and predicates
		NSArray *predicates = [smartCreator valueForKey:@"conditions"];
		NSNumber *combiStyle = [smartCreator valueForKey:@"combinationStyle"];
		NSString *smartTitle = [smartCreator valueForKey:@"folderTitle"];
		
		if ( !smartTitle || [smartTitle length] == 0 ) 
			smartTitle = NSLocalizedString(@"untitled title",@"");
		
		// set the new characteristics for the entry
		[aFolder setValue:smartTitle forKey:@"title"];
		[aFolder setValue:combiStyle forKey:@"combinationStyle"];
		[aFolder setValue:predicates forKey:@"conditions"];
		
		// evaluate with the new properties
		[aFolder invalidatePredicate:YES];
		[aFolder generateDynamicDatePredicates:NO];
		[aFolder evaluateAndAct:[self valueForKeyPath:@"journal.entries"] considerChildren:YES];
				
		// save the collection and it's children
		[[self valueForKey:@"journal"] saveCollection:aFolder saveChildren:YES];
		
		//NSLog([[aFolder conditions] description]);
	}
}

- (IBAction) emptyTrash:(id)sender
{
	if ( [[NSAlert confirmEmptyTrash] runModal] != NSAlertFirstButtonReturn )
		return;
	
	NSArray *trashedEntries = [NSArray arrayWithArray:[self valueForKeyPath:@"journal.trashCollection.entries"]];
	for ( JournlerEntry *anEntry in trashedEntries )
		[[self valueForKey:@"journal"] deleteEntry:anEntry];
}

- (IBAction) editFolderProperty:(id)sender
{	
	return;
}

- (IBAction) selectFolderFromMenu:(id)sender 
{	
	[sourceListController selectCollection:[sender representedObject] byExtendingSelection:NO];
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
	
	BOOL success;
	
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
	
	// locate the entry
	if ( [[entriesController arrangedObjects] indexOfObjectIdenticalTo:theEntry] == NSNotFound )
	{
		NSCalendarDate *aDate = [theEntry valueForKey:@"calDate"];
		[calendar setValue:aDate forKey:@"selectedDate"];
	}
	
	[resourceTable deselectAll:self];
	success = [entriesController setSelectedObjects:[NSArray arrayWithObject:theEntry]];
	
	// pass the entries to the cell controller
	[entryCellController setSelectedEntries:[NSArray arrayWithObject:theEntry]];

	return success;
}

- (IBAction) renameResource:(id)sender
{
	// pass it to the controller
	[resourceController renameResource:sender];
}

#pragma mark -
#pragma mark Working with Entries

- (IBAction) gotoRandomEntry:(id)sender
{
	BOOL trashed = YES;
	
	if ( [[self valueForKeyPath:@"journal.libraryCollection.entries"] count] == 0 )
	{
		NSBeep(); return;
	}
	
	while ( trashed )
	{
		NSInteger r = ( random() % [[self valueForKeyPath:@"journal.entries"] count] );
		JournlerEntry *theEntry = [[self valueForKeyPath:@"journal.entries"] objectAtIndex:r];
		if ( [[theEntry valueForKey:@"markedForTrash"] boolValue] )
			continue;
		else
		{
			// clear the search and filter if there is one
			[self clearSearchAndFilter:self];
			
			NSCalendarDate *ranDate = [[[self valueForKeyPath:@"journal.entries"] objectAtIndex:r] valueForKey:@"calDate"];
			[calendar setValue:ranDate forKey:@"selectedDate"];
			[entriesController setSelectedObjects:[NSArray arrayWithObject:[[self valueForKeyPath:@"journal.entries"] objectAtIndex:r]]];
			
			trashed = NO;
			break;
		}
	}
}

- (IBAction) gotoEntryDateInCalendar:(id)sender
{
	NSArray *theEntries = [self selectedEntries];
	if ( !theEntries || [theEntries count] == 0 ) 
	{
		NSBeep(); return;
	}
	
	JournlerEntry *anEntry = [theEntries objectAtIndex:0];
	NSCalendarDate *entryDate = [anEntry valueForKey:@"calDate"];
	
	[calendar setSelectedDate:entryDate];
	[entriesController setSelectedObjects:[NSArray arrayWithObject:anEntry]];
}

- (IBAction) editEntryPropertyInTable:(id)sender
{
	NSInteger rowIndex = [entriesTable selectedRow];
	if ( rowIndex == -1 )
	{
		NSBeep(); return;
	}
	
	// determine which column will be edited
	NSString *identifier = nil;
	
	switch ( [sender tag] )
	{
	case 10012:
		identifier = @"title";
		break;
	
	case 10013:
		identifier = @"category";
		break;
	
	case 10014:
		identifier = @"keywords";
		break;
	
	case 10015:
		identifier = @"calDate";
		break;
	}
	
	if ( identifier != nil )
	{
		NSInteger columnIndex = [entriesTable columnWithIdentifier:identifier];
		[entriesTable editColumn:columnIndex row:rowIndex withEvent:nil select:YES];
	}
	else 
	{
		NSBeep();
	}
}

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

- (IBAction) printEntrySelection:(id)sender
{
	// print the selected entries
	NSArray *printArray = [[[NSArray alloc] initWithArray:[self selectedEntries]] autorelease];
	NSDictionary *printDict = [NSDictionary dictionaryWithObjectsAndKeys: printArray, @"entries", nil];

	[self printEntries:printDict];

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
		// special case when dealing with a single entry - may be selection only
		NSAttributedString *content = [entryCellController selectedText];
		[JournlerApplicationDelegate sendRichMail:content to:@"" subject:[[theEntries objectAtIndex:0] valueForKey:@"title"] isMIME:YES withNSMail:NO];
	}
	
	else 
	{
		[super emailEntrySelection:sender];
	}

}


- (IBAction) duplicateEntry:(id)sender
{
	NSArray *theEntries = [self selectedEntries];
	if ( theEntries == nil || [theEntries count] == 0 ) {
		NSBeep(); return;
	}
	
	NSPredicate *regularFolders = [NSPredicate predicateWithFormat:@"isRegularFolder == YES"];
	NSArray *theFolders = [[self selectedFolders] filteredArrayUsingPredicate:regularFolders];
	
    for ( JournlerEntry *anEntry in theEntries )
	{
		// #warning does not duplicate media contents
		JournlerEntry *duplicated = [[anEntry copyWithZone:[self zone]] autorelease];
		NSString *title = [duplicated valueForKey:@"title"];
		
		//[duplicated setTagID:[NSNumber numberWithInteger:[[self journal] newEntryTag]]];
		//[[self journal] addEntry:duplicated];
		
		[duplicated setTitle:[NSString stringWithFormat:@"%@ %@", title, NSLocalizedString(@"duplicated entry", @"")]];
		
		[theFolders makeObjectsPerformSelector:@selector(addEntry:) withObject:duplicated];
		[[self journal] saveEntry:duplicated];
	}
}

#pragma mark -
#pragma mark Creating New Resources

- (IBAction) showNewResourceSheet:(id)sender
{
	// simulates a popup button but with a sheet-like window
	// switching to menu
	
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
        /*
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
        */
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

- (void) showFirstRunConfiguration
{
	JournlerEntry *theEntry = [[self journal] entryForTagID:[NSNumber numberWithInteger:1]];
	JournlerCollection *libraryFolder = [self valueForKeyPath:@"journal.libraryCollection"];
	
	[self selectDate:[theEntry valueForKey:@"calDate"] folders:[NSArray arrayWithObject:libraryFolder] 
			entries:[NSArray arrayWithObject:theEntry] resources:nil];
	
	[entriesTable setColumnWithIdentifier:@"blogged" hidden:YES];
	[entriesTable setColumnWithIdentifier:@"calDateModified" hidden:YES];
	[entriesTable setColumnWithIdentifier:@"label" hidden:YES];
	[entriesTable setColumnWithIdentifier:@"tagID" hidden:YES];
	[entriesTable setColumnWithIdentifier:@"relevanceNumber" hidden:YES];
	//[entriesTable setColumnWithIdentifier:@"calDateDue" hidden:YES];
	
	// hide the keywords (aka comments) field, leaving the new tags field visible
	[entriesTable setColumnWithIdentifier:@"keywords" hidden:YES];
	
	[[browserContentSplit subviewAtPosition:0] setDimension:100];
	[[foldersEntriesSplit subviewAtPosition:0] setDimension:190];
	
	[[contentResourceSplit subviewAtPosition:1] setDimension:200];
	[[contentResourceSplit subviewAtPosition:1] collapse];
	
	[resourceController exposeAllResources:self];
	[sourceListController exposeAllFolders:self];
	
	[[[self tabContent] window] makeFirstResponder:[entryCellController textView]];
	
	if ( [[[entryCellController textView] string] length] > 0 )
	{
		[[entryCellController textView] setSelectedRange:NSMakeRange(0,0)];
		[[entryCellController textView] scrollRangeToVisible:NSMakeRange(0,0)];
	}
	
	[entriesTable sizeToFit];
	[sourceList sizeToFit];
}

- (void) showFirstRunTabConfiguration
{
	[entriesTable setColumnWithIdentifier:@"blogged" hidden:YES];
	[entriesTable setColumnWithIdentifier:@"calDateModified" hidden:YES];
	//[entriesTable setColumnWithIdentifier:@"calDateDue" hidden:YES];
	[entriesTable setColumnWithIdentifier:@"label" hidden:YES];
	[entriesTable setColumnWithIdentifier:@"tagID" hidden:YES];
	[entriesTable setColumnWithIdentifier:@"tagID" hidden:YES];
	[entriesTable setColumnWithIdentifier:@"relevanceNumber" hidden:YES];
	[[browserContentSplit subviewAtPosition:0] setDimension:100];
	
	[[[self tabContent] window] makeFirstResponder:[entryCellController textView]];
	
	if ( [[[entryCellController textView] string] length] > 0 )
	{
		[[entryCellController textView] setSelectedRange:NSMakeRange(0,0)];
		[[entryCellController textView] scrollRangeToVisible:NSMakeRange(0,0)];
	}
	
	[entriesTable sizeToFit];
	[sourceList sizeToFit];
}

- (void) servicesMenuAppendSelection:(NSPasteboard*)pboard desiredType:(NSString*)type
{
	// pass the message to the cell controller - subclasses should override
	[entryCellController servicesMenuAppendSelection:pboard desiredType:type];
}

#pragma mark -
#pragma mark Working with the Calendar

- (IBAction) toToday:(id)sender
{
	[calendar toToday:sender];
}

- (IBAction) dayToRight:(id)sender
{
	[calendar dayToRight:sender];
}

- (IBAction) dayToLeft:(id)sender
{
	[calendar dayToLeft:sender];
}

- (IBAction) monthToRight:(id)sender
{
	[calendar monthToRight:sender];
}

- (IBAction) monthToLeft:(id)sender
{
	[calendar monthToLeft:sender];
}

#pragma mark -
#pragma mark Appearance

- (IBAction) toggleUsesAlternatingRows:(id)sender
{
	BOOL value = [[NSUserDefaults standardUserDefaults] boolForKey:@"BrowseTableAlternatingRows"];
	[[NSUserDefaults standardUserDefaults] setBool:!value forKey:@"BrowseTableAlternatingRows"];
}

- (IBAction) toggleDrawsLabelBackground:(id)sender
{
	BOOL value = [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryTableNoLabelBackground"];
	[[NSUserDefaults standardUserDefaults] setBool:!value forKey:@"EntryTableNoLabelBackground"];
}

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

- (IBAction) showEntryTableColumn:(id)sender
{
	NSString *identifier = nil;
	
	switch ( [sender tag] )
	{
	case 711:
		identifier = @"blogged";
		break;
	case 712:
		identifier = @"category";
		break;
	case 713:
		identifier = @"calDate";
		break;
	case 720:
		identifier = @"label";
		break;
	case 716:
		identifier = @"calDateModified";
		break;
	case 714:
		identifier = @"marked";
		break;
	case 715:
		identifier = @"keywords";
		break;
	case 717:
		identifier = @"calDateDue";
		break;
	case 718:
		identifier = @"tagID";
		break;
	case 721:
		identifier = @"numberOfResources";
		break;
	case 722:
		identifier = @"tags";
		break;
	}
	
	if ( identifier != nil )
	{
		// reset the sort descriptor to "title" if removing the currently sorted column
		NSArray *sortDescriptors = [entriesController sortDescriptors];
		if ( [sortDescriptors count] != 0 && [[[sortDescriptors objectAtIndex:0] key] isEqualToString:identifier] )
			[entriesController setSortDescriptors:[NSArray arrayWithObject:
						[[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES] autorelease]]];
			
		// toggle the column
		[entriesTable setColumnWithIdentifier:identifier hidden:![entriesTable columnWithIdentifierIsHidden:identifier]];
	}
}

- (IBAction) sortEntryTableByColumn:(id)sender
{
	NSSortDescriptor *descriptor = nil;
	
	switch ( [sender tag] ) 
	{
	case 731:
		descriptor = [[[NSSortDescriptor allocWithZone:[self zone]]
				initWithKey:@"blogged" ascending:YES selector:@selector(compare:)] autorelease];
		break;
	case 732:
		descriptor = [[[NSSortDescriptor allocWithZone:[self zone]]
				initWithKey:@"category" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] autorelease];
		break;
	case 733:
		descriptor = [[[NSSortDescriptor allocWithZone:[self zone]]
				initWithKey:@"calDate" ascending:YES selector:@selector(compare:)] autorelease];
		break;
	case 734:
		descriptor = [[[NSSortDescriptor allocWithZone:[self zone]]
				initWithKey:@"marked" ascending:YES selector:@selector(compare:)] autorelease];
		break;
	case 735:
		descriptor = [[[NSSortDescriptor allocWithZone:[self zone]]
				initWithKey:@"keywords" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] autorelease];
		break;
	case 736:
		descriptor = [[[NSSortDescriptor allocWithZone:[self zone]]
				initWithKey:@"calDateModified" ascending:YES selector:@selector(compare:)] autorelease];
		break;
	case 739:
		descriptor = [[[NSSortDescriptor allocWithZone:[self zone]]
				initWithKey:@"title" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] autorelease];
		break;
	case 740:
		descriptor = [[[NSSortDescriptor allocWithZone:[self zone]]
				initWithKey:@"label" ascending:YES selector:@selector(compare:)] autorelease];
		break;
	case 737:
		descriptor = [[[NSSortDescriptor allocWithZone:[self zone]]
				initWithKey:@"calDateDue" ascending:YES selector:@selector(compare:)] autorelease];
		break;
	case 738:
		descriptor = [[[NSSortDescriptor allocWithZone:[self zone]]
				initWithKey:@"tagID" ascending:YES selector:@selector(compare:)] autorelease];
		break;
	case 741:
		descriptor = [[[NSSortDescriptor allocWithZone:[self zone]]
				initWithKey:@"numberOfResources" ascending:YES selector:@selector(compare:)] autorelease];
		break;
	case 742:
		descriptor = [[[NSSortDescriptor allocWithZone:[self zone]]
				initWithKey:@"tags.@count" ascending:NO selector:@selector(compare:)] autorelease];
		break;
	}
	
	if ( ( descriptor && [entriesTable tableColumnWithIdentifier:[descriptor key]] ) 
			|| ( [[descriptor key] isEqualToString:@"tags.@count"] && [entriesTable tableColumnWithIdentifier:@"tags"] ) )
		[entriesController setSortDescriptors:[NSArray arrayWithObject:descriptor]];
	else
		NSBeep();
}

#pragma mark -
#pragma mark Shortcuts

- (IBAction) focusOnSection:(id)sender
{
	switch ( [sender tag] )
	{
	case 221: // folders
		[self makeSourceListFirstResponder:sender];
		break;
	case 222: // entries
		[self makeEntriesTableFirstResponder:sender];
		break;
	case 223: // content
		[self makeEntryTextFirstResponder:sender];
		break;
	case 224: // resources
		[self makeResourceTableFirstResponder:sender];
		break;
	}	
}

- (IBAction) makeSourceListFirstResponder:(id)sender
{
	[[[self tabContent] window] makeFirstResponder:sourceList];
}

- (IBAction) makeEntriesTableFirstResponder:(id)sender
{
	[[[self tabContent] window] makeFirstResponder:entriesTable];
}

- (IBAction) makeEntryTextFirstResponder:(id)sender
{
	[[[self tabContent] window] makeFirstResponder:[entryCellController textView]];
}

- (IBAction) makeResourceTableFirstResponder:(id)sender
{
	[[[self tabContent] window] makeFirstResponder:resourceTable];
}	

- (IBAction) previousDayWithEntries:(id)sender
{
	#warning seems to jump to before the currently selected date when searching
	NSInteger i;
	BOOL found = NO;
	
	// every entry sorted by date
	NSArray *allEntries = [[[self journal] entries] sortedArrayUsingDescriptors:
			[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"calDate" ascending:YES] autorelease]]];
	
	// the currently selected date
	NSCalendarDate *currentDate = [calendar selectedDate];
	
	// find the first entry according to the current date
	for ( i = 0; i < [allEntries count]; i++ ) 
	{
		NSCalendarDate *aDate = [[allEntries objectAtIndex:i] valueForKey:@"calDate"];
		if ( [aDate dayOfMonth] == [currentDate dayOfMonth] 
				&& [aDate monthOfYear] == [currentDate monthOfYear] && [aDate yearOfCommonEra] == [currentDate yearOfCommonEra] )
			break;
	}
	
	// find the first previous entry that does not have this date
	for ( --i; i > 0; i-- ) 
	{
		NSCalendarDate *aDate = [[allEntries objectAtIndex:i] valueForKey:@"calDate"];
		if ( [aDate dayOfMonth] != [currentDate dayOfMonth] 
				|| [aDate monthOfYear] != [currentDate monthOfYear] || [aDate yearOfCommonEra] != [currentDate yearOfCommonEra] )
		{
			[calendar setSelectedDate:[[allEntries objectAtIndex:i] valueForKey:@"calDate"]];
			found = YES;
			break;
		}
	}
	
	if ( !found )
		NSBeep();
}

- (IBAction) nextDayWithEntries:(id)sender
{
	NSInteger i;
	BOOL found = NO;
	
	// every entry sorted by date
	NSArray *allEntries = [[[self journal] entries] sortedArrayUsingDescriptors:
			[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"calDate" ascending:YES] autorelease]]];
	
	// the currently selected date
	NSCalendarDate *currentDate = [calendar selectedDate];
	
	// find the first entry according to the current date
	for ( i = 0; i < [allEntries count]; i++ ) 
	{
		NSCalendarDate *aDate = [[allEntries objectAtIndex:i] valueForKey:@"calDate"];
		if ( [aDate dayOfMonth] == [currentDate dayOfMonth] 
				&& [aDate monthOfYear] == [currentDate monthOfYear] && [aDate yearOfCommonEra] == [currentDate yearOfCommonEra] )
			break;
	}
	
	// find the first previous entry that does not have this date
	for ( ++i; i < [allEntries count]; i++ ) 
	{
		NSCalendarDate *aDate = [[allEntries objectAtIndex:i] valueForKey:@"calDate"];
		if ( [aDate dayOfMonth] != [currentDate dayOfMonth] 
				|| [aDate monthOfYear] != [currentDate monthOfYear] || [aDate yearOfCommonEra] != [currentDate yearOfCommonEra] )
		{
			[calendar setSelectedDate:[[allEntries objectAtIndex:i] valueForKey:@"calDate"]];
			found = YES;
			break;
		}
	}
	
	if ( !found )
		NSBeep();

}

- (IBAction) navigateSection:(id)sender
{
	switch ( [sender tag] )
	{
	case 9207: //previous entry
		[self selectPreviousEntry:self];
		break;
	case 9206: //next entry
		[self selectNextEntry:self];
		break;
	case 9209: //previous folder
		[self selectPreviousFolder:sender];
		break;
	case 9208: //next folder
		[self selectNextFolder:sender];
		break;
	case 9211: //select library
		[self selectJournal:sender];
		break;
	}
}

- (IBAction) selectJournal:(id)sender
{
	[sourceListController selectCollection:[[self journal] libraryCollection] byExtendingSelection:NO];
	[sourceList scrollRowToVisible:[sourceList selectedRow]];
}

- (IBAction) selectNextFolder:(id)sender
{
/*	DEPRECATED
    if ( [sourceList selectedRow] == [sourceList numberOfRows] - 1 )
		[sourceList selectRow:0 byExtendingSelection:NO];
	else
		[sourceList selectRow:[sourceList selectedRow]+1 byExtendingSelection:NO];
*/
    NSUInteger desiredIndex = ( [sourceList selectedRow]==[sourceList numberOfRows]-1 ? 0 : [sourceList selectedRow]+1 );
    [sourceList selectRowIndexes:[NSIndexSet indexSetWithIndex:desiredIndex] byExtendingSelection:NO];
	[sourceList scrollRowToVisible:[sourceList selectedRow]];
}

- (IBAction) selectPreviousFolder:(id)sender
{
/*	DEPRECATED
    if ( [sourceList selectedRow] == 0 )
		[sourceList selectRow:[sourceList numberOfRows]-1 byExtendingSelection:NO];
	else
		[sourceList selectRow:[sourceList selectedRow]-1 byExtendingSelection:NO];
*/
	NSUInteger desiredIndex = ([sourceList selectedRow]==0 ? [sourceList numberOfRows]-1 : [sourceList selectedRow]-1 );
    [sourceList selectRowIndexes:[NSIndexSet indexSetWithIndex:desiredIndex] byExtendingSelection:NO];
	[sourceList scrollRowToVisible:[sourceList selectedRow]];
}

- (IBAction) selectPreviousEntry:(id)sender
{
	[entriesController selectPrevious:sender];
	[entriesTable scrollRowToVisible:[entriesTable selectedRow]];
}

- (IBAction) selectNextEntry:(id)sender
{
	[entriesController selectNext:sender];
	[entriesTable scrollRowToVisible:[entriesTable selectedRow]];
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
		_forceNewEntryToMainWindow = YES;
		[self newEntry:self];
		_forceNewEntryToMainWindow = NO;
		if ( !_didCreateNewEntry )
		{
			NSBeep(); return;
		}
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
		_forceNewEntryToMainWindow = YES;
		[self newEntry:self];
		_forceNewEntryToMainWindow = NO;
		if ( !_didCreateNewEntry )
		{
			NSBeep(); return;
		}
	}
	
	// pass the message to the cell controller
	[entryCellController sproutedAudioRecorder:recorder insertRecording:path title:title];
}

- (void) sproutedSnapshot:(SproutedRecorder*)recorder insertRecording:(NSString*)path title:(NSString*)title
{
	#ifdef __DEBUG__
	NSLog(@"%s %@",__PRETTY_FUNCTION__,path);
	#endif
	
	// make sure an entry is available for it
	NSArray *theEntries = [self selectedEntries];
	if ( theEntries == nil || [theEntries count] != 1 )
	{
		_forceNewEntryToMainWindow = YES;
		[self newEntry:self];
		_forceNewEntryToMainWindow = NO;
		if ( !_didCreateNewEntry )
		{
			NSBeep(); return;
		}
	}
	
	// pass the message to the cell controller
	[entryCellController sproutedSnapshot:recorder insertRecording:path title:title];
}

#pragma mark -

- (BOOL) highlightString:(NSString*)aString
{
	if ( [self activeContentView] == [entryCellController contentView] )
		return [entryCellController highlightString:aString];
	
	else if ( [self activeContentView] == [resourceCellController contentView] )
		return [resourceCellController highlightString:aString];
	
	else
		return NO;
}

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
	NSInteger tag = [menuItem tag];
	SEL action = [menuItem action];
	
	
	// a number of these are passed to the entry controller
	if ( action == @selector( editEntryProperty: ) )
		enabled = [entriesController validateMenuItem:menuItem];
	
	else if ( action == @selector( exportEntrySelection: ) )
		enabled = [entriesController validateMenuItem:menuItem];
	
	else if ( action == @selector( printEntrySelection: ) )
		enabled = [entriesController validateMenuItem:menuItem];
	
	else if ( action == @selector( emailEntrySelection: ) )
		enabled = [entriesController validateMenuItem:menuItem];
		
	else if ( action == @selector( blogEntrySelection: ) )
		enabled = [entriesController validateMenuItem:menuItem];
	
	else if ( action == @selector( sendEntryToiWeb: ) )
		enabled = [entriesController validateMenuItem:menuItem];
		
	else if ( action == @selector( sendEntryToiPod: ) )
		enabled = [entriesController validateMenuItem:menuItem];
		
	else if ( action == @selector( editEntryPropertyInTable: ) )
		enabled = [entriesController validateMenuItem:menuItem];
	
	else if ( action == @selector( getEntryInfo: ) )
		enabled = [entriesController validateMenuItem:menuItem];
	
	else if ( action == @selector( openEntryInNewTab: ) )
		enabled = [entriesController validateMenuItem:menuItem];
		
	else if ( action == @selector( openEntryInNewWindow: ) )
		enabled = [entriesController validateMenuItem:menuItem];	
	
	else if ( action == @selector( openEntryInNewFloatingWindow: ) )
		enabled = [entriesController validateMenuItem:menuItem];
		
	else if ( action == @selector( gotoEntryDateInCalendar: ) )
		enabled = [entriesController validateMenuItem:menuItem];
		
	else if ( action == @selector( untrashSelectedEntries: ) )
		enabled = [entriesController validateMenuItem:menuItem];
		
	else if ( action == @selector( deleteSelectedEntries: ) )
		enabled = [entriesController validateMenuItem:menuItem];
	
	else if ( action == @selector( duplicateEntry:) )
		enabled = [entriesController validateMenuItem:menuItem];
	
	else if ( action == @selector(showEntryForSelectedResource:) )
		enabled = [resourceController validateMenuItem:menuItem];
	
	else if ( action == @selector( openResourceInNewWindow: ) )
		enabled = [resourceController validateMenuItem:menuItem];	
	
	else if ( action == @selector( openResourceInNewFloatingWindow: ) )
		enabled = [resourceController validateMenuItem:menuItem];
	
	
	else if ( action == @selector( makeSourceListFirstResponder: ) )
		enabled = YES;
	else if ( action == @selector( makeEntriesTableFirstResponder: ) )
		enabled = YES;
	else if ( action == @selector( makeEntryTextFirstResponder: ) )
		enabled = YES;
	else if ( action == @selector( makeResourceTableFirstResponder: ) )
		enabled = YES;
	
	else if ( action == @selector( toToday: ) )
		enabled = YES;
	else if ( action == @selector( selectJournal: ) )
		enabled = YES;
	else if ( action == @selector( gotoRandomEntry: ) )
		enabled = YES;
	else if ( action == @selector( selectPreviousFolder: ) )
		enabled = YES;
	else if ( action == @selector( selectNextFolder: ) )
		enabled = YES;
	else if ( action == @selector( selectPreviousEntry: ) )
		enabled = YES;
	else if ( action == @selector( selectNextEntry: ) )
		enabled = YES;
	else if ( action == @selector( dayToLeft: ) )
		enabled = YES;
	else if ( action == @selector( dayToRight: ) )
		enabled = YES;
	else if ( action == @selector( previousDayWithEntries: ) )
		enabled = YES;
	else if ( action == @selector( nextDayWithEntries: ) )
		enabled = YES;
	else if ( action == @selector( monthToLeft: ) )
		enabled = YES;
	else if ( action == @selector( monthToRight: ) )
		enabled = YES;

	else if ( action == @selector( performDelete: ) )
	{
		if ( [[[self owner] window] firstResponder] == resourceTable )
			enabled = ( [[self selectedResources] count] != 0 );
		else if ( [[[self owner] window] firstResponder] == entriesTable || [entryCellController textView] )
			enabled = ( [[self selectedEntries] count] != 0 );
		else if ( [[[self owner] window] firstResponder] == sourceList )
			enabled = ( [[self selectedFolders] count] != 0 );
		else
			enabled = NO;
	}

	else if ( action == @selector( removeSelectedEntriesFromFolder: ) )
	{
		BOOL onlyRegularFolders = YES;
		for ( JournlerCollection *aFolder in [self selectedFolders] )
		{
			if ( ![aFolder isRegularFolder] )
			{
				onlyRegularFolders = NO;
				break;
			}
		}
		
		enabled = ( onlyRegularFolders && [[self selectedEntries] count] != 0 );
	}
	
	else if ( action == @selector(sortEntryTableByColumn:) )
	{
		// the sort by option - by default disable
		[menuItem setState:NSOffState];
		
		// enable only if the sort descriptor corresponds
		NSString *descriptorKey;
		if ( [[entriesController sortDescriptors] count] != 0 )
			descriptorKey = [[[entriesController sortDescriptors] objectAtIndex:0] key];
		else
			descriptorKey = nil;
		
		if (tag == 731 && [descriptorKey isEqualToString:@"blogged"] )
			[menuItem setState:NSOnState];
		else if ( tag == 732 && [descriptorKey isEqualToString:@"category"] )
			[menuItem setState:NSOnState];
		else if ( tag == 733 && [descriptorKey isEqualToString:@"calDate"] )
			[menuItem setState:NSOnState];
		else if ( tag == 734 && [descriptorKey isEqualToString:@"marked"] )
			[menuItem setState:NSOnState];
		else if ( tag == 735 && [descriptorKey isEqualToString:@"keywords"] )
			[menuItem setState:NSOnState];
		else if ( tag == 736 && [descriptorKey isEqualToString:@"calDateModified"] )
			[menuItem setState:NSOnState];
		else if ( tag == 739 && [descriptorKey isEqualToString:@"title"] )
			[menuItem setState:NSOnState];
		else if ( tag == 737 && [descriptorKey isEqualToString:@"calDateDue"] )
			[menuItem setState:NSOnState];
		else if ( tag == 738 && [descriptorKey isEqualToString:@"tagID"] )
			[menuItem setState:NSOnState];
		else if ( tag == 740 && [descriptorKey isEqualToString:@"label"] )
			[menuItem setState:NSOnState];
		else if ( tag == 741 && [descriptorKey isEqualToString:@"numberOfResources"] )
			[menuItem setState:NSOnState];
		else if ( tag == 742 && [descriptorKey isEqualToString:@"tags.@count"] )
			[menuItem setState:NSOnState];

	}
	
	else if ( action == @selector(showEntryTableColumn:) )
	{
		if ( tag == 711 )
			[menuItem setState:( [entriesTable tableColumnWithIdentifier:@"blogged"] != nil ? NSOnState : NSOffState )];
		else if ( tag == 712 )
			[menuItem setState:( [entriesTable tableColumnWithIdentifier:@"category"] != nil ? NSOnState : NSOffState )];
		else if ( tag == 713 )
			[menuItem setState:( [entriesTable tableColumnWithIdentifier:@"calDate"] != nil ? NSOnState : NSOffState )];
		else if ( tag == 714 )
			[menuItem setState:( [entriesTable tableColumnWithIdentifier:@"marked"] != nil ? NSOnState : NSOffState )];
		else if ( tag == 715 )
			[menuItem setState:( [entriesTable tableColumnWithIdentifier:@"keywords"] != nil ? NSOnState : NSOffState )];
		else if ( tag == 716 )
			[menuItem setState:( [entriesTable tableColumnWithIdentifier:@"calDateModified"] != nil ? NSOnState : NSOffState )];
		else if ( tag == 719 )
			[menuItem setState:( [entriesTable tableColumnWithIdentifier:@"title"] != nil ? NSOnState : NSOffState )];
		else if ( tag == 720 )
			[menuItem setState:( [entriesTable tableColumnWithIdentifier:@"label"] != nil ? NSOnState : NSOffState )];
		else if ( tag == 717 )
			[menuItem setState:( [entriesTable tableColumnWithIdentifier:@"calDateDue"] != nil ? NSOnState : NSOffState )];
		else if ( tag == 718 )
			[menuItem setState:( [entriesTable tableColumnWithIdentifier:@"tagID"] != nil ? NSOnState : NSOffState )];
		else if ( tag == 721 )
			[menuItem setState:( [entriesTable tableColumnWithIdentifier:@"numberOfResources"] != nil ? NSOnState : NSOffState )];
		else if ( tag == 722 )
			[menuItem setState:( [entriesTable tableColumnWithIdentifier:@"tags"] != nil ? NSOnState : NSOffState )];
	}
	
	else if ( action == @selector(newFolder:) )
	{
		if ( [[self selectedEntries] count] > 1 )
			[menuItem setTitle:NSLocalizedString(@"menuitem new folder with selection",@"")];
		else
			[menuItem setTitle:NSLocalizedString(@"menuitem new folder",@"")];
	}
	
	else if ( action == @selector(toggleHeader:) )
		[menuItem setState:![entryCellController headerHidden]];
		
	else if ( action == @selector(toggleFooter:) )
		[menuItem setState:![entryCellController footerHidden]];
	
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

- (void) setFullScreen:(BOOL)inFullScreen
{
	[entryCellController setFullScreen:inFullScreen];
}

#pragma mark -

- (NSArray*) scriptVisibleEntries
{
	// subclasses should override to return the list of entries currently visible in the tab
	return [entriesController arrangedObjects];
}


@end
