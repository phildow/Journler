//
//  IndexTreeController.m
//  Journler
//
//  Created by Philip Dow on 2/6/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "IndexTreeController.h"

#import <SproutedUtilities/SproutedUtilities.h>

/*
#import "NSOutlineView_Extensions.h"
#import "NSOutlineView_ProxyAdditions.h"
*/

@implementation IndexTreeController

-(void)setSortDescriptors:(NSArray *)sortDescriptors
{
	// seems to be a bug - the outline view is not immediately re-ordered
	
	ignoreNewSelection = YES;
	
	// note the selection
	//NSArray *theSelection = [outlineView allSelectedItems];
	id theSelection = [[outlineView originalItemAtRow:[outlineView selectedRow]] retain];
	
	int i;
	NSMutableArray *expandedItems = [NSMutableArray array];
	
	// note the expanded items
	for ( i = 0; i < [outlineView numberOfRows]; i++ )
	{
		if ( [outlineView isItemExpanded:[outlineView itemAtRow:i]] )
			[expandedItems addObject:[outlineView originalItemAtRow:i]];
	}
	
	// deselect, set sort descriptor, re-order
	[outlineView deselectAll:self];
	[super setSortDescriptors:sortDescriptors];
	[self rearrangeObjects];
	
	// re-expand the expanded rows
	for ( i = 0; i < [expandedItems count]; i++ )
		[outlineView expandItem:[outlineView itemAtRow:[outlineView rowForOriginalItem:[expandedItems objectAtIndex:i]]] expandChildren:NO];
	
	// reselect the old selection
	//[outlineView selectItems:theSelection byExtendingSelection:NO];
	unsigned targetRow = [outlineView rowForOriginalItem:theSelection];
	if ( targetRow != -1 ) 
	{
		//[outlineView selectRow:targetRow byExtendingSelection:NO]; DEPRECATED
		[outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:targetRow] byExtendingSelection:NO];
        [outlineView scrollRowToVisible:targetRow];
	}
	
	[theSelection release];
	ignoreNewSelection = NO;
}

#pragma mark -

- (BOOL) ignoreNewSelection
{
	return ignoreNewSelection;
}

- (void) setIgnoreNewSelection:(BOOL)ignore
{
	ignoreNewSelection = ignore;
}

#pragma mark -
#pragma mark Dummy NSOutlineView Data Source


- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item 
{
	return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item 
{
	return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item 
{
	return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView 
		objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item 
{
	return nil;
}

#pragma mark -

- (BOOL)outlineView:(NSOutlineView *)anOutlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard 
{
	// pass these to the outline view's delegate
	// convert the items to their actual counterparts
	
	id outlineDelegate = [anOutlineView delegate];
	if ( [outlineDelegate respondsToSelector:@selector(outlineView:writeItems:toPasteboard:)] )
	{
		id anItem;
		NSEnumerator *enumerator = [items objectEnumerator];
		NSMutableArray *actualItems = [NSMutableArray arrayWithCapacity:[items count]];
		
		while ( anItem = [enumerator nextObject] )
		{
			id representedObject = nil;
			if ( [anItem respondsToSelector:@selector(representedObject)] )
				representedObject = [anItem representedObject];
			else if ( [anItem respondsToSelector:@selector(observedObject)] )
				representedObject = [anItem observedObject];
			
			if ( representedObject != nil )
				[actualItems addObject:representedObject];
		}
		
		return [outlineDelegate outlineView:anOutlineView writeItems:actualItems toPasteboard:pboard];
	}
	else
		return NO;
}

- (NSArray *)outlineView:(NSOutlineView *)anOutlineView 
		namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedItems:(NSArray *)items
{
	// pass these to the outline view's delegate
	// convert the items to their actual counterparts
	
	id outlineDelegate = [anOutlineView delegate];
	if ( [outlineDelegate respondsToSelector:@selector(outlineView:namesOfPromisedFilesDroppedAtDestination:forDraggedItems:)] )
	{
		id anItem;
		NSEnumerator *enumerator = [items objectEnumerator];
		NSMutableArray *actualItems = [NSMutableArray arrayWithCapacity:[items count]];
		
		while ( anItem = [enumerator nextObject] )
		{
			id representedObject = nil;
			if ( [anItem respondsToSelector:@selector(representedObject)] )
				representedObject = [anItem representedObject];
			else if ( [anItem respondsToSelector:@selector(observedObject)] )
				representedObject = [anItem observedObject];
			
			if ( representedObject != nil )
				[actualItems addObject:representedObject];
		}

		return [outlineDelegate outlineView:anOutlineView namesOfPromisedFilesDroppedAtDestination:dropDestination forDraggedItems:actualItems];
	}
	else
		return nil;
}

@end
