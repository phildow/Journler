//
//  PDTableHeaderCell.m
//  Journler XD Lite
//
//  Created by Philip Dow on 9/14/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import "PDTableHeaderCell.h"

#import <SproutedUtilities/SproutedUtilities.h>
//#import "NSBezierPath_AMShading.h"
//#import "NSBezierPath_AMAdditons.h"

// #warning fade elements when window is not in focus

@implementation PDTableHeaderCell


- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	// call super
	[super drawInteriorWithFrame:cellFrame inView:controlView];
	
	NSInteger offset = ( [self image] == nil ? 0 : 1 );
	
	// but then cover over one line from the top
	NSGraphicsContext *context = [NSGraphicsContext currentContext];
	//NSColor *color = [[NSColor colorForControlTint:[NSColor currentControlTint]] highlightWithLevel:0.2];
	//NSColor *color = [[NSColor colorWithCalibratedWhite:1.0 alpha:0.8] 
	//		blendedColorWithFraction:0.3 ofColor:[NSColor colorForControlTint:[NSColor currentControlTint]]];
	NSColor *color = [NSColor darkGrayColor];
	NSBezierPath *path = [NSBezierPath bezierPathWithLineFrom:NSMakePoint( cellFrame.origin.x, cellFrame.origin.y + offset ) 
			to:NSMakePoint( cellFrame.origin.x + cellFrame.size.width, cellFrame.origin.y + offset ) lineWidth:1.0];
	
	[path setLineWidth:1.0];
	[context saveGraphicsState];
	[context setShouldAntialias:NO];
	
	[color set];
	[path stroke];
	
	[context restoreGraphicsState];

}


- (void)highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	// call super
	[super highlight:flag withFrame:cellFrame inView:controlView];
	
	// but then cover over one line from the top
	NSGraphicsContext *context = [NSGraphicsContext currentContext];
	//NSColor *color = [NSColor colorForControlTint:[NSColor currentControlTint]];
	//NSColor *color = [NSColor whiteColor];
	NSColor *color = [NSColor darkGrayColor];
	NSBezierPath *path = [NSBezierPath bezierPathWithLineFrom:NSMakePoint( cellFrame.origin.x, cellFrame.origin.y+1 ) 
			to:NSMakePoint( cellFrame.origin.x + cellFrame.size.width, cellFrame.origin.y+1 ) lineWidth:1.0];
	
	[context saveGraphicsState];
	[context setShouldAntialias:NO];
	
	[color set];
	[path stroke];
	
	[context restoreGraphicsState];
}


@end
