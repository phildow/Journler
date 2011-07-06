//
//  PDDelegatedToolbar.h
//  Journler
//
//  Created by Phil Dow on 12/1/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define PDToolbarDidShowNotification @"PDToolbarDidShowNotification"
#define PDToolbarDidHideNotification @"PDToolbarDidHideNotification"

@interface PDToolbar : NSToolbar {

}

- (NSToolbarItem*) itemWithTag:(int)aTag;
- (NSToolbarItem*) itemWithIdentifier:(NSString*)identifier;

@end

@interface NSObject (PDToolbarDelegate)

- (void) toolbarDidChangeSizeMode:(PDToolbar*)aToolbar;
- (void) toolbarDidChangeDisplayMode:(PDToolbar*)aToolbar;

- (void) toolbarDidShow:(PDToolbar*)aToolbar;
- (void) toolbarDidHide:(PDToolbar*)aToolbar;

@end