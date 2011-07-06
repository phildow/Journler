//
//  PDButtonColorWellCell.h
//  Journler
//
//  Created by Philip Dow on 1/7/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PDButtonColorWellCell : NSButtonCell {
	
	NSColor *_color;
	
}

- (NSColor*) color;
- (void) setColor:(NSColor*)color;

@end
