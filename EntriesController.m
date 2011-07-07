//
//  EntriesController.m
//  Journler
//
//  Created by Philip Dow on 10/24/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import "EntriesController.h"
#import "Definitions.h"

#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>


#import "JournlerEntry.h"
#import "JournlerJournal.h"
#import "EntriesTableView.h"


@implementation EntriesController

+ (void)initialize
{
	[self exposeBinding:@"stateArray"];
}

- (void) awakeFromNib
{
	[[NSNotificationCenter defaultCenter] addObserver:self 
			selector:@selector(journlerObjectValueDidChange:) 
			name:JournlerObjectDidChangeValueForKeyNotification 
			object:nil];
	
	//[self resetAllRowHeights];
}

- (void) dealloc
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
			name:JournlerObjectDidChangeValueForKeyNotification 
			object:nil];
			
	[super dealloc];
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

- (NSArray*) stateArray
{
	NSLog(@"%s",__PRETTY_FUNCTION__);
	return nil;
}

- (void) setStateArray:(NSArray*)anArray
{
	NSLog(@"%s - %@",__PRETTY_FUNCTION__, anArray);
}

#pragma mark -

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

- (void) journlerObjectValueDidChange:(NSNotification*)aNotification
{
	JournlerObject *theObject = [aNotification object];
	if ( [theObject isKindOfClass:[JournlerEntry class]] 
		&& [[[aNotification userInfo] objectForKey:JournlerObjectAttributeKey] isEqualToString:JournlerObjectAttributeLabelKey] )
	{
		int theRow = [[self arrangedObjects] indexOfObjectIdenticalTo:theObject];
		if ( theRow != -1 )
			[entriesTable setNeedsDisplayInRect:[entriesTable rectOfRow:theRow]];
	}
}

#pragma mark -
#pragma mark NSTableView Dummy Data Source

- (int)numberOfRowsInTableView:(NSTableView *)aTableView 
{
	return 0;
}

- (id)tableView:(NSTableView *)aTableView 
		objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex 
{
	return nil;
}


