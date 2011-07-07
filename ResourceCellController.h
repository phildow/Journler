//
//  ResourceCellController.h
//  Journler
//
//  Created by Philip Dow on 10/28/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class JournlerResource;

@class PDBorderedView;
@class JournlerGradientView;
@class PDGradientView;
@class MediaContentController;
@class MissingFileController;
@class PDPhotoView;
@class PDMediaBar;

@interface ResourceCellController : NSObject {
	
	IBOutlet PDBorderedView *contentView;
	IBOutlet NSView			*contentPlaceholder;
	
	IBOutlet NSView			*defaultContent;
	IBOutlet WebView		*defaultWebView;
	IBOutlet PDGradientView	*defaultGradient;
	IBOutlet NSTextField	*defaultStatus;
	IBOutlet PDMediaBar		*defaultContentMediabar;
	
	IBOutlet NSView			*photoContainer;
	IBOutlet PDPhotoView	*photoView;
	IBOutlet NSMenu			*photoMenu;
	IBOutlet PDMediaBar		*photoContainerMediabar;
	
	id delegate;
	
	NSView *activeContentView;
	MediaContentController *mediaController; 
	MissingFileController *fileErrorController;
	
	JournlerResource *selectedResource;
	NSArray *selectedResources;
	
	// the url used when viewing a single, unknown file 
	// updated when the file browser changes its selection
	NSURL *mediaURL;
}

- (NSView*) contentView;

- (id) delegate;
- (void) setDelegate:(id)anObject;

- (NSView*) activeContentView;
- (void) setActiveContentView:(NSView*)aView;

- (MediaContentController*) mediaController;
- (void) setMediaController:(MediaContentController*)aController;

- (JournlerResource*) selectedResource;
- (void) setSelectedResource:(JournlerResource*)aResource;

- (NSArray*) selectedResources;
- (void) setSelectedResources:(NSArray*)anArray;

- (NSURL*) mediaURL;
- (void) setMediaURL:(NSURL*)aURL;

- (void) showInfoForMultipleResources:(NSArray*)anArray;
//- (void) showInfoForResource:(JournlerResource*)aResource;
- (void) loadMediaViewerForResource:(JournlerResource*)aResource;

- (void) appropriateFirstResponder:(NSWindow*)aWindow;
- (void) establishKeyViews:(NSView*)previous nextKeyView:(NSView*)next;
- (BOOL) highlightString:(NSString*)aString;

- (BOOL) openURL:(NSURL*)aURL;
- (NSURL*) webBrowsedURL;

- (BOOL) isWebBrowsing;
- (NSString*) documentTitle;

- (void) ownerWillClose;
- (void) stopContent;
- (IBAction) printDocument:(id)sender;
- (BOOL) trumpsPrint;

- (IBAction) exportResource:(id)sender;
- (IBAction) printFileViewerContent:(id)sender;
- (IBAction) printMultipleSelection:(id)sender;

- (IBAction) openLinkInFinder:(id)sender;
- (IBAction) revealLinkInFinder:(id)sender;

- (IBAction) jumpToEntryFromPhotoView:(id)sender;
- (IBAction) openInFinderFromPhotoView:(id)sender;
- (IBAction) revealInFinderFromPhotoView:(id)sender;
- (IBAction) openInNewTabFromPhotoView:(id)sender;
- (IBAction) openInNewWindowFromPhotoView:(id)sender;
- (IBAction) getInfoFromPhotoView:(id)sender;

#pragma mark -

- (IBAction) mediabarDefaultContentGetInfo:(id)sender;
- (IBAction) mediabarDefaultContentShowInFinder:(id)sender;
- (IBAction) mediabarDefaultContentOpenInFinder:(id)sender;

- (IBAction) mediabarMultipleSelectionGetInfo:(id)sender;
- (IBAction) mediabarMultipleSelectionShowInFinder:(id)sender;
- (IBAction) mediabarMultipleSelectionOpenInFinder:(id)sender;

@end

@interface ResourceCellController (FindPanelSupport)

- (BOOL) handlesFindCommand;
- (void) performCustomFindPanelAction:(id)sender;
- (void) checkCustomFindPanelAction;

- (BOOL) handlesTextSizeCommand;
- (void) checkCustomTextSizeAction;
- (void) performCustomTextSizeAction:(id)sender;

@end

@interface ResourceCellController (MissingFileSupport)

- (IBAction) deleteMissingFile:(id)sender;
- (IBAction) searchForMissingFile:(id)sender;
- (IBAction) locateMissingFile:(id)sender;

@end

@interface NSObject (ResourceCellControllerDelegate)

- (void) resourceCellController:(ResourceCellController*)aController didChangeTitle:(NSString*)newTitle;
- (void) resourceCellController:(ResourceCellController*)aController didChangePreviewIcon:(NSImage*)icon forResource:(JournlerResource*)aResource;

@end