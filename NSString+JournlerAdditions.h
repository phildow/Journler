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
- (NSString*) formattedMD5DigestForLicense:(NSInteger)licenseType version:(NSInteger)licenseVersion;

- (BOOL) isWellformedURL;

@end
