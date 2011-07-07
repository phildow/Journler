//
//  IndexBrowser.m
//  Journler
//
//  Created by Philip Dow on 2/6/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "IndexBrowser.h"

#import "IndexOutlineView.h"
#import "IndexColumnView.h"
#import "IndexColumn.h"
#import "IndexNode.h"

@implementation IndexBrowser

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		
		columns = [[NSArray alloc] init];
		[self addColumn:self];
    }
    return self;
}

- (void) awakeFromNib
{
	// establish a few characteristics for the first column
	
	IndexColumn *firstColumn = [[self columns] objectAtIndex:0];
	
	// determine if it draws its icons
	if ( [[self delegate] respondsToSelector:@selector(browser:columnForNodeDrawsIcon:atColumnIndex:)] )
		[firstColumn setDrawsIcon:[[self delegate] browser:self columnForNodeDrawsIcon:nil atColumnIndex:-1]];
	
	// determine if it draws its count
	if ( [[self delegate] respondsToSelector:@selector(browser:columnForNodeShowsCount:atColumnIndex:)] )
		[firstColumn setShowsCount:[[self delegate] browser:self columnForNodeShowsCount:nil atColumnIndex:-1]];
	
	// determine if it draws its frequency
	if ( [[self delegate] respondsToSelector:@selector(browser:columnForNodeShowsFrequency:atColumnIndex:)] )
		[firstColumn setShowsFrequency:[[self delegate] browser:self columnForNodeShowsFrequency:nil atColumnIndex:-1]];
	
	// does the column allow multiple selection
	if ( [[self delegate] respondsToSelector:@selector(browser:columnForNodeAllowsMultipleSelection:atColumnIndex:) ] )
		[firstColumn setAllowsMultipleSelection:[[self delegate] browser:self columnForNodeAllowsMultipleSelection:nil atColumnIndex:-1]];
	
	// can the column delete its content
	if ( [[self delegate] respondsToSelector:@selector(browser:columnForNodeCanDeleteContent:atColumnIndex:) ] )
		[firstColumn setCanDeleteContent:[[self delegate] browser:self columnForNodeCanDeleteContent:nil atColumnIndex:-1]];
	
	// the row height
	if ( [[self delegate] respondsToSelector:@selector(browser:rowHeightForNode:atColumnIndex:)] )
		[firstColumn setRowHeight:[[self delegate] browser:self rowHeightForNode:nil atColumnIndex:-1]];
	
	// does the column filter the count
	[firstColumn setCanFilterCount:YES];
	
	// determine the title
	if ( [[self delegate] respondsToSelector:@selector(browser:titleForNode:atColumnIndex:)] )
	{
		NSString *delegateTitle = [[self delegate] browser:self titleForNode:nil atColumnIndex:-1];
		if ( delegateTitle != nil ) [firstColumn setTitle:delegateTitle];
	}
	
	// determine the title
	if ( [[self delegate] respondsToSelector:@selector(browser:headerTitleForNode:atColumnIndex:)] )
	{
		NSString *delegateHeaderTitle = [[self delegate] browser:self headerTitleForNode:nil atColumnIndex:-1];
		if ( delegateHeaderTitle != nil ) [firstColumn setHeaderTitle:delegateHeaderTitle];
	}
	
	// determine the count suffix
	if ( [[self delegate] respondsToSelector:@selector(browser:countSuffixForNode:atColumnIndex:)] )
	{
		NSString *delegateSuffix = [[self delegate] browser:self countSuffixForNode:nil atColumnIndex:-1];
		if ( delegateSuffix != nil ) [firstColumn setCountSuffix:delegateSuffix];
	}

}

- (void) dealloc
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	[columns makeObjectsPerformSelector:@selector(ownerWillClose:) withObject:nil];
	[columns release];
	[super dealloc];
}

