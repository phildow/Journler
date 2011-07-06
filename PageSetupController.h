/* PageSetupController */

#import <Cocoa/Cocoa.h>

@interface PageSetupController : NSObject
{
    IBOutlet NSView *contentView;
}

+ (id) sharedPageSetup;

- (NSView*) contentView;

@end
