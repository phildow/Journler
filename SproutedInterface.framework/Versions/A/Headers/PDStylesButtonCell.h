//
//  PDStylesButtonCell.h
//  Journler
//
//  Created by Philip Dow on 5/1/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PDStylesButtonCell : NSButtonCell {
	
	int _superscriptValue;
}

- (int) superscriptValue;
- (void) setSuperscriptValue:(int)offset;

@end
