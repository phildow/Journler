//
//  IndividualLabelView.h
//  Journler
//
//  Created by Philip Dow on 4/18/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IndividualLabelView : NSView {
	
	NSInteger tag;
}

- (NSInteger) tag;
- (void) setTag:(NSInteger)aTag;

@end
