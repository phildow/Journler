//
//  WordDocumentController.h
//  Journler
//
//  Created by Phil Dow on 2/6/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JournlerMediaContentController.h"

@class IndexServerTextView;

@interface WordDocumentController : JournlerMediaContentController {
	
	IBOutlet IndexServerTextView *textView;

	float		lastScale;
}

- (float) lastScale;
- (void) setLastScale:(float)scaleValue;

@end
