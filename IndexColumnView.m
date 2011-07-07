//
//  IndexColumnView.m
//  Journler
//
//  Created by Philip Dow on 2/7/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

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
