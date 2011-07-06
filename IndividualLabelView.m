//
//  IndividualLabelView.m
//  Journler
//
//  Created by Phil Dow on 4/18/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "IndividualLabelView.h"

#import <SproutedUtilities/SproutedUtilities.h>

/*
#import "NSBezierPath_AMShading.h"
#import "NSBezierPath_AMAdditons.h"
#import "NSColor_JournlerAdditions.h"
*/

@implementation IndividualLabelView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		tag = 1;
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
	
	[[NSGraphicsContext currentContext] saveGraphicsState];
	
	NSRect inset = NSInsetRect(rect,2.5,2.5);
	
	NSColor *gradientStart = [NSColor colorForLabel:[self tag] gradientEnd:YES];
	NSColor *gradientEnd = [NSColor colorForLabel:[self tag] gradientEnd:NO];
	
	NSBezierPath *aPath = [NSBezierPath bezierPathWithRoundedRect:inset cornerRadius:7.3];
	
	[[NSColor colorWithCalibratedWhite:0.6 alpha:1.0] set];
		
	NSShadow *textShadow = [[NSShadow alloc] init];
	[textShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.3 alpha:0.64]];
	[textShadow setShadowOffset:NSMakeSize(0,-1)];

	[textShadow set];

	[aPath setLineWidth:1.0];
	[aPath stroke];
	
	[aPath linearGradientFillWithStartColor:gradientStart endColor:gradientEnd];
	
	[[NSGraphicsContext currentContext] restoreGraphicsState];
}

- (int) tag
{
	return tag;
}

- (void) setTag:(int)aTag
{
	tag = aTag;
}

@end
