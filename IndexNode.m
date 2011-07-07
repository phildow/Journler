//
//  IndexNode.m
//  Journler
//
//  Created by Philip Dow on 2/6/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "IndexNode.h"


@implementation IndexNode

- (id) init
{
	if ( self = [super init] )
	{
		count = 0;
		title = [[NSString alloc] init];
		representedObject = nil;
		
		parent = nil;
		children = [[NSArray alloc] init];
	}
	return self;
}

- (void) dealloc
{
	//#ifdef __DEBUG__
	//NSLog(@"%s",__PRETTY_FUNCTION__);
	//#endif
	
	[title release], title = nil;
	[representedObject release], representedObject = nil;
	
	//[parent release]; // parent is a weak reference
	
	//[children setValue:nil forKey:@"parent"];
	[children release], children = nil;
	
	[super dealloc];
}

#pragma mark -

- (id)copyWithZone:(NSZone *)zone
{
	IndexNode *newNode = [[[self class] allocWithZone:zone] init];
	
	[newNode setParent:[self parent]];
	[newNode setChildren:[self children]];
	
	[newNode setTitle:[self title]];
	[newNode setRepresentedObject:[self representedObject]];
	
	newNode->count = count;
	newNode->frequency = frequency;
	
	return newNode;
}

#pragma mark -

- (int) count
{
	return count;
}

- (void) setCount:(int)aCount
{
	count = aCount;
}

- (int) frequency
{
	return frequency;
}

- (void) setFrequency:(int)aFrequency
{
	frequency = aFrequency;
}

- (NSString*) title
{
	return title;
}

- (void) setTitle:(NSString*)aString
{
	if ( title != aString )
	{
		[title release];
		title = [aString copyWithZone:[self zone]];
	}
}

- (id) representedObject
{
	return representedObject;
}

- (void) setRepresentedObject:(id)anObject
{
	if ( representedObject != anObject )
	{
		[representedObject release];
		representedObject = [anObject retain];
	}
}

#pragma mark -

- (IndexNode*) parent
{
	return parent;
}

- (void) setParent:(IndexNode*)aNode
{
	if ( parent != aNode )
	{
		//[parent release];
		//parent = [aNode retain];
		parent = aNode;
	}
}

- (NSArray*) children
{
	return children;
}

- (void) setChildren:(NSArray*)anArray
{
	if ( children != anArray )
	{
		//[children setValue:nil forKey:@"parent"];
		
		[children release];
		children = [anArray retain];
		
		[children setValue:self forKey:@"parent"];
	}
}

#pragma mark -

- (unsigned) childCount
{
	return (unsigned)[children count];
}

- (BOOL) isLeaf
{
	return ( [children count] == 0 );
}

@end
