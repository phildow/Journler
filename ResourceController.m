//
//  ResourceController.m
//  Journler
//
//  Created by Philip Dow on 10/26/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import "ResourceController.h"
#import "TabController.h"
#import "Definitions.h"

#import "JournlerObject.h"
#import "JournlerEntry.h"
#import "JournlerResource.h"
#import "JournlerCollection.h"
#import "JournlerJournal.h"
#import "JournlerSearchManager.h"

#import "NSURL+JournlerAdditions.h"
#import "NSAlert+JournlerAdditions.h"

#import "ResourceNode.h"
#import "ResourceTableView.h"
#import "ImageTextAndRankCell.h"

#define kResourceImageLargeSize 36
#define kResourceImageSmallSize 22

#define kResourceRowHeight	42
#define kResourcesSmallRowHeight 24
#define kLabelRowHeight		20
#define kEntryListIndent	8

static NSSortDescriptor *ResourceByKindSortPrototype()
{
	static NSSortDescriptor *descriptor = nil;
	if ( descriptor == nil )
	{
		descriptor = [[NSSortDescriptor alloc] initWithKey:@"resource.uti" ascending:YES selector:@selector(caseInsensitiveCompare:)];
	}
	return descriptor;
}

static NSSortDescriptor *ResourceByTitleSortPrototype()
{
	static NSSortDescriptor *descriptor = nil;
	if ( descriptor == nil )
	{
		descriptor = [[NSSortDescriptor alloc] initWithKey:@"resource.title" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
	}
	return descriptor;
}

static NSSortDescriptor *ResourceByRankSortPrototype()
{
	static NSSortDescriptor *descriptor = nil;
	if ( descriptor == nil )
	{
		descriptor = [[NSSortDescriptor alloc] initWithKey:@"resource.relevance" ascending:NO selector:@selector(compare:)];
	}
	return descriptor;
}

#pragma mark -

@implementation ResourceController

- (void) awakeFromNib
{
	// set the sort descriptors for the resource table
	//[self setSortDescriptors:[NSArray arrayWithObject:ResourceByTitleSortPrototype()]];
	
	onTheFlyTag = -1;
	dragProducedEntry = NO;
	
	smallDiscloure = [[NSImage imageNamed:@"SmallDisclosure"] retain];
	smallAltDisclosure = [[NSImage imageNamed:@"SmallAltDisclosure"] retain];
	
	[resourceTable setIndentationPerLevel:4.0];
	[resourceTable setIndentationMarkerFollowsCell:NO];
	
	foldersNode = [[ResourceNode alloc] init];
	[foldersNode setValue:[NSNumber numberWithBool:YES] forKey:@"label"];
	[foldersNode setValue:NSLocalizedString(@"resource node folder",@"") forKey:@"labelTitle"];
	
	internalNode = [[ResourceNode alloc] init];
	[internalNode setValue:[NSNumber numberWithBool:YES] forKey:@"label"];
	[internalNode setValue:NSLocalizedString(@"resource node internal",@"") forKey:@"labelTitle"];
	
	contactsNode = [[ResourceNode alloc] init];
	[contactsNode setValue:[NSNumber numberWithBool:YES] forKey:@"label"];
	[contactsNode setValue:NSLocalizedString(@"resource node contacts",@"") forKey:@"labelTitle"];
	
	correspondenceNode = [[ResourceNode alloc] init];
	[correspondenceNode setValue:[NSNumber numberWithBool:YES] forKey:@"label"];
	[correspondenceNode setValue:NSLocalizedString(@"resource node correspondence",@"") forKey:@"labelTitle"];
	
	urlsNode = [[ResourceNode alloc] init];
	[urlsNode setValue:[NSNumber numberWithBool:YES] forKey:@"label"];
	[urlsNode setValue:NSLocalizedString(@"resource node urls",@"") forKey:@"labelTitle"];
	
	pdfsNode = [[ResourceNode alloc] init];
	[pdfsNode setValue:[NSNumber numberWithBool:YES] forKey:@"label"];
	[pdfsNode setValue:NSLocalizedString(@"resource node pdfs",@"") forKey:@"labelTitle"];
	
	imagesNode = [[ResourceNode alloc] init];
	[imagesNode setValue:[NSNumber numberWithBool:YES] forKey:@"label"];
	[imagesNode setValue:NSLocalizedString(@"resource node images",@"") forKey:@"labelTitle"];
	
	archivesNode = [[ResourceNode alloc] init];
	[archivesNode setValue:[NSNumber numberWithBool:YES] forKey:@"label"];
	[archivesNode setValue:NSLocalizedString(@"resource node archives",@"") forKey:@"labelTitle"];
	
	avNode = [[ResourceNode alloc] init];
	[avNode setValue:[NSNumber numberWithBool:YES] forKey:@"label"];
	[avNode setValue:NSLocalizedString(@"resource node av",@"") forKey:@"labelTitle"];

	documentsNode = [[ResourceNode alloc] init];
	[documentsNode setValue:[NSNumber numberWithBool:YES] forKey:@"label"];
	[documentsNode setValue:NSLocalizedString(@"resource node docs",@"") forKey:@"labelTitle"];
	
	stateDictionary = [[NSMutableDictionary alloc] init];
	
	// set the double action on the table
	[resourceTable setTarget:self];
	[resourceTable setDoubleAction:@selector(tableDoubleClick:)];
	
	// watch for changes to the resource-entry relationships
	[[NSNotificationCenter defaultCenter] addObserver:self 
			selector:@selector(_entryDidChangeResourceContent:) 
			name:EntryDidAddResourceNotification 
			object:nil];
	
	[[NSNotificationCenter defaultCenter] 
			addObserver:self 
			selector:@selector(_entryDidChangeResourceContent:) 
			name:EntryDidRemoveResourceNotification 
			object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
			selector:@selector(journlerObjectValueDidChange:) 
			name:JournlerObjectDidChangeValueForKeyNotification 
			object:nil];
	
	// bind a value to user defaults
	[self bind:@"usesSmallResourceIcons" 
			toObject:[NSUserDefaultsController sharedUserDefaultsController]
			withKeyPath:@"values.ResourceListUseSmallIcons" 
			options:[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithBool:NO], NSNullPlaceholderBindingOption, nil]];
	
}

- (void) dealloc
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
			name:EntryDidAddResourceNotification 
			object:nil];
			
	[[NSNotificationCenter defaultCenter] removeObserver:self 
			name:EntryDidRemoveResourceNotification 
			object:nil];
			
	[[NSNotificationCenter defaultCenter] removeObserver:self 
			name:JournlerObjectDidChangeValueForKeyNotification 
			object:nil];
	
	[foldersNode release];
	[internalNode release];
	[contactsNode release];
	[correspondenceNode release];
	[urlsNode release];
	[pdfsNode release];
	[imagesNode release];
	[archivesNode release];
	[avNode release];
	[documentsNode release];
	
	[stateDictionary release];
	
	[selectedResources release];
	[arrangedResources release];
	
	[intersectSet release];
	[folders release];
	[resources release];
	[resourceNodes release];
	
	[defaultDisclosure release];
	[defaultAltDisclosure release];
	
	[smallDiscloure release];
	[smallAltDisclosure release];
	
	[super dealloc];
}

- (id) delegate
{
	return delegate;
}

- (void) setDelegate:(id)anObject
{
	delegate = anObject;
}

- (BOOL) showingSearchResults
{
	return showingSearchResults;
}

- (void) setShowingSearchResults:(BOOL)searching
{
	showingSearchResults = searching;
}

- (NSArray*) selectedResources
{
	return selectedResources;
}

- (void) setSelectedResources:(NSArray*)anArray
{
	if ( selectedResources != anArray )
	{
		[selectedResources release];
		selectedResources = [anArray retain];
	}
}

- (NSArray*) arrangedResources
{
	return arrangedResources;
}

- (void) setArrangedResources:(NSArray*)anArray
{
	if ( arrangedResources != anArray )
	{
		[arrangedResources release];
		arrangedResources = [anArray retain];
	}
}

- (NSSet*) intersectSet 
{ 
	return intersectSet; 
}

- (void) setIntersectSet:(NSSet*)newSet 
{	
	if ( intersectSet != newSet ) 
	{
		[intersectSet release];
		intersectSet = [newSet copyWithZone:[self zone]];
		
		// and update our display
		[self rearrangeObjects];
	}
}

- (NSArray*) folders
{
	return folders;
}

- (void) setFolders:(NSArray*)anArray
{
	if ( folders != anArray )
	{
		[folders release];
		folders = [anArray retain];
		
		// transform the resources into nodes for the outline view
		[self prepareResourceNodes];
		[resourceTable reloadData];
	}
}

- (NSArray*) resources
{
	return resources;
}

- (void) setResources:(NSArray*)anArray
{
	if ( resources != anArray )
	{
		// let go of the preview icon for the currently selected resources
		[resources makeObjectsPerformSelector:@selector(releasePreview)];
		
		[resources release];
		resources = [anArray retain];
		
		// hold onto the preview icon for the newly selected resources
		[resources makeObjectsPerformSelector:@selector(retainPreview)];
		
		// transform the resources into nodes for the outline view
		[self prepareResourceNodes];
		[resourceTable reloadData];
	}
}

- (NSArray*) resourceNodes
{
	return resourceNodes;
}

- (void) setResourceNodes:(NSArray*)anArray
{
	if ( resourceNodes != anArray )
	{
		[resourceNodes release];
		resourceNodes = [anArray retain];
	}
}

#pragma mark -

- (BOOL) usesSmallResourceIcons
{
	return usesSmallResourceIcons;
}

- (void) setUsesSmallResourceIcons:(BOOL)smallIcons
{
	usesSmallResourceIcons = smallIcons;
	[self rearrangeObjects];
}


#pragma mark -

- (void)rearrangeObjects
{
	[self prepareResourceNodes];
	[resourceTable reloadData];
}

/*
- (NSArray *)arrangeObjects:(NSArray *)objects 
{
	// uses the intesect set to filter out objects
	NSArray *returnArray;
	
    if ( intersectSet == nil ) 
	{
		returnArray = [super arrangeObjects:objects];
	}
	else 
	{
		NSMutableSet *returnSet = [[[NSMutableSet alloc] initWithArray:objects] autorelease];
		
		[returnSet intersectSet:intersectSet];
		returnArray = [super arrangeObjects:[returnSet allObjects]];
	}
	
	return returnArray;
}
*/

