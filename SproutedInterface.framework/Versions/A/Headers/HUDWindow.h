//
//  HUDWindow.h
//  HUDWindow
//
//  Created by Matt Gemmell on 12/02/2006.
//  Copyright 2006 Magic Aubergine. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SproutedUtilities/SproutedUtilities.h>

@interface HUDWindow : NSPanel {
    BOOL forceDisplay;
	BOOL closesOnEvent;
	BOOL closesOnEscape;
}

- (BOOL) closesOnEvent;
- (void) setClosesOnEvent:(BOOL)closes;

- (BOOL) closesOnEscape;
- (void) setClosesOnEscape:(BOOL)closes;

- (NSColor *)sizedHUDBackground;
- (void)addCloseWidget;

@end

@interface NSObject (HUDWindowDelegate)

- (IBAction) runClose:(id)sender;

@end
