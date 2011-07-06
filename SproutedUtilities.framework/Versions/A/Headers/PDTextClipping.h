//
//  PDTextClipping.h
//  Journler
//
//  Created by Phil Dow on 3/17/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PDTextClipping : NSObject {
	
	id textRepresentation;
	BOOL isRichText;
}

- (id) initWithContentsOfFile:(NSString*)filename;

- (BOOL) isRichText;

- (NSString*) plainTextRepresentation;
- (NSAttributedString*) richTextRepresentation;

@end
