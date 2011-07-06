//
//  JournlerGradientView.h
//  Journler XD Pro
//
//  Created by Phil Dow on 10/20/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreImage.h> // needed for Core Image

@interface JournlerGradientView : NSView {
	
	NSColor *gradientStartColor;
    NSColor *gradientEndColor;
    NSColor *backgroundColor;
	
	int	borders[4];
	BOOL bordered;
	
	BOOL usesBezierPath;
	BOOL drawsGradient;
	
	NSColor		*fillColor;
	NSColor		*borderColor;
	
	NSControlTint controlTint;
}

+ (void) drawGradientInView:(NSView*)aView rect:(NSRect)aRect highlight:(BOOL)highlight shadow:(float)shadowLevel;

- (int*) borders;
- (void) setBorders:(int*)sides;

- (BOOL) bordered;
- (void) setBordered:(BOOL)flag;

- (BOOL) drawsGradient;
- (void) setDrawsGradient:(BOOL)draws;

- (BOOL) usesBezierPath;
- (void) setUsesBezierPath:(BOOL)bezier;

- (NSColor*) fillColor;
- (void) setFillColor:(NSColor*)aColor;

- (NSColor*) borderColor;
- (void) setBorderColor:(NSColor*)aColor;

- (NSControlTint) controlTint;
- (void) setControlTint:(NSControlTint)aTint;

- (NSColor *)gradientStartColor;
- (void)setGradientStartColor:(NSColor *)newGradientStartColor;
- (NSColor *)gradientEndColor;
- (void)setGradientEndColor:(NSColor *)newGradientEndColor;
- (NSColor *)backgroundColor;
- (void)setBackgroundColor:(NSColor *)newBackgroundColor;

- (void) resetGradient;

@end
