//
//  ImageAndTextCell.h
//
//  Copyright (c) 2001-2002, Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ImageAndTextCell : NSTextFieldCell {
	
	BOOL separatorCell;
	BOOL updating;
	
	BOOL dim;
	BOOL selected;
	BOOL boldsWhenSelected;
	int contentCount;
	NSSize	imageSize;
    NSImage	*image;	
	NSMutableParagraphStyle	*_paragraph;
}

- (BOOL) dim;
- (void) setDim:(BOOL)isDim;

- (BOOL) updating;
- (void) setUpdating:(BOOL)isUpdating;

- (BOOL) isSeparatorCell;
- (void) setIsSeparatorCell:(BOOL)separator;

- (BOOL) isSelected;
- (void) setSelected:(BOOL)isSelected;

- (BOOL) boldsWhenSelected;
- (void) setBoldsWhenSelected:(BOOL)doesBold;

- (int) contentCount;
- (void) setContentCount:(int)count;

- (NSSize) imageSize;
- (void) setImageSize:(NSSize)aSize;

- (NSImage *)image;
- (void)setImage:(NSImage *)anImage;

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (NSSize)cellSize;

@end
