//
//  GenericMediaController.h
//  Journler
//
//  Created by Philip Dow on 6/17/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JournlerMediaContentController.h"
#import <SproutedInterface/SproutedInterface.h>

@interface GenericMediaController : JournlerMediaContentController {
	IBOutlet NSView *previewPlaceholder;
	
	PDFileInfoView *infoView;
	NSView *previewView;
	
	BOOL usesQuickLook;
}

- (BOOL) usesQuickLook;
- (void) setUsesQuickLook:(BOOL)ql;

- (void) _showQLPreviewForURL:(NSURL*)url;
- (void) _showFileInfoForURL:(NSURL*)url;

@end
