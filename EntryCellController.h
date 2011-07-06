//
//  EntryCellController.h
//  Journler
//
//  Created by Phil Dow on 10/25/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

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

//- (void) showContentForMultipleEntries:(NSArray*)anArray;
- (IBAction) performFindPanelAction:(id)sender;
- (IBAction) printDocument:(id)sender;

- (IBAction) scaleText:(id)sender;
- (IBAction) setMargin:(id)sender;

- (IBAction) _setMargin:(int)margin;

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
		modifierFlags:(unsigned int)flags 
		highlight:(NSString*)aTerm;

- (void) entryCellController:(EntryCellController*)aController 
		clickedOnResource:(JournlerResource*)aResource 
		modifierFlags:(unsigned int)flags 
		highlight:(NSString*)aTerm;

- (void) entryCellController:(EntryCellController*)aController 
		clickedOnFolder:(JournlerCollection*)aFolder 
		modifierFlags:(unsigned int)flags;
		
- (void) entryCellController:(EntryCellController*)aController 
		clickedOnURL:(NSURL*)aURL 
		modifierFlags:(unsigned int)flags;

- (BOOL) entryCellController:(EntryCellController*)aController 
		newDefaultEntry:(NSNotification*)aNotification;

@end
