/* AddressRecordController */

#import <Cocoa/Cocoa.h>
#import <AddressBook/AddressBook.h>
#import <Carbon/Carbon.h>
#import <SproutedInterface/SproutedInterface.h>

#import "JournlerMediaContentController.h"

@class PDPersonViewer;

@interface AddressRecordController : JournlerMediaContentController
{
	IBOutlet PDPersonViewer *personViewer;
	IBOutlet NSObjectController *objectController;

	IBOutlet NSMenu *phoneMenu;
	IBOutlet NSMenu *emailMenu;
	IBOutlet NSMenu *websiteMenu;
	IBOutlet NSMenu *addressMenu;
	
	ABPerson *person;
	
	NSString *defaultEmail;
	NSString *defaultHomepage;
}

- (ABPerson*) person;
- (void) setPerson:(ABPerson*)person;

- (NSString*) defaultEmail;
- (void) setDefaultEmail:(NSString*)aString;

- (NSString*) defaultHomepage;
- (void) setDefaultHomepage:(NSString*)aString;

- (IBAction) sendMailToDefaultAddress:(id)sender;
- (IBAction) browseDefaultHomepage:(id)sender;

- (IBAction) showFieldMenu:(id)sender;

- (IBAction) openRecordInNewWindow:(id)sender;
- (IBAction) openRecordInAddressBook:(id)sender;

- (IBAction) viewNumberWithLargeType:(id)sender;
- (IBAction) callWithSkype:(id)sender;

- (IBAction) sendEmail:(id)sender;
- (IBAction) searchEmailInSpotlight:(id)sender;

- (IBAction) openURL:(id)sender;
- (IBAction) openURLInWindow:(id)sender;
- (IBAction) openURLInFinder:(id)sender;

@end

@interface NSObject (AddressRecordControllerAdditions)

- (void) addressRecordController:(AddressRecordController*)anAddressRecordController displayURL:(NSURL*)aURL;

@end
