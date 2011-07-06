/* StatsController */

#import <Cocoa/Cocoa.h>

@interface StatsController : NSWindowController
{
    IBOutlet NSTextField *charsField;
    IBOutlet NSTextField *parsField;
    IBOutlet NSTextField *wordsField;
}

- (int) runAsSheetForWindow:(NSWindow*)window 
		attached:(BOOL)sheet
		chars:(int)charNum 
		words:(int)wordNum 
		pars:(int)parNum;

- (IBAction)genericStop:(id)sender;

@end
