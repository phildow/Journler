//
//  JournlerApplication.m
//  Journler
//
//  Created by Philip Dow on 9/7/07.
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

#import "JournlerApplication.h"
#import "JournlerWindowController.h"

@implementation JournlerApplication

- (id)targetForAction:(SEL)anAction to:(id)aTarget from:(id)sender
{
	// override to retarget find panel actions
	
	//NSLog(@"%s - action: %s, target: %@, from: %@", __PRETTY_FUNCTION__, anAction, aTarget, sender);
	id theTarget = aTarget;
	
	if ( anAction == @selector(performFindPanelAction:) )
	{
		// discover the target
		theTarget = [super targetForAction:anAction to:aTarget from:sender];
		
		if ( theTarget == nil )
		{
			// if the target is nil retarget at the current document
			// NSLog(@"%s - attempting to retarget for find panel action", __PRETTY_FUNCTION__);
			
			if ( [[[self mainWindow] windowController] respondsToSelector:@selector(handlesFindCommand)] && [[[self mainWindow] windowController] handlesFindCommand] )
				theTarget = [[self mainWindow] windowController];
		}
		
		else if ( theTarget != nil )
		{
			// the target may invalidate the menu item. if so retarget at the current document
			// NSLog(@"%s - action: %s, established target: %@, from: %@", __PRETTY_FUNCTION__, anAction, theTarget, sender);
			
			if ( [sender isKindOfClass:[NSMenuItem class]] 
			&& ( ( [theTarget respondsToSelector:@selector(validateMenuItem:)] && ![theTarget validateMenuItem:sender] ) 
				|| [theTarget respondsToSelector:@selector(validateUserInterfaceItem:)] && ![theTarget validateUserInterfaceItem:sender] ) )
			{
				if ( [[[self mainWindow] windowController] respondsToSelector:@selector(handlesFindCommand)] && [[[self mainWindow] windowController] handlesFindCommand] )
					theTarget = [[self mainWindow] windowController];
			}
		}
	}
	
	else if ( anAction == @selector(modifyFont:) )
	{
		// discover the font manager's font action target, if there is one.
		// if there is a target and it can be editable, check if it is.
		// otherwise we want our custom behavior
		
		SEL fontAction = [[NSFontManager sharedFontManager] action];
		id fontActionTarget = [super targetForAction:fontAction to:nil from:[NSFontManager sharedFontManager]];
		
		if ( fontActionTarget == nil || ( [fontActionTarget respondsToSelector:@selector(isEditable:)] && [fontActionTarget isEditable] == NO ) )
		{
			if ( [[[self mainWindow] windowController] respondsToSelector:@selector(handlesTextSizeCommand)] && [[[self mainWindow] windowController] handlesTextSizeCommand] )
				theTarget = [[self mainWindow] windowController];
			else
				theTarget = [NSFontManager sharedFontManager];
		}
		else
		{
			theTarget = [NSFontManager sharedFontManager];
		}
	}
	
	else
	{
		// all other cases - let NSApplication handle it
		theTarget = [super targetForAction:anAction to:aTarget from:sender];
	}
	
	return theTarget;
}

- (BOOL)sendAction:(SEL)anAction to:(id)aTarget from:(id)sender
{
	// it may be necessary to retarget for a find panel action or a text size action
	//NSLog(@"%s - action: %s, target: %@, from: %@", __PRETTY_FUNCTION__, anAction, aTarget, sender);
	
	id theTarget = aTarget;
	
	if ( anAction == @selector(performFindPanelAction:) )
		theTarget = [self targetForAction:anAction to:aTarget from:sender];
	
	else if ( anAction == @selector(modifyFont:) )
		theTarget = [self targetForAction:anAction to:aTarget from:sender];
	
	return [super sendAction:anAction to:theTarget from:sender];
}

- (void)sendEvent:(NSEvent *)anEvent
{
	// is this a keyboard equivalent event and if so does the key window responds to custom keyboard equivalents?
	if ( [anEvent type] == NSKeyDown && ( [anEvent modifierFlags] & NSCommandKeyMask ) 
			&& [[[self keyWindow] windowController] respondsToSelector:@selector(performCustomKeyEquivalent:)] )
	{
		// if the key window doesn't have anything to do, pass the message onto super
		if ( ![[[self keyWindow] windowController] performSelector:@selector(performCustomKeyEquivalent:) withObject:anEvent] )
			[super sendEvent:anEvent];
	}
	else
	{
		// let super handle anything else
		[super sendEvent:anEvent];
	}
}	

@end
