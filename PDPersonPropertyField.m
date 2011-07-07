//
//  PDPersonPropertyField.m
//  PeoplePickerTest
//
//  Created by Philip Dow on 10/19/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import "PDPersonPropertyField.h"
#import "PDPersonPropertyCell.h"

@implementation PDPersonPropertyField

- (id)initWithFrame:(NSRect)frameRect {
	
	if ( self = [super initWithFrame:frameRect] ) {
		[self setDrawsBackground:NO];
		[self setBezeled:NO];
		[self setBordered:NO];
		[self setEditable:NO];
		[self setSelectable:NO];
		[self setEnabled:YES];
		[self setAutoresizingMask:NSViewWidthSizable];
		
		//[self sendActionOn:NSLeftMouseDown];
	}
	
	return self;
}

+ (Class)cellClass {
	return [PDPersonPropertyCell class];
}	

#pragma mark -

- (NSString*) property {
	return [[self cell] property];
}

- (void) setProperty:(NSString*)key {
	[[self cell] setProperty:key];
}

- (NSString*) label {
	return [[self cell] label];
}

- (void) setLabel:(NSString*)aString {
	[[self cell] setLabel:aString];
}

- (NSString*) content {
	return [[self cell] content];
}

- (void) setContent:(NSString*)aString {
	[[self cell] setContent:aString];
}

#pragma mark -

- (NSEvent*) menuEvent {
	return menuEvent;
}

- (void)mouseDown:(NSEvent *)theEvent {
	
	// test to make sure the mouse down is in our label area
	NSPoint local_point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	if ( [self mouse:local_point inRect:[[self cell] labelBoundsForCellFrame:[self bounds]]] )
	{
		menuEvent = [theEvent retain];
		[[self target] performSelector:[self action] withObject:self];
		[menuEvent release];
	}
	
}

- (BOOL) pointDoesHighlight:(NSPoint)aPoint {
	if ( NSPointInRect(aPoint,[[self cell] labelBoundsForCellFrame:[self frame]]) )
		return YES;
	else if ( NSPointInRect(aPoint,[[self cell] contentBoundsForCellFrame:[self frame]]) )
		return YES;
	else
		return NO;
}

#pragma mark -

@end
