//
//  JournlerLicenseManager.h
//  Journler
//
//  Created by Philip Dow on 4/10/08.
//  Copyright 2008 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SproutedUtilities/SproutedUtilities.h>

typedef enum {
	kJournlerLicenseInvalid = -1, 
	kJournlerLicensePersonal = 0,
	kJournlerLicenseNonPersonal = 1,
	kJournlerLicenseBeta = 2,
	kJournlerLicenseSpecial = 3,
	kJournlerLicenseFull = 9
} JournlerLicenseIdentifier;

@interface JournlerLicenseManager : NSObject {

}

+ (id) sharedManager;

- (NSInteger) licenseType;
- (int) licenseTypeForName:(NSString*)licenseName digest:(NSString*)proposedDigest;

@end
