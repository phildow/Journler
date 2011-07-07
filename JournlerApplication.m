//
//  JournlerApplication.m
//  Journler
//
//  Created by Philip Dow on 9/7/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

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
