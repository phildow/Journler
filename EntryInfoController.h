/* EntryInfoController */

#import <Cocoa/Cocoa.h>
#import <SproutedInterface/SproutedInterface.h>

@class JournlerJournal;
@class JournlerEntry;

@interface EntryInfoController : NSWindowController
{
    // Main inteface
	
	IBOutlet NSTableView	*blogsTable;
    IBOutlet NSComboBox		*category;
    
    IBOutlet NSTextField	*location;
    IBOutlet NSTextField	*title;
	
	IBOutlet NSTextView		*comments;
	IBOutlet NSTokenField	*tags;
	
	IBOutlet LabelPicker	*label;
	
	IBOutlet NSObjectController *objectController;
	IBOutlet NSArrayController *blogListController;
	
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
	
	IBOutlet NSDatePicker	*dateAndTime;
	
	NSString			*entryLocation;
	NSCalendarDate		*entryDate;
	NSCalendarDate		*entryDateDue;
	BOOL clearsDateDue;
	
	// entry is a weak reference while representedEntry is a copy
	// allows me to save or cancel changes made
	
	JournlerJournal *journal;
	JournlerEntry *entry;
	JournlerEntry *representedEntry;
	
	NSMutableArray *blogs;
	NSArray *tagCompletions;

}

- (NSString*) entryLocation;
- (void) setEntryLocation:(NSString*)string;

- (NSCalendarDate*) entryDate;
- (void) setEntryDate:(NSCalendarDate*)date;

- (NSCalendarDate*) entryDateDue;
- (void) setEntryDateDue:(NSCalendarDate*)date;

- (JournlerJournal*) journal;
- (void) setJournal:(JournlerJournal*)aJournal;

- (JournlerEntry*) entry;
- (void) setEntry:(JournlerEntry*)object;

- (JournlerEntry*) representedEntry;
- (void) setRepresentedEntry:(JournlerEntry*)object;

- (NSArray*) blogs;
- (void) setBlogs:(NSArray*)newBlogs;

- (NSArray*) tagCompletions;
- (void) setTagCompletions:(NSArray*)anArray;

- (BOOL) clearsDateDue;
- (void) setClearsDateDue:(BOOL)clears;

- (IBAction)addBlog:(id)sender;
- (IBAction)cancelChanges:(id)sender;
- (IBAction)editBlogList:(id)sender;
- (IBAction)removeBlog:(id)sender;
- (IBAction)saveChanges:(id)sender;
- (IBAction)showHelp:(id)sender;

- (IBAction) cancelBlogAdd:(id)sender;
- (IBAction) confirmBlogAdd:(id)sender;

- (IBAction) cancelBlogDelete:(id)sender;
- (IBAction) confirmBlogDelete:(id)sender;

@end
