//
//  PDCalendarButton.h
//  Journler
//
//  Created by Philip Dow on 7/15/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PDCalendarButton : NSImageView {
	id _delegate;
	
	id target;
	SEL action;
}

- (id) delegate;
- (void) setDelegate:(NSObject*)anObject;

- (id) target;
- (void) setTarget:(id)anObject;

- (SEL) action;
- (void) setAction:(SEL)aSelector;

@end

@interface NSObject (PDCalendarButtonDelegate)

- (void) calendarButtonDraggingEntered:(PDCalendarButton*)aButton;
- (void) calendarButtonDraggingEnded:(PDCalendarButton*)aButton;

@end