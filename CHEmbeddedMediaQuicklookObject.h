//
//  CHEmbeddedMediaQuicklookObject.h
//  Per Se
//
//  Created by Philip Dow on 1/13/11.
//  Copyright 2011 Sprouted. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface CHEmbeddedMediaQuicklookObject : NSObject <QLPreviewItem> {
	
	NSURL *previewItemURL;
	NSString *previewItemTitle;
}

@property(readonly) NSURL *previewItemURL;
@property(readonly) NSString *previewItemTitle;

- (id) initWithURL:(NSURL*)url title:(NSString*)title;

@end
