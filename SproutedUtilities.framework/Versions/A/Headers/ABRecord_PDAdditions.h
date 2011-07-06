//
//  ABRecord_PDAdditions.h
//  SproutedUtilities
//
//  Created by Philip Dow on 9/30/06.
//  Copyright 2006 Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AddressBook/AddressBook.h>
#import <AddressBook/AddressBookUI.h>

@interface ABRecord (PDAdditions)

- (NSString*) fullname;
- (NSImage*) image;

- (NSString*) note;
- (NSString*) emailAddress;
- (NSString*) website;

- (NSString*) htmlRepresentationWithCache:(NSString*)cachePath;

@end
