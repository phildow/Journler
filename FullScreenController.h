/* FullScreenController */

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>


#import "JournlerWindowController.h"
#import "JournalWindowController.h"

@class JournlerEntry;
@class JournlerJournal;
@class JournlerPlugin;

@class FullScreenWindow;
@class BrowseTableFieldEditor;

@interface FullScreenController : JournalWindowController
{
	//IBOutlet NSView *initalTabPlaceholder;
	//IBOutlet BrowseTableFieldEditor	*browseTableFieldEditor;
	
	JournlerWindowController *callingController;
}

+ (void) enableFullscreenMode;
- (BOOL) isFullScreenController;

- (id) initWithJournal:(JournlerJournal*)aJournal callingController:(JournlerWindowController*)aController;

- (JournlerWindowController*) callingController;
- (void) setCallingController:(JournlerWindowController*)aWindowController;

@end
