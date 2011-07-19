//
//  IndexColumn.m
//  Journler
//
//  Created by Philip Dow on 2/6/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import "IndexColumn.h"

#import "IndexNode.h"
#import "IndexColumnView.h"
#import "IndexOutlineView.h"
#import "IndexTreeController.h"
#import "IndexSearchField.h"

#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>

static NSString *kIndexColumnObserver = @"IndexColumnObserver";

#warning progress indicator: indicator

@implementation IndexColumn

- (id)init
{
	if ( self = [super init] )
	{
		showsCount = YES;
		showsFrequency = YES;
		
		canFilterTitle = YES;
		canFilterCount = YES;
		
		title = [[NSString alloc] init];
		headerTitle = [[NSString alloc] initWithString:@"Term"];
		countSuffix = [[NSString alloc] init];
		
		[NSBundle loadNibNamed:@"IndexColumn" owner:self];
	}
	
	return self;
}

- (void) awakeFromNib
{
	// default sort descriptor
	NSSortDescriptor *titleSort = [[[NSSortDescriptor alloc] 
			initWithKey:@"title" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] autorelease];
	
	[outlineView sizeToFit];
	[outlineController setSortDescriptors:[NSArray arrayWithObject:titleSort]];
	
	NSInteger borders[4] = {0,1,0,1};
	[footer setBordered:YES];
	[footer setBorders:borders];
	[header setBordered:YES];
	[header setBorders:borders];
	
	//[rootController addObserver:self 
	//		forKeyPath:@"filterPredicate" 
	//		options:0 
	//		context:kIndexColumnObserver];
	
	[rootController addObserver:self 
			forKeyPath:@"arrangedObjects" 
			options:0 
			context:kIndexColumnObserver];
			
	[outlineController addObserver:self 
			forKeyPath:@"selectedObjects" 
			options:0 
			context:kIndexColumnObserver];
}

- (void) dealloc
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	[title release];
	[countSuffix release];
	[columnView release];
	[filterPredicate release];
	
	[ownerController release];
	[outlineController release];
	[rootController release];
	
	[super dealloc];
}

- (void) ownerWillClose:(NSNotification*)aNotification
{
	//[rootController removeObserver:self forKeyPath:@"filterPredicate"];
	[rootController removeObserver:self forKeyPath:@"arrangedObjects"];
	[outlineController removeObserver:self forKeyPath:@"selectedObjects"];
	
	[outlineView setDelegate:nil];
	//[rootController setContent:nil];
	
	[ownerController unbind:@"contentObject"];
	[ownerController setContent:nil];
}

#pragma mark -

- (IndexColumnView*) columnView
{
	return columnView;
}

- (IndexNode*) selectedObject
{
	if ( [[outlineController selectedObjects] count] == 0 )
		return nil;
	
	else return [[outlineController selectedObjects] objectAtIndex:0];
}

- (NSArray*) selectedObjects
{
	if ( [[outlineController selectedObjects] count] == 0 )
		return nil;
		
	else return [outlineController selectedObjects];
	
}

- (NSArray*) content
{
	return [rootController content];
}

- (void) setContent:(NSArray*)content
{
	// pass it to the array controller, but unbind the tree controller first - why is this necessary to prevent a crash?
	[outlineController unbind:@"contentArray"];
	[outlineController setContent:nil];
	
	if ( content == nil )
	{
		// nil content is a message that the content is being loaded
		// pass an empty array if that is not the case
		
		[rootController setContent:[NSArray array]];
		[outlineController setContent:[NSArray array]];
		
		/*
		if ( [indicator isHidden] )
		{
			[indicator setHidden:NO];
			[indicator startAnimation:self];
		}
		*/
	}
	else
	{
		/*
		if ( ![indicator isHidden] )
		{
			[indicator stopAnimation:self];
			[indicator setHidden:YES];
		}
		*/
		
		[rootController setContent:content];
	}
	
	[outlineController bind:@"contentArray" toObject:rootController withKeyPath:@"arrangedObjects" options:nil];

}

- (NSArray*) sortDescriptors
{
	return [outlineController sortDescriptors];
}

- (void) setSortDescriptors:(NSArray*)anArray
{
	// just pass it on to the controller
	[outlineController setSortDescriptors:anArray];
}

- (BOOL) allowsMultipleSelection
{
	return [outlineView allowsMultipleSelection];
}

