/* LinkController */

#import <Cocoa/Cocoa.h>

@interface LinkController : NSWindowController
{
	IBOutlet NSObjectController *objectController;
   
	IBOutlet NSTextField *linkField;
    IBOutlet NSTextField *urlField;
	
	NSString *_linkString;
	NSString *_URLString;
}

- (id) initWithLink:(NSString*)link URL:(NSString*)url;

- (int) runAsSheetForWindow:(NSWindow*)window attached:(BOOL)sheet;

- (NSString*) linkString;
- (void) setLinkString:(NSString*)string;

- (NSString*) URLString;
- (void) setURLString:(NSString*)string;

- (IBAction)genericCancel:(id)sender;
- (IBAction)genericOkay:(id)sender;

@end
