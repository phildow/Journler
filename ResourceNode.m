//
//  ResourceNode.m
//  Journler
//
//  Created by Philip Dow on 11/12/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import "ResourceNode.h"


@implementation ResourceNode

- (id) init
{
	self = [super init];
	
	parent = nil;
	label = [[NSNumber alloc] initWithBool:NO];
	
	return self;
}

- (void) dealloc
{
	[label release], label = nil;
	[labelTitle release], labelTitle = nil;
	
	[resource release], resource = nil;
	// parent is a weak reference
	
	//[children setValue:nil forKey:@"parent"];
	[children release], children = nil;
	
	[super dealloc];
}

#pragma mark -

- (NSNumber*) label
{
	return label;
}

- (void) setLabel:(NSNumber*)aNumber
{
	if ( label != aNumber )
	{
		[label release];
		label = [aNumber retain];
	}
}

- (NSString*) labelTitle
{
	return labelTitle;
}

- (void) setLabelTitle:(NSString*)aString
{
	if ( labelTitle != aString )
	{
		[labelTitle release];
		labelTitle = [aString retain];
	}
}

- (JournlerResource*) resource
{
	return resource;
}

- (void) setResource:(JournlerResource*)aResource
{
	if ( resource != aResource )
	{
		[resource release];
		resource = [aResource retain];
	}
}

- (ResourceNode*) parent
{
	return parent;
}

- (void) setParent:(ResourceNode*)aResourceNode
{
	if ( parent != aResourceNode )
	{
		parent = aResourceNode;
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
		[children release];
		children = [anArray retain];
		
		[children setValue:self forKey:@"parent"];
	}
}

#pragma mark -

- (BOOL) isLeafNode
{
	return ![self isExpandable];
}

- (BOOL) isExpandable
{
	return ( [label boolValue] || [self countOfChildren] != 0 );
}

- (NSUInteger) countOfChildren
{
	return [children count];
}

- (ResourceNode*) childAtIndex:(NSUInteger)index
{
	if ( index < [children count] )
		return [children objectAtIndex:index];
	else
		return nil;
}

@end
