//
//  DropBoxTable.m
//  Journler
//
//  Created by Phil Dow on 3/16/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "DropBoxTable.h"


@implementation DropBoxTable

/*
- (BOOL)isOpaque
{
	return NO;
}
*/

/*
- (void)drawRect:(NSRect)aRect
{
	[[NSColor clearColor] set];
	NSRectFill(aRect);
	
	[super drawRect:aRect];
}
*/

- (BOOL)needsPanelToBecomeKey
{
	return YES;
}

- (void) textDidEndEditing: (NSNotification *) notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSNumber *textMovement = [userInfo objectForKey: @"NSTextMovement"];
	
    int movementCode = [textMovement intValue];

    // see if this a 'pressed-return' instance
    if (movementCode == NSReturnTextMovement && [self numberOfRows] == 1 ) 
	{
        // hijack the notification and pass a different textMovement
        // value

        textMovement = [NSNumber numberWithInt: NSCancelTextMovement];
        NSDictionary *newUserInfo = [NSDictionary dictionaryWithObject: textMovement forKey: @"NSTextMovement"];
        notification = [NSNotification notificationWithName: [notification name] object: [notification object] userInfo: newUserInfo];
		
		[super textDidEndEditing: notification];
    }
	else 
	{
		// if its not the return, ie the tab instead, the change should be made only after the call to super
		[super textDidEndEditing: notification];
	}
}

- (BOOL)becomeFirstResponder
{
	BOOL became = [super becomeFirstResponder];
	if ( became == YES && [self selectedRow] == -1 && [self numberOfRows] != 0 )
		[self selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        //[self selectRow:0 byExtendingSelection:NO]; DEPRECATED
	
	return became;
}

- (void)keyDown:(NSEvent *)event 
{ 
	static unichar kUnicharKeyReturn = '\r';
	static unichar kUnicharKeyNewline = '\n';
	
	unsigned int flags = [event modifierFlags];
	unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];

	if ( [event keyCode] == 53 )
		[[self window] keyDown:event];
		
	else if ( ( key == kUnicharKeyReturn || key == kUnicharKeyNewline ) )
	{
		if ( ( flags & NSShiftKeyMask ) && [self selectedRow] != -1 )
			[self editColumn:0 row:[self selectedRow] withEvent:event select:YES];
		else
			[[self window] keyDown:event];
	} 
	else
		[super keyDown:event];
}

@end
