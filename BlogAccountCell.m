//
//  BlocAccountCell.m
//  Journler
//
//  Created by Philip Dow on 4/3/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import "BlogAccountCell.h"

#import <SproutedUtilities/SproutedUtilities.h>

/*
#import "NSBezierPath_AMShading.h"
#import "NSBezierPath_AMAdditons.h"
*/

@implementation BlogAccountCell

- (id)initWithCoder:(NSCoder *)decoder {
	
	if ( self = [super initWithCoder:decoder] ) 
	{
		imageSize = NSMakeSize(32,32);
	}
	
	return self;
}

- (id)initTextCell:(NSString *)aString {
	
	if ( self = [super initTextCell:aString] ) 
	{
		imageSize = NSMakeSize(32,32);
	}
	
	return self;
}


- (void)dealloc {
   
	 [image release];
    image = nil;
	
	if ( _paragraph ) [_paragraph release];
	_paragraph = nil;
	
    [super dealloc];
}

- copyWithZone:(NSZone *)zone {
    
	BlogAccountCell *cell = (BlogAccountCell *)[super copyWithZone:zone];
	
    cell->image = [image retain];
	cell->_paragraph = [_paragraph retain];
	cell->blogType = [blogType retain];
	cell->imageSize = imageSize;
	cell->selected = selected;
	
    return cell;
}

- (NSSize) imageSize 
{
	return imageSize;
}

- (void) setImageSize:(NSSize)aSize 
{
	imageSize = aSize;
}

- (NSImage *)image
{
    return image;
}

- (void)setImage:(NSImage *)anImage 
{
    if (anImage != image) 
	{
        [image release];
        image = [anImage retain];
    }
}

- (NSString*) blogType
{
	return blogType;
}

- (void) setBlogType:(NSString*)aString
{
	if ( blogType != aString )
	{
		[blogType release];
		blogType = [aString copyWithZone:[self zone]];
	}
}

- (BOOL) isSelected
{
	return selected;
}

- (void) setSelected:(BOOL)isSelected
{
	selected = isSelected;
}

#pragma mark -

- (NSRect)imageFrameForCellFrame:(NSRect)cellFrame {
    if (image != nil) {
        NSRect imageFrame;
		imageFrame.size = [self imageSize];
        imageFrame.origin = cellFrame.origin;
        imageFrame.origin.x += 3;
        imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
        return imageFrame;
    }
    else
        return NSZeroRect;
}

- (NSSize)cellSize {
    NSSize cellSize = [super cellSize];
	cellSize.width += (image ? [self imageSize].width : 0) + 3;
    return cellSize;
}

#pragma mark -

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	
	if (image != nil) {
		
		NSSize	myImageSize;
		NSRect	imageFrame;

		myImageSize = [self imageSize];
		NSDivideRect(cellFrame, &imageFrame, &cellFrame, 3 + myImageSize.width, NSMinXEdge);
			
		imageFrame.origin.x += 3;
		imageFrame.size = myImageSize;

		if ([controlView isFlipped])
			imageFrame.origin.y += ceil((cellFrame.size.height + imageFrame.size.height) / 2);
		else
			imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
		
		//[image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
		
		//#warning this seems like a lot of extra work just because a newly created item draws flipped
		
		NSImage *imageCopy = [[[NSImage alloc] initWithSize:[self imageSize]] autorelease];
		//[imageCopy setFlipped:[controlView isFlipped]];
		
		[imageCopy lockFocus];
		
		[[NSGraphicsContext currentContext] saveGraphicsState];
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
		
		[image drawInRect:NSMakeRect(0,0,[self imageSize].width,[self imageSize].height) fromRect:NSMakeRect(0,0,[image size].width,[image size].height) 
				operation:NSCompositeSourceOver fraction:1.0];

		[[NSGraphicsContext currentContext] restoreGraphicsState];
		
		[imageCopy unlockFocus];
		
		//[imageCopy drawInRect:imageFrame fromRect:NSMakeRect(0,0,[imageCopy size].width,[imageCopy size].height) operation:NSCompositeSourceOver fraction:1.0];
		[imageCopy compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
	}
	
    [super drawWithFrame:cellFrame inView:controlView];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	
	CGFloat textHeight;
	
	NSRect inset = cellFrame;
	NSMutableDictionary *attrs;
	NSAttributedString *attrStringValue = [self attributedStringValue];
	
	if ( attrStringValue != nil && [attrStringValue length] != 0)
		attrs = [[[attrStringValue attributesAtIndex:0 effectiveRange:NULL] mutableCopyWithZone:[self zone]] autorelease];
	else
		attrs = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSFont systemFontOfSize:11], NSFontAttributeName,
				[NSColor blackColor], NSForegroundColorAttributeName, nil];
	
	// paragraph attribute
	
	if ( _paragraph == nil ) {
		_paragraph = [[NSParagraphStyle defaultParagraphStyle] mutableCopyWithZone:[self zone]];
		[_paragraph setLineBreakMode:NSLineBreakByTruncatingTail];
	}
	
	[attrs setValue:_paragraph forKey:NSParagraphStyleAttributeName];

	if ([self isSelected]) 
		[attrs setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	else 
		[attrs setValue:[self textColor] forKey:NSForegroundColorAttributeName];

	// modify the inset some
	inset.origin.x += 2;
	inset.size.width -= 4;
	
	// center the text and take into account the required inset
	textHeight = [[self stringValue] sizeWithAttributes:attrs].height;
	inset.origin.y = inset.origin.y + (inset.size.height/2 - textHeight/2);
	
	inset.size.height = textHeight;
	
	NSRect titleRect = inset;
	NSRect typeRect = inset;
	
	titleRect.origin.y -= textHeight/2;
	typeRect.origin.y += textHeight/2;
	
	// actually draw the title
	[[self stringValue] drawInRect:titleRect withAttributes:attrs];
	
	if ([self isSelected]) 
		[attrs setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	else 
		[attrs setValue:[NSColor darkGrayColor] forKey:NSForegroundColorAttributeName];

	[[self blogType] drawInRect:typeRect withAttributes:attrs];
}

@end
