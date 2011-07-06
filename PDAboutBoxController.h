/* PDAboutBoxController */

#import <Cocoa/Cocoa.h>

@class PDScrollingText;

@interface PDAboutBoxController : NSWindowController
{
    IBOutlet NSTextView			*additionalText;
    IBOutlet NSTextField		*appnameField;
	//IBOutlet NSTextField		*copyrightField;
    IBOutlet NSImageView		*imageView;
    IBOutlet NSTextField		*versionField;
	IBOutlet PDScrollingText	*mainText;
	IBOutlet NSTextView			*aboutText;
}

+ (id)sharedController;

- (IBAction) showAboutBox:(id)sender;
- (IBAction) doSomething:(id)sender;
@end
