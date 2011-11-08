//
//  BrowseTableFieldEditor.m
//  Journler
//
//  Created by Philip Dow on 7/5/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
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
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:-99] forKey:@"NSTextMovement"];
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