- (void) setAllowsMultipleSelection:(BOOL)flag
{
	// just pass it to the outline view
	[outlineView setAllowsMultipleSelection:flag];
}

- (float) rowHeight
{
	return [outlineView rowHeight];
}

- (void) setRowHeight:(float)height
{
	// just pass it to the outline view
	[outlineView setRowHeight:height];
}

- (NSMenu*) menu
{
	return [outlineView menu];
}

- (void) setMenu:(NSMenu*)aMenu
{
	[outlineView setMenu:aMenu];
}

#pragma mark -

- (id) delegate
{
	return delegate;
}

- (void) setDelegate:(id)anObject
{
	delegate = anObject;
}

- (BOOL) drawsIcon
{
	return drawsIcon;
}

- (void) setDrawsIcon:(BOOL)draw
{
	drawsIcon = draw;
}

- (BOOL) showsCount
{
	return showsCount;
}

- (void) setShowsCount:(BOOL)show
{
	if ( showsCount != show )
	{
		showsCount = show;
		
		if ( !showsCount )
			[outlineView removeTableColumn:[outlineView tableColumnWithIdentifier:@"count"]];
		
		[outlineView sizeToFit];
	}
}

- (BOOL) showsFrequency
{
	return showsFrequency;
}

- (void) setShowsFrequency:(BOOL)show
{
	if ( showsFrequency != show )
	{
		showsFrequency = show;
		
		if ( !showsFrequency )
			[outlineView removeTableColumn:[outlineView tableColumnWithIdentifier:@"frequency"]];
		
		[outlineView sizeToFit];
	}
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

- (NSString*) headerTitle
{
	return headerTitle;
}

- (void) setHeaderTitle:(NSString*)aString
{
	if ( headerTitle != aString )
	{
		[headerTitle release];
		headerTitle = [aString copyWithZone:[self zone]];
	}
}

- (NSString*) countSuffix
{
	return countSuffix;
}

- (void) setCountSuffix:(NSString*)aString
{
	if ( countSuffix != aString )
	{
		[countSuffix release];
		countSuffix = [aString copyWithZone:[self zone]];
	}
}

- (NSPredicate*) filterPredicate
{
	return filterPredicate;
}

- (void) setFilterPredicate:(NSPredicate*)aPredicate
{
	if ( filterPredicate != aPredicate )
	{
		[filterPredicate release];
		filterPredicate = [aPredicate retain];
		
		[self setTitleFilterEnabled:( aPredicate == nil ? NO : YES )];
	}
	
	#ifdef __DEBUG__
	if ( aPredicate == nil )
		NSLog(@"%s - nil predicate", __PRETTY_FUNCTION__);
	else
		NSLog(@"%s - %@", __PRETTY_FUNCTION__, [aPredicate description]);
	#endif

}

#pragma mark -

- (int) minCount
{
	return minCount;
}

- (void) setMinCount:(int)aCount
{
	minCount = aCount;
	[self setCountRestriction:nil];
}

- (int) maxCount
{
	return maxCount;
}

- (void) setMaxCount:(int)aCount
{
	maxCount = aCount;
	[self setCountRestriction:nil];
}

- (BOOL) canFilterCount
{
	return canFilterCount;
}

- (void) setCanFilterCount:(BOOL)countFilters
{
	canFilterCount = countFilters;
}

- (BOOL) canFilterTitle
{
	return canFilterTitle;
}

- (void) setCanFilterTitle:(BOOL)titleFilters
{
	canFilterTitle = titleFilters;
}

#pragma mark -

- (BOOL) countFilterEnabled
{
	return countFilterEnabled;
}

- (void) setCountFilterEnabled:(BOOL)enabled
{
	countFilterEnabled = enabled;
	[self determineCompoundPredicate];
}

- (BOOL) titleFilterEnabled
{
	return titleFilterEnabled;
}

- (void) setTitleFilterEnabled:(BOOL)enabled
{
	titleFilterEnabled = enabled;
	[self determineCompoundPredicate];
}

- (BOOL) canDeleteContent
{
	return canDeleteContent;
}

- (void) setCanDeleteContent:(BOOL)canDelete
{
	canDeleteContent = canDelete;
}

#pragma mark -

- (BOOL) selectNode:(IndexNode*)aNode
{
	NSInteger row = [outlineView rowForOriginalItem:aNode];
	
	if ( row == -1 )
		return NO;
	else 
	{
		[outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
		
		NSRect rowRect = [outlineView rectOfRow:row];
		[[[outlineView enclosingScrollView] contentView] scrollToPoint:rowRect.origin];
		[[outlineView enclosingScrollView] reflectScrolledClipView:[[outlineView enclosingScrollView] contentView]];
		
		// re-target the outline view - the selection created a new one that took focus
		[[outlineView window] makeFirstResponder:outlineView];
		
		//[outlineView scrollRowToVisible:<#(int)row#>
		return YES;
	}
}

- (BOOL) scrollNodeToVisible:(IndexNode*)aNode
{
	NSInteger row = [outlineView rowForOriginalItem:aNode];
	
	if ( row == -1 )
		return NO;
	else 
	{
		NSRect rowRect = [outlineView rectOfRow:row];
		[[[outlineView enclosingScrollView] contentView] scrollToPoint:rowRect.origin];
		[[outlineView enclosingScrollView] reflectScrolledClipView:[[outlineView enclosingScrollView] contentView]];
		
		// re-target the outline view - the selection created a new one that took focus
		[[outlineView window] makeFirstResponder:outlineView];
		
		//[outlineView scrollRowToVisible:<#(int)row#>
		return YES;
	}
}

- (BOOL) focusOutlineWithSelection:(BOOL)selectFirstNode
{
	[[outlineView window] makeFirstResponder:outlineView];
	
	if ( selectFirstNode && [outlineView selectedRow] == -1 )
		[outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	
	return YES;
}

- (IBAction) setCountRestriction:(id)sender
{
	[self setCountFilterEnabled:( [self minCount] != 0 || [self maxCount] != 0 )];
}

#pragma mark -

- (void) determineCompoundPredicate
{
	#ifdef __DEBUG__
	NSLog(@"%s - min: %i max: %i", __PRETTY_FUNCTION__, minCount, maxCount);
	#endif
	
	NSPredicate *countPredicate = nil;
	NSPredicate *myFilterPredicate = nil;
	
	NSPredicate *compoundPredicate = nil;
	
	if ( [self countFilterEnabled] )
	{
		if ( minCount == 0 && maxCount == 0 )
			countPredicate = nil;
		
		else if ( minCount > 0 && maxCount == 0 )
			countPredicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"count >= %i", minCount]];
		
		else if ( minCount == 0 && maxCount > 0 )
			countPredicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"count <= %i", maxCount]];
		
		else if ( minCount > 0 && maxCount > 0 )
			countPredicate  = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"count >= %i AND count <= %i", minCount, maxCount]];
	}
	
	
	if ( [self titleFilterEnabled] )
	{
		myFilterPredicate = [self filterPredicate];
	}
	
	
	if ( countPredicate == nil && myFilterPredicate == nil )
		compoundPredicate = nil;
	
	else if ( countPredicate != nil && myFilterPredicate == nil )
		compoundPredicate = countPredicate;
	
	else if ( countPredicate == nil && myFilterPredicate != nil )
		compoundPredicate = myFilterPredicate;
	
	else if ( countPredicate != nil && myFilterPredicate != nil )
		compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:countPredicate, myFilterPredicate, nil]];
	
	
	[rootController setFilterPredicate:compoundPredicate];
}

