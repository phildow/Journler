//
//  CHEmbeddedMediaQuicklookObject.m
//  Per Se
//
//  Created by Philip Dow on 1/13/11.
//  Copyright 2011 Sprouted. All rights reserved.
//

#import "CHEmbeddedMediaQuicklookObject.h"


@implementation CHEmbeddedMediaQuicklookObject

@synthesize previewItemURL;
@synthesize previewItemTitle;

- (id) initWithURL:(NSURL*)url title:(NSString*)title {
	if ( self = [super init] ) {
		previewItemTitle = [title copy];
		previewItemURL = [url copy];
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone {
	id object = [[[self class] alloc] initWithURL:self.previewItemURL title:self.previewItemTitle];
	return object;
}

- (void) dealloc {
	[previewItemURL release];
	[previewItemTitle release];
	[super dealloc];
}

@end
