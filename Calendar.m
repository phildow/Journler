#import "Calendar.h"

#import "Definitions.h"
#import "JournlerApplicationDelegate.h"

#import "DatesController.h"

#import "JournlerEntry.h"
#import "JournlerJournal.h"

#import "NSAlert+JournlerAdditions.h"

#import "MonthAndYearCell.h"
#import "CalendarButtonCell.h"

#import <SproutedInterface/SproutedInterface.h>

#define kRowHeight		18
#define kColWidth		22
#define kButtonCellHeight	16

#define kWidthOffset	2

#define kCalendarRequiredWidth 160

#define kMonthYearOffset 23
#define kBackgroundOffset 58
#define kDaysOffset 57
#define kDayHeaderOffset 40

#pragma mark -

@implementation Calendar

static void SetSegmentDescriptions(NSSegmentedControl *control, NSString *firstDescription, ...) {
    // Use NSAccessibilityUnignoredDescendant to be sure we start with the correct object.
    id segmentElement = NSAccessibilityUnignoredDescendant(control);

    // Use the accessibility protocol to get the children.
    NSArray *segments = [segmentElement accessibilityAttributeValue:NSAccessibilityChildrenAttribute];

    va_list args;
    va_start(args, firstDescription);

    id segment;
    NSString *description = firstDescription;
    NSEnumerator *e = [segments objectEnumerator];
    while ((segment = [e nextObject])) {
        if (description != nil) {
            [segment accessibilitySetOverrideValue:description forAttribute:NSAccessibilityDescriptionAttribute];
        } else {
            // Exit loop if we run out of descriptions.
            break;
        }
        description = va_arg(args, id);
    }

    va_end(args);
}

#pragma mark -

+ (void)initialize
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self exposeBinding:@"content"];
	[pool release];
}

- (id)initWithFrame:(NSRect)frameRect
{
	if ( self = [super initWithFrame:frameRect] ) {
		
		//
		// initial date information
		
		todaysDate = [[NSCalendarDate calendarDate] retain];
		selectedDate = [[NSCalendarDate calendarDate] retain];
		
		myDay = [selectedDate dayOfMonth];
		myMonth = [selectedDate monthOfYear];
		myYear = [selectedDate yearOfCommonEra];
		
		//set up a timer to catch the day change
		NSCalendarDate *daychangeFireDate = [[NSCalendarDate dateWithYear:[todaysDate yearOfCommonEra] 
				month:[todaysDate monthOfYear] day:[todaysDate dayOfMonth] hour:0 minute:0 second:1 timeZone:nil]
				dateByAddingYears:0 months:0 days:1 hours:0 minutes:0 seconds:0];
				
		dateWatcher = [[NSTimer alloc] initWithFireDate:daychangeFireDate interval:86400 
				target:self selector:@selector(resetToday:) userInfo:nil repeats:YES];
		[[NSRunLoop currentRunLoop] addTimer:dateWatcher forMode:NSDefaultRunLoopMode];

		//and cursor
		pointCursor = [[NSCursor pointingHandCursor] retain];
		
		// wake from sleep notification - the date may have changed
		[[NSNotificationCenter defaultCenter] addObserver:self 
				selector:@selector(computerDidWake:) 
				name:PDPowerManagementNotification 
				object:[PDPowerManagement sharedPowerManagement]];
		
		drawsBorder = NO;
		backgroundColor = [[NSColor whiteColor] retain];
		content = nil;
		
		_dropDate = -1;
		
		[self registerForDraggedTypes:[NSArray arrayWithObjects:PDEntryIDPboardType, 
			NSFilenamesPboardType, NSURLPboardType, NSRTFDPboardType, NSRTFPboardType, 
			NSStringPboardType, NSTIFFPboardType, NSPICTPboardType, kMailMessagePboardType, nil]];
		
		monthYearCell = [[MonthAndYearCell alloc] init];
		monthBackCell = [[CalendarButtonCell alloc] init];
		monthTodayCell = [[CalendarButtonCell alloc] init];
		monthForwardCell = [[CalendarButtonCell alloc] init];
		
		[monthBackCell setTarget:self];
		[monthBackCell setAction:@selector(monthToLeft:)];
		[monthBackCell setCommand:kCalendarCommandMonthBack];
		[monthBackCell setContinuous:YES];
		[monthBackCell setPeriodicDelay:0.8 interval:0.2];
		
		[monthTodayCell setTarget:self];
		[monthTodayCell setAction:@selector(toToday:)];
		[monthTodayCell setCommand:kCalendarCommandToToday];

		[monthTodayCell setContinuous:YES];
		[monthTodayCell setPeriodicDelay:0.8 interval:500];
		
		[monthForwardCell setTarget:self];
		[monthForwardCell setAction:@selector(monthToRight:)];
		[monthForwardCell setCommand:kCalendarCommandMonthForward];
		[monthForwardCell setContinuous:YES];
		[monthForwardCell setPeriodicDelay:0.8 interval:0.2];
		
		// register for a notification prefs will send when th start day changes
		[[NSNotificationCenter defaultCenter] addObserver:self 
				selector:@selector(startDayChanged:) 
				name:CalendarStartDayChangedNotification 
				object:nil];
		
		currentDragRect = NSZeroRect;
	}
	return self;
}

- (void) dealloc
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self unregisterDraggedTypes];
	
	[selectedDate release];
	[todaysDate release];

	[pointCursor release];
	[backgroundColor release];
		
	[monthYearCell release];
	[monthBackCell release];
	[monthTodayCell release];
	[monthForwardCell release];
	
    [super dealloc];
}

- (void) ownerWillClose:(NSNotification*)aNotification
{
	[dateWatcher invalidate];
	[dateWatcher release];
}

#pragma mark -

+ (NSArray*) englishWeekDays {
	
	return [NSArray arrayWithObjects:@"Sunday", @"Monday", @"Tuesday", @"Wednesday",
			@"Thursday", @"Friday", @"Saturday", nil];
}

+ (int) lastDayOfMonth:(int)month year:(int)year {
	
	//0 is january, 11 is december
	//even though locally (myMonth) 1 is january and 12 is december
	
	BOOL leap = NO;
	static int daysInMonth[] = { 31,28,31,30,31,30,31,31,30,31,30,31 };
	
	if ( year % 4 == 0 ) {
		leap = YES;
		if ( year % 100 == 0 ) { leap = NO; }
		if ( year % 400 == 0 ) { leap = YES; }
	}
	
	if ( leap && month == 2 ) { return 29; }
	else { return daysInMonth[month-1]; }

}

#pragma mark -

- (id) delegate
{
	return delegate;
}

- (void) setDelegate:(id)anObject
{
	delegate = anObject;
}

- (NSArray*) content 
{
	return content;
}

- (void) setContent:(NSArray*)anArray 
{
	if ( content != anArray ) 
	{
		[content release];
		content = [anArray retain];
		
		[self updateDaysWithEntries];
	}
}

- (BOOL) highlighted
{
	return highlighted;
}

- (void) setHighlighted:(BOOL)highlight
{
	highlighted = highlight;
}

- (BOOL) drawsBorder 
{ 
	return drawsBorder; 
}

- (void) setDrawsBorder:(BOOL)draw 
{
	drawsBorder = draw;
}

