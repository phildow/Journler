//
//  IndividualLabelView.h
//  Journler
//
//  Created by Phil Dow on 4/18/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IndividualLabelView : NSView {
	
	int tag;
}

- (int) tag;
- (void) setTag:(int)aTag;

@end
