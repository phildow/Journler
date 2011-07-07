//
//  CalendarButtonCell.m
//  Journler XD Lite
//
//  Created by Philip Dow on 9/20/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import "CalendarButtonCell.h"

#import <SproutedUtilities/SproutedUtilities.h>
/*
#import "NSBezierPath_AMAdditons.h"
#import "NSBezierPath_AMShading.h"
*/

@implementation CalendarButtonCell

- (id) init {
	self = [self initTextCell:[NSString string]];
	return self;
}

- (id) initTextCell:(NSString*)aString {
	if ( self = [super initTextCell:aString] ) {
		
		
		[self setButtonType:NSMomentaryPushButton];
		
		command = kCalendarCommandToToday;
	}
	return self;
}

#pragma mark -

- (CalbendarButtonCommand) command {
	return command;
}

- (void) setCommand:(CalbendarButtonCommand)aCommand {
	command = aCommand;
}

#pragma mark -

- (void)highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	[self drawWithFrame:cellFrame inView:controlView];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	
	//[controlView lockFocus];
	
	//
	// draws the gradient and boundaries
	
	NSColor *gradientStart;
	NSColor *gradientEnd;
	
	if ( [self state] == NSOffState && ![self isHighlighted] ) {
		
		gradientStart = [NSColor 
				colorWithCalibratedRed:254.0/255.0 green:254.0/255.0 blue:254.0/255.0 alpha:1.0];
		gradientEnd = [NSColor 
				colorWithCalibratedRed:217.0/255.0 green:217.0/255.0 blue:217.0/255.0 alpha:1.0];
	}
	else {
		
		gradientStart = [NSColor 
				colorWithCalibratedRed:205.0/255.0 green:205.0/255.0 blue:205.0/255.0 alpha:1.0];
		gradientEnd = [NSColor 
				colorWithCalibratedRed:161.0/255.0 green:161.0/255.0 blue:161.0/255.0 alpha:1.0];
		
	}

	NSRect fillRect = cellFrame;
	//fillRect.origin.y++;
	
	NSRect top, bottom;
	NSDivideRect(cellFrame, &top, &bottom, fillRect.size.height/2, NSMinYEdge);
	top.size.height++;
	
	[[NSBezierPath bezierPathWithRect:top] linearGradientFillWithStartColor:gradientStart endColor:gradientEnd];
	[[NSBezierPath bezierPathWithRect:bottom] linearGradientFillWithStartColor:gradientEnd endColor:gradientStart];
	
	[[NSColor lightGrayColor] set];
	
	NSGraphicsContext *context = [NSGraphicsContext currentContext];
	[context saveGraphicsState];
	[context setShouldAntialias:NO];
	
	[[NSBezierPath bezierPathWithLineFrom:NSMakePoint(cellFrame.origin.x, cellFrame.origin.y + cellFrame.size.height ) 
			to:NSMakePoint(cellFrame.origin.x + cellFrame.size.width, cellFrame.origin.y + cellFrame.size.height ) 
			lineWidth:1] stroke];
	
	[context restoreGraphicsState];
	
	[self drawInteriorWithFrame:cellFrame inView:controlView];
	
	//[controlView unlockFocus];
	
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	
	//
	// draws the shape depending on the command
	
	NSSize size = cellFrame.size;
	float x = cellFrame.origin.x;
	float y = cellFrame.origin.y;
	
	switch ( [self command] ) {
		
		case kCalendarCommandMonthBack:
			[[NSColor darkGrayColor] set];
			[[NSBezierPath bezierPathWithTriangleInRect:NSMakeRect(x+size.width/2-4,y+6,8,6) orientation:AMTriangleDown] fill];
			break;
		
		case kCalendarCommandMonthForward:
			[[NSColor darkGrayColor] set];
			[[NSBezierPath bezierPathWithTriangleInRect:NSMakeRect(x+size.width/2-4,y+6,8,6) orientation:AMTriangleUp] fill];
			break;
		
		case kCalendarCommandToToday:
			[[NSColor darkGrayColor] set];
			[[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(x+size.width/2-3,y+6,6,6)] fill];
			[[NSColor lightGrayColor] set];
			
			NSGraphicsContext *context = [NSGraphicsContext currentContext];
			[context saveGraphicsState];
			[context setShouldAntialias:NO];
			
			[[NSBezierPath bezierPathWithLineFrom:NSMakePoint(x,1) to:NSMakePoint(x,y+size.height) lineWidth:1] stroke];
			[[NSBezierPath bezierPathWithLineFrom:NSMakePoint(x+size.width-1,1) to:NSMakePoint(x+size.width-1,y+size.height) lineWidth:1] stroke];
			
			[context restoreGraphicsState];
			
			break;
	}
}

@end
