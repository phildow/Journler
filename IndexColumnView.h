//
//  IndexColumnView.h
//  Journler
//
//  Created by Philip Dow on 2/7/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IndexColumn.h"

#define IndexColumnViewWillBeginResizing @"IndexColumnViewWillBeginResizing"
#define IndexColumnViewDidEndResizing @"IndexColumnViewDidEndResizing"

@interface IndexColumnView : NSView {
	IBOutlet NSView *dragView;
	IBOutlet IndexColumn *indexColumn;
}

- (IndexColumn*) indexColumn;

@end
