//
//  PDPersonPropertyCell.m
//  PeoplePickerTest
//
//  Created by Philip Dow on 10/18/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "PDPersonPropertyCell.h"

#import <SproutedUtilities/SproutedUtilities.h>
//#import "NSBezierPath_AMAdditons.h"

#define kPadding 5
#define kDefaultMargin 80

@implementation PDPersonPropertyCell

- (id) init {
	return [self initTextCell:[NSString string]];
}

- (id)initTextCell:(NSString *)aString {
	if ( self = [super initTextCell:aString] ) {
	
		label = [[NSString alloc] init];
		content = [[NSString alloc] init];
		
		NSMutableParagraphStyle *paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopyWithZone:[self zone]] autorelease];
		[paragraphStyle setAlignment:NSRightTextAlignment];
		[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingMiddle];
		
		labelAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
				paragraphStyle, NSParagraphStyleAttributeName,
				[NSColor colorWithCalibratedWhite:0.5 alpha:1.0], NSForegroundColorAttributeName,
				[NSFont boldSystemFontOfSize:12], NSFontAttributeName, 
				[NSNumber numberWithFloat:2.0], NSBaselineOffsetAttributeName,nil];
		
		labelHighlightedAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
				paragraphStyle, NSParagraphStyleAttributeName,
				[NSColor colorWithCalibratedWhite:1.0 alpha:1.0], NSForegroundColorAttributeName,
				[NSFont boldSystemFontOfSize:12], NSFontAttributeName,
				[NSNumber numberWithFloat:2.0], NSBaselineOffsetAttributeName,nil];
		
		NSMutableParagraphStyle *contentStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopyWithZone:[self zone]] autorelease];
		[contentStyle setLineBreakMode:NSLineBreakByWordWrapping];
		
		contentAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
				contentStyle, NSParagraphStyleAttributeName,
				[NSColor blackColor], NSForegroundColorAttributeName,
				[NSFont systemFontOfSize:12], NSFontAttributeName,
				[NSNumber numberWithFloat:2.0], NSBaselineOffsetAttributeName,nil];
				
		margin = kDefaultMargin;
		
		
		textStorage = [[NSTextStorage alloc] initWithString:[NSString string]];
		textContainer = [[NSTextContainer alloc] initWithContainerSize: NSMakeSize(FLT_MAX, FLT_MAX)];
		layoutManager = [[NSLayoutManager alloc] init];
	
		[layoutManager addTextContainer:textContainer];
		[textStorage addLayoutManager:layoutManager];
		
		[textContainer setLineFragmentPadding:0.0];
		
	}
	return self;
}

- (void) dealloc {
	
	[property release];
	property = nil;
	
	[label release];
	label = nil;
	
	[content release];
	content = nil;
	
	[textStorage release];
	textStorage = nil;
	
	[textContainer release];
	textContainer = nil;
	
	[layoutManager release];
	layoutManager = nil;
	
	[labelAttributes release];
	labelAttributes= nil;
	
	[labelHighlightedAttributes release];
	labelHighlightedAttributes = nil;
	
	[contentAttributes release];
	contentAttributes = nil;
	
	[super dealloc];
}

#pragma mark -

- (float) margin {
	return margin;
}

- (void) setMargin:(float)value {
	margin = value;
}

- (NSString*) property {
	return property;
}

- (void) setProperty:(NSString*)key {
	if ( property != key ) {
		[property release];
		property = [key copyWithZone:[self zone]];
	}
}

- (NSString*) label {
	return label;
}

- (void) setLabel:(NSString*)aString {
	if ( label != aString ) {
		[label release];
		label = [aString copyWithZone:[self zone]];
	}
}

- (NSString*) content {
	return content;
}

- (void) setContent:(NSString*)aString {
	if ( content != aString ) {
		[content release];
		content = [aString copyWithZone:[self zone]];
		
		// automatically clear the attributed content value
		[self setAttributedContent:nil];
	}
}

#pragma mark -

//- (NSAttributedString*) attributedLabel;
//- (void) setAttributedLabel:(NSAttributedString*)anAttributedString;

- (NSAttributedString*) attributedContent {
	return attributedContent;
}

- (void) setAttributedContent:(NSAttributedString*)anAttributedString {
	if ( attributedContent != anAttributedString ) {
		[attributedContent release];
		attributedContent = [anAttributedString copyWithZone:[self zone]];
	}
}

#pragma mark -

- (NSSize) cellSizeWithWidth:(float)maxWidth {	
	return [self cellSizeForBounds:NSMakeRect(0,0,maxWidth,0)];
}

#pragma mark -

- (NSSize)cellSizeForBounds:(NSRect)aRect {
	
	NSRect labelBounds = [self labelBoundsForCellFrame:aRect];
	NSRect contentBounds = [self contentBoundsForCellFrame:aRect];
	
	NSSize cellSize = NSMakeSize( aRect.size.width, 
			labelBounds.size.height > contentBounds.size.height ? labelBounds.size.height : contentBounds.size.height );
	return cellSize;
	
}

//- (NSRect)titleRectForBounds:(NSRect)theRect {
//	return [self contentBoundsForCellFrame:theRect];
//}

