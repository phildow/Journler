//
//  EntryCellController.h
//  Journler
//
//  Created by Philip Dow on 10/25/06.
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
#import <SproutedAVI/SproutedAVI.h>

@class JournlerEntry;
@class JournlerJournal;
@class JournlerResource;
@class JournlerCollection;

@class PDStylesBar;
@class PDBorderedView;
@class PDGradientView;
@class LinksOnlyNSTextView;
@class JournlerGradientView;

@interface EntryCellController : NSObject {
	
	IBOutlet NSObjectController *objectController;
	
	IBOutlet PDBorderedView *contentView;
	IBOutlet PDGradientView *headerView;
	
	IBOutlet JournlerGradientView *statusBar;
	IBOutlet NSTextField *statusText;
	IBOutlet NSPopUpButton *scalePop;
	IBOutlet NSPopUpButton *marginPop;
	
	IBOutlet NSTextField *titleField;
	IBOutlet NSTextField *categoryField;
	IBOutlet NSTextField *dateField;
	
	IBOutlet NSTokenField *tagsField;
	
	LinksOnlyNSTextView *textView;
	PDStylesBar *stylesBar;
	
	id delegate;
	
	JournlerJournal *journal;
	JournlerEntry *selectedEntry;
	NSArray *selectedEntries;
	
	BOOL headerHidden;
	BOOL stylesBarVisible;
	BOOL footerHidden;
	BOOL headerIsWhite;
	
	NSString *openSmartQuote;
	NSString *closeSmartQuote;
	BOOL openQuote;
	
	NSColor *textBackgroundColor;
	NSColor *headerBackgroundColor;
	NSColor *headerLabelColor;
	NSColor *headerTextColor;
	
	BOOL loadingEntries;
	
	JournlerResource *draggedResource;
}

- (void) installTextSystem;

- (NSView*) contentView;
- (NSView*) headerView;
- (LinksOnlyNSTextView*)textView;
- (NSTextField*) titleField;

- (void) setFullScreen:(BOOL)isFullScreen;

- (JournlerEntry*) selectedEntry;
- (void) setSelectedEntry:(JournlerEntry*)anEntry;

- (NSArray*) selectedEntries;
- (void) setSelectedEntries:(NSArray*)anArray;

- (JournlerJournal*) journal;
- (void) setJournal:(JournlerJournal*) aJournal;

- (void) _determineHeaderBorders;
- (BOOL) commitEditing;

- (id) delegate;
- (void) setDelegate:(id)anObject;

- (BOOL) headerHidden;
- (void) setHeaderHidden:(BOOL)hidden;

- (BOOL) footerHidden;
- (void) setFooterHidden:(BOOL)hidden;

- (BOOL) rulerVisible;
- (void) setRulerVisible:(BOOL)visible;

- (BOOL) stylesBarVisible;
- (void) setStylesBarVisible:(BOOL)visible;

- (BOOL) headerIsWhite;
- (void) setHeaderIsWhite:(BOOL)isWhite;

- (NSColor*) headerBackgroundColor;
- (void) setHeaderBackgroundColor:(NSColor*)aColor;

- (NSColor*) textBackgroundColor;
- (void) setTextBackgroundColor:(NSColor*)aColor;

- (NSColor*) headerLabelColor;
- (void) setHeaderLabelColor:(NSColor*)aColor;

- (NSColor*) headerTextColor;
- (void) setHeaderTextColor:(NSColor*)aColor;

- (IBAction) performFindPanelAction:(id)sender;
- (IBAction) printDocument:(id)sender;

- (IBAction) scaleText:(id)sender;
- (IBAction) setMargin:(id)sender;

- (IBAction) _setMargin:(NSInteger)margin;

- (BOOL) highlightString:(NSString*)aString;
- (void) servicesMenuAppendSelection:(NSPasteboard*)pboard desiredType:(NSString*)type;

- (BOOL) hasSelectedText;
- (NSAttributedString*) selectedText;

- (void) ownerWillClose;
- (void) appropriateFirstResponder:(NSWindow*)aWindow;
- (void) appropriateFirstResponderForNewEntry:(NSWindow*)window;
- (void) establishKeyViews:(NSView*)previous nextKeyView:(NSView*)next;

- (void) updateLiveCount;
- (BOOL) processTextForLinksAndMisspelledWords:(NSTextStorage*)aTextStorage range:(NSRange)aRange;

@end

@interface NSObject (EntryCellControllerDelegate)

- (void) entryCellController:(EntryCellController*)aController 
		clickedOnEntry:(JournlerEntry*)anEntry 
		modifierFlags:(NSUInteger)flags 
		highlight:(NSString*)aTerm;

- (void) entryCellController:(EntryCellController*)aController 
		clickedOnResource:(JournlerResource*)aResource 
		modifierFlags:(NSUInteger)flags 
		highlight:(NSString*)aTerm;

- (void) entryCellController:(EntryCellController*)aController 
		clickedOnFolder:(JournlerCollection*)aFolder 
		modifierFlags:(NSUInteger)flags;
		
- (void) entryCellController:(EntryCellController*)aController 
		clickedOnURL:(NSURL*)aURL 
		modifierFlags:(NSUInteger)flags;

- (BOOL) entryCellController:(EntryCellController*)aController 
		newDefaultEntry:(NSNotification*)aNotification;

@end
