/* EntriesTableView */

#import <Cocoa/Cocoa.h>

#define EntriesTableViewDidBeginDragNotification	@"EntriesTableViewBeginDragNotification"
#define EntriesTableViewDidEndDragNotification		@"EntriesTableViewDidEndDragNotification"

@class JournlerEntry;
@class JournlerJournal;

@class DateSelectionController;

@interface EntriesTableView : NSTableView
{
	
	IBOutlet NSTableColumn *bloggedColumn;
	IBOutlet NSTableColumn *markColumn;
	IBOutlet NSTableColumn *labelColumn;
	IBOutlet NSTableColumn *rankColumn;
	IBOutlet NSTableColumn *attachmentColumn;
	
	NSMutableDictionary *allColumns;
	
	BOOL	_alternateForRevealDown;
	BOOL	_editingCategory;
	
	id _draggingObject;
	id _draggingObjects;
	
	NSTimeInterval	_searchInterval;
	NSMutableString *_searchString;
	
	BOOL drawsLabelBackground;
	NSInteger _shortcutRow;
	NSArray *_stateArray;
}

- (BOOL) editingCategory;

- (id) draggingObject;
- (void) setDraggingObject:(id)object;

- (id) draggingObjects;
- (void) setDraggingObjects:(id)objects;

- (BOOL) drawsLabelBackground;
- (void) setDrawsLabelBackground:(BOOL)draws;

- (NSArray*) stateArray;
- (void) setStateArray:(NSArray*)anArray;

- (void) restoreStateWithArray:(NSArray*)anArray;

- (IBAction) toggleDrawsLabelBackground:(id)sender;
- (IBAction) toggleUsesAlternatingRows:(id)sender;

- (NSColor*) highlightColorForOpenShorcut;

- (void) setColumnWithIdentifier:(id)identifier hidden:(BOOL)hide;
- (BOOL) columnWithIdentifierIsHidden:(id)identifier;

- (IBAction) copy:(id)sender;
- (IBAction) sizeToFit:(id)sender;

@end

@interface NSObject (EntriesTableViewDelegate)

// the delegate should return yes if it handles this action
- (BOOL) tableView:(EntriesTableView*)aTableView didSelectRowAlreadySelected:(int)aRow event:(NSEvent*)mouseEvent;

@end
