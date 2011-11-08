//
//  JournalTabController.h
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

#import <Cocoa/Cocoa.h>
//#import <iMediaBrowser/iMedia.h>
#import <SproutedInterface/SproutedInterface.h>
#import <SproutedAVI/SproutedAVI.h>

#import "TabController.h"

@class JournlerObject;

@class Calendar;
@class CalendarController;
@class FoldersController, EntriesController;
@class ResourceController, DatesController;

@class PDBorderedFill;

@class EntryCellController;
@class ResourceCellController;
@class EntryFilterController;

@class EntriesTableView;
@class ResourceTableView;
@class CollectionsSourceList;

@interface JournalTabController : TabController {
	
	Calendar *calendar;
	CalendarController *calController;
	IBOutlet PDBorderedFill *calContainer;
	
	IBOutlet EntriesTableView *entriesTable;
	IBOutlet CollectionsSourceList *sourceList;
	IBOutlet ResourceTableView *resourceTable;
	
	IBOutlet FoldersController *sourceListController;
	IBOutlet DatesController *datesController;
	IBOutlet EntriesController *entriesController;
	IBOutlet ResourceController *resourceController;
	
	IBOutlet NSView *contentPlaceholder;
	
	IBOutlet RBSplitView *contentResourceSplit;
	IBOutlet RBSplitView *browserContentSplit;
	IBOutlet RBSplitView *foldersEntriesSplit;
	
	IBOutlet NSView *foldersDragView;
	IBOutlet NSView *resourcesDragView;
	
	IBOutlet NSButton *folderWorktool;
	IBOutlet NSButton *resourceWorktool;
	IBOutlet NSButton *newResourceButton;
	
	IBOutlet NSButton *resourceToggle;
	
	IBOutlet NSMenu *entryMenu;
	IBOutlet NSMenu *columnsMenu;
	
	IBOutlet NSMenu *referenceMenu;
	IBOutlet NSMenu *resourceWorktoolMenu;
	
	IBOutlet NSMenu *foldersMenu;
	IBOutlet NSMenu *foldersWorktoolMenu;
	
	IBOutlet NSMenu *newResourceMenu;
	
	IBOutlet NSMenu *labelMenu;
	IBOutlet NSMenu *resourceLabelMenu;
	IBOutlet NSMenu *resourceWorktoolLabelMenu;
	IBOutlet NSMenu *folderLableMenu;
	IBOutlet NSMenu *folderWorktoolLabelMenu;
	
	IBOutlet NSView *aCornerView;
	IBOutlet NSMenuItem *emptyTrashItem;
	
	IBOutlet NSMenuItem *entryInNewTabItem;
	IBOutlet NSMenuItem *resourceInNewTabItem;
	IBOutlet NSMenuItem *resourceInNewTabItemB;
	
	EntryCellController *entryCellController;
	ResourceCellController *resourceCellController;
	
	NSPopUpButtonCell *worktoolPopCell;
	NSPopUpButtonCell *resourceWorktoolPopCell;
	NSPopUpButtonCell *newResourcePopCell;
	
	NSView *activeContentView;
	
	EntryFilterController *entryFilter;
	NSArray *preSearchDescriptors;
	NSArray *preSearchTableState;
	
	BOOL _didCreateNewEntry;
	BOOL _forceNewEntryToMainWindow;
	
	BOOL usesSmallCalendar;
	
	BOOL keepSearching;
	NSString *searchString;
}

- (NSView*) activeContentView;
- (void) setActiveContentView:(NSView*)aView;

- (NSString*) searchString;
- (void) setSearchString:(NSString*)aString;

#pragma mark -

- (BOOL) usesSmallCalendar;
- (void) setUsesSmallCalendar:(BOOL)smallCalendar;

- (IBAction) toggleResources:(id)sender;
- (IBAction) showFolderWorktoolContextual:(id)sender;
- (IBAction) showResourceWorktoolContextual:(id)sender;

#pragma mark -

- (IBAction) performToolbarSearch:(id)sender;
- (IBAction) filterEntries:(id)sender;

- (IBAction) newEntry:(id)sender;
- (IBAction) newFolder:(id)sender;
- (IBAction) newSmartFolder:(id)sender;

- (IBAction) performDelete:(id)sender;
- (IBAction) deleteSelectedFolder:(id)sender;
- (IBAction) deleteSelectedEntries:(id)sender;
- (IBAction) deleteSelectedResources:(id)sender;

- (IBAction) trashSelectedEntries:(id)sender;
- (IBAction) untrashSelectedEntries:(id)sender;
- (IBAction) removeSelectedEntriesFromFolder:(id)sender;
- (IBAction) removeSelectedEntriesFromJournal:(id)sender;

- (IBAction) renameFolder:(id)sender;
- (IBAction) editSmartFolder:(id)sender;
- (IBAction) emptyTrash:(id)sender;
- (IBAction) editFolderProperty:(id)sender;
- (IBAction) selectFolderFromMenu:(id)sender;

- (IBAction) showEntryForSelectedResource:(id)sender;
- (BOOL) _showEntryForSelectedResources:(NSArray*)anArray;

- (IBAction) renameResource:(id)sender;

- (IBAction) gotoRandomEntry:(id)sender;
- (IBAction) gotoEntryDateInCalendar:(id)sender;
- (IBAction) editEntryPropertyInTable:(id)sender;


- (IBAction) printEntrySelection:(id)sender;

- (IBAction) printDocument:(id)sender;

- (IBAction) showNewResourceSheet:(id)sender;
- (IBAction) insertNewResource:(id)sender;
- (IBAction) addFileFromFinder:(id)sender;

- (IBAction) focusOnSection:(id)sender;
- (IBAction) makeSourceListFirstResponder:(id)sender;
- (IBAction) makeEntriesTableFirstResponder:(id)sender;
- (IBAction) makeEntryTextFirstResponder:(id)sender;
- (IBAction) makeResourceTableFirstResponder:(id)sender;

- (IBAction) previousDayWithEntries:(id)sender;
- (IBAction) nextDayWithEntries:(id)sender;

- (IBAction) navigateSection:(id)sender;
- (IBAction) selectJournal:(id)sender;
- (IBAction) selectNextFolder:(id)sender;
- (IBAction) selectPreviousFolder:(id)sender;

- (IBAction) selectPreviousEntry:(id)sender;
- (IBAction) selectNextEntry:(id)sender;

- (IBAction) toToday:(id)sender;
- (IBAction) dayToRight:(id)sender;
- (IBAction) dayToLeft:(id)sender;
- (IBAction) monthToRight:(id)sender;
- (IBAction) monthToLeft:(id)sender;

- (IBAction) showEntryTableColumn:(id)sender;
- (IBAction) sortEntryTableByColumn:(id)sender;

- (IBAction) saveSearchResults:(id)sender;
- (IBAction) saveFilterResults:(id)sender;

- (IBAction) clearSearchAndFilter:(id)sender;

- (IBAction) duplicateEntry:(id)sender;

- (void) showFirstRunConfiguration;
- (void) showFirstRunTabConfiguration;
- (void) servicesMenuAppendSelection:(NSPasteboard*)pboard desiredType:(NSString*)type;

- (void) showLexiconSelection:(JournlerObject*)anObject forTerm:(NSString*)aTerm;

- (void) _hideResourcesSubview:(id)sender;
- (void) _updateResourceToggleImage;

- (void) _journalWillChangeEntrysTrashStatus:(NSNotification*)aNotification;
- (void) _journalDidChangeEntrysTrashStatus:(NSNotification*)aNotification;

@end
