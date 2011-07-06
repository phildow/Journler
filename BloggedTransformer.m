//
//  RankTransformer.m
//  Cocoa Journler
//
//  Created by Philip Dow on 27.08.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BloggedTransformer.h"


@implementation BloggedTransformer

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
	
	if ( [beforeObject boolValue] )
		return [NSImage imageNamed:@"browseblogged.tif"];
	else
		return nil;
}

@end
