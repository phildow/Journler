//
//  JournalFullScreenController.h
//  Journler
//
//  Created by Phil Dow on 3/27/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FullScreenController.h"
#import "JournlerWindowController.h"

@interface JournalFullScreenController : JournalWindowController {

JournlerWindowController *callingController;

}

+ (void) enableFullscreenMode;
- (BOOL) isFullScreenController;

- (JournlerWindowController*) callingController;
- (void) setCallingController:(JournlerWindowController*)aWindowController;

@end