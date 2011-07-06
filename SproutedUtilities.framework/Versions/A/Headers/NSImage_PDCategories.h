//
//  NSImage_PDCategories.h
//  SproutedUtilities
//
//  Created by Philip Dow on 9/9/06.
//  Copyright 2006 Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSImage (PDCategories)

+ (NSImage*) imageByReferencingImageNamed:(NSString*)imageName;

+ (BOOL) canInitWithFile:(NSString*)path;
+ (NSImage*) iconWithContentsOfFile:(NSString*)path edgeSize:(float)size inset:(float)padding;

+ (NSImage *) imageFromCIImage:(CIImage *)ciImage;
+ (CIImage *) CIImageFromImage:(NSImage*)anImage;

- (NSImage *) reflectedImage:(float)fraction;
- (NSImage*) imageWithWidth:(float)width height:(float)height;
- (NSImage*) imageWithWidth:(float)width height:(float)height inset:(float)inset;

- (NSData*) pngData;
- (NSAttributedString*) attributedString:(int)qual maxWidth:(int)mWidth;

@end
