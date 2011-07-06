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
