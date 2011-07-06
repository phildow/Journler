#import "EntriesTableView.h"

#import "JournlerEntry.h"
#import "JournlerJournal.h"

#import "PDTableHeaderCell.h"
#import "PDCornerView.h"

#import <SproutedUtilities/SproutedUtilities.h>

/*
#import "NSBezierPath_AMShading.h"
#import "NSBezierPath_AMAdditons.h"
#import "NSColor_JournlerAdditions.h"
*/

#import "CollectionsSourceList.h"
#import "DateSelectionController.h"
#import "Definitions.h"

#define kSearchIntervalDelay 1.5
#define kMinRowHeight 17
// 14

@implementation EntriesTableView

+ (void)initialize
{
	[self exposeBinding:@"stateArray"];
}

- (void) awakeFromNib 
{
	int i;
	NSArray *columns = [self tableColumns];
	//NSLog(@"%@",[columns valueForKey:@"identifier"]);
	
	// the all columns dictionary stores the columns for hiding/showing as needed
	allColumns = [[NSMutableDictionary alloc] initWithCapacity:[[self tableColumns] count]];
	
	for ( i = 0; i < [columns count]; i++ )
	{
		NSTableColumn *aColumn = [columns objectAtIndex:i];
		
		// retain the columns so the user can decided which ones are visible
		[allColumns setObject:aColumn forKey:[aColumn identifier]];
		
		//	-- custom header cell
		id objectValue = [[aColumn headerCell] objectValue];
		NSFont *font = [[aColumn headerCell] font];
		NSLineBreakMode lineBreak = NSLineBreakByTruncatingTail;
		NSTextAlignment alignment = [[aColumn headerCell] alignment];
		
		PDTableHeaderCell *headerCell = [[[PDTableHeaderCell alloc] init] autorelease];
		
		[headerCell setFont:font];
		[headerCell setAlignment:alignment];
		[headerCell setLineBreakMode:lineBreak];
		[headerCell setObjectValue:objectValue];
		
		[aColumn setHeaderCell:headerCell];
		// */
	}
	
	// remove the rank column
	//[self setColumnWithIdentifier:@"relevanceNumber" hidden:YES];
	//[self removeTableColumn:rankColumn];
	
	// prepare the tags column for its token field goodness
	NSTableColumn *tagsColumn = [self tableColumnWithIdentifier:@"tags"];
	PDTokenFieldCell *tokenCell = [[[PDTokenFieldCell alloc] init] autorelease];
	
	[tokenCell setFont:[NSFont controlContentFontOfSize:11]];
	[tokenCell setControlSize:NSSmallControlSize];
	[tokenCell setDelegate:[self delegate]];
	[tokenCell setBezeled:NO];
	[tokenCell setBordered:NO];
	
	[tagsColumn setDataCell:tokenCell];
	
	// place an image in a few of the header cells
	[[labelColumn headerCell] setImage:[NSImage imageNamed:@"headerlabel.png"]];
	[[bloggedColumn headerCell] setImage:[NSImage imageNamed:@"browseheaderblogged.tif"]];
	[[markColumn headerCell] setImage:[NSImage imageNamed:@"headerflagged.tif"]];
	[[attachmentColumn headerCell] setImage:[NSImage imageNamed:@"headerattachment.tiff"]];
	
	_shortcutRow = -1;
	_searchString = [[NSMutableString alloc] init];
	
	[self setCornerView:[[[PDCornerView alloc] initWithFrame:NSMakeRect(0,0,16,16)] autorelease]];
	
	// bind a couple of appearance attributes to user defaults
	[self bind:@"usesAlternatingRowBackgroundColors" 
			toObject:[NSUserDefaultsController sharedUserDefaultsController] 
			withKeyPath:@"values.BrowseTableAlternatingRows" 
			options:[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithBool:NO], NSNullPlaceholderBindingOption, nil]];
			
	[self bind:@"drawsLabelBackground" 
			toObject:[NSUserDefaultsController sharedUserDefaultsController] 
			withKeyPath:@"values.EntryTableNoLabelBackground" 
			options:[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithBool:NO], NSNullPlaceholderBindingOption, 
					NSNegateBooleanTransformerName, NSValueTransformerNameBindingOption, nil]];
	
	[self bind:@"font" 
			toObject:[NSUserDefaultsController sharedUserDefaultsController] 
			withKeyPath:@"values.BrowserTableFont" 
			options:[NSDictionary dictionaryWithObjectsAndKeys:
					@"NSUnarchiveFromData", NSValueTransformerNameBindingOption,
					[NSFont controlContentFontOfSize:11], NSNullPlaceholderBindingOption, nil]];
}

