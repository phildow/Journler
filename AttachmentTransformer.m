//
//  AttachmentTransformer.m
//  Journler
//
//  Created by Phil Dow on 1/30/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "AttachmentTransformer.h"


@implementation AttachmentTransformer

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
	
	if ( [beforeObject intValue] != 0 )
		return [NSString stringWithFormat:@"%i",[beforeObject intValue]];
	else
		return nil;
}

@end
