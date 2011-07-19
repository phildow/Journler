//
//  BrowseTableFieldEditor.m
//  Journler
//
//  Created by Philip Dow on 7/5/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import "BrowseTableFieldEditor.h"


@implementation BrowseTableFieldEditor

- (id)initWithFrame:(NSRect)frame 
{
    if ( self = [super initWithFrame:frame] ) 
	{
        // Initialization code here.
		_completions = [[NSArray alloc] init];
    }
    return self;
}

- (void) dealloc 
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	[_completions release];
	[super dealloc];
}


- (BOOL) completes 
{ 
	return _completes; 
}

- (void) setCompletes:(BOOL)shouldComplete 
{
	_completes = shouldComplete;
}

- (NSArray*) completions 
{ 
	return _completions; 
}

- (void) setCompletions:(NSArray*)anArray 
{
	if ( _completions != anArray ) 
	{
		[_completions release];
		_completions = [anArray copyWithZone:[self zone]];
	}
}

- (NSArray *)completionsForPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index 
{
	NSInteger i;
	NSMutableArray *returnArray = [[NSMutableArray alloc] initWithCapacity:[_completions count]];
	NSString *potential = [[self string] substringWithRange:charRange];
	
	for ( i = 0; i < [_completions count]; i++ ) 
	{
		if ( [[_completions objectAtIndex:i] rangeOfString:potential options:NSCaseInsensitiveSearch].location == 0 )
			[returnArray addObject:[_completions objectAtIndex:i]];
	}
	
	return [returnArray autorelease];
}

- (BOOL)shouldDrawInsertionPoint 
{
	return YES;
}

- (void)insertText:(id)aString 
{
	[super insertText:aString];
	if ( _completes ) 
		[self complete:self];
}

/*
- (void)keyDown:(NSEvent *)theEvent
{
	if ( [theEvent keyCode] == 53 )
	{ 
		// escape key ends editing
		if ( [[self delegate] respondsToSelector:@selector(textShouldEndEditing:)] 
				&& [[self delegate] textShouldEndEditing:self] && [[self delegate] respondsToSelector:@selector(textDidEndEditing:)] )
		{
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:-99] forKey:@"NSTextMovement"];
			NSNotification *aNotification = [NSNotification notificationWithName:NSTextDidEndEditingNotification object:self userInfo:userInfo];
			[[self delegate] textDidEndEditing:aNotification];
		}
	}
	else
	{
		[super keyDown:theEvent];
	}
}
*/

@end
