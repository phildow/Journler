//
//  IndexArrayController.h
//  Journler
//
//  Created by Philip Dow on 2/8/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IndexTreeController;

@interface IndexArrayController : NSArrayController {
	IBOutlet NSOutlineView *outlineView;
	IBOutlet IndexTreeController *treeController;
}

@end
