//
//  JournlerMediaContentController.h
//  Journler
//
//  Created by Philip Dow on 6/11/06.
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