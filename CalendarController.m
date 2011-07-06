#import "CalendarController.h"
#import "PDCalendarButton.h"

#import <SproutedInterface/SproutedInterface.h>

/*
#import "PDGradientView.h"
#import "JournlerGradientView.h"
*/

@implementation CalendarController

- (id) init
{
	if ( self = [super init] )
	{
		_closeTag = -1;
		_dragTag = -1;
		
		usesSmallCalendar = NO; // to be explicit about it
		textColor = [[NSColor blackColor] retain];
		textFont = [[NSFont systemFontOfSize:11] retain];
		[NSBundle loadNibNamed:@"CalendarControl" owner:self];
	}
	
	return self;
}

- (void) awakeFromNib
{	
	
	[datePicker bind:@"value" toObject:calendar withKeyPath:@"selectedDate" options:nil];
	[dateField bind:@"value" toObject:calendar withKeyPath:@"selectedDate" options:nil];
	
	[datePicker setDrawsBackground:NO];
	[datePicker setBackgroundColor:[NSColor colorWithCalibratedRed:231/255.0 green:237/255.0 blue:246/255.0 alpha:1.0]];
	[datePicker setFocusRingType:NSFocusRingTypeExterior];
	[datePicker setBordered:NO];
	[[datePicker cell] setControlSize:NSSmallControlSize];
	
	[datePickerContainer setUsesBezierPath:YES];
	[datePickerContainer setDrawsGradient:NO];
	
	[datePickerContainer bind:@"backgroundColor" toObject:[NSUserDefaultsController sharedUserDefaultsController] 
			withKeyPath:@"values.FolderBackgroundColor" options:[NSDictionary dictionaryWithObjectsAndKeys:
			@"NSUnarchiveFromData", NSValueTransformerNameBindingOption,
			[NSColor colorWithCalibratedHue:234.0/400.0 saturation:1.0/100.0 brightness:97.0/100.0 alpha:1.0], NSNullPlaceholderBindingOption, nil]];
	
	[calendarButton setDelegate:self];
	[calendarButton setTarget:calendar];
	[calendarButton setAction:@selector(toToday:)];
	
	[self setHighlighted:NO];
}

- (void) dealloc
{
	#ifdef __DEBUG__
	NSLog(@"%@ %s",[self className],_cmd);
	#endif
	
	[contextMenu release];
	[calendar release];
	[datePickerContainer release];
	
	if ( _calWin != nil )
	{
		[_calWin release];
		[calendar removeTrackingRect:_closeTag];
	}
	
	[super dealloc];
}

- (void) ownerWillClose:(NSNotification*)aNotification
{
	#ifdef __DEBUG__
	NSLog(@"%@ %s",[self className],_cmd);
	#endif
	
	[datePicker unbind:@"value"];
	[dateField unbind:@"value"];
	
	[objectController unbind:@"contentObject"];
	[objectController setContent:nil];
}

- (Calendar*) calendar
{
	return calendar;
}

