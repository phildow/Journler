//
//  LexiconFullScreenController.h
//  Journler
//
//  Created by Philip Dow on 3/27/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FullScreenController.h"
#import "TermIndexWindowController.h"

@interface LexiconFullScreenController : TermIndexWindowController {

JournlerWindowController *callingController;

}

+ (void) enableFullscreenMode;
- (BOOL) isFullScreenController;

- (JournlerWindowController*) callingController;
- (void) setCallingController:(JournlerWindowController*)aWindowController;
@end