- (NSColor*) backgroundColor 
{ 
	return backgroundColor; 
}

- (void) setBackgroundColor:(NSColor*)bgColor 
{
	if ( backgroundColor != bgColor ) 
	{
		[backgroundColor release];
		backgroundColor = [bgColor copyWithZone:[self zone]];
	}
}

- (DatesController*) dataSource
{
	return dataSource;
}

- (void) setDataSource:(DatesController*)aController
{
	if ( dataSource != aController )
	{
		[dataSource release];
		dataSource = [aController retain];
	}
}

#pragma mark -


- (void)setSelectedDate:(NSDate*)aDate 
{
	BOOL entireDisplayNeedsUpdate = YES;
	NSRect earlierInvalidatedRect = [self frameOfDateWithDay:myDay month:myMonth year:myYear];
	
	if ( aDate == nil ) // date shouldn't be nil
		aDate = [NSCalendarDate calendarDate];
	// else if ( [aDate isMemberOfClass:[NSDate class]] )
	// leopard bug, must guarantee that this is a calendar date
	else
		aDate = [aDate dateWithCalendarFormat:nil timeZone:nil];
				
	if ( selectedDate != aDate ) {
		[selectedDate release];
		selectedDate = [aDate copyWithZone:[self zone]];
	}
	
	//and update our date integers for easy access
	int newYear = [(NSCalendarDate*)selectedDate yearOfCommonEra];
	int newMonth = [(NSCalendarDate*)selectedDate monthOfYear];
	
	if ( myMonth == newMonth && myYear == newYear )
		entireDisplayNeedsUpdate = NO;
	
	myDay = [(NSCalendarDate*)selectedDate dayOfMonth];
	myMonth = newMonth;
	myYear = newYear;
	
	//if ( entireDisplayNeedsUpdate )
	[self updateDaysWithEntries];
	
	[[self window] invalidateCursorRectsForView:self];
	
	if ( entireDisplayNeedsUpdate )
		[self setNeedsDisplay:YES];
	else
	{
		NSRect invalidatedRect = [self frameOfDateWithDay:myDay month:myMonth year:myYear];
		
		[self setNeedsDisplayInRect:invalidatedRect];
		[self setNeedsDisplayInRect:earlierInvalidatedRect];
	}
}

- (NSCalendarDate*) selectedDate {

	// return a mix of the current date and the present time
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	return [NSCalendarDate 
			dateWithYear:[selectedDate yearOfCommonEra] month:[selectedDate monthOfYear] day:[selectedDate dayOfMonth] 
			hour:[now hourOfDay] minute:[now minuteOfHour] second:[now secondOfMinute] timeZone:nil];
}

- (void) setCurrentDate:(NSCalendarDate*)aDate
{
	[self setSelectedDate:aDate];
}

- (NSCalendarDate*) currentDate
{
	return [self selectedDate];
}

#pragma mark -


- (void) resetToday:(id)sender {

	//called by the timer every 24 hours 1 second after midnight to update the current day
	
	//reset "todays" date
	[todaysDate release];
	todaysDate = [[NSCalendarDate calendarDate] retain];
	//update our display
	//[self setNeedsDisplay:YES];
	[self setNeedsDisplayInRect:[self frameOfDateWithDay:[todaysDate dayOfWeek] month:[todaysDate monthOfYear] year:[todaysDate yearOfCommonEra]]];
}

- (void) computerDidWake:(NSNotification*)aNotification {
	
	// just make sure that today's date is corrected if the computer was asleep during a midnight date change
	if ( [[[aNotification userInfo] objectForKey:PDPowerManagementMessage] intValue] == PDPowerManagementPoweredOn )
		[self resetToday:self];
	
}

#pragma mark -

- (void)dayToLeft {
	
	BOOL entireDisplayNeedsUpdate = NO;
	NSRect earlierInvalidatedRect = [self frameOfDateWithDay:myDay month:myMonth year:myYear];

	myDay--;
	if ( myDay < 1 ) {
		//get us set up on the right day
		if ( myMonth == 1 ) { myDay = [Calendar lastDayOfMonth:12 year:myYear]; }
		else { myDay = [Calendar lastDayOfMonth:myMonth-1 year:myYear]; }
		//and shift our month, which will take care of refreshing
		[self monthToLeft];
		
		entireDisplayNeedsUpdate = YES;
	}
	else {
		//call a setCurrentInfo so our latest information is posted to our observers.
		[self setSelectedDate:[NSCalendarDate dateWithYear:myYear month:myMonth day:myDay hour:1 minute:1 second:1 timeZone:nil]];
		
	}
	
	if ( entireDisplayNeedsUpdate )
		[self setNeedsDisplay:YES];
	else
	{
		NSRect invalidatedRect = [self frameOfDateWithDay:myDay month:myMonth year:myYear];
		
		[self setNeedsDisplayInRect:invalidatedRect];
		[self setNeedsDisplayInRect:earlierInvalidatedRect];
	}
}

- (void)dayToRight 
{
	BOOL entireDisplayNeedsUpdate = NO;
	NSRect earlierInvalidatedRect = [self frameOfDateWithDay:myDay month:myMonth year:myYear];
	
	myDay++;
	if ( myDay > [Calendar lastDayOfMonth:myMonth year:myYear] ) {
		myDay = 1;
		[self monthToRight];
		
		entireDisplayNeedsUpdate = YES;
	}
	else {
		//call a setCurrentInfo so our latest information is posted to our observers.
		[self setSelectedDate:[NSCalendarDate dateWithYear:myYear month:myMonth day:myDay hour:1 minute:1 second:1 timeZone:nil]];
		
	}
	
	if ( entireDisplayNeedsUpdate )
		[self setNeedsDisplay:YES];
	else
	{
		NSRect invalidatedRect = [self frameOfDateWithDay:myDay month:myMonth year:myYear];
		
		[self setNeedsDisplayInRect:invalidatedRect];
		[self setNeedsDisplayInRect:earlierInvalidatedRect];
	}
}

- (void) monthToLeft 
{
	BOOL entireDisplayNeedsUpdate = YES;
	NSRect earlierInvalidatedRect = [self frameOfDateWithDay:myDay month:myMonth year:myYear];
	
	if ( myMonth != 1 ) { myMonth--; }
	else {
		myMonth = 12;
		myYear--;
	}
	
	//and in case we've switched months and our day has gone over
	if ( myDay > [Calendar lastDayOfMonth:myMonth year:myYear] ) { myDay = [Calendar lastDayOfMonth:myMonth year:myYear]; }
	
	//call a setCurrentInfo so our latest information is posted to our observers.
	[self setSelectedDate:[NSCalendarDate dateWithYear:myYear month:myMonth day:myDay hour:1 minute:1 second:1 timeZone:nil]];
	
	if ( entireDisplayNeedsUpdate )
		[self setNeedsDisplay:YES];
	else
	{
		NSRect invalidatedRect = [self frameOfDateWithDay:myDay month:myMonth year:myYear];
		
		[self setNeedsDisplayInRect:invalidatedRect];
		[self setNeedsDisplayInRect:earlierInvalidatedRect];
	}
}

