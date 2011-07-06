//
//  NSBezierPath_AMShading.h
//  ShadingTest
//
//  Created by Andreas on 2005-06-01.
//  Copyright 2005 Andreas Mayer. All rights reserved.
//
//	based on http://www.cocoadev.com/index.pl?GradientFill

//	2005-12-05  Andreas Mayer
//	- for some reason the method for drawing a vertical shading was called customHorizontalFillWith...
//	  fixed this. It's -customVerticalFillWithCallbacks:firstColor:secondColor: now.


#import <Cocoa/Cocoa.h>


@interface NSBezierPath (AMShading)

- (void)linearGradientFillWithStartColor:(NSColor *)startColor endColor:(NSColor *)endColor;
- (void)bilinearGradientFillWithOuterColor:(NSColor *)outerColor innerColor:(NSColor *)innerColor;
- (void)sweptGradientFillWithStartColor:(NSColor *)startColor endColor:(NSColor *)endColor;

- (void)customVerticalFillWithCallbacks:(CGFunctionCallbacks)functionCallbacks firstColor:(NSColor *)firstColor secondColor:(NSColor *)secondColor;
- (void)customSweptFillWithCallbacks:(CGFunctionCallbacks)functionCallbacks firstColor:(NSColor *)firstColor secondColor:(NSColor *)secondColor;

@end