- (void)setNilValueForKey:(NSString *)key
{
	// called for nil values with scalars
	
	if ( [key isEqualToString:@"usesAlternatingRowBackgroundColors"] )
		[self setValue:[NSNumber numberWithBool:NO] forKey:@"usesAlternatingRowBackgroundColors"];
		
	else if ( [key isEqualToString:@"drawsLabelBackground"] )
		[self setValue:[NSNumber numberWithBool:NO] forKey:@"drawsLabelBackground"];
	
	else
		[super setNilValueForKey:key];
}

- (void) dealloc 
{	
	#ifdef __DEBUG__
	NSLog(@"%@ %s",[self className],_cmd);
	#endif
	
	[_searchString release];
	[allColumns release];
	
	[super dealloc];	
}

#pragma mark -

- (id) draggingObject 
{ 
	return _draggingObject; 
}

- (void) setDraggingObject:(id)object 
{	
	_draggingObject = object;	
}

- (id) draggingObjects 
{ 
	return _draggingObjects; 
}

- (void) setDraggingObjects:(id)objects 
{
	_draggingObjects = objects;
}

- (BOOL) drawsLabelBackground 
{ 
	return drawsLabelBackground; 
}

- (void) setDrawsLabelBackground:(BOOL)draws 
{	
	drawsLabelBackground = draws;
	[self setNeedsDisplay:YES];
	//[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:drawsLabelBackground]
	//		forKey:@"EntryTableNoLabelBackground"];
}

#pragma mark -

- (void)drawRow:(int)rowIndex clipRect:(NSRect)clipRect 
{
	// ask the data source for the entry's label
	NSNumber *labelColorVal = [[[[self dataSource] arrangedObjects] objectAtIndex:rowIndex] valueForKey:@"label"];
	
	// grab the draw rect
	NSRect targetRect = [self rectOfRow:rowIndex];
	
	// if this is the row being temporarily "selected" for an open shortcut
	if ( rowIndex == _shortcutRow && ![[self selectedRowIndexes] containsIndex:rowIndex] ) 
	{
		[[self highlightColorForOpenShorcut] set];
		
		targetRect.origin.x+=2.0;
		targetRect.size.width-=3.0;
		targetRect.size.height-=1.0;
		
		[self lockFocus];
		NSRectFill(targetRect);
		[self unlockFocus];
	}
	
	// if the label is around and this isn't the selected row
	else if ( [self drawsLabelBackground] && labelColorVal && 
			[labelColorVal intValue] != 0 && targetRect.size.width != 0 && [self selectedRow] != rowIndex )
	{
		NSColor *gradientStart = [NSColor colorForLabel:[labelColorVal intValue] gradientEnd:NO];
		NSColor *gradientEnd = [NSColor colorForLabel:[labelColorVal intValue] gradientEnd:YES];
				
		if ( gradientStart != nil && gradientEnd != nil )
		{
			targetRect.origin.x+=2.0;
			targetRect.size.width-=3.0;
			targetRect.size.height-=1.0;
			
			[self lockFocus];
			[[NSBezierPath bezierPathWithRoundedRect:targetRect cornerRadius:7.3] 
					linearGradientFillWithStartColor:gradientStart endColor:gradientEnd];
			[self unlockFocus];
		}
	}
	
	[super drawRow:rowIndex clipRect:clipRect];
	
	if ( [self editedRow] == rowIndex && [self editedColumn] != -1 ) 
	{
		[[NSColor blackColor] set];
		
		NSRect aFrame = [self frameOfCellAtColumn:[self editedColumn] row:rowIndex];
		aFrame.size.width-=1; // don't know why this is necessary
		
		[[NSBezierPath bezierPathWithRect:aFrame] stroke];
	}
}

