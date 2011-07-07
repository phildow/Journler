//
//  BlocAccountCell.h
//  Journler
//
//  Created by Philip Dow on 4/3/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BlogAccountCell : NSTextFieldCell {
	
	NSSize	imageSize;
    NSImage	*image;	
	NSMutableParagraphStyle	*_paragraph;
	NSString *blogType;
	BOOL selected;
}

- (NSSize) imageSize;
- (void) setImageSize:(NSSize)aSize;

- (NSImage *)image;
- (void)setImage:(NSImage *)anImage;

- (NSString*) blogType;
- (void) setBlogType:(NSString*)aString;

- (BOOL) isSelected;
- (void) setSelected:(BOOL)isSelected;

@end