#pragma mark -

- (void)observeValueForKeyPath:(NSString *)keyPath 
		ofObject:(id)object 
		change:(NSDictionary *)change 
		context:(void *)context
{	
	if ( context == kIndexColumnObserver )
	{
		if ( object == outlineController && [[outlineController selectedObjects] count] != 0 && ![outlineController ignoreNewSelection] )
		{
			if ( [[self delegate] respondsToSelector:@selector(columnDidChangeSelection:)] )
				[[self delegate] columnDidChangeSelection:self];
		}
		else if ( object == rootController )
		{
			/*
			if ( [keyPath isEqualToString:@"filterPredicate"] )
			{
				BOOL filtering = ( [rootController filterPredicate] != nil );
				[searchCheck setState:( filtering ? NSOnState : NSOffState )];
			}
			*/
			
			if ( [keyPath isEqualToString:@"arrangedObjects"] )
			{
				
				NSString *titleFieldValue = [NSString stringWithFormat:@"%@: %i %@", [self title], 
						[[rootController arrangedObjects] count], [self countSuffix]];
			
				[titleField setStringValue:titleFieldValue];
			}
		}
	}
	else
	{
		[super observeValueForKeyPath:keyPath 
				ofObject:object 
				change:change 
				context:context];
	}
}

#pragma mark -

