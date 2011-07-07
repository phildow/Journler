//
//  JournlerWindow.m
//  Journler
//
//  Created by Philip Dow on 4/2/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import "JournlerWindow.h"
#import "TabController.h"
#import "JournlerApplicationDelegate.h"
#import "EntriesTableView.h"

@implementation JournlerWindow

- (NSText *)fieldEditor:(BOOL)createFlag forObject:(id)anObject 
{
	id editor = [super fieldEditor:createFlag forObject:anObject];
	if ( [anObject isKindOfClass:[EntriesTableView class]] )
		[editor setTextColor:[NSColor blackColor]];
	return editor;
}

@end

@implementation JournlerWindow (JournlerScripting)

- (TabController*) scriptSelectedTab
{
	return [[self delegate] scriptSelectedTab];
}

#pragma mark -

- (int) indexOfObjectInJSTabs:(TabController*)aTab
{
	return [[self delegate] indexOfObjectInJSTabs:aTab];
}

- (unsigned int) countOfJSTabs
{
	return [[self delegate] countOfJSTabs];
}

- (TabController*) objectInJSTabsAtIndex:(unsigned int)i
{
	return [[self delegate] objectInJSTabsAtIndex:i];
}

#pragma mark -

- (void) insertObject:(TabController*)aTab inJSTabsAtIndex:(unsigned int)index
{
	[[self delegate] insertObject:aTab inJSTabsAtIndex:index];
}

- (void) insertInJSTabs:(TabController*)aTab
{
	[[self delegate] insertInJSTabs:aTab];
}


#pragma mark -

- (void) removeObjectFromJSTabsAtIndex:(unsigned int)index
{
	[[self delegate] removeObjectFromJSTabsAtIndex:index];
}

- (void) removeFromJSTabsAtIndex:(unsigned int)index
{
	[[self delegate] removeFromJSTabsAtIndex:index];
}

@end

