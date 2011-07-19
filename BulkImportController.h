/* BulkImportController */

#import <Cocoa/Cocoa.h>
#import <SproutedInterface/SproutedInterface.h>

@class JournlerJournal;
@class JournlerEntry;
@class JRLRBulkImport;
@class JournlerCollection;

@interface BulkImportController : NSWindowController
{
    
	BOOL _userInteraction;
	NSInteger datePreference;
	
	NSFileManager *fm;
	JRLRBulkImport		*importOptions;
	
	IBOutlet NSView					*optionsPlace;
	IBOutlet NSProgressIndicator	*progress;
	IBOutlet NSTextField			*progressLabel;
	IBOutlet PDGradientView			*gradient;
	
	JournlerJournal *journal;
	NSMutableString *importLog;
	
	NSMutableArray *rootFolders;
	NSMutableArray *allEntries;
}

- (id) initWithJournal:(JournlerJournal*)aJournal;

- (JournlerCollection*) targetCollection;
- (void) setTargetCollection:(JournlerCollection*)collection;

- (JournlerJournal*) journal;
- (void) setJournal:(JournlerJournal*)aJournal;

- (BOOL) userInteraction;
- (void) setUserInteraction:(BOOL)visual;

- (BOOL) preserveModificationDate;
- (void) setPreserveModificationDate:(BOOL)preserve;

- (void) setTargetDate:(NSCalendarDate*)date;

- (IBAction)cancel:(id)sender;
- (IBAction)help:(id)sender;
- (IBAction)okay:(id)sender;

- (int) runAsSheetForWindow:(NSWindow*)window attached:(BOOL)sheet 
		files:(NSArray*)filenames folders:(NSArray**)importedFolders entries:(NSArray**)importedEntries;

- (BOOL) importContentsOfDirectory:(NSString*)path targetFolder:(JournlerCollection*)parentFolder;
- (BOOL) importContentsOfFile:(NSString*)path targetFolder:(JournlerCollection*)parentFolder;

@end

