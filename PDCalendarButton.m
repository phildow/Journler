//
//  PDCalendarButton.m
//  Journler
//
//  Created by Philip Dow on 7/15/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "PDCalendarButton.h"
#import "Definitions.h"

#import <SproutedUtilities/SproutedUtilities.h>

//static NSString *kABPeopleUIDsPboardType = @"ABPeopleUIDsPboardType";
//static NSString *kMailMessagePboardType = @"MV Super-secret message transfer pasteboard type";

@implementation PDCalendarButton

- (void) awakeFromNib {
	// how can I just register for everything under the sun?
	[self registerForDraggedTypes:[NSArray arrayWithObjects:
			kABPeopleUIDsPboardType, kMailMessagePboardType, NSFilenamesPboardType, WebURLsWithTitlesPboardType, NSURLPboardType,
			NSRTFDPboardType, NSRTFPboardType, NSStringPboardType, NSTIFFPboardType, NSPICTPboardType,
			PDFolderIDPboardType, PDEntryIDPboardType, PDResourceIDPboardType, nil]];
}

- (id) delegate { return _delegate; }

- (void) setDelegate:(NSObject*)anObject {
	_delegate = anObject;
}

- (id) target
{
	return target;
}

- (void) setTarget:(id)anObject
{
	target = anObject;
}

- (SEL) action
{
	return action;
}

- (void) setAction:(SEL)aSelector
{
	action = aSelector;
}

#pragma mark -

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	
	if ( [_delegate respondsToSelector:@selector(calendarButtonDraggingEntered:)] )
		[_delegate calendarButtonDraggingEntered:self];
		
	return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
	
	return NSDragOperationNone;
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender {
	
	if ( [_delegate respondsToSelector:@selector(calendarButtonDraggingExited:)] )
		[_delegate calendarButtonDraggingEnded:self];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
	
	//if ( [_delegate respondsToSelector:@selector(calendarButtonDraggingExited:)] )
	//	[_delegate calendarButtonDraggingExited:self];
}

#pragma mark -

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	
	return NO;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	
	return NO;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
	
}

#pragma mark -

- (void)mouseDown:(NSEvent *)theEvent
{
	if ( [[self target] respondsToSelector:[self action]] )
		[[self target] performSelector:[self action] withObject:self];
}

@end
