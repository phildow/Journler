//
//  PDTextContentExtractor.h
//  TextContentExtractor
//
//  Created by Philip Dow on 5/10/07.
//  Copyright 2007 Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PDFileTextContentExtractor : NSObject {
	
	NSURL *url;
}

- (id) initWithURL:(NSURL*)aURL;
- (id) initWithFile:(NSString*)aPath;

- (NSString*) content;

@end
