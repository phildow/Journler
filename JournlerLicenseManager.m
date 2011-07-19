//
//  JournlerLicenseManager.m
//  Journler
//
//  Created by Philip Dow on 4/10/08.
//  Copyright 2008 Sprouted, Philip Dow. All rights reserved.
//

#import "JournlerLicenseManager.h"
#import "NSString+JournlerAdditions.h"

static NSArray * BannedLicenseNames()
{
	static NSArray *array = nil;
	if ( array == nil ) 
	{
		array = [[NSArray alloc] initWithObjects:
			@"Special [k]", nil];
	}
	
	return array;
}

@implementation JournlerLicenseManager

+ (id)sharedManager 
{
    static JournlerLicenseManager *sharedManager = nil;
    if (!sharedManager) sharedManager = [[JournlerLicenseManager allocWithZone:NULL] init];
	return sharedManager;
}

- (NSInteger) licenseType
{
	NSInteger licenseType;
	
	NSString *dLicenseName = [[NSUserDefaults standardUserDefaults] stringForKey:@"LicenseName"];
	NSString *dLicenseCode = [[NSUserDefaults standardUserDefaults] stringForKey:@"LicenseCode"];
	
	if ( dLicenseName == nil || dLicenseCode == nil )
		licenseType = kJournlerLicenseInvalid;
	else
		licenseType = [self licenseTypeForName:dLicenseName 
				digest:dLicenseCode];
	
	return licenseType;
}

- (NSInteger) licenseTypeForName:(NSString*)licenseName digest:(NSString*)proposedDigest
{
	NSInteger myLicense;
	
	if ( [BannedLicenseNames() containsObject:licenseName] )
	{
		myLicense = kJournlerLicenseInvalid;
	}
	else
	{
	
	#ifdef __BETA__
		
		NSString *licenseDigestBeta =		[licenseName formattedMD5DigestForLicense:2 version:210];
		NSString *licenseDigestJournler =	[licenseName formattedMD5DigestForLicense:3 version:210];
		
		if ( [[proposedDigest uppercaseString] isEqualToString:[licenseDigestBeta uppercaseString]] )
			myLicense = kJournlerLicenseBeta;
		else if ( [[proposedDigest uppercaseString] isEqualToString:[licenseDigestJournler uppercaseString]] )
			myLicense = kJournlerLicenseSpecial;
		else
			myLicense = kJournlerLicenseInvalid;
		
	#else 
		
		NSString *licenseDigestPersonal =	[licenseName formattedMD5DigestForLicense:0 version:210];
		NSString *licenseDigestBusiness =	[licenseName formattedMD5DigestForLicense:1 version:210];
		NSString *licenseDigestJournler =	[licenseName formattedMD5DigestForLicense:3 version:210];
		
		NSString *licenseDigestFull =		[licenseName formattedMD5DigestForLicense:9 version:260];
		
		if ( [[proposedDigest uppercaseString] isEqualToString:[licenseDigestPersonal uppercaseString]] )
			myLicense = kJournlerLicensePersonal;
		else if ( [[proposedDigest uppercaseString] isEqualToString:[licenseDigestBusiness uppercaseString]] )
			myLicense = kJournlerLicenseNonPersonal;
		else if ( [[proposedDigest uppercaseString] isEqualToString:[licenseDigestJournler uppercaseString]] )
			myLicense = kJournlerLicenseSpecial;
		else if ( [[proposedDigest uppercaseString] isEqualToString:[licenseDigestFull uppercaseString]] )
			myLicense = kJournlerLicenseFull;
		else
			myLicense = kJournlerLicenseInvalid;
		
	#endif

	}
	
	return myLicense;
}

@end
