/* QTInstallController */

#import <Cocoa/Cocoa.h>

@interface QTInstallController : NSWindowController
{
	
}

+ (NSString*) LAMEFrameworkBundlePath;
+ (NSString*) LAMEComponentBundlePath;

+ (NSString*) LAMEFrameworkInstallPath;
+ (NSString*) LAMEComponentInstallPath;

+ (BOOL) LAMEComponentsInstalled;
+ (BOOL) simplyInstallLameComponents;
- (BOOL) installLameComponents;

//- (NSInteger) runAsSheetForWindow:(NSWindow*)window attached:(BOOL)sheet;

- (IBAction)dontInstall:(id)sender;
- (IBAction)install:(id)sender;

@end
