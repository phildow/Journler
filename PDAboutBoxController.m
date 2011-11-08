
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

#import "PDAboutBoxController.h"

@implementation PDAboutBoxController

+ (id)sharedController 
{
    static PDAboutBoxController *sharedAboutBoxController = nil;

    if (!sharedAboutBoxController) 
	{
        sharedAboutBoxController = [[PDAboutBoxController allocWithZone:NULL] init];
    }

    return sharedAboutBoxController;
}

- (id)init 
{
	if ( self = [self initWithWindowNibName:@"PDAboutBox"] ) 
	{
		[self window];
    }
    return self;
}

- (void) awakeFromNib
{
	[[additionalText enclosingScrollView] setDrawsBackground:NO];
	[additionalText setDrawsBackground:NO];
}

- (void)dealloc 
{	
	[super dealloc];	
}

- (void) windowDidLoad 
{
	// set the window's background color
	[[self window] setBackgroundColor:[NSColor whiteColor]];
	
	// prepare the scrolling text using a default text document
	//NSString *creditsPath = creditsPath = [[NSBundle mainBundle] pathForResource:@"PDAboutBox" ofType:@"rtfd"];
	//if ( creditsPath )
	//	[mainText prepViewWithFile:creditsPath];
	
	// prepare other fields with default values taken from the apps info.plist files
	NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
	NSDictionary *localInfoDictionary = (NSDictionary *)CFBundleGetLocalInfoDictionary( CFBundleGetMainBundle() );
	
	//NSString *title = [NSString stringWithFormat:NSLocalizedStringFromTable(@"window title", @"PDAboutBox", @""),
	//		[localInfoDictionary objectForKey:@"CFBundleName"]];
			
	//[[self window] setTitle:title];
	
	NSString *shortVersion = [localInfoDictionary objectForKey:@"CFBundleShortVersionString"];
	NSString *version = [infoDictionary objectForKey:@"CFBundleVersion"];
	
	NSString *versionString = [NSString stringWithFormat:@"Version %@ (%@)", 
	( shortVersion != nil ? shortVersion : @"" ), ( version != nil ? version : @"" )];
	
	//NSLog(versionString);
	
	[appnameField setStringValue:[localInfoDictionary objectForKey:@"CFBundleName"]];
	[versionField setStringValue:versionString];
	//[copyrightField setStringValue:[localInfoDictionary objectForKey:@"NSHumanReadableCopyright"]];
	
	[aboutText setTextContainerInset:NSMakeSize(5,10)];
}

#pragma mark -

- (IBAction)showWindow:(id)sender
{
	[self showAboutBox:self];
}

- (IBAction) showAboutBox:(id)sender 
{	
	//[mainText startScroll:YES];
	[NSApp runModalForWindow:[self window]];
	//[mainText stopScroll];	
}

- (IBAction)doSomething:(id)sender
{
}

- (BOOL)windowShouldClose:(id)sender {
	return YES;
}

- (void)windowWillClose:(NSNotification *)aNotification 
{	
	if ( [NSApp modalWindow] == [self window] ) 
		[NSApp stopModal];	
}

@end
