
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
	NSLog(@"%s",__PRETTY_FUNCTION__);
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
	NSLog(@"%s",__PRETTY_FUNCTION__);
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
