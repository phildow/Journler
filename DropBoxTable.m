//
//  DropBoxTable.m
//  Journler
//
//  Created by Philip Dow on 3/16/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

/*
 Redistribution and use in source and binary forms, with or without modification, are permitted
 provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions
 and the following disclaimer in the documentation and/or other materials provided with the
 distribution.
 
 * Neither the name of the author nor the names of its contributors may be used to endorse or
 promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// Basically, you can use the code in your free, commercial, private and public projects
// as long as you include the above notice and attribute the code to Philip Dow / Sprouted
// If you use this code in an app send me a note. I'd love to know how the code is used.

// Please also note that this copyright does not supersede any other copyrights applicable to
// open source code used herein. While explicit credit has been given in the Journler about box,
// it may be lacking in some instances in the source code. I will remedy this in future commits,
// and if you notice any please point them out.

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
	
    NSInteger movementCode = [textMovement integerValue];

    // see if this a 'pressed-return' instance
    if (movementCode == NSReturnTextMovement && [self numberOfRows] == 1 ) 
	{
        // hijack the notification and pass a different textMovement
        // value

        textMovement = [NSNumber numberWithInteger: NSCancelTextMovement];
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
	
	NSUInteger flags = [event modifierFlags];
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
