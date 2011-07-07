//
//  EntryFilterController.m
//  Journler
//
//  Created by Philip Dow on 5/22/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import "EntryFilterController.h"
#import "JournlerCondition.h"
#import "JournlerConditionController.h"

#import <SproutedInterface/SproutedInterface.h>
//#import "CollectionManagerView.h"

@implementation EntryFilterController

- (id) init 
{
	return [self initWithDelegate:nil];
}

- (id) initWithDelegate:(id)anObject
{
	if ( self = [super init] )
	{
		
		delegate = anObject;
		
		_conditions = [[NSMutableArray alloc] init];
		
		_filters = [[CollectionManagerView alloc] initWithFrame:NSMakeRect(0,0,600,kConditionViewHeight)];
		[_filters setAutoresizingMask:(NSViewWidthSizable|NSViewMinYMargin)];
		[_filters setBordered:NO];
		
		// add a single condition to our view
		JournlerConditionController *initialCondition = [[JournlerConditionController alloc] initWithTarget:self];
		
		[initialCondition setSendsLiveUpdate:YES];
		[initialCondition setAutogeneratesDynamicDates:YES];
		[initialCondition setRemoveButtonEnabled:NO];
		[_conditions addObject:initialCondition];
		
		[initialCondition release];
		
		[_filters setNumConditions:1];
		[self updateConditionsView];
	}
	
	return self;
}

- (void) dealloc 
{
	[_conditions release];
	[_filters release];
	[tagCompletions release];
	
	[super dealloc];	
}

#pragma mark -

- (NSView*) contentView 
{
	return _filters;
}

- (id) delegate
{
	return delegate;
}

- (void) setDelegate:(id)anObject
{
	delegate = anObject;
}

- (NSArray*) tagCompletions
{
	return tagCompletions;
}

- (void) setTagCompletions:(NSArray*)anArray
{
	if ( tagCompletions != anArray )
	{
		[tagCompletions release];
		tagCompletions = [anArray copyWithZone:[self zone]];
	}
}

#pragma mark -
#pragma mark Delegate Methods

- (void) conditionDidChange:(id)condition 
{	
	if ( [self delegate] && [[self delegate] respondsToSelector:@selector(entryFilterController:predicateDidChange:)] ) {
		
		//
		// rebuild the predicate and send it
		int i;
		
		NSMutableString *predicateString;
		NSString *firstPredicateString = [[_conditions objectAtIndex:0] predicateString];
		if ( firstPredicateString )
		{
			// does this string involve tags? if so normalize them
			if ( [firstPredicateString rangeOfString:@"in tags" options:NSBackwardsSearch].location == ( [firstPredicateString length] - 7 ) )
				firstPredicateString = [JournlerCondition normalizedTagCondition:firstPredicateString];

			predicateString = [firstPredicateString mutableCopyWithZone:[self zone]];
		}
		else
			predicateString = [[NSMutableString alloc] init];
			
		for ( i = 1; i < [_conditions count]; i++ ) 
		{
			NSString *append_string = [[_conditions objectAtIndex:i] predicateString];
			
			// does this string involve tags? if so normalize them
			if ( [append_string rangeOfString:@"in tags" options:NSBackwardsSearch].location == ( [append_string length] - 7 ) )
				append_string = [JournlerCondition normalizedTagCondition:append_string];
			
			if ( append_string != nil ) [predicateString appendString:[NSString stringWithFormat:@" AND %@", append_string]];
		}
		
		NSPredicate *predicate = ( [predicateString length] != 0 ? [NSPredicate predicateWithFormat:predicateString] : nil );
		[[self delegate] entryFilterController:self predicateDidChange:predicate];
		[predicateString release];
	}
	
	// update the keyview loop
	[self updateKeyViewLoop];
}

- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring 
	indexOfToken:(int)tokenIndex indexOfSelectedItem:(int *)selectedIndex
{
	NSArray *theCompletions = nil;
	
	if ( [[self delegate] respondsToSelector:@selector(tokenField:completionsForSubstring:indexOfToken:indexOfSelectedItem:)] )
		theCompletions = [[self delegate] tokenField:tokenField completionsForSubstring:substring indexOfToken:tokenIndex indexOfSelectedItem:selectedIndex];
	
	return theCompletions;
}

#pragma mark -

