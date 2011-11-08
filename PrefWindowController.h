/* PrefWindowController */

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

/* 488 x 243 */

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <SproutedInterface/SproutedInterface.h>

typedef enum {
	
	kPrefStart = 0,
	kPrefDonations = 1,
	kPrefGeneral = 2,
	kPrefAdvanced = 3,
	/*kPrefBlogging = 4,*/
	kPrefBackup = 5,
	kPrefWindow = 6,
	kPrefFontsAndColors = 7,
	kPrefCalendar = 8,
	kPrefRecording = 11,
	kPrefMedia = 12,
	kPrefDotMac = 13,
	kPrefiTunes = 14,
	kPrefImages = 15,
	kPrefEditing = 16,
	kPrefLabels = 17
	
} JournlerPrefTags;

#define PDPreferencesDidEndEditingNotification	@"PDPreferencesDidEndEditingNotification"


//@class BlogPref;
@class JournlerEntry;
@class JournlerJournal;

@class IndividualLabelView;

//@class MyPopUpButton;
//@class MyHeaderView;
//@class BlogAccountWizardController;

@interface PrefWindowController : NSWindowController
{

	IBOutlet NSView		*panelDonations;
	IBOutlet NSView		*panelGeneral;
	IBOutlet NSView		*panelWindow;
	IBOutlet NSView		*panelLabels;
	IBOutlet NSView		*panelEditing;
	IBOutlet NSView		*panelMedia;
	
	IBOutlet NSView		*panelAdvanced;
	
	//IBOutlet JournlerGradientView	*panelTemporary;
	NSView	*panelTemporary;
	
	IBOutlet WebView *licenseWebView;
	IBOutlet NSButton *enterLicenseButton;
	IBOutlet NSButton *purchaseJournlerButton;
	IBOutlet NSTextField *thanksField;
	
	IBOutlet NSUserDefaultsController	*defaultsController;
	IBOutlet NSArrayController			*catListController;
	
	IBOutlet NSObjectController			*prefController;
	
	IBOutlet NSWindow					*newCatSheet;
	IBOutlet NSTextField				*newCatName;
	IBOutlet NSButton					*makeDefaultCategory;
	IBOutlet NSPopUpButton				*defaultCatPop;

	IBOutlet PDFontPreview *entrytextFontPreview;
	IBOutlet PDFontPreview *foldersFontPreview;
	IBOutlet PDFontPreview *browserFontPreview;
	IBOutlet PDFontPreview *referencesFontPreview;
	
	IBOutlet NSButton					*enablePassword;
	IBOutlet NSWindow					*passwordWindow;
		IBOutlet NSTextField				*passA;
		IBOutlet NSTextField				*passB;
	
	//IBOutlet PDGradientView		*panelBlogs;
	//IBOutlet NSArrayController	*blogPrefsController;
	//IBOutlet NSTableView			*blogTable;
	//IBOutlet NSPopUpButton		*blogTypes;
	//IBOutlet NSTextField			*xmlrpcLoc;
	//IBOutlet NSTextField			*blogID;
	
	IBOutlet NSTextField *imageWidthField;
	IBOutlet NSButton *useAppleMailCheck;
	
	// ------------------------------------------------------------
	
	IBOutlet NSWindow					*deleteCatSheet;
	IBOutlet NSPopUpButton				*deleteCatPop;
	
	IBOutlet NSWindow *wordListSheet;
	IBOutlet NSTableView *wordListTable;
	IBOutlet NSButton *wordListWoorktool;
	IBOutlet NSMenu *wordListMenu;
	IBOutlet NSArrayController *wordListController;
	
	IBOutlet NSWindow *licenseSheet;
	IBOutlet NSTextField *licenseNameField;
	IBOutlet NSTextField *licenseSequence1;
	IBOutlet NSTextField *licenseSequence2;
	IBOutlet NSTextField *licenseSequence3;
	IBOutlet NSTextField *licenseSequence4;
	
