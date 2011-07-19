//
//  MonthAndYearCell.h
//  Journler XD Lite
//
//  Created by Philip Dow on 9/19/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MonthAndYearCell : NSTextFieldCell {
	
	NSArray *months;
	NSInteger selectedMonth;
	NSInteger selectedYear;
}

+ (NSArray*) englishMonths;

- (NSArray*) months;
- (void) setMonths:(NSArray*)anArray;

- (NSInteger) selectedMonth;
- (void) setSelectedMonth:(NSInteger)month;

- (NSInteger) selectedYear;
- (void) setSelectedYear:(NSInteger)year;

@end