- (void) prepareResourceNodes
{	
	NSMutableArray *theInternalNodes = [NSMutableArray array];
	
	NSMutableArray *contacts = [NSMutableArray array];
	NSMutableArray *urls = [NSMutableArray array];
	NSMutableArray *pdfs = [NSMutableArray array];
	NSMutableArray *archives = [NSMutableArray array];
	NSMutableArray *images = [NSMutableArray array];
	NSMutableArray *audioVideo = [NSMutableArray array];
	NSMutableArray *documents = [NSMutableArray array];
	NSMutableArray *correspondence = [NSMutableArray array];
	
	NSMutableArray *theNodes = [NSMutableArray arrayWithCapacity:8];
	
	// add the folders -- not shown when searching
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"ResourceTableShowFolders"] && intersectSet == nil )
	{
		NSMutableArray *theFolders = [NSMutableArray array];
		
        for ( JournlerCollection *aFolder in [self folders] )
		{
			// create a temporary resurce - should deallocate when the node is no longer in use
			JournlerResource *aFolderResource = [[[JournlerResource alloc] initJournalObjectResource:[aFolder URIRepresentation]] autorelease];
			[aFolderResource setValue:[NSNumber numberWithInt:onTheFlyTag--] forKey:@"tagID"];
			[aFolderResource setValue:[aFolder valueForKey:@"title"] forKey:@"title"];
			[aFolderResource setValue:[aFolder valueForKey:@"icon"] forKey:@"icon"];
			[aFolderResource setValue:[self valueForKeyPath:@"delegate.journal"] forKey:@"journal"];
			
			// create the node which encompasses the resource
			ResourceNode *aNode = [[[ResourceNode alloc] init] autorelease];
			[aNode setValue:aFolderResource forKey:@"resource"];
			
			[theFolders addObject:aNode];
		}
		
		// complete the node and make sure it's available for the outline
		if ( [theFolders count] != 0 )
		{
			[theFolders setValue:foldersNode forKey:@"parent"];
			[foldersNode setValue:[theFolders sortedArrayUsingDescriptors:
					[NSArray arrayWithObjects:ResourceByTitleSortPrototype(), nil]] forKey:@"children"];
			[theNodes addObject:foldersNode];
		}
		else
		{
			[foldersNode setChildren:nil];
		}
	}
	
	// add the internal links (journler resources ) -- not shown when searching
	/*
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"ResourceTableShowJournlerLinks"] && intersectSet == nil )
	{
		JournlerResource *anInternalResource;
		NSEnumerator *internalEnumerator = [[self journlerResources] objectEnumerator];
		NSMutableArray *theInternalNodes = [NSMutableArray array];
		
		while ( anInternalResource = [internalEnumerator nextObject] )
		{
			ResourceNode *aNode = [[[ResourceNode alloc] init] autorelease];
			[aNode setValue:anInternalResource forKey:@"resource"];
			
			[theInternalNodes addObject:aNode];
		}
		
		if ( [theInternalNodes count] != 0 )
		{
			[theInternalNodes setValue:internalNode forKey:@"parent"];
			[internalNode setValue:[theInternalNodes sortedArrayUsingDescriptors:
					[NSArray arrayWithObjects:ResourceByTitleSortPrototype(), nil]] forKey:@"children"];
			[theNodes addObject:internalNode];
		}
		else
		{
			[internalNode setChildren:nil];
		}
	}
	*/
	
    for ( JournlerResource *aResource in [self resources] )
	{
		// if the intersect set is available but doesn't contain this object, skip it
		if ( intersectSet != nil && ![intersectSet member:aResource] )
			continue;
		
		ResourceNode *aNode = [[[ResourceNode alloc] init] autorelease];
		[aNode setValue:aResource forKey:@"resource"];
		
		// add representations for each entry this resources is associated with, when associated with more than one
		if ( [[aResource entries] count] > 1 )
		{
			JournlerEntry *owningEntry = [aResource entry];
			NSMutableArray *resourcesEntryChildren = [NSMutableArray arrayWithCapacity:[[aResource entries] count]];
			
			// create a temporary resurce for the parent, always first - should deallocate when the node is no longer in use
			JournlerResource *owningEntryResource = [[[JournlerResource alloc] initJournalObjectResource:[owningEntry URIRepresentation]] autorelease];
			[owningEntryResource setValue:[NSNumber numberWithInt:onTheFlyTag--] forKey:@"tagID"];
			[owningEntryResource setValue:[owningEntry valueForKey:@"title"] forKey:@"title"];
			[owningEntryResource setValue:[owningEntry valueForKey:@"icon"] forKey:@"icon"];
			[owningEntryResource setValue:[self valueForKeyPath:@"delegate.journal"] forKey:@"journal"];
			
			// create the node which encompasses the resource
			ResourceNode *owningEntryNode = [[[ResourceNode alloc] init] autorelease];
			[owningEntryNode setValue:owningEntryResource forKey:@"resource"];
			
			[resourcesEntryChildren addObject:owningEntryNode];
			
            for ( JournlerEntry *anEntry in [aResource entries] )
			{
				#warning huh, neither of these continue conditionals seems to be working
				
				// don't add the parent a second time
				if ( anEntry == owningEntry )
					continue;
				
				// don't add the entry if it's marked for the trash
				if ( [[anEntry valueForKey:@"markedForTrash"] boolValue] == YES )
					continue;
				
				// create a temporary resurce - should deallocate when the node is no longer in use
				JournlerResource *anEntryResource = [[[JournlerResource alloc] initJournalObjectResource:[anEntry URIRepresentation]] autorelease];
				[anEntryResource setValue:[NSNumber numberWithInt:onTheFlyTag--] forKey:@"tagID"];
				[anEntryResource setValue:[anEntry valueForKey:@"title"] forKey:@"title"];
				[anEntryResource setValue:[anEntry valueForKey:@"icon"] forKey:@"icon"];
				[anEntryResource setValue:[self valueForKeyPath:@"delegate.journal"] forKey:@"journal"];
				
				// create the node which encompasses the resource
				ResourceNode *anEntryNode = [[[ResourceNode alloc] init] autorelease];
				[anEntryNode setValue:anEntryResource forKey:@"resource"];
				
				[resourcesEntryChildren addObject:anEntryNode];
			}
			
			// establish the parent <-> child relationship for this resource and its associated entries
			[resourcesEntryChildren setValue:aNode forKey:@"parent"];
			[aNode setChildren:resourcesEntryChildren];
		}
		
		// determine which category node this particular resource belongs to
		if ( [aResource representsABRecord] )
			[contacts addObject:aNode];
		else if ( [aResource representsURL] )
			[urls addObject:aNode];
		else if ( [aResource representsJournlerObject] )
			[theInternalNodes addObject:aNode];
		else if ([aResource representsFile] /* || [aResource representsRecording] */ )
		{
			if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"ResourceTableCollapseDocuments"] )
			{
				// if all files are collapsed into documents, store them here
				[documents addObject:aNode];
			}
			else
			{
				// otherwise, diversify
				if ( UTTypeConformsTo((CFStringRef)[aResource uti],kUTTypePDF) )
					[pdfs addObject:aNode];
				else if ( UTTypeConformsTo((CFStringRef)[aResource uti],kUTTypeWebArchive) )
					[archives addObject:aNode];
				else if ( UTTypeConformsTo((CFStringRef)[aResource uti],kUTTypeImage) )
					[images addObject:aNode];
				else if ( UTTypeConformsTo((CFStringRef)[aResource uti],kUTTypeAudiovisualContent) )
					[audioVideo addObject:aNode];
				else if ( UTTypeConformsTo((CFStringRef)[aResource uti],kUTTypeMessage)
						|| UTTypeConformsTo((CFStringRef)[aResource uti],(CFStringRef)ResourceMailUTI) 
						|| UTTypeConformsTo((CFStringRef)[aResource uti],(CFStringRef)ResourceMailStandardEmailUTI)
						|| UTTypeConformsTo((CFStringRef)[aResource uti],(CFStringRef)ResourceChatUTI) )
					[correspondence addObject:aNode];
				else
					[documents addObject:aNode];
			}
		}
	}
	
	NSArray *universalSortOrder;
	//if ( intersectSet == nil )
	if ( [self showingSearchResults] )
		universalSortOrder = [NSArray arrayWithObjects:ResourceByRankSortPrototype(), ResourceByTitleSortPrototype(), nil];
	else
		universalSortOrder = [NSArray arrayWithObjects:ResourceByTitleSortPrototype(), nil];
	
	
	if ( [theInternalNodes count] != 0 && [[NSUserDefaults standardUserDefaults] boolForKey:@"ResourceTableShowJournlerLinks"] && intersectSet == nil )
	{
		[theInternalNodes setValue:internalNode forKey:@"parent"];
		[internalNode setValue:[theInternalNodes sortedArrayUsingDescriptors:universalSortOrder] forKey:@"children"];
		[theNodes addObject:internalNode];
	}
	else
	{
		[internalNode setChildren:nil];
	}

	if ( [contacts count] > 0 )
	{
		[contacts setValue:contactsNode forKey:@"parent"];
		[contactsNode setValue:[contacts sortedArrayUsingDescriptors:universalSortOrder] forKey:@"children"];
		[theNodes addObject:contactsNode];
	}
	else
	{
		[contactsNode setChildren:nil];
	}
	
	if ( [correspondence count] > 0 )
	{
		[correspondence setValue:correspondenceNode forKey:@"parent"];
		[correspondenceNode setValue:[correspondence sortedArrayUsingDescriptors:universalSortOrder] forKey:@"children"];
		[theNodes addObject:correspondenceNode];
	}
	else
	{
		[correspondenceNode setChildren:nil];
	}
	
	if ( [urls count] > 0 )
	{
		[urls setValue:urlsNode forKey:@"parent"];
		[urlsNode setValue:[urls sortedArrayUsingDescriptors:universalSortOrder] forKey:@"children"];
		[theNodes addObject:urlsNode];
	}
	else
	{
		[urlsNode setChildren:nil];
	}
	
	if ( [pdfs count] > 0 )
	{
		[pdfs setValue:pdfsNode forKey:@"parent"];
		[pdfsNode setValue:[pdfs sortedArrayUsingDescriptors:universalSortOrder] forKey:@"children"];
		[theNodes addObject:pdfsNode];
	}
	else
	{
		[pdfsNode setChildren:nil];
	}
	
	if ( [archives count] > 0 )
	{
		[archives setValue:archivesNode forKey:@"parent"];
		[archivesNode setValue:[archives sortedArrayUsingDescriptors:universalSortOrder] forKey:@"children"];
		[theNodes addObject:archivesNode];
	}
	else
	{
		[archivesNode setChildren:nil];
	}
	
	if ( [images count] > 0 )
	{
		[images setValue:imagesNode forKey:@"parent"];
		[imagesNode setValue:[images sortedArrayUsingDescriptors:universalSortOrder] forKey:@"children"];
		[theNodes addObject:imagesNode];
	}
	else
	{
		[imagesNode setChildren:nil];
	}
	
	if ( [audioVideo count] > 0 )
	{
		[audioVideo setValue:avNode forKey:@"parent"];
		[avNode setValue:[audioVideo sortedArrayUsingDescriptors:universalSortOrder] forKey:@"children"];
		[theNodes addObject:avNode];
	}
	else
	{
		[avNode setChildren:nil];
	}
	
	if ( [documents count] > 0 )
	{
	
		if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"ResourceTableArrangedCollapsedDocumentsByKind"] )
		{
			//if ( intersectSet == nil )
			if ( [self showingSearchResults] )
			{
				[documentsNode setValue:[documents sortedArrayUsingDescriptors:[NSArray arrayWithObjects:
						ResourceByRankSortPrototype(), ResourceByKindSortPrototype(), ResourceByTitleSortPrototype(), nil]] forKey:@"children"];
			}
			else
			{
				[documentsNode setValue:[documents sortedArrayUsingDescriptors:[NSArray arrayWithObjects:
						ResourceByKindSortPrototype(), ResourceByTitleSortPrototype(), nil]] forKey:@"children"];
			}
		}
		else
		{
			[documentsNode setValue:[documents sortedArrayUsingDescriptors:universalSortOrder] forKey:@"children"];
		}
		
		[documents setValue:documentsNode forKey:@"parent"];
		[theNodes addObject:documentsNode];
	}
	else
	{
		[documentsNode setChildren:nil];
	}

	[self setResourceNodes:theNodes];
}

#pragma mark -
#pragma mark Navigation Events

- (void) outlineView:(NSOutlineView*)anOutlineView leftNavigationEvent:(NSEvent*)anEvent
{
	if ( [[self delegate] respondsToSelector:@selector(outlineView:leftNavigationEvent:)] )
		[[self delegate] outlineView:anOutlineView leftNavigationEvent:anEvent];
}

- (void) outlineView:(NSOutlineView*)anOutlineView rightNavigationEvent:(NSEvent*)anEvent
{
	if ( [[self delegate] respondsToSelector:@selector(outlineView:rightNavigationEvent:)] )
		[[self delegate] outlineView:anOutlineView rightNavigationEvent:anEvent];
}


#pragma mark -
#pragma mark NSOutlineView Data Source

// This method is called repeatedly when the table view is displaying it self. 
- (id)outlineView:(NSOutlineView *)ov child:(int)index ofItem:(id)item
{
    // is the parent non-nil?
    if (item != nil)
        return [item childAtIndex:index];
	
	 // Else return the root
    else 
		return [resourceNodes objectAtIndex:index];
}

// Called repeatedly to find out if there should be an "expand triangle" next to the label
- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item
{
    // Returns YES if the node has children
    return [item isExpandable];
}

// Called repeatedly when the table view is displaying itself
- (int)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item
{
 // The root object;
    if (item == nil) 
	   return [resourceNodes count];
	
	// any other object
    return
		[item countOfChildren];
}

// This method gets called repeatedly when the outline view is trying
// to display it self.

- (id)outlineView:(NSOutlineView *)olv objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item 
{
    id objectValue = nil;
    // The return value from this method is used to configure the state of the items cell via setObjectValue:
	
	ResourceNode *actualItem; 
	// necessary hack to get around NSTreeController proxy object, 10.5 compatible
	if ( [item respondsToSelector:@selector(representedObject)] )
		actualItem = [item representedObject];
	else if ( [item respondsToSelector:@selector(observedObject)] )
		actualItem = [item observedObject];
	else
		actualItem = item;

	if ( [[actualItem valueForKey:@"label"] boolValue] )
		objectValue = [actualItem valueForKey:@"labelTitle"];
	else
		objectValue = [actualItem valueForKeyPath:@"resource.title"];
    
    return objectValue;
}

#pragma mark -
#pragma mark NSOutlineView Data Source