- (NSView*) datePickerContainer
{
	return datePickerContainer;
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

#pragma mark -

- (NSColor*) textColor
{
	return textColor;
}

- (void) setTextColor:(NSColor*)aColor
{
	if ( textColor != aColor )
	{
		[textColor release];
		textColor = [aColor copyWithZone:[self zone]];
	}
}

- (NSFont*) textFont
{
	return textFont;
}

- (void) setTextFont:(NSFont*)aFont
{
	if ( textFont != aFont )
	{
		[textFont release];
		textFont = [aFont copyWithZone:[self zone]];
	}
}

#pragma mark -

- (BOOL) highlighted
{
	return highlighted;
}

- (void) setHighlighted:(BOOL)highlight
{
	highlighted = highlight;
	
	// take care of some business
	[calendar setHighlighted:highlighted];
		
}

- (BOOL) usesSmallCalendar
{
	return usesSmallCalendar;
}

- (void) setUsesSmallCalendar:(BOOL)smallCalendar
{
	if ( usesSmallCalendar != smallCalendar )
	{
		usesSmallCalendar = smallCalendar;
		
		// whatever happens, remove the calendar from the superview
		[calendar removeFromSuperview];
		
		if ( usesSmallCalendar )
		{
			// switch to the small calendar
			[datePickerContainer removeFromSuperview];
			[calendar setBackgroundColor:[NSColor whiteColor]];
		}
		else
		{
			// switch to the big view
			
			if ( _closeTag != -1 )
			{
				[calendar removeTrackingRect:_closeTag];
				_closeTag = -1;
			}
			
			if ( _dragTag != -1 )
			{
				[datePickerContainer removeTrackingRect:_dragTag];
				_dragTag = -1;
			}
			
			if ( _calWin != nil )
			{
				[_calWin orderOut:self];
				[_calWin release];
				_calWin = nil;
			}
			
			[calendar setBackgroundColor:[NSColor whiteColor]];
		}
	}
}

- (void) finalizeCalendarSizeChange:(BOOL)isSmall
{
	if ( isSmall )
	{
		_dragTag = [datePickerContainer addTrackingRect:[calendarButton frame] owner:self userData:NULL assumeInside:NO];
	}
}

- (IBAction) toggleSmallCalendar:(id)sender
{
	// change it at the defaults level so that every listener gets the message
	BOOL alreadySmall = [[NSUserDefaults standardUserDefaults] boolForKey:@"CalendarUseButton"];
	[[NSUserDefaults standardUserDefaults] setBool:!alreadySmall forKey:@"CalendarUseButton"];
}

#pragma mark -

- (IBAction) discloseCalendar:(id)sender
{
	//build the window if it is nil
	if ( _calWin == nil ) 
	{
		NSPoint TL = NSMakePoint( [datePickerContainer frame].origin.x, [datePickerContainer frame].origin.y );
		NSRect calRect = [calendar bounds];
		
		NSPoint baseTL = [datePicker convertPoint:TL toView:nil];
		NSPoint screenTL = [[datePicker window] convertBaseToScreen:baseTL];
		NSRect contentRect = NSMakeRect( screenTL.x - 32, screenTL.y - calRect.size.height, 
				calRect.size.width, calRect.size.height);
		
		_calWin = [[NSWindow alloc] initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
		
		[_calWin setReleasedWhenClosed:NO];
		[_calWin setLevel:NSPopUpMenuWindowLevel];
		[_calWin setHasShadow:YES];
		[_calWin setAlphaValue:0.98];
		[_calWin setContentView:calendar];
		
		[calendar setDrawsBorder:NO];
		_closeTag = [calendar addTrackingRect:NSInsetRect([calendar bounds],0.0,0.0) owner:self userData:nil assumeInside:YES];
	}
	
	if ( [sender state] == NSOnState )
	{
		[_calWin makeKeyAndOrderFront:self];
		//[_calWin invalidateCursorRectsForView:calendar];
		[_calWin resetCursorRects];
	}
	else
	{
		[_calWin orderOut:self];
	}
}

- (void)mouseEntered:(NSEvent *)theEvent
{ 
	if ( [theEvent trackingNumber] == _dragTag )
	{
		[discloseButton setState:NSOnState];
		[self discloseCalendar:discloseButton];
	}
}

- (void)mouseExited:(NSEvent *)theEvent 
{
	if ( [theEvent trackingNumber] == _closeTag )
	{
		[_calWin orderOut:self];
		[discloseButton setState:NSOffState];
	}
}

#pragma mark -

- (void) calendarButtonDraggingEntered:(PDCalendarButton*)aButton
{
	[discloseButton setState:NSOnState];
	[self discloseCalendar:discloseButton];
}

- (void) calendarButtonDraggingEnded:(PDCalendarButton*)aButton
{
	[discloseButton setState:NSOffState];
	[self discloseCalendar:discloseButton];
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	BOOL enabled = YES;
	SEL action = [menuItem action];
	
	if ( action == @selector(toggleSmallCalendar:) )
		[menuItem setState: ( [[NSUserDefaults standardUserDefaults] boolForKey:@"CalendarUseButton"] ? NSOnState : NSOffState )];
	
	return enabled;
}

@end
