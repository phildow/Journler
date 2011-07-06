/* IntegrationCopyFiles */

#import <Cocoa/Cocoa.h>

@interface IntegrationCopyFiles : NSWindowController
{
	IBOutlet NSObjectController *controller;
	IBOutlet NSProgressIndicator *progress;
	
	NSString *noticeText;
}

- (NSString*)noticeText;
- (void) setNoticeText:(NSString*)aString;

- (void) runNotice;
- (void) endNotice;

@end
