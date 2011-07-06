/* CollectionsSourceList */

#import <Cocoa/Cocoa.h>

@interface CollectionsSourceList : NSOutlineView
{
	id							_revealingObject;
	BOOL						_revealingCollections;
	
	NSTimeInterval	_searchInterval;
	NSMutableString *_searchString;
}

- (NSArray*) stateArray;
- (void) restoreStateFromArray:(NSArray*)anArray;

- (IBAction) copy:(id)sender;

- (void) _drawSelectionInRect:(NSRect)aRect highlight:(BOOL)highlight;

@end

@interface NSObject (CollectionsSourceListDelegate)

// the delegate should return yes if it handles this action
- (BOOL) sourceList:(CollectionsSourceList*)aSourceList didSelectRowAlreadySelected:(int)aRow event:(NSEvent*)mouseEvent;

@end