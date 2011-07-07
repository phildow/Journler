//
//  IndexOutlineView.m
//  Journler
//
//  Created by Philip Dow on 2/7/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "IndexOutlineView.h"

#import "IndexNode.h"
#import "IndexColumn.h"

#import <SproutedUtilities/SproutedUtilities.h>

/*
#import "NSBezierPath_AMShading.h"
#import "NSBezierPath_AMAdditons.h"

#import "NSOutlineView_Extensions.h"
#import "NSOutlineView_ProxyAdditions.h"
*/

#define kSearchIntervalDelay 1.5

@implementation IndexOutlineView

- (void) awakeFromNib 
{
	_searchString = [[NSMutableString alloc] init];
}

- (void) dealloc
{
	[_searchString release];
	[super dealloc];
}

- (IndexColumn*) indexColumn
{
	return indexColumn;
}

#pragma mark -

- (id)_highlightColorForCell:(NSCell *)cell
{
	return [self backgroundColor];
}

- (void)keyDown:(NSEvent *)event 
{ 
	//static unichar kUnicharKeyReturn = '\r';
	//static unichar kUnicharKeyNewline = '\n';
	
	unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];
  
	if (key == NSDeleteCharacter && [self numberOfRows] > 0 && [self selectedRow] != -1) 
	{ 
		// request a delete from the delegate
		if ( [[self delegate] respondsToSelector:@selector(indexOutlineView:deleteSelectedRows:)] )
			[[self delegate] indexOutlineView:self deleteSelectedRows:[self selectedRowIndexes]];
    }
	
	else 
	{ 
		// perform a search
		NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
		
		if ( currentTime - _searchInterval > kSearchIntervalDelay )
			[_searchString setString:@""];
		
		_searchInterval = currentTime;
		NSString *new_characters = [event characters];
		
		if ( new_characters && [new_characters length] > 0 ) 
		{
			unichar a_char = [new_characters characterAtIndex:0];
			if ( a_char >= 0xF700 && a_char <= 0xF8FF )
			{
				[super keyDown:event];
			}
			else 
			{
				int i;
				NSArray *objects = [rootController arrangedObjects];
				[_searchString appendString:new_characters];
				
				for ( i = 0; i < [objects count]; i++ ) 
				{
					if ( [[[objects objectAtIndex:i] valueForKey:@"title"] 
							rangeOfString:_searchString options:NSCaseInsensitiveSearch].location == 0 ) 
					{
						[self scrollRowToVisible:i];
						[self selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
						break;
					}
				}
			}
		}
		else
		{
			[super keyDown:event];
		}
    } 
}

- (void)drawRow:(int)rowIndex clipRect:(NSRect)clipRect {
	
	// grab the draw rect
	NSRect targetRect = [self rectOfRow:rowIndex];
	
	if ( [[self selectedRowIndexes] containsIndex:rowIndex] )
	{
		NSRect gradientRect = targetRect;
		gradientRect.size.height--;
		
		[self _drawSelectionInRect:gradientRect 
				highlight: (([[self window] firstResponder] == self) && [[self window] isMainWindow] && [[self window] isKeyWindow]) ];

	}
	
	[super drawRow:rowIndex clipRect:clipRect];

}

- (void) _drawSelectionInRect:(NSRect)aRect highlight:(BOOL)highlight
{
	//[JournlerGradientView drawGradientInView:self rect:aRect highlight:highlight];
	
	NSColor *gradientStart, *gradientEnd;
	
	if ( highlight ) 
	{
		gradientStart = [[NSColor colorWithCalibratedRed:136.0/255.0 green:165.0/255.0 blue:212.0/255.0 alpha:1.0]
			blendedColorWithFraction:0.5 ofColor:[NSColor colorForControlTint:[NSColor currentControlTint]]];
			
		
		gradientEnd = [[NSColor colorWithCalibratedRed:102.0/255.0 green:133.0/255.0 blue:183.0/255.0 alpha:1.0]
			blendedColorWithFraction:0.5 ofColor:[NSColor colorForControlTint:[NSColor currentControlTint]]];
			
	} 
	else 
	{
		gradientStart = [[NSColor colorWithCalibratedRed:172.0/255.0 green:186.0/255.0 blue:207.0/255.0 alpha:0.9]
			blendedColorWithFraction:0.5 ofColor:[NSColor colorForControlTint:[NSColor currentControlTint]]];
			
			
		gradientEnd = [[NSColor colorWithCalibratedRed:152.0/255.0 green:170.0/255.0 blue:196.0/255.0 alpha:0.9]
			blendedColorWithFraction:0.5 ofColor:[NSColor colorForControlTint:[NSColor currentControlTint]]];
		
	}
	
	[[NSBezierPath bezierPathWithRect:aRect] linearGradientFillWithStartColor:gradientStart endColor:gradientEnd];

}

