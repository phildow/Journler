//
//  EntriesController.h
//  Journler
//
//  Created by Philip Dow on 10/24/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JournlerEntry;
@class EntriesTableView;

@interface EntriesController : NSArrayController {
	
	id delegate;
	NSSet *intersectSet;
	IBOutlet EntriesTableView *entriesTable;
}

- (id) delegate;
- (void) setDelegate:(id)anObject;

- (NSSet*) intersectSet;
- (void) setIntersectSet:(NSSet*)newSet;

- (NSArray*) stateArray;
- (void) setStateArray:(NSArray*)anArray;

- (IBAction) deleteSelectedEntries:(id)sender;

- (IBAction) openEntryInNewTab:(id)sender;
- (IBAction) openEntryInNewWindow:(id)sender;
- (IBAction) openEntryInNewFloatingWindow:(id)sender;

- (void) openAnEntryInNewWindow:(JournlerEntry*)anEntry;
- (void) openAnEntryInNewTab:(JournlerEntry*)anEntry;

//- (void) resetAllRowHeights;

@end

@interface NSObject (EntriesControllerDelegate)

- (void) entryController:(EntriesController*)anEntriesController willChangeSelection:(NSArray*)currentSelection;
- (BOOL) entryController:(EntriesController*)anEntriesController tableDidSelectRowAlreadySelected:(NSInteger)aRow event:(NSEvent*)mouseEvent;

- (BOOL) entryController:(EntriesController*)aController shouldDeleteEntries:(NSArray*)theEntries;
- (BOOL) entryController:(EntriesController*)aController didDeleteEntries:(NSArray*)theEntries; 

@end