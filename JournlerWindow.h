//
//  JournlerWindow.h
//  Journler
//
//  Created by Philip Dow on 4/2/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SproutedInterface/SproutedInterface.h>

@class TabController;

@interface JournlerWindow : PolishedWindow {

}

@end


@interface JournlerWindow (JournlerScripting)

- (TabController*) scriptSelectedTab;

- (NSInteger) indexOfObjectInJSTabs:(TabController*)aTab;
- (NSUInteger) countOfJSTabs;
- (TabController*) objectInJSTabsAtIndex:(NSUInteger)i;

- (void) insertObject:(TabController*)aTab inJSTabsAtIndex:(NSUInteger)index;
- (void) insertInJSTabs:(TabController*)aTab;

- (void) removeObjectFromJSTabsAtIndex:(NSUInteger)index; 
- (void) removeFromJSTabsAtIndex:(NSUInteger)index;

@end