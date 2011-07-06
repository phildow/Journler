/* CollectionManagerView */

#import <Cocoa/Cocoa.h>

@interface CollectionManagerView : NSView
{
	BOOL bordered;
	int numConditions;
}

- (int) numConditions;
- (void) setNumConditions:(int)num;

- (BOOL) bordered;
- (void) setBordered:(BOOL)drawsBorder;

@end