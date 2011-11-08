//
//  CalendarButtonCell.m
//  Journler XD Lite
//
//  Created by Philip Dow on 9/20/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

/*
 Redistribution and use in source and binary forms, with or without modification, are permitted
 provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions
 and the following disclaimer in the documentation and/or other materials provided with the
 distribution.
 
 * Neither the name of the author nor the names of its contributors may be used to endorse or
 promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// Basically, you can use the code in your free, commercial, private and public projects
// as long as you include the above notice and attribute the code to Philip Dow / Sprouted
// If you use this code in an app send me a note. I'd love to know how the code is used.

// Please also note that this copyright does not supersede any other copyrights applicable to
// open source code used herein. While explicit credit has been given in the Journler about box,
// it may be lacking in some instances in the source code. I will remedy this in future commits,
// and if you notice any please point them out.

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
