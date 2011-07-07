//
//  TextDocumentController.h
//  Journler
//
//  Created by Philip Dow on 2/6/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "JournlerMediaContentController.h"

@class IndexServerTextView;

@interface TextDocumentController : JournlerMediaContentController {
	
	IBOutlet IndexServerTextView *textView;
	
	float		lastScale;
}

- (float) lastScale;
- (void) setLastScale:(float)scaleValue;

@end
