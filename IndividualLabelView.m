//
//  IndividualLabelView.m
//  Journler
//
//  Created by Philip Dow on 4/18/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

/*
 Redistribution and use in source and binary forms, with or without modification, are permitted
 provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions
 and the following disclaimer in the documentation and/or other materials provided with the
 distribution.
 
 * Neither the name of the author nor the names of its contributors may be used to endorse or
 promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// Basically, you can use the code in your free, commercial, private and public projects
// as long as you include the above notice and attribute the code to Philip Dow / Sprouted
// If you use this code in an app send me a note. I'd love to know how the code is used.

// Please also note that this copyright does not supersede any other copyrights applicable to
// open source code used herein. While explicit credit has been given in the Journler about box,
// it may be lacking in some instances in the source code. I will remedy this in future commits,
// and if you notice any please point them out.

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

- (NSInteger) tag
{
	return tag;
}

- (void) setTag:(NSInteger)aTag
{
	tag = aTag;
}

@end
