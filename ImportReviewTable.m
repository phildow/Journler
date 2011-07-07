//
//  ImportReviewTable.m
//  Journler
//
//  Created by Philip Dow on 1/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ImportReviewTable.h"

#import <SproutedUtilities/SproutedUtilities.h>
/*
#import "NSBezierPath_AMShading.h"
#import "NSBezierPath_AMAdditons.h"
#import "NSColor_JournlerAdditions.h"
*/

#import "JournlerEntry.h"
#import "DateSelectionController.h"

@implementation ImportReviewTable

- (void) dealloc
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	[super dealloc];
}

- (BOOL) editingCategory
{
	return _editingCategory;
}

- (void)keyDown:(NSEvent *)event 
{ 
	//static unichar kUnicharKeyReturn = '\r';
	//static unichar kUnicharKeyNewline = '\n';
	
	unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];
	
	if (key == NSDeleteCharacter && [self numberOfRows] > 0 && [self selectedRow] != -1) 
	{ 
		// request a delete from the delegate
		if ( [[self delegate] respondsToSelector:@selector(importReviewTable:deleteEntries:)] )
			[[self delegate] importReviewTable:self deleteEntries:nil];
    }
	else
	{
		[super keyDown:event];
	}
}

- (void)editColumn:(int)columnIndex row:(int)rowIndex withEvent:(NSEvent *)theEvent select:(BOOL)flag {
	
	NSString *identifier = [[[self tableColumns] objectAtIndex:columnIndex] identifier];
	
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

- (void)drawRow:(int)rowIndex clipRect:(NSRect)clipRect 
{
	// ask the data source for the entry's label
	NSNumber *labelColorVal = [[[[self dataSource] arrangedObjects] objectAtIndex:rowIndex] valueForKey:@"label"];
	
	// grab the draw rect
	NSRect targetRect = [self rectOfRow:rowIndex];
	
	// if the label is around and this isn't the selected row
	if ( [labelColorVal intValue] != 0 && targetRect.size.width != 0 && [self selectedRow] != rowIndex )
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

@end