- (float)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item 
{
	
	// to support variable row heights in the outline view, available in 10.4 and later
		
	ResourceNode *actualItem; 
	// necessary hack to get around NSTreeController proxy object, 10.5 compatible
	if ( [item respondsToSelector:@selector(representedObject)] )
		actualItem = [item representedObject];
	else if ( [item respondsToSelector:@selector(observedObject)] )
		actualItem = [item observedObject];
	else
		actualItem = item;
	
	//return kLabelRowHeight;
	if ( [[actualItem valueForKey:@"label"] boolValue] )
		return kLabelRowHeight;
		
	else if ( [actualItem parent] != nil && [[[actualItem parent] label] boolValue] == NO )
		return kResourcesSmallRowHeight;
	
	else return ( [self usesSmallResourceIcons] ? kResourcesSmallRowHeight : kResourceRowHeight );
}

- (void)outlineView:(NSOutlineView *)outlineView 
		willDisplayCell:(id)aCell 
		forTableColumn:(NSTableColumn *)tableColumn 
		item:(id)item {
	
	if ([[tableColumn identifier] isEqualToString: @"title"]) {
		
		//
		// Set the image here since the value returned from 
		// outlineView:objectValueForTableColumn:... didn't specify the image part...
		
		ResourceNode *actualItem; 
		// necessary hack to get around NSTreeController proxy object, 10.5 compatible
		if ( [item respondsToSelector:@selector(representedObject)] )
			actualItem = [item representedObject];
		else if ( [item respondsToSelector:@selector(observedObject)] )
			actualItem = [item observedObject];
		else
			actualItem = item;
		
		if ( [[actualItem valueForKey:@"label"] boolValue] )
		{
			[(ImageTextAndRankCell*)aCell setImage:nil];
			[(ImageTextAndRankCell*)aCell setStringValue:[actualItem valueForKey:@"labelTitle"]];
			[(ImageTextAndRankCell*)aCell setLabel:YES];
			[(ImageTextAndRankCell*)aCell setRank:0];
			[(ImageTextAndRankCell*)aCell setCount:[actualItem countOfChildren]];
			
			[(ImageTextAndRankCell*)aCell setEnabled:NO];
			[(ImageTextAndRankCell*)aCell setEditable:NO];
			
			[(ImageTextAndRankCell*)aCell setAdditionalIndent:0];
		}
		else
		{
		
			JournlerResource *aResource = [actualItem valueForKey:@"resource"];
			[(ImageTextAndRankCell*)aCell setImage:[aResource valueForKey:@"icon"]];
			[(ImageTextAndRankCell*)aCell setLabel:NO];
			[(ImageTextAndRankCell*)aCell setEnabled:YES];
			[(ImageTextAndRankCell*)aCell setEditable:YES];
			
			// icon size and additional indentation
			if ( [self usesSmallResourceIcons] )
				[(ImageTextAndRankCell*)aCell setImageSize:NSMakeSize(kResourceImageSmallSize,kResourceImageSmallSize)];
			
			else if ( [actualItem parent] != nil && [[[actualItem parent] label] boolValue] == NO )
				[(ImageTextAndRankCell*)aCell setImageSize:NSMakeSize(kResourceImageSmallSize,kResourceImageSmallSize)];
			
			else 
				[(ImageTextAndRankCell*)aCell setImageSize:NSMakeSize(kResourceImageLargeSize,kResourceImageLargeSize)];
			
			// image indent
			if ( [actualItem parent] != nil && [[[actualItem parent] label] boolValue] == NO )
				[(ImageTextAndRankCell*)aCell setAdditionalIndent:kEntryListIndent];
			else
				[(ImageTextAndRankCell*)aCell setAdditionalIndent:0];
			
			// selection (so color can determine colors, font, etc)
			//[(ImageTextAndRankCell*)aCell setSelected:( [outlineView rowForItem:item] == [outlineView selectedRow] )];
			//[(ImageAndTextCell*)aCell setSelected:( [[self selectedObjects] containsObject:item] )];
			[(ImageAndTextCell*)aCell setSelected:( [[outlineView selectedRowIndexes] containsIndex:[outlineView rowForItem:item]] )];
			
			//if ( intersectSet != nil )
			if ( [self showingSearchResults] )
				[(ImageTextAndRankCell*)aCell setRank:[aResource relevance]];
			else
				[(ImageTextAndRankCell*)aCell setRank:0];
		}
	}
}

- (void)outlineView:(NSOutlineView *)ov 
		setObjectValue:(id)object 
		forTableColumn:(NSTableColumn *)tableColumn 
		byItem:(id)item
{
    // The only editable column in the item name column
    // so I know immediately where to put it.
    // If there were more editable columns I would
    // need an if-statement like in the previous method
	
	ResourceNode *actualItem; 
	// necessary hack to get around NSTreeController proxy object, 10.5 compatible
	if ( [item respondsToSelector:@selector(representedObject)] )
		actualItem = [item representedObject];
	else if ( [item respondsToSelector:@selector(observedObject)] )
		actualItem = [item observedObject];
	else
		actualItem = item;

	if ( [[actualItem valueForKey:@"label"] boolValue] )
		NSBeep();
	else
		[actualItem setValue:object forKeyPath:@"resource.title"];
    
    // Brute force reload to update sums
    //[resourceTable reloadItem:_rootNode reloadChildren:YES];
	[resourceTable reloadItem:[item valueForKey:@"parent"] reloadChildren:YES];
}

- (void)outlineView:(NSOutlineView *)outlineView 
		willDisplayOutlineCell:(id)cell 
		forTableColumn:(NSTableColumn *)tableColumn 
		item:(id)item
{
	// alter the image displayed next to resources with multiple entries
	
	ResourceNode *actualItem; 
	// necessary hack to get around NSTreeController proxy object, 10.5 compatible
	if ( [item respondsToSelector:@selector(representedObject)] )
		actualItem = [item representedObject];
	else if ( [item respondsToSelector:@selector(observedObject)] )
		actualItem = [item observedObject];
	else
		actualItem = item;
		
	if ( [[actualItem label] boolValue] == NO )
	{
		[cell setImage:smallDiscloure];
		[cell setAlternateImage:smallAltDisclosure];
	}
	else
	{
		if ( defaultDisclosure == nil ) defaultDisclosure = [[cell image] retain];
		if ( defaultAltDisclosure == nil ) defaultAltDisclosure = [[cell alternateImage] retain];
		
		[cell setImage:defaultDisclosure];
		[cell setAlternateImage:defaultAltDisclosure];
	}
}

#pragma mark -
#pragma mark NSOutlineView Delegation

