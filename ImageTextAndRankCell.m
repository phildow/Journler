//
//  ImageTextAndRankCell.m
//  Journler XD Lite
//
//  Created by Philip Dow on 9/13/06.
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

#import "ImageTextAndRankCell.h"

#import <SproutedUtilities/SproutedUtilities.h>

/*
#import "NSBezierPath_AMShading.h"
#import "NSBezierPath_AMAdditons.h"
*/
//#import "JournlerGradientView.h"

#define kLabelOffset 10

@implementation ImageTextAndRankCell

- (id)initWithCoder:(NSCoder *)decoder {
	
	if ( self = [super initWithCoder:decoder] ) {
		
		minRank = 0.0;
		maxRank = 1.0;
		capBottom = YES;
		additionalIndent = 0;
		imageSize = NSMakeSize(32,32);
		
		imageCell = [[NSImageCell alloc] initImageCell:nil];
		
		[imageCell setImageFrameStyle:NSImageFrameNone];
		[imageCell setImageScaling:NSScaleNone];
		
		[imageCell setAlignment:NSCenterTextAlignment];
		[imageCell setImageAlignment:NSImageAlignTop];
		
		[imageCell setBezeled:NO];
		[imageCell setBordered:YES];
	}
	
	return self;
}

- (id)initTextCell:(NSString *)aString {
	
	if ( self = [super initTextCell:aString] ) {
		
		minRank = 0.0;
		maxRank = 1.0;
		capBottom = YES;
		additionalIndent = 0;
		imageSize = NSMakeSize(32,32);
		
		imageCell = [[NSImageCell alloc] initImageCell:nil];
		
		[imageCell setImageFrameStyle:NSImageFrameNone];
		[imageCell setImageScaling:NSScaleNone];
		
		[imageCell setAlignment:NSCenterTextAlignment];
		[imageCell setImageAlignment:NSImageAlignTop];
		
		[imageCell setBezeled:NO];
		[imageCell setBordered:YES];

	}
	
	return self;
}

- (void)dealloc {
   
	[image release];
    image = nil;
	
	[imageCell release];
	
	if ( _paragraph ) [_paragraph release];
	_paragraph = nil;
	
    [super dealloc];
}

- copyWithZone:(NSZone *)zone 
{
    ImageTextAndRankCell *cell = (ImageTextAndRankCell *)[super copyWithZone:zone];
	
    cell->image = [image retain];
	cell->_paragraph = [_paragraph retain];
	cell->imageCell = [imageCell retain];
	
	cell->count = count;
	cell->label = label;
	cell->selected = selected;
	cell->additionalIndent = additionalIndent;
	
	cell->imageSize = imageSize;
	cell->capTop = capTop;
	cell->capBottom = capBottom;

    return cell;
}

#pragma mark -

- (void) setCapTop:(BOOL)top capBottom:(BOOL)bottom
{
	capTop = top;
	capBottom = bottom;
}

- (BOOL) isSelected
{
	return selected;
}

- (void) setSelected:(BOOL)isSelected
{
	selected = isSelected;
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
		imageFrame.origin.x += additionalIndent;
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
    NSDivideRect (aRect, &imageFrame, &textFrame, additionalIndent + 3 + [self imageSize].width, NSMinXEdge);
    
	NSMutableDictionary *attrs;
	NSAttributedString *attrStringValue = [self attributedStringValue];
	
	if ( attrStringValue != nil && [attrStringValue length] != 0)
		attrs = [[[attrStringValue attributesAtIndex:0 effectiveRange:NULL] mutableCopyWithZone:[self zone]] autorelease];
	else
		attrs = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSFont systemFontOfSize:11], NSFontAttributeName,
				[NSColor blackColor], NSForegroundColorAttributeName, nil];

	// center the text and take into account the required inset
	NSInteger textHeight = [[self stringValue] sizeWithAttributes:attrs].height;
	textFrame.origin.y = textFrame.origin.y + (textFrame.size.height/2 - textHeight/2);
	textFrame.size.height = textHeight;
	
	textFrame.size.width -= 6;
	textFrame.size.width -= additionalIndent;
	
	[super editWithFrame: textFrame inView: controlView editor:textObj delegate:anObject event: theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength {
   
	NSRect textFrame, imageFrame;
   	NSDivideRect (aRect, &imageFrame, &textFrame, additionalIndent + 3 + [self imageSize].width, NSMinXEdge);
   
	NSMutableDictionary *attrs;
	NSAttributedString *attrStringValue = [self attributedStringValue];
	
	if ( attrStringValue != nil && [attrStringValue length] != 0)
		attrs = [[[attrStringValue attributesAtIndex:0 effectiveRange:NULL] mutableCopyWithZone:[self zone]] autorelease];
	else
		attrs = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSFont systemFontOfSize:11], NSFontAttributeName,
				[NSColor blackColor], NSForegroundColorAttributeName, nil];
	
	// center the text and take into account the required inset
	NSInteger textHeight = [[self stringValue] sizeWithAttributes:attrs].height;
	textFrame.origin.y = textFrame.origin.y + (textFrame.size.height/2 - textHeight/2);
	textFrame.size.height = textHeight;
	
	textFrame.size.width -= 6;
	textFrame.size.width -= additionalIndent;

	[super selectWithFrame: textFrame inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}


