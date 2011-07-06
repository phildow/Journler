//
//  PDButtonColorWell.h
//  Journler
//
//  Created by Philip Dow on 1/7/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PDButtonColorWell : NSButton {
	NSString *defaultsKey;
}

- (NSColor*) color;
- (void) setColor:(NSColor*)color;

- (NSString*) defaultsKey;
- (void) setDefaultsKey:(NSString*)aKey;

@end
