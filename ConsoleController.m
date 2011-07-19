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
