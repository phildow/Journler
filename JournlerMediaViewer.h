/* MediaViewer */

#import <Cocoa/Cocoa.h>

#import "PageSetupController.h"
//#import "JUtility.h"

@class MediaContentController;
@class AudioViewController;
@class MovieViewController;
@class WebViewController;
@class PDPDFViewController;
@class ImageViewController;
@class AddressRecordController;

@interface JournlerMediaViewer : NSWindowController
{
	NSURL *homeURL;
	MediaContentController *_contentController;
	IBOutlet NSView *contentPlaceholder;
}

+ (BOOL) canDisplayMediaOfType:(NSString*)uti url:(NSURL*)aURL;
- (id) initWithURL:(NSURL*)url uti:(NSString*)uti;

- (id) representedObject;
- (void) setRepresentedObject:(id)anObject;

- (MediaContentController*) contentController;

- (BOOL) highlightString:(NSString*)aString;

- (IBAction) printDocument:(id)sender;

- (IBAction) save:(id)sender;
- (IBAction) exportSelection:(id)sender;

@end

@interface JournlerMediaViewer (CustomMenuSupport)

- (void) performCustomFindPanelAction:(id)sender;
- (void) performCustomTextSizeAction:(id)sender;

@end