#pragma mark -

- (NSInteger) count
{
	return count;
}

- (void) setCount:(NSInteger)value
{
	count = value;
}

- (BOOL) label
{
	return label;
}

- (void) setLabel:(BOOL)isLabel
{
	label = isLabel;
}

- (float) minRank {
	return minRank;
}

- (void) setMinRank:(float)value {
	minRank = value;
}

- (float) maxRank {
	return maxRank;
}

- (void) setMaxRank:(float)value {
	maxRank = value;
}

- (float) rank {
	return rank;
}

- (void) setRank:(float)value {
	rank = value;
}

- (NSInteger) additionalIndent
{
	return additionalIndent;
}

- (void) setAdditionalIndent:(NSInteger)value
{
	additionalIndent = value;
}

#pragma mark -

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	
	if ( label )
	{
		// readjust the cell for labeling
		cellFrame.origin.x += kLabelOffset;
		cellFrame.size.width -= kLabelOffset;
		
		// working with the control size is a bad idea for a generic cell class
		NSRect controlBds = [controlView bounds];
		NSRect gradientBounds = NSMakeRect(	controlBds.origin.x, cellFrame.origin.y, 
											controlBds.size.width, cellFrame.size.height-1);
		
		//[JournlerGradientView drawGradientInView:controlView rect:gradientBounds highlight:NO shadow:0.09];
		
		//bottomColor = [NSColor colorWithCalibratedRed:91.0/255.0 green:129.0/255.0 blue:204.0/255.0 alpha:1.0];
		NSColor *gradientStart = [NSColor colorWithCalibratedWhite:0.92 alpha:1.0];
		NSColor *gradientEnd = [NSColor colorWithCalibratedWhite:0.82 alpha:1.0];
		
		// [NSColor colorWithCalibratedWhite:0.92 alpha:0.8]
		// [NSColor colorWithCalibratedWhite:0.82 alpha:0.8]
		
		[[NSBezierPath bezierPathWithRect:gradientBounds] linearGradientFillWithStartColor:
				gradientStart endColor:gradientEnd];
		
		//NSColor *capColor = [[NSColor colorForControlTint:[NSColor currentControlTint]] shadowWithLevel:0.2];
		NSColor *capColor = [NSColor colorWithCalibratedWhite:0.62 alpha:1.0];
		NSBezierPath *capPath;
		
		
		//  = [NSBezierPath bezierPathWithLineFrom:NSMakePoint(controlBds.origin.x, cellFrame.origin.y + cellFrame.size.height - 1)
		//		to:NSMakePoint(controlBds.size.width, cellFrame.origin.y + cellFrame.size.height - 1) lineWidth:1.0];

		
		
		NSGraphicsContext *context = [NSGraphicsContext currentContext];
		[context saveGraphicsState];
		[context setShouldAntialias:NO];
		
		//if ( capTop )
		//{
			capPath = [NSBezierPath bezierPath];
			[capPath setLineWidth:1.0];
			
			[capPath moveToPoint:NSMakePoint( controlBds.origin.x, cellFrame.origin.y + 1)];
			[capPath lineToPoint:NSMakePoint( controlBds.size.width, cellFrame.origin.y + 1)];
			
			[[capColor highlightWithLevel:0.6] set];
			[capPath stroke];
		//}
		if ( capBottom )
		{
			capPath = [NSBezierPath bezierPath];
			[capPath setLineWidth:1.0];
			
			[capPath moveToPoint:NSMakePoint(controlBds.origin.x, cellFrame.origin.y + cellFrame.size.height - 1)];
			[capPath lineToPoint:NSMakePoint(controlBds.size.width, cellFrame.origin.y + cellFrame.size.height - 1)];
			
			[capColor set];
			[capPath stroke];
		}
		
		[context restoreGraphicsState];
		
		/*
		NSColor *gradientStart;
		
		NSRect controlBds = [controlView bounds];
		//NSRect gradientBounds = NSMakeRect(controlBds.origin.x, cellFrame.origin.y+1, 
		//		controlBds.size.width, cellFrame.size.height-1);
		
		NSRect gradientBounds = NSMakeRect(controlBds.origin.x, cellFrame.origin.y, 
				controlBds.size.width, cellFrame.size.height-1);
			
		//bottomColor = [NSColor colorWithCalibratedRed:91.0/255.0 green:129.0/255.0 blue:204.0/255.0 alpha:1.0];
		gradientStart = [NSColor colorWithCalibratedRed:128.0/255.0 green:142.0/255.0 blue:163.0/255.0 alpha:1.0];
		gradientEnd = [NSColor colorWithCalibratedRed:111.0/255.0 green:129.0/255.0 blue:156.0/255.0 alpha:1.0];
			
		[[NSBezierPath bezierPathWithRect:gradientBounds] linearGradientFillWithStartColor:
				gradientStart endColor:gradientEnd];
		*/
	}
	
	/*
    else if ( [self isHighlighted] ) {
		
		NSColor *gradientStart, *gradientEnd;
		
		NSRect controlBds = [controlView bounds];
		//NSRect gradientBounds = NSMakeRect(controlBds.origin.x, cellFrame.origin.y+1, 
		//		controlBds.size.width, cellFrame.size.height-1);
		
		NSRect gradientBounds = NSMakeRect(controlBds.origin.x, cellFrame.origin.y, 
				controlBds.size.width, cellFrame.size.height-1);
		
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
		
		imageFrame.origin.y += 2;
        imageFrame.origin.x += 3;
		imageFrame.origin.x += additionalIndent;
        imageFrame.size = myImageSize;
		
      //  if ([controlView isFlipped])
      //      imageFrame.origin.y += ceil((cellFrame.size.height + imageFrame.size.height) / 2);
      //  else
      //      imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
		
		// #warning this seems like a lot of extra work just because a newly created item draws flipped
		
		NSImage *imageCopy = [[[NSImage alloc] initWithSize:[self imageSize]] autorelease];
		
		//[imageCopy setFlipped:[controlView isFlipped]];
		[imageCopy lockFocus];
		
		[[NSGraphicsContext currentContext] saveGraphicsState];
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
		
		[image drawInRect:NSMakeRect(0,0,[self imageSize].width,[self imageSize].height) fromRect:NSMakeRect(0,0,[image size].width,[image size].height) 
				operation:NSCompositeSourceOver fraction:1.0];

		[[NSGraphicsContext currentContext] restoreGraphicsState];
		[imageCopy unlockFocus];
		
		//BOOL wasFlipped = [imageCopy isFlipped];
		//[imageCopy setFlipped:[controlView isFlipped]];
		
		[imageCell setImage:imageCopy];
		[imageCell drawWithFrame:imageFrame inView:controlView];
		
		//[imageCopy setFlipped:wasFlipped];
		
		//[imageCopy unlockFocus];
		//[imageCopy drawInRect:imageFrame fromRect:NSMakeRect(0,0,[imageCopy size].width,[imageCopy size].height)
		//		operation:NSCompositeSourceOver fraction:1.0];
		//[imageCopy compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
    }
		
    [super drawWithFrame:cellFrame inView:controlView];
	//[self drawInteriorWithFrame:cellFrame inView:controlView];
}


- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	
	NSInteger textHeight;
	
	NSRect inset = cellFrame;
	NSMutableDictionary *attrs;
	NSAttributedString *attrStringValue = [self attributedStringValue];
	
	if ( attrStringValue != nil && [attrStringValue length] != 0)
		attrs = [[[attrStringValue attributesAtIndex:0 effectiveRange:NULL] mutableCopyWithZone:[self zone]] autorelease];
	else
		attrs = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSFont systemFontOfSize:11], NSFontAttributeName,
				[NSColor blackColor], NSForegroundColorAttributeName, nil];
	
	if ( _paragraph == nil ) {
		_paragraph = [[NSParagraphStyle defaultParagraphStyle] mutableCopyWithZone:[self zone]];
		[_paragraph setLineBreakMode:NSLineBreakByTruncatingTail];
	}
	
	[attrs setValue:_paragraph forKey:NSParagraphStyleAttributeName];
	
	if ( [self label] )
	{
		// prepare the text in black.
		//NSColor *attrColor = [[[NSColor blackColor]
		//		blendedColorWithFraction:0.5 ofColor:[NSColor colorForControlTint:[NSColor currentControlTint]]]
		//		shadowWithLevel:0.5];
		
		NSColor *attrColor = [NSColor colorWithCalibratedRed:0.20 green:0.20 blue:0.20 alpha:1.0];
		
        [attrs setValue:attrColor forKey:NSForegroundColorAttributeName];
		
		// bold
		//[attrs setValue:[NSFont controlContentFontOfSize:10] forKey:NSFontAttributeName];
		[attrs setValue:[NSFont controlContentFontOfSize:10] forKey:NSFontAttributeName];
		
		//NSFont *originalFont = [NSFont controlContentFontOfSize:10];
		NSFont *originalFont = [NSFont controlContentFontOfSize:10];
		if ( originalFont ) {
			NSFont *boldedFont = [[NSFontManager sharedFontManager] convertFont:originalFont toHaveTrait:NSBoldFontMask];
			if ( boldedFont )
			{
				[attrs setValue:boldedFont forKey:NSFontAttributeName];
			}
		}
		
		// with a shadow
		/*
		NSShadow *textShadow = [[[NSShadow alloc] init] autorelease];
	
		[textShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.96 alpha:0.96]];
		[textShadow setShadowOffset:NSMakeSize(0,-1)];
		
		 [attrs setValue:textShadow forKey:NSShadowAttributeName];
		 */
	}
	
	else if ( [self isSelected] ) {
		// prepare the text in white.
        [attrs setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
		
		NSFont *originalFont = [attrs objectForKey:NSFontAttributeName];
		if ( originalFont ) {
			NSFont *boldedFont = [[NSFontManager sharedFontManager] convertFont:originalFont toHaveTrait:NSBoldFontMask];
			if ( boldedFont )
				[attrs setValue:boldedFont forKey:NSFontAttributeName];
		}
		
    } 
	else {
		// prepare the text in black.
        [attrs setValue:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	}
	
	
	// prepare the string that describes the count
	//if ( label && count != 0 )
	//{
	//	NSString *countString = [NSString stringWithFormat:@"%i",count];
	//}
	
	// center the text and take into account the required inset
	inset.origin.x += 2;
	inset.size.width -= 6;
	
	inset.origin.x += additionalIndent;
	inset.size.width -= additionalIndent;
	
	textHeight = [[self stringValue] sizeWithAttributes:attrs].height;
	inset.origin.y = inset.origin.y + (inset.size.height/2 - textHeight/2);
	inset.size.height = textHeight;
	
	//
	// do the drawing
	
	//[controlView lockFocus];
	[[self stringValue] drawInRect:inset withAttributes:attrs];
	//[controlView unlockFocus];
	
	// draw the rank
	if ( rank != 0 ) {
		
		float delta = ( maxRank - minRank );
		if ( delta == 0 ) delta = 0.000001;
		
		float rankPercent = ( rank - minRank ) / delta;
		float distance = ( inset.size.width * rankPercent );
		
		NSRect rankRect = NSMakeRect(	inset.origin.x, 
										inset.origin.y + inset.size.height + 1,
										distance, 5);
		
		NSColor *gradientStart, *gradientEnd;
		
		gradientStart = [NSColor colorWithCalibratedRed:195.0/255.0 green:195.0/255.0 blue:195.0/255.0 alpha:1.0];
		gradientEnd = [NSColor colorWithCalibratedRed:161.0/255.0 green:161.0/255.0 blue:161.0/255.0 alpha:1.0];
			
		NSRect top, bottom;
		NSDivideRect(rankRect, &top, &bottom, rankRect.size.height/2, NSMinYEdge);
		top.size.height++;
		
		NSBezierPath *clipPath = [NSBezierPath bezierPath];
		
		NSInteger i;
		for ( i = 1; i < distance; i+=2 )
		{
			[clipPath moveToPoint:NSMakePoint(rankRect.origin.x+i, rankRect.origin.y)];
			[clipPath lineToPoint:NSMakePoint(rankRect.origin.x+i, rankRect.origin.y+rankRect.size.height)];
		}
		
		[[NSBezierPath bezierPathWithRect:top] linearGradientFillWithStartColor:gradientStart endColor:gradientEnd];
		[[NSBezierPath bezierPathWithRect:bottom] linearGradientFillWithStartColor:gradientEnd endColor:gradientStart];
		
		NSGraphicsContext *context = [NSGraphicsContext currentContext];
		[context saveGraphicsState];
		[context setShouldAntialias:NO];
		
		[[NSColor colorWithCalibratedWhite:1.0 alpha:0.3] set];
		[clipPath setLineWidth:1.0];
		[clipPath stroke];
		
		[context restoreGraphicsState];

	}
}

#pragma mark -

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	return nil;
}

/*
- (NSColor*) textColor {
	
	//if ( [self isHighlighted] )
	//	return [NSColor whiteColor];
	//else
		return [super textColor];
	
}
*/


@end
