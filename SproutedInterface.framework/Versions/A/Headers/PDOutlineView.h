//
//  PDOutlineView.h
//  Journler
//
//  Created by Phil Dow on 2/1/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PDOutlineView : NSOutlineView {

}

@end

@interface NSObject (PDOutlineViewDelegate)

- (void) outlineView:(NSOutlineView*)anOutlineView leftNavigationEvent:(NSEvent*)anEvent;
- (void) outlineView:(NSOutlineView*)anOutlineView rightNavigationEvent:(NSEvent*)anEvent;

@end