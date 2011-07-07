//
//  IndexLetterView.h
//  Journler
//
//  Created by Philip Dow on 1/31/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IndexLetterView : NSView {
	
	NSString *letters;
	NSShadow *textShadow;
	NSFont *font;
	
	id target;
	SEL action;
	NSRange selectionRange;
}

+ (NSString*) englishLetters;

- (NSString*) letters;
- (void) setLetters:(NSString*)aString;

- (NSString*) selectedLetter;

- (NSFont*) font;
- (void) setFont:(NSFont*)aFont;

- (id) target;
- (void) setTarget:(id)anObject;

- (SEL) action;
- (void) setAction:(SEL)anAction;

- (float) requiredWidthForFont:(NSFont*)aFont;

@end
