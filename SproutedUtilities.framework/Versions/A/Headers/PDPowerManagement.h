//
//  PDPowerManagement.h
//  Originally part of the Journler project: http://journler.phildow.net
//  Source code available at http://developers.phildow.net
//
//  Created by Philip Dow on 3/21/06.
//  Licensed under the LGPL: http://www.gnu.org/copyleft/lesser.html
//
//  Of course, I would appreciate a mentioning in your app's about box.
//  If you make improvements or additions to the code, please let me know.
//

#import <Cocoa/Cocoa.h>

//
// Be sure to include the IOKit Framework in your project

#import <mach/mach_port.h>
#import <mach/mach_interface.h>
#import <mach/mach_init.h>

#import <IOKit/pwr_mgt/IOPMLib.h>
#import <IOKit/IOMessage.h>

//
// Notifications
//
// The PDPowerManagementNotification will be sent to the default notification center
// with the shared instance of PDPowerManagement as the object. To make sure that a shared 
// instance is available, call [PDPowerManagement sharedPowerManagement] somewhere in your code.
//
// The notification's user info dictionary will contain the PDPowerManagementMessage key with an 
// NSNumber whose int value is either PDPowerManagementWillSleep or PDPowerManagementPoweredOn.

#define PDPowerManagementNotification	@"PDPowerManagementNotification"
#define PDPowerManagementMessage		@"PDPowerManagementMessage"
#define PDPowerManagementWillSleep		1
#define PDPowerManagementPoweredOn		3

//
// Disallowing Sleep
//
// There are two ways to disallow a power down. Either call setPermitSleep: with NO 
// or implement the - (BOOL) shouldAllowIdleSleep:(id)sender delegate method and return NO as needed.
// At initialization _permitSleep is set to YES. With this value, the delegate method is
// always called if the delegate implements it. If _permitSleep is set to NO, the delegate
// method is never called. setPermitSleep: is thus a lazy way of always disallowing sleep.
//
// It must however be noted that it is not possible to cancel a sleep command that the user
// initiates. _permitSleep and the delegate method can only prevent an idle sleep. For 
// more information: http://developer.apple.com/qa/qa2004/qa1340.html

@interface PDPowerManagement : NSObject {
	
	BOOL	_permitSleep;
	id		_delegate;
	
}

+ (id)sharedPowerManagement;

- (BOOL) permitSleep;
- (void) setPermitSleep:(BOOL)permitSleep;

- (id) delegate;
- (void) setDelegate:(id)delegate;

- (void) _postPMNotification:(int)message;
- (BOOL) _shouldAllowSleep;

@end

//
// Delegation
// You should implement: - (BOOL) shouldAllowIdleSleep:(id)sender
// 
// If you set a delegate, before the computer is put to idle sleep the delegate's
// shouldAllowSleep: method will be called. Return NO to disallow the power down, 
// return yes to permit it.

@interface NSObject (PDPowerManagementDelegate)

//
// return YES to permit a power down, NO to disallow it
- (BOOL) shouldAllowIdleSleep:(id)sender;

@end
