//
//  NSURL+JournlerAdditions.h
//  Journler
//
//  Created by Philip Dow on 6/7/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSURL (JournlerAdditions)

- (BOOL) isJournlerURI;
- (BOOL) isJournlerHelpURI;
- (BOOL) isJournlerLicenseURI;

- (BOOL) isJournlerEntry;
- (BOOL) isJournlerResource;
- (BOOL) isJournlerFolder;

- (BOOL) isAddressBookUID;
- (BOOL) isPhotoID;
- (BOOL) isOldJournlerResource;

- (BOOL) isHTTP;

@end