- (NSRect) labelBoundsForCellFrame:(NSRect)cellFrame {
	
	[textContainer setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
	[textStorage setAttributedString:[[[NSAttributedString alloc] initWithString:label attributes:labelAttributes] autorelease]];
		
	(void) [layoutManager glyphRangeForTextContainer:textContainer];
	NSSize labelSize = [layoutManager usedRectForTextContainer:textContainer].size;

	NSRect labelBounds;
	labelBounds = NSMakeRect( cellFrame.origin.x + margin - kPadding - labelSize.width, cellFrame.origin.y,
								labelSize.width, labelSize.height );
								
	return labelBounds;
}

- (NSRect) contentBoundsForCellFrame:(NSRect)cellFrame {
	
	//#warning that 10 difference goes here
	
	NSSize contentSize;
	NSRect contentBounds;
	float maxWidth = cellFrame.size.width-cellFrame.origin.x-margin;
	
	[textContainer setContainerSize:NSMakeSize(maxWidth, FLT_MAX)];
	[textStorage setAttributedString:[[[NSAttributedString alloc] initWithString:content attributes:contentAttributes] autorelease]];
	
	(void) [layoutManager glyphRangeForTextContainer:textContainer];
	contentSize = [layoutManager usedRectForTextContainer:textContainer].size;
	
	contentBounds = NSMakeRect(cellFrame.origin.x + margin, cellFrame.origin.y, contentSize.width, contentSize.height);
	return contentBounds;
	
}

#pragma mark -

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	[self highlight:[self isHighlighted] withFrame:cellFrame inView:controlView];
}

- (void)highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	
	if ( flag ) {
	
		NSRect contentBounds = [self contentBoundsForCellFrame:cellFrame];
		contentBounds.size.height--;
		
		NSRect contentLeft = NSMakeRect(contentBounds.origin.x-2.0, contentBounds.origin.y, 6.0, contentBounds.size.height);
		NSRect contentRight = NSMakeRect(contentBounds.origin.x-2.0, contentBounds.origin.y, contentBounds.size.width+2.0+6.0, contentBounds.size.height);
		
		[[NSColor colorWithCalibratedWhite:0.9 alpha:1.0] set];
		
		[[NSBezierPath bezierPathWithRoundedRect: contentRight cornerRadius:7.5] fill];
		[[NSBezierPath bezierPathWithRect:contentLeft] fill];
	
		
		NSRect labelBounds = [self labelBoundsForCellFrame:cellFrame];
		labelBounds.size.height--;
		
		NSRect labelLeft = NSMakeRect(labelBounds.origin.x-6.0, labelBounds.origin.y, labelBounds.size.width+8.0, labelBounds.size.height);
		NSRect labelRight = NSMakeRect(labelBounds.origin.x + labelBounds.size.width - 6.0, labelBounds.origin.y, 8.0, labelBounds.size.height);
		
		[[NSColor colorWithCalibratedWhite:0.7 alpha:1.0] set];
		
		[[NSBezierPath bezierPathWithRoundedRect: labelLeft cornerRadius:7.5] fill];
		[[NSBezierPath bezierPathWithRect:labelRight] fill];
	}
	
	[self setHighlighted:flag];
	[self drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	
	[textContainer setContainerSize:NSMakeSize(margin-kPadding, FLT_MAX)];
	
	if ( [self isHighlighted] )
		[textStorage setAttributedString:[[[NSAttributedString alloc] initWithString:label attributes:labelHighlightedAttributes] autorelease]];
	else
		[textStorage setAttributedString:[[[NSAttributedString alloc] initWithString:label attributes:labelAttributes] autorelease]];
		
	NSRange range = [layoutManager glyphRangeForTextContainer:textContainer];
	
	[layoutManager drawBackgroundForGlyphRange:range atPoint:NSMakePoint(cellFrame.origin.x, cellFrame.origin.y)];
	[layoutManager drawGlyphsForGlyphRange:range atPoint:NSMakePoint(cellFrame.origin.x, cellFrame.origin.y)];
		
	float maxWidth = cellFrame.size.width - cellFrame.origin.x - margin;
	
	if ( attributedContent == nil ) {
		
		[textContainer setContainerSize:NSMakeSize(maxWidth, FLT_MAX)];
		[textStorage setAttributedString:[[[NSAttributedString alloc] initWithString:content attributes:contentAttributes] autorelease]];
		
		NSRange range = [layoutManager glyphRangeForTextContainer:textContainer];
		
		[layoutManager drawBackgroundForGlyphRange:range atPoint:NSMakePoint(cellFrame.origin.x + margin, cellFrame.origin.y)];
		[layoutManager drawGlyphsForGlyphRange:range atPoint:NSMakePoint(cellFrame.origin.x + margin, cellFrame.origin.y)];
		
	}
	else {
		
		[textContainer setContainerSize:NSMakeSize(maxWidth, FLT_MAX)];
		[textStorage setAttributedString:attributedContent];
		
		NSRange range = [layoutManager glyphRangeForTextContainer:textContainer];
		
		[layoutManager drawBackgroundForGlyphRange:range atPoint:NSMakePoint(cellFrame.origin.x + margin, cellFrame.origin.y)];
		[layoutManager drawGlyphsForGlyphRange:range atPoint:NSMakePoint(cellFrame.origin.x + margin, cellFrame.origin.y)];
		
	}
	
}

#pragma mark -

+ (NSFocusRingType)defaultFocusRingType {
	return NSFocusRingTypeNone;
}

@end
