
#import "AddressPanelController.h"

@implementation AddressPanelController

+ (id)sharedAddressPanelController 
{
    static AddressPanelController *sharedAddressPanelController = nil;

    if (!sharedAddressPanelController) 
	{
        sharedAddressPanelController = [[AddressPanelController allocWithZone:NULL] init];
    }

    return sharedAddressPanelController;
}

- (id)init 
{
    if ( [super initWithWindowNibName:@"AddressPanel"] )
	{
		[self setWindowFrameAutosaveName:@"Address Panel"];
	}
    return self;
}

- (void) awakeFromNib 
{
	// people picker setup
	[peoplePickerView setTarget:peoplePickerView];
	[peoplePickerView setNameDoubleAction:@selector(selectInAddressBook:)];
	[peoplePickerView setAccessoryView:accessoryView];
		
	// load up the selected people picker objects
	[[insertButton cell] setRepresentedObject:[peoplePickerView selectedRecords]];
	
	// notifications baby
	//[[NSNotificationCenter defaultCenter] addObserver:self 
	//		selector:@selector(contactSelectionDidChange:) 
	//		name:ABPeoplePickerNameSelectionDidChangeNotification 
	//		object:peoplePickerView];
	
	// adjust the appearance of the insert button for 10.4 tiger users
	if ( ![[self window] respondsToSelector:@selector(autorecalculatesContentBorderThicknessForEdge:)] )
	{
		NSRect frame = [insertButton frame];
		frame.size.width += 10;
		
		[insertButton setFrame:frame];
		[insertButton setBezelStyle:NSRegularSquareBezelStyle];
	}
}

- (void) dealloc
{
	//[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

#pragma mark -

- (BOOL) editRecordInAddressBook:(NSString*)uniqueID 
{
	if ( !uniqueID ) 
	{
		NSLog(@"%@ %s - Cannot accept a nil address book ID", [self className], _cmd);
		return NO;
	}
	
	id record = [[ABAddressBook sharedAddressBook] recordForUniqueId:uniqueID];
	
	if ( !record ) 
	{
		NSLog(@"%@ %s - Unable to convert address book ID to record", [self className], _cmd);
		return NO;
	}

	
	[peoplePickerView selectRecord:record byExtendingSelection:NO];
	[peoplePickerView selectInAddressBook:self];
	return YES;
}

- (void) contactSelectionDidChange:(NSNotification*)aNotification
{
	[insertButton setEnabled:([[peoplePickerView selectedRecords] count]!=0)];
	[[insertButton cell] setRepresentedObject:[peoplePickerView selectedRecords]];
}

- (IBAction) myInsertContact:(id)sender
{
	[[insertButton cell] setRepresentedObject:[peoplePickerView selectedRecords]];
	[NSApp sendAction:@selector(insertContact:) to:nil from:insertButton];
}

@end
