//
//  IndexColumn.h
//  Journler
//
//  Created by Philip Dow on 2/6/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define kIndexColumnSmallRowHeight 14
#define kIndexColumnLargeRowHeight 32
#define kIndexColumnMediumRowHeight 22

@class IndexNode;
@class IndexColumnView;
@class IndexTreeController;

@class PDGradientView;

@interface IndexColumn : NSObject {
	
	IBOutlet IndexColumnView *columnView;
	IBOutlet NSOutlineView *outlineView;
	IBOutlet NSTextField *titleField;
	IBOutlet NSSearchField *searchField;
	IBOutlet NSButton *searchCheck;
	
	IBOutlet NSTextField *minField;
	IBOutlet NSTextField *maxField;
	IBOutlet NSButton *countCheck;
	
	IBOutlet NSObjectController *ownerController;
	IBOutlet IndexTreeController *outlineController;
	IBOutlet NSArrayController *rootController;
	
	IBOutlet NSProgressIndicator *indicator;
	
	IBOutlet PDGradientView *footer;
	IBOutlet PDGradientView *header;
	
	id delegate;
	
	BOOL drawsIcon;
	BOOL showsCount;
	BOOL showsFrequency;
	
	NSString *title;
	NSString *headerTitle;
	NSString *countSuffix;
	NSPredicate *filterPredicate;
	
	int minCount;
	int maxCount;
	
	BOOL canDeleteContent;
	BOOL canFilterCount;
	BOOL canFilterTitle;
	
	BOOL countFilterEnabled;
	BOOL titleFilterEnabled;
}

- (IndexColumnView*) columnView;

- (IndexNode*) selectedObject;
- (NSArray*) selectedObjects;

- (NSArray*) content;
- (void) setContent:(NSArray*)content;

- (NSArray*) sortDescriptors;
- (void) setSortDescriptors:(NSArray*)anArray;

- (BOOL) allowsMultipleSelection;
- (void) setAllowsMultipleSelection:(BOOL)flag;

- (float) rowHeight;
- (void) setRowHeight:(float)height;

- (NSMenu*) menu;
- (void) setMenu:(NSMenu*)aMenu;

- (NSString*) title;
- (void) setTitle:(NSString*)aString;

- (NSString*) headerTitle;
- (void) setHeaderTitle:(NSString*)aString;

- (NSString*) countSuffix;
- (void) setCountSuffix:(NSString*)aString;

- (NSPredicate*) filterPredicate;
- (void) setFilterPredicate:(NSPredicate*)aPredicate;

- (BOOL) drawsIcon;
- (void) setDrawsIcon:(BOOL)draw;

- (BOOL) showsCount;
- (void) setShowsCount:(BOOL)show;

- (BOOL) showsFrequency;
- (void) setShowsFrequency:(BOOL)show;

- (id) delegate;
- (void) setDelegate:(id)anObject;

- (int) minCount;
- (void) setMinCount:(int)aCount;

- (int) maxCount;
- (void) setMaxCount:(int)aCount;

#pragma mark -

- (BOOL) canFilterCount;
- (void) setCanFilterCount:(BOOL)countFilters;

- (BOOL) canFilterTitle;
- (void) setCanFilterTitle:(BOOL)titleFilters;

- (BOOL) canDeleteContent;
- (void) setCanDeleteContent:(BOOL)canDelete;

#pragma mark -

- (BOOL) countFilterEnabled;
- (void) setCountFilterEnabled:(BOOL)enabled;

- (BOOL) titleFilterEnabled;
- (void) setTitleFilterEnabled:(BOOL)enabled;

#pragma mark -

- (void) ownerWillClose:(NSNotification*)aNotification;

- (BOOL) selectNode:(IndexNode*)aNode;
- (BOOL) scrollNodeToVisible:(IndexNode*)aNode;
- (BOOL) focusOutlineWithSelection:(BOOL)selectFirstNode;

- (void) determineCompoundPredicate;
- (IBAction) setCountRestriction:(id)sender;

@end

@interface NSObject (IndexColumnDelegate)

- (void) columnDidChangeSelection:(IndexColumn*)aColumn;
- (void) columnDidComeIntoFocus:(IndexColumn*)aColumn;
- (BOOL) indexColumn:(IndexColumn*)aColumn deleteSelectedRows:(NSIndexSet*)selectedRows nodes:(NSArray*)theNodes;

@end