- (void) monthToRight 
{
	BOOL entireDisplayNeedsUpdate = YES;
	NSRect earlierInvalidatedRect = [self frameOfDateWithDay:myDay month:myMonth year:myYear];
	
	if ( myMonth != 12 ) { myMonth++; }
	else {
		myMonth = 1;
		myYear++;
	}
	
	//and in case we've switched months and our day has gone over
	if ( myDay > [Calendar lastDayOfMonth:myMonth year:myYear] ) { myDay = [Calendar lastDayOfMonth:myMonth year:myYear]; }
	
	//call a setCurrentInfo so our latest information is posted to our observers.
	[self setSelectedDate:[NSCalendarDate dateWithYear:myYear month:myMonth day:myDay hour:1 minute:1 second:1 timeZone:nil]];
	
	if ( entireDisplayNeedsUpdate )
		[self setNeedsDisplay:YES];
	else
	{
		NSRect invalidatedRect = [self frameOfDateWithDay:myDay month:myMonth year:myYear];
		
		[self setNeedsDisplayInRect:invalidatedRect];
		[self setNeedsDisplayInRect:earlierInvalidatedRect];
	}
}

- (void) toToday 
{
	BOOL entireDisplayNeedsUpdate = NO;
	NSRect earlierInvalidatedRect = [self frameOfDateWithDay:myDay month:myMonth year:myYear];
	
	if ( ![[[NSCalendarDate calendarDate] descriptionWithCalendarFormat:@"%Y%m%d"] isEqualToString:
			[todaysDate descriptionWithCalendarFormat:@"%Y%m%d"]] )
		[self resetToday:self];
	
	[self setSelectedDate:[NSCalendarDate calendarDate]];
	
	if ( entireDisplayNeedsUpdate )
		[self setNeedsDisplay:YES];
	else
	{
		NSRect invalidatedRect = [self frameOfDateWithDay:myDay month:myMonth year:myYear];
		
		[self setNeedsDisplayInRect:invalidatedRect];
		[self setNeedsDisplayInRect:earlierInvalidatedRect];
	}
}

#pragma mark -

- (IBAction) dayToLeft:(id)sender { 
	[self dayToLeft];
}

- (IBAction) dayToRight:(id)sender {
	[self dayToRight];
}

- (IBAction) monthToLeft:(id)sender { 
	[self monthToLeft];
}

- (IBAction) monthToRight:(id)sender { 
	[self monthToRight];
}

- (IBAction) toToday:(id)sender { 
	[self toToday];
}

#pragma mark -

- (IBAction) contexutalDateChange:(id)sender {
	
	if ( [sender tag] >= 501 && [sender tag] <= 512 ) {
		
		// acquire a month from 01 to 12 for January to February
		int targetMonth = [sender tag] - 500;
		int highestDay = [Calendar lastDayOfMonth:targetMonth year:myYear];
		
		NSCalendarDate *newDate = [NSCalendarDate dateWithYear:myYear month:targetMonth day:(myDay<=highestDay?myDay:highestDay) 
				hour:0 minute:0 second:0 timeZone:nil];
		
		[self setSelectedDate:newDate];
		
	}
	
	else if ( [sender tag] == 400 ) {
		
		// requesting a year change
		
		int newYear = [sender intValue];
		int highestDay = [Calendar lastDayOfMonth:myMonth year:newYear];
		
		NSCalendarDate *newDate = [NSCalendarDate dateWithYear:newYear month:myMonth day:(myDay<=highestDay?myDay:highestDay) 
				hour:0 minute:0 second:0 timeZone:nil];
		
		[self setSelectedDate:newDate];
		
	}
	
	else if ( [sender tag] == 401 ) {
		
		// focus on the year field and select it
		//[[self window] makeFirstResponder:yearField];
		//[yearField selectText:self];
		
	}
	
}

- (BOOL)validateMenuItem:(NSMenuItem*)anItem {
	
	BOOL enabled = YES;
	
	if ( [anItem tag] >= 501 && [anItem tag] <= 512 ) {
		
		// acquire a month from 01 to 12 for January to February
		int targetMonth = [anItem tag] - 500;
		if ( targetMonth == myMonth )
			[anItem setState:NSOnState];
		else
			[anItem setState:NSOffState];
		
	}
	
	return enabled;
	
}

#pragma mark -

- (NSString*) todaysInfo:(NSString*)format {
	//always create this thing on the fly as I don't keep this information in memory - localizedDateInfo ?
	return [[NSCalendarDate dateWithYear:myYear month:myMonth day:myDay hour:1 minute:1 second:1 timeZone:nil] descriptionWithCalendarFormat:format locale:nil];
}

// ============================================================
// Handling our display
// ============================================================

#pragma mark -
#pragma mark Drawing

