#import "CollectionsSourceList.h"
#import "Definitions.h"

#import "JournlerCollection.h"

#import "FoldersController.h"
//#import "BrowseArrayController.h"
#import "EntriesTableView.h"

#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>

/*
#import "NSOutlineView_Extensions.h"
#import "NSOutlineView_ProxyAdditions.h"
#import "NSBezierPath_AMShading.h"
#import "NSBezierPath_AMAdditons.h"
#import "NSImage_PDCategories.h"
#import "NSColor_JournlerAdditions.h"
#import "NSUserDefaults+PDDefaultsAdditions.h"
#import "JournlerGradientView.h"

static NSString *kMailMessagePboardType = @"MV Super-secret message transfer pasteboard type";
*/

#define kSearchIntervalDelay 1.5

@implementation CollectionsSourceList

- (void) awakeFromNib {

	[self setIntercellSpacing:NSMakeSize(0.0,0.0)];
			
	_searchString = [[NSMutableString alloc] init];
	
	[self setAutoresizesOutlineColumn:NO];
	
	// appearance bindings
	[self bind:@"font" toObject:[NSUserDefaultsController sharedUserDefaultsController] 
			withKeyPath:@"values.FoldersTableFont" options:[NSDictionary dictionaryWithObjectsAndKeys:
			@"NSUnarchiveFromData", NSValueTransformerNameBindingOption,
			[NSFont controlContentFontOfSize:11], NSNullPlaceholderBindingOption, nil]];
			
	[self bind:@"backgroundColor" toObject:[NSUserDefaultsController sharedUserDefaultsController] 
			withKeyPath:@"values.FolderBackgroundColor" options:[NSDictionary dictionaryWithObjectsAndKeys:
			@"NSUnarchiveFromData", NSValueTransformerNameBindingOption,
			[NSColor colorWithCalibratedHue:234.0/400.0 saturation:1.0/100.0 brightness:97.0/100.0 alpha:1.0], NSNullPlaceholderBindingOption, nil]];
	
	// drag types
	NSArray *draggedTypes = [NSArray arrayWithObjects: PDFolderIDPboardType, PDEntryIDPboardType, 
			NSFilenamesPboardType, WebURLsWithTitlesPboardType, NSURLPboardType, NSRTFDPboardType, NSRTFPboardType, 
			NSStringPboardType, NSTIFFPboardType, NSPICTPboardType, kMailMessagePboardType, nil];
			
	[self registerForDraggedTypes:draggedTypes];
	
	[self setDraggingSourceOperationMask:NSDragOperationCopy|NSDragOperationMove forLocal:YES];
	[self setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
}

- (void) dealloc
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	[self unregisterDraggedTypes];
	
	[_searchString release];
	
	[super dealloc];
}

