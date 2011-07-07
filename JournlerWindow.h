//
//  JournlerWindow.h
//  Journler
//
//  Created by Philip Dow on 4/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SproutedInterface/SproutedInterface.h>

@class TabController;

@interface JournlerWindow : PolishedWindow {

}

@end


@interface JournlerWindow (JournlerScripting)

- (TabController*) scriptSelectedTab;

- (int) indexOfObjectInJSTabs:(TabController*)aTab;
- (unsigned int) countOfJSTabs;
- (TabController*) objectInJSTabsAtIndex:(unsigned int)i;

- (void) insertObject:(TabController*)aTab inJSTabsAtIndex:(unsigned int)index;
- (void) insertInJSTabs:(TabController*)aTab;

- (void) removeObjectFromJSTabsAtIndex:(unsigned int)index; 
- (void) removeFromJSTabsAtIndex:(unsigned int)index;

@end