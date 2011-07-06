//
//  EntryFilterController.h
//  Journler
//
//  Created by Philip Dow on 5/22/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JournlerConditionController;
@class CollectionManagerView;

@interface EntryFilterController : NSObject {
	
	id delegate;
	
	NSMutableArray	*_conditions;
	CollectionManagerView *_filters;
	NSArray *tagCompletions;
}

- (id) initWithDelegate:(id)anObject;
- (NSView*) contentView;

- (NSArray*) tagCompletions;
- (void) setTagCompletions:(NSArray*)anArray;

- (id) delegate;
- (void) setDelegate:(id)anObject;

- (void) updateConditionsView;
- (void) addCondition:(id)sender;
- (void) removeCondition:(id)sender;

- (NSArray*) conditions;
- (void) updateKeyViewLoop;
- (void) appropriateFirstResponder:(NSWindow*)aWindow;

@end


#pragma mark -


@interface NSObject (FilterDelegate)

- (void) entryFilterController:(EntryFilterController*)filterController frameDidChange:(NSRect)filterFrame;
- (void) entryFilterController:(EntryFilterController*)filterController predicateDidChange:(NSPredicate*)filterPredicate;

@end