/* ActivityViewer */

#import <Cocoa/Cocoa.h>

@class JournlerJournal;

@interface ActivityViewer : NSWindowController
{
    IBOutlet NSTextView *textView;
	
	JournlerJournal *journal;
}

+ (id) sharedActivityViewer;
- (id) initWithJournal:(JournlerJournal*)aJournal;

- (JournlerJournal*) journal;
- (void) setJournal:(JournlerJournal*)aJournal;

@end
