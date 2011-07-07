//
//  PDPersonPropertyField.h
//  PeoplePickerTest
//
//  Created by Philip Dow on 10/19/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PDPersonPropertyField : NSTextField {
	NSEvent *menuEvent;
}

- (NSEvent*) menuEvent;

- (NSString*) property;
- (void) setProperty:(NSString*)key;

- (NSString*) label;
- (void) setLabel:(NSString*)aString;

- (NSString*) content;
- (void) setContent:(NSString*)aString;

- (BOOL) pointDoesHighlight:(NSPoint)aPoint;

@end
