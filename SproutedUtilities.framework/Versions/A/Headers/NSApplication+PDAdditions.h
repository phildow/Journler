//
//  NSApplication+PDAdditions.h
//  SproutedUtilities
//
//  Created by Philip Dow on 9/10/07.
//  Copyright 2007 Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSApplication (PDAdditions)

- (NSWindowController*) singletonControllerWithClass:(Class)aClass;

@end
