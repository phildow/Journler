//
//  WebArchive+PDWebArchiveAdditions.h
//  Journler
//
//  Created by Philip Dow on 6/1/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface PDWebArchive : WebArchive {
	BOOL _finished_loading;
}

- (NSString*) stringValue;

@end

/*
@interface NSView (WebArchiveExtras)

- (NSString*) string;

@end
*/