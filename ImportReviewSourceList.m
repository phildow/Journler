//
//  ImportReviewSourceList.m
//  Journler
//
//  Created by Philip Dow on 1/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ImportReviewSourceList.h"


@implementation ImportReviewSourceList

- (void) dealloc
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	[super dealloc];
}

- (void)keyDown:(NSEvent *)event 
{ 
	//static unichar kUnicharKeyReturn = '\r';
	//static unichar kUnicharKeyNewline = '\n';
	
	unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];
	
	if (key == NSDeleteCharacter && [self numberOfRows] > 0 && [self selectedRow] != -1) 
	{ 
		// request a delete from the delegate
		if ( [[self delegate] respondsToSelector:@selector(importReviewSourceList:deleteFolders:)] )
			[[self delegate] importReviewSourceList:self deleteFolders:nil];
    }
	else
	{
		[super keyDown:event];
	}
}


@end
