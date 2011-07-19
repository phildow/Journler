/* NewEntryController */

#import <Cocoa/Cocoa.h>

@class JournlerEntry;
@class JournlerCollection;
@class JournlerJournal;

@class LabelPicker;
@class PDGradientView;

@class DropBoxSourceList;
@class DropBoxFoldersController;

@interface NewEntryController : NSWindowController
{
    IBOutlet NSObjectController *objectController;
	
	IBOutlet DropBoxFoldersController *sourceController;
	IBOutlet DropBoxSourceList *sourceList;
	
    IBOutlet NSComboBox			*categoryField;
    IBOutlet NSPopUpButton		*collectionField;
    IBOutlet NSTextField		*keywordsField;
    IBOutlet NSTextField		*titleField;
	IBOutlet NSButton			*disclose;
	IBOutlet LabelPicker		*labelPicker;
	
	IBOutlet PDGradientView		*containerView;
	IBOutlet NSView				*advancedView;
	
	NSString *title;
	NSString *category;
	NSArray *tags;
	NSDate *date;
	NSDate *dateDue;
	NSNumber *marking;
	
	BOOL includeDateDue;
	BOOL alreadyEditedCategory;
	
	JournlerJournal *journal;
	
	NSArray		*_categories;
	NSArray		*tagCompletions;
	
	IBOutlet NSDatePicker *datePicker;
}

- (id)initWithJournal:(JournlerJournal*)aJournal;

- (JournlerJournal*) journal;
- (void) setJournal:(JournlerJournal*)aJournal;

- (NSString*) title;
- (void) setTitle:(NSString*)aString;

- (NSString*) category;
- (void) setCategory:(NSString*)aString;

- (NSArray*) tags;
- (void) setTags:(NSArray*)anArray;

- (NSDate*) date;
- (void) setDate:(NSDate*)aDate;

- (NSDate*) dateDue;
- (void) setDateDue:(NSDate*)aDate;

- (BOOL) includeDateDue;
- (void) setIncludeDateDue:(BOOL)include;

- (NSNumber*) marking;
- (void) setMarking:(NSNumber*)aNumber;

- (NSNumber*) labelValue;
- (void) setLabelValue:(NSNumber*)aNumber;

// DEPRECATED
- (JournlerCollection*) selectedCollection;
- (void) setSelectedCollection:(JournlerCollection*)aCollection;

- (NSArray*) tagCompletions;
- (void) setTagCompletions:(NSArray*)anArray;

- (NSArray*) selectedFolders;
- (void) setSelectedFolders:(NSArray*)anArray;

// DEPRECATED
- (IBAction) selectFolder:(id)sender;

- (IBAction) didChangeCategory:(id)sender;

- (IBAction)cancel:(id)sender;
- (IBAction)disclose:(id)sender;
- (IBAction)help:(id)sender;
- (IBAction)okay:(id)sender;

- (NSInteger) runAsSheetForWindow:(NSWindow*)window attached:(BOOL)sheet;

@end

