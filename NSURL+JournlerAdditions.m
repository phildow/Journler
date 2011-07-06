//
//  NSURL+JournlerAdditions.m
//  Journler
//
//  Created by Philip Dow on 6/7/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NSURL+JournlerAdditions.h"


@implementation NSURL (JournlerAdditions)

- (BOOL) isJournlerURI
{
	static NSString *journler_scheme = @"journler";
	return [[self scheme] isEqualToString:journler_scheme];
}

- (BOOL) isJournlerHelpURI
{
	static NSString *help_host = @"help";
	return [[self host] isEqualToString:help_host];
}

- (BOOL) isJournlerLicenseURI
{
	static NSString *license_host = @"license";
	return [[self host] isEqualToString:license_host];
}

- (BOOL) isJournlerEntry 
{
	static NSString *entry_host = @"entry";
	return [[self host] isEqualToString:entry_host];
}

- (BOOL) isJournlerResource 
{
	static NSString *resource_host = @"reference";
	return [[self host] isEqualToString:resource_host];
}

- (BOOL) isJournlerFolder
{
	static NSString *resource_host = @"folder";
	return [[self host] isEqualToString:resource_host];
}

#pragma mark -

- (BOOL) isOldJournlerResource
{
	static NSString *resource_host = @"resource";
	return [[self host] isEqualToString:resource_host];
}

- (BOOL) isAddressBookUID
{
	static NSString *abUID_scheme = @"AddressBookUID";
	return [[self scheme] isEqualToString:abUID_scheme];
}

- (BOOL) isPhotoID
{
	static NSString *photoID_scheme = @"iPhotoID";
	return [[self scheme] isEqualToString:photoID_scheme];
}

- (BOOL) isHTTP
{
	static NSString *http_scheme = @"http";
	return [[self scheme] isEqualToString:http_scheme];
}

@end
