//
//  PDHorizontallyCenteredText.h
//  Lex
//
//  Created by Phil Dow on 6/19/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PDHorizontallyCenteredText : NSTextFieldCell {
	
	BOOL selected;
	BOOL boldsWhenSelected;
}

- (BOOL) isSelected;
- (void) setSelected:(BOOL)isSelected;

- (BOOL) boldsWhenSelected;
- (void) setBoldsWhenSelected:(BOOL)doesBold;

@end