#pragma mark -

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
	
	/*
	NSColor *gradientStartColor = [NSColor colorWithCalibratedRed:0.92*255.0 green:0.92*255.0 blue:0.92*255.0 alpha:0.6];
	NSColor *gradientEndColor = [NSColor colorWithCalibratedRed:0.82*255.0 green:0.82*255.0 blue:0.82*255.0 alpha:0.6];

    NSRect boxRect = [self bounds];
    NSRect bgRect = NSMakeRect(0,0,boxRect.size.width,18);
  
	int minX = NSMinX(bgRect);
    int maxX = NSMaxX(bgRect);
    int minY = NSMinY(bgRect);
    int maxY = NSMaxY(bgRect);
	
	NSBezierPath *bgPath = [NSBezierPath bezierPathWithRect:rect];
	
	// Wonder if there's a nicer way to get a CIColor from an NSColor...
	CIColor* startColor = [CIColor colorWithRed:[gradientStartColor redComponent] 
										  green:[gradientStartColor greenComponent] 
										   blue:[gradientStartColor blueComponent] 
										  alpha:[gradientStartColor alphaComponent]];
	CIColor* endColor = [CIColor colorWithRed:[gradientEndColor redComponent] 
										green:[gradientEndColor greenComponent] 
										 blue:[gradientEndColor blueComponent] 
										alpha:[gradientEndColor alphaComponent]];
	
	CIFilter *myFilter = [CIFilter filterWithName:@"CILinearGradient"];
	[myFilter setDefaults];
	[myFilter setValue:[CIVector vectorWithX:(minX) 
										   Y:(minY)] 
				forKey:@"inputPoint0"];
	[myFilter setValue:[CIVector vectorWithX:(minX) 
										   Y:(maxY)] 
				forKey:@"inputPoint1"];
	[myFilter setValue:startColor 
				forKey:@"inputColor0"];
	[myFilter setValue:endColor 
				forKey:@"inputColor1"];
	CIImage *theImage = [myFilter valueForKey:@"outputImage"];
	
	
	// Get a CIContext from the NSGraphicsContext, and use it to draw the CIImage
	CGRect dest = CGRectMake(minX, minY, maxX - minX, maxY - minY);
	
	CGPoint pt = CGPointMake(bgRect.origin.x, bgRect.origin.y);
	
	NSGraphicsContext *nsContext = [NSGraphicsContext currentContext];
	[nsContext saveGraphicsState];
	
	[bgPath addClip];
	
	[[nsContext CIContext] drawImage:theImage 
							 atPoint:pt 
							fromRect:dest];
	
	[nsContext restoreGraphicsState];
	*/
	
}

#pragma mark -

- (NSArray*) columns
{
	return columns;
}

- (void) setColumns:(NSArray*)anArray
{
	if ( columns != anArray )
	{
		[columns release];
		columns = [anArray retain];
	}
}

- (id) delegate
{
	return delegate;
}

- (void) setDelegate:(id)anObject
{
	delegate = anObject;
}

#pragma mark -

- (void) setInitialContent:(NSArray*)anArray
{
	unsigned columnCount = [[self columns] count];
	
	if ( columnCount == 0 )
	{
		NSBeep();
		NSLog(@"%s - cannot set initial content when there are no columns", __PRETTY_FUNCTION__);
	}
	
	else if ( columnCount == 1 )
	{
		// set the content array on the first column
		[[[self columns] objectAtIndex:0] setContent:anArray];
	}
	
	else 
	{
		int i;
		// remove every visible column but the first
		for ( i = 1; i < columnCount; i++ )
		{
			[self removeColumn:self];
		}
	}
}

- (void) setContentAtIndex:(NSDictionary*)aDictionary
{
	[self setContent:[aDictionary objectForKey:@"content"] forColumnAtIndex:[[aDictionary objectForKey:@"index"] intValue]];
}

- (BOOL) setContent:(NSArray*)anArray forColumnAtIndex:(unsigned)index
{
	unsigned total = [[self columns] count] - 1;
	if ( index > total )
	{
		NSLog(@"%s - index %i beyond bounds %i", __PRETTY_FUNCTION__, index, total);
		return NO;
	}
	
	[(IndexColumn*)[[self columns] objectAtIndex:index] setContent:anArray];
	return YES;
}

- (float) minWidth
{
	// add together the widths of the currently available columns
	float minWidth = 0.0;
	
	IndexColumn *aColumn;
	NSEnumerator *enumerator = [[self columns] objectEnumerator];
	
	while ( aColumn = [enumerator nextObject] )
		minWidth += ( [[aColumn columnView] bounds].size.width + 2 );
	
	minWidth -= 2;
	return minWidth;
}

#pragma mark -

