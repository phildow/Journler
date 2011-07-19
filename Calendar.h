/* Calendar */

#import <Cocoa/Cocoa.h>

@class PDPowerManagement;
@class MonthAndYearCell;
@class CalendarButtonCell;
@class DatesController;

#define CalendarStartDayChangedNotification @"CalendarStartDayChangedNotification"

@interface Calendar : NSView
{	
	
	MonthAndYearCell *monthYearCell;
	CalendarButtonCell *monthBackCell, *monthTodayCell, *monthForwardCell;
	
	NSCalendarDate		*selectedDate;
	NSCalendarDate		*todaysDate;
	
	NSColor				*backgroundColor;
	
	NSCursor			*pointCursor;
	
	BOOL				dayOfMonthHasEntry[32];
	NSInteger myDay, myMonth, myYear;

	NSInteger _dropDate;
	BOOL drawsBorder;
	
	id delegate;
	IBOutlet DatesController *dataSource;
	NSArray *content;
	
	NSTimer *dateWatcher;
	
	BOOL highlighted;
	NSRect currentDragRect;
}

+ (NSArray*) englishWeekDays;
+ (NSInteger) lastDayOfMonth:(NSInteger)month year:(NSInteger)year;

- (id) delegate;
- (void) setDelegate:(id)anObject;

- (NSArray*) content;
- (void) setContent:(NSArray*)anArray;

- (BOOL) highlighted;
- (void) setHighlighted:(BOOL)highlight;

- (NSColor*) backgroundColor;
- (void) setBackgroundColor:(NSColor*)bgColor;

- (DatesController*) dataSource;
- (void) setDataSource:(DatesController*)aController;

- (void) ownerWillClose:(NSNotification*)aNotification;

- (IBAction) dayToLeft:(id)sender;
- (IBAction) dayToRight:(id)sender;
- (IBAction) monthToLeft:(id)sender;
- (IBAction) monthToRight:(id)sender;
- (IBAction) toToday:(id)sender;

- (IBAction) contexutalDateChange:(id)sender;

// takes a date but converts it internally to a calendar date, thus returns a calendar date
- (void) setSelectedDate:(NSDate*)aDate;
- (NSCalendarDate*) selectedDate;

// these two methods offer backwards compatibility with Journler 2.0
- (void) setCurrentDate:(NSCalendarDate*)aDate;
- (NSCalendarDate*) currentDate;

- (BOOL) drawsBorder;
- (void) setDrawsBorder:(BOOL)draw;

- (void) resetToday:(id)sender;

- (void) dayToLeft;
- (void) dayToRight;
- (void) monthToLeft;
- (void) monthToRight;
- (void) toToday;

- (NSString*) todaysInfo:(NSString*)format;

- (void) updateDaysWithEntries;
//- (void) setDaysWithEntriesArray:(BOOL[])toSet;

- (void) computerDidWake:(NSNotification*)aNotification;

- (NSBezierPath*) bezierPathForSelectedDateAtColumn:(NSInteger)column row:(NSInteger)row offset:(NSInteger)offset;
- (void) drawButtons;

- (IBAction) selectMonth:(id)sender;
- (IBAction) performContextMenuCommand:(id)sender;

- (void) startDayChanged:(NSNotification*)aNotification;

- (BOOL) importPasteboardToDateWithDictionary:(NSDictionary*)aDictionary;

- (NSRect) frameOfDateWithDay:(NSInteger)aDay month:(NSInteger)aMonth year:(NSInteger)aYear;

@end

@interface NSObject (CalendarDelegate)

- (void) calendar:(Calendar*)aCalendar requestsNewEntryForDate:(NSCalendarDate*)aCalendarDate;
- (void) calendarWantsToJumpToDayOfSelectedEntry:(Calendar*)aCalendar;

@end