- (NSString *)outlineView:(NSOutlineView *)ov 
		toolTipForCell:(NSCell *)cell 
		rect:(NSRectPointer)rect 
		tableColumn:(NSTableColumn *)tc 
		item:(id)item 
		mouseLocation:(NSPoint)mouseLocation
{
	// provide a context dependendt tooltip
	
	ResourceNode *actualItem; 
	// necessary hack to get around NSTreeController proxy object, 10.5 compatible
	if ( [item respondsToSelector:@selector(representedObject)] )
		actualItem = [item representedObject];
	else if ( [item respondsToSelector:@selector(observedObject)] )
		actualItem = [item observedObject];
	else
		actualItem = item;

	if ( [[actualItem valueForKey:@"label"] boolValue] )
		return nil;
	else
	{
		NSMutableString *theTooltip = [NSMutableString string];
		JournlerResource *representedResource = [actualItem resource];
		
		if ( [representedResource representsJournlerObject] )
		{
			JournlerObject *encompassedObject = nil;
			encompassedObject = [representedResource journlerObject];
		
			if ( [encompassedObject isKindOfClass:[JournlerEntry class]] )
			{
				NSString *plainContent = [[encompassedObject valueForKey:@"attributedContent"] string];
			
				if ( plainContent == nil )
					return [encompassedObject valueForKey:@"title"];
				
				SKSummaryRef summaryRef = SKSummaryCreateWithString((CFStringRef)plainContent);
				
				if ( summaryRef == NULL )
					return [encompassedObject valueForKey:@"title"];
				
				NSString *summary = [(NSString*)SKSummaryCopySentenceSummaryString(summaryRef,1) autorelease];
				if ( summary == nil )
					return [encompassedObject valueForKey:@"title"];
				else
					[theTooltip setString:summary];
			}
			else if ( [encompassedObject isKindOfClass:[JournlerCollection class]] )
			{
				// append the title
				[theTooltip appendString:[actualItem valueForKeyPath:@"resource.title"]];
				
				// show the folder hierarchy
				JournlerCollection *parent = [(JournlerCollection*)encompassedObject valueForKey:@"parent"];
				JournlerCollection *rootCollection = [encompassedObject valueForKeyPath:@"journal.rootCollection"];
				
				if ( parent != nil && parent != rootCollection )
				{
					NSMutableString *hierarchyString = [NSMutableString string];
					[hierarchyString appendString:[encompassedObject valueForKey:@"title"]];
					
					while ( parent != nil && parent != rootCollection )
					{
						[hierarchyString insertString:@" > " atIndex:0];
						[hierarchyString insertString:[parent valueForKey:@"title"] atIndex:0];
						
						parent = [parent valueForKey:@"parent"];
					}
					
					// newline
					[theTooltip appendString:@"\n"];
					[theTooltip appendString:hierarchyString];
				}
			}
		}
		else
		{
			// append the title
			[theTooltip appendString:[actualItem valueForKeyPath:@"resource.title"]];
			
			// as well as any entries this resource is linked to
			int i = 1;
#warning iterate i here?
        
            for ( JournlerEntry *anEntry in [[actualItem resource] entries] )
				[theTooltip appendFormat:@"\n%i. %@", i, [anEntry title]];
		}
		
		return theTooltip;
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView 
		shouldEditTableColumn:(NSTableColumn *)tableColumn 
		item:(id)item
{
	ResourceNode *actualItem; 
	// necessary hack to get around NSTreeController proxy object, 10.5 compatible
	if ( [item respondsToSelector:@selector(representedObject)] )
		actualItem = [item representedObject];
	else if ( [item respondsToSelector:@selector(observedObject)] )
		actualItem = [item observedObject];
	else
		actualItem = item;

	if ( [[actualItem valueForKey:@"label"] boolValue] || [[actualItem resource] representsJournlerObject] )
		return NO;
	else
		return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	ResourceNode *actualItem; // necessary hack to get around NSTreeController proxy object
	if ( [item respondsToSelector:@selector(observedObject)] )
		actualItem = [item observedObject];
	else
		actualItem = item;

	if ( [[actualItem valueForKey:@"label"] boolValue] )
		return NO;
	else
		return YES;
}

- (BOOL)selectionShouldChangeInOutlineView:(NSOutlineView *)outlineView 
{
	if ( delegate != nil && [delegate respondsToSelector:@selector(resourceController:willChangeSelection:)] )
		// [delegate resourceController:self willChangeSelection:[self selectedObjects]];
		// [self selectedObjects] doesn't return anything?
		[delegate resourceController:self willChangeSelection:[self selectedResources]];

	return YES;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSIndexSet *selectedRows = [resourceTable selectedRowIndexes];
	NSMutableArray *selectedItems = [NSMutableArray arrayWithCapacity:[selectedRows count]];
	
	unsigned current_index = [selectedRows firstIndex];
    while (current_index != NSNotFound)
    {
		// grab the item at this index and act on it
		ResourceNode *aNode = [resourceTable originalItemAtRow:current_index];
		if ( aNode != nil && ![[aNode valueForKey:@"label"] boolValue] )
			[selectedItems addObject:[aNode valueForKey:@"resource"]];
		
		// grab the next index
        current_index = [selectedRows indexGreaterThanIndex: current_index];
	}
	
	// manually update the seleted items object for folks who are listening to it
	//[self setSelectedObjects:selectedItems];
	[self setSelectedResources:selectedItems];
}

#pragma mark -
#pragma mark NSOutlineView Drag & Drop

- (BOOL)outlineView:(NSOutlineView *)outlineView 
		writeItems:(NSArray *)items 
		toPasteboard:(NSPasteboard *)pboard
{
	int i;
	NSArray *objects = items;
	
	NSMutableArray *referenceURIs = [NSMutableArray arrayWithCapacity:[objects count]];
	NSMutableArray *referencePromises = [NSMutableArray arrayWithCapacity:[objects count]];
	NSMutableArray *referenceTitles = [NSMutableArray arrayWithCapacity:[objects count]];
	
	for ( i = 0; i < [objects count]; i++ ) 
	{
		JournlerResource *aReference = [[objects objectAtIndex:i] resource];
		
		[referenceURIs addObject:[[aReference URIRepresentation] absoluteString]];
		[referencePromises addObject:[aReference valueForKey:@"uti"]];
		[referenceTitles addObject:[aReference valueForKey:@"title"]];
	}
	
	// prepare the favorites data
	NSDictionary *favoritesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
			[[[objects objectAtIndex:0] resource] valueForKey:@"title"], PDFavoriteName, 
			[[[[objects objectAtIndex:0] resource] URIRepresentation] absoluteString], PDFavoriteID, nil];
	
	// prepare the web urls
	NSArray *web_urls_array = [NSArray arrayWithObjects:referenceURIs,referenceTitles,nil];
	
	// declare the pasteboard types
	NSArray *types = [NSArray arrayWithObjects:
			PDResourceIDPboardType, NSFilesPromisePboardType, 
			PDFavoritePboardType, WebURLsWithTitlesPboardType, 
			NSURLPboardType, NSStringPboardType, nil];
			
	[pboard declareTypes:types owner:self];
	
	// write the data to the pasteboard
	[pboard setPropertyList:referenceURIs forType:PDResourceIDPboardType];
	[pboard setPropertyList:referencePromises forType:NSFilesPromisePboardType];
	[pboard setPropertyList:favoritesDictionary forType:PDFavoritePboardType];
	[pboard setPropertyList:web_urls_array forType:WebURLsWithTitlesPboardType];
	
	// write the url for the first item to the pasteboard, as a url and as a string
	[[[[objects objectAtIndex:0] resource] URIRepresentation] writeToPasteboard:pboard];
	[pboard setString:[[[objects objectAtIndex:0] resource] URIRepresentationAsString] forType:NSStringPboardType];
	
	return YES;

}

- (NSArray *)outlineView:(NSOutlineView *)outlineView 
		namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination 
		forDraggedItems:(NSArray *)items
{
	if ( ![dropDestination isFileURL] ) 
		return nil;
	
	int i;
	NSString *rootPath = [dropDestination path];
	NSArray *objects = items;
	NSMutableArray *titles = [NSMutableArray arrayWithCapacity:[objects count]];
	
	for ( i = 0; i < [objects count]; i++ ) 
	{
		JournlerResource *aReference = [[objects objectAtIndex:i] resource];
		if ( [aReference createFileAtDestination:rootPath] == nil )
			NSLog(@"%s - problem exporing the resource out of journler: resource %@", __PRETTY_FUNCTION__, [aReference tagID]);
		
		[titles addObject:[aReference valueForKey:@"title"]];
	}
	
	return [NSArray array];

}

#pragma mark -

- (BOOL)outlineView:(NSOutlineView *)outlineView 
		acceptDrop:(id <NSDraggingInfo>)info 
		item:(id)item 
		childIndex:(int)index
{
	BOOL success = NO;
	static NSString *http_string = @"http://";
	static NSString *secure_http_string = @"https://";
	
	NSPasteboard *pboard = [info draggingPasteboard];
	
    NSArray *types = [NSArray arrayWithObjects:
			PDEntryIDPboardType, PDResourceIDPboardType, 
			kABPeopleUIDsPboardType, kMailMessagePboardType,
			NSFilenamesPboardType, NSTIFFPboardType, 
			NSPICTPboardType, NSRTFDPboardType, 
			NSRTFPboardType, WebURLsWithTitlesPboardType, 
			NSURLPboardType, NSStringPboardType, nil];
	
	//id source = [info draggingSource];
	unsigned operation = _dragOperation;
    NSString *desiredType = [pboard availableTypeFromArray:types];
	NSArray *availableTypes = [pboard types];
	
	if ( [[[self delegate] selectedEntries] count] == 0 )
	{
		if ( [[self delegate] respondsToSelector:@selector(resourceController:newDefaultEntry:)] )
		{
			dragProducedEntry = YES;
			[[self delegate] resourceController:self newDefaultEntry:nil];
		}
		else
		{
			NSBeep();
			return NO;
		}
	}
	
	else if ( [[[self delegate] selectedEntries] count] > 1 )
	{
		NSBeep();
		return NO;
	}
	
	JournlerEntry *targetEntry = [[[self delegate] selectedEntries] objectAtIndex:0];

	// add people to the text
	if ( [desiredType isEqualToString:kABPeopleUIDsPboardType] ) 
	{
		int i;
		success = YES;
		NSArray *uids = [pboard propertyListForType:kABPeopleUIDsPboardType];
		for ( i = 0; i < [uids count]; i++ ) 
		{
			ABPerson *person = (ABPerson*)[[ABAddressBook sharedAddressBook] recordForUniqueId:[uids objectAtIndex:i]];
			success = ( [self _addPerson:person toEntry:targetEntry] && success );
		}
	}
	
	// add a message to the text
	else if ( [desiredType isEqualToString:kMailMessagePboardType] )
	{
		success = YES;
		// this takes a long time, so return and perform the copy after a short delay
		NSDictionary *objectDictionary = [NSDictionary dictionaryWithObjectsAndKeys:info, @"dragginginfo", targetEntry, @"entry", nil];
		[self performSelector:@selector(_addMailMessage:) withObject:[objectDictionary retain] afterDelay:0.1];
	}
	
	// add files to the text
	else if ( [desiredType isEqualToString:NSFilenamesPboardType] ) 
	{
		int j;
		success = YES;
		NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		for ( j = 0; j < [files count]; j++ ) 
		{
			NSString *fileLoc = [files objectAtIndex:j];
			success = ( [self _addFile:fileLoc title:nil resourceCommand:operation toEntry:targetEntry] && success );
		}
	}
	
	// add a web url to the text
	else if ( [desiredType isEqualToString:WebURLsWithTitlesPboardType] ) 
	{
		// iMBNativePasteboardFlavor iMBNativePasteboardFlavor
		BOOL iIntegration = NO;
		
		if ( [availableTypes containsObjects:[NSArray arrayWithObjects:kiLifeIntegrationPboardType, NSFilenamesPboardType, nil]] ) 
			iIntegration = YES;

		// iterate through each of the items, forcing a link
		NSArray *pbArray = [pboard propertyListForType:WebURLsWithTitlesPboardType];
		NSArray *URLArray = [pbArray objectAtIndex:0];
		NSArray *titleArray = [pbArray objectAtIndex:1];
		
		if ( !URLArray || !titleArray || [URLArray count] != [titleArray count] ) 
		{
			NSLog(@"%s - malformed WebURLsWithTitlesPboardType data", __PRETTY_FUNCTION__);
			success = NO;
		}
		else 
		{
			success = YES;
			
			int i;
			for ( i = 0; i < [URLArray count]; i++ ) 
			{
				if ( iIntegration)
				{
					// coming from iIntegration, link the file
					success = ( [self _addFile:[[NSURL URLWithString:[URLArray objectAtIndex:i]] path]
							title:[titleArray objectAtIndex:i] resourceCommand:operation toEntry:targetEntry] && success );
				}
				else
				{
					// if we have web urls, the operation is copy, and http:// is in the string, download an archive
					if ( operation == NSDragOperationCopy 
						&& ( [[URLArray objectAtIndex:i] rangeOfString:http_string].location == 0 
						|| [[URLArray objectAtIndex:i] rangeOfString:secure_http_string].location == 0 ) )
						success = ( [self _addWebArchiveFromURL:[NSURL URLWithString:[URLArray objectAtIndex:i]] title:[titleArray objectAtIndex:i] toEntry:targetEntry] && success );
					
					// add a url to the text if we don't want to copy the site as an archive
					else
						success = ( [self _addURL:[NSURL URLWithString:[URLArray objectAtIndex:i]] title:[titleArray objectAtIndex:i] toEntry:targetEntry] && success );
				}
			}
		}
	}
	
	// add a url to the text
	else if ( [desiredType isEqualToString:NSURLPboardType] ) 
	{
		if ( operation == NSDragOperationCopy && [[NSURL URLFromPasteboard:pboard] isHTTP] )
			success = [self _addWebArchiveFromURL:[NSURL URLFromPasteboard:pboard] title:nil toEntry:targetEntry];
		else
			success = [self _addURL:[NSURL URLFromPasteboard:pboard] title:nil toEntry:targetEntry];
	}
	
	// add an image to the text, producing a hard copy of the image while I'm at it
	else if ( [desiredType isEqualToString:NSTIFFPboardType] || [desiredType isEqualToString:NSPICTPboardType] ) 
	{		
		success = [self _addImageData:[pboard dataForType:desiredType] dataType:desiredType title:nil toEntry:targetEntry];
	}
	
	// add a journler object to the text
	else if ( [desiredType isEqualToString:PDEntryIDPboardType] || [desiredType isEqualToString:PDResourceIDPboardType] )
	{
		int i;
		NSArray *URIs = [pboard propertyListForType:desiredType];
		success = YES;
		
		for ( i = 0; i < [URIs count]; i++ )
		{
			success = ( [self _addJournlerObjectWithURI:[NSURL URLWithString:[URIs objectAtIndex:i]] toEntry:targetEntry] && success );
		}
	}
	
	// add rich text to the entry
	else if ( [desiredType isEqualToString:NSRTFPboardType] || [desiredType isEqualToString:NSRTFDPboardType] ) 
	{
		NSAttributedString *attr_str = nil;
		NSData *data = [pboard dataForType:desiredType];
		
		if ( [desiredType isEqualToString:NSRTFPboardType] )
			attr_str = [[NSAttributedString alloc] initWithRTF:data documentAttributes:nil];
		else if ( [desiredType isEqualToString:NSRTFDPboardType] )
			attr_str = [[NSAttributedString alloc] initWithRTFD:data documentAttributes:nil];
		
		if ( attr_str != nil ) 
		{
			success = [self _addAttributedString:attr_str toEntry:targetEntry];
		}
	}
	
	// add string data to the entry
	else if ( [desiredType isEqualToString:NSStringPboardType] )
	{
		NSString *string = [pboard stringForType:NSStringPboardType];
		if ( string != nil )
		{
			success = [self _addString:string toEntry:targetEntry];
		}
	}
	
	if ( dragProducedEntry == YES && [[targetEntry resources] count] > 0 )
	{
		// set the title on the entry if this is the first chance for it
		NSString *resourceTitle = [[[targetEntry resources] objectAtIndex:0] valueForKey:@"title"];
		if ( resourceTitle != nil ) [targetEntry setValue:resourceTitle forKey:@"title"];
	}
	
	// put up an error if necessary
	if ( success == NO )
	{
		NSBeep();
		[[NSAlert resourceToEntryError] runModal];
	}
	
	// some clean up
	dragProducedEntry = NO;
	return success;
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView 
		validateDrop:(id <NSDraggingInfo>)info 
		proposedItem:(id)item 
		proposedChildIndex:(int)index
{
	unsigned operation;
	_dragOperation = NSDragOperationNone;
	//id source = [info draggingSource];
	
    NSArray *types = [NSArray arrayWithObjects:
			PDEntryIDPboardType, PDResourceIDPboardType, 
			PDFolderIDPboardType, kABPeopleUIDsPboardType, 
			kMailMessagePboardType, NSTIFFPboardType, 
			NSPICTPboardType, NSRTFDPboardType, 
			NSRTFPboardType, WebURLsWithTitlesPboardType, 
			NSFilenamesPboardType, NSURLPboardType, 
			NSStringPboardType, nil];
	
	NSPasteboard *pboard = [info draggingPasteboard];
    NSString *desiredType = [pboard availableTypeFromArray:types];
	NSArray *availableTypes = [pboard types];
	
	if ( [[delegate selectedEntries] count] > 1 )
	{
		operation = NSDragOperationNone;
	}
	else 
	{
		operation = [info draggingSourceOperationMask];
		
		// address record are always copied to text
		if ( [kABPeopleUIDsPboardType isEqualToString:desiredType] )
			operation = NSDragOperationLink; 
		
		// images are always copied to text
		else if ( [NSTIFFPboardType isEqualToString:desiredType] || [NSPICTPboardType isEqualToString:desiredType] )
			operation = NSDragOperationCopy; 
			
		// journler objects are always linked
		else if ( [PDEntryIDPboardType isEqualToString:desiredType] || [PDResourceIDPboardType isEqualToString:desiredType] || [PDFolderIDPboardType isEqualToString:desiredType] )
			operation = NSDragOperationLink; 
		
		// string data is copied this time around
		else if ( [NSStringPboardType isEqualToString:desiredType] )
			operation = NSDragOperationCopy;
		
		// mail messages directly from mail may be linked or copied
		else if ( [kMailMessagePboardType isEqualToString:desiredType] )
		{
			//if ( GetCurrentKeyModifiers() & optionKey )
				operation = NSDragOperationCopy;
			//else
			//	operation = NSDragOperationLink;
		}
		
		// urls are linked but may be copied as a web archive
		else if ( [NSURLPboardType isEqualToString:desiredType] ) 
		{
			if ( GetCurrentKeyModifiers() & optionKey )
				operation = NSDragOperationCopy;
			else
				operation = NSDragOperationLink; 
		}
		
		// web urls require special attention depending on the source
		else if ( [WebURLsWithTitlesPboardType isEqualToString:desiredType] ) 
		{
			if ( [availableTypes containsObjects:[NSArray arrayWithObjects:kiLifeIntegrationPboardType, NSFilenamesPboardType, nil]] )
			{
				// iLife integration links by default, copy if the user really wants it
				operation = NSDragOperationLink;
				if ( GetCurrentKeyModifiers() & optionKey )
					operation = NSDragOperationCopy;
			}
			else if ( GetCurrentKeyModifiers() & optionKey )
				operation = NSDragOperationCopy;
			else
				operation = NSDragOperationLink;
		}
		
		// files also require special attention
		else if ( [NSFilenamesPboardType isEqualToString:desiredType] ) 
		{
			operation = NSDragOperationGeneric;
			
			if ( [availableTypes containsObject:kMVMessageContentsPboardType] )
				operation = NSDragOperationCopy; // force a copy if there is message contents data on the pasteboard
			else if ( GetCurrentKeyModifiers() & optionKey )
				operation = NSDragOperationCopy;
			else if ( GetCurrentKeyModifiers() & controlKey )
				operation = NSDragOperationLink;
			else
			{
				// requires a little more care - examine what is being dragged, determine from there, keep operation generic though
				
				BOOL dir, package;
				NSString *appName = nil, *fileType = nil;
				NSString *path = [[pboard propertyListForType:NSFilenamesPboardType] objectAtIndex:0];
				
				// determine directory, type and package information
				if ( ! [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&dir] )
					goto bail;
				
				if ( ! [[NSWorkspace sharedWorkspace] getInfoForFile:path application:&appName type:&fileType] )
					goto bail;
					
				package = [[NSWorkspace sharedWorkspace] isFilePackageAtPath:path];
				
				_dragOperation = NSDragOperationGeneric;
				operation = [self _commandForCurrentCommand:NSDragOperationNone fileType:fileType directory:dir package:package];

			}
		}
	}
	
bail:
	
	// target the first spot always
	[resourceTable setDropItem:nil dropChildIndex:-1];
	
	if ( _dragOperation == NSDragOperationNone )
		_dragOperation = operation;
		
	return operation;
}

/*
- (BOOL)ignoreModifierKeysWhileDragging 
{
	return NO;
}
*/

#pragma mark -
#pragma mark Outline View State: Collapse and Expand

- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
	id collapsedObject = [[notification userInfo] objectForKey:@"NSObject"];
	
	#ifdef __DEBUG__
	NSLog(@"%s - %@", __PRETTY_FUNCTION__, [collapsedObject labelTitle]);
	#endif
	
	if ( [[collapsedObject valueForKey:@"label"] boolValue] == YES )
		[stateDictionary setObject:[NSNumber numberWithInt:kResourceNodeCollapsed] forKey:[collapsedObject labelTitle]];
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
	id expandedObject = [[notification userInfo] objectForKey:@"NSObject"];
	
	#ifdef __DEBUG__
	NSLog(@"%s - %@", __PRETTY_FUNCTION__, [expandedObject labelTitle]);
	#endif
	
	if ( [[expandedObject valueForKey:@"label"] boolValue] == YES )
		[stateDictionary setObject:[NSNumber numberWithInt:kResourceNodeExpanded] forKey:[expandedObject valueForKey:@"labelTitle"]];
}

- (NSDictionary*) stateDictionary
{
	return [[stateDictionary copyWithZone:[self zone]] autorelease];
}

- (BOOL) restoreStateFromDictionary:(NSDictionary*)aDictionary
{	
	if ( stateDictionary != aDictionary )
	{
		[stateDictionary release];
		stateDictionary = [aDictionary mutableCopyWithZone:[self zone]];
	}
    
    for ( NSString *aKey in [aDictionary keyEnumerator] )
	{
		// contacts
		if ( [aKey isEqualToString:[contactsNode labelTitle]] && [resourceTable rowForItem:contactsNode] != -1 )
		{
			if ( [[aDictionary objectForKey:aKey] intValue] == kResourceNodeCollapsed && [resourceTable isItemExpanded:contactsNode] )
				[resourceTable collapseItem:contactsNode];
			else if ( [[aDictionary objectForKey:aKey] intValue] == kResourceNodeExpanded && ![resourceTable isItemExpanded:contactsNode] )
				[resourceTable expandItem:contactsNode expandChildren:NO];
		}
		
		// urls
		else if ( [aKey isEqualToString:[urlsNode labelTitle]] && [resourceTable rowForItem:urlsNode] != -1 )
		{
			if ( [[aDictionary objectForKey:aKey] intValue] == kResourceNodeCollapsed && [resourceTable isItemExpanded:urlsNode] )
				[resourceTable collapseItem:urlsNode];
			else if ( [[aDictionary objectForKey:aKey] intValue] == kResourceNodeExpanded && ![resourceTable isItemExpanded:urlsNode] )
				[resourceTable expandItem:urlsNode expandChildren:NO];
		}

		
		// correspondence
		else if ( [aKey isEqualToString:[correspondenceNode labelTitle]] && [resourceTable rowForItem:correspondenceNode] != -1 )
		{
			if ( [[aDictionary objectForKey:aKey] intValue] == kResourceNodeCollapsed && [resourceTable isItemExpanded:correspondenceNode] )
				[resourceTable collapseItem:correspondenceNode];
			else if ( [[aDictionary objectForKey:aKey] intValue] == kResourceNodeExpanded && ![resourceTable isItemExpanded:correspondenceNode] )
				[resourceTable expandItem:correspondenceNode expandChildren:NO];
		}
		
		// documents
		else if ( [aKey isEqualToString:[documentsNode labelTitle]] && [resourceTable rowForItem:documentsNode] != -1 )
		{
			if ( [[aDictionary objectForKey:aKey] intValue] == kResourceNodeCollapsed && [resourceTable isItemExpanded:documentsNode] )
				[resourceTable collapseItem:documentsNode];
			else if ( [[aDictionary objectForKey:aKey] intValue] == kResourceNodeExpanded && ![resourceTable isItemExpanded:documentsNode] )
				[resourceTable expandItem:documentsNode expandChildren:NO];
		}
		
		// pdfs
		else if ( [aKey isEqualToString:[pdfsNode labelTitle]] && [resourceTable rowForItem:pdfsNode] != -1 )
		{
			if ( [[aDictionary objectForKey:aKey] intValue] == kResourceNodeCollapsed && [resourceTable isItemExpanded:pdfsNode] )
				[resourceTable collapseItem:pdfsNode];
			else if ( [[aDictionary objectForKey:aKey] intValue] == kResourceNodeExpanded && ![resourceTable isItemExpanded:pdfsNode] )
				[resourceTable expandItem:pdfsNode expandChildren:NO];
		}
		
		// web archives
		else if ( [aKey isEqualToString:[archivesNode labelTitle]] && [resourceTable rowForItem:archivesNode] != -1 )
		{
			if ( [[aDictionary objectForKey:aKey] intValue] == kResourceNodeCollapsed && [resourceTable isItemExpanded:archivesNode] )
				[resourceTable collapseItem:archivesNode];
			else if ( [[aDictionary objectForKey:aKey] intValue] == kResourceNodeExpanded && ![resourceTable isItemExpanded:archivesNode] )
				[resourceTable expandItem:archivesNode expandChildren:NO];
		}
		
		// images
		else if ( [aKey isEqualToString:[imagesNode labelTitle]] && [resourceTable rowForItem:imagesNode] != -1 )
		{
			if ( [[aDictionary objectForKey:aKey] intValue] == kResourceNodeCollapsed && [resourceTable isItemExpanded:imagesNode] )
				[resourceTable collapseItem:imagesNode];
			else if ( [[aDictionary objectForKey:aKey] intValue] == kResourceNodeExpanded && ![resourceTable isItemExpanded:imagesNode] )
				[resourceTable expandItem:imagesNode expandChildren:NO];
		}
		
		// audio/visual
		else if ( [aKey isEqualToString:[avNode labelTitle]] && [resourceTable rowForItem:avNode] != -1 )
		{
			if ( [[aDictionary objectForKey:aKey] intValue] == kResourceNodeCollapsed && [resourceTable isItemExpanded:avNode] )
				[resourceTable collapseItem:avNode];
			else if ( [[aDictionary objectForKey:aKey] intValue] == kResourceNodeExpanded && ![resourceTable isItemExpanded:avNode] )
				[resourceTable expandItem:avNode expandChildren:NO];
		}
		
		// internal folders
		else if ( [aKey isEqualToString:[foldersNode labelTitle]] && [resourceTable rowForItem:foldersNode] != -1 )
		{
			if ( [[aDictionary objectForKey:aKey] intValue] == kResourceNodeCollapsed && [resourceTable isItemExpanded:foldersNode] )
				[resourceTable collapseItem:foldersNode];
			else if ( [[aDictionary objectForKey:aKey] intValue] == kResourceNodeExpanded && ![resourceTable isItemExpanded:foldersNode] )
				[resourceTable expandItem:foldersNode expandChildren:NO];
		}
		
		// internal links (entries)
		else if ( [aKey isEqualToString:[internalNode labelTitle]] && [resourceTable rowForItem:internalNode] != -1 )
		{
			if ( [[aDictionary objectForKey:aKey] intValue] == kResourceNodeCollapsed && [resourceTable isItemExpanded:internalNode] )
				[resourceTable collapseItem:internalNode];
			else if ( [[aDictionary objectForKey:aKey] intValue] == kResourceNodeExpanded && ![resourceTable isItemExpanded:internalNode] )
				[resourceTable expandItem:internalNode expandChildren:NO];
		}
	}
	
	return YES;
}

#pragma mark -
#pragma mark Entry Resource Relationship Notifications

- (void) _entryDidChangeResourceContent:(NSNotification*)aNotification
{
	// locate the node 
	// deselect if that row is selected
	// rebuild the nodes children
	// reload the data
	
	JournlerEntry *theEntry = [aNotification object];
	JournlerResource *theResource = [[aNotification userInfo] objectForKey:@"resource"];
	ResourceNode *representingNode = [self _nodeForResource:theResource];
	
	if ( representingNode != nil )
	{
		if ( [[aNotification name] isEqualToString:EntryDidRemoveResourceNotification] )
		{
			// deselect the node if it is selected and we're removing this particular item
			if ( [[resourceTable selectedRowIndexes] containsIndex:[resourceTable rowForItem:representingNode]] )
				[resourceTable deselectRow:[resourceTable rowForItem:representingNode]];
		
			// and remove the node representing resource representing entry from this item
			int childIndex = [[representingNode valueForKeyPath:@"children.resource.journlerObject"] indexOfObject:theEntry];
			if ( childIndex != NSNotFound )
			{
				NSMutableArray *childNodes = [[[representingNode children] mutableCopyWithZone:[self zone]] autorelease];
				[childNodes removeObjectAtIndex:childIndex];
				[representingNode setChildren:childNodes];
			}
		}
		
		else if ( [[aNotification name] isEqualToString:EntryDidAddResourceNotification] )
		{
			//#warning not working
			int childIndex = [[representingNode valueForKeyPath:@"children.resource.journlerObject"] indexOfObject:theEntry];
			if ( childIndex == NSNotFound )
			{
				// create a new dummy node representing resource representing entry for this item and add it to the children
				JournlerResource *anEntryResource = [[[JournlerResource alloc] initJournalObjectResource:[theEntry URIRepresentation]] autorelease];
				[anEntryResource setValue:[NSNumber numberWithInt:onTheFlyTag--] forKey:@"tagID"];
				[anEntryResource setValue:[theEntry valueForKey:@"title"] forKey:@"title"];
				[anEntryResource setValue:[theEntry valueForKey:@"icon"] forKey:@"icon"];
				[anEntryResource setValue:[self valueForKeyPath:@"delegate.journal"] forKey:@"journal"];
				
				// create the node which encompasses the resource
				ResourceNode *anEntryNode = [[[ResourceNode alloc] init] autorelease];
				[anEntryNode setValue:anEntryResource forKey:@"resource"];
				[anEntryNode setValue:representingNode forKey:@"parent"];
				
				NSMutableArray *childNodes = [[[representingNode children] mutableCopyWithZone:[self zone]] autorelease];
				[childNodes addObject:anEntryNode];
				[representingNode setChildren:childNodes];
			}
		}
		
		[resourceTable reloadItem:representingNode reloadChildren:[resourceTable isItemExpanded:representingNode]];
	}
}

- (ResourceNode*) _nodeForResource:(JournlerResource*)aResource
{
	// returns the node associated with the specified resources
	
	ResourceNode *foundNode = nil;
    
    for ( ResourceNode *aNode in [self resourceNodes] )
	{
        for ( ResourceNode *innerNode in [aNode children] )
		{
			if ( [innerNode resource] == aResource )
			{
				foundNode = innerNode;
				break;
			}
		}
		
		if ( foundNode != nil )
			break;
	}

	return foundNode;
}

- (void) journlerObjectValueDidChange:(NSNotification*)aNotification
{
	JournlerObject *theObject = [aNotification object];
	if ( [theObject isKindOfClass:[JournlerResource class]] 
		&& [[[aNotification userInfo] objectForKey:JournlerObjectAttributeKey] isEqualToString:JournlerObjectAttributeLabelKey] )
	{
		int theRow = [resourceTable rowForOriginalItem:[self _nodeForResource:(JournlerResource*)theObject]];
		if ( theRow != -1 )
			[resourceTable setNeedsDisplayInRect:[resourceTable rectOfRow:theRow]];
	}
}

#pragma mark -

- (IBAction) tableDoubleClick:(id)sender
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	NSArray *selection = [self selectedResources];
	if ( [selection count] != 1 )
	{
		NSBeep(); return;
	}
	
	JournlerObject *theObject = nil;
	JournlerResource *theResource = [selection objectAtIndex:0];
	
	if ( ![theResource representsJournlerObject] || ![[self delegate] respondsToSelector:@selector(selectEntries:)] || ( theObject = [theResource journlerObject] ) == nil )
	{
		NSBeep();
	}
	else
	{
		// but what kind of Journler object? The selection could represent a containing folder or an entry link
		if ( [theObject isKindOfClass:[JournlerEntry class]] )
			[[self delegate] selectEntries:[NSArray arrayWithObject:theObject]];
		else if ( [theObject isKindOfClass:[JournlerCollection class]] )
			[[self delegate] selectFolders:[NSArray arrayWithObject:theObject]];
		else
			NSBeep();
	}
}