#pragma mark -

- (void)copy:(id)sender
{
	// copy the strings onto the pasteboard 
	[[self dataSource] outlineView:self writeItems:[self allSelectedItems] toPasteboard:[NSPasteboard generalPasteboard]];
}


#pragma mark -

/*
- (void)keyDown:(NSEvent *)event 
{ 
	unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];
	unsigned int modifierFlags = [event modifierFlags];
	
	if ( key == NSLeftArrowFunctionKey && [[self delegate] respondsToSelector:@selector(outlineView:leftKeyDown:)] && ( modifierFlags & NSCommandKeyMask ) )
		[[self delegate] outlineView:self leftKeyDown:event];
	else if ( key == NSRightArrowFunctionKey && [[self delegate] respondsToSelector:@selector(outlineView:rightKeyDown:)] && ( modifierFlags & NSCommandKeyMask ) )
		[[self delegate] outlineView:self rightKeyDown:event];
	else
		[super keyDown:event];
}
*/


- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal 
{
	if ( isLocal )
		return NSDragOperationLink;
	else
		return NSDragOperationCopy;
}


- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows 
		tableColumns:(NSArray *)tableColumns event:(NSEvent*)dragEvent offset:(NSPointPointer)dragImageOffset 
{
	// it doesn't matter what kind of object we're dealing with, as long as it responds to title and icon
	id anObject = [[self originalItemAtRow:[dragRows firstIndex]] representedObject];
	
	if ( !anObject ) return [super dragImageForRowsWithIndexes:dragRows tableColumns:tableColumns event:dragEvent offset:dragImageOffset];
	if ( ![anObject respondsToSelector:@selector(title)] || ![anObject respondsToSelector:@selector(icon)] )
		return [super dragImageForRowsWithIndexes:dragRows tableColumns:tableColumns event:dragEvent offset:dragImageOffset];
	
	NSString *title = [anObject valueForKey:@"title"];
	if ( !title ) return [super dragImageForRowsWithIndexes:dragRows tableColumns:tableColumns event:dragEvent offset:dragImageOffset];
	
	NSImage *icon = [self resizedImage:[anObject valueForKey:@"icon"] width:32 height:32 inset:0];
	if ( !icon ) return [super dragImageForRowsWithIndexes:dragRows tableColumns:tableColumns event:dragEvent offset:dragImageOffset];
	
	/*
	// if more than one row is being dragged, determine which dragBadge to use
	NSImage *dragBadge = nil;
	if ( [dragRows count] > 1 && [dragRows count] < 100 )
		dragBadge = [[[NSImage imageNamed:@"dragBadge1.png"] copyWithZone:[self zone]] autorelease];
	else if ( [dragRows count] >= 100 && [dragRows count] < 1000 )
		dragBadge = [[[NSImage imageNamed:@"dragBadge2.png"] copyWithZone:[self zone]] autorelease];
	else if ( [dragRows count] >= 1000 )
		dragBadge = [[[NSImage imageNamed:@"dragBadge3.png"] copyWithZone:[self zone]] autorelease];
	
	// Get the size of this thing
	if ( dragBadge ) 
	{
		// draw the count if necessary
		NSDictionary *countAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName,
				[NSColor colorWithCalibratedWhite:1.0 alpha:1.0], NSForegroundColorAttributeName, nil];
		
		NSString *countString = [[NSNumber numberWithInt:[dragRows count]] stringValue];
		NSSize countSize = [countString sizeWithAttributes:countAttributes];
		
		[dragBadge lockFocus];
		[countString drawInRect:NSMakeRect(	[dragBadge size].width/2 - countSize.width/2, 
											[dragBadge size].height/2 - countSize.height/2,
											countSize.width, countSize.height ) withAttributes:countAttributes];
		[dragBadge unlockFocus];
	}
	*/
	
	NSImage *returnImage;
	
	NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	
	[shadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.96]];
	[shadow setShadowOffset:NSMakeSize(1,-1)];
	
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys: 
	[NSFont systemFontOfSize:11], NSFontAttributeName,
	[NSColor colorWithCalibratedWhite:0.01 alpha:1.0], NSForegroundColorAttributeName, 
	shadow, NSShadowAttributeName, nil];
	
	NSSize iconSize = [icon size];
	NSSize stringSize = [title sizeWithAttributes:attributes];
	
	float myWidth = [self bounds].size.width;
	float proposedWidth = iconSize.width+stringSize.width+20;
	
	returnImage = [[NSImage alloc] initWithSize:NSMakeSize( ( myWidth > proposedWidth ? myWidth : proposedWidth ) , 
		(iconSize.height >= stringSize.height ? iconSize.height : stringSize.height) + 6)];
	
	
	
	[returnImage lockFocus];
	
	//NSGraphicsContext *graphicsContext = [NSGraphicsContext currentContext];
	//[graphicsContext saveGraphicsState];
	
	//[shadow set];
	
	[[NSColor colorWithCalibratedWhite:0.25 alpha:0.3] set];
	//NSRectFill(NSMakeRect(0,6,[returnImage size].width,[returnImage size].height-6));
	[[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0,6,[returnImage size].width,[returnImage size].height-6) cornerRadius:10.0] fill];
	
	[[NSColor colorWithCalibratedWhite:0.5 alpha:0.3] set];
	//NSFrameRect(NSMakeRect(0,6,[returnImage size].width,[returnImage size].height-6));
	[[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0,6,[returnImage size].width,[returnImage size].height-6) cornerRadius:10.0] stroke];
	
	//[graphicsContext restoreGraphicsState];
	
	[icon compositeToPoint:NSMakePoint(6,6) operation:NSCompositeSourceOver fraction:1.0];
	[title drawAtPoint:NSMakePoint(iconSize.width+7,8) withAttributes:attributes];

	
	/*
	if ( dragBadge ) 
	{
		[dragBadge compositeToPoint:NSMakePoint(iconSize.width+7-[dragBadge size].width, 0) operation:NSCompositeSourceOver fraction:1.0];
	}
	*/
	
	[returnImage unlockFocus];
	return [returnImage autorelease];
}

- (BOOL)becomeFirstResponder
{
	// let the delegate know that we become first responder
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	BOOL didBecome = [super becomeFirstResponder];
	if ( didBecome && [[self delegate] respondsToSelector:@selector(outlineViewDidBecomeFirstResponder:)] )
		[[self delegate] outlineViewDidBecomeFirstResponder:self];
	
	return didBecome;
}

@end

@implementation IndexOutlineView (AdditionalUISupport)

- (NSImage*) resizedImage:(NSImage*)anImage width:(float)width height:(float)height inset:(float)inset 
{	
	// returns a WxH version of the image but with the image inset on all sides
	NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(width,height)];
	NSRect dRect = NSMakeRect(inset,inset,width-inset*2,height-inset*2);
	
	[image lockFocus];
	[[NSGraphicsContext currentContext] saveGraphicsState];
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	[anImage drawInRect:dRect fromRect:NSMakeRect(0,0,[anImage size].width,[anImage size].height) 
			operation:NSCompositeSourceOver fraction:1.0];
	[[NSGraphicsContext currentContext] restoreGraphicsState];
	[image unlockFocus];

	return [image autorelease];
}

@end

