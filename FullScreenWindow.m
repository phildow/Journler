//
//  FullScreenWindow.m
//  Journler
//
//  Created by Philip Dow on 6/30/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import "FullScreenWindow.h"

//
//  TransparentWindow.m
//  RoundedFloatingPanel
//
//  Created by Matt Gemmell on Thu Jan 08 2004.
//  <http://iratescotsman.com/>
//

#define kEdgeInset 40
#define kWinHeight 186

#import "FullScreenWindow.h"

@implementation FullScreenWindow

- (id)init 
{
	return [self initWithContentRect:NSMakeRect(0,0,186,186) styleMask:NSBorderlessWindowMask 
			backing:NSBackingStoreBuffered defer:NO];
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag 
{
    if (self = [super initWithContentRect:contentRect  styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO]) 
	{
        [self setHasShadow:NO];
		[self setReleasedWhenClosed:YES];
		
		_closesOnEvent = NO;
		_closesOnEscape = YES;
		
        return self;
    }
	
    return nil;
}

- (BOOL) closesOnEvent 
{ 
	return _closesOnEvent; 
}

- (void) setClosesOnEvent:(BOOL)closes 
{
	_closesOnEvent = closes;
}

- (BOOL) closesOnEscape
{
	return _closesOnEscape;
}

- (void) setClosesOnEscape:(BOOL)closes
{
	_closesOnEscape = closes;
}

#pragma mark -

- (void) fillScreenHorizontallyAndCenter 
{
	NSScreen *screen = [NSScreen mainScreen];
	NSRect visible_frame = [screen visibleFrame];
	
	NSRect win_frame = NSMakeRect( kEdgeInset, 20, visible_frame.size.width - kEdgeInset*2, kWinHeight );
	[self setFrame:win_frame display:NO];
	[self center];
}

- (void) completelyFillScreen 
{
	[self setFrame:[[NSScreen mainScreen] visibleFrame] display:YES];
}

#pragma mark -

- (BOOL) canBecomeKeyWindow
{
    return YES;
}

- (BOOL) canBecomeMainWindow
{
	return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{    
    if ( _closesOnEvent ) 
		[self close];
	else
		[super mouseDown:theEvent];
}

- (void)keyDown:(NSEvent *)theEvent 
{
	if ( _closesOnEvent || ( _closesOnEscape && [theEvent keyCode] == 53 ) ) 
		[self close];
	else
		[super keyDown:theEvent];
}


- (void)sendEvent:(NSEvent *)theEvent 
{	
	if ( _closesOnEscape && [theEvent type] == NSKeyDown && [theEvent keyCode] == 53 )
		[self close];
	else
		[super sendEvent:theEvent];
}

#pragma mark -

- (void)resignKeyWindow 
{
	if ( _closesOnEvent ) 
		[self close];
	else
		[super resignKeyWindow];
}

- (void)resignMainWindow 
{
	if ( _closesOnEvent ) 
		[self close];
	else
		[super resignMainWindow];
}

@end
