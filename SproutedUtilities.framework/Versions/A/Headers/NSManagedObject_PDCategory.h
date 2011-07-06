//
//  NSManagedObject_PDCategory.h
//  SproutedUtilities
//
//  Created by Philip Dow on 5/14/07.
//  Copyright 2007 Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSManagedObject (PDCategory)

- (NSURL*) URIRepresentation;
- (NSURL*) UUIDURIRepresentation;

@end
