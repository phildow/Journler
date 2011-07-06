//
//  PDDocument_PDCategory.h
//  SproutedUtilities
//
//  Created by Philip Dow on 1/19/07.
//  Copyright 2007 Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface PDFDocument (PDCategory )

- (NSImage*) thumbnailForPage:(unsigned int)index size:(float)edge;
- (NSImage*) efficientThumbnailForPage:(unsigned int)index size:(float)edge;

@end