- (void)drawRect:(NSRect)rect {
	
	//NSLog(@"calendar content count: %i",[content count]);
	
	NSString *dayID;
	
	NSMutableDictionary *tempAttributes = [NSMutableDictionary dictionary];
	
	NSRect bds = [self bounds];
	int total_offset = kWidthOffset + ( bds.size.width/2 - kCalendarRequiredWidth/2 );
	
	[backgroundColor set];
	NSRectFill(bds);
	
	if ( drawsBorder ) {
		[[NSColor lightGrayColor] set];
		NSFrameRect(bds);
	}
	else
	{
		[[NSColor colorWithCalibratedWhite:0.5 alpha:1.0] set];
		NSFrameRect( NSMakeRect(0,bds.size.height-1,bds.size.width,bds.size.height-1) );
		//[[NSBezierPath bezierPathWithLineFrom:NSMakePoint(0,bds.size.height-1) to:NSMakePoint(bds.size.width,bds.size.height-1) lineWidth:1] stroke];
	}
	
	int col, row, offset, i;
	
	//draw my days
	[tempAttributes setObject:[NSFont boldSystemFontOfSize:11.0] forKey:NSFontAttributeName];
	[tempAttributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	
	int start_day = [[NSUserDefaults standardUserDefaults] integerForKey:@"CalendarStartDay"];
	// 0 indicates Sunday, 6 indicates Monday
	
	int day_id = start_day;
	NSArray *weekDays = [[NSUserDefaults standardUserDefaults] objectForKey:NSShortWeekDayNameArray];
	if ( !weekDays || [weekDays count] < 7 ) weekDays = [Calendar englishWeekDays];
	
	for ( i = 0; i <= 6 ; i++ ) {
		
		dayID = [[weekDays objectAtIndex:day_id] substringToIndex:1];
		[dayID drawAtPoint:
				NSMakePoint( total_offset + kColWidth*i + ( kColWidth/2 - [dayID sizeWithAttributes:tempAttributes].width/2 ), 
				kDayHeaderOffset) withAttributes:tempAttributes];
		
		day_id++;
		if (day_id == 7 ) day_id = 0;
	}

	//reset the font info
	NSFont *ohneEntriesFont = [NSFont systemFontOfSize:11.0];
	NSFont *mitEntriesFont = [NSFont boldSystemFontOfSize:11.0];
	[tempAttributes setObject:ohneEntriesFont forKey:NSFontAttributeName];
	
	// set up offset based on first day of week
	offset = [[NSCalendarDate dateWithYear:myYear month:myMonth day:1 hour:1 minute:1 second:1 timeZone:nil] dayOfWeek];
	
	// set the original column and row based on offset and start information
	col = offset - start_day;
	row = 0;
	
	// if the original column due to offset is seven or more, adjust
	if ( col < 0 ) col+= 7;
	
	int todaysDay = [todaysDate dayOfMonth];
	int todaysMonth = [todaysDate monthOfYear];
	int todaysYear = [todaysDate yearOfCommonEra];
	
	// draw the buttons
	[self drawButtons];
	
	// draw the month and year
	[monthYearCell setSelectedMonth:myMonth-1];
	[monthYearCell setSelectedYear:[[self selectedDate] yearOfCommonEra]];
	[monthYearCell drawWithFrame:
			NSMakeRect(total_offset, kMonthYearOffset, bds.size.width - total_offset*2, kRowHeight-2) inView:self];
	
	// draw the background for the first row
	NSBezierPath *bg = [NSBezierPath bezierPathWithRoundedRect:
			NSMakeRect(total_offset, kBackgroundOffset, bds.size.width - total_offset*2, kRowHeight-2) 
			cornerRadius:8.0];
	[[NSColor colorWithCalibratedWhite:0.95 alpha:1.0] set];
	[bg fill];
	
	// draw the days 
	for ( i = 1; i <= [Calendar lastDayOfMonth:myMonth year:myYear ]; i++ ) {
		
		// create the string that will be drawn
		dayID = [NSString stringWithFormat:@"%i",i];
		
		// draw the row's background whenever the 0 columns is reached
		if ( col == 0 && row != 0 ) {
			
			NSBezierPath *bg = [NSBezierPath bezierPathWithRoundedRect:
					NSMakeRect(total_offset, kBackgroundOffset+row*kRowHeight, bds.size.width - total_offset*2, kRowHeight-2) 
					cornerRadius:8.0];
			[[NSColor colorWithCalibratedWhite:0.95 alpha:1.0] set];
			[bg fill];
			
		}
		
		// draw a drop circle
		if ( i == _dropDate ) {
			
			// highlight the day grey
			[[NSColor colorWithCalibratedWhite:0.4 alpha:1.0] set];
			[[self bezierPathForSelectedDateAtColumn:col row:row offset:total_offset] fill];
			
			// bold the date and use a white color
			NSFont *font = [tempAttributes objectForKey:NSFontAttributeName];
			NSFont *boldFont = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSBoldFontMask];
			
			[tempAttributes setObject:boldFont forKey:NSFontAttributeName];
			[tempAttributes setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
			
			// draw the date
			[dayID drawAtPoint:NSMakePoint( 
					total_offset+col*kColWidth+( kColWidth/2 - [dayID sizeWithAttributes:tempAttributes].width/2 ), 
					kDaysOffset+row*kRowHeight + ( kRowHeight/2 - [dayID sizeWithAttributes:tempAttributes].height/2 ) ) 
					withAttributes:tempAttributes];
		
			// set the font back
			[tempAttributes setObject:font forKey:NSFontAttributeName];
			
		}
		
		// draw the selected day
		else if ( i == myDay ) {
			
			// highlight the day blue
			if (([[self window] firstResponder] == self) && [[self window] isMainWindow] && [[self window] isKeyWindow])
				[[NSColor colorWithCalibratedRed:102.0/255.0 green:133.0/255.0 blue:183.0/255.0 alpha:1.0] set];
			else
				[[NSColor colorWithCalibratedRed:152.0/255.0 green:170.0/255.0 blue:196.0/255.0 alpha:0.9] set];
			
			[[self bezierPathForSelectedDateAtColumn:col row:row offset:total_offset] fill];
			
			// bold the date and use a white color
			NSFont *font = [tempAttributes objectForKey:NSFontAttributeName];
			NSFont *boldFont = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSBoldFontMask];
			
			[tempAttributes setObject:boldFont forKey:NSFontAttributeName];
			[tempAttributes setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
			
			// draw the date
			[dayID drawAtPoint:NSMakePoint( 
					total_offset+col*kColWidth+( kColWidth/2 - [dayID sizeWithAttributes:tempAttributes].width/2 ), 
					kDaysOffset+row*kRowHeight + ( kRowHeight/2 - [dayID sizeWithAttributes:tempAttributes].height/2 ) ) 
					withAttributes:tempAttributes];
		
			// set the font back
			[tempAttributes setObject:font forKey:NSFontAttributeName];
		}
		
		// draw todays day if it is other than the selected day
		else if ( todaysDay == i && todaysMonth == myMonth && todaysYear == myYear ) {
			
			// highlight the day grey
			[[NSColor colorWithCalibratedWhite:0.7 alpha:1.0] set];
			[[self bezierPathForSelectedDateAtColumn:col row:row offset:total_offset] fill];
			
			// bold the date and use a white color
			NSFont *font = [tempAttributes objectForKey:NSFontAttributeName];
			NSFont *boldFont = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSBoldFontMask];
			
			[tempAttributes setObject:boldFont forKey:NSFontAttributeName];
			[tempAttributes setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
			
			// draw the date
			[dayID drawAtPoint:NSMakePoint( 
					total_offset+col*kColWidth+( kColWidth/2 - [dayID sizeWithAttributes:tempAttributes].width/2 ), 
					kDaysOffset+row*kRowHeight + ( kRowHeight/2 - [dayID sizeWithAttributes:tempAttributes].height/2 ) ) 
					withAttributes:tempAttributes];
			
			// set the font back
			[tempAttributes setObject:font forKey:NSFontAttributeName];
		
		}
		
		// draw a date neither selected or today
		else 
		{
			// color the date depending on the presence of entries
			if ( dayOfMonthHasEntry[i] )
			{
				// date with entry
				[tempAttributes setObject:mitEntriesFont forKey:NSFontAttributeName];
				[tempAttributes setObject:[NSColor colorWithCalibratedWhite:0.15 alpha:1.0] forKey:NSForegroundColorAttributeName];
			}
			else 
			{
				// date without entry
				[tempAttributes setObject:ohneEntriesFont forKey:NSFontAttributeName];
				[tempAttributes setObject:[NSColor darkGrayColor] forKey:NSForegroundColorAttributeName];
			}
			
			// draw the date
			[dayID drawAtPoint:NSMakePoint( 
					total_offset+col*kColWidth+( kColWidth/2 - [dayID sizeWithAttributes:tempAttributes].width/2 ), 
					kDaysOffset+row*kRowHeight + ( kRowHeight/2 - [dayID sizeWithAttributes:tempAttributes].height/2 ) ) 
					withAttributes:tempAttributes];
		}
		
		col++;
		if ( col == 7 ) {
			
			row++;
			col = 0;
		}
	}
}

- (void) drawButtons {
	
	NSRect bds = [self bounds];
	int third = ceil(bds.size.width / 3.0);
	
	NSRect monthBack = NSMakeRect(0,0,third,kButtonCellHeight);
	NSRect monthToday = NSMakeRect(third,0,third,kButtonCellHeight);
	NSRect monthForward = NSMakeRect(bds.size.width-third,0,third,kButtonCellHeight);
	
	[monthBackCell drawWithFrame:monthBack inView:self];
	[monthForwardCell drawWithFrame:monthForward inView:self];
	[monthTodayCell drawWithFrame:monthToday inView:self];

}

- (NSBezierPath*) bezierPathForSelectedDateAtColumn:(int)column row:(int)row offset:(int)offset {
	
	NSBezierPath *path;
	
	if ( column == 0 ) {
	
		// special action for a column at the far left
		NSBezierPath *curve = [NSBezierPath bezierPathWithRoundedRect:
				NSMakeRect(offset+column*kColWidth, kBackgroundOffset+row*kRowHeight, 22, kRowHeight-2) 
				cornerRadius:8.0];
				
		path = [NSBezierPath bezierPathWithRect:
				NSMakeRect(offset+12+column*kColWidth, kBackgroundOffset+row*kRowHeight, 10, kRowHeight-2)];
	
		[path appendBezierPath:curve];
		
	}
	else if ( column == 6 ) {
		
		// special action for a column at the far right
		NSBezierPath *curve = [NSBezierPath bezierPathWithRoundedRect:
				NSMakeRect(offset+2+column*kColWidth, kBackgroundOffset+row*kRowHeight, 22, kRowHeight-2) 
				cornerRadius:8.0];
				
		path = [NSBezierPath bezierPathWithRect:
				NSMakeRect(offset+column*kColWidth, kBackgroundOffset+row*kRowHeight, 10, kRowHeight-2)];
	
		[path appendBezierPath:curve];
	
	}
	else {
		
		// regular old rectangle
		path = [NSBezierPath bezierPathWithRect:
				NSMakeRect(offset+column*kColWidth, kBackgroundOffset+row*kRowHeight, 21, kRowHeight-2)];
	}
	
	return path;
}

- (NSRect) frameOfDateWithDay:(int)aDay month:(int)aMonth year:(int)aYear
{
	if ( aMonth != myMonth || aYear != myYear )
		return NSZeroRect;
	else
	{
		int col, row, offset, i;
		int start_day = [[NSUserDefaults standardUserDefaults] integerForKey:@"CalendarStartDay"];
		
		NSRect bds = [self bounds];
		int total_offset = kWidthOffset + ( bds.size.width/2 - kCalendarRequiredWidth/2 );
		
		NSRect theFrame = NSZeroRect;
		
		// set up offset based on first day of week
		offset = [[NSCalendarDate dateWithYear:myYear month:myMonth day:1 hour:1 minute:1 second:1 timeZone:nil] dayOfWeek];
		
		// set the original column and row based on offset and start information
		col = offset - start_day;
		row = 0;
		
		// if the original column due to offset is seven or more, adjust
		if ( col < 0 ) col+= 7;
		
		// get the column and row for this position
		for ( i = 1; i < aDay; i++ ) 
		{
			col++;
			if ( col == 7 ) 
			{
				row++;
				col = 0;
			}
		}
		
		theFrame = NSMakeRect(total_offset+col*kColWidth - 2, kBackgroundOffset+row*kRowHeight - 2, kColWidth + 4, kRowHeight + 4);
		return theFrame;
	}

}

#pragma mark -

- (void)keyDown:(NSEvent *)theEvent {
	
	//
	// calendar as first responder, keyboard events change date
	
	unichar key = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
	unsigned flags = [theEvent modifierFlags];
	
	if ( key == NSLeftArrowFunctionKey && !(flags & NSShiftKeyMask) )
		[self dayToLeft];
	else if ( key == NSLeftArrowFunctionKey && (flags & NSShiftKeyMask) )
		[self monthToLeft];
		
	else if ( key == NSRightArrowFunctionKey && !(flags & NSShiftKeyMask) )
		[self dayToRight];
	else if ( key == NSRightArrowFunctionKey && (flags & NSShiftKeyMask) )	
		[self monthToRight];
		
	else if ( key == NSCarriageReturnCharacter || key == NSEnterCharacter )
		[self toToday];
	
	//else if ( key == NSTabCharacter )
	//	[self monthToRight];
	//else if ( key == (unichar)25 ) // the capitalized tab?
	//	[self monthToLeft];
	
}

- (void)mouseDown:(NSEvent *)theEvent {
	
	//
	// calendar as first responder, mouse events change date
	
	NSRect bds = [self bounds];
	int total_offset = kWidthOffset + ( bds.size.width/2 - kCalendarRequiredWidth/2 );
	
	int myX, myY, i, j, offset, dayHit;
	NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	// git rid of first responder so that the year field won't highlight ( fr goes away otherwise anyway? )
	//[[self window] makeFirstResponder:nil];
	
	NSRect navRect = NSMakeRect(0,0,bds.size.width,kButtonCellHeight);
	NSRect monthYearRect = NSMakeRect(total_offset, kMonthYearOffset, bds.size.width - total_offset*2, kRowHeight-2);
	
	// check to see if the user is clicking one of the buttons
	if ( NSPointInRect(mouseLoc,navRect) ) {
		
		int third = ceil(bds.size.width / 3.0);
		
		NSRect monthBack = NSMakeRect(0,0,third,kButtonCellHeight);
		NSRect monthToday = NSMakeRect(third,0,third,kButtonCellHeight);
		NSRect monthForward = NSMakeRect(bds.size.width-third,0,third,kButtonCellHeight);
		
		if ( NSPointInRect(mouseLoc,monthBack) ) {
			
			[monthBackCell setState:NSOnState];
			[self displayRect:monthBack];
			[monthBackCell trackMouse:theEvent inRect:monthBack ofView:self untilMouseUp:YES];
			[monthBackCell setState:NSOffState];
			[self displayRect:monthBack];
			
			//[self monthToLeft];
		}
		else if ( NSPointInRect(mouseLoc,monthToday) ) {
			
			[monthTodayCell setState:NSOnState];
			[self displayRect:monthToday];
			[monthTodayCell trackMouse:theEvent inRect:monthToday ofView:self untilMouseUp:YES];
			[monthTodayCell setState:NSOffState];
			[self displayRect:monthToday];
			
			//[self toToday];
		}
		else if ( NSPointInRect(mouseLoc,monthForward) ) {
			
			[monthForwardCell setState:NSOnState];
			[self displayRect:monthForward];
			[monthForwardCell trackMouse:theEvent inRect:monthForward ofView:self untilMouseUp:YES];
			[monthForwardCell setState:NSOffState];
			[self displayRect:monthForward];
			
			//[self monthToRight];
		}
	}
	
	// check to see if the mouse went down in the month/year field
	else if ( NSPointInRect(mouseLoc,monthYearRect) ) {
		
		int i;
		NSArray *months = [monthYearCell months];
		NSMenu *monthsMenu = [[NSMenu alloc] initWithTitle:[NSString string]];
		
		for ( i = 0; i < 12; i++ ) {
			[monthsMenu addItemWithTitle:[months objectAtIndex:i] action:@selector(selectMonth:) keyEquivalent:@""];
		}
		
		[[monthsMenu itemAtIndex:myMonth-1] setState:NSOnState];
		[NSMenu popUpContextMenu:monthsMenu withEvent:theEvent forView:self];
		
		//[monthYearCell editWithFrame:NSMakeRect(total_offset, kMonthYearOffset, bds.size.width - total_offset*2, kRowHeight-2) 
		//		inView:self editor:[[self window] fieldEditor:YES forObject:self] delegate:self event:theEvent];
	
		
		//return;
	}
	
	// check for a simple date click
	else {
	
		myX = mouseLoc.x - total_offset;
		myY = mouseLoc.y - kDaysOffset;
		
		//I must know the day of the week, so construct a date and grab that information
		int start_day = [[NSUserDefaults standardUserDefaults] integerForKey:@"CalendarStartDay"];
		offset = [[NSCalendarDate dateWithYear:myYear month:myMonth day:1 hour:1 minute:1 second:1 timeZone:nil] dayOfWeek];
		
		//set up my offset, taking account that sunday is a 0 for the date but a 6 for me, while monday is a 0
		offset = offset - start_day;
		if ( offset < 0 ) offset += 7;
		
		// calculate the hit location
		for ( i = 0; i <= 6; i++ ) {
			if ( (myX >= i*kColWidth) && (myX < (i+1)*kColWidth) ) break;
		}
		for ( j = 0; j <= 6; j++ ) {
			if ( (myY >= j*kRowHeight) && (myY < (j+1)*kRowHeight) ) break;
		}
		
		if ( i <= 6 && j <= 6 )
		{
			dayHit = i+1 + j*7;
			dayHit = dayHit - offset;
			
			// select the new date if there is in fact one
			if ( dayHit > 0 && dayHit <= [Calendar lastDayOfMonth:myMonth year:myYear] ) {
				
				NSCalendarDate *newDayLoc = [[[NSCalendarDate alloc] 
						initWithYear:myYear month:myMonth day:dayHit hour:1 minute:1 second:1 timeZone:nil] autorelease];
				
				[self setSelectedDate:newDayLoc];
			}
		}
	}
}

#pragma mark -

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
	return NO;
}

