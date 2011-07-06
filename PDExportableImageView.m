//
//  PDExportableImageView.m
//  Journler
//
//  Created by Philip Dow on 10/30/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "PDExportableImageView.h"
#import <SproutedUtilities/SproutedUtilities.h>

@implementation PDExportableImageView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		[self setEditable:YES];
		[self unregisterDraggedTypes];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	if ( self = [super initWithCoder:decoder] )
	{
		[self setEditable:YES];
		[self unregisterDraggedTypes];
	}
	return self;
}

- (void) dealloc
{
	[filename release];
	[super dealloc];
}

- (NSString*) filename
{
	return filename;
}

- (void) setFilename:(NSString*)aFilename
{
	if ( filename != aFilename )
	{
		[filename release];
		filename = [aFilename copyWithZone:[self zone]];
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	BOOL enabled = NO;
	SEL action = [menuItem action];
	
	if ( action == @selector(paste:) )
		enabled = NO;
	else if ( action == @selector(cut:) )
		enabled = NO;
	else if ( action == @selector(delete:) )
		enabled = NO;
	else if ( action == @selector(copy:) )
		enabled = YES;
	else if ( [super respondsToSelector:@selector(validateMenuItem:)] )
		enabled = [super validateMenuItem:menuItem];
	
	return enabled;
}

#pragma mark -

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	// don't permit local drags - pretty specific functioning
	return ( isLocal ? NSDragOperationNone : NSDragOperationCopy );
}

- (BOOL)ignoreModifierKeysWhileDragging
{
	return YES;
}

- (void)mouseDown:(NSEvent *)theEvent 
{
    NSEvent *dragEvent;

    [[self window] setAcceptsMouseMovedEvents:YES];
    dragEvent = [[self window] nextEventMatchingMask:NSLeftMouseDraggedMask | NSLeftMouseUpMask];

    if ([dragEvent type] == NSLeftMouseDragged)
    {
        NSSize imageSize;
        NSPoint imageOrigin, localCoordinates;
		
		NSPasteboard *pboard;
		NSArray *types;
		NSImage *myImage, *dragImage, *returnImage;
		
		localCoordinates = [self convertPoint:[dragEvent locationInWindow] fromView:nil];
		
		myImage = [self image];
		dragImage = [myImage imageWithWidth:64 height:[myImage size].height * 64. / [myImage size].width];
		returnImage = [[NSImage alloc] initWithSize:NSMakeSize([dragImage size].width+12, [dragImage size].height+12)];
	
		[returnImage lockFocus];
		
		[[NSColor colorWithCalibratedWhite:0.15 alpha:0.5] set];
		[[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0,0,[returnImage size].width,[returnImage size].height) cornerRadius:7.0] fill];
		
		[[NSColor colorWithCalibratedWhite:0.4 alpha:0.5] set];
		[[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0,0,[returnImage size].width,[returnImage size].height) cornerRadius:7.0] stroke];
			
		[dragImage compositeToPoint:NSMakePoint(6,6) operation:NSCompositeSourceOver fraction:0.9];
		[returnImage unlockFocus];
		
        imageSize = [returnImage size];
		imageOrigin = NSMakePoint(localCoordinates.x-(imageSize.width*3/4.), localCoordinates.y-(imageSize.height/4.));
		
		pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
		if ( [self filename] != nil )
			types = [NSArray arrayWithObjects:NSFilenamesPboardType, NSTIFFPboardType, nil];
		else
			types = [NSArray arrayWithObjects:NSTIFFPboardType, nil];
		
		[pboard declareTypes:types owner:self];
		[pboard setData:[[self image] TIFFRepresentation] forType:NSTIFFPboardType];
		
		if ( [self filename] != nil )
			[pboard setPropertyList:[NSArray arrayWithObject:[self filename]] forType:NSFilenamesPboardType];
		
		[self dragImage:returnImage at:imageOrigin offset:NSZeroSize
		event:theEvent pasteboard:[NSPasteboard pasteboardWithName:NSDragPboard] source:self slideBack:YES];
    }
	
    [[self window] setAcceptsMouseMovedEvents:NO];
}

@end
