
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

#import "ConsoleController.h"

@implementation ConsoleController
	
- (id) init 
{
	if ( self = [self initWithWindowNibName:@"Console"] ) 
	{
		[self retain];
	}
	
	return self;
}	

- (void) awakeFromNib {
	
	[[console window] setBackgroundColor: [NSColor clearColor]];
	[[console window] setAlphaValue:1.0];
	[[console window] setOpaque:NO];
	[[console window] setHasShadow:YES];
	[[console window] setBackgroundColor:[NSColor clearColor]];
	
	[console setString:@"> journler developer's console, please enter a command\n> "];
	[console setTextColor:[NSColor whiteColor]];
	[console setInsertionPointColor:[NSColor whiteColor]];
	[console setBackgroundColor:[[NSColor blackColor] colorWithAlphaComponent:0.8]];
	
	NSFont *font;
	font = [NSFont fontWithName:@"Andale Mono" size:11];
	if ( !font )
		font = [NSFont systemFontOfSize:11];
	
	[console setFont:font];
}

#pragma mark -

- (id) delegate
{
	return delegate;
}

- (void) setDelegate:(id)anObject 
{	
	delegate = anObject;	
}

#pragma mark -

- (void)windowWillClose:(NSNotification *)aNotification {
	//
	// let ourselves go
	[self autorelease];
}

- (NSInteger) runAsSheetForWindow:(NSWindow*)window attached:(BOOL)sheet {
	
	//result = [NSApp runModalForWindow: [self window]];
	[[self window] makeKeyAndOrderFront:self];
		
	return 1;
	
}

#pragma mark -

- (void)textDidChange:(NSNotification *)aNotification {
	
	static NSString *exitString = @"exit";
	
	unichar lastChar = [[console string] characterAtIndex:[[console string] length]-1];
	
	if ( lastChar == '\n' || lastChar == '\r' ) {
		
		NSMutableString *allText = [[console string] mutableCopy];
		
		// just to be safe
		if ( [allText length] <= 3 )
			return;
		
		// grab just this line
		NSArray *lines = [allText componentsSeparatedByString:[NSString 
				stringWithCharacters:(const unichar[]) { NSNewlineCharacter } length:1]];
		NSString *lastLine = [lines objectAtIndex:[lines count]-2];
		
		// quit out if the exit command
		if ( [lastLine rangeOfString:exitString options:NSCaseInsensitiveSearch].location != NSNotFound ) {
			[[self window] performClose:self];
			return;
		}
		
		// otherwise ask the controller to perform the command
		NSString *result = [delegate runConsoleCommand:lastLine];
		if ( result ) {
			[allText appendString:result];
			[allText appendString:@"\n"];
		}
		
		// finish preping the text and send it out
		[allText appendString:@"> "];
		[console setString:allText];
		
		[allText release];
		
	}
	
}

@end
