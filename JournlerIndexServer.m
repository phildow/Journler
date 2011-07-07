//
//  JournlerIndexServer.m
//  Journler
//
//  Created by Philip Dow on 2/13/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import "JournlerIndexServer.h"

#import "JournlerObject.h"
#import "JournlerEntry.h"
#import "JournlerResource.h"
#import "JournlerSearchManager.h"

#import "IndexNode.h"

@implementation JournlerIndexServer

static NSArray *DefaultDocumentsSort()
{
	static NSArray *documentSort = nil;
	if ( documentSort == nil )
	{
		NSSortDescriptor *titleSort = [[[NSSortDescriptor alloc] 
				initWithKey:@"title" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] autorelease];
		
		NSSortDescriptor *utiSort = [[[NSSortDescriptor alloc] 
				initWithKey:@"uti" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease];
		
		documentSort = [[NSArray alloc] initWithObjects:titleSort, utiSort, nil];
	}
	
	return documentSort;
}

#pragma mark -

- (id) initWithSearchManager:(JournlerSearchManager*)aSearchManager
{
	if ( self = [super init] )
	{
		searchManager = [aSearchManager retain];
		
		termToDocumentsDictionary = [[NSMutableDictionary alloc] init];
		documentToTermsDictionary = [[NSMutableDictionary alloc] init];
		
		rootTermsLoaded = NO;
		rootTermNodes = [[NSArray alloc] init];
	}
	
	return self;
}

- (void) dealloc
{
	[searchManager release];
	
	[termToDocumentsDictionary release];
	[documentToTermsDictionary release];
	
	[rootTermNodes release];
	
	//[embeddedLexiconMenuItem release];
	//[embeddedLexiconMenuItemTerm release];
	
	[super dealloc];
}

#pragma mark -

- (JournlerSearchManager*)searchManager
{
	return searchManager;
}

- (BOOL) loadRootTerms
{
	if ( searchManager == nil )
		return NO;
	
	// load this guy up
	NSString *aTerm;
	NSArray *allTerms = [searchManager allTerms:kIgnoreNumericTerms];
	NSEnumerator *enumerator = [allTerms objectEnumerator];
	
	NSMutableArray *termRootArray = [NSMutableArray arrayWithCapacity:[allTerms count]];
	
	while ( aTerm = [enumerator nextObject] )
	{
		unsigned count = [searchManager countOfDocumentsForTerm:aTerm options:kIgnoreNumericTerms];
		
		IndexNode *aNode = [[[IndexNode alloc] init] autorelease];
		
		[aNode setTitle:aTerm];
		[aNode setCount:count];
		[aNode setRepresentedObject:aTerm];
			
		[termRootArray addObject:aNode];
	}
	
	[self setRootTermNodes:termRootArray];
	rootTermsLoaded = YES;
	return YES;
}

- (BOOL) rootTermsLoaded
{
	return rootTermsLoaded;
}

- (NSArray*) rootTermNodes;
{
	return rootTermNodes;
}

- (void) setRootTermNodes:(NSArray*)anArray
{
	if ( rootTermNodes != anArray )
	{
		[rootTermNodes release];
		rootTermNodes = [anArray retain];
	}
}

#pragma mark -

- (NSArray*) termNodesForDocumentNodes:(NSArray*)anArray
{
	
	if ( anArray == nil || [anArray count] == 0 )
		return nil;
	
	JournlerObject *anObject = [anArray objectAtIndex:0];
	
	NSMutableArray *content = [NSMutableArray array];
	
	// modified to prevent entry duplication via copyWithZone
	// NSArray *objectTermDictionaries = [documentToTermsDictionary objectForKey:anObject];
	NSArray *objectTermDictionaries = [documentToTermsDictionary objectForKey:[anObject valueForKey:@"tagID"]];
		
	if ( objectTermDictionaries == nil )
	{
		NSString *aTerm;
		NSArray *terms = [searchManager termsForJournlerObject:anObject options:kIgnoreNumericTerms];
		NSEnumerator *enumerator = [terms objectEnumerator];

		while ( aTerm = [enumerator nextObject] )
		{
						
			unsigned count = [searchManager countOfDocumentsForTerm:aTerm options:kIgnoreNumericTerms];
			unsigned frequency = [searchManager frequenceyOfTerm:aTerm forDocument:anObject options:kIgnoreNumericTerms];
			
			IndexNode *aNode = [[[IndexNode alloc] init] autorelease];
		
			[aNode setTitle:aTerm];
			[aNode setRepresentedObject:aTerm];
			[aNode setCount:count];
			[aNode setFrequency:frequency];
			
			[content addObject:aNode];

		}
		
		// #warning the journler entry is copied here - don't use entries for keys, use their ids instead
		// [documentToTermsDictionary setObject:content forKey:anObject];
		[documentToTermsDictionary setObject:content forKey:[anObject valueForKey:@"tagID"]];
	}
	else
	{
		[content setArray:objectTermDictionaries];
	}
	
	return content;

}

- (NSArray*) documentNodesForTermNodes:(NSArray*)anArray
{	
	// bail if we don't have anything to work with
	if ( anArray == nil || [anArray count] == 0 )
		return nil;
	
	// get the nodes represented object
	
	NSMutableArray *content = [NSMutableArray array];
	NSMutableArray *multiArray = [NSMutableArray array];
	
	id anObject;
	IndexNode *selectedNode;
	NSEnumerator *nodesEnumerator = [anArray objectEnumerator];
	
	while ( selectedNode = [nodesEnumerator nextObject] )
	{
		anObject = [selectedNode representedObject];
		if ( ![anObject isKindOfClass:[NSString class]] )
			continue;
		
		NSString *theTerm = anObject;
		
		// get an array of journler objects that have been prepared for this selection (no duplicates allowed)
		NSArray *alreadyRepresented = [multiArray valueForKey:@"representedObject"];
		
		// try the cache
		NSArray *journlerObjects = [termToDocumentsDictionary objectForKey:theTerm];
		if ( journlerObjects == nil ) 
		{
			NSMutableArray *thisTermsObjects = [NSMutableArray array];
			
			// grab the objects and set the cache
			journlerObjects = [[searchManager journlerObjectsForTerm:theTerm options:kIgnoreNumericTerms]
					sortedArrayUsingDescriptors:DefaultDocumentsSort()];
			
			JournlerObject *aJournlerObject;
			NSEnumerator *enumerator = [journlerObjects objectEnumerator];
			
			while ( aJournlerObject = [enumerator nextObject] )
			{
				IndexNode *aNode = [[[IndexNode alloc] init] autorelease];
				
				[aNode setTitle:[aJournlerObject title]];
				[aNode setRepresentedObject:aJournlerObject];
				//[aNode setCount:0];
				
				// produce children for the journler object
				NSArray *children = nil;
				NSMutableArray *childNodes = [NSMutableArray array];
				
				if ( [aJournlerObject isKindOfClass:[JournlerResource class]] )
					children = [(JournlerResource*)aJournlerObject entries];
				else if ( [aJournlerObject isKindOfClass:[JournlerEntry class]] )
					children = [(JournlerEntry*)aJournlerObject resources];
				
				JournlerObject *aChildObject;
				NSEnumerator *childEnumerator = [children objectEnumerator];
				
				while ( aChildObject = [childEnumerator nextObject] )
				{
					IndexNode *aChildNode = [[[IndexNode alloc] init] autorelease];
				
					[aChildNode setTitle:[aChildObject title]];
					[aChildNode setRepresentedObject:aChildObject];
					[aChildNode setParent:aNode];
					
					[childNodes addObject:aChildNode];
				}
				
				// actually set the child nodes - could do the same for user defined term synonyms
				[aNode setChildren:childNodes];
				
				[content addObject:aNode];
				[thisTermsObjects addObject:aNode];
				
				if ( ![alreadyRepresented containsObject:aJournlerObject] )
					[multiArray addObject:aNode];
			}
			
			// reset the count for this term
			[selectedNode setCount:[thisTermsObjects count]];
			
			// set the cache for this term -> documents
			[termToDocumentsDictionary setObject:thisTermsObjects forKey:theTerm];
		}
		else
		{
			//[content setArray:journlerObjects];
			
			// only add objects that have not been added already
			IndexNode *aCachedNode;
			NSEnumerator *journlerObjectsEnumerator = [journlerObjects objectEnumerator];
			
			while ( aCachedNode = [journlerObjectsEnumerator nextObject] )
			{
				if ( ![alreadyRepresented containsObject:[aCachedNode representedObject]] )
					[multiArray addObject:aCachedNode];
			}
		}
		
	}
	
	// reset the count on this node
	[selectedNode setCount:[content count]];
	
	// set the returned content to our parsed-for-duplicates multi array
	[content setArray:multiArray];
	
	return content;

}

#pragma mark -

- (void) releaseTermAndDocumentDictionaries
{
	[rootTermNodes release];
	rootTermNodes = nil;
	rootTermsLoaded = NO;
	
	[termToDocumentsDictionary removeAllObjects];
	[documentToTermsDictionary removeAllObjects];
}

#pragma mark -
#pragma mark Built-in Support for Menu Delegation

- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(int)index shouldCancel:(BOOL)shouldCancel
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	id aTarget = [embeddedLexiconMenuItem target];
	SEL anAction = [embeddedLexiconMenuItem action];
	NSArray *journlerObjects = [embeddedLexiconMenuItem representedObject];
	
	if ( index >= [journlerObjects count] )
		return NO;
	
	JournlerObject *anObject = [journlerObjects objectAtIndex:index];
	
	[item setTitle:[anObject title]];
	[item setRepresentedObject:anObject];
	[item setImage:[self image:[anObject icon] withWidth:18 height:18]];
	
	[item setTarget:aTarget];
	[item setAction:anAction];
	
	[pool release];
	
	if ( index == [journlerObjects count] )
		return NO;
	else
		return YES;
}

