/* LoadErrorReporter */

#import <Cocoa/Cocoa.h>

@class JournlerJournal;

@interface LoadErrorReporter : NSWindowController
{
    IBOutlet NSArrayController *errorController;
    IBOutlet NSTableView *errorTable;
	
	JournlerJournal *journal;
	NSArray *errorInfo;
}

- (id) initWithJournal:(JournlerJournal*)aJournal errors:(NSArray*)errorInfo;
- (IBAction)dismiss:(id)sender;
- (IBAction) showHelp:(id)sender;

- (JournlerJournal*) journal;
- (void) setJournal:(JournlerJournal*)aJournal;

- (NSArray*) errorInfo;
- (void) setErrorInfo:(NSArray*)anArray;

@end
