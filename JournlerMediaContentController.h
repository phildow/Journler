//
//  JournlerMediaContentController.h
//  Journler
//
//  Created by Philip Dow on 6/11/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define PDMediabarItemShowInFinder		@"PDMediabarItemShowInFinder"
#define PDMediabarItemOpenWithFinder	@"PDMediabarItemOpenWithFinder"
#define PDMediaBarItemGetInfo			@"PDMediaBarItemGetInfo"

@class PDMediaBar;
@class PDMediabarItem;
@class JournlerGradientView;

// I would prefer to keep journler specific items out of the file - thus the category
@class JournlerResource;

@interface JournlerMediaContentController : NSObject {
	
	IBOutlet NSView *contentView;
	IBOutlet PDMediaBar *bar;
	
	id delegate;
	NSURL *URL;
	
	id representedObject;
	NSString *searchString;
	
	NSDictionary *fileError;
}

- (NSView*) contentView;

- (id) delegate;
- (void) setDelegate:(id)anObject;

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

- (void) ownerWillClose:(NSNotification*)aNotification;

- (void) updateContent;
- (void) stopContent;

- (BOOL) handlesFindCommand;
- (void) performCustomFindPanelAction:(id)sender;

- (BOOL) handlesTextSizeCommand;
- (void) performCustomTextSizeAction:(id)sender;

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem;

@end

@interface NSObject (JournlerMediaContentDelegate)

- (void) contentController:(JournlerMediaContentController*)aController didLoadURL:(NSURL*)aURL;
- (void) contentController:(JournlerMediaContentController*)controller changedTitle:(NSString*)title;
- (void) contentController:(JournlerMediaContentController*)aController showLexiconSelection:(id)anObject term:(NSString*)aTerm;

@end

@interface NSView (JournlerMediaContentAdditions)

- (void) setImage:(NSImage*)anImage;

@end

@interface JournlerMediaContentController (JournlerResourceAdditions)

- (void) showInfoForResource:(JournlerResource*)aResource;

@end