//
//  MonthAndYearCell.h
//  Journler XD Lite
//
//  Created by Philip Dow on 9/19/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MonthAndYearCell : NSTextFieldCell {
	
	NSArray *months;
	int selectedMonth;
	int selectedYear;
}

+ (NSArray*) englishMonths;

- (NSArray*) months;
- (void) setMonths:(NSArray*)anArray;

- (int) selectedMonth;
- (void) setSelectedMonth:(int)month;

- (int) selectedYear;
- (void) setSelectedYear:(int)year;

@end
