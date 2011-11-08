//
//  ImportReviewTable.m
//  Journler
//
//  Created by Philip Dow on 1/2/07.
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

- (void)editColumn:(NSInteger)columnIndex row:(NSInteger)rowIndex withEvent:(NSEvent *)theEvent select:(BOOL)flag {
	
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

- (void)drawRow:(NSInteger)rowIndex clipRect:(NSRect)clipRect 
{
	// ask the data source for the entry's label
	NSNumber *labelColorVal = [[[[self dataSource] arrangedObjects] objectAtIndex:rowIndex] valueForKey:@"label"];
	
	// grab the draw rect
	NSRect targetRect = [self rectOfRow:rowIndex];
	
	// if the label is around and this isn't the selected row
	if ( [labelColorVal integerValue] != 0 && targetRect.size.width != 0 && [self selectedRow] != rowIndex )
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
