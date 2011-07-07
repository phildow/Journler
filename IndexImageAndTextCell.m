//
//  IndexImageAndTextCell.m
//  Journler
//
//  Created by Philip Dow on 2/7/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "IndexImageAndTextCell.h"

#import <SproutedUtilities/SproutedUtilities.h>

/*
#import "NSBezierPath_AMShading.h"
#import "NSBezierPath_AMAdditons.h"
*/

@implementation IndexImageAndTextCell

- (void)dealloc {
   
	 [image release];
    image = nil;
	
	if ( _paragraph ) [_paragraph release];
	_paragraph = nil;
	
    [super dealloc];
}

- copyWithZone:(NSZone *)zone {
    
	IndexImageAndTextCell *cell = (IndexImageAndTextCell *)[super copyWithZone:zone];
	
    cell->image = [image retain];
	cell->_paragraph = [_paragraph retain];
	cell->imageSize = imageSize;
	
    return cell;
}

- (NSSize) imageSize {
	return imageSize;
}

- (void) setImageSize:(NSSize)aSize {
	imageSize = aSize;
}

- (void)setImage:(NSImage *)anImage {
    if (anImage != image) {
        [image release];
        image = [anImage retain];
    }
}

- (NSImage *)image {
    return image;
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

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {
    
	NSRect textFrame, imageFrame;
    NSDivideRect (aRect, &imageFrame, &textFrame, 3 + [self imageSize].width, NSMinXEdge);
    
	NSMutableDictionary *attrs;
	NSAttributedString *attrStringValue = [self attributedStringValue];
	
	if ( attrStringValue != nil && [attrStringValue length] != 0)
		attrs = [[[attrStringValue attributesAtIndex:0 effectiveRange:NULL] mutableCopyWithZone:[self zone]] autorelease];
	else
		attrs = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSFont systemFontOfSize:11], NSFontAttributeName,
				[NSColor blackColor], NSForegroundColorAttributeName, nil];
				
	//[textObj setTextColor:[NSColor blackColor]];
	//[textObj setTextColor:[NSColor blackColor] range:NSMakeRange(0,[[textObj string] length])];	
	
	// center the text and take into account the required inset
	int textHeight = [[self stringValue] sizeWithAttributes:attrs].height;
	textFrame.origin.y = textFrame.origin.y + (textFrame.size.height/2 - textHeight/2);
	textFrame.size.height = textHeight;
	textFrame.size.width -= 4;
	
	[super editWithFrame: textFrame inView: controlView editor:textObj delegate:anObject event: theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength {
   
	NSRect textFrame, imageFrame;
   	NSDivideRect (aRect, &imageFrame, &textFrame, 3 + [self imageSize].width, NSMinXEdge);
   
	NSMutableDictionary *attrs;
	NSAttributedString *attrStringValue = [self attributedStringValue];
	
	if ( attrStringValue != nil && [attrStringValue length] != 0)
		attrs = [[[attrStringValue attributesAtIndex:0 effectiveRange:NULL] mutableCopyWithZone:[self zone]] autorelease];
	else
		attrs = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSFont systemFontOfSize:11], NSFontAttributeName,
				[NSColor blackColor], NSForegroundColorAttributeName, nil];
		
	//[textObj setTextColor:[NSColor blackColor]];
	//[textObj setTextColor:[NSColor blackColor] range:NSMakeRange(0,[[textObj string] length])];		
	
	// center the text and take into account the required inset
	int textHeight = [[self stringValue] sizeWithAttributes:attrs].height;
	textFrame.origin.y = textFrame.origin.y + (textFrame.size.height/2 - textHeight/2);
	textFrame.size.height = textHeight;
	textFrame.size.width -= 4;

	[super selectWithFrame: textFrame inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

#pragma mark -

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	
	/*
	 if ([self isHighlighted]) {
		
		NSColor *gradientStart, *gradientEnd;
		
		NSRect controlBds = [controlView bounds];
		//NSRect gradientBounds = NSMakeRect(controlBds.origin.x, cellFrame.origin.y+1, 
		//		controlBds.size.width, cellFrame.size.height-1);
		
		NSRect gradientBounds = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, 
				cellFrame.size.width, cellFrame.size.height-1);
		
		if (([[controlView window] firstResponder] == controlView) && [[controlView window] isMainWindow] &&
				[[controlView window] isKeyWindow]) {
			
			//bottomColor = [NSColor colorWithCalibratedRed:91.0/255.0 green:129.0/255.0 blue:204.0/255.0 alpha:1.0];
			gradientStart = [NSColor colorWithCalibratedRed:136.0/255.0 green:165.0/255.0 blue:212.0/255.0 alpha:1.0];
			gradientEnd = [NSColor colorWithCalibratedRed:102.0/255.0 green:133.0/255.0 blue:183.0/255.0 alpha:1.0];
			
		} else {
			
			//bottomColor = [NSColor colorWithCalibratedRed:140.0/255.0 green:152.0/255.0 blue:176.0/255.0 alpha:0.9];
			gradientStart = [NSColor colorWithCalibratedRed:172.0/255.0 green:186.0/255.0 blue:207.0/255.0 alpha:0.9];
			gradientEnd = [NSColor colorWithCalibratedRed:152.0/255.0 green:170.0/255.0 blue:196.0/255.0 alpha:0.9];
		}
		
		[[NSBezierPath bezierPathWithRect:gradientBounds] linearGradientFillWithStartColor:
				gradientStart endColor:gradientEnd];
	}
	*/
	
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
	//[self drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if ( [self image] == nil )
		[super drawInteriorWithFrame:cellFrame inView:controlView];
	else
	{
	
	int textHeight;
	
	NSRect inset = cellFrame;
	NSMutableDictionary *attrs;
	NSAttributedString *attrStringValue = [self attributedStringValue];
	
	if ( attrStringValue != nil && [attrStringValue length] != 0)
		attrs = [[[attrStringValue attributesAtIndex:0 effectiveRange:NULL] mutableCopyWithZone:[self zone]] autorelease];
	else
		attrs = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSFont systemFontOfSize:11], NSFontAttributeName,
				[self textColor], NSForegroundColorAttributeName, nil];
	
	// paragraph attribute
	
	if ( _paragraph == nil ) {
		_paragraph = [[NSParagraphStyle defaultParagraphStyle] mutableCopyWithZone:[self zone]];
		[_paragraph setLineBreakMode:NSLineBreakByTruncatingTail];
	}
	
	[attrs setValue:_paragraph forKey:NSParagraphStyleAttributeName];
	
	/*
	if ([self isHighlighted]) {
		// prepare the text in white.
		[attrs setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
		
		NSFont *originalFont = [attrs objectForKey:NSFontAttributeName];
		if ( originalFont ) {
			NSFont *boldedFont = [[NSFontManager sharedFontManager] convertFont:originalFont toHaveTrait:NSBoldFontMask];
			if ( boldedFont ) [attrs setValue:boldedFont forKey:NSFontAttributeName];
		}
		
	} 
	else {
		// prepare the text in black.
		[attrs setValue:[self textColor] forKey:NSForegroundColorAttributeName];
	}
	*/
	
	// modify the inset some
	inset.origin.x += 2;
	inset.size.width -= 4;
	
	// center the text and take into account the required inset
	textHeight = [[self stringValue] sizeWithAttributes:attrs].height;
	inset.origin.y = inset.origin.y + (inset.size.height/2 - textHeight/2);
	inset.size.height = textHeight;
	
	// actually draw the title
	[super drawInteriorWithFrame:inset inView:controlView];
	//[[self stringValue] drawInRect:inset withAttributes:attrs];
	
	}
}


- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	return nil;
}


- (NSColor*) textColor {
	
	if ( [self isHighlighted] )
		return [NSColor whiteColor];
	else
		return [super textColor];
	
}

@end
