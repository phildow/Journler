//
//  AutoCorrectWordPair.m
//  Journler
//
//  Created by Phil Dow on 11/17/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AutoCorrectWordPair.h"


@implementation AutoCorrectWordPair

- (id) init
{
	return [self initWithMisspelledWord:[NSString string] correctWord:[NSString string]];
}

- (id) initWithMisspelledWord:(NSString*)incorrect correctWord:(NSString*)correct
{
	if ( self = [super init] )
	{
		misspelledWord = [incorrect retain];
		correctWord = [correct retain];
	}
	return self;
}

- (void) dealloc
{
	[misspelledWord release];
	[correctWord release];
	
	[super dealloc];
}

- (NSString*) misspelledWord
{
	return misspelledWord;
}

- (void) setMisspelledWord:(NSString*)aString
{
	if ( misspelledWord != aString )
	{
		[misspelledWord release];
		misspelledWord = [aString retain];
	}
}

- (NSString*) correctWord
{
	return correctWord;
}

- (void) setCorrectWord:(NSString*)aString
{
	if ( correctWord != aString )
	{
		[correctWord release];
		correctWord = [aString retain];
	}
}

@end
