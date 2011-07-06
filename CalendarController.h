/* CalendarController */

#import <Cocoa/Cocoa.h>

#import "Calendar.h"

@class PDGradientView;
@class PDCalendarButton;
@class JournlerGradientView;

@interface CalendarController : NSObject
{
	id delegate;
	
	IBOutlet Calendar *calendar;
	IBOutlet NSTextField *dateField;
	IBOutlet NSDatePicker *datePicker;
	IBOutlet NSButton *discloseButton;
	IBOutlet JournlerGradientView *datePickerContainer;
	IBOutlet NSMenu *contextMenu;
	IBOutlet PDCalendarButton *calendarButton;
	
	IBOutlet NSObjectController *objectController;
	
	NSWindow *_calWin;
	NSTrackingRectTag _closeTag;
	NSTrackingRectTag _dragTag;
	
	BOOL highlighted;
	BOOL usesSmallCalendar;
	
	NSFont *textFont;
	NSColor *textColor;
}

- (Calendar*) calendar;
- (NSView*) datePickerContainer;

- (BOOL) highlighted;
- (void) setHighlighted:(BOOL)highlight;

- (id) delegate;
- (void) setDelegate:(id)anObject;

- (BOOL) usesSmallCalendar;
- (void) setUsesSmallCalendar:(BOOL)smallCalendar;

- (IBAction) toggleSmallCalendar:(id)sender;
- (void) finalizeCalendarSizeChange:(BOOL)isSmall;

- (NSColor*) textColor;
- (void) setTextColor:(NSColor*)aColor;

- (NSFont*) textFont;
- (void) setTextFont:(NSFont*)aFont;

- (IBAction) discloseCalendar:(id)sender;
- (void) ownerWillClose:(NSNotification*)aNotification;

@end
