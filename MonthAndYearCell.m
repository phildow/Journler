//
//  MonthAndYearCell.m
//  Journler XD Lite
//
//  Created by Philip Dow on 9/19/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import "MonthAndYearCell.h"


@implementation MonthAndYearCell

- (id) init {
	
	self = [self initTextCell:[NSString string]];
	return self;
}

- (id) initTextCell:(NSString*)aString {
	if ( self = [super initTextCell:aString] ) {
		
		NSArray *monthNames = [[NSUserDefaults standardUserDefaults] objectForKey:NSMonthNameArray];
		if ( [monthNames count] == 12 )
			[self setMonths:monthNames];
		else
			[self setMonths:[MonthAndYearCell englishMonths]];
		
		selectedYear = [[NSCalendarDate calendarDate] yearOfCommonEra];
		selectedMonth = [[NSCalendarDate calendarDate] monthOfYear] - 1;
		
		[self setFont:[NSFont boldSystemFontOfSize:11.0]];
		[self setTextColor:[NSColor blackColor]];
		[self setAlignment:NSCenterTextAlignment];
		[self setEnabled:YES];
		[self setEditable:YES];
		
	}
	
	return self;
}

- (void) dealloc {
	
	[months release];
	months = nil;
	
	[super dealloc];
}

#pragma mark -

+ (NSArray*) englishMonths {
	
	static NSArray *englishMonths = nil; 
	if ( englishMonths == nil ) {
		englishMonths = [[NSArray alloc] initWithObjects:
			@"January", @"February", @"March", @"April", @"May", @"June", 
			@"July", @"August", @"September", @"October", @"November", @"December", nil];
	}
	
	return englishMonths;
}

#pragma mark -

- (NSArray*) months {
	return months;
}

- (void) setMonths:(NSArray*)anArray {
	if ( months != anArray ) {
		[months release];
		months = [anArray copyWithZone:[self zone]];
	}
}

- (NSInteger) selectedMonth {
	return selectedMonth;
}

- (void) setSelectedMonth:(NSInteger)month {
	
	if ( month < 0 )
		selectedMonth = 0;
	else if ( month > 11 )
		selectedMonth = 11;
	else
		selectedMonth = month;
}

- (NSInteger) selectedYear {
	return selectedYear;
}

- (void) setSelectedYear:(NSInteger)year {
	selectedYear = year;
}

/*
#pragma mark -

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView 
		editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength {
	
	// make sure only the year is selected
	NSLog(@"selecting");
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView 
		editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {
	
	// make sure only the year is edited
	NSLog(@"editing");
}
*/


#pragma mark -

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	
	// just pass this onto the interior with the correct string
	
	NSInteger year = [self selectedYear];
	NSString *monthString = [[self months] objectAtIndex:[self selectedMonth]];
	NSString *text = [NSString stringWithFormat:@"%@ %i", monthString, year];
	
	[self setStringValue:text];
	[self drawInteriorWithFrame:cellFrame inView:controlView];
}

@end
