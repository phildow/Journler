//
//  IndexArrayController.m
//  Journler
//
//  Created by Philip Dow on 2/8/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import "IndexArrayController.h"
#import "IndexTreeController.h"

#import <SproutedUtilities/SproutedUtilities.h>

/*
#import "NSOutlineView_Extensions.h"
#import "NSOutlineView_ProxyAdditions.h"
*/

@implementation IndexArrayController


- (void)setFilterPredicate:(NSPredicate *)filterPredicate
{
	// note the selection
	id theSelection = [[outlineView originalItemAtRow:[outlineView selectedRow]] retain];
	
	// ignore the selection change for a moment
	[treeController setIgnoreNewSelection:YES];
	
	// and unbind it
	[treeController setContent:nil];
	[treeController unbind:@"contentArray"];
	
	NSInteger i;
	NSMutableArray *expandedItems = [NSMutableArray array];
	
	// note the expanded items
	for ( i = 0; i < [outlineView numberOfRows]; i++ )
	{
		if ( [outlineView isItemExpanded:[outlineView itemAtRow:i]] )
			[expandedItems addObject:[outlineView originalItemAtRow:i]];
	}
	
	// deselect
	[outlineView deselectAll:self];
	
	// filter
	[super setFilterPredicate:filterPredicate];
	
	// re-expand the still visible items
	for ( i = 0; i < [expandedItems count]; i++ )
	{
		NSInteger aRow = [outlineView rowForOriginalItem:[expandedItems objectAtIndex:i]];
		if ( aRow != -1 ) [outlineView expandItem:[outlineView itemAtRow:aRow] expandChildren:NO];
	}
	
	// rebind it
	[treeController bind:@"contentArray" toObject:self withKeyPath:@"arrangedObjects" options:nil];
	//[outlineView reloadData]; 
	
	// re-select the last selection if it is availble, otherwise select the first item - or just deselect all
	NSInteger selectionRow = [outlineView rowForOriginalItem:theSelection];
	if ( selectionRow != - 1)
	{
		//[outlineView selectRow:selectionRow byExtendingSelection:NO]; DEPRECATED
		[outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectionRow] byExtendingSelection:NO];
        [outlineView scrollRowToVisible:selectionRow];
	}
	else
	{
		[treeController setIgnoreNewSelection:NO];
		[outlineView deselectAll:self];
	}
	
	//restore selection watching
	[treeController setIgnoreNewSelection:NO];
	[theSelection release];
}

@end