- (void)keyDown:(NSEvent *)event 
{ 
	static unichar kUnicharKeyReturn = '\r';
	static unichar kUnicharKeyNewline = '\n';
	
	unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];
  
	if (key == NSDeleteCharacter && [self numberOfRows] > 0 && [self selectedRow] != -1) 
	{ 
		// request a delete from the delegate
		if ( [[self delegate] respondsToSelector:@selector(deleteSelectedFolder:)] )
			[[self delegate] performSelector:@selector(deleteSelectedFolder:) withObject:self];
		
    }
	
	//#warning - what about opening into a new tab (but not new window)
	else if ( ( key == kUnicharKeyReturn || key == kUnicharKeyNewline ) && ( [event modifierFlags] & NSControlKeyMask ) ) 
		[super keyDown:event];

	
	//else if ( key == NSRightArrowFunctionKey ) 
	//{
	//	[[self window] makeFirstResponder: [[[self dataSource] browseController] entriesTable] ];
	//}
	
	// perform a search
	else 
	{ 
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
				NSInteger i;
				NSArray *objects = [[self dataSource] allObjects];
				[_searchString appendString:new_characters];
				
				for ( i = 0; i < [objects count]; i++ ) 
				{
					if ( [[[objects objectAtIndex:i] valueForKey:@"title"] 
							rangeOfString:_searchString options:NSCaseInsensitiveSearch].location == 0 ) 
					{
						[[self dataSource] selectCollection:[objects objectAtIndex:i] byExtendingSelection:NO];
						[self scrollRowToVisible:i];
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

- (void) textDidEndEditing: (NSNotification *) notification
{
    NSDictionary *userInfo;
    userInfo = [notification userInfo];

    NSNumber *textMovement;
    textMovement = [userInfo objectForKey: @"NSTextMovement"];

    NSInteger movementCode;
    movementCode = [textMovement intValue];

    // see if this a 'pressed-return' instance

    if (movementCode == NSReturnTextMovement) {
        // hijack the notification and pass a different textMovement
        // value

        textMovement = [NSNumber numberWithInt: NSIllegalTextMovement];

        NSDictionary *newUserInfo;
        newUserInfo = [NSDictionary dictionaryWithObject: textMovement
                                    forKey: @"NSTextMovement"];

        notification = [NSNotification notificationWithName:
                                           [notification name]
                                       object: [notification object]
                                       userInfo: newUserInfo];
    }

    [super textDidEndEditing: notification];

} // textDidEndEditing


-(void)_drawDropHighlightOnRow:(int)rowIndex
{
	
	static float widthOffset = 5.0;
	static float heightOffset = 3.0;
	
	[self lockFocus];
	
	NSRect drawRect = [self rectOfRow:rowIndex];
	
	drawRect.size.width -= widthOffset;
	drawRect.origin.x += widthOffset/2.0;

	drawRect.size.height -= heightOffset;
	drawRect.origin.y += heightOffset/2.0;
	
	//[[[NSColor blueColor]colorWithAlphaComponent:0.2]set];
	[[NSColor colorWithCalibratedRed:31.0/255.0 green:100.0/255.0 blue:205.0/255.0 alpha:0.2] set];
	[NSBezierPath fillRoundRectInRect:drawRect radius:4.0];

	//[[[NSColor blueColor]colorWithAlphaComponent:0.8]set];
	[[NSColor colorWithCalibratedRed:0.0/255.0 green:64.0/255.0 blue:188.0/255.0 alpha:0.96] set];
	[NSBezierPath setDefaultLineWidth:2.0];
	[NSBezierPath strokeRoundRectInRect:drawRect radius:4.0];

	[self unlockFocus];
}


- (id)_highlightColorForCell:(NSCell *)cell
{
	return [self backgroundColor];
	//return [NSColor colorWithCalibratedRed:210.0/255.0 green:216.0/255.0 blue:225.0/255.0 alpha:1.0];
	
	//if(([[self window] firstResponder] == self) && [[self window] isMainWindow] && [[self window] isKeyWindow])
	//	return [NSColor colorWithCalibratedRed:61.0/256.0 green:128.0/256.0 blue:223.0/256.0 alpha:1.0];
	//else
	//	return [NSColor secondarySelectedControlColor];
}


- (void)drawRow:(int)rowIndex clipRect:(NSRect)clipRect {
	
	JournlerCollection *actualItem;
	id anObject = [self itemAtRow:rowIndex];
	
	// 10.4 hack, 10.5 compatible
	if ( [anObject respondsToSelector:@selector(representedObject)] )
		actualItem = [anObject representedObject];
	else if ( [anObject respondsToSelector:@selector(observedObject)] )
		actualItem = [anObject observedObject];
	else
		actualItem = anObject;
	
	// ask the data source for the entry's label
	NSNumber *labelColorVal = [actualItem valueForKey:@"label"];
	
	// grab the draw rect
	NSRect targetRect = [self rectOfRow:rowIndex];
	
	if ( [[self selectedRowIndexes] containsIndex:rowIndex] )
	{
		NSRect gradientRect = targetRect;
		gradientRect.size.height--;
		
		[self _drawSelectionInRect:gradientRect 
				highlight: (([[self window] firstResponder] == self) && [[self window] isMainWindow] && [[self window] isKeyWindow]) ];
		
	}
	
	else if ( labelColorVal && [labelColorVal intValue] != 0 )
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
}

- (void) _drawSelectionInRect:(NSRect)aRect highlight:(BOOL)highlight
{
	//[JournlerGradientView drawGradientInView:self rect:aRect highlight:highlight];
	
	NSColor *gradientStart, *gradientEnd;
	
	if ( highlight ) 
	{
		gradientStart = [[NSColor colorWithCalibratedRed:136.0/255.0 green:165.0/255.0 blue:212.0/255.0 alpha:1.0]
			blendedColorWithFraction:0.5 ofColor:[NSColor colorForControlTint:[NSColor currentControlTint]]];
			
		
		gradientEnd = [[NSColor colorWithCalibratedRed:102.0/255.0 green:133.0/255.0 blue:183.0/255.0 alpha:1.0]
			blendedColorWithFraction:0.5 ofColor:[NSColor colorForControlTint:[NSColor currentControlTint]]];
			
	} 
	else 
	{
		gradientStart = [[NSColor colorWithCalibratedRed:172.0/255.0 green:186.0/255.0 blue:207.0/255.0 alpha:0.9]
			blendedColorWithFraction:0.5 ofColor:[NSColor colorForControlTint:[NSColor currentControlTint]]];
			
			
		gradientEnd = [[NSColor colorWithCalibratedRed:152.0/255.0 green:170.0/255.0 blue:196.0/255.0 alpha:0.9]
			blendedColorWithFraction:0.5 ofColor:[NSColor colorForControlTint:[NSColor currentControlTint]]];
		
	}
	
	[[NSBezierPath bezierPathWithRect:aRect] linearGradientFillWithStartColor:gradientStart endColor:gradientEnd];

}

/*
- (void) mouseDown:(NSEvent*)theEvent 
{
	NSPoint window_point = [theEvent locationInWindow];
	NSPoint table_point = [self convertPoint:window_point fromView:nil];
	NSUInteger row_selection = [self rowAtPoint:table_point];
	
	if ( [theEvent clickCount] == 1 && row_selection == [self selectedRow] 
			&& [[self delegate] respondsToSelector:@selector(sourceList:didSelectRowAlreadySelected:event:)] )
	{
		if ( ![[self delegate] sourceList:self didSelectRowAlreadySelected:row_selection event:theEvent] )
			// pass the event on
			[super mouseDown:theEvent];
	}
	else
	{
		// pass the event on
		[super mouseDown:theEvent];
	}
}
*/

#pragma mark -
#pragma mark State Information

- (NSArray*) stateArray
{
	NSMutableArray *state_array = [[[NSMutableArray alloc] initWithCapacity:[self numberOfRows]] autorelease];
	
	NSInteger i;
	for ( i = 0; i < [self numberOfRows]; i++ )
		[state_array addObject:[NSNumber numberWithBool:[self isItemExpanded:[self itemAtRow:i]]]];
	
	return state_array;
}

- (void) restoreStateFromArray:(NSArray*)anArray
{
	if ( anArray == nil )
		return;
		
	NSInteger i;
	for ( i = 0; i < [anArray count]; i++ ) 
	{
		if ( [[anArray objectAtIndex:i] boolValue] && i < [self numberOfRows] )
			[self expandItem:[self itemAtRow:i] expandChildren:NO];
	}
}

#pragma mark -

/*
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	NSLog(@"%s",__PRETTY_FUNCTION__);
	return [sender draggingSourceOperationMask];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	NSLog(@"%s",__PRETTY_FUNCTION__);
}
*/

#pragma mark -

//- (NSUInteger)draggingSourceOperationMaskForLocal:(BOOL)isLocal
//{
//	NSUInteger mask;
//	mask = ( isLocal ? NSDragOperationCopy | NSDragOperationMove : NSDragOperationCopy );
//	return mask;
//}

- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows 
		tableColumns:(NSArray *)tableColumns 
		event:(NSEvent*)dragEvent 
		offset:(NSPointPointer)dragImageOffset 
{
	
	JournlerCollection *collection = [self originalItemAtRow:[dragRows firstIndex]];
	
	if ( !collection ) return [super dragImageForRowsWithIndexes:dragRows 
			tableColumns:tableColumns event:dragEvent offset:dragImageOffset];
	
	NSString *title = [collection valueForKey:@"title"];
	if ( !title ) 
		return [super dragImageForRowsWithIndexes:dragRows tableColumns:tableColumns event:dragEvent offset:dragImageOffset];
	
	NSImage *icon = [[collection valueForKey:@"icon"] imageWithWidth:32 height:32 inset:0];
	if ( !icon ) 
		return [super dragImageForRowsWithIndexes:dragRows tableColumns:tableColumns event:dragEvent offset:dragImageOffset];
	
	// if more than one row is being dragged, determine which dragBadge to use
	NSImage *dragBadge = nil;
	if ( [dragRows count] > 1 && [dragRows count] < 100 )
		dragBadge = [[[NSImage imageNamed:@"dragBadge1.png"] copyWithZone:[self zone]] autorelease];
	else if ( [dragRows count] >= 100 && [dragRows count] < 1000 )
		dragBadge = [[[NSImage imageNamed:@"dragBadge2.png"] copyWithZone:[self zone]] autorelease];
	else if ( [dragRows count] >= 1000 )
		dragBadge = [[[NSImage imageNamed:@"dragBadge3.png"] copyWithZone:[self zone]] autorelease];
	
	// Get the size of this thing
	if ( dragBadge ) 
	{
		// draw the count if necessary
		NSDictionary *countAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName,
				[NSColor colorWithCalibratedWhite:1.0 alpha:1.0], NSForegroundColorAttributeName, nil];
		
		NSString *countString = [[NSNumber numberWithInt:[dragRows count]] stringValue];
		NSSize countSize = [countString sizeWithAttributes:countAttributes];
		
		[dragBadge lockFocus];
		[countString drawInRect:NSMakeRect(	[dragBadge size].width/2 - countSize.width/2, 
											[dragBadge size].height/2 - countSize.height/2,
											countSize.width, countSize.height ) withAttributes:countAttributes];
		[dragBadge unlockFocus];
	}
	
	NSImage *returnImage;
	
	NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	
	[shadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.96]];
	[shadow setShadowOffset:NSMakeSize(1,-1)];
	
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys: 
	[NSFont systemFontOfSize:11], NSFontAttributeName,
	[NSColor colorWithCalibratedWhite:0.01 alpha:1.0], NSForegroundColorAttributeName, 
	shadow, NSShadowAttributeName, nil];
	
	NSSize iconSize = [icon size];
	NSSize stringSize = [title sizeWithAttributes:attributes];
	
	float myWidth = [self bounds].size.width;
	float proposedWidth = iconSize.width+stringSize.width+20;
	
	returnImage = [[NSImage alloc] initWithSize:NSMakeSize( ( myWidth > proposedWidth ? myWidth : proposedWidth ) , 
		(iconSize.height >= stringSize.height ? iconSize.height : stringSize.height) + 6)];
	
	
	
	[returnImage lockFocus];
	
	//NSGraphicsContext *graphicsContext = [NSGraphicsContext currentContext];
	//[graphicsContext saveGraphicsState];
	
	//[shadow set];
	
	[[NSColor colorWithCalibratedWhite:0.25 alpha:0.3] set];
	//NSRectFill(NSMakeRect(0,6,[returnImage size].width,[returnImage size].height-6));
	[[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0,6,[returnImage size].width,[returnImage size].height-6) cornerRadius:10.0] fill];
	
	[[NSColor colorWithCalibratedWhite:0.5 alpha:0.3] set];
	//NSFrameRect(NSMakeRect(0,6,[returnImage size].width,[returnImage size].height-6));
	[[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0,6,[returnImage size].width,[returnImage size].height-6) cornerRadius:10.0] stroke];
	
	//[graphicsContext restoreGraphicsState];
	
	[icon compositeToPoint:NSMakePoint(6,6) operation:NSCompositeSourceOver fraction:1.0];
	[title drawAtPoint:NSMakePoint(iconSize.width+7,8) withAttributes:attributes];
	
	if ( dragBadge ) 
	{
		[dragBadge compositeToPoint:NSMakePoint(iconSize.width+7-[dragBadge size].width, 0) operation:NSCompositeSourceOver fraction:1.0];
	}
	
	[returnImage unlockFocus];
		
	return [returnImage autorelease];
}


#pragma mark -

- (IBAction) copy:(id)sender
{
	[[self dataSource] outlineView:self writeItems:[self allSelectedItems] toPasteboard:[NSPasteboard generalPasteboard]];
}

- (BOOL)becomeFirstResponder
{
	NSMenuItem *copyItem = [[[[NSApp mainMenu] itemWithTag:2] submenu] itemWithTag:99];
	[copyItem setTitle:NSLocalizedString(@"folder link menu item",@"")];
	
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
	float lineHeight = [[[[NSLayoutManager alloc] init] autorelease] defaultLineHeightForFont:fontObject];
	
	[[self valueForKeyPath:@"tableColumns.dataCell"] setValue:fontObject forKey:@"font"];
	[self setRowHeight:lineHeight];
	
	if ( [[self delegate] respondsToSelector:@selector(adjustRowHeightsFromFontSize:) ] )
		[[self delegate] adjustRowHeightsFromFontSize:lineHeight];
	
	[self setNeedsDisplay:YES];
}

- (IBAction) changeColor:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setColor:[sender color] forKey:@"FolderBackgroundColor"];
}
@end
