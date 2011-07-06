//
//  JournalTabController.h
//  Journler
//
//  Created by Phil Dow on 10/24/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <iMediaBrowser/iMedia.h>
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
