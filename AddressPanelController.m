
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
		NSLog(@"%s - Cannot accept a nil address book ID", __PRETTY_FUNCTION__);
		return NO;
	}
	
	id record = [[ABAddressBook sharedAddressBook] recordForUniqueId:uniqueID];
	
	if ( !record ) 
	{
		NSLog(@"%s - Unable to convert address book ID to record", __PRETTY_FUNCTION__);
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
