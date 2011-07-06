//
//  LockoutController.h
//  Journler
//
//  Created by Phil Dow on 10/24/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PDGradientView;

typedef enum {
	kLockoutModePassword = 0,
	kLockoutModeChecksum = 1
} LockoutModes;

@interface LockoutController : NSWindowController {
	
	IBOutlet NSTextField *passwordField;
	IBOutlet NSButton *hideButton;
	IBOutlet NSButton *okButton;
	IBOutlet NSTextField *attemptsField;
	IBOutlet NSTextField *lockoutField;
	IBOutlet PDGradientView *gradient;
	
	IBOutlet NSTextField *progressLabel;
	IBOutlet NSProgressIndicator *progress;
	
	unsigned int mode;
	unsigned int numAttempts;
	
	NSString *password;
	NSString *checksum;
	NSString *validatedPassword;
}

- (id) initWithPassword:(NSString*)aString;
- (id) initWithChecksum:(NSString*)aString;

- (BOOL) confirmPassword;
- (BOOL) confirmChecksum;

- (NSString*) validatedPassword;

- (IBAction) okay:(id)sender;
- (IBAction) cancel:(id)sender;
- (IBAction) hide:(id)sender;
- (IBAction) unhide:(id)sender;

- (IBAction) showProgressIndicator:(id)sender;
- (IBAction) hideProgressIndicator:(id)sender;
- (IBAction) enableLockedOutControls:(id)sender;

@end
