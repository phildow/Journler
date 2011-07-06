//
//  PDFavorite.h
//  Journler
//
//  Created by Philip Dow on 3/17/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define PDFavoriteNoHover		0
#define PDFavoriteHover			1
#define PDFavoriteMouseDown		2

@interface PDFavorite : NSView {
	
	NSString			*_title;
	//NSAttributedString	*_attributedTitle;
	id					_identifier;
	//NSArray				*_subElements;
	
	NSSize				_idealSize;
	int					_state;
	
	int label;
	BOOL drawsLabel;
}

- (id) initWithFrame:(NSRect)frame title:(NSString*)title identifier:(id)identifier;

- (NSString*) title;
- (void) setTitle:(NSString*)title;

//- (NSAttributedString*) attributedTitle;
//- (void) setAttributedTitle:(NSAttributedString*)title;

- (id) identifier;
- (void) setIdentifier:(id)identifier;

- (int) state;
- (void) setState:(int)state;

- (int) label;
- (void) setLabel:(int)aLabel;

- (BOOL) drawsLabel;
- (void) setDrawsLabel:(BOOL)draws;

- (NSAttributedString*) generateAttributedTitle:(NSString*)title;
- (NSAttributedString*) generateHoverAttributedTitle:(NSString*)title;
- (NSSize) idealSize;
- (NSImage*) image;

- (void) _drawLabel:(NSRect)rect;

@end
