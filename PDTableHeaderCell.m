//
//  PDTableHeaderCell.m
//  Journler XD Lite
//
//  Created by Philip Dow on 9/14/06.
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
