//
//  IndexOutlineView.h
//  Journler
//
//  Created by Phil Dow on 2/7/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IndexColumn;

@interface IndexOutlineView : NSOutlineView {

	IBOutlet IndexColumn *indexColumn;
	IBOutlet NSArrayController *rootController;

	NSTimeInterval	_searchInterval;
	NSMutableString *_searchString;
}

- (IndexColumn*) indexColumn;
- (void) _drawSelectionInRect:(NSRect)aRect highlight:(BOOL)highlight;

@end

@interface IndexOutlineView (AdditionalUISupport)

- (NSImage*) resizedImage:(NSImage*)anImage width:(float)width height:(float)height inset:(float)inset;

@end

@interface NSObject (IndexOutlineViewDelegate)

- (void) indexOutlineView:(IndexOutlineView*)anOutlineView deleteSelectedRows:(NSIndexSet*)selectedRows;
- (void) outlineViewDidBecomeFirstResponder:(IndexOutlineView*)anOutlineView;

@end