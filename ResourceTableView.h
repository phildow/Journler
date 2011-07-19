//
//  ResourceTableView.h
//  Journler
//
//  Created by Philip Dow on 10/26/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ResourceTableView : NSOutlineView {
	
	IBOutlet NSTableColumn *titleColumn;
	
	NSTimeInterval	_searchInterval;
	NSMutableString *_searchString;
	
	NSInteger _shortcutRow;
}

- (NSTableColumn*) titleColumn;
- (IBAction) copy:(id)sender;

- (NSColor*) highlightColorForOpenShorcut;
- (void) _drawSelectionInRect:(NSRect)aRect highlight:(BOOL)highlight;

@end

@interface NSObject (ResourceTableViewDelegate)

// the delegate should return yes if it handles this action
- (BOOL) resourceTable:(ResourceTableView*)aResourceTable didSelectRowAlreadySelected:(NSInteger)aRow event:(NSEvent*)mouseEvent;

@end