- (IBAction) addColumn:(id)sender
{
	//NSRect bds = [self bounds];
	NSRect frame = [self frame];
	
	IndexColumn *newColumn = [[[IndexColumn alloc] init] autorelease];
	NSRect columnFrame = [[newColumn columnView] bounds];
	
	// establish the delegate
	[newColumn setDelegate:self];
	
	// set the height of the new column to our current column
	columnFrame.size.height = frame.size.height - frame.origin.y;
	
	// set the width of the new column to that of the last, if there is one
	if ( [[self columns] count] != 0 )
		columnFrame.size.width = [[[[self columns] lastObject] columnView] bounds].size.width;
	
	// position the column at the bottom and end of our view
	columnFrame.origin.y = 0;
	
	float minWidth = [self minWidth];
	columnFrame.origin.x = minWidth + 2;
	
	// set our current frame to mind width and adjust by the width of the new column + 2
	frame.size.width = minWidth + columnFrame.size.width + 2;
	
	// reset our frame
	[self setFrame:frame];
	
	// frame the new column
	[[newColumn columnView] setFrame:columnFrame];
	
	// add the column to the end of our view
	[self addSubview:[newColumn columnView]];
	
	// add the column to our array
	NSMutableArray *newColumns = [[[self columns] mutableCopyWithZone:[self zone]] autorelease];
	[newColumns addObject:newColumn];
	[self setColumns:newColumns]; 
	
	// scroll so that the new column is visible
	[self scrollRectToVisible:columnFrame];
	[[self enclosingScrollView] reflectScrolledClipView:[[self enclosingScrollView] documentView]];
	
	// redraw immediately
	[self display];
	
	// watch for frame notifications
	[[NSNotificationCenter defaultCenter] addObserver:self 
			selector:@selector(columnFrameDidChange:) 
			name:NSViewFrameDidChangeNotification 
			object:[newColumn columnView]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
			selector:@selector(columnWillResize:) 
			name:IndexColumnViewWillBeginResizing 
			object:[newColumn columnView]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
			selector:@selector(columnDidResize:) 
			name:IndexColumnViewDidEndResizing 
			object:[newColumn columnView]];
}

- (IBAction) removeColumn:(id)sender
{
	// remove the last column - retain while we're working with it
	
	NSRect frame = [self frame];
	IndexColumn *lastColumn = [[[self columns] lastObject] retain];
	
	// prepare the column to be removed
	[lastColumn setDelegate:nil];
	[lastColumn ownerWillClose:nil];
	
	// remove ourselves as an observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:lastColumn];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:IndexColumnViewWillBeginResizing object:lastColumn];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:IndexColumnViewDidEndResizing object:lastColumn];
	
	// nil the focused column if this was it
	if ( focusedColumn == lastColumn )
		focusedColumn = nil;
	
	// remove the column's view from our view
	[[lastColumn columnView] removeFromSuperview];
	
	// remove the column from our array
	NSMutableArray *newColumns = [[[self columns] mutableCopyWithZone:[self zone]] autorelease];
	[newColumns removeObject:lastColumn];
	[self setColumns:newColumns]; 
	
	// set our current frame to the new min width
	frame.size.width = [self minWidth];
	// reset our frame
	[self setFrame:frame];
	
	// redraw immediately
	[self display];
	
	// clean up and let the superview know we've reframed
	[lastColumn release];
	[[NSNotificationCenter defaultCenter] postNotificationName:NSViewFrameDidChangeNotification object:self];
}

#pragma mark -

// what if the search field is focused
- (IndexColumn*) focusedColumn
{
	if ( focusedColumn != nil )
		return focusedColumn;
	else return [[self columns] lastObject];
}

- (void) columnDidComeIntoFocus:(IndexColumn*)aColumn
{
	focusedColumn = aColumn;
}

- (NSArray*) focusedNodes
{
	NSResponder *theFirstResponder = [[self window] firstResponder];
	
	if ( [theFirstResponder isKindOfClass:[IndexOutlineView class]] )
	{
		IndexColumn *theColumn = [(IndexOutlineView*)theFirstResponder indexColumn];
		return [theColumn selectedObjects];
	}
	else
	{
		return nil;
	}
}

#pragma mark -
#pragma mark Building the Next Column after the Selection Changes

