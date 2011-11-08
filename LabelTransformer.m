//
//  LabelTransformer.m
//  Journler
//
//  Created by Philip Dow on 3/12/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
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

#import "LabelTransformer.h"
#import <SproutedUtilities/SproutedUtilities.h>

@implementation LabelTransformer

- (id) init {
	
	if ( self = [super init] ) {
		
		//
		// prep the images
		
		// the entire label image
		NSImage *allLabels = BundledImageWithName(@"labelall.tif", @"com.sprouted.interface");
		
		// individual labels
		NSImage *redLabel = [[[NSImage alloc] initWithSize:NSMakeSize(17,16)] autorelease];
		NSImage *orangeLabel = [[[NSImage alloc] initWithSize:NSMakeSize(17,16)] autorelease];
		NSImage *yellowLabel = [[[NSImage alloc] initWithSize:NSMakeSize(17,16)] autorelease];
		NSImage *greenLabel = [[[NSImage alloc] initWithSize:NSMakeSize(17,16)] autorelease];
		NSImage *blueLabel = [[[NSImage alloc] initWithSize:NSMakeSize(17,16)] autorelease];
		NSImage *purpleLabel = [[[NSImage alloc] initWithSize:NSMakeSize(17,16)] autorelease];
		NSImage *greyLabel = [[[NSImage alloc] initWithSize:NSMakeSize(17,16)] autorelease];
		
		NSRect clearRect = NSMakeRect(0,0,17,16);
		
		NSRect redRect = NSMakeRect(22,0,17,16);
		NSRect orangeRect = NSMakeRect(40,0,17,16);
		NSRect yellowRect = NSMakeRect(58,0,17,16);
		
		NSRect greenRect = NSMakeRect(76,0,17,16);
		NSRect blueRect = NSMakeRect(94,0,17,16);
		NSRect purpleRect = NSMakeRect(112,0,17,16);
		NSRect greyRect = NSMakeRect(130,0,17,16);
		
		// draw into each individual label
		[redLabel lockFocus];
		[allLabels drawInRect:clearRect fromRect:redRect operation:NSCompositeSourceOver fraction:1.0];
		[redLabel unlockFocus];
		
		[orangeLabel lockFocus];
		[allLabels drawInRect:clearRect fromRect:orangeRect operation:NSCompositeSourceOver fraction:1.0];
		[orangeLabel unlockFocus];
		
		[yellowLabel lockFocus];
		[allLabels drawInRect:clearRect fromRect:yellowRect operation:NSCompositeSourceOver fraction:1.0];
		[yellowLabel unlockFocus];
		
		[greenLabel lockFocus];
		[allLabels drawInRect:clearRect fromRect:greenRect operation:NSCompositeSourceOver fraction:1.0];
		[greenLabel unlockFocus];
		
		[blueLabel lockFocus];
		[allLabels drawInRect:clearRect fromRect:blueRect operation:NSCompositeSourceOver fraction:1.0];
		[blueLabel unlockFocus];
		
		[purpleLabel lockFocus];
		[allLabels drawInRect:clearRect fromRect:purpleRect operation:NSCompositeSourceOver fraction:1.0];
		[purpleLabel unlockFocus];
		
		[greyLabel lockFocus];
		[allLabels drawInRect:clearRect fromRect:greyRect operation:NSCompositeSourceOver fraction:1.0];
		[greyLabel unlockFocus];

		
		labelImages = [[NSArray alloc] initWithObjects:
		redLabel, orangeLabel, yellowLabel, greenLabel, blueLabel, purpleLabel, greyLabel, nil];
		
	}
	
	return self;
	
}

- (void) dealloc {
	
	[labelImages release];
		labelImages = nil;
	
	[super dealloc];
	
}

#pragma mark -

+ (Class)transformedValueClass
{
    return [NSString self];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)beforeObject
{
	
	//
	// takes before object as a number and creates a rank image from it
	// - assumes that the beforeObject value is on a scale from 0 to 100
	//
	
	NSInteger val = [beforeObject integerValue];
	NSImage *returnImage = nil;
	
	if ( val != 0 && val <= [labelImages count] )
		returnImage = [labelImages objectAtIndex:(val-1)];
	
	return returnImage;
}


@end
