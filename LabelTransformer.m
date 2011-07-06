//
//  LabelTransformer.m
//  Journler
//
//  Created by Philip Dow on 3/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

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
	
	int val = [beforeObject intValue];
	NSImage *returnImage = nil;
	
	if ( val != 0 && val <= [labelImages count] )
		returnImage = [labelImages objectAtIndex:(val-1)];
	
	return returnImage;
}


@end
