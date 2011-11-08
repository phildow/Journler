/* LinksOnlyNSTextView */

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
	NSUInteger _dragOperation;
	
	BOOL inFullScreen;
	BOOL continuouslyPostsSelectionNotification;
	
	NSInteger actualMargin;
	NSInteger horizontalInset;
	NSInteger horizontalInsetFullscreen;
	NSUInteger modifierFlags;
}

- (void) doSetup;

+ (NSMenuItem*) highlightMenuItem;

- (JournlerEntry*)entry;
- (void) setEntry:(JournlerEntry*)entry;

- (float) lastScale;
- (void) setLastScale:(float)scaleValue;

- (BOOL) inFullScreen;
- (void) setInFullScreen:(BOOL)fullscreen;

- (NSUInteger) modifierFlags;
- (void) setModifierFlags:(NSUInteger)flags;

- (NSURL*) lastURL;
- (void) setLastURL:(NSURL*)newURL;

- (BOOL) continuouslyPostsSelectionNotification;
- (void) setContinuouslyPostsSelectionNotification:(BOOL)continuous;

- (NSColor*) linkColor;
- (void) setLinkColor:(NSColor*)aColor;

- (BOOL) linkUnderlined;
- (void) setLinkUnderlined:(BOOL)underline;

- (NSInteger) actualMargin;
- (void) setActualMargin:(NSInteger)inset;

- (NSInteger) horizontalInset;
- (void) setHorizontalInset:(NSInteger)inset;

- (NSInteger) horizontalInsetFullscreen;
- (void) setHorizontalInsetFullscreen:(NSInteger)inset;

- (void) setFullScreen:(BOOL)inFullScreen;

//requested to the first responder
- (IBAction) insertCheckbox:(id) sender;
- (IBAction) insertDateTime:(id)sender;
- (IBAction) pasteAndMatchStyle:(id)sender;
- (IBAction) copyAsHTML:(id)sender;
- (IBAction) highlightSelection:(id) sender;

- (IBAction) strikeSelection:(id)sender;
- (void) strikeSelection:(NSColor*)aColor styleMask:(NSInteger)mask;

#pragma mark -

- (BOOL) addFileToText:(NSString*)path fileName:(NSString*)title forceTitle:(BOOL)forceTitle resourceCommand:(NSInteger)command;
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
- (NSUInteger) _charIndexForDraggingLoc:(NSPoint)point;
- (NSString*) _mdTitleFoFileAtPath:(NSString*)fullpath;
- (NSString*) _linkedTextForAudioFile:(NSString*)fullpath;
- (NSUInteger) _commandForCurrentCommand:(NSUInteger)dragOperation fileType:(NSString*)type directory:(BOOL)dir package:(BOOL)package;

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