- (id)_highlightColorForCell:(NSCell *)cell
{
	if(([[self window] firstResponder] == self) && [[self window] isMainWindow] && [[self window] isKeyWindow])
	{
		if ( [NSColor currentControlTint] == NSBlueControlTint )
			return [NSColor colorWithCalibratedRed:61.0/256.0 green:128.0/256.0 blue:223.0/256.0 alpha:1.0];
		else
			return [[[NSColor colorWithCalibratedRed:61.0/256.0 green:128.0/256.0 blue:223.0/256.0 alpha:1.0]
				blendedColorWithFraction:0.7 ofColor:[NSColor colorForControlTint:[NSColor currentControlTint]]]
				shadowWithLevel:0.1];
	}
	else if ( [self editedRow] != -1 && [self editedColumn] != -1 )
	{
		if ( [NSColor currentControlTint] == NSBlueControlTint )
			return [NSColor colorWithCalibratedRed:61.0/256.0 green:128.0/256.0 blue:223.0/256.0 alpha:1.0];
		else
			return [[[NSColor colorWithCalibratedRed:61.0/256.0 green:128.0/256.0 blue:223.0/256.0 alpha:1.0]
				blendedColorWithFraction:0.7 ofColor:[NSColor colorForControlTint:[NSColor currentControlTint]]]
				shadowWithLevel:0.1];
	}
	else
		return [NSColor secondarySelectedControlColor];
}

- (NSColor*) highlightColorForOpenShorcut 
{
	return [NSColor colorWithCalibratedRed:212.0/256.0 green:226.0/256.0 blue:244.0/256.0 alpha:1.0];
}

#pragma mark -

- (void)draggedImage:(NSImage *)anImage beganAt:(NSPoint)aPoint
{
	#ifdef __DEBUG__
	NSLog(@"%@ %s",[self className],_cmd);
	#endif
	
	[[NSNotificationCenter defaultCenter] postNotificationName:EntriesTableViewDidBeginDragNotification object:self userInfo:nil];
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation
{
	#ifdef __DEBUG__
	NSLog(@"%@ %s",[self className],_cmd);
	#endif
	
	[[NSNotificationCenter defaultCenter] postNotificationName:EntriesTableViewDidEndDragNotification object:self userInfo:nil];
}

- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
	
	if ( isLocal )
		return ( NSDragOperationDelete | NSDragOperationCopy );
	else
		return NSDragOperationCopy;
	
}

- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows 
		tableColumns:(NSArray *)tableColumns event:(NSEvent*)dragEvent offset:(NSPointPointer)dragImageOffset {
		
	//
	// We'll use the first icon the workspace manager returns
	// draw that guy into an image, along with the tracks name
	// I mean, let's be fancy about it!
	//
	
	//JournlerEntry *entry = [[[self dataSource] arrangedObjects] objectAtIndex:[[dragRows objectAtIndex:0] intValue]];
	JournlerEntry *entry = [[[self dataSource] arrangedObjects] objectAtIndex:[dragRows firstIndex]];
	if ( !entry )
		return nil;
	
	NSString *title = [entry title];
	if ( !title )
		return nil;
	
	NSImage *icon = [NSImage imageNamed:@"EntryDrag.tif"];
	NSImage *returnImage;
	NSImage *dragBadge = nil;
	
	//
	// if more than one row is being dragged, determine which dragBadge to use
	
	if ( [dragRows count] > 1 && [dragRows count] < 100 )
		dragBadge = [[[NSImage imageNamed:@"dragBadge1.png"] copyWithZone:[self zone]] autorelease];
	else if ( [dragRows count] >= 100 && [dragRows count] < 1000 )
		dragBadge = [[[NSImage imageNamed:@"dragBadge2.png"] copyWithZone:[self zone]] autorelease];
	else if ( [dragRows count] >= 1000 )
		dragBadge = [[[NSImage imageNamed:@"dragBadge3.png"] copyWithZone:[self zone]] autorelease];
	
	//
	// Get the size of this thing
	//
	
	if ( dragBadge ) {
		
		//
		// draw the count if necessary
		NSDictionary *countAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName,
				[NSColor colorWithCalibratedWhite:1.0 alpha:1.0], NSForegroundColorAttributeName, nil];
		
		NSString *countString = [[NSNumber numberWithInt:[dragRows count]] stringValue];
		NSSize countSize = [countString sizeWithAttributes:countAttributes];
		
		[dragBadge lockFocus];
		[countString drawInRect:NSMakeRect(	[dragBadge size].width/2 - countSize.width/2, 
											[dragBadge size].height/2 - countSize.height/2,
											countSize.width, countSize.height )
				withAttributes:countAttributes];
		[dragBadge unlockFocus];
		
	}
	
	NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	
	[shadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.96]];
	[shadow setShadowOffset:NSMakeSize(1,-1)];
	
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys: 
	[NSFont systemFontOfSize:11], NSFontAttributeName,
	[NSColor colorWithCalibratedWhite:0.01 alpha:1.0], NSForegroundColorAttributeName, 
	shadow, NSShadowAttributeName, nil];
	
	NSSize iconSize = [icon size];
	NSSize stringSize = [title sizeWithAttributes:attributes];
	
	returnImage = [[NSImage alloc] initWithSize:NSMakeSize(iconSize.width+stringSize.width+12, 
		(iconSize.height >= stringSize.height ? iconSize.height : stringSize.height) + 6)];
	
	[returnImage lockFocus];
	
	[[NSColor colorWithCalibratedWhite:0.25 alpha:0.3] set];
	[[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0,6,[returnImage size].width,[returnImage size].height-6) cornerRadius:10.0] fill];
	
	[[NSColor colorWithCalibratedWhite:0.5 alpha:0.3] set];
	[[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0,6,[returnImage size].width,[returnImage size].height-6) cornerRadius:10.0] stroke];
		
	[icon compositeToPoint:NSMakePoint(2,6) operation:NSCompositeSourceOver fraction:1.0];
	[title drawAtPoint:NSMakePoint(iconSize.width+7,8) withAttributes:attributes];
	
	if ( dragBadge ) 
	{
		[dragBadge compositeToPoint:NSMakePoint(iconSize.width+7-[dragBadge size].width, 0) operation:NSCompositeSourceOver fraction:1.0];
	}
	
	[returnImage unlockFocus];
	
	// and set our dragging object
	[self setDraggingObjects:dragRows];
		
	return [returnImage autorelease];

}

