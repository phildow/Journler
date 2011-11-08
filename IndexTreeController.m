//
//  IndexTreeController.m
//  Journler
//
//  Created by Philip Dow on 2/6/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

/*
 Redistribution and use in source and binary forms, with or without modification, are permitted
 provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions
 and the following disclaimer in the documentation and/or other materials provided with the
 distribution.
 
 * Neither the name of the author nor the names of its contributors may be used to endorse or
 promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// Basically, you can use the code in your free, commercial, private and public projects
// as long as you include the above notice and attribute the code to Philip Dow / Sprouted
// If you use this code in an app send me a note. I'd love to know how the code is used.

// Please also note that this copyright does not supersede any other copyrights applicable to
// open source code used herein. While explicit credit has been given in the Journler about box,
// it may be lacking in some instances in the source code. I will remedy this in future commits,
// and if you notice any please point them out.

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
	
	NSInteger i;
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
	NSUInteger targetRow = [outlineView rowForOriginalItem:theSelection];
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


- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item 
{
	return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item 
{
	return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item 
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
		NSMutableArray *actualItems = [NSMutableArray arrayWithCapacity:[items count]];
		
        for ( id anItem in items )
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
		NSMutableArray *actualItems = [NSMutableArray arrayWithCapacity:[items count]];
		
        for ( id anItem in items )
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
