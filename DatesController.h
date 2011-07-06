/* DatesController */

#import <Cocoa/Cocoa.h>

@class Calendar;

@interface DatesController : NSArrayController
{
	
	IBOutlet Calendar *calendar;
	
	id delegate;
	NSPredicate *datePredicate;
	NSDate *selectedDate;
}

- (id) delegate;
- (void) setDelegate:(id)anObject;

- (NSPredicate*) datePredicate;
- (void) setDatePredicate:(NSPredicate*)aPredicate;

- (NSDate*) selectedDate;
- (void) setSelectedDate:(NSDate*)aDate;

- (Calendar*) calendar;
- (void) setCalendar:(Calendar*)aCalendar;

- (void) updateSelectedObjects:(id)sender;

@end

@interface NSObject (DatesControllerDelegate)

- (void) datesController:(DatesController*)aDatesController willChangeDate:(NSDate*)aDate;
- (void) datesController:(DatesController*)aDatesController didChangeDate:(NSDate*)aDate;

@end
