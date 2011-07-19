/* MultipleEntryController */

#import <Cocoa/Cocoa.h>

@class LabelPicker;

@class BlogPref;
@class JournlerEntry;
@class JournlerJournal;

@interface MultipleEntryInfoController : NSWindowController
{
	//
	// properties will be filled with initial values and handled by the controller

	NSArray				*entries;
	JournlerJournal		*journal;
	
	NSString			*category;
	NSString			*keywords;
	NSDate				*calDate;
	NSDate				*eventDate;
	NSDate				*dateDue;
	NSDate				*calDateModified;
	NSArray				*tags;
	
	NSMutableArray		*blogs;
	
	int				marked;
	
	IBOutlet NSObjectController *objectController;
	IBOutlet NSArrayController	*blogListController;
	IBOutlet NSComboBox			*categoryCombo;
	
	IBOutlet LabelPicker		*label;
	IBOutlet NSTextField		*numField;
	
	// dates
	IBOutlet NSDatePicker 		*dateCreatedPicker;
	IBOutlet NSDatePicker		*dateDuePicker;
	IBOutlet NSDatePicker		*eventDatePicker;
	
	// Adding an Blog Record
	IBOutlet NSWindow		*addBlogSheet;
	IBOutlet NSPopUpButton	*addBlogType;
	IBOutlet NSComboBox		*addBlogName;
	IBOutlet NSTextField	*addBlogJournal;
	
	// Deleting a Blog Record
	IBOutlet NSWindow		*deleteBlogSheet;
	IBOutlet NSTextField	*deleteBlogType;
	IBOutlet NSTextField	*deleteBlogName;
	IBOutlet NSTextField	*deleteBlogJournal;
	
	// keeping track of what to change
	BOOL	modifiedCat;
	BOOL	modifiedCalDate;
	BOOL	modifiedCalDateModified;
	BOOL	modifiedLabel;
	BOOL	modifiedMarked;
	BOOL	modifiedBlogs;
	BOOL	modifiedDateDue;
	BOOL	modifiedEventDate;
	
	BOOL	modifiedKeywords;
	BOOL	modifiedTags;
	
	BOOL clearsDateDue;
	NSArray *tagCompletions;
}

- (id) initWithEntries:(NSArray*)initialEntries;

- (NSArray*) entries;
- (void) setEntries:(NSArray*) newEntries;

- (JournlerJournal*)journal;
- (void) setJournal:(JournlerJournal*)aJournal;

- (NSArray*) tagCompletions;
- (void) setTagCompletions:(NSArray*)anArray;

- (void) updateViewValues;

//
// editing values

- (NSString*) category;
- (void) setCategory:(NSString*) newCategory;

- (NSString*) keywords;
- (void) setKeywords:(NSString*) newKeywords;

- (NSArray*) tags;
- (void) setTags:(NSArray*)anArray;

- (NSDate*) calDate;
- (void) setCalDate:(NSDate*)newCalDate;

- (NSDate*) dateDue;
- (void) setDateDue:(NSDate*)newCalDate;

- (NSDate*) eventDate;
- (void) setEventDate:(NSDate*)newCalDate;

- (NSDate*) calDateModified;
- (void) setCalDateModified:(NSDate*)newCalDateModified;

- (NSArray*) blogs;
- (void) setBlogs:(NSArray*)theBlogs;

- (NSInteger) marked;
- (void) setMarked:(NSInteger)newMark;

- (BOOL) clearsDateDue;
- (void) setClearsDateDue:(BOOL)clears;

#pragma mark -

- (BOOL) modifiedCat;
- (void) setModifiedCat:(BOOL)modified;

- (BOOL) modifiedKeywords;
- (void) setModifiedKeywords:(BOOL)modified;

- (BOOL) modifiedTags;
- (void) setModifiedTags:(BOOL)modified;

- (BOOL) modifiedCalDate;
- (void) setModifiedCalDate:(BOOL)modified;

- (BOOL) modifiedCalDateModified;
- (void) setModifiedCalDateModified:(BOOL)modified;

- (BOOL) modifiedLabel;
- (void) setModifiedLabel:(BOOL)modified;

- (BOOL) modifiedMarked;
- (void) setModifiedMarked:(BOOL)modified;

- (BOOL) modifiedBlogs;
- (void) setModifiedBlogs:(BOOL)modified;

- (BOOL) modifiedDateDue;
- (void) setModifiedDateDue:(BOOL)modified;

- (BOOL) modifiedEventDate;
- (void) setModifiedEventDate:(BOOL)modified;

- (IBAction)activateProperty:(id)sender;

- (IBAction)addBlog:(id)sender;
- (IBAction)editBlogList:(id)sender;
- (IBAction)removeBlog:(id)sender;

- (IBAction) cancelBlogAdd:(id)sender;
- (IBAction) confirmBlogAdd:(id)sender;

- (IBAction) cancelBlogDelete:(id)sender;
- (IBAction) confirmBlogDelete:(id)sender;

- (IBAction)cancelChanges:(id)sender;
- (IBAction)saveChanges:(id)sender;

@end
