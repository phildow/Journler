//
//  IndexColumnView.m
//  Journler
//
//  Created by Philip Dow on 2/7/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
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

#import "IndexColumnView.h"

#define IndexColumnMidWidth 150

@implementation IndexColumnView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
}

#pragma mark -

- (IndexColumn*) indexColumn
{
	return indexColumn;
}

- (void)resetCursorRects
{
	[self addCursorRect:[dragView frame] cursor:[NSCursor resizeLeftRightCursor]];
}

- (NSView *)hitTest:(NSPoint)aPoint
{
	if ( [self mouse:aPoint inRect:[self frame]] ) 
	{
		NSPoint local_point = [self convertPoint:aPoint fromView:[self superview]];
		if ( [self mouse:local_point inRect:[dragView frame]] )
			return self;
		else
			return [super hitTest:aPoint];
	}
	else
		return [super hitTest:aPoint];
}

#warning scroll problem here - drag view doesn't move directly underneath the mouse
- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint new_local_point;
	NSRect newFrame = [self frame];
	NSPoint local_point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	NSPoint min_width_point = NSMakePoint(-1,-1);
	
	NSPoint new_global_point;
	NSPoint original_global_point = [theEvent locationInWindow];
	float originalFrameWidth = [self frame].size.width;
	
	if ( !NSPointInRect(local_point,[dragView frame]) )
	{
		[super mouseDown:theEvent];
	}
	else
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:IndexColumnViewWillBeginResizing object:self userInfo:nil];
		
		// enter into an event loop
		while ( ( theEvent = [NSApp nextEventMatchingMask:NSLeftMouseDownMask|NSLeftMouseDraggedMask|NSLeftMouseUpMask 
				untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES] ) && ( [theEvent type] != NSLeftMouseUp ) ) {
			
			float deltaWidth, originalWidth;
			newFrame = [self frame];
			originalWidth = newFrame.size.width;
			
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			new_local_point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
			new_global_point = [theEvent locationInWindow];
			
			//deltaWidth = new_local_point.x - local_point.x;
			deltaWidth = new_global_point.x - original_global_point.x;
			NSLog(@"%s - delta: %f", __PRETTY_FUNCTION__, deltaWidth);
			
			if ( deltaWidth < 0 )
			{
				//newFrame.size.width += deltaWidth;
				newFrame.size.width = originalFrameWidth + deltaWidth;
			}
			else if ( deltaWidth > 0 && new_local_point.x >= min_width_point.x )
			{
				//newFrame.size.width += deltaWidth;
				newFrame.size.width = originalFrameWidth + deltaWidth;
			}
				
			// do not reframe if this is the min width or if the frame hasn't changed
			if ( newFrame.size.width != originalWidth && newFrame.size.width >= IndexColumnMidWidth )
				[self setFrame:newFrame];
			else if ( min_width_point.x == -1 )
				min_width_point.x = new_local_point.x + [dragView frame].size.width/2;
			
			local_point = new_local_point;
			[pool release];
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:IndexColumnViewDidEndResizing object:self userInfo:nil];
	}
}

@end
