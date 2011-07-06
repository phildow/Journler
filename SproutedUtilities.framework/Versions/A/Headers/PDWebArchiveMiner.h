//
//  PDWebArchiveMiner.h
//  WebArchiveWorker
//
//  Created by Philip Dow on 3/30/07.
//  Copyright 2007 Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/Webkit.h>

@interface PDWebArchiveMiner : NSObject {
	WebArchive *webArchive;
	NSArray *resources;
	NSString *plaintextRepresentation;
}

- (id) initWithWebArchive:(WebArchive*)aWebArchive;

+ (NSString*) plaintextRepresentationForWebArchive:(WebArchive*)aWebArchive;
+ (NSString*) plaintextRepresentationForResource:(WebResource*)aResource;
+ (NSArray*) resourcesForWebArchive:(WebArchive*)aWebArchive;

- (WebArchive*) webArchive;
- (void) setWebArchive:(WebArchive*)aWebArchive;

- (NSArray*) resources;
- (NSString*) plaintextRepresentation;

- (NSArray*) _resourcesForWebArchive:(WebArchive*)webArchive;

@end