#pragma mark -
#pragma mark NSTableView Delegate

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell 
		rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(int)row mouseLocation:(NSPoint)mouseLocation 
{
	NSString *tooltip = nil;
	JournlerEntry *anEntry = [[self arrangedObjects] objectAtIndex:row];
	
	BOOL tipDiscovered = NO;
	int columnIndex = [aTableView columnAtPoint:mouseLocation];
	NSArray *tableColumns = [aTableView tableColumns];
	
	if ( columnIndex != -1 && columnIndex < [tableColumns count] )
	{
		if ( [[[tableColumns objectAtIndex:columnIndex] identifier] isEqualToString:@"numberOfResources"] )
		{
			NSArray *resourceTitles = [anEntry valueForKeyPath:@"resources.title"];
			if ( [resourceTitles count] != 0  )
			{
				int i;
				NSMutableString *resourcesTip = [NSMutableString string];
				for ( i = 0; i < [resourceTitles count]; i++ )
				{
					[resourcesTip appendString:[NSString stringWithFormat:@"%i. %@", i+1, [resourceTitles objectAtIndex:i]]];
					if ( i != [resourceTitles count] - 1 )
						[resourcesTip appendString:@"\n"];
				}
				
				tooltip = resourcesTip;
				
				//tooltip = [resourceTitles componentsJoinedByString:@"\n"];
				if ( [tooltip length] != 0 )
					tipDiscovered = YES;
				else
					tooltip = nil;
			}
		}
		
		else if ( [[[tableColumns objectAtIndex:columnIndex] identifier] isEqualToString:@"blogged"] )
		{
			NSArray *blogTitles = [anEntry valueForKeyPath:@"blogs.blogJournal"];
			if ( [blogTitles count] != 0 )
			{
				tooltip = [blogTitles componentsJoinedByString:@"\n"];
				if ( [tooltip length] != 0 )
					tipDiscovered = YES;
				else
					tooltip = nil;
			}
		}
		
		else if ( [[[tableColumns objectAtIndex:columnIndex] identifier] isEqualToString:@"calDate"] )
		{
			tipDiscovered = YES;
			tooltip = [[anEntry valueForKey:@"calDate"] descriptionAsDifferenceBetweenDate:[NSDate date]];
		}
		
		else if ( [[[tableColumns objectAtIndex:columnIndex] identifier] isEqualToString:@"calDateModified"] )
		{
			tipDiscovered = YES;
			tooltip = [[anEntry valueForKey:@"calDateModified"] descriptionAsDifferenceBetweenDate:[NSDate date]];
		}
		
		else if ( [[[tableColumns objectAtIndex:columnIndex] identifier] isEqualToString:@"calDateDue"] )
		{
			tipDiscovered = YES;
			tooltip = [[anEntry valueForKey:@"calDateDue"] descriptionAsDifferenceBetweenDate:[NSDate date]];
		}
		
		else if ( [[[tableColumns objectAtIndex:columnIndex] identifier] isEqualToString:@"keywords"] )
		{
			tipDiscovered = YES;
			tooltip = [anEntry valueForKey:@"keywords"];
		}
		
		else if ( [[[tableColumns objectAtIndex:columnIndex] identifier] isEqualToString:@"tags"] )
		{
			NSArray *tags = [anEntry valueForKey:@"tags"];
			
			if ( [tags count] != 0 )
			{
				tooltip = [tags componentsJoinedByString:@"\n"];
				if ( [tooltip length] != 0 )
					tipDiscovered = YES;
				else
					tooltip = nil;
			}
		}
	}
	
	if ( !tipDiscovered )
	{
		// if the tooltip hasn't been set yet, fall back on default behavior
		NSString *plainContent = [[anEntry valueForKey:@"attributedContent"] string];
		
		if ( plainContent == nil )
			return [anEntry valueForKey:@"title"];
		
		SKSummaryRef summaryRef = SKSummaryCreateWithString((CFStringRef)plainContent);
		
		if ( summaryRef == NULL )
			return [anEntry valueForKey:@"title"];
		
		NSString *summary = [(NSString*)SKSummaryCopySentenceSummaryString(summaryRef,1) autorelease];
		if ( summary == nil )
			return [anEntry valueForKey:@"title"];
		else
			tooltip = summary;
	}
	
	return tooltip;
}

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView
{
	#ifdef __DEBUG__
	NSLog(@"%s", __PRETTY_FUNCTION__ );
	#endif
	
	// this method must return immediately or the table is left in an inconsisten state
	// the delegate method should take care of its business on another thread or call a method after a delay, returning immediately
	
	if ( delegate != nil && [delegate respondsToSelector:@selector(entryController:willChangeSelection:)] )
		[delegate entryController:self willChangeSelection:[self selectedObjects]];
		
	return YES;
}

- (BOOL) tableView:(EntriesTableView*)aTableView 
		didSelectRowAlreadySelected:(int)aRow 
		event:(NSEvent*)mouseEvent
{
	if ( [[self delegate] respondsToSelector:@selector(entryController:tableDidSelectRowAlreadySelected:event:)] )
		return [[self delegate] entryController:self 
				tableDidSelectRowAlreadySelected:aRow 
				event:mouseEvent];
	else
		return NO;
}

