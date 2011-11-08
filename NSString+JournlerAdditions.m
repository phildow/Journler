//
//  NSString+JournlerAdditions.m
//  Journler
//
//  Created by Philip Dow on 10/19/07.
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

- (NSString*) formattedMD5DigestForLicense:(NSInteger)licenseType version:(NSInteger)licenseVersion
{
	// generates the journler license
	NSString *digest;
	
	if ( licenseVersion == 210 || licenseVersion == 260 )
	{
		NSInteger i;
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
