//
//  MediaContentController.h
//  Journler
//
//  Created by Philip Dow on 6/11/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreData/CoreData.h>

#define PDMediabarItemShowInFinder		@"PDMediabarItemShowInFinder"
#define PDMediabarItemOpenWithFinder	@"PDMediabarItemOpenWithFinder"
#define PDMediaBarItemGetInfo			@"PDMediaBarItemGetInfo"

@class PDMediaBar;
@class PDMediabarItem;
@class JournlerGradientView;

@interface MediaContentController : NSObject {
	
	IBOutlet NSView *contentView;
	IBOutlet PDMediaBar *bar;
	
	id delegate;
	NSURL *URL;
	
	id representedObject;
	NSString *searchString;
	
	NSDictionary *fileError;
	NSManagedObjectContext *managedObjectContext;
}

- (id) initWithOwner:(id)anObject managedObjectContext:(NSManagedObjectContext*)moc;

- (NSView*) contentView;
- (NSUndoManager*) undoManager;

- (id) delegate;
- (void) setDelegate:(id)anObject;

- (NSManagedObjectContext*) managedObjectContext;
- (void) setManagedObjectContext:(NSManagedObjectContext*)moc;

- (id) representedObject;
- (void) setRepresentedObject:(id)anObject;

- (NSURL*) URL;
- (void) setURL:(NSURL*)aURL;

- (NSString*) searchString;
- (void) setSearchString:(NSString*)aString;

- (BOOL) loadURL:(NSURL*)aURL;
- (BOOL) highlightString:(NSString*)aString;

- (IBAction) printDocument:(id)sender;
- (IBAction) exportSelection:(id)sender;

- (IBAction) getInfo:(id)sender;
- (IBAction) showInFinder:(id)sender;
- (IBAction) openInFinder:(id)sender;

- (void) prepareTitleBar;
- (void) setWindowTitleFromURL:(NSURL*)aURL;

- (NSResponder*) preferredResponder;
- (void) appropriateFirstResponder:(NSWindow*)window;
- (void) appropriateAlternateResponder:(NSWindow*)aWindow;
- (void) establishKeyViews:(NSView*)previous nextKeyView:(NSView*)next;

- (BOOL) commitEditing;
- (void) ownerWillClose:(NSNotification*)aNotification;

- (void) updateContent;
- (void) stopContent;

- (BOOL) handlesFindCommand;
- (void) performCustomFindPanelAction:(id)sender;

- (BOOL) handlesTextSizeCommand;
- (void) performCustomTextSizeAction:(id)sender;

- (BOOL) canAnnotateDocumentSelection;
- (IBAction) annotateDocumentSelection:(id)sender;

- (BOOL) canHighlightDocumentSelection;
- (IBAction) highlightDocumentSelection:(id)sender;

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem;

@end

@interface NSObject (MediaContentDelegate)

- (void) contentController:(MediaContentController*)controller changedTitle:(NSString*)title;
- (void) contentController:(MediaContentController*)aController showLexiconSelection:(id)anObject term:(NSString*)aTerm;

@end

@interface NSView (MediaContentAdditions)

- (void) setImage:(NSImage*)anImage;

@end