/*
#pragma mark -

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	CGFloat naturalHeight = [tableView rowHeight];
	CGFloat rowHeight = naturalHeight;
	
	NSTableColumn *tagsColumn = [tableView tableColumnWithIdentifier:@"tags"];
	
	if ( tagsColumn != nil )
	{
		NSCell *theCell = [[tagsColumn dataCellForRow:row] copyWithZone:[self zone]];
		[theCell setObjectValue:[[[self arrangedObjects] objectAtIndex:row] valueForKey:@"tags"]];
		
		CGFloat tableWidth = [tagsColumn width];
		NSRect constrainedRect = NSMakeRect(0,0,tableWidth,10000);
		NSSize cellSize = [theCell cellSizeForBounds:constrainedRect];
		
		NSInteger multiplier = ceil(cellSize.height / naturalHeight);
		rowHeight = naturalHeight * multiplier;
		
		[theCell release];
	}
	
	return rowHeight;
}

- (void)tableViewColumnDidResize:(NSNotification *)aNotification
{
	[self resetAllRowHeights];
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn: (NSTableColumn *)tableColumn
{
	[self resetAllRowHeights];
}

- (void) resetAllRowHeights
{
	NSInteger row;
	NSInteger rowCount = [entriesTable numberOfRows];
	for (row=0; row< rowCount; row++) {
		[entriesTable noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:row]];
	}
	
	// [entriesTable noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [entriesTable numberOfRows])]];
}
*/

#pragma mark -
#pragma mark Navigation Events

- (void) tableView:(NSTableView*)aTableView leftNavigationEvent:(NSEvent*)anEvent
{
	if ( [[self delegate] respondsToSelector:@selector(tableView:leftNavigationEvent:)] )
		[[self delegate] tableView:aTableView leftNavigationEvent:anEvent];
}

- (void) tableView:(NSTableView*)aTableView rightNavigationEvent:(NSEvent*)anEvent
{
	if ( [[self delegate] respondsToSelector:@selector(tableView:rightNavigationEvent:)] )
		[[self delegate] tableView:aTableView rightNavigationEvent:anEvent];
}

	
#pragma mark -
#pragma mark Dragging Source

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard 
{
	
	NSArray *entries = [[self arrangedObjects] objectsAtIndexes:rowIndexes];
	
	int i;
	NSMutableArray *entryURIs = [NSMutableArray array];
	NSMutableArray *entryTitles = [NSMutableArray array];
	NSMutableArray *entryPromises = [NSMutableArray array];
	
	for ( i = 0; i < [entries count]; i++ ) 
	{
		JournlerEntry *anEntry = [entries objectAtIndex:i];
		
		[entryURIs addObject:[[anEntry URIRepresentation] absoluteString]];
		[entryTitles addObject:[anEntry valueForKey:@"title"]];
		[entryPromises addObject:(NSString*)kUTTypeFolder];
	}
	
	// prepare the favorites data
	NSDictionary *favoritesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
			[[entries objectAtIndex:0] valueForKey:@"title"], PDFavoriteName, 
			[[[entries objectAtIndex:0] URIRepresentation] absoluteString], PDFavoriteID, nil];
	
	// prepare the web urls
	NSArray *web_urls_array = [NSArray arrayWithObjects:entryURIs,entryTitles,nil];
	
	// declare the types
	NSArray *pboardTypes = 	[NSArray arrayWithObjects: PDEntryIDPboardType, NSFilesPromisePboardType, 
			PDFavoritePboardType, WebURLsWithTitlesPboardType, NSURLPboardType, NSStringPboardType, nil];
	[pboard declareTypes:pboardTypes owner:self];
	
	[pboard setPropertyList:entryURIs forType:PDEntryIDPboardType];
	[pboard setPropertyList:entryPromises forType:NSFilesPromisePboardType];
	[pboard setPropertyList:favoritesDictionary forType:PDFavoritePboardType];
	[pboard setPropertyList:web_urls_array forType:WebURLsWithTitlesPboardType];
	
	// write the url for the first item to the pasteboard, as a url and as a string
	[[[entries objectAtIndex:0] URIRepresentation] writeToPasteboard:pboard];
	[pboard setString:[[entries objectAtIndex:0] URIRepresentationAsString] forType:NSStringPboardType];
	
	return YES;
}

