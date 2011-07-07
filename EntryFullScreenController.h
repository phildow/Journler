//
//  EntryFullScreenController.h
//  Journler
//
//  Created by Philip Dow on 3/27/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FullScreenController.h"
#import "EntryWindowController.h"

@interface EntryFullScreenController : EntryWindowController {

JournlerWindowController *callingController;

}

+ (void) enableFullscreenMode;
- (BOOL) isFullScreenController;

- (JournlerWindowController*) callingController;
- (void) setCallingController:(JournlerWindowController*)aWindowController;

@end
