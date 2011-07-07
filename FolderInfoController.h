//
//  FolderInfoController.h
//  Journler
//
//  Created by Philip Dow on 11/1/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

@class JournlerJournal;
@class JournlerCollection;

@class LabelPicker;
@class PDGradientView;

@interface FolderInfoController : NSWindowController {
	
	IBOutlet PDGradientView *gradient;
	IBOutlet NSImageView *imageView;
	IBOutlet LabelPicker *labelPicker;
	IBOutlet NSObjectController *objectController;
	
	IBOutlet NSWindow *imageWindow;
	IBOutlet PDGradientView *imageGradient;
	IBOutlet NSButton *journalButton;
	IBOutlet NSButton *trashButton;
	IBOutlet NSButton *smartButton;
	IBOutlet NSButton *folderButton;
	IBOutlet NSButton *webarchiveButton;
	IBOutlet NSButton *pdfButton;
	IBOutlet NSButton *bookmarksButton;
	IBOutlet NSButton *picturesButton;
	IBOutlet NSButton *audioButton;
	IBOutlet NSButton *moviesButton;
	
	JournlerJournal *journal;
	JournlerCollection *collection;
	
	NSString *title;
	NSImage *image;
	
}

- (id) initWithCollection:(JournlerCollection*)aCollection journal:(JournlerJournal*)aJournal;

- (JournlerCollection*)collection;
- (void) setCollection:(JournlerCollection*)aCollection;

- (JournlerJournal*)journal;
- (void) setJournal:(JournlerJournal*)aJournal;

- (NSImage*)image;
- (void) setImage:(NSImage*)anImage;

- (NSString*)title;
- (void) setTitle:(NSString*)aString;

- (NSNumber*)label;
- (void) setLabel:(NSNumber*)aNumber;

- (IBAction) okay:(id)sender;
- (IBAction) cancel:(id)sender;
- (IBAction) editImage:(id)sender;
- (IBAction) verifyDraggedImage:(id)sender;

- (IBAction) selectImage:(id)sender;
- (IBAction) searchImage:(id)sender;

@end
