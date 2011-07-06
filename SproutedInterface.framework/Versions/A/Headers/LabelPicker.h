//
//  LabelPicker.h
//  Cocoa Journler
//
//  Created by Philip Dow on 11/12/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LabelPicker : NSView {
	
	int		_tag;
	
	id		_target;
	SEL		_selector;
	
	NSImage *_labelImage;
	NSImage *_labelSelectedImage;
	NSImage *_labelHoverImage;
	
	int _labelSelection;
	
	NSRect	_clearRect;
	NSRect	_redRect;
	NSRect	_orangeRect;
	NSRect	_yellowRect;
	NSRect	_greenRect;
	NSRect	_blueRect;
	NSRect	_purpleRect;
	NSRect	_greyRect;
	
}

- (int) tag;
- (void) setTag:(int)aTag;

- (id) target;
- (void) setTarget:(id)targetObject;

- (SEL) action;
- (void) setAction:(SEL)targetSelector;

- (int) labelSelection;
- (void) setLabelSelection:(int)value;

+ (int) finderEquivalentForPickerLabel:(int)value;
+ (int) pickerEquivalentForFinderLabel:(int)value;

@end