- (BOOL)mouseDownCanMoveWindow {
	return NO;
}

- (BOOL)acceptsFirstResponder {
	return YES;
}

- (BOOL)resignFirstResponder {
	
	[self setNeedsDisplay:YES];
	return YES;
}

- (BOOL)becomeFirstResponder {
	
	[self setNeedsDisplay:YES];
	return YES;
}


#pragma mark -

- (void) updateDaysWithEntries {
	
	int i;
	int maxDays = [Calendar lastDayOfMonth:[selectedDate monthOfYear] year:[selectedDate yearOfCommonEra]];
	int	dateInt = [[selectedDate descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil] intValue];
	
	dateInt-=([selectedDate dayOfMonth]-1);
	
	for ( i = 1; i <= 31; i++ ) {
		
		//NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ANY dateCreatedInt == %i && markedForTrash == NO", dateInt];
		//dayOfMonthHasEntry[i] = ( [[content filteredArrayUsingPredicate:predicate] count] != 0 );
		
		int j;
		BOOL entryAtDate = NO;
		if ( content != nil )
		{
			for ( j = 0; j < CFArrayGetCount((CFArrayRef)content); j++ )
			{
				JournlerEntry *anEntry = (id)CFArrayGetValueAtIndex((CFArrayRef)content,j);			
				if ( [anEntry dateCreatedInt] == dateInt && ![[anEntry valueForKey:@"markedForTrash"] boolValue] ) 
				{
					entryAtDate = YES;
					break;
				}
			}
		}
		
		dayOfMonthHasEntry[i] = entryAtDate;
		
		//up myself by a day
		dateInt++;
		
		//and kill the for loop if we've gone over
		if ( i >= maxDays )
			break;
			
	}
}

