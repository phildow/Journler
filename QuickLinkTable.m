//
//  QuickLinkTable.m
//  Journler
//
//  Created by Philip Dow on 2/15/06.
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

#import "QuickLinkTable.h"
#import "JournlerEntry.h"
#import "QuickLinkArrayController.h"

#import <SproutedUtilities/SproutedUtilities.h>
/*
#import "NSBezierPath_AMShading.h"
#import "NSBezierPath_AMAdditons.h"
*/

#import "Definitions.h"

@implementation QuickLinkTable

- (id) draggingObject { return _draggingObject; }

- (void) setDraggingObject:(id)object {
	
	_draggingObject = object;
	
}

- (id) draggingObjects { return _draggingObjects; }

- (void) setDraggingObjects:(id)objects {
	
	_draggingObjects = objects;
	
}

#pragma mark -

- (NSUInteger)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
	
	if ( isLocal )
		return ( NSDragOperationDelete | NSDragOperationCopy );
	else
		return NSDragOperationCopy;
	
}

- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows 
		tableColumns:(NSArray *)tableColumns event:(NSEvent*)dragEvent offset:(NSPointPointer)dragImageOffset {
	
	//
	// We'll use the first icon the workspace manager returns
	// draw that guy into an image, along with the tracks name
	// I mean, let's be fancy about it!
	//
	
	//JournlerEntry *entry = [[[self dataSource] arrangedObjects] objectAtIndex:[[dragRows objectAtIndex:0] integerValue]];
	JournlerEntry *entry = [[[self dataSource] arrangedObjects] objectAtIndex:[dragRows firstIndex]];
	if ( !entry )
		return nil;
	
	NSString *title = [entry title];
	if ( !title )
		return nil;
	
	NSImage *icon = [NSImage imageNamed:@"EntryDrag.tif"];
	NSImage *returnImage;
	NSImage *dragBadge = nil;
	
	//
	// if more than one row is being dragged, determine which dragBadge to use
	
	if ( [dragRows count] > 1 && [dragRows count] < 100 )
		dragBadge = [[[NSImage imageNamed:@"dragBadge1.png"] copyWithZone:[self zone]] autorelease];
	else if ( [dragRows count] >= 100 && [dragRows count] < 1000 )
		dragBadge = [[[NSImage imageNamed:@"dragBadge2.png"] copyWithZone:[self zone]] autorelease];
	else if ( [dragRows count] >= 1000 )
		dragBadge = [[[NSImage imageNamed:@"dragBadge3.png"] copyWithZone:[self zone]] autorelease];
	
	//
	// Get the size of this thing
	//
	
	if ( dragBadge ) {
		
		//
		// draw the count if necessary
		NSDictionary *countAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName,
				[NSColor colorWithCalibratedWhite:1.0 alpha:1.0], NSForegroundColorAttributeName, nil];
		
		NSString *countString = [[NSNumber numberWithInteger:[dragRows count]] stringValue];
		NSSize countSize = [countString sizeWithAttributes:countAttributes];
		
		[dragBadge lockFocus];
		[countString drawInRect:NSMakeRect(	[dragBadge size].width/2 - countSize.width/2, 
											[dragBadge size].height/2 - countSize.height/2,
											countSize.width, countSize.height )
				withAttributes:countAttributes];
		[dragBadge unlockFocus];
		
	}
	
	NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	
	[shadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.96]];
	[shadow setShadowOffset:NSMakeSize(1,-1)];
	
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys: 
	[NSFont systemFontOfSize:11], NSFontAttributeName,
	[NSColor colorWithCalibratedWhite:0.01 alpha:1.0], NSForegroundColorAttributeName, 
	shadow, NSShadowAttributeName, nil];
	
	NSSize iconSize = [icon size];
	NSSize stringSize = [title sizeWithAttributes:attributes];
	
	returnImage = [[NSImage alloc] initWithSize:NSMakeSize(iconSize.width+stringSize.width+12, 
		(iconSize.height >= stringSize.height ? iconSize.height : stringSize.height) + 6)];
	
	[returnImage lockFocus];
	
	//[[NSColor colorWithCalibratedWhite:0.2 alpha:0.05] set];
	//NSRectFill(NSMakeRect(0,6,[returnImage size].width,[returnImage size].height-6));
	
	//[[NSColor lightGrayColor] set];
	//NSFrameRect(NSMakeRect(0,6,[returnImage size].width,[returnImage size].height-6));
	
	[[NSColor colorWithCalibratedWhite:0.25 alpha:0.3] set];
	//NSRectFill(NSMakeRect(0,6,[returnImage size].width,[returnImage size].height-6));
	[[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0,6,[returnImage size].width,[returnImage size].height-6) cornerRadius:10.0] fill];
	
	[[NSColor colorWithCalibratedWhite:0.5 alpha:0.3] set];
	//NSFrameRect(NSMakeRect(0,6,[returnImage size].width,[returnImage size].height-6));
	[[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0,6,[returnImage size].width,[returnImage size].height-6) cornerRadius:10.0] stroke];
		
	[icon compositeToPoint:NSMakePoint(2,6) operation:NSCompositeSourceOver fraction:1.0];
	[title drawAtPoint:NSMakePoint(iconSize.width+7,8) withAttributes:attributes];
		
	if ( dragBadge ) {
		[dragBadge compositeToPoint:NSMakePoint(iconSize.width+7-[dragBadge size].width, 0) operation:NSCompositeSourceOver fraction:1.0];
	}
	
	[returnImage unlockFocus];
	
	// and set our dragging object
	[self setDraggingObjects:dragRows];
		
	return [returnImage autorelease];

}

#pragma mark -

- (void)keyDown:(NSEvent *)event { 
    
	//
	// overridden to implement a delete key down event
	//
	
	static unichar kUnicharKeyReturn = '\r';
	static unichar kUnicharKeyNewline = '\n';
	
	unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];
	
	if ( key == kUnicharKeyReturn || key == kUnicharKeyNewline ) {
		//
		// open this guy in a new window
		if ( [event modifierFlags] & NSShiftKeyMask )
			[NSApp sendAction:@selector(newTabWithSelectedEntry:) to:nil from:self];
		else
			[NSApp sendAction:@selector(openEntryInWindow:) to:nil from:self];
	}
	else { 
		[super keyDown:event];
    }
	
}

#pragma mark -

- (IBAction) copy:(id)sender
{
	[[self dataSource] tableView:self writeRowsWithIndexes:[self selectedRowIndexes] toPasteboard:[NSPasteboard generalPasteboard]];
}

- (BOOL)becomeFirstResponder
{
	NSMenuItem *copyItem = [[[[NSApp mainMenu] itemWithTag:2] submenu] itemWithTag:99];
	[copyItem setTitle:NSLocalizedString(@"entry link menu item",@"")];
	
	return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
	NSMenuItem *copyItem = [[[[NSApp mainMenu] itemWithTag:2] submenu] itemWithTag:99];
	[copyItem setTitle:NSLocalizedString(@"copy menu item",@"")];
	
	return [super resignFirstResponder];
}


@end
