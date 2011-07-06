//
//  NSString+JournlerAdditions.m
//  Journler
//
//  Created by Philip Dow on 10/19/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NSString+JournlerAdditions.h"
#import <SproutedUtilities/SproutedUtilities.h>
#include <openssl/md5.h>

@implementation NSString (JournlerAdditions)

- (NSString*) journlerMD5Digest 
{	
	NSString *returnString = nil;
	NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
	if ( data ) 
	{
		NSMutableData *digest = [NSMutableData dataWithLength:MD5_DIGEST_LENGTH];
		if ( digest && MD5([data bytes], [data length], [digest mutableBytes])) {
			NSString *digestAsString = [digest description];
			returnString = digestAsString;
		}
	}
	
	return returnString;
}

- (NSString*) formattedMD5DigestForLicense:(int)licenseType version:(int)licenseVersion
{
	// generates the journler license
	NSString *digest;
	
	if ( licenseVersion == 210 || licenseVersion == 260 )
	{
		int i;
		BOOL negate = NO;
		unichar characters[200]; //max lenth is two hu
		for ( i = 0; i < [self length]; i++ )
		{
			if ( i >= 199 )
				break;
			
			unichar characterAtIndex = [self characterAtIndex:i];
			characters[i] = ( negate ? characterAtIndex - i : characterAtIndex + i );
			if ( characters[i] <= 0 )
				characters[i] = 1;
			
			// adjust the last character depending on the license type
			if ( i == [self length] - 1 ) 
				characters[i] = characters[i] + licenseType;
				
			// I was supposed to be doing this before, or?
			if ( licenseVersion == 260 )
				negate = !negate;
			
		}
		
		NSString *modifedSelf = [NSString stringWithCharacters:characters length:i];
		if ( modifedSelf == nil )
			return nil;
		
		NSMutableString *digestedSelf = [[[modifedSelf journlerMD5Digest] mutableCopyWithZone:[self zone]] autorelease];
		if ( digestedSelf == nil )
			return nil;
		
		[digestedSelf replaceOccurrencesOfString:@"<" withString:@"" options:0 range:NSMakeRange(0,[digestedSelf length])];
		[digestedSelf replaceOccurrencesOfString:@">" withString:@"" options:0 range:NSMakeRange(0,[digestedSelf length])];
		[digestedSelf replaceOccurrencesOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] withString:@"" 
				options:0 range:NSMakeRange(0,[digestedSelf length])];
		
		digest = [[digestedSelf substringToIndex:16] uppercaseString];
	}
	else
	{
		digest = nil;
	}
	
	return digest;
}

#pragma mark -

- (BOOL) isWellformedURL
{
	// right now the method only checks for http:// links with any text after the http:// 
	// that can be initialized by nsurl
	
	static NSString *httpScheme = @"http://";
	
	if ( [self rangeOfString:httpScheme options:NSCaseInsensitiveSearch].location == 0 )
		return ( [self length] > [httpScheme length] && ( [NSURL URLWithString:self] != nil ) );
	else return NO;
}

@end
