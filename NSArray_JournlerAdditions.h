//
//  NSArray_JournlerAdditions.h
//  Journler
//
//  Created by Philip Dow on 11/3/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JournlerJournal;
@class JournlerResource;

@interface NSArray (JournlerAdditions)

- (NSArray*) arrayProducingURIRepresentations:(JournlerJournal*)journal;
- (NSArray*) arrayProducingJournlerObjects:(JournlerJournal*)journal;

- (NSUInteger) indexOfObjectIdenticalToResource:(JournlerResource*)aResource;

@end