- (void) outlineView:(IndexOutlineView*)anOutlineView leftKeyDown:(NSEvent*)anEvent
{
	if ( [[self delegate] respondsToSelector:@selector(outlineView:leftKeyDown:)] )
		[[self delegate] outlineView:anOutlineView leftKeyDown:anEvent];
}

- (void) outlineView:(IndexOutlineView*)anOutlineView rightKeyDown:(NSEvent*)anEvent
{
	if ( [[self delegate] respondsToSelector:@selector(outlineView:rightKeyDown:)] )
		[[self delegate] outlineView:anOutlineView rightKeyDown:anEvent];
}

#pragma mark -

/*
- (float)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
	IndexNode *actualItem = nil;
	if ( [item respondsToSelector:@selector(representedObject)] )
		actualItem = [item representedObject];
	else if ( [item respondsToSelector:@selector(observedObject)] )
		actualItem = [item observedObject];

	if ( drawsIcon ) return ( [actualItem parent] == nil ? kLargeRowHeight : kMediumRowHeight );
	else return kSmallRowHeight;
}
*/

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if ( drawsIcon )
	{
		IndexNode *actualItem = nil;
		if ( [item respondsToSelector:@selector(representedObject)] )
			actualItem = [item representedObject];
		else if ( [item respondsToSelector:@selector(observedObject)] )
			actualItem = [item observedObject];
		
		// set the image
		[(ImageAndTextCell*)cell setImage:[actualItem valueForKeyPath:@"representedObject.icon"]];
		// let the cell know what size of image to use
		[(ImageAndTextCell*)cell setImageSize:
				( [actualItem parent] == nil ? NSMakeSize(kIndexColumnLargeRowHeight,kIndexColumnLargeRowHeight) : NSMakeSize(kIndexColumnMediumRowHeight,kIndexColumnMediumRowHeight) )];
	}
	
	else [(ImageAndTextCell*)cell setImage:nil];
	
}

#pragma mark -

- (BOOL)outlineView:(NSOutlineView *)anOutlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard 
{
	// pass these to my delegate
	id outlineDelegate = [self delegate];
	if ( [outlineDelegate respondsToSelector:@selector(outlineView:writeItems:toPasteboard:)] )
		return [outlineDelegate outlineView:anOutlineView writeItems:items toPasteboard:pboard];
	else
		return NO;

}
- (NSArray *)outlineView:(NSOutlineView *)anOutlineView 
		namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedItems:(NSArray *)items
{
	// pass these to my delegate
	id outlineDelegate = [self delegate];
	if ( [outlineDelegate respondsToSelector:@selector(outlineView:namesOfPromisedFilesDroppedAtDestination:forDraggedItems:)] )
		return [outlineDelegate outlineView:anOutlineView namesOfPromisedFilesDroppedAtDestination:dropDestination forDraggedItems:items];
	else
		return nil;
}

#pragma mark -

- (void) indexOutlineView:(IndexOutlineView*)anOutlineView deleteSelectedRows:(NSIndexSet*)selectedRows
{
	NSBeep();
	return;
	
	// NOT SUPPORTED YET
	
	// permit the operation if we're adding stopwords, otherwise do not allow
	if ( ![self canDeleteContent] || ![[self delegate] respondsToSelector:@selector(indexColumn:deleteSelectedRows:nodes:)] )
	{
		NSBeep(); return;
	}
	
	NSArray *deletedNodes = [[rootController arrangedObjects] objectsAtIndexes:selectedRows];
	
	BOOL deleted = [[self delegate] indexColumn:self deleteSelectedRows:selectedRows nodes:deletedNodes];
	if ( deleted )
	{
		NSMutableArray *newContent = [[[self content] mutableCopyWithZone:[self zone]] autorelease];
		[newContent removeObjectsInArray:deletedNodes];
		[self setContent:newContent];
	}
	
}

#pragma mark -

- (void) searchFieldDidBecomeFirstResponder:(IndexSearchField*)aSearchField
{
	if ( [[self delegate] respondsToSelector:@selector(columnDidComeIntoFocus:)] )
		[[self delegate] columnDidComeIntoFocus:self];
}

- (void) outlineViewDidBecomeFirstResponder:(IndexOutlineView*)anOutlineView
{
	if ( [[self delegate] respondsToSelector:@selector(columnDidComeIntoFocus:)] )
		[[self delegate] columnDidComeIntoFocus:self];
}

@end