#pragma mark -

- (NSArray*) stateArray 
{
	
	// used to store and restore the state of the table without relying on preferences
	// returns an array of data objects describing the state of the table's columns:
	// a) identifier b) position c) width
	
	int i;
	NSArray *columns = [self tableColumns];
	
	[_stateArray release];
	_stateArray = [[NSMutableArray alloc] initWithCapacity:[columns count]];
	
	for ( i = 0; i < [columns count]; i++ ) 
	{
		NSTableColumn *aColumn = [columns objectAtIndex:i];
		
		NSString *identifier = [aColumn identifier];
		NSNumber *position = [NSNumber numberWithInt:i];
		NSNumber *width = [NSNumber numberWithFloat:[aColumn width]];
		
		NSDictionary *columnState = [NSDictionary dictionaryWithObjectsAndKeys:
				identifier, @"identifier", position, @"position", width, @"width", nil];
		
		[(NSMutableArray*)_stateArray addObject:columnState];
	}
	
	return _stateArray;
}

- (void) setStateArray:(NSArray*)anArray
{
	NSLog(@"%@ %s", [self className], _cmd);
	// only restore the state if there is data to be restored
	if ( anArray != nil && [anArray count] != 0 && anArray != _stateArray )
	{
		NSLog(@"%@ %s", [self className], _cmd);
		[self restoreStateWithArray:anArray];
		[_stateArray release];
		_stateArray = [anArray copyWithZone:[self zone]];
	}
}

- (void) restoreStateWithArray:(NSArray*)anArray 
{	
	// #warning buggy getting the right sizes down
	int i;
	
	// remove the columns that are not part of the restored estate
	//NSArray *myColumns = [self tableColumns];
	NSArray *myColumns = [allColumns allValues];
	// not sure why it's necessary to use the allcolumns dictionary here. [self tableColumns] doesn't return every column!
	
	for ( i = 0; i < [myColumns count]; i++ )
	{
		int j;
		BOOL found = NO;
		for ( j = 0; j < [anArray count]; j++ )
		{
			//NSLog(@"available: %@ - saved: %@", [[myColumns objectAtIndex:i] identifier], [[anArray objectAtIndex:j] valueForKey:@"identifier"]);
			if ( [[[myColumns objectAtIndex:i] identifier] isEqual:[[anArray objectAtIndex:j] valueForKey:@"identifier"]] )
				found = YES;
		}
		
		if ( !found )
			[self setColumnWithIdentifier:[[myColumns objectAtIndex:i] identifier] hidden:YES];
	}
	
	// restore the state
	for ( i = 0; i < [anArray count]; i++ ) 
	{
		NSDictionary *columnState = [anArray objectAtIndex:i];
		
		NSString *identifier = [columnState valueForKey:@"identifier"];
		int position = [[columnState valueForKey:@"position"] intValue];
		float width = [[columnState valueForKey:@"width"] floatValue];
		
		int existingPosition = [self columnWithIdentifier:identifier];
		NSTableColumn *existingColumn = [self tableColumnWithIdentifier:identifier];
		
		if ( existingPosition != -1 && existingColumn != nil ) 
		{
			// the table column is already part of the table, move and resize
			[self moveColumn:existingPosition toColumn:position];
			[existingColumn setWidth:width];
			
		}
		else 
		{
			NSLog(@"%@ %s - unable to restore table column with state %@", [self className], _cmd, columnState);
		}
	}
}

