/* ConsoleController */

#import <Cocoa/Cocoa.h>

@interface ConsoleController : NSWindowController
{
    IBOutlet NSTextView *console;
	id	delegate;
}

- (int) runAsSheetForWindow:(NSWindow*)window attached:(BOOL)sheet;

- (id) delegate;
- (void) setDelegate:(id)anObject;

@end

@interface NSObject (ConsoleControllerDelegate)

- (NSString*) runConsoleCommand:(NSString*)command;

@end