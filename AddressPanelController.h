/* AddressPanelController */

#import <Cocoa/Cocoa.h>
#import <AddressBook/AddressBook.h>
#import <AddressBook/AddressBookUI.h>

@interface AddressPanelController : NSWindowController
{
    IBOutlet ABPeoplePickerView *peoplePickerView;
	IBOutlet NSView *accessoryView;
	IBOutlet NSButton *insertButton;
}

+ (id)sharedAddressPanelController;
- (BOOL) editRecordInAddressBook:(NSString*)uniqueID;

- (IBAction) myInsertContact:(id)sender;

@end