#pragma mark -

- (void) mouseDown:(NSEvent*)theEvent 
{	
	unsigned int mods = [theEvent modifierFlags];
	
	if ( (mods & NSCommandKeyMask) && (mods & NSShiftKeyMask) )
	{
		// open the entry in a new tab without selecting it here
		NSPoint window_point = [theEvent locationInWindow];
		NSPoint table_point = [self convertPoint:window_point fromView:nil];
		
		JournlerEntry *anEntry;
		unsigned int row_selection = [self rowAtPoint:table_point];
		
		if ( row_selection != -1 && ( anEntry = [[[self dataSource] arrangedObjects] objectAtIndex:row_selection] ) &&
				[[self delegate] respondsToSelector:@selector(openAnEntryInNewTab:)] )
		{
			_shortcutRow = row_selection;
			[self displayRect:[self rectOfRow:_shortcutRow]];
			
			// #warning doesn't seem to work with trashed entries
			[[self delegate] performSelector:@selector(openAnEntryInNewTab:) withObject:anEntry];

			[self setNeedsDisplayInRect:[self rectOfRow:_shortcutRow]];
			
			_shortcutRow = -1;
			
		}
	}
	
	else if ( (mods & NSCommandKeyMask) && (mods & NSAlternateKeyMask) )
	{
		// open the entry in a new window without selecting it here
		NSPoint window_point = [theEvent locationInWindow];
		NSPoint table_point = [self convertPoint:window_point fromView:nil];
		
		JournlerEntry *anEntry;
		unsigned int row_selection = [self rowAtPoint:table_point];
		
		if ( row_selection != -1 && ( anEntry = [[[self dataSource] arrangedObjects] objectAtIndex:row_selection] ) &&
				[[self delegate] respondsToSelector:@selector(openAnEntryInNewWindow:)] )
		{
			_shortcutRow = row_selection;
			[self displayRect:[self rectOfRow:_shortcutRow]];
			
			// #warning selects tab, which I don't really like
			[[self delegate] performSelector:@selector(openAnEntryInNewWindow:) withObject:anEntry];
			
			[self setNeedsDisplayInRect:[self rectOfRow:_shortcutRow]];
			_shortcutRow = -1;
		}
	}
	
	else
	{
		NSPoint window_point = [theEvent locationInWindow];
		NSPoint table_point = [self convertPoint:window_point fromView:nil];
		unsigned int row_selection = [self rowAtPoint:table_point];
		
		if ( [theEvent clickCount] == 1 && row_selection == [self selectedRow] 
				&& [[self delegate] respondsToSelector:@selector(tableView:didSelectRowAlreadySelected:event:)] )
		{
			if ( ![[self delegate] tableView:self didSelectRowAlreadySelected:row_selection event:theEvent] )
				// pass the event on
				[super mouseDown:theEvent];
		}
		else
			// pass the event on
			[super mouseDown:theEvent];
	}
}

