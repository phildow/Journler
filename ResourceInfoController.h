//
//  ResourceInfoController.h
//  Journler
//
//  Created by Phil Dow on 1/21/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


#import "ResourceInfoView.h"
@class ResourceHUDWindow;
@class JournlerResource;

@interface ResourceInfoController : NSWindowController {
	
	IBOutlet ResourceInfoView		*infoView;
}

- (id) initWithResource:(JournlerResource*)aResource alignment:(ResourceInfoAlignment)viewAlignment;

- (JournlerResource*) resource;
- (void) setResource:(JournlerResource*)aResource;

- (ResourceInfoAlignment) viewAlignment;
- (void) setViewAlignment:(ResourceInfoAlignment)alignment;


@end
