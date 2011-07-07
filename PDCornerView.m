//
//  PDCornerView.m
//  Journler XD Lite
//
//  Created by Philip Dow on 9/14/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import "PDCornerView.h"

#import <SproutedUtilities/SproutedUtilities.h>

@implementation PDCornerView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
	
	NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
	
	NSColor *gradientEnd;
	NSColor *gradientStart;
	
	gradientStart = [NSColor 
			colorWithCalibratedRed:254.0/255.0 green:254.0/255.0 blue:254.0/255.0 alpha:1.0];
	gradientEnd = [NSColor 
			colorWithCalibratedRed:235.0/255.0 green:235.0/255.0 blue:235.0/255.0 alpha:1.0];
	
	// draw the background
	NSRect top, bottom;
	NSDivideRect(rect, &top, &bottom, rect.size.height/2, NSMinYEdge);
	top.size.height++;
	
	[[NSBezierPath bezierPathWithRect:top] linearGradientFillWithStartColor:gradientStart endColor:gradientEnd];
	[[NSBezierPath bezierPathWithRect:bottom] linearGradientFillWithStartColor:gradientEnd endColor:gradientStart];
			
	[currentContext saveGraphicsState];
	[currentContext setShouldAntialias:NO];
	
	// line the bottom
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(	rect.origin.x, 
									rect.origin.y + rect.size.height)];
	[path lineToPoint:NSMakePoint(	rect.origin.x + rect.size.width, 
									rect.origin.y + rect.size.height)];
	
	[path moveToPoint:NSMakePoint(	rect.origin.x, 
									rect.origin.y)];
	[path lineToPoint:NSMakePoint(	rect.origin.x, 
									rect.origin.y + rect.size.height)];
	
	[[NSColor lightGrayColor] set];
	
	[path setLineWidth:1];
	[path stroke];

	[currentContext restoreGraphicsState];
}

- (BOOL) isFlipped { 
	return YES; 
}

@end
