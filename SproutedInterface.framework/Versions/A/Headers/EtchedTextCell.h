/* MyTitleCell */

// NOTE TO SELF: where did this come from?

#import <Cocoa/Cocoa.h>

@interface EtchedTextCell : NSTextFieldCell
{
	NSColor *mShadowColor;
}

-(void)setShadowColor:(NSColor *)aColor;

@end
