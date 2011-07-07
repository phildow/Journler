//
//  IndexTreeController.h
//  Journler
//
//  Created by Philip Dow on 2/6/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IndexTreeController : NSTreeController {
	
	IBOutlet NSOutlineView *outlineView;
	
	NSPredicate *filterPredicate;
	NSArrayController *arrayController;
	
	NSArray *actualContent;
	NSArray *originalContent;
	
	BOOL ignoreNewSelection;
}

- (BOOL) ignoreNewSelection;
- (void) setIgnoreNewSelection:(BOOL)ignore;

@end