- (NSArray *)tableView:(NSTableView *)aTableView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination 
		forDraggedRowsWithIndexes:(NSIndexSet *)indexSet 
{
	
	if ( ![dropDestination isFileURL] ) 
		return nil;
	
	int i;
	NSMutableArray *titles = [[NSMutableArray alloc] init];
	NSArray *entries = [[self arrangedObjects] objectsAtIndexes:indexSet];
	NSString *destinationPath = [dropDestination path];
	
	int flags = kEntrySetLabelColor;
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryExportIncludeHeader"] )
		flags |= kEntryIncludeHeader;
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryExportSetCreationDate"] )
		flags |= kEntrySetFileCreationDate;
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryExportSetModificationDate"] )
		flags |= kEntrySetFileModificationDate;

	for ( i = 0; i < [entries count]; i++ ) 
	{
		JournlerEntry *anEntry = [entries objectAtIndex:i];
		//NSString *filePath = [NSString stringWithFormat:@"%@ %@", [anEntry tagID], [anEntry pathSafeTitle]];
		//[anEntry writeToFile:[destinationPath stringByAppendingPathComponent:filePath] as:kEntrySaveAsRTFD flags:flags];
		//[titles addObject:filePath];
		NSString *completePath = [[destinationPath stringByAppendingPathComponent:[anEntry pathSafeTitle]] pathWithoutOverwritingSelf];
		[anEntry writeToFile:completePath as:kEntrySaveAsRTFD flags:flags];
		[titles addObject:completePath];
	}
	
	[titles release];
	return [NSArray array];
}

#pragma mark -
#pragma mark NSTokenFieldCell Delegation

- (BOOL)tokenFieldCell:(NSTokenFieldCell *)tokenFieldCell hasMenuForRepresentedObject:(id)representedObject
{
	//NSLog(@"%s",__PRETTY_FUNCTION__);
	return YES;
}

- (NSMenu *)tokenFieldCell:(NSTokenFieldCell *)tokenFieldCell menuForRepresentedObject:(id)representedObject
{
	//NSLog(@"%s",__PRETTY_FUNCTION__);
	
	NSMenu *theMenu = nil;
	
	NSArray *results;
	JournlerJournal *journal = [[self delegate] journal];
	representedObject = ( [representedObject isKindOfClass:[NSString class]] ? [representedObject lowercaseString] : representedObject );
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%@ in tags.lowercaseString AND markedForTrash == NO", representedObject];
		
	NSSortDescriptor *titleSort = [[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES 
	selector:@selector(localizedCaseInsensitiveCompare:)] autorelease];
	
	results = [[[journal entries] filteredArrayUsingPredicate:predicate] sortedArrayUsingDescriptors:[NSArray arrayWithObject:titleSort]];
	
	if ( [results count] > 0 )
	{
		theMenu = [[[NSMenu alloc] initWithTitle:[NSString string]] autorelease];
        NSSize size = NSMakeSize(0,0);

        for ( JournlerEntry *anEntry in results )
		{
			NSMenuItem *anItem = [anEntry menuItemRepresentation:size];
			if ( anItem != nil )
			{
				[anItem setTarget:[self delegate]];
				[anItem setAction:@selector(selectEntryFromTokenMenu:)];
				
				[theMenu addItem:anItem];
			}
		}
	}
	else
	{
		NSLog(@"%s - filter returned no objects", __PRETTY_FUNCTION__);
	}
	
	return theMenu;
}

- (NSArray *)tokenFieldCell:(NSTokenFieldCell *)tokenFieldCell completionsForSubstring:(NSString *)substring 
indexOfToken:(int)tokenIndex indexOfSelectedItem:(int)selectedIndex
{
	//NSLog(@"%s",__PRETTY_FUNCTION__);
	
	NSArray *tagsArray = [[[[self delegate] journal] entryTags] allObjects];
	//NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self beginswith[cd] %@", substring];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self beginswith %@", substring];
	NSArray *completions = [tagsArray filteredArrayUsingPredicate:predicate];
	return completions;
}

- (NSArray *)tokenFieldCell:(NSTokenFieldCell *)tokenFieldCell shouldAddObjects:(NSArray *)tokens atIndex:(unsigned)index
{
	//NSLog(@"%s - %@",__PRETTY_FUNCTION__,tokens);
	
	NSMutableArray *modifiedArray = [NSMutableArray array];

    for ( NSString *aString in tokens )
	{
		if ( ![aString isOnlyWhitespace] )
			//[modifiedArray addObject:[aString lowercaseString]];
			[modifiedArray addObject:aString];
	}
	
	return modifiedArray;

}

