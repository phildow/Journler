//
//  NSColor_JournlerAdditions.h
//  SproutedUtilities
//
//  Created by Philip Dow on 1/9/07.
//  Copyright 2007 Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSColor (JournlerAdditions)

+ (NSColor*) colorForLabel:(int)label gradientEnd:(BOOL)end;
+ (NSColor*) darkColorForLabel:(int)label gradientEnd:(BOOL)end;

@end
