//
//  NSString+JournlerUtilities.m
//  Journler
//
//  Created by Philip Dow on 8/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSString+JournlerUtilities.h"

@implementation NSString (NSString_JournlerUtilities)

- (NSArray*) jn_rangesOfString:(NSString*)aString options:(NSUInteger)mask range:(NSRange)aRange
{
	if ( aString == nil ) return nil;
	
	NSMutableArray *ranges = [NSMutableArray array];
	
	while ( aRange.location != NSNotFound && aRange.location < [self length] )
	{
		aRange = [self rangeOfString:aString options:mask range:aRange];
		if ( aRange.location == NSNotFound )
			break;
		
		[ranges addObject:[NSValue valueWithRange:aRange]];
		
		aRange.location = aRange.location + aRange.length;
        aRange.length = [self length] - aRange.location;
	}
	
	return ranges;
}

@end