#pragma mark -

- (IBAction) setDisplayOption:(id)sender
{
	int tag = [sender tag];
	if ( tag >= 101 && tag <= 104 ) 
	{
		NSString *defaultsKey = nil;
		if ( tag == 101 ) defaultsKey = @"ResourceTableShowFolders";
		else if ( tag == 102 ) defaultsKey = @"ResourceTableShowJournlerLinks";
		else if ( tag == 103) defaultsKey = @"ResourceTableCollapseDocuments";
		else if ( tag == 104) defaultsKey = @"ResourceTableArrangedCollapsedDocumentsByKind";
		
		BOOL currentValue = [[NSUserDefaults standardUserDefaults] boolForKey:defaultsKey];
		[[NSUserDefaults standardUserDefaults] setBool:!currentValue forKey:defaultsKey];
		
		[self prepareResourceNodes];
		[resourceTable reloadData];
	}
}

- (IBAction) setProperty:(id)sender
{
	NSArray *theResources = [self selectedResources];
	if ( theResources == nil || [theResources count] == 0 )
	{
		NSBeep(); return;
	}
	
	if ( [sender tag] == 2 )
	{
		// searches
		JournlerSearchManager *searchManager = [[theResources objectAtIndex:0] valueForKeyPath:@"journal.searchManager"];
		BOOL willSearch = ![[[theResources objectAtIndex:0] valueForKey:@"searches"] boolValue];
		
		// remove or add the items to the search index as needed
		
        for ( JournlerResource *aResource in theResources )
		{
			if ( willSearch )
				[searchManager indexResource:aResource owner:[aResource valueForKey:@"entry"]];
			else
				[searchManager removeResource:aResource owner:[aResource valueForKey:@"entry"]];
		}
		
		// and finally set the search value on every resource
		[theResources setValue:[NSNumber numberWithBool:willSearch] forKey:@"searches"];
	}
}