	IBOutlet IndividualLabelView *labelView1;
	IBOutlet IndividualLabelView *labelView2;
	IBOutlet IndividualLabelView *labelView3;
	IBOutlet IndividualLabelView *labelView4;
	IBOutlet IndividualLabelView *labelView5;
	IBOutlet IndividualLabelView *labelView6;
	IBOutlet IndividualLabelView *labelView7;
	
	IBOutlet PDButtonColorWell *highlightYellow;
	IBOutlet PDButtonColorWell *highlightOrange;
	IBOutlet PDButtonColorWell *highlightRed;
	IBOutlet PDButtonColorWell *highlightBlue;
	IBOutlet PDButtonColorWell *highlightGreen;
	
	IBOutlet PDButtonColorWell *colorLink;
	
	IBOutlet PDButtonColorWell *backgroundColorText;
	IBOutlet PDButtonColorWell *backgroundColorHeader;
	IBOutlet PDButtonColorWell *headerColorLabel;
	IBOutlet PDButtonColorWell *headerColorValue;
	
	IBOutlet NSPopUpButton *weblogEditorPopUp;
	
	NSString							*shortFormJournalLoc;
	
	NSInteger passed;
	NSInteger licenseType;
	
	JournlerJournal *journal;
	NSArray *autoCorrectWordPairs;
}

+ (id)sharedController;

- (JournlerJournal*) journal;
- (void) setJournal:(JournlerJournal*)aJournal;

- (NSArray*) autoCorrectWordPairs;
- (void) setAutoCorrectWordPairs:(NSArray*)anArray;

#pragma mark -

- (IBAction) editWordList:(id)sender;
- (IBAction) showWordListWorktool:(id)sender;
- (IBAction) cancelWordListChanges:(id)sender;
- (IBAction) okayWordListChanges:(id)sender;
- (IBAction) toggleUseWordList:(id)sender;

- (IBAction) clearWordList:(id)sender;
- (IBAction) restoreDefaultWordList:(id)sender;
- (IBAction) loadWordListFromFile:(id)sender;

- (IBAction) showSecurityHelp:(id)sender;
- (IBAction) showTunesHelp:(id)sender;
- (IBAction) showMediaHelp:(id)sender;

- (IBAction) makeDonation:(id)sender;
- (IBAction) changeCalendarStartDay:(id)sender;

- (IBAction) changePassword:(id)sender;
- (IBAction) okayPassword:(id)sender;
- (IBAction) cancelPassword:(id)sender;

- (IBAction) addCategory:(id)sender;
- (IBAction) createCategory:(id)sender;
- (IBAction) closeCreateCategory:(id)sender;

- (IBAction) removeCategory:(id)sender;
- (IBAction) proceedRemoveCategory:(id)sender;
- (IBAction) closeRemoveCategory:(id)sender;

- (IBAction) enterLicense:(id)sender;
- (IBAction) confirmLicense:(id)sender;
- (IBAction) cancelLicense:(id)sender;

- (void) checkLicenseName:(NSString*)name code:(NSString*)code;

//- (IBAction) showBlogHelp:(id)sender;
//- (IBAction) blogTypeChange:(id)sender;
//- (IBAction) addBlog:(id)sender;
//- (IBAction) removeBlog:(id)sender;
//- (IBAction) blogAccountWizard:(id)sender;
//- (void) selectBlog:(BlogPref*)aBlog;

// ------------------------------------------------------------------

- (void) loadHandledDefaults;
- (void) loadLicenseViewer;

- (NSString*) shortFormJournalLoc;

- (void) setShortFormJournalLoc:(NSString*)jloc;

- (NSInteger) passed;
- (void) setPassed:(NSInteger)newVal;

- (void) cleanup:(NSNotification*)aNotification;

- (IBAction) tabPanel:(id)sender;
- (void) selectPanel:(NSNumber*)tagNum;

- (IBAction) changeEmailSetting:(id)sender;
- (IBAction) chooseWeblogEditor:(id)sender;
- (IBAction) selectColor:(id) sender;

- (void) setPreferredWeblogEditor:(NSString*)filename;

@end

@interface PrefWindowController (Toolbars)
	- (void) setupToolbar;
@end
