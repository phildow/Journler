//
//  FullScreenWindow.h
//  Journler
//
//  Created by Philip Dow on 6/30/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "JournlerWindow.h"

@interface FullScreenWindow : JournlerWindow {
	
	BOOL _closesOnEvent;
	BOOL _closesOnEscape;
    NSPoint initialLocation;
}

- (BOOL) closesOnEvent;
- (void) setClosesOnEvent:(BOOL)closes;

- (BOOL) closesOnEscape;
- (void) setClosesOnEscape:(BOOL)closes;

- (void) completelyFillScreen;
- (void) fillScreenHorizontallyAndCenter;

@end
