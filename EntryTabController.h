//
//  EntryTabController.h
//  Journler
//
//  Created by Philip Dow on 11/9/06.
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
//#import <iMediaBrowser/iMedia.h>
#import <SproutedInterface/SproutedInterface.h>
#import <SproutedAVI/SproutedAVI.h>

#import "TabController.h"

@class JournlerEntry;
@class ResourceController;

@class EntryCellController;
@class ResourceCellController;

@class ResourceTableView;

@interface EntryTabController : TabController {
	
	IBOutlet NSMenu *referenceMenu;
	IBOutlet NSMenu *resourceWorktoolMenu;
	IBOutlet NSMenu *newResourceMenu;
	
	IBOutlet NSView *contentPlaceholder;
	IBOutlet RBSplitView *contentResourceSplit;
	IBOutlet ResourceController *resourceController;
	IBOutlet NSView *resourcesDragView;
	IBOutlet ResourceTableView *resourceTable;
	
	IBOutlet NSMenuItem *resourceInNewTabItem;
	IBOutlet NSMenuItem *resourceInNewTabItemB;
	
	IBOutlet NSButton *resourceWorktool;
	IBOutlet NSButton *newResourceButton;
	IBOutlet NSButton *toggleResourcesButton;
	
	NSPopUpButtonCell *resourceWorktoolPopCell;
	NSPopUpButtonCell *newResourcePopCell;
	
	IBOutlet NSButton *resourceToggle;
	
	JournlerEntry *selectedEntry;
	
	EntryCellController *entryCellController;
	ResourceCellController *resourceCellController;
	
	NSView *activeContentView;
}

- (NSView*) activeContentView;
- (void) setActiveContentView:(NSView*)aView;

- (JournlerEntry*)selectedEntry;
- (void) setSelectedEntry:(JournlerEntry*)anEntry;

- (BOOL) selectResources:(NSArray*)anArray;

- (void) setFullScreen:(BOOL)isFullScreen;
- (void) servicesMenuAppendSelection:(NSPasteboard*)pboard desiredType:(NSString*)type;

- (IBAction) toggleResources:(id)sender;
- (IBAction) showNewResourceSheet:(id)sender;
- (IBAction) insertNewResource:(id)sender;
- (IBAction) addFileFromFinder:(id)sender;
- (IBAction) showResourceWorktoolContextual:(id)sender;

- (void) _hideResourcesSubview:(id)sender;
- (void) _updateResourceToggleImage;

#pragma mark -

- (IBAction) showEntryForSelectedResource:(id)sender;
- (BOOL) _showEntryForSelectedResources:(NSArray*)anArray;

//- (IBAction) revealResource:(id)sender;
//- (IBAction) launchResource:(id)sender;
//- (IBAction) openResourceInNewTab:(id)sender;
//- (IBAction) openResourceInNewWindow:(id)sender;

@end