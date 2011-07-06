/* PDTabsView */

#import <Cocoa/Cocoa.h>

@class PDTabs;

@interface PDTabsView : NSView
{
	int availableWidth;
	int closeDown;
	
	int		_flashingTab;
	int		_malFlash;
	BOOL	_flashing;
	
	int		_tabToSelect;
	int		_targetTabForContext;
	BOOL	_amSwitching;
	
	BOOL	_tabFromTop;
	BOOL drawsShadow;
	
	NSPoint	_lastViewLoc;
	NSDate *_lastStillMoment;

	NSPopUpButton		*morePop;
	NSMenuItem			*popTitle;
	
	NSColor			*backgroundColor;
	
	int lastTabCount;
	int hoverIndex;
	int closeHoverIndex;
	int selectingIndex;
	NSMutableArray *titleTrackingRects;
	NSMutableArray *closeButtonTrackingRects;
	
	NSImage			*tabCloseFront;
	NSImage			*tabCloseFrontDown;
	
	NSImage			*tabCloseBack;
	NSImage			*tabCloseBackDown;
	
	NSImage			*backRollover;
	NSImage			*frontRollover;
	
	int borders[4];
	
	// Jourlner Additions --------------------------
	
	NSImage			*totalImage;
	
	IBOutlet id delegate;
	IBOutlet id dataSource;
	
	NSMenu *contextMenu;
}

- (id) delegate;
- (void) setDelegate:(id)anObject;

- (id) dataSource;
- (void) setDataSource:(id)anObject;

- (int) selectedTab;

#pragma mark -

- (BOOL) tabFromTop;
- (void) setTabFromTop:(BOOL)direction;

- (BOOL) drawsShadow;
- (void) setDrawsShadow:(BOOL)shadow;

- (int*) borders;
- (void) setBorders:(int*)theBorders;

- (int) availableWidth;
- (void) setAvailableWidth:(int)tabWidth;

- (NSColor*) backgroundColor;
- (void) setBackgroundColor:(NSColor*)color;

- (void) handleRegisterDragTypes;
- (void) handleDeregisterDragTypes;

- (void) flashTab:(int)tab;
- (void) flash:(NSTimer*)timer;

- (void) closeTab:(int)tab;
- (void) selectTab:(int)newSelection;

- (IBAction) selectTabByPop:(id)sender;

- (IBAction) newTab:(id)sender;
- (IBAction) closeTargetedTab:(id)sender;
- (IBAction) closeOtherTabs:(id)sender;

- (void) updateTrackingRects;
- (void) _updateTrackingRects:(NSNotification*)aNotification;
- (void) _toolbarDidChangeVisible:(NSNotification*)aNotification;

- (NSRect) frameOfTabAtIndex:(int)theIndex;
- (NSRect) frameOfCloseButtonAtIndex:(int)theIndex;

@end

@interface NSObject (PDTabsDataSource)
	
- (unsigned int) numberOfTabsInTabView:(PDTabsView*)aTabView;
- (unsigned int) selectedTabIndexInTabView:(PDTabsView*)aTabView;
- (NSString*) tabsView:(PDTabsView*)aTabView titleForTabAtIndex:(unsigned int)index;
	
@end

@interface NSObject (PDTabsDelegate)

- (void) tabsView:(PDTabsView*)aTabView removedTabAtIndex:(int)index;
- (void) tabsView:(PDTabsView*)aTabView selectedTabAtIndex:(int)index;

@end