- (void)tokenFieldCell:(PDTokenFieldCell *)tokenFieldCell didReadTokens:(NSArray*)theTokens fromPasteboard:(NSPasteboard *)pboard
{
	//NSLog(@"%s - %@", __PRETTY_FUNCTION__, theTokens);
	[[self selectedObjects] makeObjectsPerformSelector:@selector(setTags:) withObject:theTokens];
}

#pragma mark -

- (IBAction) deleteSelectedEntries:(id)sender
{
	if ( [[self delegate] respondsToSelector:@selector(deleteSelectedEntries:)] )
		[[self delegate] performSelector:@selector(deleteSelectedEntries:) withObject:sender];
}

#pragma mark -

- (IBAction) openEntryInNewTab:(id)sender
{
	if ( [[self delegate] respondsToSelector:@selector(openEntryInNewTab:)] )
		[[self delegate] performSelector:@selector(openEntryInNewTab:) withObject:sender];
}

- (IBAction) openEntryInNewWindow:(id)sender
{
	if ( [[self delegate] respondsToSelector:@selector(openEntryInNewWindow:)] )
		[[self delegate] performSelector:@selector(openEntryInNewWindow:) withObject:sender];
}

- (IBAction) openEntryInNewFloatingWindow:(id)sender
{
	if ( [[self delegate] respondsToSelector:@selector(openEntryInNewFloatingWindow:)] )
		[[self delegate] performSelector:@selector(openEntryInNewFloatingWindow:) withObject:sender];
}

#pragma mark -

- (void) openAnEntryInNewWindow:(JournlerEntry*)anEntry
{
	if ( [[self delegate] respondsToSelector:@selector(openAnEntryInNewWindow:)] )
		[[self delegate] performSelector:@selector(openAnEntryInNewWindow:) withObject:anEntry];
}

- (void) openAnEntryInNewTab:(JournlerEntry*)anEntry
{
	if ( [[self delegate] respondsToSelector:@selector(openAnEntryInNewTab:)] )
		[[self delegate] performSelector:@selector(openAnEntryInNewTab:) withObject:anEntry];
}

#pragma mark -
#pragma mark Menu Validation

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	BOOL enabled = YES;
	int tag = [menuItem tag];
	SEL action = [menuItem action];
	unsigned selectionCount = [[self selectedObjects] count];
	
	enabled = ( selectionCount != 0 );
	
	if ( action == @selector( newEntry: ) )
		enabled = YES;
		
	else if ( action == @selector( runFileImporter:) )
		enabled = YES;
	
	else if ( action == @selector(editEntryProperty:) )
	{
		if ( enabled )
		{
			NSArray *markedArray = [self valueForKeyPath:@"selectedObjects.marked"];
			BOOL areTheSame = [markedArray allObjectsAreEqual];
			
			if ( tag == 331 ) // flagged
			{
				if ( !areTheSame )
				{
					if ( [markedArray containsObject:[NSNumber numberWithInt:1]] )
						[menuItem setState:NSMixedState];
					else
						[menuItem setState:NSOffState];
				}
				else
				{
					if ( [markedArray containsObject:[NSNumber numberWithInt:1]] )
						[menuItem setState:NSOnState];
					else
						[menuItem setState:NSOffState];
				}
			}
			else if ( tag == 334 ) // checked
			{
				if ( !areTheSame )
				{
					if ( [markedArray containsObject:[NSNumber numberWithInt:2]] )
						[menuItem setState:NSMixedState];
					else
						[menuItem setState:NSOffState];
				}
				else
				{
					if ( [markedArray containsObject:[NSNumber numberWithInt:2]] )
						[menuItem setState:NSOnState];
					else
						[menuItem setState:NSOffState];
				}
			}
		}

	}
	
	return enabled;
}

@end
