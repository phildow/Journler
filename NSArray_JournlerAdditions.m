//
//  NSArray_JournlerAdditions.m
//  Journler
//
//  Created by Philip Dow on 11/3/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import "NSArray_JournlerAdditions.h"

#import "JournlerEntry.h"
#import "JournlerResource.h"
#import "JournlerCollection.h"
#import "JournlerJournal.h"

@implementation NSArray (JournlerAdditions)

- (NSArray*) arrayProducingURIRepresentations:(JournlerJournal*)journal
{
	NSMutableArray *uriReps = [NSMutableArray arrayWithCapacity:[self count]];
	
	id anObject;
	NSEnumerator *enumerator = [self objectEnumerator];
	while ( anObject = [enumerator nextObject] )
	{
		if ( [anObject respondsToSelector:@selector(URIRepresentation)] )
			[uriReps addObject:[anObject URIRepresentation]];
	}
	
	return uriReps;
}

- (NSArray*) arrayProducingJournlerObjects:(JournlerJournal*)journal
{
	NSMutableArray *journalObjects = [NSMutableArray arrayWithCapacity:[self count]];
	
	id anObject;
	NSEnumerator *enumerator = [self objectEnumerator];
	while ( anObject = [enumerator nextObject] )
	{
		id theObject = [journal objectForURIRepresentation:anObject];
		if ( [theObject isKindOfClass:[JournlerEntry class]] || [theObject isKindOfClass:[JournlerResource class]] ||
				[theObject isKindOfClass:[JournlerCollection class]] )
			[journalObjects addObject:theObject];
	}
	
	return journalObjects;
}

- (unsigned) indexOfObjectIdenticalToResource:(JournlerResource*)aResource
{
	// sends an isEqualToResource: message to each object in the receiver
	
	int i; unsigned foundIndex = NSNotFound;
	id anObject;
	for ( i = 0; i < [self count]; i++ )
	{
		anObject = [self objectAtIndex:i];
		if ( [anObject respondsToSelector:@selector(isEqualToResource:)] && [anObject isEqualToResource:aResource] )
		{
			foundIndex = i;
			break;
		}
	}
	
	return foundIndex;
}

@end