- (void) columnDidChangeSelection:(IndexColumn*)aColumn
{
	NSArray *newContent = nil;
	BOOL multipleSelection = NO;
	BOOL allowsDeletion = NO;
	
	// determine if a new column is needed
	unsigned columnCount = [[self columns] count];
	unsigned indexOfColumn = [[self columns] indexOfObjectIdenticalTo:aColumn];
	
	// ask the delegate for the content of the selection
	if ( [[self delegate] respondsToSelector:@selector(browser:contentForNodes:atColumnIndex:)] )
		newContent = [[self delegate] browser:self contentForNodes:[aColumn selectedObjects] atColumnIndex:indexOfColumn];
	else
		newContent = [NSArray array];	
	
	// add a column
	if ( indexOfColumn + 1 >= columnCount )
		[self addColumn:self];
	
	// or get rid of extraneous columns
	else if ( columnCount > indexOfColumn + 2 )
	{
		int i;
		for ( i = indexOfColumn + 2; i < columnCount; i++ )
			[self removeColumn:self];
	}
	
	// determine if it draws its icons
	if ( [[self delegate] respondsToSelector:@selector(browser:columnForNodeDrawsIcon:atColumnIndex:)] )
		[[[self columns] objectAtIndex:indexOfColumn+1] setDrawsIcon:
		[[self delegate] browser:self columnForNodeDrawsIcon:[aColumn selectedObject] atColumnIndex:indexOfColumn]];
	
	// determine if it draws its count
	if ( [[self delegate] respondsToSelector:@selector(browser:columnForNodeShowsCount:atColumnIndex:)] )
		[[[self columns] objectAtIndex:indexOfColumn+1] setShowsCount:
		[[self delegate] browser:self columnForNodeShowsCount:[aColumn selectedObject] atColumnIndex:indexOfColumn]];
	
	// determine if it draws its count
	if ( [[self delegate] respondsToSelector:@selector(browser:columnForNodeShowsFrequency:atColumnIndex:)] )
		[[[self columns] objectAtIndex:indexOfColumn+1] setShowsFrequency:
		[[self delegate] browser:self columnForNodeShowsFrequency:[aColumn selectedObject] atColumnIndex:indexOfColumn]];
	
	// determine if it filters the count
	if ( [[self delegate] respondsToSelector:@selector(browser:columnForNodeFiltersCount:atColumnIndex:)] )
		[[[self columns] objectAtIndex:indexOfColumn+1] setCanFilterCount:
		[[self delegate] browser:self columnForNodeFiltersCount:[aColumn selectedObject] atColumnIndex:indexOfColumn]];
	
	// does the column allow multiple selection
	if ( [[self delegate] respondsToSelector:@selector(browser:columnForNodeAllowsMultipleSelection:atColumnIndex:) ] )
	{
		multipleSelection = [[self delegate] browser:self 
			columnForNodeAllowsMultipleSelection:[aColumn selectedObject] atColumnIndex:indexOfColumn];
		[[[self columns] objectAtIndex:indexOfColumn+1] setAllowsMultipleSelection:multipleSelection];
	}
	
	// the row height
	if ( [[self delegate] respondsToSelector:@selector(browser:rowHeightForNode:atColumnIndex:)] )
		[[[self columns] objectAtIndex:indexOfColumn+1] 
		setRowHeight:[[self delegate] browser:self rowHeightForNode:[aColumn selectedObject] atColumnIndex:indexOfColumn]];
	
	// does the column allow row deletion
	if ( [[self delegate] respondsToSelector:@selector(browser:columnForNodeCanDeleteContent:atColumnIndex:) ] )
	{
		allowsDeletion = [[self delegate] browser:self 
			columnForNodeCanDeleteContent:[aColumn selectedObject] atColumnIndex:indexOfColumn];
		[[[self columns] objectAtIndex:indexOfColumn+1] setCanDeleteContent:allowsDeletion];
	}
	
	// set the context menu if that's allowed
	if ( [[self delegate] respondsToSelector:@selector(browser:contextMenuForNode:atColumnIndex:)] )
		[[[self columns] objectAtIndex:indexOfColumn+1] setMenu:
		[[self delegate] browser:self contextMenuForNode:[aColumn selectedObject] atColumnIndex:indexOfColumn]];
	
	// determine the title
	if ( [[self delegate] respondsToSelector:@selector(browser:titleForNode:atColumnIndex:)] )
	{
		NSString *delegateTitle = [[self delegate] browser:self 
				titleForNode:[aColumn selectedObject] atColumnIndex:indexOfColumn];
		
		if ( delegateTitle != nil )
			[(IndexColumn*)[[self columns] objectAtIndex:indexOfColumn+1] setTitle:delegateTitle];
		else
			[(IndexColumn*)[[self columns] objectAtIndex:indexOfColumn+1] setTitle:[[aColumn selectedObject] valueForKey:@"title"]];
	}
	
	// determine the header title
	if ( [[self delegate] respondsToSelector:@selector(browser:headerTitleForNode:atColumnIndex:)] )
	{
		NSString *delegateHeaderTitle = [[self delegate] browser:self headerTitleForNode:[aColumn selectedObject] atColumnIndex:indexOfColumn];
		
		if ( delegateHeaderTitle != nil )
			[(IndexColumn*)[[self columns] objectAtIndex:indexOfColumn+1] setHeaderTitle:delegateHeaderTitle];
	}
	
	// determine the count suffix
	if ( [[self delegate] respondsToSelector:@selector(browser:countSuffixForNode:atColumnIndex:)] )
	{
		NSString *delegateSuffix = [[self delegate] browser:self 
				countSuffixForNode:[aColumn selectedObject] atColumnIndex:indexOfColumn];
		
		if ( delegateSuffix != nil )
			[(IndexColumn*)[[self columns] objectAtIndex:indexOfColumn+1] setCountSuffix:delegateSuffix];
	}

	// set the sort descriptor

	// set or append the content of the column
	[[[self columns] objectAtIndex:indexOfColumn+1] setContent:newContent];
	
	// and finally, with everything taken care of, inform the delegate that the selection has changed
	if ( [[self delegate] respondsToSelector:@selector(browser:column:didChangeSelection:lastSelection:)] )
		[[self delegate] browser:self column:aColumn didChangeSelection:[aColumn selectedObjects] lastSelection:[aColumn selectedObject]];
}