- (void)keyDown:(NSEvent *)event 
{ 
	static unichar kUnicharKeyReturn = '\r';
	static unichar kUnicharKeyNewline = '\n';
	
	unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];
	
	if (key == NSDeleteCharacter && [self numberOfRows] > 0 && [self selectedRow] != -1) { 
       
		// request a delete from the delegate
		if ( [[self delegate] respondsToSelector:@selector(deleteSelectedEntries:)] )
			[[self delegate] performSelector:@selector(deleteSelectedEntries:) withObject:self];
		
    }
	
	//else if ( key == NSLeftArrowFunctionKey ) {
	//	[[self window] makeFirstResponder: [[[self dataSource] sourceController] sourceList] ];
	//}
	
	else if ( key == kUnicharKeyReturn || key == kUnicharKeyNewline ) 
	{
		if ( ( [event modifierFlags] & NSShiftKeyMask ) && [[self delegate] respondsToSelector:@selector(openEntryInNewTab:)] )
			[[self delegate] performSelector:@selector(openEntryInNewTab:) withObject:self];
			
		else if ( [event modifierFlags] & NSAlternateKeyMask && [[self delegate] respondsToSelector:@selector(openEntryInNewFloatingWindow:)] )
			[[self delegate] performSelector:@selector(openEntryInNewFloatingWindow:) withObject:self];
		
		else if ( [[self delegate] respondsToSelector:@selector(openEntryInNewWindow:)] && [[self delegate] respondsToSelector:@selector(openEntryInNewWindow:)] )
			[[self delegate] performSelector:@selector(openEntryInNewWindow:) withObject:self];
			
		else
			NSBeep();
	}
	
	else 
	{ 
		// perform a title based search
		NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
		
		if ( currentTime - _searchInterval > kSearchIntervalDelay )
			[_searchString setString:@""];
		
		_searchInterval = currentTime;
		NSString *new_characters = [event characters];
		
		if ( new_characters && [new_characters length] > 0 ) 
		{
			unichar a_char = [new_characters characterAtIndex:0];
			if ( a_char >= 0xF700 && a_char <= 0xF8FF )
			{
				[super keyDown:event];
			}
			else 
			{
				int i;
				NSArray *objects = [[self dataSource] arrangedObjects];
				[_searchString appendString:new_characters];
				
				for ( i = 0; i < [objects count]; i++ ) 
				{
					if ( [[[objects objectAtIndex:i] valueForKey:@"title"] 
							rangeOfString:_searchString options:NSCaseInsensitiveSearch].location == 0 ) 
					{
						[self scrollRowToVisible:i];
						[self selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
						break;
					}
				}
			}
		}
		else
		{
			[super keyDown:event];
		}
    }
}

#pragma mark -

- (BOOL) editingCategory 
{ 
	return _editingCategory; 
}

- (void)editColumn:(int)columnIndex row:(int)rowIndex withEvent:(NSEvent *)theEvent select:(BOOL)flag {
	
	NSString *identifier = [[[self tableColumns] objectAtIndex:columnIndex] identifier];
	//id formatter = [[[[self tableColumns] objectAtIndex:columnIndex] dataCell] formatter];
	
	if ( columnIndex != -1 && [identifier isEqualToString:@"category"] )
		_editingCategory = YES;
	else
		_editingCategory = NO;
	
	if ( [identifier isEqualToString:@"calDate"] || [identifier isEqualToString:@"calDateDue"] )
	{
		JournlerEntry *anEntry = [[[self dataSource] arrangedObjects] objectAtIndex:rowIndex];
		
		DateSelectionController *dateSelector = [[[DateSelectionController alloc] 
				initWithDate:[anEntry valueForKey:identifier] key:identifier] autorelease];
				
		[dateSelector setRepresentedObject:anEntry];
		[dateSelector setDelegate:self];
		[dateSelector setClearDateHidden:[identifier isEqualToString:@"calDate"]];
		
		NSRect cell_frame = [self frameOfCellAtColumn:columnIndex row:rowIndex];
		NSRect base_frame = [self convertRect:cell_frame toView:nil];
		
		[dateSelector runAsSheetForWindow:[self window] attached:[[self window] isMainWindow] location:base_frame];	
	}
	else
	{
		[super editColumn:columnIndex row:rowIndex withEvent:theEvent select:flag];
	}
}

#pragma mark -
#pragma mark DateSelection Delegation

- (void) dateSelectorDidCancelDateSelection:(DateSelectionController*)aDateSelector
{

}

- (void) dateSelector:(DateSelectionController*)aDateSelector didClearDateForKey:(NSString*)aKey
{
	JournlerEntry *anEntry = [aDateSelector representedObject];
	[anEntry setValue:nil forKey:aKey];
}

- (void) dateSelector:(DateSelectionController*)aDateSelector didSaveDate:(NSDate*)aDate key:(NSString*)aKey
{
	JournlerEntry *anEntry = [aDateSelector representedObject];
	[anEntry setValue:[aDate dateWithCalendarFormat:nil timeZone:nil] forKey:aKey];
}

/*
- (void)textDidChange:(NSNotification *)aNotification 
{
	[[self window] setDocumentEdited:YES];
	[super textDidChange:aNotification];
}
*/