/*
- (void) setDaysWithEntriesArray:(BOOL[])toSet {

	int i;
	for ( i = 1; i <= 31; i++ ) { dayOfMonthHasEntry[i] = toSet[i]; }
	//marked date information has changed, we need to redraw
	[self setNeedsDisplay:YES];
}
*/

#pragma mark -

- (BOOL) isFlipped { 
	return YES; 
}

- (void)resetCursorRects {
	
	//
	// sets both the cursor rects and the tooltips
	
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	int col, row, offset, i;
	NSRect visRect = [self visibleRect];
	NSRect cursRect;
	
	[self discardCursorRects];
	[self removeAllToolTips];
	
	//I must know the day of the week, so construct a date and grab that information then calc the offset
	offset = [[NSCalendarDate dateWithYear:myYear month:myMonth day:1 hour:1 minute:1 second:1 timeZone:nil] dayOfWeek];
	int start_day = [[NSUserDefaults standardUserDefaults] integerForKey:@"CalendarStartDay"];
	
	NSRect bds = [self bounds];
	int total_offset = kWidthOffset + ( bds.size.width/2 - kCalendarRequiredWidth/2 );
	
	//set up my offset, taking account that sunday is a 0 for the date but a 6 for me, while monday is a 0
	col = offset - start_day;
	row = 0;
	if ( col < 0 ) col+= 7;
	
	// actually establish the cursor rects
	for ( i = 1; i <= [Calendar lastDayOfMonth:myMonth year:myYear ]; i++ ) {
		
		cursRect = NSMakeRect(total_offset+col*kColWidth, kBackgroundOffset+row*kRowHeight, 20, kRowHeight-2);
		if ( NSContainsRect(visRect,cursRect) ) { 
			
			//add a cursor rect - not the difference between point drawing, inset and made slighly smaller
			[self addCursorRect:cursRect cursor:pointCursor];
			
			NSCalendarDate *newDayLoc = [[[NSCalendarDate alloc] 
				initWithYear:myYear month:myMonth day:i hour:1 minute:1 second:1 timeZone:nil] autorelease];
			NSDateFormatter *date_formatter = [[[NSDateFormatter alloc] init] autorelease];

			[date_formatter setDateStyle:NSDateFormatterFullStyle];
			[date_formatter setTimeStyle:NSDateFormatterNoStyle];
			
			NSString *tip = [date_formatter stringFromDate:newDayLoc];
			[self addToolTipRect:cursRect owner:[tip retain] userData:NULL];

		}
		
		col++;
		if ( col == 7 ) {
			row++;
			col = 0;
		}
	}

}

#pragma mark -

- (void)viewDidMoveToSuperview {
	
	if ( [self superview] == nil )
		return;
	
	[[self window] invalidateCursorRectsForView:self];
}

- (void)viewDidMoveToWindow
{
	if ( [self window] == nil )
		return;
	
	[[self window] invalidateCursorRectsForView:self];
}

- (IBAction) selectMonth:(id)sender {
	
	int index = [[sender menu] indexOfItem:sender];
	int targetMonth = index + 1;
	
	// acquire a month from 01 to 12 for January to February
	int highestDay = [Calendar lastDayOfMonth:targetMonth year:myYear];
	
	NSCalendarDate *newDate = [NSCalendarDate dateWithYear:myYear month:targetMonth day:(myDay<=highestDay?myDay:highestDay) 
			hour:0 minute:0 second:0 timeZone:nil];
	
	[self setSelectedDate:newDate];
}

- (IBAction) performContextMenuCommand:(id)sender
{
	switch ( [sender tag] )
	{
	case 870: //  new entry selected date
		if ( [[self delegate] respondsToSelector:@selector(calendar:requestsNewEntryForDate:)] )
			[[self delegate] calendar:self requestsNewEntryForDate:[self selectedDate]];
		break;
	case 871: // new entry today's date
		if ( [[self delegate] respondsToSelector:@selector(calendar:requestsNewEntryForDate:)] )
			[[self delegate] calendar:self requestsNewEntryForDate:todaysDate];
		break;
	case 872: // snap to date of entry
		if ( [[self delegate] respondsToSelector:@selector(calendarWantsToJumpToDayOfSelectedEntry:)] )
			[[self delegate] calendarWantsToJumpToDayOfSelectedEntry:self];
		break;
	case 873: // snap to today's date
		[self toToday:sender];
	}
}

