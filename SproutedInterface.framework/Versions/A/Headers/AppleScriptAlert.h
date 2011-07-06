/* AppleScriptAlert */

#import <Cocoa/Cocoa.h>

@interface AppleScriptAlert : NSWindowController
{
    IBOutlet NSTextView *errorView;
    IBOutlet NSTextView *sourceView;
	
	id source;
	id error;
}

- (id) initWithSource:(id)source error:(id)error;

@end
