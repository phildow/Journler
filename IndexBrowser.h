//
//  IndexBrowser.h
//  Journler
//
//  Created by Philip Dow on 2/6/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IndexNode;
@class IndexColumn;

@interface IndexBrowser : NSView {
	
	NSArray *columns;
	IndexColumn *focusedColumn;
	id delegate;
}

- (NSArray*) columns;
- (void) setColumns:(NSArray*)anArray;

- (id) delegate;
- (void) setDelegate:(id)anObject;

- (void) setInitialContent:(NSArray*)anArray;
- (void) setContentAtIndex:(NSDictionary*)aDictionary;
- (BOOL) setContent:(NSArray*)anArray forColumnAtIndex:(NSUInteger)index;

- (float) minWidth;

- (IBAction) addColumn:(id)sender;
- (IBAction) removeColumn:(id)sender;

- (IndexColumn*) focusedColumn;
- (NSArray*) focusedNodes;

- (void) columnFrameDidChange:(NSNotification*)aNotification;
- (void) columnWillResize:(NSNotification*)aNotification;
- (void) columnDidResize:(NSNotification*)aNotification;

@end

@interface NSObject (IndexBrowserDelegate)

// the represented object or selection in this methods is the selection in the column anIndex + 1
// both the represented object and the column index indicate items previous to those about to be displayed

// the selection will be nil and the represented object -1 if the browser is asking for information for the first column

- (NSArray*) browser:(IndexBrowser*)aBrowser contentForNodes:(NSArray*)selectedNodes atColumnIndex:(NSUInteger)anIndex;
- (void) browser:(IndexBrowser*)aBrowser column:(IndexColumn*)aColumn didChangeSelection:(NSArray*)selectedNode lastSelection:(IndexNode*)aNode;

- (NSString*) browser:(IndexBrowser*)aBrowser titleForNode:(IndexNode*)selectedNode atColumnIndex:(NSUInteger)anIndex;
- (NSString*) browser:(IndexBrowser*)aBrowser headerTitleForNode:(IndexNode*)selectedNode atColumnIndex:(NSUInteger)anIndex;

- (NSString*) browser:(IndexBrowser*)aBrowser countSuffixForNode:(IndexNode*)selectedNode atColumnIndex:(NSUInteger)anIndex;
- (NSArray*) browser:(IndexBrowser*)aBrowser sortDescriptorsForNode:(IndexNode*)selectedNode atColumnIndex:(NSUInteger)anIndex;

- (NSMenu*) browser:(IndexBrowser*)aBrowser contextMenuForNode:(IndexNode*)selectedNode atColumnIndex:(NSUInteger)anIndex;
- (float) browser:(IndexBrowser*)aBrowser rowHeightForNode:(IndexNode*)selectedNode atColumnIndex:(NSUInteger)anIndex;

- (BOOL) browser:(IndexBrowser*)aBrowser columnForNodeDrawsIcon:(IndexNode*)selectedNode atColumnIndex:(NSUInteger)anIndex;
- (BOOL) browser:(IndexBrowser*)aBrowser columnForNodeShowsCount:(IndexNode*)selectedNode atColumnIndex:(NSUInteger)anIndex;
- (BOOL) browser:(IndexBrowser*)aBrowser columnForNodeShowsFrequency:(IndexNode*)selectedNode atColumnIndex:(NSUInteger)anIndex;

- (BOOL) browser:(IndexBrowser*)aBrowser columnForNodeAllowsMultipleSelection:(IndexNode*)selectedNode atColumnIndex:(NSUInteger)anIndex;
- (BOOL) browser:(IndexBrowser*)aBrowser columnForNodeCanDeleteContent:(IndexNode*)selectedNode atColumnIndex:(NSUInteger)anIndex;

- (BOOL) browser:(IndexBrowser*)aBrowser columnForNodeFiltersCount:(IndexNode*)selectedNode atColumnIndex:(NSUInteger)anIndex;
- (BOOL) browser:(IndexBrowser*)aBrowser columnForNodeFiltersTitle:(IndexNode*)selectedNode atColumnIndex:(NSUInteger)anIndex;

/*
- (NSString*) browser:(IndexBrowser*)aBrowser titleForSelection:(id)anObject atColumnIndex:(NSUInteger)anIndex;
- (NSString*) browser:(IndexBrowser*)aBrowser countSuffixForSelection:(id)anObject atColumnIndex:(NSUInteger)anIndex;
- (NSArray*) browser:(IndexBrowser*)aBrowser sortDescriptorsForSelection:(id)anObject atColumnIndex:(NSUInteger)anIndex;

- (BOOL) browser:(IndexBrowser*)aBrowser columnForRepresentedObjectDrawsIcon:(id)anObject atColumnIndex:(NSUInteger)anIndex;
- (BOOL) browser:(IndexBrowser*)aBrowser columnForRepresentedObjectShowsCount:(id)anObject atColumnIndex:(NSUInteger)anIndex;
- (BOOL) browser:(IndexBrowser*)aBrowser columnForRepresentedObjectShowsFrequency:(id)anObject atColumnIndex:(NSUInteger)anIndex;
*/

@end