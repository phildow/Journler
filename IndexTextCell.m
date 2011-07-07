//
//  IndexTextCell.m
//  Journler
//
//  Created by Philip Dow on 2/7/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "IndexTextCell.h"

#import <SproutedUtilities/SproutedUtilities.h>

/*
#import "NSBezierPath_AMShading.h"
#import "NSBezierPath_AMAdditons.h"
*/

@implementation IndexTextCell

/*
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView 
{
	 if ([self isHighlighted]) {
		
		NSColor *gradientStart, *gradientEnd;
		
		NSRect controlBds = [controlView bounds];
		//NSRect gradientBounds = NSMakeRect(controlBds.origin.x, cellFrame.origin.y+1, 
		//		controlBds.size.width, cellFrame.size.height-1);
		
		NSRect gradientBounds = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, 
				cellFrame.size.width, cellFrame.size.height-1);
		
		if (([[controlView window] firstResponder] == controlView) && [[controlView window] isMainWindow] &&
				[[controlView window] isKeyWindow]) {
			
			//bottomColor = [NSColor colorWithCalibratedRed:91.0/255.0 green:129.0/255.0 blue:204.0/255.0 alpha:1.0];
			gradientStart = [NSColor colorWithCalibratedRed:136.0/255.0 green:165.0/255.0 blue:212.0/255.0 alpha:1.0];
			gradientEnd = [NSColor colorWithCalibratedRed:102.0/255.0 green:133.0/255.0 blue:183.0/255.0 alpha:1.0];
			
		} else {
			
			//bottomColor = [NSColor colorWithCalibratedRed:140.0/255.0 green:152.0/255.0 blue:176.0/255.0 alpha:0.9];
			gradientStart = [NSColor colorWithCalibratedRed:172.0/255.0 green:186.0/255.0 blue:207.0/255.0 alpha:0.9];
			gradientEnd = [NSColor colorWithCalibratedRed:152.0/255.0 green:170.0/255.0 blue:196.0/255.0 alpha:0.9];
		}
		
		[[NSBezierPath bezierPathWithRect:gradientBounds] linearGradientFillWithStartColor:
				gradientStart endColor:gradientEnd];
	}
	
	[super drawWithFrame:cellFrame inView:controlView];
	//[self drawInteriorWithFrame:cellFrame inView:controlView];
}
*/
/*
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	int textHeight;
	
	NSRect inset = cellFrame;
	NSMutableDictionary *attrs;
	NSAttributedString *attrStringValue = [self attributedStringValue];
	
	if ( attrStringValue != nil && [attrStringValue length] != 0)
		attrs = [[[attrStringValue attributesAtIndex:0 effectiveRange:NULL] mutableCopyWithZone:[self zone]] autorelease];
	else
		attrs = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSFont systemFontOfSize:11], NSFontAttributeName,
				[self textColor], NSForegroundColorAttributeName, nil];
	
	
	if ([self isHighlighted]) 
	{
		// prepare the text in white
		[attrs setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
		
		NSFont *originalFont = [attrs objectForKey:NSFontAttributeName];
		if ( originalFont ) {
			NSFont *boldedFont = [[NSFontManager sharedFontManager] convertFont:originalFont toHaveTrait:NSBoldFontMask];
			if ( boldedFont ) [attrs setValue:boldedFont forKey:NSFontAttributeName];
		}
		
	} 
	else {
		// prepare the text in black.
		[attrs setValue:[self textColor] forKey:NSForegroundColorAttributeName];
	}
	
	
	// modify the inset some
	//inset.origin.x += 2;
	//inset.size.width -= 4;
	
	// center the text and take into account the required inset
	textHeight = [[self stringValue] sizeWithAttributes:attrs].height;
	inset.origin.y = inset.origin.y + (inset.size.height/2 - textHeight/2);
	inset.size.height = textHeight;
	
	// actually draw the title
	[[self stringValue] drawInRect:inset withAttributes:attrs];
}
*/


- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	return nil;
}

- (NSColor*) textColor {
	
	if ( [self isHighlighted] )
		return [NSColor whiteColor];
	else
		return [super textColor];
	
}

@end
