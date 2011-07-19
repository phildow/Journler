//
//  ImageTextAndRankCell.h
//  Journler XD Lite
//
//  Created by Philip Dow on 9/13/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ImageTextAndRankCell : NSTextFieldCell {
	
	float minRank, maxRank, rank;
	NSInteger additionalIndent;
	
	NSInteger count;
	BOOL label;
	BOOL selected;
	
	BOOL capTop;
	BOOL capBottom;
	
	NSSize	imageSize;
    NSImage	*image;	
	NSMutableParagraphStyle	*_paragraph;
	
	NSImageCell *imageCell;
}

- (void) setCapTop:(BOOL)top capBottom:(BOOL)bottom;

- (BOOL) label;
- (void) setLabel:(BOOL)isLabel;

- (float) minRank;
- (void) setMinRank:(float)value;

- (float) maxRank;
- (void) setMaxRank:(float)value;

- (NSInteger) additionalIndent;
- (void) setAdditionalIndent:(NSInteger)value;

- (BOOL) isSelected;
- (void) setSelected:(BOOL)isSelected;

- (float) rank;
- (void) setRank:(float)value;

- (NSInteger) count;
- (void) setCount:(NSInteger)value;

- (NSSize) imageSize;
- (void) setImageSize:(NSSize)aSize;

- (void)setImage:(NSImage *)anImage;
- (NSImage *)image;

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (NSSize)cellSize;

@end
