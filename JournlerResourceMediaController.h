//
//  JournlerResourceMediaController.h
//  Journler
//
//  Created by Philip Dow on 10/29/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JournlerMediaContentController.h"

@class ResourceInfoView;

@interface JournlerResourceMediaController : JournlerMediaContentController {
	IBOutlet ResourceInfoView *infoView;
}

@end
