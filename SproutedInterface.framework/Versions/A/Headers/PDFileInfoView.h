//
//  PDFileInfoView.h
//  Journler
//
//  Created by Phil Dow on 6/17/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef UInt32 PDFileInfoAlignment;
enum PDInfoAlignment {
	PDFileInfoAlignLeft = 0,
	PDFileInfoAlignRight = 1
};


@interface PDFileInfoView : NSView {
	NSURL *url;
	NSImageCell *cell;
	PDFileInfoAlignment viewAlignment;
}

- (NSURL*) url;
- (void) setURL:(NSURL*)aURL;

- (void) _drawInfoForFile;

@end