- (void) updateConditionsView 
{
	
	int i;
	
	// note the current first responder
	NSResponder *currentResponder = [[_filters window] firstResponder];
	if ( [currentResponder isKindOfClass:[NSWindow class]] || currentResponder == nil )
		currentResponder = ( [_conditions count] > 0 ? [[_conditions objectAtIndex:0] selectableView] : currentResponder );
	else if ( [currentResponder isKindOfClass:[NSTextView class]] && [[_filters window] fieldEditor:NO forObject:nil] != nil )
		currentResponder = [(NSTextView*)currentResponder delegate];
	
	// make sure the predicates view knows how many rows to draw
	[_filters setNumConditions:[_conditions count]];
	
	// remove all the subviews
	for ( i = 0; i < [[_filters subviews] count]; i++ )
		[[[_filters subviews] objectAtIndex:i] removeFromSuperviewWithoutNeedingDisplay];
	
	// and add what's left or more according to our internal array
	for ( i = 0; i < [_conditions count]; i++ ) 
	{
		JournlerConditionController *aCondition = [_conditions objectAtIndex:i];
		
		// reset the tag on each of these guys
		[aCondition setTag:i];
		
		// add the condition's view to our predicates view and position it
		[_filters addSubview:[aCondition conditionView]];
		[[aCondition conditionView] setFrameOrigin:NSMakePoint(0,(i*kConditionViewHeight)+1)];
		[[aCondition conditionView] setFrameSize:NSMakeSize([_filters frame].size.width, kConditionViewHeight)];
		
	}
	
	// make sure the predicates view knows to redraw itself, love those alternating rows
	[_filters setNeedsDisplay:YES];
	
	// update the keyview loop
	[self updateKeyViewLoop];
	
	// re-establish the first responder
	[[_filters window] makeFirstResponder:currentResponder]; 
}

- (void) updateKeyViewLoop
{
	// for manually recalculating the keyview loop
	// this hijacks the keyview loop
	
	NSView *firstView = ( [_conditions count] > 0 ? [[_conditions objectAtIndex:0] selectableView] : nil );
	NSView *lastView = ( [_conditions count] > 0 ? [[_conditions lastObject] selectableView] : nil );
	NSView *lastInResponderLoop = firstView;
	
	int i;
	// and add what's left or more according to our internal array
	for ( i = 1; i < [_conditions count]; i++ ) 
	{
		JournlerConditionController *aCondition = [_conditions objectAtIndex:i];
		if ( [aCondition selectableView] != nil ) {
			// insert this to the responder chain
			[lastInResponderLoop setNextKeyView:[aCondition selectableView]];
			lastInResponderLoop = [aCondition selectableView];
		}
	}
	
	// complete the loop
	[lastView setNextKeyView:firstView];
}

#pragma mark -

- (void) addCondition:(id)sender {
	
	//
	// resize the window positive by our condition view height
	// and add a new condition to our view
	//
	
	// add a new condition to our view
	JournlerConditionController *aCondition = [[JournlerConditionController alloc] initWithTarget:self];
	[aCondition setSendsLiveUpdate:YES];
	[aCondition setAutogeneratesDynamicDates:YES];
	
	if ( sender == self )
		[_conditions addObject:aCondition];
	else
		[_conditions insertObject:aCondition atIndex:[sender tag]+1];

	// clean up - okay because the array now has ownership of this guy
	[aCondition release];

	// update our display
	[self updateConditionsView];
	
	// and resize
	if ( sender != self ) {
	
		NSRect contentRect = [_filters frame];
		int newHeight = contentRect.size.height + kConditionViewHeight;
		
		contentRect.origin.y = contentRect.origin.y + contentRect.size.height - newHeight;
		contentRect.size.height = newHeight;
		
		[_filters setFrame:contentRect];
	
	}
	
	[self conditionDidChange:nil];
	
	if ( [[self delegate] respondsToSelector:@selector(entryFilterController:frameDidChange:)] )
		[[self delegate] entryFilterController:self frameDidChange:[[self contentView] frame]];
}

- (void) removeCondition:(id)sender {
	
	//
	// resize the window negative by our condition view height
	// and remove the condition at the index of this tag
	//
	
		
	// get rid of the subview first
	[[[_conditions objectAtIndex:[sender tag]] conditionView] removeFromSuperviewWithoutNeedingDisplay];
	
	// and the condition second
	[_conditions removeObjectAtIndex:[sender tag]];
	
	// update the conditions view, this subview already removed
	[self updateConditionsView];
	
	// resize the window and the conditions view with it
	//int newHeight = [[self window] frame].size.height - kConditionViewHeight;

	NSRect contentRect = [_filters frame];
	
	int newHeight = contentRect.size.height - kConditionViewHeight;
	
	contentRect.origin.y = contentRect.origin.y + contentRect.size.height - newHeight;
	contentRect.size.height = newHeight;
	
	[_filters setFrame:contentRect];
	
	[self conditionDidChange:nil];
	
	if ( [[self delegate] respondsToSelector:@selector(entryFilterController:frameDidChange:)] )
		[[self delegate] entryFilterController:self frameDidChange:[[self contentView] frame]];
}

- (NSArray*) conditions { 
	
	int i;
	NSMutableArray *allPredicates = [[NSMutableArray alloc] init];
	
	for ( i = 0; i < [_conditions count]; i++ ) {
		NSString *aPredicateString = [[_conditions objectAtIndex:i] predicateString];
		if ( aPredicateString != nil ) [allPredicates addObject:aPredicateString];
	}
	
	return [allPredicates autorelease];

}

#pragma mark -

- (void) appropriateFirstResponder:(NSWindow*)aWindow
{
	if ( [_conditions count] != 0 )
		[[_conditions objectAtIndex:0] appropriateFirstResponder:aWindow];
}

@end