- (IBAction) deleteSelectedResources:(id)sender
{
	BOOL canDelete = YES;
	
    for ( JournlerResource *aResource in [self selectedResources] )
	{
		if ( ([aResource representsJournlerObject] && [[aResource URIRepresentation] isJournlerFolder]) 
			|| [[aResource tagID] intValue] < 0 )
		{
			canDelete = NO;
			break;
		}
	}
	
	if ( canDelete == NO )
	{
		NSBeep(); return;
	}
	else if ( [delegate respondsToSelector:@selector(deleteSelectedResources:)] )
	{
		[delegate performSelector:@selector(deleteSelectedResources:) withObject:sender];
	}
	else
	{
		NSBeep();
	}
}

#pragma mark -

- (IBAction) renameResource:(id)sender
{
	/*
	if ( [delegate respondsToSelector:@selector(renameResource:)] )
		[delegate performSelector:@selector(renameResource:) withObject:sender];
	else
		NSBeep();
	*/
	
	NSArray *theResourceSelection = [self selectedResources];
	if ( theResourceSelection == nil || [theResourceSelection count] == 0 )
	{
		NSBeep();
		return;
	}
	
	[resourceTable editColumn:0 row:[resourceTable selectedRow] withEvent:nil select:YES];
}

- (IBAction) showEntryForSelectedResource:(id)sender
{
	if ( [delegate respondsToSelector:@selector(showEntryForSelectedResource:)] )
		[delegate performSelector:@selector(showEntryForSelectedResource:) withObject:sender];
	else
		NSBeep();
}

- (IBAction) setSelectionAsDefaultForEntry:(id)sender
{
	if ( [delegate respondsToSelector:@selector(setSelectionAsDefaultForEntry:)] )
		[delegate performSelector:@selector(setSelectionAsDefaultForEntry:) withObject:sender];
	else
		NSBeep();
	
	/*
	if ( [[self selectedResources] count] != 1 || [[[self delegate] selectedEntries] count] != 1 )
	{
		NSBeep(); return;
	}
	
	JournlerResource *theResource = [[self selectedResources] objectAtIndex:0];
	
	if ( [theResource valueForKeyPath:@"entry.selectedResource"] == theResource )
		[[theResource valueForKey:@"entry"] setValue:nil forKey:@"selectedResource"];
	else
		[[theResource valueForKey:@"entry"] setValue:theResource forKey:@"selectedResource"];
	*/
}

- (IBAction) rescanResourceIcon:(id)sender
{
	if ( [delegate respondsToSelector:@selector(rescanResourceIcon:)] )
		[delegate performSelector:@selector(rescanResourceIcon:) withObject:sender];
	else
		NSBeep();
}

- (IBAction) rescanResourceUTI:(id)sender
{
	if ( [delegate respondsToSelector:@selector(rescanResourceUTI:)] )
		[delegate performSelector:@selector(rescanResourceUTI:) withObject:sender];
	else
		NSBeep();
}

- (IBAction) editResourceLabel:(id)sender
{
	if ( [delegate respondsToSelector:@selector(editResourceLabel:)] )
		[delegate performSelector:@selector(editResourceLabel:) withObject:sender];
	else
		NSBeep();
}

- (IBAction) editResourcePropety:(id)sender
{
	return;
}

- (IBAction) emailResourceSelection:(id)sender
{
	if ( [delegate respondsToSelector:@selector(emailResourceSelection:)] )
		[delegate performSelector:@selector(emailResourceSelection:) withObject:sender];
	else
		NSBeep();
}

#pragma mark -

- (IBAction) revealResource:(id)sender
{
	if ( [delegate respondsToSelector:@selector(revealResource:)] )
		[delegate performSelector:@selector(revealResource:) withObject:sender];
	else
		NSBeep();
	
}

-(IBAction) launchResource:(id)sender
{
	if ( [delegate respondsToSelector:@selector(launchResource:)] )
		[delegate performSelector:@selector(launchResource:) withObject:sender];
	else
		NSBeep();
}

- (IBAction) openResourceInNewTab:(id)sender
{
	if ( [delegate respondsToSelector:@selector(openResourceInNewTab:)] )
		[delegate performSelector:@selector(openResourceInNewTab:) withObject:sender];
	else
		NSBeep();
}

- (IBAction) openResourceInNewWindow:(id)sender
{
	if ( [delegate respondsToSelector:@selector(openResourceInNewWindow:)] )
		[delegate performSelector:@selector(openResourceInNewWindow:) withObject:sender];
	else
		NSBeep();
}

- (IBAction) openResourceInNewFloatingWindow:(id)sender
{
	if ( [delegate respondsToSelector:@selector(openResourceInNewFloatingWindow:)] )
		[delegate performSelector:@selector(openResourceInNewFloatingWindow:) withObject:sender];
	else
		NSBeep();
}

#pragma mark -

- (void) openAResourceWithFinder:(JournlerResource*)aResource
{
	if ( [delegate respondsToSelector:@selector(openAResourceWithFinder:)] )
		[delegate performSelector:@selector(openAResourceWithFinder:) withObject:aResource];
	else
		NSBeep();
}

- (void) openAResourceInNewTab:(JournlerResource*)aResource
{
	if ( [delegate respondsToSelector:@selector(openAResourceInNewTab:)] )
		[delegate performSelector:@selector(openAResourceInNewTab:) withObject:aResource];
	else
		NSBeep();
}

- (void) openAResourceInNewWindow:(JournlerResource*)aResource
{
	if ( [delegate respondsToSelector:@selector(openAResourceInNewWindow:)] )
		[delegate performSelector:@selector(openAResourceInNewWindow:) withObject:aResource];
	else
		NSBeep();
}

#pragma mark -

- (void) sortBy:(int)sortTag
{
	/*
	switch ( sortTag )
	{
	case 0:
		[[resourceTable titleColumn] setSortDescriptorPrototype:ResourceByKindSortPrototype()];
		[self setSortDescriptors:[NSArray arrayWithObjects:ResourceByKindSortPrototype(), ResourceByTitleSortPrototype(), nil]];
		break;
	
	case 1:
		[[resourceTable titleColumn] setSortDescriptorPrototype:ResourceByTitleSortPrototype()];
		[self setSortDescriptors:[NSArray arrayWithObjects:ResourceByTitleSortPrototype(), ResourceByKindSortPrototype(), nil]];
		break;
	
	case 2:
		[[resourceTable titleColumn] setSortDescriptorPrototype:ResourceByRankSortPrototype()];
		[self setSortDescriptors:[NSArray arrayWithObjects:ResourceByRankSortPrototype(), ResourceByTitleSortPrototype(), nil]];
		break;
	
	default:
		[[resourceTable titleColumn] setSortDescriptorPrototype:ResourceByTitleSortPrototype()];
		[self setSortDescriptors:[NSArray arrayWithObjects:ResourceByTitleSortPrototype(), ResourceByKindSortPrototype(), nil]];
		break;
	}
	*/
}

- (IBAction) sortByCommand:(id)sender
{
	[self sortBy:[sender tag]];
}

#pragma mark -

- (IBAction) exposeAllResources:(id)sender
{
    for ( ResourceNode *aNode in [self resourceNodes] )
		[resourceTable expandItem:[resourceTable itemAtRow:[resourceTable rowForOriginalItem:aNode]] expandChildren:NO];
}