- (void) startDayChanged:(NSNotification*)aNotification
{
	[self setNeedsDisplay:YES];
}

#pragma mark -
#pragma Drag & Drop

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	
	NSDragOperation operation = NSDragOperationNone;
	
	if ( [[[sender draggingPasteboard] types] containsObject:PDEntryIDPboardType] )
		operation = NSDragOperationLink;
	else
		operation = NSDragOperationCopy;
	
	if ( operation != NSDragOperationNone ) {
		
		//
		// determine the target date
		
		NSPoint mouseLoc;
		NSRect bds = [self bounds];
		
		int start_day = [[NSUserDefaults standardUserDefaults] integerForKey:@"CalendarStartDay"];
		int total_offset = kWidthOffset + ( bds.size.width/2 - kCalendarRequiredWidth/2 );
		int myX, myY, i, j, offset, dayHit;
		
		mouseLoc = [self convertPoint:[sender draggingLocation] fromView:nil];
		
		NSRect navRect = NSMakeRect(0,0,bds.size.width,kButtonCellHeight);
		
		// check to see if the user is clicking one of the buttons
		if ( NSPointInRect(mouseLoc,navRect) ) {
		
			operation = NSDragOperationNone;
			
			int third = ceil(bds.size.width / 3.0);
			
			NSRect monthBack = NSMakeRect(0,0,third,kButtonCellHeight);
			NSRect monthToday = NSMakeRect(third,0,third,kButtonCellHeight);
			NSRect monthForward = NSMakeRect(bds.size.width-third,0,third,kButtonCellHeight);
			
			if ( NSPointInRect(mouseLoc,monthBack) ) {
				
				[monthBackCell setState:NSOnState];
				[self displayRect:monthBack];
				[monthBackCell trackMouse:[NSApp currentEvent] inRect:monthBack ofView:self untilMouseUp:NO];
				[monthBackCell setState:NSOffState];
				[self displayRect:monthBack];
			}
			
			else if ( NSPointInRect(mouseLoc,monthToday) ) {
				
				[monthTodayCell setState:NSOnState];
				[self displayRect:monthToday];
				[monthTodayCell trackMouse:[NSApp currentEvent] inRect:monthToday ofView:self untilMouseUp:NO];
				[monthTodayCell setState:NSOffState];
				[self displayRect:monthToday];
			}
			
			else if ( NSPointInRect(mouseLoc,monthForward) ) {
				
				[monthForwardCell setState:NSOnState];
				[self displayRect:monthForward];
				[monthForwardCell trackMouse:[NSApp currentEvent] inRect:monthForward ofView:self untilMouseUp:NO];
				[monthForwardCell setState:NSOffState];
				[self displayRect:monthForward];
			}
		}
		else
		{
		
			myX = mouseLoc.x - total_offset;
			myY = mouseLoc.y - 57;
			
			//I must know the day of the week, so construct a date and grab that information
			
			offset = [[NSCalendarDate dateWithYear:myYear month:myMonth day:1 
					hour:1 minute:1 second:1 timeZone:nil] dayOfWeek];
			
			//set up my offset, taking account that sunday is a 0 for the date but a 6 for me, while monday is a 0
			offset = offset - start_day;
			if ( offset < 0 ) offset += 7;

			for ( i = 0; i <= 6; i++ ) {
				if ( (myX >= i*kColWidth) && (myX < (i+1)*kColWidth) ) break;
			}
			for ( j = 0; j <= 6; j++ ) {
				if ( (myY >= j*kRowHeight) && (myY < (j+1)*kRowHeight) ) break;
			}
			
			if ( i <= 6 && j <= 6 )
			{
				dayHit = i+1 + j*7;
				dayHit = dayHit - offset;
				
				if ( dayHit > 0 && dayHit <= [Calendar lastDayOfMonth:myMonth year:myYear] )
					_dropDate = dayHit;
				else {
					_dropDate = -1;
					operation = NSDragOperationNone;
				}
			}
			else
			{
				_dropDate = -1;
				operation = NSDragOperationNone;
			}
		}
		
		[self setNeedsDisplayInRect:currentDragRect];
		if ( _dropDate != -1 )
		{
			currentDragRect = [self frameOfDateWithDay:dayHit month:myMonth year:myYear];
			[self setNeedsDisplayInRect:currentDragRect];
		}

	}
	
	return operation;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
	
	NSDragOperation operation = NSDragOperationNone;
	
	if ( [[[sender draggingPasteboard] types] containsObject:PDEntryIDPboardType] )
		operation = NSDragOperationLink;
	else
		operation = NSDragOperationCopy;
	
	if ( operation != NSDragOperationNone ) {
		
		//
		// determine the target date
		
		NSPoint mouseLoc;
		NSRect bds = [self bounds];
		
		int start_day = [[NSUserDefaults standardUserDefaults] integerForKey:@"CalendarStartDay"];
		int total_offset = kWidthOffset + ( bds.size.width/2 - kCalendarRequiredWidth/2 );
		int myX, myY, i, j, offset, dayHit;
		
		mouseLoc = [self convertPoint:[sender draggingLocation] fromView:nil];
		
		NSRect navRect = NSMakeRect(0,0,bds.size.width,kButtonCellHeight);
		
		// check to see if the user is clicking one of the buttons
		if ( NSPointInRect(mouseLoc,navRect) ) {
		
			operation = NSDragOperationNone;
			
			int third = ceil(bds.size.width / 3.0);
			
			NSRect monthBack = NSMakeRect(0,0,third,kButtonCellHeight);
			NSRect monthToday = NSMakeRect(third,0,third,kButtonCellHeight);
			NSRect monthForward = NSMakeRect(bds.size.width-third,0,third,kButtonCellHeight);
			
			if ( NSPointInRect(mouseLoc,monthBack) ) {
				
				[monthBackCell setState:NSOnState];
				[self displayRect:monthBack];
				[monthBackCell trackMouse:[NSApp currentEvent] inRect:monthBack ofView:self untilMouseUp:NO];
				[monthBackCell setState:NSOffState];
				[self displayRect:monthBack];
			}
			
			else if ( NSPointInRect(mouseLoc,monthToday) ) {
				
				[monthTodayCell setState:NSOnState];
				[self displayRect:monthToday];
				[monthTodayCell trackMouse:[NSApp currentEvent] inRect:monthToday ofView:self untilMouseUp:NO];
				[monthTodayCell setState:NSOffState];
				[self displayRect:monthToday];
			}
			
			else if ( NSPointInRect(mouseLoc,monthForward) ) {
				
				[monthForwardCell setState:NSOnState];
				[self displayRect:monthForward];
				[monthForwardCell trackMouse:[NSApp currentEvent] inRect:monthForward ofView:self untilMouseUp:NO];
				[monthForwardCell setState:NSOffState];
				[self displayRect:monthForward];
			}
		}
		
		else
		{
		
			myX = mouseLoc.x - total_offset;
			myY = mouseLoc.y - 57;
			
			//I must know the day of the week, so construct a date and grab that information
			
			offset = [[NSCalendarDate dateWithYear:myYear month:myMonth day:1 
					hour:1 minute:1 second:1 timeZone:nil] dayOfWeek];
			
			//set up my offset, taking account that sunday is a 0 for the date but a 6 for me, while monday is a 0
			offset = offset - start_day;
			if ( offset < 0 ) offset += 7;

			for ( i = 0; i <= 6; i++ ) {
				if ( (myX >= i*kColWidth) && (myX < (i+1)*kColWidth) ) break;
			}
			for ( j = 0; j <= 6; j++ ) {
				if ( (myY >= j*kRowHeight) && (myY < (j+1)*kRowHeight) ) break;
			}
			
			if ( i <= 6 && j <= 6 )
			{
				dayHit = i+1 + j*7;
				dayHit = dayHit - offset;
				
				if ( dayHit > 0 && dayHit <= [Calendar lastDayOfMonth:myMonth year:myYear] )
					_dropDate = dayHit;
				else {
					_dropDate = -1;
					operation = NSDragOperationNone;
				}
			}
			else
			{
				_dropDate = -1;
				operation = NSDragOperationNone;
			}
		}
		
		[self setNeedsDisplayInRect:currentDragRect];
		if ( _dropDate != -1 )
		{
			currentDragRect = [self frameOfDateWithDay:dayHit month:myMonth year:myYear];
			[self setNeedsDisplayInRect:currentDragRect];
		}

	}
	
	return operation;
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender 
{
	_dropDate = -1;
	[self setNeedsDisplayInRect:currentDragRect];
	currentDragRect = NSZeroRect;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender 
{
	_dropDate = -1;
	[self setNeedsDisplayInRect:currentDragRect];
	//currentDragRect = NSZeroRect;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender 
{
	_dropDate = -1;
	[self setNeedsDisplayInRect:currentDragRect];
	//currentDragRect = NSZeroRect;
}

#pragma mark -

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	
	BOOL success = NO;
	
	//
	// determine the target date
	
	NSPoint mouseLoc;
	NSRect bds = [self bounds];
	
	int start_day = [[NSUserDefaults standardUserDefaults] integerForKey:@"CalendarStartDay"];
	int total_offset = kWidthOffset + ( bds.size.width/2 - kCalendarRequiredWidth/2 );
	int myX, myY, i, j, offset, dayHit;
	
	mouseLoc = [self convertPoint:[sender draggingLocation] fromView:nil];
	
	myX = mouseLoc.x - total_offset;
	myY = mouseLoc.y - 57;
	
	//I must know the day of the week, so construct a date and grab that information
	
	offset = [[NSCalendarDate dateWithYear:myYear month:myMonth day:1 
			hour:1 minute:1 second:1 timeZone:nil] dayOfWeek];
	
	//set up my offset, taking account that sunday is a 0 for the date but a 6 for me, while monday is a 0
	offset = offset - start_day;
	if ( offset < 0 ) offset += 7;

	for ( i = 0; i <= 6; i++ ) {
		if ( (myX >= i*kColWidth) && (myX < (i+1)*kColWidth) ) break;
	}
	for ( j = 0; j <= 6; j++ ) {
		if ( (myY >= j*kRowHeight) && (myY < (j+1)*kRowHeight) ) break;
	}
	
	dayHit = i+1 + j*7;
	dayHit = dayHit - offset;
	
	if ( dayHit > 0 && dayHit <= [Calendar lastDayOfMonth:myMonth year:myYear] ) 
	{
		NSCalendarDate *jetzt = [NSCalendarDate calendarDate];
		NSCalendarDate *dropDate = [[[NSCalendarDate alloc] 
				initWithYear:myYear month:myMonth day:dayHit 
				hour:[jetzt hourOfDay] minute:[jetzt minuteOfHour] second:[jetzt secondOfMinute] timeZone:nil] autorelease];
		
		if ( [[[sender draggingPasteboard] types] containsObject:PDEntryIDPboardType] ) {
		
			// the entry ids as strings from the pboard
			NSArray *entryURIs = [[sender draggingPasteboard] propertyListForType:PDEntryIDPboardType];
			success = YES;
			
			int i;
			for ( i = 0; i < [entryURIs count]; i++ ) 
			{
				// conver the ids to actual entries
				NSString *absoluteString = [entryURIs objectAtIndex:i];
				NSURL *theURI = [NSURL URLWithString:absoluteString];
				
				JournlerEntry *anEntry = (JournlerEntry*)[[self valueForKeyPath:@"delegate.journal"] objectForURIRepresentation:theURI];
				if ( anEntry != nil )
				{
					[anEntry setValue:dropDate forKey:@"calDate"];
					[[anEntry journal] saveEntry:anEntry];
				}
				else
				{
					NSLog(@"%s - trouble converting entry uri to actual entry %@", __PRETTY_FUNCTION__, [theURI absoluteString]);
					success = NO;
				}
			}
			
		}
		else if ( [[[sender draggingPasteboard] types] containsObject:kMailMessagePboardType] )
		{
			success = YES;
			// perform the action after a delay so as not to screw up drop loop
			NSDictionary *objectDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
					[sender draggingPasteboard], @"pasteboard", 
					dropDate, @"dropDate", nil];
			
			[self performSelector:@selector(importPasteboardToDateWithDictionary:) withObject:objectDictionary afterDelay:0.1];
		}
		
		else
		{
			NSArray *pasteboardEntries = [[NSApp delegate] entriesForPasteboardData:[sender draggingPasteboard] visual:NO preferredTypes:nil];
			if ( pasteboardEntries == nil )
			{
				NSBeep();
				[[NSAlert pasteboardImportFailure] runModal];
				success = NO;
			}
			else
			{
				JournlerEntry *pasteboardEntry;
				NSEnumerator *enumerator = [pasteboardEntries objectEnumerator];
				while ( pasteboardEntry = [enumerator nextObject] )
				{
					[pasteboardEntry setValue:dropDate forKey:@"calDate"];
					[[self valueForKeyPath:@"delegate.journal"] saveEntry:pasteboardEntry];
				}
				success = YES;
			}

		}
	}
	else {
		NSBeep();
		success = NO;
	}

	// update the associated dates controller
	[dataSource updateSelectedObjects:self];
	[self updateDaysWithEntries];
	
	return success;
}

- (BOOL) importPasteboardToDateWithDictionary:(NSDictionary*)aDictionary
{
	// just pass it on to the appropriate handler
	BOOL success;
	NSCalendarDate *dropDate = [aDictionary objectForKey:@"dropdate"];
	NSPasteboard *pboard = [aDictionary objectForKey:@"pasteboard"];
	
	NSArray *pasteboardEntries = [[NSApp delegate] entriesForPasteboardData:pboard visual:NO preferredTypes:nil];
	if ( pasteboardEntries == nil )
	{
		NSBeep();
		[[NSAlert pasteboardImportFailure] runModal];
		success = NO;
	}
	else
	{
		JournlerEntry *pasteboardEntry;
		NSEnumerator *enumerator = [pasteboardEntries objectEnumerator];
		while ( pasteboardEntry = [enumerator nextObject] )
		{
			[pasteboardEntry setValue:dropDate forKey:@"calDate"];
			[[self valueForKeyPath:@"delegate.journal"] saveEntry:pasteboardEntry];
		}
		success = YES;
	}
	
	return success;
}

@end