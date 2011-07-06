/* MovieViewController */

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

#import "JournlerMediaContentController.h"

@interface MovieViewController : JournlerMediaContentController
{
	IBOutlet NSView *movieContainer;
    IBOutlet QTMovieView *movieView;
	IBOutlet NSPopUpButton *scalePop;
	
	int current_scale;
}

- (IBAction) openWithQuicktime:(id)sender;

- (IBAction) setScale:(id)sender;

- (NSSize) _containerSizeForMovieSize:(NSSize)movieSize scale:(float)sizeMultiple;
- (void) movieContainerFrameChanged:(NSNotification*)aNotification;

@end