- (BOOL) selectResource:(JournlerResource*)aResource byExtendingSelection:(BOOL)extend
{
	if ( aResource != nil && [aResource isKindOfClass:[JournlerResource class]] ) 
	{
		ResourceNode *parentToExpand = nil;
		ResourceNode *childToSelect = nil;
		
		NSArray *theResourceNodes = [self resourceNodes];
		
        for ( ResourceNode *aNode in theResourceNodes )
		{
			NSArray *nodeChildren = [aNode children];
			
            for ( ResourceNode *childNode in nodeChildren )
			{
				if ( [[childNode resource] isEqual:aResource] )
				{
					childToSelect = childNode;
					parentToExpand = aNode;
					break;
				}
			}
			
			if ( childToSelect != nil )
				break;
		}
		
		if ( parentToExpand != nil && childToSelect != nil )
		{
			// expand the parent
			[resourceTable expandItem:parentToExpand expandChildren:NO];
			
			// select the child
			unsigned childIndex = [resourceTable rowForItem:childToSelect];
			[resourceTable selectRowIndexes:[NSIndexSet indexSetWithIndex:childIndex] byExtendingSelection:extend];
		}
		else 
		{
			[resourceTable selectItems:nil byExtendingSelection:NO];
		}
		
		/*
		// expand the columns so that this guy is visible
		JournlerCollection *nodeWantsVisibility = aCollection;
		NSMutableArray *nodesToExpand = [[[NSMutableArray alloc] init] autorelease];
		
		while ( nodeWantsVisibility = [nodeWantsVisibility parent] ) 
		{
			if ( nodeWantsVisibility == [self rootCollection] )
				break;
			
			[nodesToExpand addObject:nodeWantsVisibility];
			
			if ( [sourceList rowForOriginalItem:nodeWantsVisibility] != -1 )
				break;
		}
		
		int i;
		for ( i = [nodesToExpand count] - 1; i >= 0; i-- )
		{
			unsigned aRow = [sourceList rowForOriginalItem:[nodesToExpand objectAtIndex:i]];
			id treeNode = [sourceList itemAtRow:aRow];
			[sourceList expandItem:treeNode expandChildren:NO];
			
			//[sourceList expandItem:[nodesToExpand objectAtIndex:i] expandChildren:NO];
		}
		
		[sourceList selectRowIndexes:[NSIndexSet indexSetWithIndex:
				[sourceList rowForOriginalItem:aCollection]] byExtendingSelection:extend];
		*/
	}
	else 
	{
		[resourceTable selectItems:nil byExtendingSelection:NO];
	}
	
	return YES;
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem*)anItem
{
	BOOL enabled = YES;
	SEL action = [anItem action];
	int tag = [anItem tag];
	NSArray *selectedObjects = [self selectedResources];
	
	if ( action == @selector(setDisplayOption:) )
	{
		enabled = YES;
		
		// determine the key
		NSString *defaultsKey = nil;
		if ( tag == 101 ) defaultsKey = @"ResourceTableShowFolders";
		else if ( tag == 102 ) defaultsKey = @"ResourceTableShowJournlerLinks";
		else if ( tag == 103) defaultsKey = @"ResourceTableCollapseDocuments";
		else if ( tag == 104) defaultsKey = @"ResourceTableArrangedCollapsedDocumentsByKind";
		
		if ( tag == 104 ) // by kind is enabled only if we've collapsed all into documents
			enabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"ResourceTableCollapseDocuments"];
		
		// set the state
		[anItem setState:( [[NSUserDefaults standardUserDefaults] boolForKey:defaultsKey] )];
		
	}
	else if ( action == @selector(editResourcePropety:) )
	{
		enabled = YES;
	}
	
	else if ( selectedObjects == nil || [selectedObjects count] == 0 )
	{
		enabled = NO;
		[anItem setState:NSOffState];
	}
		
	else
	{
		// auto-disable the selection if there is no entry available anywhere - a folder is selected
		if ( [[selectedObjects valueForKey:@"entry"] containsObject:[NSNull null]] )
		{
			enabled = NO;
			[anItem setState:NSOffState];
		}
		
		else if ( action == @selector(setProperty:) && tag == 2 )
		{
			//searches
			NSArray *doesSearch = [selectedObjects valueForKey:@"searches"];
			[anItem setState:[[doesSearch objectAtIndex:0] boolValue]];
			
            for ( JournlerResource *aResource in selectedObjects )
			{
				if ( [aResource representsJournlerObject] )
				{
					enabled = NO;
					break;
				}
			}
		}
		
		else if ( action == @selector(renameResource:) )
		{
            for ( JournlerResource *aResource in selectedObjects )
			{
				if ( [aResource representsJournlerObject] )
				{
					enabled = NO;
					break;
				}
			}
		}
		
		else if ( action == @selector(revealResource:) || action == @selector(launchResource:) )
		{
            for ( JournlerResource *aResource in selectedObjects )
			{
				if ( [aResource representsJournlerObject] )
				{
					enabled = NO;
					break;
				}
			}
		}
		
		else if ( action == @selector(openResourceInNewTab:) || action == @selector(openResourceInNewWindow:) )
		{
		
		}
		
		/*
		else if ( action == @selector(showEntryForSelectedResource:) )
		{
		
		}
		*/
		
		else if ( action == @selector(deleteSelectedResources:) )
		{
            for ( JournlerResource *aResource in selectedObjects )
			{
				if ( ([aResource representsJournlerObject] && [[aResource URIRepresentation] isJournlerFolder]) 
					|| [[aResource tagID] intValue] < 0 )
				{
					enabled = NO;
					break;
				}
			}
		}
		
		else if ( action == @selector(setSelectionAsDefaultForEntry:) )
		{
			if ( [[self selectedResources] count] == 1 && [[[self delegate] selectedEntries] count] == 1 )
			{
				JournlerResource *theResource = [[self selectedResources] objectAtIndex:0];

				if ( [theResource representsJournlerObject] )
				{
					enabled = NO;
					[anItem setState:NSOffState];
				}
				else 
				{
					enabled = YES;
					if ( [theResource valueForKeyPath:@"entry.selectedResource"] == theResource )
						[anItem setState:NSOnState];
					else
						[anItem setState:NSOffState];
				}
			}
			else
			{
				enabled = NO;
				[anItem setState:NSOffState];
			}
			
		}
		
		else if ( action == @selector(editResourceLabel:) )
		{
			unsigned entryCount = [[self selectedResources] count];
			enabled = ( entryCount > 0 );
			
			if ( tag == 0 || tag == 10 )
				[anItem setState:NSOffState];
			else
			{
				// set the state
				[anItem setState: [[[self selectedResources] valueForKey:@"label"] stateForInteger:tag] ];
					
				// set the title -- would bind but does not work in Leopard 10.5.2 at the very least
				NSString *defaultsKey = [NSString stringWithFormat:@"LabelName%i",tag];
				NSString *itemTitle = [[NSUserDefaults standardUserDefaults] stringForKey:defaultsKey];
				if ( itemTitle != nil ) [anItem setTitle:itemTitle];
			}
		}
		
		else if ( action == @selector(emailResourceSelection:) )
		{
			enabled = ( [[NSUserDefaults standardUserDefaults] integerForKey:@"UseMailForEmailing"] != 2 );
		}
		
	}
	
	return enabled;
}

#pragma mark -
#pragma mark Adding media to entries

- (BOOL) _addMailMessage:(NSDictionary*)objectDictionary
{
	// YOU MUST RETAIN objectDictionary BEFORE CALLING THIS METHOD
	
	BOOL success = [self _addMailMessage:[objectDictionary objectForKey:@"dragginginfo"] toEntry:[objectDictionary objectForKey:@"entry"]];
	
	// objectDictionary was retained before being sent
	[objectDictionary release];
	return success;
}

- (BOOL) _addMailMessage:(id <NSDraggingInfo>)sender toEntry:(JournlerEntry*)anEntry
{
	IntegrationCopyFiles *notice = [[IntegrationCopyFiles alloc] init];
	[notice setNoticeText:NSLocalizedString(@"integration reading messages",@"")];
	[notice runNotice];
	
	BOOL success = YES;
	unsigned operation = _dragOperation;
	NSPasteboard *pboard = [sender draggingPasteboard];
	
	// get the path, get the selection via applescript, build the full paths
	static NSString *selectionIDsSource = @"tell application \"Mail\"\nset mailSelection to the selection\nset allIDs to {}\nrepeat with aMail in mailSelection\nset allIDs to allIDs & {{the id of aMail, the subject of aMail}}\nend repeat\nreturn allIDs\nend tell";
	
	NSString *mboxPath = [pboard stringForType:kMailMessagePboardType];
	
	#ifdef __DEBUG__
	NSLog(mboxPath);
	#endif
	
	NSDictionary *errorDictionary = nil;
	NSAppleEventDescriptor *eventDescriptor;
	NSAppleScript *script;
	NSString *scriptPath = [[NSBundle mainBundle] pathForResource:@"GetMailSelection" ofType:@"scpt"];
	
	if (scriptPath == nil )
		script = [[[NSAppleScript alloc] initWithSource:selectionIDsSource] autorelease];
	else
		script = [[[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:scriptPath] error:&errorDictionary] autorelease];
	
	if ( script == nil )
	{
		NSLog(@"%s - unable to initialize the mail message script: %@", __PRETTY_FUNCTION__, errorDictionary);
		
		id theSource = [script richTextSource];
		if ( theSource == nil ) theSource = [script source];
		AppleScriptAlert *scriptAlert = [[[AppleScriptAlert alloc] initWithSource:theSource error:errorDictionary] autorelease];
			
		NSBeep();
		[scriptAlert showWindow:self];
		
		success = NO;
		goto bail;
	}
	else
	{
	
		eventDescriptor = [script executeAndReturnError:&errorDictionary];
		if ( eventDescriptor == nil && [[errorDictionary objectForKey:NSAppleScriptErrorNumber] intValue] != kScriptWasCancelledError )
		{
			NSLog(@"%s - problem compiling mail message selection script: %@", __PRETTY_FUNCTION__, errorDictionary);
			
			id theSource = [script richTextSource];
			if ( theSource == nil ) theSource = [script source];
			AppleScriptAlert *scriptAlert = [[[AppleScriptAlert alloc] initWithSource:theSource error:errorDictionary] autorelease];
			
			NSBeep();
			[scriptAlert showWindow:self];
			
			success = NO;
			goto bail;
		}
		else if ( [eventDescriptor numberOfItems] == 0 )
		{
			NSLog(@"%s - mail messasge drag, the return event descriptor contains no items: %@", __PRETTY_FUNCTION__, eventDescriptor);
			success = NO;
			goto bail;
		}
		else
		{
			#ifdef __DEBUG__
			NSLog([eventDescriptor description]);
			#endif
			
			int i, totalItems = [eventDescriptor numberOfItems];
			for ( i = 1; i <= totalItems; i++ )
			{
				NSAppleEventDescriptor *itemDescriptor = [eventDescriptor descriptorAtIndex:i];
				
				#ifdef __DEBUG__
				NSLog([itemDescriptor description]);
				#endif
				
				if ( [itemDescriptor numberOfItems] != 2 )
				{
					NSLog(@"%s - the item descriptor is not properly formatted", __PRETTY_FUNCTION__);
					success = NO;
					continue;
				}
				
				// each event descriptor is itself an array of two items: id, subject
				int anID = [[itemDescriptor descriptorAtIndex:1] int32Value];
				NSString *aSubject = [[itemDescriptor descriptorAtIndex:2] stringValue];
				
				NSString *aMessagePath = [[mboxPath stringByAppendingPathComponent:@"Messages"] 
						stringByAppendingPathComponent:[NSString stringWithFormat:@"%i.emlx", anID]];
				
				success = ( [self _addFile:aMessagePath title:( [aSubject length] > 0 ? aSubject : NSLocalizedString(@"untitled title", @"") ) 
				resourceCommand:operation toEntry:anEntry] && success );
			}
		}
	}
	
bail:

	[notice endNotice];
	[notice release];

	// put up an error if necessary
	if ( success == NO )
	{
		NSBeep();
		[[NSAlert resourceToEntryError] runModal];
	}
	
	return success;
}

- (BOOL) _addPerson:(ABPerson*)aPerson toEntry:(JournlerEntry*)anEntry
{
	BOOL success = NO;
	
	JournlerResource *resource = [anEntry resourceForABPerson:aPerson];
	if ( resource == nil )
		NSLog(@"%s - unable to create resource for ABPerson %@", __PRETTY_FUNCTION__, [aPerson uniqueId]);
	else
		success = YES;
	
	return success;
}

- (BOOL) _addURL:(NSURL*)aURL title:(NSString*)title toEntry:(JournlerEntry*)anEntry
{
	BOOL success = NO;
	
	if ( [aURL isFileURL] )
		success = [self _addFile:[aURL path] title:title resourceCommand:kNewResourceForceLink toEntry:anEntry];
	
	else if ( [aURL isJournlerURI] )
		success = [self _addJournlerObjectWithURI:aURL toEntry:anEntry];
	
	else
	{
		JournlerResource *resource = [anEntry resourceForURL:[aURL absoluteString] title:title];
		if ( resource == nil )
			NSLog(@"%s - unable to create resource for url %@", __PRETTY_FUNCTION__, [aURL absoluteString]);
		else
			success = YES;
	}
	
	return success;
}

