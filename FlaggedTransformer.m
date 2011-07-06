//
//  FlaggedTransformer.m
//  Cocoa Journler
//
//  Created by Philip Dow on 27.08.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "FlaggedTransformer.h"


@implementation FlaggedTransformer

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
	
	int int_value = [beforeObject intValue];
	
	if ( int_value == 1 )
		return [NSImage imageNamed:@"flagged.tif"];
	else if ( int_value == 2 )
		return [NSImage imageNamed:@"EntryChecked.png"];
	else
		return nil;
}

@end
