//
//  ResourceInfoView.h
//  Journler
//
//  Created by Philip Dow on 1/20/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef UInt32 ResourceInfoAlignment;
enum ResourceAlignment {
	ResourceInfoAlignLeft = 0,
	ResourceInfoAlignRight = 1
};

#import <SproutedInterface/SproutedInterface.h>

@class JournlerResource;

@interface ResourceInfoView : NSView {
	
	NSImageCell *cell;
	JournlerResource *resource;
	ResourceInfoAlignment viewAlignment;
}

- (ResourceInfoAlignment) viewAlignment;
- (void) setViewAlignment:(ResourceInfoAlignment)alignment;

- (JournlerResource*) resource;
- (void) setResource:(JournlerResource*)aResource;

- (void) _drawInfoForFile;
- (void) _drawInfoForABRecord;
- (void) _drawInfoForURL;
- (void) _drawInfoForJournlerObject;

@end