- (BOOL) _addJournlerObjectWithURI:(NSURL*)aURL toEntry:(JournlerEntry*)anEntry
{
	BOOL success = NO;
	
	JournlerObject *theObject = [[self valueForKeyPath:@"delegate.journal"] objectForURIRepresentation:aURL];
	if ( theObject == nil )
		NSLog(@"%s - unable to produce object for uri %@", __PRETTY_FUNCTION__, [aURL absoluteString]);
	else
	{
		if ( [theObject isKindOfClass:[JournlerEntry class]] || [theObject isKindOfClass:[JournlerCollection class]] )
		{
			// establish the relationship with the entry - note I don't actually use this resource for anything
			JournlerResource *resource = [anEntry resourceForJournlerObject:theObject];
			if ( resource == nil )
				NSLog(@"%s - unable to produce new resource for uri %@", __PRETTY_FUNCTION__, [aURL absoluteString]);
			else
				success = YES;
		}
		else if ([theObject isKindOfClass:[JournlerResource class]] )
		{
			// add the resource to the entry
			success = ( [anEntry addResource:(JournlerResource*)theObject] == (JournlerResource*)theObject );
		}
	}
	
	return success;
}

- (BOOL) _addAttributedString:(NSAttributedString*)anAttributedString toEntry:(JournlerEntry*)anEntry
{
	BOOL success = NO;
	
	NSFileWrapper *fileWrapper = [anAttributedString RTFDFileWrapperFromRange:NSMakeRange(0,[anAttributedString length]) documentAttributes:nil];
	if ( fileWrapper == nil )
		NSLog(@"%s - unable to create file wrapper for attributed string", __PRETTY_FUNCTION__);
	else
	{
		NSString *destination = [[TempDirectory() stringByAppendingPathComponent:NSLocalizedString(@"untitled title",@"")]
				stringByAppendingPathExtension:@"rtfd"];
		if ( destination == nil )
			NSLog(@"%s - unable to temporary path for file wrapper", __PRETTY_FUNCTION__);
		else
		{
			if ( ![fileWrapper writeToFile:destination atomically:YES updateFilenames:YES] )
				NSLog(@"%s - unable to save attributed string file wrapper to %@", __PRETTY_FUNCTION__, destination);
			else
			{
				if ( ![anEntry resourceForFile:destination operation:kNewResourceForceCopy] )
					NSLog(@"%s - unable to convert path to resource: %@", __PRETTY_FUNCTION__, destination);
				else
					success = YES;
			}
		}
	}
	
	return success;
}

- (BOOL) _addString:(NSString*)aString toEntry:(JournlerEntry*)anEntry
{
	BOOL success = NO;
	
	NSString *destination = [[TempDirectory() stringByAppendingPathComponent:NSLocalizedString(@"untitled title",@"")]
			stringByAppendingPathExtension:@"txt"];
	if ( destination == nil )
		NSLog(@"%s - unable to prepare temporary path for string", __PRETTY_FUNCTION__);
	else
	{
		NSError *error;
		if ( ![aString writeToFile:destination atomically:YES encoding:NSUTF8StringEncoding error:&error] )
			NSLog(@"%s - unable to write string to file %@, error %@", __PRETTY_FUNCTION__, destination, error);
		else
		{
			if ( ![anEntry resourceForFile:destination operation:kNewResourceForceCopy] )
				NSLog(@"%s - unable to convert path to resource: %@", __PRETTY_FUNCTION__, destination);
			else
				success = YES;
		}
	}
	
	return success;
}

- (BOOL) _addWebArchiveFromURL:(NSURL*)aURL title:(NSString*)title toEntry:(JournlerEntry*)anEntry
{
	BOOL success = NO;
	
	IntegrationCopyFiles *notice = [[IntegrationCopyFiles alloc] init];
	[notice setNoticeText:NSLocalizedString(@"integration creating archive",@"")];
	[notice runNotice];
	
	NSString *destination;
	NSURLRequest *url_request = [[NSURLRequest alloc] initWithURL:aURL];
	WebView *web_view = [[WebView alloc] initWithFrame:NSMakeRect(0,0,100,100)];
	PDWebDelegate *web_delegate = [[PDWebDelegate alloc] initWithWebView:web_view];
	
	[[web_view mainFrame] loadRequest:url_request];
	[web_delegate waitForView:15.0];
	
	[notice endNotice];
	[notice release];
	
	if ( [[[web_view mainFrame] dataSource] isLoading] )
	{
		[[web_view mainFrame] stopLoading];
		NSLog(@"%s - operation timed out loading url %@", __PRETTY_FUNCTION__, [aURL absoluteString] );
		destination = nil;
		goto bail;
	}
	
	WebArchive *services_archive = [[[web_view mainFrame] DOMDocument] webArchive];
	if ( title == nil ) title = [[[web_view mainFrame] dataSource] pageTitle];
	if ( title == nil || [title length] == 0 ) title = NSLocalizedString(@"untitled title", @"");
	
	if ( services_archive == nil ) 
	{
		NSLog(@"%s - unable to derive webarchive from url %@", __PRETTY_FUNCTION__, [aURL absoluteString] );
		destination = nil;
		goto bail;
	}
	
	destination = [[TempDirectory() stringByAppendingPathComponent:[title pathSafeString]] stringByAppendingPathExtension:@"webarchive"];
	
	if ( ![[services_archive data] writeToFile:destination options:NSAtomicWrite error:nil]	) 
	{
		NSLog(@"%s - unable to write webarchive to %@", __PRETTY_FUNCTION__, destination);
		destination = nil;
		goto bail;
	}

bail:
	
	if ( destination == nil )
		success =  NO;
	else
		success = [self _addFile:destination title:( title ? title : [aURL absoluteString] ) resourceCommand:kNewResourceForceCopy toEntry:anEntry];
	
	return success;
}

- (BOOL) _addImageData:(NSData*)imageData dataType:(NSString*)type title:(NSString*)title toEntry:(JournlerEntry*)anEntry
{
	BOOL success = NO;
	
	return success;
}

- (BOOL) _addFile:(NSString*)filename title:(NSString*)title resourceCommand:(NewResourceCommand)command toEntry:(JournlerEntry*)anEntry
{
	BOOL success = NO;
	
	BOOL dir, package;
	int actualCommand = kNewResourceForceLink;
	//NSString *displayName;
	NSString *appName = nil, *fileType = nil;
	
	// make sure the file exists at this path
	if ( ![[NSFileManager defaultManager] fileExistsAtPath:filename isDirectory:&dir] ) 
	{
		NSLog(@"%s - file does not exist at path %@", __PRETTY_FUNCTION__, filename);
		return NO;
	}
	
	// get the file's type
	if ( ![[NSWorkspace sharedWorkspace] getInfoForFile:filename application:&appName type:&fileType] ) 
	{
		NSLog(@"%s - unable to get file type at path %@", __PRETTY_FUNCTION__, filename);
		//return NO;
	}
	
	// is the file a package?
	package = [[NSWorkspace sharedWorkspace] isFilePackageAtPath:filename];
	
	// determine the actual command, copy or link the file, depending on type, media policy and caller's demands
	actualCommand = [self _commandForCurrentCommand:command fileType:fileType directory:dir package:package];
	
	// having determined the actual command, perform the copy or link
	JournlerResource *resource;
	if ( actualCommand == kNewResourceForceLink ) 
	{
		resource = [anEntry resourceForFile:filename operation:actualCommand];
	}
	
	else if ( actualCommand == kNewResourceForceCopy ) 
	{
		IntegrationCopyFiles *notice = [[IntegrationCopyFiles alloc] init];
		[notice runNotice];
		
		resource = [anEntry resourceForFile:filename operation:actualCommand];
		
		[notice endNotice];
		[notice release];
	}

	if ( resource == nil ) 
	{
		NSLog(@"%s - unable to create resource for file at path %@", __PRETTY_FUNCTION__, filename);
		return NO;
	}
	
	success = YES;
	
	// set the resources title if requested
	//if ( title != nil )
	//	[resource setValue:( [title length] != 0 ? title : NSLocalizedString(@"untitled title",@"") ) forKey:@"title"];
	
	if ( [[NSWorkspace sharedWorkspace] canPlayFile:filename] 
			|| [[NSWorkspace sharedWorkspace] canWatchFile:filename] || [[NSWorkspace sharedWorkspace] canViewFile:filename] )
	{
		NSString *displayTitle = [[NSWorkspace sharedWorkspace] mdTitleForFile:filename];
		if ( displayTitle != nil ) [resource setValue:displayTitle forKey:@"title"];
		else [resource setValue:( [title length] != 0 ? title : NSLocalizedString(@"untitled title",@"") ) forKey:@"title"];
	}
	else
	{
		//if ( title == nil ) title = [[NSFileManager defaultManager] displayNameAtPath:filename];
		//[resource setValue:( title != nil && [title length] != 0 ? title : NSLocalizedString(@"untitled title",@"") ) forKey:@"title"];
	}
	
	
	return success;
}

#pragma mark -

- (unsigned) _commandForCurrentCommand:(unsigned)dragOperation fileType:(NSString*)type directory:(BOOL)dir package:(BOOL)package
{
	int actualCommand = kNewResourceForceLink;
	
	// determine the actual command, copy or link the file, depending on type, media policy and caller's demands
	if ( dragOperation == kNewResourceForceLink ) 
	{
		actualCommand = kNewResourceForceLink;
	}
	
	else if ( dragOperation == kNewResourceForceCopy ) 
	{
		actualCommand = kNewResourceForceCopy;
	}
	
	else 
	{
		if ( [NSApplicationFileType isEqualToString:type] || [NSShellCommandFileType isEqualToString:type] ) 
		{
			// always link applications
			actualCommand = kNewResourceForceLink;
		}
		
		else if ( [NSDirectoryFileType isEqualToString:type] || ( dir && !package)  ) 
		{
			if ( [[NSUserDefaults standardUserDefaults] integerForKey:@"MediaPolicyDirectories"] == 0 )
			{
				// link directory with policy = 0
				actualCommand = kNewResourceForceLink;
			}
			
			else 
			{
				// copy if otherwise
				actualCommand = kNewResourceForceCopy;
			}
		}
		
		else if ( [NSFilesystemFileType isEqualToString:type] ) 
		{
			// always link mount points
			actualCommand = kNewResourceForceLink;
		}
		
		else 
		{
			if ( [[NSUserDefaults standardUserDefaults] integerForKey:@"MediaPolicyFiles"] == 0 )
			{
				// link file with policy = 0
				actualCommand = kNewResourceForceLink;
			}
			
			else 
			{
				// copy otherwise
				actualCommand = kNewResourceForceCopy;
			}
		}
	}
	
	return actualCommand;
} 

- (NSString*) _linkedTextForAudioFile:(NSString*)fullpath {
	
	//
	// have a look at the metadata for the file, author and name, or use display name
	
	NSMutableString *return_string = [[NSMutableString allocWithZone:[self zone]] init];
	
	MDItemRef meta_data = MDItemCreate(NULL,(CFStringRef)fullpath);
	if ( meta_data != NULL ) {
		
		NSString *title = (NSString*)MDItemCopyAttribute(meta_data,kMDItemTitle);
		NSArray *authors = (NSArray*)MDItemCopyAttribute(meta_data,kMDItemAuthors);
		NSString *composer = (NSString*)MDItemCopyAttribute(meta_data,kMDItemComposer);
		
		if ( title != nil ) {
			
			if ( authors != nil )
				[return_string appendFormat:@"%@ - ", [authors componentsJoinedByString:@", "]];
			else if ( composer != nil )
				[return_string appendFormat:@"%@ - ", composer];
			
			[return_string appendString:title];
			
		}
		else {
			
			// use the display name no path
			[return_string appendString:[[fullpath lastPathComponent] stringByDeletingPathExtension]];
			
		}
		
		//
		// clean up
		CFRelease(meta_data);
		
	}
	else {
		
		//
		// use the display name no path
		[return_string appendString:[[fullpath lastPathComponent] stringByDeletingPathExtension]];
		
	}
	
	return [return_string autorelease];
}

- (NSString*) _mdTitleFoFileAtPath:(NSString*)fullpath {
	
	//
	// have a look at the metadata for the file, author and name, or use display name
	
	NSString *title = nil;
	
	MDItemRef meta_data = MDItemCreate(NULL,(CFStringRef)fullpath);
	if ( meta_data != NULL ) 
	{
		// grab the title
		title = [(NSString*)MDItemCopyAttribute(meta_data,kMDItemTitle) autorelease];
		// clean up
		CFRelease(meta_data);
	}
	else 
	{
		// use the display name no path
		title = [[fullpath lastPathComponent] stringByDeletingPathExtension];
	}
	
	return title;
}

@end
