//
//  PDBorderedFill.h
//  Cocoa Journler
//
//  Created by Philip Dow on 12/15/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PDBorderedView : NSView {
	
	int			borders[4];
	BOOL		bordered;
	
	NSColor		*fillColor;
	NSColor		*borderColor;
	
}

- (int*) borders;
- (void) setBorders:(int*)sides;

- (BOOL) bordered;
- (void) setBordered:(BOOL)flag;

- (NSColor*) fillColor;
- (void) setFillColor:(NSColor*)aColor;

- (NSColor*) borderColor;
- (void) setBorderColor:(NSColor*)aColor;

@end
