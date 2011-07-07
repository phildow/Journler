//
//  CalendarButtonCell.h
//  Journler XD Lite
//
//  Created by Philip Dow on 9/20/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	kCalendarCommandMonthBack = 1,
	kCalendarCommandToToday,
	kCalendarCommandMonthForward,
	MonthForward
}CalbendarButtonCommand;

@interface CalendarButtonCell : NSButtonCell {
	
	CalbendarButtonCommand command;
}

- (CalbendarButtonCommand) command;
- (void) setCommand:(CalbendarButtonCommand)aCommand;

@end
