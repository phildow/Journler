//
//  PDSingletons.h
//  Journler
//
//  Created by Philip Dow on 4/29/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>

static NSNumber *BooleanNumber(BOOL isTrue)
{
	static NSNumber *amTrue = nil;
	static NSNumber *amNotTrue = nil;
	
	if ( isTrue )
	{
		if ( amTrue == nil ) amTrue = [[NSNumber alloc] initWithBool:YES];
		return amTrue;
	}
	else
	{
		if ( amNotTrue == nil ) amNotTrue = [[NSNumber alloc] initWithBool:NO];
		return amNotTrue;
	}
}

static NSNumber *ZeroNumber()
{
	static NSNumber *zeroNumber = nil;
	if ( zeroNumber == nil ) zeroNumber = [[NSNumber alloc] initWithInt:0];
	return zeroNumber;
}

static NSString *EmptyString()
{
	static NSString *emptyString = nil;
	if ( emptyString == nil ) emptyString = [[NSString alloc] init];
	return emptyString;
}

static NSArray *EmptyArray()
{
	static NSArray *emptyArray = nil;
	if ( emptyArray == nil ) emptyArray = [[NSArray alloc] init];
	return emptyArray;
}
