//
//  PDDatePicker.h
//  Journler
//
//  Created by Philip Dow on 6/26/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PDDatePicker : NSDatePicker {
	
	id enterOnlyTarget;
	SEL enterOnlyAction;
}

- (id) enterOnlyTarget;
- (void) setEnterOnlyTarget:(id)anObject;

- (SEL) enterOnlyAction;
- (void) setEnterOnlyAction:(SEL)aSelector;

@end
