//
//  TransparentWindow.h
//  RoundedFloatingPanel
//
//  Created by Matt Gemmell on Thu Jan 08 2004.
//  <http://iratescotsman.com/>
//


#import <Cocoa/Cocoa.h>

@interface TransparentWindow : NSWindow
{
	BOOL _closesOnEvent;
    NSPoint initialLocation;
}

- (BOOL) closesOnEvent;
- (void) setClosesOnEvent:(BOOL)closes;

- (void) completelyFillScreen;
- (void) fillScreenHorizontallyAndCenter;

@end
