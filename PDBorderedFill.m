//
//  PDBorderedFill.m
//  Cocoa Journler
//
//  Created by Philip Dow on 12/15/05.
//  Copyright 2005 Sprouted, Philip Dow. All rights reserved.
//

#import "PDBorderedFill.h"


@implementation PDBorderedFill

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		_fill = [[NSColor whiteColor] retain];
		_border = [[NSColor colorWithCalibratedRed:157.0/255.0 green:157.0/255.0 blue:157.0/255.0 alpha:1.0] retain];
		
		_borders[0] = 1;	// top
		_borders[1] = 1;	// right
		_borders[2] = 1;	// bottom
		_borders[3] = 1;	// left
		
    }
    return self;
}

- (void) dealloc {
	
	[_fill release];
		_fill = nil;
	
	[_border release];
		_border = nil;
	
	[super dealloc];
	
}

#pragma mark -

- (NSInteger*) borders { return _borders; }

- (void) setBorders:(NSInteger*)sides {
	_borders[0] = sides[0];
	_borders[1] = sides[1];
	_borders[2] = sides[2];
	_borders[3] = sides[3];
}

- (BOOL) bordered { return _bordered; }

- (void) setBordered:(BOOL)flag { _bordered = flag; }

- (NSColor*) fill { return _fill; }

- (void) setFill:(NSColor*)fillColor {
	if ( _fill != fillColor ) {
		[_fill release];
		_fill = [fillColor copyWithZone:[self zone]];
	}
}

- (NSColor*) border { return _border; }

- (void) setBorder:(NSColor*)borderColor {
	if ( _border != borderColor ) {
		[_border release];
		_border = [borderColor copyWithZone:[self zone]];
	}
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
	
	// Draw a frame and fill in white
	NSRect bds = [self bounds];
	
	//
	//then fills it the requested color
	[[self fill] set];
	if ( [self bordered] )
		NSRectFill(NSMakeRect( 0, 0, bds.size.width, bds.size.height));
	else
		NSRectFill(bds);
	
	//
	//draws an outline around the guy, just like with other views
	if ( [self bordered] ) {
		NSBezierPath *borderPath = [NSBezierPath bezierPath];
		if ( _borders[0] ) {
			[borderPath moveToPoint:NSMakePoint(0, bds.size.height)];
			[borderPath lineToPoint:NSMakePoint(bds.size.width, bds.size.height)];
		}
		if ( _borders[1] ) {
			[borderPath moveToPoint:NSMakePoint(bds.size.width, bds.size.height)];
			[borderPath lineToPoint:NSMakePoint(bds.size.width, 0)];
		}
		if ( _borders[2] ) {
			[borderPath moveToPoint:NSMakePoint(bds.size.width, 0)];
			[borderPath lineToPoint:NSMakePoint(0, 0)];
		}
		if ( _borders[3] ) {
			[borderPath moveToPoint:NSMakePoint(0, 0)];
			[borderPath lineToPoint:NSMakePoint(0, bds.size.height)];
		}

		[[self border] set ];
		[borderPath stroke];
	}
	
}

@end
