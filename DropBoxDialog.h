/* DropBoxDialog */

#import <Cocoa/Cocoa.h>
#import <SproutedInterface/SproutedInterface.h>

@class JournlerJournal;
@class JournlerCollection;
@class FoldersController;

@class DropBoxFoldersController;
@class DropBoxSourceList;

@interface DropBoxDialog : NSWindowController
{
	JournlerJournal *journal;
	
	IBOutlet JournlerGradientView *gradientBackground;
	IBOutlet DropBoxFoldersController *sourceController;
	IBOutlet DropBoxSourceList *sourceList;
	
	IBOutlet NSTextField *titleField;
	IBOutlet NSTextField *noteField;
	IBOutlet NSButton *rememberFolderSelectionCheckbox;
	
	IBOutlet NSTokenField *tagsField;
	IBOutlet NSComboBox	*categoryField;
	
	IBOutlet NSButton *returnButton;
	IBOutlet NSButton *cancelButton;
	
	IBOutlet NSArrayController *filesController;
	IBOutlet NSTableView *filesTable;
	
	BOOL multipleFiles;
	BOOL canCancelImport;
	BOOL shouldDeleteOriginal;
	
	id delegate;
	id representedObject;
	NSArray *content;
	NSDictionary *activeApplication;
	
	NSInteger mode;
	SEL didEndSelector;
	
	NSArray *tags;
	NSString *category;
	
	NSArray *tagCompletions;
}

- (id) initWithJournal:(JournlerJournal*)aJournal delegate:(id)aDelegate mode:(int)dropboxMode didEndSelector:(SEL)aSelector;
- (void) _endWithCode:(int)code;

+ (NSArray*) contentForFilenames:(NSArray*)filenames;
+ (NSArray*) contentForEntries:(NSArray*)entries;

- (JournlerJournal*) journal;
- (void) setJournal:(JournlerJournal*)aJournal;

- (NSArray*)content;
- (void) setContent:(NSArray*)anArray;

- (id) representedObject;
- (void) setRepresentedObject:(id)anObject;

- (NSDictionary*) activeApplication;
- (void) setActiveApplication:(NSDictionary*)aDictionary;

- (BOOL) multipleFiles;
- (void) setMultipleFiles:(BOOL)multiple;

- (BOOL) canCancelImport;
- (void) setCanCancelImport:(BOOL)canCancel;

- (BOOL) shouldDeleteOriginal;
- (void) setShouldDeleteOriginal:(BOOL)deletesOriginal;

- (NSArray*) tagCompletions;
- (void) setTagCompletions:(NSArray*)anArray;

- (IBAction) runClose:(id)sender;
- (IBAction) doImport:(id)sender;

- (IBAction) changeFolderSelectionMemory:(id)sender;

- (void) fadeWindowOut:(id)sender;
- (void) fadeWindowIn:(id)sender;

- (NSArray*) tags;
- (void) setTags:(NSArray*)anArray;

- (NSString*) category;
- (void) setCategory:(NSString*)aCategory;

- (JournlerCollection*) selectedFolder;
- (NSArray*) selectedFolders;

@end

@interface NSObject (DropBoxDialogDelegate)

- (void) dropBox:(DropBoxDialog*)aDialog didAcceptContent:(NSArray*)content;
- (void) dropBox:(DropBoxDialog*)aDialog didDenyContent:(NSArray*)content;

@end