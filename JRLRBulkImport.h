/* JRLRBulkImport */

#import <Cocoa/Cocoa.h>

@class JournlerCollection;
@class JournlerJournal;
@class JournlerCollection;

@class LabelPicker;

@interface JRLRBulkImport : NSObject
{
    IBOutlet NSView				*view;
	
	IBOutlet NSObjectController *objectController;
	
    IBOutlet NSMatrix			*datePreference;
    IBOutlet NSPopUpButton		*collectionField;
	IBOutlet NSComboBox			*categories;
	IBOutlet NSButton			*preserveFolders;
	IBOutlet NSButton			*preserveDateModifiedCheck;
	
	IBOutlet NSDatePicker		*datePicker;
	
	IBOutlet LabelPicker		*labelPicker;
	
	NSString *title;
	NSString *category;
	NSArray *tags;
	NSDate *date;
	NSNumber *marking;
	NSString *comments;
	
	JournlerJournal *journal;
	
	BOOL alreadyEditedCategory;
}

- (id) initWithJournal:(JournlerJournal*)aJournal;

- (JournlerCollection*) targetCollection;
- (void) setTargetCollection:(JournlerCollection*)collection;

- (JournlerJournal*) journal;
- (void) setJournal:(JournlerJournal*)aJournal;

- (void) setTargetDate:(NSCalendarDate*)date;

- (void)ownerWillClose:(NSNotification *)aNotification;

- (BOOL) preserveFolderStructure;
- (BOOL) preserveDateModified;

- (int) datePreference;

- (NSCalendarDate*) date;
- (void) setDate:(NSDate*)aDate;

- (NSString*) title;
- (void) setTitle:(NSString*)aString;

- (NSString*) category;
- (void) setCategory:(NSString*)aString;

- (NSArray*) tags;
- (void) setTags:(NSArray*)aString;

- (NSString*) comments;
- (void) setComments:(NSString*)theComments;

- (NSNumber*) marking;
- (void) setMarking:(NSNumber*)aNumber;

- (NSNumber*) labelValue;
- (void) setLabelValue:(NSNumber*)aNumber;

- (NSView*) view;

- (IBAction) selectFolder:(id)sender;

- (BOOL) commitEditing;

@end

