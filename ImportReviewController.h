/* ImportReviewController */

#import <Cocoa/Cocoa.h>
#import <SproutedInterface/SproutedInterface.h>

@class JournlerEntry;
@class JournlerCollection;
@class JournlerJournal;
@class BrowseTableFieldEditor;

@interface ImportReviewController : NSWindowController
{
	
	IBOutlet NSObjectController		*objectController;
	IBOutlet NSArrayController		*entriesController;
	IBOutlet NSTreeController		*foldersController;
	
	IBOutlet NSOutlineView			*foldersOutline;
	IBOutlet NSTableView			*entriesTable;
	
	IBOutlet NSProgressIndicator	*progress;
	IBOutlet NSTextField			*tipField;
	
	IBOutlet NSWindow				*previewWin;
	IBOutlet NSTextView				*previewText;
	
	IBOutlet NSButton *okayButton;
	IBOutlet NSMenu *labelMenu;
	
	IBOutlet PDGradientView			*gradient;
	IBOutlet BrowseTableFieldEditor	*browseTableFieldEditor;
	
	JournlerCollection *_targetFolder;
	JournlerJournal		*journal;
	
	NSMutableArray		*_entries;
	NSArray *folders;
	
	BOOL _userInteraction;
	BOOL _importHasBegun;
	BOOL _continuing;
	BOOL _finishedImport;
	BOOL _preserveModificationDate;
}

- (id) initWithJournal:(JournlerJournal*)aJournal folders:(NSArray*)theFolders entries:(NSArray*)theEntries;

- (JournlerJournal*) journal;
- (void) setJournal:(JournlerJournal*)aJournal;

- (NSArray*) entries;
- (void) setEntries:(NSArray*)entryContent;

- (NSArray*) folders;
- (void) setFolders:(NSArray*)theFolders;

- (BOOL) userInteraction;
- (void) setUserInteraction:(BOOL)visual;

- (BOOL) preserveModificationDate;
- (void) setPreserveModificationDate:(BOOL)preserve;

- (void) deleteEntries:(NSArray*)theEntries;
- (void) deleteFolder:(JournlerCollection*)aFolder;

- (int) runAsSheetForWindow:(NSWindow*)window attached:(BOOL)sheet targetCollection:(JournlerCollection*)aFolder;

- (IBAction)cancel:(id)sender;
- (IBAction)okay:(id)sender;
- (IBAction)help:(id)sender;
- (IBAction)log:(id)sender;

- (void) _performImport:(id)anObject;
- (void) performImport:(BOOL)threaded;
- (void) addFolderToJournal:(JournlerCollection*)aFolder;

- (IBAction)preview:(id)sender;
- (IBAction) editEntryLabel:(id)sender;

@end
