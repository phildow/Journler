//
//  EntryTabController.h
//  Journler
//
//  Created by Philip Dow on 11/9/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <iMediaBrowser/iMedia.h>
#import <SproutedInterface/SproutedInterface.h>
#import <SproutedAVI/SproutedAVI.h>

#import "TabController.h"

@class JournlerEntry;
@class ResourceController;

@class EntryCellController;
@class ResourceCellController;

@class ResourceTableView;

@interface EntryTabController : TabController {
	
	IBOutlet NSMenu *referenceMenu;
	IBOutlet NSMenu *resourceWorktoolMenu;
	IBOutlet NSMenu *newResourceMenu;
	
	IBOutlet NSView *contentPlaceholder;
	IBOutlet RBSplitView *contentResourceSplit;
	IBOutlet ResourceController *resourceController;
	IBOutlet NSView *resourcesDragView;
	IBOutlet ResourceTableView *resourceTable;
	
	IBOutlet NSMenuItem *resourceInNewTabItem;
	IBOutlet NSMenuItem *resourceInNewTabItemB;
	
	IBOutlet NSButton *resourceWorktool;
	IBOutlet NSButton *newResourceButton;
	IBOutlet NSButton *toggleResourcesButton;
	
	NSPopUpButtonCell *resourceWorktoolPopCell;
	NSPopUpButtonCell *newResourcePopCell;
	
	IBOutlet NSButton *resourceToggle;
	
	JournlerEntry *selectedEntry;
	
	EntryCellController *entryCellController;
	ResourceCellController *resourceCellController;
	
	NSView *activeContentView;
}

- (NSView*) activeContentView;
- (void) setActiveContentView:(NSView*)aView;

- (JournlerEntry*)selectedEntry;
- (void) setSelectedEntry:(JournlerEntry*)anEntry;

- (BOOL) selectResources:(NSArray*)anArray;

- (void) setFullScreen:(BOOL)isFullScreen;
- (void) servicesMenuAppendSelection:(NSPasteboard*)pboard desiredType:(NSString*)type;

- (IBAction) toggleResources:(id)sender;
- (IBAction) showNewResourceSheet:(id)sender;
- (IBAction) insertNewResource:(id)sender;
- (IBAction) addFileFromFinder:(id)sender;
- (IBAction) showResourceWorktoolContextual:(id)sender;

- (void) _hideResourcesSubview:(id)sender;
- (void) _updateResourceToggleImage;

#pragma mark -

- (IBAction) showEntryForSelectedResource:(id)sender;
- (BOOL) _showEntryForSelectedResources:(NSArray*)anArray;

//- (IBAction) revealResource:(id)sender;
//- (IBAction) launchResource:(id)sender;
//- (IBAction) openResourceInNewTab:(id)sender;
//- (IBAction) openResourceInNewWindow:(id)sender;

@end