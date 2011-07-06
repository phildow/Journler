/* ImageViewController */

#import <Cocoa/Cocoa.h>
#import "JournlerMediaContentController.h"

@class PDExportableImageView;

@interface ImageViewController : JournlerMediaContentController
{
    IBOutlet PDExportableImageView *_imageView;
	IBOutlet NSMenu	*_contextual;
	
}
- (IBAction)openInNewWindow:(id)sender;
- (IBAction)openInPreview:(id)sender;

@end
