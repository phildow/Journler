//
//  NSParagraphStyle_PDAdditions.h
//  SproutedUtilities
//
//  Created by Philip Dow on 2/3/07.
//  Copyright 2007 Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSParagraphStyle (PDAdditions)

+ (NSParagraphStyle*) defaultParagraphStyleWithLineBreakMode:(NSLineBreakMode)lineBreak;
+ (NSParagraphStyle*) defaultParagraphStyleWithAlignment:(NSTextAlignment)textAlignment;

@end