- (void) textDidEndEditing: (NSNotification *) notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSNumber *textMovement = [userInfo objectForKey: @"NSTextMovement"];
	
    int movementCode = [textMovement intValue];
	_editingCategory = NO;

    // see if this a 'pressed-return' instance
    if (movementCode == NSReturnTextMovement) 
	{
        // hijack the notification and pass a different textMovement
        // value

        textMovement = [NSNumber numberWithInt: NSIllegalTextMovement];
        NSDictionary *newUserInfo = [NSDictionary dictionaryWithObject: textMovement forKey: @"NSTextMovement"];
        notification = [NSNotification notificationWithName: [notification name] object: [notification object] userInfo: newUserInfo];
		
		[super textDidEndEditing: notification];
		[[self window] makeFirstResponder:self];
    }
	
	else if ( movementCode == -99 )
	{
		[self abortEditing];
		
		// We lose focus so re-establish
		[[self window] makeFirstResponder:self];
	}
	
	else 
	{
		// if its not the return, ie the tab instead, the change should be made only after the call to super
		[super textDidEndEditing: notification];
	}
}

#pragma mark -

- (IBAction) toggleUsesAlternatingRows:(id)sender {
	
	[self setUsesAlternatingRowBackgroundColors:![self usesAlternatingRowBackgroundColors]];
	[self setNeedsDisplay:YES];
	//[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[self usesAlternatingRowBackgroundColors]]
	//		forKey:@"BrowseTableAlternatingRows"];
	
}

- (IBAction) toggleDrawsLabelBackground:(id)sender 
{
	[self setDrawsLabelBackground:![self drawsLabelBackground]];
}

#pragma mark -

- (void) setColumnWithIdentifier:(id)identifier hidden:(BOOL)hide {
	
	NSTableColumn *aColumn = [allColumns objectForKey:identifier];
	if ( aColumn == nil )
		return;
		
	if ( hide && [self tableColumnWithIdentifier:identifier] != nil )
		[self removeTableColumn:aColumn];
	else if ( !hide && [self tableColumnWithIdentifier:identifier] == nil )
		[self addTableColumn:aColumn];
	
	//[self sizeToFit];
}

- (BOOL) columnWithIdentifierIsHidden:(id)identifier
{
	return ( [self tableColumnWithIdentifier:identifier] == nil );
}

- (BOOL)validateMenuItem:(NSMenuItem *)item 
{	
	BOOL enabled = YES;
	SEL action = [item action];
	
	if ( [item tag] == 51 ) 
	{
		BOOL alternate = ([self usesAlternatingRowBackgroundColors]?YES:NO);
		[item setState:alternate];
	}
	else if ( action == @selector(copy:) )
		enabled = ( [self selectedRow] != -1 );
	
	return enabled;
}

#pragma mark -

- (IBAction) copy:(id)sender
{
	[[self dataSource] tableView:self 
			writeRowsWithIndexes:[self selectedRowIndexes] 
			toPasteboard:[NSPasteboard generalPasteboard]];
}

- (IBAction) sizeToFit:(id)sender
{
	[self sizeToFit];
}

- (BOOL)becomeFirstResponder
{
	NSMenuItem *copyItem = [[[[NSApp mainMenu] itemWithTag:2] submenu] itemWithTag:99];
	[copyItem setTitle:NSLocalizedString(@"entry link menu item",@"")];
	
	return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
	NSMenuItem *copyItem = [[[[NSApp mainMenu] itemWithTag:2] submenu] itemWithTag:99];
	[copyItem setTitle:NSLocalizedString(@"copy menu item",@"")];
	
	return [super resignFirstResponder];
}

#pragma mark -

- (void)setFont:(NSFont *)fontObject
{
	// overridden to pass the message onto the individual cells and change the row height
	float wouldBeRowHeight = [[[[NSLayoutManager alloc] init] autorelease] defaultLineHeightForFont:fontObject];
	if ( wouldBeRowHeight < kMinRowHeight ) wouldBeRowHeight = kMinRowHeight;
	else wouldBeRowHeight+=(floor(wouldBeRowHeight/4));
	
	[[self valueForKeyPath:@"tableColumns.dataCell"] setValue:fontObject forKey:@"font"];
	[self setRowHeight:wouldBeRowHeight];
	[self setNeedsDisplay:YES];
}

@end
