#import "QTInstallController.h"

#import "NSAlert+JournlerAdditions.h"
#import "Definitions.h"

@implementation QTInstallController

- (id) init {
	
	if ( self = [super init] ) {
	//if ( self = [self initWithWindowNibName:@"QTInstall"] ) {
	//	[self window];
		
		//[NSBundle loadNibNamed:@"QTInstall" owner:self];
		
	}
	
	return self;
	
}

- (void)windowWillClose:(NSNotification *)aNotification {
	
}

#pragma mark -

+ (NSString*) LAMEFrameworkBundlePath {
	
	//static NSString *path = @"/Contents/LAMEComponents/LAME.framework/";
	//NSString *bundle_path = [[NSBundle mainBundle] bundlePath];
	//return [bundle_path stringByAppendingPathComponent:path];
	
	NSString *frameworkPath = [[NSBundle mainBundle] pathForResource:@"LAME" ofType:@"framework"];
	return frameworkPath;
}

+ (NSString*) LAMEComponentBundlePath {
	
	//static NSString *path = @"/Contents/LAMEComponents/LAMEEncoder.component/";
	//NSString *bundle_path = [[NSBundle mainBundle] bundlePath];
	//return [bundle_path stringByAppendingPathComponent:path];
	
	NSString *frameworkPath = [[NSBundle mainBundle] pathForResource:@"LAMEEncoder" ofType:@"component"];
	return frameworkPath;
}

+ (NSString*) LAMEFrameworkInstallPath {
	static NSString *path = @"/Library/Frameworks/LAME.framework/";
	return path;
}

+ (NSString*) LAMEComponentInstallPath {
	static NSString *path = @"/Library/QuickTime/LAMEEncoder.component/";
	return path;
}

+ (BOOL) LAMEComponentsInstalled {
	
	NSFileManager *fm = [NSFileManager defaultManager];
	return ( [fm fileExistsAtPath:[QTInstallController LAMEFrameworkInstallPath]] && 
			[fm fileExistsAtPath:[QTInstallController LAMEComponentInstallPath]] );
	
}

- (IBAction)dontInstall:(id)sender
{
	[NSApp abortModal];
}

- (IBAction)install:(id)sender
{
	[NSApp stopModal];
}

#pragma mark -

+ (BOOL) simplyInstallLameComponents
{
	return [[[[QTInstallController alloc] init] autorelease] installLameComponents];
}

- (BOOL) installLameComponents {
	
	//
	// installs the LAME.framework and LAMEEncoder.component into the required system directories
	//
	
	NSLog(@"Installing LAME.framework and LAMEEncoder.component");
	
	BOOL success = YES;
	
	NSFileManager *fm = [NSFileManager defaultManager];
	
	if ( [fm fileExistsAtPath:[QTInstallController LAMEFrameworkBundlePath]] && 
			![fm fileExistsAtPath:[QTInstallController LAMEFrameworkInstallPath]] )
		success = [fm copyPath:[QTInstallController LAMEFrameworkBundlePath] 
				toPath:[QTInstallController LAMEFrameworkInstallPath] handler:self];
		
	if ( [fm fileExistsAtPath:[QTInstallController LAMEComponentBundlePath]] && 
			![fm fileExistsAtPath:[QTInstallController LAMEComponentInstallPath]] )
		success = ( success && [fm copyPath:[QTInstallController LAMEComponentBundlePath] 
				toPath:[QTInstallController LAMEComponentInstallPath] handler:self] );	
	
	if ( success ) {
		
		// set the group to admin, common for items in the framework and components directories
		NSDictionary *groupDict = [NSDictionary dictionaryWithObjectsAndKeys:
				@"admin", NSFileGroupOwnerAccountName, nil];
		
		success = [fm changeFileAttributes:groupDict atPath:[QTInstallController LAMEFrameworkInstallPath]];
		success = ( success && [fm changeFileAttributes:groupDict atPath:[QTInstallController LAMEComponentInstallPath]] );	
		
	}
	
	if ( success ) {
		
		NSLog(@"Successfully installed mp3 encoding components");
		//[[NSAlert lameInstallSuccess] runModal];
	}
	else {
		
		NSLog(@"Unable to install mp3 encoding components");
		//[[NSAlert lameInstallFailure] runModal];
		
	}
	
	return success;
}

#pragma mark -
#pragma mark File Manager Delegation

- (void)fileManager:(NSFileManager *)manager willProcessPath:(NSString *)path {
	
	//
	// simply for the sake of consistency
	//
	
}

- (BOOL)fileManager:(NSFileManager *)manager shouldProceedAfterError:(NSDictionary *)errorInfo {
	
	//
	// log the error and return no
	//
	
	NSLog(@"\nEncountered file manager error: source = %@, error = %@, destination = %@\n",
			[errorInfo objectForKey:@"Path"], [errorInfo objectForKey:@"Error"], [errorInfo objectForKey:@"ToPath"]);
	
	return NO;
	
}

@end
