//
//  JournalWindowController.h
//  Journler
//
//  Created by Phil Dow on 10/24/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//
//	The JournalWindowController manages the presentation of the main journal window

#import <Cocoa/Cocoa.h>
#import <SproutedAVI/SproutedAVI.h>

#import "JournlerWindowController.h"

@class PDPopUpButtonToolbarItem;
@class BrowseTableFieldEditor;

@interface JournalWindowController : JournlerWindowController {
	
	IBOutlet NSView *initalTabPlaceholder;
	
	IBOutlet NSView *navOutlet;
	IBOutlet NSButton *navBack;
	IBOutlet NSButton *navForward;
	IBOutlet NSSegmentedControl *navBackForward;
	
	IBOutlet NSSearchField *searchOutlet;
	PDPopUpButtonToolbarItem *dateTimeButton;
	PDPopUpButtonToolbarItem *highlightButton;
	
	IBOutlet BrowseTableFieldEditor	*browseTableFieldEditor;
}

+ (id) sharedController;

//- (IBAction) toggleResources:(id)sender;

- (IBAction) clearSearch:(id)sender;
- (IBAction) changeSearchOption:(id)sender;
- (IBAction) setAutoenablePrefixSearching:(id)sender;
- (IBAction) setSearchedContent:(id)sender;
- (IBAction) setSearchSystem:(id)sender;
- (IBAction) focusSearchField:(id)sender;
- (IBAction) performToolbarSearch:(id)sender;
- (IBAction) filterEntries:(id)sender;

- (IBAction) showSearchHelp:(id)sender;

- (IBAction) saveSearchResults:(id)sender;
- (IBAction) saveFilterResults:(id)sender;

- (IBAction) showEntryTableColumn:(id)sender;
- (IBAction) sortEntryTableByColumn:(id)sender;

- (void) showFirstRunConfiguration;

@end

@interface JournalWindowController (Toolbar)

- (void) setupToolbar;
- (void) setupDateTimePopUpButton;
- (void) setupHighlightPopUpButton;

@end
