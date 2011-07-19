//
//  JournalWindowController.h
//  Journler
//
//  Created by Philip Dow on 10/24/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//
//	The JournlerWindowController is the base class for all of
//	Journler's main window controllers: journal, entry, full screen
//	It handles tab management and the bookmarks bar 

#import <Cocoa/Cocoa.h>
#import <SproutedInterface/SproutedInterface.h>
#import <SproutedAVI/SproutedAVI.h>

@class JournlerJournal;
@class JournlerEntry;

@class TabController;

@interface JournlerWindowController : NSWindowController {
	
	NSArray *tabControllers;
	NSUInteger selectedTabIndex;
	
	JournlerJournal *journal;
	
@public
	BOOL bookmarksHidden;
	BOOL tabsHidden;
	
	NSView *activeTabView;
	PDTabsView *tabsBar;
	PDFavoritesBar *favoritesBar;
}

- (Class) defaultTabClass;
- (NSArray*) observedPathsForTab:(TabController*)aTab;

- (void) startObservingTab:(TabController*)aTab paths:(NSArray*)keyPaths;
- (void) stopObservingTab:(TabController*)aTab paths:(NSArray*)keyPaths;

// every subclass must implement this initializer and call a super initializer from there
- (id) initWithJournal:(JournlerJournal*)aJournal;

- (JournlerJournal*) journal;
- (void) setJournal:(JournlerJournal*)aJournal;

- (NSUInteger) selectedTabIndex;
- (void) setSelectedTabIndex:(NSUInteger)theSelection;

- (NSArray*) tabControllers;
- (void) setTabControllers:(NSArray*)anArray;

- (BOOL) bookmarksHidden;
- (void) setBookmarksHidden:(BOOL)hidden;

- (BOOL) tabsHidden;
- (void) setTabsHidden:(BOOL)hidden;

- (NSData*) stateData;
- (NSArray*) stateArray;
- (void) restoreStateFromData:(NSData*)data;
- (void) restoreStateFromArray:(NSArray*)anArray;

- (NSString*) windowTitle;
- (TabController*) selectedTab;
- (NSSearchField*) searchOutlet;

- (NSMenuItem*) dockMenuRepresentation;
- (IBAction) performDockRequest:(id)sender;

- (void) selectTabAtIndex:(NSUInteger)index force:(BOOL)force;
- (void) removeTabAtIndex:(NSUInteger)index;
- (void) addTab:(TabController*)aTab atIndex:(NSUInteger)index;
- (void) replaceTabAtIndex:(NSUInteger)index withTab:(TabController*)aTab;

- (void) updateNavInterface;
- (IBAction) navigateBack:(id)sender;
- (IBAction) navigateForward:(id)sender;
- (IBAction) navigateBackOrForward:(id)sender;

- (IBAction) gotoRandomEntry:(id)sender;

- (IBAction) newTab:(id)sender;
- (IBAction) closeTab:(id)sender;

- (IBAction) selectNextTab:(id)sender;
- (IBAction) selectPreviousTab:(id)sender;

- (IBAction) toggleTabBar:(id)sender;
- (IBAction) toggleBookmarksBar:(id)sender;

- (IBAction) toggleHeader:(id)sender;
- (IBAction) toggleFooter:(id)sender;
- (IBAction) toggleResources:(id)sender;

- (IBAction) selectFavorite:(id)sender;
- (IBAction) toggleFullScreen:(id)sender;

- (IBAction) duplicateEntry:(id)sender;

- (IBAction) newWebBrower:(id)sender;
- (IBAction) newWindowWithSelection:(id)sender;
- (IBAction) newFloatingWindowWithSelection:(id)sender;

- (void) performAutosave:(NSNotification*)aNotification;
- (BOOL) performCustomKeyEquivalent:(NSEvent *)theEvent;
- (void) servicesMenuAppendSelection:(NSPasteboard*)pboard desiredType:(NSString*)type;

- (IBAction) exportSelection:(id)sender;
- (IBAction) insertContact:(id)sender;

- (void) toolbarDidShow:(PDToolbar*)aToolbar;
- (void) toolbarDidHide:(PDToolbar*)aToolbar;

//
// standard actions a subclass may want to implement

- (JournlerEntry*) entryForRecording:(id)sender;

- (IBAction) emailEntrySelection:(id)sender;
- (IBAction) blogEntrySelection:(id)sender;

- (IBAction) showEntryForSelectedResource:(id)sender;

/*

- (IBAction) newEntry:(id)sender;
- (IBAction) newFolder:(id)sender;
- (IBAction) newSmartFolder:(id)sender;

- (IBAction) importFiles:(id)sender;

- (IBAction) editEntryProperty:(id)sender;
- (IBAction) editEntryLabel:(id)sender;

- (IBAction) gotoRandomEntry:(id)sender;

- (IBAction) toggleUsesAlternatingRows:(id)sender;
- (IBAction) toggleDrawsLabelBackground:(id)sender;

- (IBAction) printDocument:(id)sender;
- (IBAction) emailDocument:(id)sender;
- (IBAction) blogDocument:(id)sender;
- (IBAction) sendEntryToiWeb:(id)sender;

- (IBAction) getEntryInfo:(id)sender;

*/

@end


@interface JournlerWindowController (JournlerScripting)

- (TabController*) scriptSelectedTab;

- (NSInteger) indexOfObjectInJSTabs:(TabController*)aTab;
- (NSUInteger) countOfJSTabs;
- (TabController*) objectInJSTabsAtIndex:(NSUInteger)i;

- (void) insertObject:(TabController*)aTab inJSTabsAtIndex:(NSUInteger)index;
- (void) insertInJSTabs:(TabController*)aTab;
- (void) JSAddNewTab:(TabController*)aTab atIndex:(NSUInteger)index;

- (void) removeObjectFromJSTabsAtIndex:(NSUInteger)index; 
- (void) removeFromJSTabsAtIndex:(NSUInteger)index;
- (void) JSDeleteTab:(TabController*)aTab;

@end

@interface JournlerWindowController (FindPanelSupport)

- (void) performCustomFindPanelAction:(id)sender;
- (void) performCustomTextSizeAction:(id)sender;

- (BOOL) handlesFindCommand;
- (void) performFindPanelAction:(id)sender;

- (BOOL) handlesTextSizeCommand;
- (void) modifyFont:(id)sender;

@end