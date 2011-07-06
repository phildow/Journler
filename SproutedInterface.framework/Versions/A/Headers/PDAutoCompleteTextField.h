//
//  PDAutoCompleteTextField.h
//  Cocoa Journler
//
//  Created by Philip Dow on 7/10/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PDAutoCompleteTextField : NSTextField {
	NSArray		*autoCompleteOptions;
}

- (NSArray*) autoCompleteOptions;
- (void) setAutoCompleteOptions:(NSArray*)options;

@end
