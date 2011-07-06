//
//  PDFavoritesBar.h
//  Journler
//
//  Created by Philip Dow on 3/17/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#define PDFavoritePboardType				@"PDFavoritePboardType"
#define PDFavoritesDidChangeNotification	@"PDFavoritesDidChangeNotification"

#define	PDFavoriteName	@"name"
#define PDFavoriteID	@"id"

#import <Cocoa/Cocoa.h>

@class PDFavorite;

@interface PDFavoritesBar : NSView {
	
	NSColor			*_backgroundColor;
	NSMutableArray	*_favorites;
	NSMutableArray	*_vFavorites;
	NSMutableArray	*_trackingRects;
	
	NSPopUpButton	*_morePop;
	NSMenuItem		*_popTitle;
	
	unsigned	_eventFavorite;
	BOOL		_titleSheet;
	
	id		delegate;
	id		_target;
	SEL		_action;
	
	NSMenu *contextMenu;
	
	BOOL drawsLabels;
}

- (NSColor*) backgroundColor;
- (void) setBackgroundColor:(NSColor*)color;

- (NSMutableArray*) favorites;
- (void) setFavorites:(NSArray*)favorites;

- (id) delegate;
- (void) setDelegate:(id)anObject;

- (id) target;
- (void) setTarget:(id)target;

- (SEL) action;
- (void) setAction:(SEL)action;

- (BOOL) drawsLabels;
- (void) setDrawsLabels:(BOOL)draws;

- (IBAction) toggleDrawsLabels:(id)sender;

- (void) sendEvent:(unsigned)sender;
- (NSDictionary*) eventFavorite;

- (BOOL) addFavorite:(NSDictionary*)aFavorite atIndex:(unsigned)loc requestTitle:(BOOL)showSheet;
- (void) removeFavoriteAtIndex:(unsigned)loc;

- (void) _generateFavoriteViews:(id)object;
- (void) _positionFavoriteViews:(id)object;

- (void) _initiateDragOperation:(unsigned)favoriteIndex location:(NSPoint)dragStart event:(NSEvent*)theEvent;

- (void) favoritesDidChange:(NSNotification*)aNotification;
- (void) _toolbarDidChangeVisible:(NSNotification*)aNotification;

- (NSString*) _titleFromTitleSheet:(NSString*)defaultTitle;
- (void) _okaySheet:(id)sender;
- (void) _cancelSheet:(id)sender;

- (PDFavorite*) favoriteWithIdentifier:(id)anIdentifier;
- (void) setLabel:(int)label forFavorite:(PDFavorite*)aFavorite;
- (void) rescanLabels;

- (NSRect) frameOfFavoriteAtIndex:(int)theIndex;

@end

@interface NSObject (FavoritesBarDelegate)

- (int) favoritesBar:(PDFavoritesBar*)aFavoritesBar labelOfItemWithIdentifier:(NSString*)anIdentifier;

@end
