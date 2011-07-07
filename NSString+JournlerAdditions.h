//
//  NSString+JournlerAdditions.h
//  Journler
//
//  Created by Philip Dow on 10/19/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (JournlerAdditions)

- (NSString*) journlerMD5Digest;
- (NSString*) formattedMD5DigestForLicense:(int)licenseType version:(int)licenseVersion;

- (BOOL) isWellformedURL;

@end
