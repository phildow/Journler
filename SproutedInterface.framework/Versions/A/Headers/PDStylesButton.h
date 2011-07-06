//
//  PDStylesButton.h
//  Journler
//
//  Created by Philip Dow on 5/1/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PDStylesButtonCell;

@interface PDStylesButton : NSButton {

}

- (int) superscriptValue;
- (void) setSuperscriptValue:(int)offset;

@end