#pragma mark -

- (void) columnFrameDidChange:(NSNotification*)aNotification
{
	// recalculate the minimum width
	float minWidth = [self minWidth];
	
	NSRect frame = [self frame];
	frame.size.width = minWidth;
	
	[self setFrame:frame];
	[self setNeedsDisplay:YES];
	
	// if the frame belongs to the last column, scroll with it
	IndexColumnView *objectView = [aNotification object];
	if ( [objectView indexColumn] == [[self columns] lastObject] )
	{
		[self scrollRectToVisible:[objectView frame]];
		[[self enclosingScrollView] reflectScrolledClipView:[[self enclosingScrollView] documentView]];
	}
}

- (void) columnWillResize:(NSNotification*)aNotification
{
	IndexColumn *theColumn = [(IndexColumnView*)[aNotification object] indexColumn];
	unsigned location = [[self columns] indexOfObjectIdenticalTo:theColumn];
	
	[[theColumn columnView] setAutoresizingMask:NSViewHeightSizable];
	
	if ( location == NSNotFound )
		return;
	else if ( location + 1 < [[self columns] count] )
	{
		int i;
		for ( i = location + 1; i < [[self columns] count]; i++ )
			[[[[self columns] objectAtIndex:i] columnView] setAutoresizingMask:NSViewHeightSizable|NSViewMinXMargin];
	}
}

- (void) columnDidResize:(NSNotification*)aNotification
{
	IndexColumn *aColumn;
	NSEnumerator *enumerator = [[self columns] objectEnumerator];
	
	while (aColumn = [enumerator nextObject] )
		[[aColumn columnView] setAutoresizingMask:NSViewHeightSizable|NSViewMaxXMargin];
}

#pragma mark -

- (void) outlineView:(IndexOutlineView*)anOutlineView leftKeyDown:(NSEvent*)anEvent
{
	IndexColumn *theColumn = [anOutlineView indexColumn];
	unsigned newColumnIndex, columnIndex = [[self columns] indexOfObjectIdenticalTo:theColumn];
	
	if ( columnIndex == 0 )
		newColumnIndex = [[self columns] count] - 1;
	else
		newColumnIndex = columnIndex - 1;
	
	IndexColumn *targetColumn = [[self columns] objectAtIndex:newColumnIndex];
	[targetColumn focusOutlineWithSelection:YES];
	
	// scroll so that the selected column is visible
	[self scrollRectToVisible:[[targetColumn columnView] frame]];
	[[self enclosingScrollView] reflectScrolledClipView:[[self enclosingScrollView] documentView]];
}

- (void) outlineView:(IndexOutlineView*)anOutlineView rightKeyDown:(NSEvent*)anEvent
{
	IndexColumn *theColumn = [anOutlineView indexColumn];
	unsigned columnIndex = [[self columns] indexOfObjectIdenticalTo:theColumn];
	unsigned newColumnIndex = columnIndex;
	
	if ( columnIndex == [[self columns] count] - 1 )
		newColumnIndex = 0;
	else
		newColumnIndex = columnIndex + 1;
	
	IndexColumn *targetColumn = [[self columns] objectAtIndex:newColumnIndex];
	[targetColumn focusOutlineWithSelection:YES];

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

- (BOOL) indexColumn:(IndexColumn*)aColumn deleteSelectedRows:(NSIndexSet*)selectedRows nodes:(NSArray*)theNodes
{
	if ( [[self delegate] respondsToSelector:@selector(indexColumn:deleteSelectedRows:nodes:)] )
		return [[self delegate] indexColumn:aColumn deleteSelectedRows:selectedRows nodes:theNodes];
	else
		return NO;
}

@end
