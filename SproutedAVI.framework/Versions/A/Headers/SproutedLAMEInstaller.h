/* SproutedLAMEInstaller */

#import <Cocoa/Cocoa.h>

@interface SproutedLAMEInstaller : NSWindowController
{
	
}

+ (NSString*) LAMEFrameworkBundlePath;
+ (NSString*) LAMEComponentBundlePath;

+ (NSString*) LAMEFrameworkInstallPath;
+ (NSString*) LAMEComponentInstallPath;

+ (BOOL) LAMEComponentsInstalled;
+ (BOOL) simplyInstallLameComponents;
- (BOOL) installLameComponents;

@end
