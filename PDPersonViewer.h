//
//  CustomView.h
//  PeoplePickerTest
//
//  Created by Philip Dow on 10/18/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AddressBook/AddressBook.h>

@class PDPersonPropertyField;

@interface PDPersonViewer : NSView {
	
	ABPerson *person;
	NSMutableArray *propertyFields;
	NSMutableArray *trackingRects;
	
	BOOL drawsNoteRule;
	float noteRuleHeight;
	
	NSColor *backgroundColor;
	BOOL drawsBackground;
	
	id target;
	SEL action;
}

- (ABPerson*) person;
- (void) setPerson:(ABPerson*)aPerson;

- (id) target;
- (void) setTarget:(id)anObject;

- (SEL) action;
- (void) setAction:(SEL)selector;

- (BOOL) drawsBackground;
- (void) setDrawsBackground:(BOOL)draws;

- (NSColor*) backgroundColor;
- (void) setBackgroundColor:(NSColor*)aColor;

- (void) boundsChanged:(NSNotification*)aNotification;

- (void) updatePropertyFields;
- (void) updatePropertyFieldLocations;

- (PDPersonPropertyField*) newPropertyFieldWithFrame:(NSRect)frame property:(NSString*)property 
		label:(NSString*)label content:(NSString*)content target:(NSObject*)aTarget action:(SEL)aSelector;

- (IBAction) showFieldMenu:(id)sender;

@end
