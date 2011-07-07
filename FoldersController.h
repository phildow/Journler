//
//  FoldersController.h
//  Journler
//
//  Created by Philip Dow on 10/24/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JournlerCollection;

@interface FoldersController : NSTreeController {
	
	IBOutlet NSOutlineView *sourceList;
	
	id delegate;
	
	JournlerCollection *rootCollection;
	NSMutableArray *_draggedNodes;
	
	float smallRowHeight;
	float fullRowHeight;
	
	BOOL draggingEntries;
	BOOL showsEntryCount;
	BOOL usesSmallFolderIcons;
}

- (JournlerCollection*) rootCollection;
- (void) setRootCollection:(JournlerCollection*)aCollection;

- (id) delegate;
- (void) setDelegate:(id)anObject;

- (float) smallRowHeight;
- (void) setSmallRowHeight:(float)aValue;

- (float) fullRowHeight;
- (void) setFullRowHeight:(float)aValue;

- (BOOL) usesSmallFolderIcons;
- (void) setUsesSmallFolderIcons:(BOOL)smallIcons;

- (BOOL) showsEntryCount;
- (void) setShowsEntryCount:(BOOL)entryCount;

- (NSArray*) allObjects;

- (void) adjustRowHeightsFromFontSize:(float)aValue;

- (IBAction) exposeAllFolders:(id)sender;
- (BOOL) selectCollection:(JournlerCollection*)aCollection byExtendingSelection:(BOOL)extend;

- (IBAction) deleteSelectedFolder:(id)sender;
- (IBAction) renameFolder:(id)sender;
- (IBAction) editSmartFolder:(id)sender;
- (IBAction) getFolderInfo:(id)sender;
- (IBAction) emptyTrash:(id)sender;
- (IBAction) editFolderProperty:(id)sender;
- (IBAction) editFolderLabel:(id)sender;
- (IBAction) selectFolderFromMenu:(id)sender;

- (IBAction) showColorPickerToChangeFolderColor:(id)sender;

- (void) importPasteboardFromDictionary:(NSDictionary*)aDictionary;
- (void) importPasteboardData:(NSPasteboard*)pboard target:(JournlerCollection*)aCollection;


@end

@interface NSObject (FolderControllerDelegate)

- (void) foldersController:(FoldersController*)aFoldersController willChangeSelection:(NSArray*)currentSelection;
- (void) foldersController:(FoldersController*)aFoldersController didChangeSelection:(NSArray*)newSelection;

@end