//
//  PDDatePicker.m
//  Journler
//
//  Created by Philip Dow on 6/26/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import "PDDatePicker.h"


@implementation PDDatePicker

/*
// Doesn't produce desired results - should send action method only on return
- (id) initWithCoder:(NSCoder*)aCoder
{
	if ( self = [super initWithCoder:aCoder] )
	{
		[[self cell] setSendsActionOnEndEditing:NO];
	}
	return self;
}

- (id) initWithFrame:(NSRect)aFrame
{
	if ( self = [super initWithFrame:aFrame] )
	{
		[[self cell] setSendsActionOnEndEditing:NO];
	}
	return self;
}
*/

/*
- copyWithZone:(NSZone *)zone {
    
	PDDatePicker *datePicker = (PDDatePicker *)[super copyWithZone:zone];
   
	[datePicker setEnterOnlyAction:[self enterOnlyAction]];
	[datePicker setEnterOnlyTarget:[self enterOnlyTarget]];
		
    return datePicker;
}
*/

#pragma mark -

- (id) enterOnlyTarget
{
	return enterOnlyTarget;
}

- (void) setEnterOnlyTarget:(id)anObject
{
	enterOnlyTarget = anObject;
}

- (SEL) enterOnlyAction
{
	return enterOnlyAction;
}

- (void) setEnterOnlyAction:(SEL)aSelector
{
	enterOnlyAction = aSelector;
}

#pragma mark -

- (void) keyDown:(NSEvent *)theEvent
{
	NSString *characters = [theEvent charactersIgnoringModifiers];
	if ( [self enterOnlyTarget] != nil && [characters length] > 0 
		&& ( [characters characterAtIndex:0] == NSEnterCharacter || [characters characterAtIndex:0] == NSCarriageReturnCharacter ) )
		[[self enterOnlyTarget] performSelector:[self enterOnlyAction] withObject:self];
	else
		[super keyDown:theEvent];
}

@end
