//
//  NSManagedObjectContext_PDCategory.h
//  SproutedUtilities
//
//  Created by Philip Dow on 5/14/07.
//  Copyright 2007 Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (PDCategory)

- (NSManagedObject*) managedObjectForURIRepresentation:(NSURL *)aURL;
- (NSManagedObject*) managedObjectRegisteredForURIRepresentation:(NSURL*)aURL;

- (NSManagedObject*) managedObjectForUUIDRepresentation:(NSURL*)aURL;
- (NSManagedObject*) managedObjectForUUID:(NSString*)uuid entity:(NSString*)entityName;

@end
