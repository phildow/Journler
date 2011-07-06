/* EntryWindowController */

#import <Cocoa/Cocoa.h>

#import "JournlerWindowController.h"

@class BrowseTableFieldEditor;
@class PDPopUpButtonToolbarItem;

@interface EntryWindowController : JournlerWindowController
{
	IBOutlet NSView *navOutlet;
	IBOutlet NSButton *navBack;
	IBOutlet NSButton *navForward;
	IBOutlet NSSegmentedControl *navBackForward;
	
	PDPopUpButtonToolbarItem *dateTimeButton;
	PDPopUpButtonToolbarItem *highlightButton;
	
	IBOutlet NSView *initalTabPlaceholder;
	IBOutlet BrowseTableFieldEditor	*browseTableFieldEditor;
}

@end

@interface EntryWindowController (Toolbars)
	- (void) setupToolbar;
	- (void) setupDateTimePopUpButton;
	- (void) setupHighlightPopUpButton;
@end