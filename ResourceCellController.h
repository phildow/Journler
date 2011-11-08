//
//  ResourceCellController.h
//  Journler
//
//  Created by Philip Dow on 10/28/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

/*
 Redistribution and use in source and binary forms, with or without modification, are permitted
 provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions
 and the following disclaimer in the documentation and/or other materials provided with the
 distribution.
 
 * Neither the name of the author nor the names of its contributors may be used to endorse or
 promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// Basically, you can use the code in your free, commercial, private and public projects
// as long as you include the above notice and attribute the code to Philip Dow / Sprouted
// If you use this code in an app send me a note. I'd love to know how the code is used.

// Please also note that this copyright does not supersede any other copyrights applicable to
// open source code used herein. While explicit credit has been given in the Journler about box,
// it may be lacking in some instances in the source code. I will remedy this in future commits,
// and if you notice any please point them out.

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