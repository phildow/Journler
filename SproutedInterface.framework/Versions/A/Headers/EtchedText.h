/* EtchedText */

// NOTE TO SELF: where did this come from?

#import <Cocoa/Cocoa.h>

@interface EtchedText : NSTextField
{
}

+ (Class)cellClass;
-(void)setShadowColor:(NSColor *)color;

@end
