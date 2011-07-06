/* LinksOnlyNSTextView */

#import <Cocoa/Cocoa.h>
#import <AddressBook/AddressBook.h>

// @class ABTableView;

@class JournlerEntry;
@class JournlerJournal;
@class JournlerResource;
@class JournlerObject;

@class StatsController;
@class LinkController;
@class IntegrationCopyFiles;

@interface LinksOnlyNSTextView : NSTextView
{
	JournlerEntry	*_entry;
	
	NSAttributedString			*_space;	//so we don't have to alloc and dealloc them during every operation
	NSURL						*lastURL;
	
	NSRange spokenRange;
	NSSpeechSynthesizer *highlightSpeechSynthesizer;
	NSDictionary *selectedRangeAttributes;
	// for highlighting the spoken text
	
	float		_lastScale;
	
	BOOL	controlDown;
	BOOL	alternateDown;
	BOOL	commandDown;
	BOOL	shiftDown;
	
	BOOL	dragProducedEntry;
	
	BOOL						windowWasKey;
	unsigned _dragOperation;
	
	BOOL inFullScreen;
	BOOL continuouslyPostsSelectionNotification;
	
	int actualMargin;
	int horizontalInset;
	int horizontalInsetFullscreen;
	unsigned int modifierFlags;
}

- (void) doSetup;

+ (NSMenuItem*) highlightMenuItem;

- (JournlerEntry*)entry;
- (void) setEntry:(JournlerEntry*)entry;

- (float) lastScale;
- (void) setLastScale:(float)scaleValue;

- (BOOL) inFullScreen;
- (void) setInFullScreen:(BOOL)fullscreen;

- (unsigned int) modifierFlags;
- (void) setModifierFlags:(unsigned int)flags;

- (NSURL*) lastURL;
- (void) setLastURL:(NSURL*)newURL;

- (BOOL) continuouslyPostsSelectionNotification;
- (void) setContinuouslyPostsSelectionNotification:(BOOL)continuous;

- (NSColor*) linkColor;
- (void) setLinkColor:(NSColor*)aColor;

- (BOOL) linkUnderlined;
- (void) setLinkUnderlined:(BOOL)underline;

- (int) actualMargin;
- (void) setActualMargin:(int)inset;

- (int) horizontalInset;
- (void) setHorizontalInset:(int)inset;

- (int) horizontalInsetFullscreen;
- (void) setHorizontalInsetFullscreen:(int)inset;

- (void) setFullScreen:(BOOL)inFullScreen;

//requested to the first responder
- (IBAction) insertCheckbox:(id) sender;
- (IBAction) insertDateTime:(id)sender;
- (IBAction) pasteAndMatchStyle:(id)sender;
- (IBAction) copyAsHTML:(id)sender;
- (IBAction) highlightSelection:(id) sender;

- (IBAction) strikeSelection:(id)sender;
- (void) strikeSelection:(NSColor*)aColor styleMask:(int)mask;

#pragma mark -

- (BOOL) addFileToText:(NSString*)path fileName:(NSString*)title forceTitle:(BOOL)forceTitle resourceCommand:(int)command;
- (BOOL) addImageDataToText:(NSData*)data dataType:(NSString*)type fileName:(NSString*)name;

- (BOOL) addURLLocToText:(NSString*)urlString http:(NSString*)httpString;
- (BOOL) addURLToText:(NSString*)urlString title:(NSString*)aTitle;
- (BOOL) addPersonToText:(ABPerson*)aPerson;
- (BOOL) addMailMessageToText:(id <NSDraggingInfo>)sender;
- (BOOL) addMailMessagesToText:(NSArray*)messageIDs;
- (BOOL) addWebArchiveToTextFromURL:(NSURL*)url title:(NSString*)sitename;

- (BOOL) addJournlerObjectWithURIToText:(NSURL*)aURI;

- (BOOL) insertText:(NSString*)linkedText image:(NSImage*)linkedImage attributes:(NSDictionary*)attr;

#pragma mark -

//modulating the work
-(BOOL) addPreparedStringToText:(NSAttributedString*)preparedText;
- (NSDictionary*) attributesAtRangeForUserTextChange;

- (IBAction) showStats:(id)sender;
//- (IBAction) showInvisibles:(id)sender;

- (IBAction) insertLink:(id)sender;
- (void) insertLink:(NSString*)url title:(NSString*)text;

- (void) handleRegisterDragTypes;
- (void) handleDeregisterDragTypes;

- (IBAction) modifyingAttributes:(NSDictionary*)attributes;
- (IBAction) applyDefaultStyle:(id)sender;

#pragma mark -

// private additions
- (unsigned) _charIndexForDraggingLoc:(NSPoint)point;
- (NSString*) _mdTitleFoFileAtPath:(NSString*)fullpath;
- (NSString*) _linkedTextForAudioFile:(NSString*)fullpath;
- (unsigned) _commandForCurrentCommand:(unsigned)dragOperation fileType:(NSString*)type directory:(BOOL)dir package:(BOOL)package;

- (void) applyDefaultStyleAndRuler;
- (IBAction) applyDefaultStyle:(id)sender;
- (IBAction) applyDefaultRuler:(id)sender;
- (IBAction) setDefaultRuler:(id) sender;
- (IBAction) setDefaultFont:(id) sender;
- (IBAction) removeFormatting:(id)sender;

- (IBAction) revealLinkInFinder:(id)sender;
- (IBAction) openLinkWithFinder:(id)sender;

- (IBAction) openLinkInNewTab:(id)sender;
- (IBAction) openLinkInNewWindow:(id)sender;

- (IBAction) linkToEntryFromMenu:(id)sender;

- (void) setFullScreen:(BOOL)isFullScreen;
- (IBAction) makeBlockQuote:(id)sender;
- (IBAction) scaleText:(id)sender;
- (IBAction) setSpacing:(id)sender;
- (IBAction) modifyCharacterCase:(id)sender;
- (IBAction) modifyCharacterSpacing:(id)sender;

- (void) ownerWillClose:(NSNotification*)aNotification;
- (void) performCustomTextSizeAction:(id)sender;

@end

@interface NSObject (LinksOnlyNSTextViewDelegate)

- (void) textView:(LinksOnlyNSTextView*)aTextView rulerToggling:(NSNotification*)aNotification;
- (BOOL) textView:(LinksOnlyNSTextView*)aTextView newDefaultEntry:(NSNotification*)aNotification;
- (BOOL) textViewIsInFullscreenMode:(LinksOnlyNSTextView*)aTextView;
- (NSImage*) textView:(LinksOnlyNSTextView*)aTextView dragImageForSelectionWithEvent:(NSEvent *)event origin:(NSPointPointer)origin;

- (void) textView:(LinksOnlyNSTextView*)aTextView showLexiconSelection:(JournlerObject*)anObject term:(NSString*)aTerm;

@end

