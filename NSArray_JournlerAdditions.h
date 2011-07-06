//
//  NSArray_JournlerAdditions.h
//  Journler
//
//  Created by Phil Dow on 11/3/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JournlerJournal;
@class JournlerResource;

@interface NSArray (JournlerAdditions)

- (NSArray*) arrayProducingURIRepresentations:(JournlerJournal*)journal;
- (NSArray*) arrayProducingJournlerObjects:(JournlerJournal*)journal;

- (unsigned) indexOfObjectIdenticalToResource:(JournlerResource*)aResource;

@end
