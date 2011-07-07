//
//  IndexOutlineScrollView.m
//  Journler
//
//  Created by Philip Dow on 2/7/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "IndexOutlineScrollView.h"


@implementation IndexOutlineScrollView

- (void)scrollWheel:(NSEvent *)theEvent
{
	[super scrollWheel:theEvent];
	if ( [self superview] != nil )
		[[self superview] scrollWheel:theEvent];
}

@end
