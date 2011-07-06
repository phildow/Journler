

#import <Cocoa/Cocoa.h>

@interface PDPopUpButtonToolbarItemCell : NSPopUpButtonCell 
{
	
	NSSize size;
}

- (NSSize) iconSize;
- (void) setIconSize:(NSSize)aSize;

@end
