//
//  ResourceTableView.m
//  Journler
//
//  Created by Philip Dow on 10/26/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import "ResourceTableView.h"
#import "Definitions.h"

#import "JournlerResource.h"
#import "ResourceNode.h"
#import "ResourceController.h"

#import "PDTableHeaderCell.h"
#import "PDCornerView.h"

#import <SproutedUtilities/SproutedUtilities.h>

#define kMinRowHeight 40
#define kSearchIntervalDelay 1.5

@implementation ResourceTableView

- (void) awakeFromNib
{
	NSInteger i;
	NSArray *columns = [self tableColumns];
	
	for ( i = 0; i < [columns count]; i++ )
	{
		NSTableColumn *aColumn = [columns objectAtIndex:i];
		
		// retain the columns so the user can decided which ones are visible
		[aColumn retain];
		
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
	
	[self setIntercellSpacing:NSMakeSize(0.0,0.0)];
	[self setCornerView:[[[PDCornerView alloc] initWithFrame:NSMakeRect(0,0,16,16)] autorelease]];
	
	_shortcutRow = -1;
	_searchString = [[NSMutableString alloc] init];
	
	[self setAutoresizesOutlineColumn:NO];
	
	// appearance bindings
	[self bind:@"font" toObject:[NSUserDefaultsController sharedUserDefaultsController] 
			withKeyPath:@"values.ReferencesTableFont" options:[NSDictionary dictionaryWithObjectsAndKeys:
			@"NSUnarchiveFromData", NSValueTransformerNameBindingOption,
			[NSFont controlContentFontOfSize:11], NSNullPlaceholderBindingOption, nil]];
			
	[self registerForDraggedTypes:[NSArray arrayWithObjects:
			kABPeopleUIDsPboardType, NSFilenamesPboardType, WebURLsWithTitlesPboardType, NSURLPboardType,
			NSRTFDPboardType, NSRTFPboardType, NSStringPboardType, NSTIFFPboardType, NSPICTPboardType,
			PDEntryIDPboardType, PDResourceIDPboardType, PDFolderIDPboardType, 
			kMailMessagePboardType, kiLifeIntegrationPboardType, nil]];

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

#pragma mark -

- (NSTableColumn*) titleColumn
{
	return titleColumn;
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

#pragma mark -
#pragma mark Dragging

- (NSUInteger)draggingSourceOperationMaskForLocal:(BOOL)isLocal 
{
	if ( isLocal )
		return ( NSDragOperationLink );
	else
		return ( NSDragOperationCopy | NSDragOperationLink );
}

- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows tableColumns:(NSArray *)tableColumns 
		event:(NSEvent*)dragEvent offset:(NSPointPointer)dragImageOffset
{
	//JournlerResource *aReference = [[[self delegate] arrangedObjects] objectAtIndex:[dragRows firstIndex]];
	JournlerResource *aReference = [[self originalItemAtRow:[dragRows firstIndex]] resource];
	if ( aReference == nil )
		return nil;
	
	NSString *title = [aReference valueForKey:@"title"];
	if ( title == nil )
		return nil;
	
	NSImage *icon = [[aReference valueForKey:@"icon"] imageWithWidth:32 height:32 inset:0];
	
	NSImage *returnImage;
	NSImage *dragBadge = nil;
	
	// if more than one row is being dragged, determine which dragBadge to use
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
		
		NSString *countString = [[NSNumber numberWithInteger:[dragRows count]] stringValue];
		NSSize countSize = [countString sizeWithAttributes:countAttributes];
		
		[dragBadge lockFocus];
		[countString drawInRect:NSMakeRect(	[dragBadge size].width/2 - countSize.width/2, 
											[dragBadge size].height/2 - countSize.height/2,
											countSize.width, countSize.height ) withAttributes:countAttributes];
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
	
	float myWidth = [self bounds].size.width;
	float proposedWidth = iconSize.width+stringSize.width+20;
	
	returnImage = [[NSImage alloc] initWithSize:NSMakeSize( ( myWidth > proposedWidth ? myWidth : proposedWidth ) , 
		(iconSize.height >= stringSize.height ? iconSize.height : stringSize.height) + 6)];

	
	[returnImage lockFocus];
	
	[[NSColor colorWithCalibratedWhite:0.25 alpha:0.3] set];
	//NSRectFill(NSMakeRect(0,6,[returnImage size].width,[returnImage size].height-6));
	[[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0,6,[returnImage size].width,[returnImage size].height-6) cornerRadius:10.0] fill];
	
	[[NSColor colorWithCalibratedWhite:0.5 alpha:0.3] set];
	//NSFrameRect(NSMakeRect(0,6,[returnImage size].width,[returnImage size].height-6));
	[[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0,6,[returnImage size].width,[returnImage size].height-6) cornerRadius:10.0] stroke];	
	[[icon imageWithWidth:26 height:26] compositeToPoint:NSMakePoint(6,8) operation:NSCompositeSourceOver fraction:1.0];
	[title drawAtPoint:NSMakePoint(iconSize.width+7,8) withAttributes:attributes];
	
	if ( dragBadge ) 
	{
		[dragBadge compositeToPoint:NSMakePoint(iconSize.width+7-[dragBadge size].width, 0) operation:NSCompositeSourceOver fraction:1.0];
	}
	
	[returnImage unlockFocus];
	return [returnImage autorelease];
}

#pragma mark -

- (void) mouseDown:(NSEvent*)theEvent 
{	
	NSUInteger mods = [theEvent modifierFlags];
	
	if ( (mods & NSCommandKeyMask) && (mods & NSShiftKeyMask) )
	{
		// open resource in new tab
		NSPoint window_point = [theEvent locationInWindow];
		NSPoint table_point = [self convertPoint:window_point fromView:nil];
		
		JournlerResource *aResource;
		NSInteger row_selection = [self rowAtPoint:table_point];
		
		if ( row_selection != -1 && ( aResource = [[self itemAtRow:row_selection] resource] ) && 
				[[self delegate] respondsToSelector:@selector(openAResourceInNewTab:)] )
		{
			_shortcutRow = row_selection;
			[self displayRect:[self rectOfRow:_shortcutRow]];
			
			[[self delegate] performSelector:@selector(openAResourceInNewTab:) withObject:aResource];
			
			_shortcutRow = -1;
			[self setNeedsDisplayInRect:[self rectOfRow:_shortcutRow]];
		}
	}
	else if ( (mods & NSCommandKeyMask) && (mods & NSAlternateKeyMask) )
	{
		// open resource in new window
		NSPoint window_point = [theEvent locationInWindow];
		NSPoint table_point = [self convertPoint:window_point fromView:nil];
		
		JournlerResource *aResource;
		NSInteger row_selection = [self rowAtPoint:table_point];
		
		if ( row_selection != -1 && ( aResource = [[self itemAtRow:row_selection] resource] ) && 
				[[self delegate] respondsToSelector:@selector(openAResourceInNewWindow:)] )
		{
			_shortcutRow = row_selection;
			[self displayRect:[self rectOfRow:_shortcutRow]];
			
			[[self delegate] performSelector:@selector(openAResourceInNewWindow:) withObject:aResource];
			
			[self setNeedsDisplayInRect:[self rectOfRow:_shortcutRow]];
			_shortcutRow = -1;
		}
	}
	else if ( (mods & NSAlternateKeyMask) )
	{
		// open resource in default application
		NSPoint window_point = [theEvent locationInWindow];
		NSPoint table_point = [self convertPoint:window_point fromView:nil];
		
		JournlerResource *aResource;
		NSInteger row_selection = [self rowAtPoint:table_point];
		
		if ( row_selection != -1 && ( aResource = [[self itemAtRow:row_selection] resource] ) && 
				[[self delegate] respondsToSelector:@selector(openAResourceWithFinder:)] )
		{
			_shortcutRow = row_selection;
			[self displayRect:[self rectOfRow:_shortcutRow]];
			
			[[self delegate] performSelector:@selector(openAResourceWithFinder:) withObject:aResource];
			
			[self setNeedsDisplayInRect:[self rectOfRow:_shortcutRow]];
			_shortcutRow = -1;
		}
	}
	else
	{
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
		if ( [[self delegate] respondsToSelector:@selector(deleteSelectedResources:)] )
			[[self delegate] performSelector:@selector(deleteSelectedResources:) withObject:self];
		
    }
	
	//else if ( key == NSLeftArrowFunctionKey ) {
	//	[[self window] makeFirstResponder: [[[self dataSource] sourceController] sourceList] ];
	//}
	
	else if ( key == kUnicharKeyReturn || key == kUnicharKeyNewline ) 
	{
		//#warning auto-selects new tab
		if ( ( [event modifierFlags] & NSShiftKeyMask ) && [[self delegate] respondsToSelector:@selector(openResourceInNewTab:)] )
			[[self delegate] performSelector:@selector(openResourceInNewTab:) withObject:self];
		
		else if (( [event modifierFlags] & NSAlternateKeyMask  && [[self delegate] respondsToSelector:@selector(openResourceInNewFloatingWindow:)]) ) 
			[[self delegate] performSelector:@selector(openResourceInNewFloatingWindow:) withObject:self];
		
		else if ( [[self delegate] respondsToSelector:@selector(openResourceInNewWindow:)]  && [[self delegate] respondsToSelector:@selector(openResourceInNewWindow:)])
			[[self delegate] performSelector:@selector(openResourceInNewWindow:) withObject:self];
			
		else
			NSBeep();
	}
	
	else 
	{ 
		/*
		// #warning doesn't seem to work
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
				NSInteger i;
				NSArray *objects = ( [[self dataSource] respondsToSelector:@selector(resourceNodes)] ? [[self dataSource] resourceNodes] : [[self dataSource] arrangedObjects] );
				[_searchString appendString:new_characters];
				
				//NSLog(@"%s - search string is %@, object count is %i", __PRETTY_FUNCTION__, _searchString, [objects count]);
				
				for ( i = 0; i < [objects count]; i++ ) 
				{
					ResourceNode *aNode = [objects objectAtIndex:i];
					
					if ( [[aNode valueForKey:@"label"] boolValue] == NO 
							&& [[aNode valueForKeyPath:@"resource.title"] rangeOfString:_searchString options:NSCaseInsensitiveSearch].location == 0 ) 
					{
						NSLog(@"%s - object %i title %@", __PRETTY_FUNCTION__, i, [aNode valueForKeyPath:@"resource.title"] );
						
						//NSInteger targetRow = [self rowForItem:[objects objectAtIndex:i]];
						NSInteger targetRow = i;
						if ( targetRow != 1 )
						{
							[self scrollRowToVisible:targetRow];
							[self selectRowIndexes:[NSIndexSet indexSetWithIndex:targetRow] byExtendingSelection:NO];
						}
						break;
					}
				}
			}
		}
		else
		{
			[super keyDown:event];
		}
		*/
		
		[super keyDown:event];
    }
}

#pragma mark -

- (void)drawRow:(NSInteger)rowIndex clipRect:(NSRect)clipRect {
	
	JournlerResource *aResource;
	id anObject = [self itemAtRow:rowIndex];
	
	if ( [anObject respondsToSelector:@selector(resource)] )
		aResource = [anObject resource];
	else
		aResource = anObject;
	
	// ask the data source for the entry's label
	NSNumber *labelColorVal = [aResource valueForKey:@"label"];
	
	// grab the draw rect
	NSRect targetRect = [self rectOfRow:rowIndex];
	
	// if this is the row being temporarily "selected" for an open shortcut
	if ( rowIndex == _shortcutRow ) 
	{
		[[self highlightColorForOpenShorcut] set];
		
		targetRect.origin.x+=2.0;
		targetRect.size.width-=3.0;
		targetRect.size.height-=1.0;
		
		[self lockFocus];
		NSRectFill(targetRect);
		[self unlockFocus];
	}
	
	else if ( [[self selectedRowIndexes] containsIndex:rowIndex] )
	{
		NSRect gradientRect = targetRect;
		gradientRect.size.height--;
		
		[self _drawSelectionInRect:gradientRect 
				highlight: (([[self window] firstResponder] == self) && [[self window] isMainWindow] && [[self window] isKeyWindow]) ];

	}
	
	else if ( labelColorVal && [labelColorVal integerValue] != 0 )
	{
		NSColor *gradientStart = [NSColor colorForLabel:[labelColorVal integerValue] gradientEnd:NO];
		NSColor *gradientEnd = [NSColor colorForLabel:[labelColorVal integerValue] gradientEnd:YES];
				
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


#pragma mark -

- (id)_highlightColorForCell:(NSCell *)cell
{
	return [self backgroundColor];
	//return [NSColor colorWithCalibratedRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0];
	
	//if(([[self window] firstResponder] == self) && [[self window] isMainWindow] && [[self window] isKeyWindow])
	//	return [NSColor colorWithCalibratedRed:61.0/256.0 green:128.0/256.0 blue:223.0/256.0 alpha:1.0];
	//else
	//	return [NSColor secondarySelectedControlColor];
}

- (NSColor*) highlightColorForOpenShorcut 
{
	return [NSColor colorWithCalibratedRed:212.0/256.0 green:226.0/256.0 blue:244.0/256.0 alpha:1.0];
}


#pragma mark -

- (IBAction) copy:(id)sender
{
	[[self dataSource] outlineView:self writeItems:[self allSelectedItems] toPasteboard:[NSPasteboard generalPasteboard]];
}

- (BOOL)becomeFirstResponder
{
	NSMenuItem *copyItem = [[[[NSApp mainMenu] itemWithTag:2] submenu] itemWithTag:99];
	[copyItem setTitle:NSLocalizedString(@"resource link menu item",@"")];
	
	return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
	NSMenuItem *copyItem = [[[[NSApp mainMenu] itemWithTag:2] submenu] itemWithTag:99];
	[copyItem setTitle:NSLocalizedString(@"copy menu item",@"")];
	
	return [super resignFirstResponder];
}


@end
