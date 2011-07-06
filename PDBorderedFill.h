//
//  PDBorderedFill.h
//  Cocoa Journler
//
//  Created by Philip Dow on 12/15/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PDBorderedFill : NSView {
	
	int			_borders[4];
	BOOL		_bordered;
	
	NSColor		*_fill;
	NSColor		*_border;
	
}

- (int*) borders;
- (void) setBorders:(int*)sides;

- (BOOL) bordered;
- (void) setBordered:(BOOL)flag;

- (NSColor*) fill;
- (void) setFill:(NSColor*)fillColor;

- (NSColor*) border;
- (void) setBorder:(NSColor*)borderColor;

@end
