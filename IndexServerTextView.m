//
//  IndexServerTextView.m
//  Journler
//
//  Created by Philip Dow on 3/5/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import "IndexServerTextView.h"

@implementation IndexServerTextView : NSTextView

- (BOOL) insertsLexiconContextSeparator
{
	return insertsLexiconContextSeparator;
}

- (void) setInsertsLexiconContextSeparator:(BOOL)withSeparator
{
	insertsLexiconContextSeparator = withSeparator;
}

#pragma mark -

- (NSMenu *)menuForEvent:(NSEvent *)theEvent 
{	
	// the menu we will return
	NSMenu *returnMenu = [super menuForEvent:theEvent];
	
	// go ahead and get out of here if this menu is already built
	if ( [returnMenu itemWithTag:10746] != nil )
		return returnMenu;
	
	// the lexicon menu, but only if a single term is selected
	if ( [self selectedRange].length > 0 
		&& [[self delegate] respondsToSelector:@selector(indexServerTextView:showLexiconSelection:term:)]
		&& [[self delegate] respondsToSelector:@selector(representedObject)] )
	{
		NSString *selection = [[self string] substringWithRange:[self selectedRange]];
		if ( [selection rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location == NSNotFound )
		{
			if ( [self insertsLexiconContextSeparator] )
				[returnMenu addItem:[NSMenuItem separatorItem]];
			
			NSMenu *lexiconMenu = [[[NSMenu alloc] initWithTitle:NSLocalizedString(@"menuitem lexicon", @"")] autorelease];
			[lexiconMenu setDelegate:[self valueForKeyPath:@"delegate.representedObject.journal.indexServer"]];
			
			NSMenuItem *lexiconMenuItem = [[[NSMenuItem alloc] 
					initWithTitle:NSLocalizedString(@"menuitem lexicon", @"") 
					action:nil 
					keyEquivalent:@""] autorelease];
			
			[lexiconMenuItem setTag:10746];
			[lexiconMenuItem setTarget:self];
			[lexiconMenuItem setAction:@selector(_showObjectFromLexicon:)];
			[lexiconMenuItem setRepresentedObject:selection];
			
			[lexiconMenuItem setSubmenu:lexiconMenu];
			[returnMenu addItem:lexiconMenuItem];
		}
	}
	
	return returnMenu;
}

- (IBAction) _showObjectFromLexicon:(id)sender
{
	id anObject = [sender representedObject];
	
	// modifiers should support opening the item in windows, tabs, etc
	// the item should be opened and the terms highlighted and located
	
	if ( anObject == nil || ![[self delegate] respondsToSelector:@selector(indexServerTextView:showLexiconSelection:term:)] )
	{
		NSBeep();
	}
	else
	{
		[[self delegate] indexServerTextView:self showLexiconSelection:anObject term:[self valueForKeyPath:@"delegate.representedObject.journal.indexServer.lexiconMenuRepresentedTerm"]];
	}
}

@end 