//
//  IndexTextCell.m
//  Journler
//
//  Created by Philip Dow on 2/7/07.
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
	CGFloat textHeight;
	
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
