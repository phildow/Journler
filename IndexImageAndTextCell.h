//
//  IndexImageAndTextCell.h
//  Journler
//
//  Created by Philip Dow on 2/7/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IndexImageAndTextCell : NSTextFieldCell {
	
	NSSize	imageSize;
    NSImage	*image;	
	NSMutableParagraphStyle	*_paragraph;
	
}

- (NSSize) imageSize;
- (void) setImageSize:(NSSize)aSize;

- (NSImage *)image;
- (void)setImage:(NSImage *)anImage;

@end
