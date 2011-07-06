/* AudioViewController */

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

#import "JournlerMediaContentController.h"

@interface AudioViewController : JournlerMediaContentController
{
    IBOutlet NSImageView *fileIcon;
    IBOutlet QTMovieView *player;
	IBOutlet NSView *containerView;
	
	IBOutlet NSTextField *_titleField;
	IBOutlet NSTextField *_authorsField;
	IBOutlet NSTextField *_durationField;
	IBOutlet NSTextField *_rateField;
	IBOutlet NSTextField *_locationField;
	
}

@end
