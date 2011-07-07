//
//  PDPersonPropertyCell.h
//  PeoplePickerTest
//
//  Created by Philip Dow on 10/18/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PDPersonPropertyCell : NSTextFieldCell {

	NSString *label;
	NSString *content;
	
	NSDictionary *labelAttributes;
	NSDictionary *labelHighlightedAttributes;
	NSDictionary *contentAttributes;
	
	//NSAttributedString *attributedLabel;
	NSAttributedString *attributedContent;
	
	float margin;
	
	NSTextStorage *textStorage;
	NSTextContainer *textContainer;
	NSLayoutManager *layoutManager;
	
	NSString *property;
}

- (float) margin;
- (void) setMargin:(float)value;

- (NSString*) property;
- (void) setProperty:(NSString*)key;

- (NSSize) cellSizeWithWidth:(float)maxWidth;

- (NSString*) label;
- (void) setLabel:(NSString*)aString;

- (NSString*) content;
- (void) setContent:(NSString*)aString;

//- (NSAttributedString*) attributedLabel;
//- (void) setAttributedLabel:(NSAttributedString*)anAttributedString;

- (NSAttributedString*) attributedContent;
- (void) setAttributedContent:(NSAttributedString*)anAttributedString;


- (NSRect) labelBoundsForCellFrame:(NSRect)cellFrame;
- (NSRect) contentBoundsForCellFrame:(NSRect)cellFrame;

@end
