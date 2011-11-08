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

// 10.6 / 10.7 changes
#import <Quartz/Quartz.h> // QuickLookUI

@class CHEmbeddedMediaQuicklookObject;

@interface GenericMediaController : JournlerMediaContentController {
	IBOutlet NSView *previewPlaceholder;
	
	PDFileInfoView *infoView;
	QLPreviewView *previewView;
	
    CHEmbeddedMediaQuicklookObject *quicklookItem;
	BOOL usesQuickLook;
}

@property(copy) CHEmbeddedMediaQuicklookObject *quicklookItem;

- (BOOL) usesQuickLook;
- (void) setUsesQuickLook:(BOOL)ql;

- (void) _showQLPreviewForURL:(NSURL*)url;
- (void) _showFileInfoForURL:(NSURL*)url;

@end