- (int)numberOfItemsInMenu:(NSMenu *)menu
{
	/*
	if ( embeddedLexiconMenuItem != nil )
		[embeddedLexiconMenuItem release];
	if ( embeddedLexiconMenuItemTerm != nil )
		[embeddedLexiconMenuItemTerm release];
	*/
	
	// flush the index to update changes
	[[self searchManager] writeIndexToDisk];
	
	// build the menu
	embeddedLexiconMenuItem = [[menu supermenu] itemWithTag:kLexiconMenuItemTag];
	if ( embeddedLexiconMenuItem == nil ) return 0;
	
	NSString *term = [embeddedLexiconMenuItem representedObject];
	if ( term == nil || ![term isKindOfClass:[NSString class]] )
		return 0;
	
	embeddedLexiconMenuItemTerm = term;
	
	//NSMutableString *menuTitle = [[[embeddedLexiconMenuItem title] mutableCopyWithZone:[self zone]] autorelease];
	
	NSArray *journlerObjects = [[[self searchManager] 
	 journlerObjectsForTerm:[term lowercaseString] options:kIgnoreNumericTerms]
	 sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] 
	 initWithKey:@"title" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] autorelease]]];
	
	//[menuTitle appendFormat:@" (%i)", [journlerObjects count]];
	//[embeddedLexiconMenuItem setTitle:menuTitle];
	[embeddedLexiconMenuItem setRepresentedObject:journlerObjects];
	
	return [journlerObjects count];
}

- (NSString*) lexiconMenuRepresentedTerm
{
	return embeddedLexiconMenuItemTerm;
}

@end

@implementation JournlerIndexServer (InterfaceSupport)

- (NSImage*) image:(NSImage*)anImage withWidth:(float)width height:(float)height {
	
	// returns a WxH version of the image
	NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(width,height)];
	
	[image lockFocus];
	[[NSGraphicsContext currentContext] saveGraphicsState];
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	[anImage drawInRect:NSMakeRect(0,0,width,height) fromRect:NSMakeRect(0,0,[anImage size].width,[anImage size].height) 
			operation:NSCompositeSourceOver fraction:1.0];
	[[NSGraphicsContext currentContext] restoreGraphicsState];
	[image unlockFocus];

	return [image autorelease];
	
}

@end
