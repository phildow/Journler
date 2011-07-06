/* QuickLinkController */

@class JournlerJournal;

#import "JournlerJournal.h"
#import "JournlerCollection.h"

#import "FiltersArrayController.h"
#import "QuickLinkTable.h"

#import <SproutedInterface/SproutedInterface.h>
//#import "PDGradientView.h"

@interface QuickLinkController : NSWindowController
{
	JournlerJournal *journal;
	
	IBOutlet QuickLinkTable			*entriesTable;
	IBOutlet FiltersArrayController	*entryController;
	
	IBOutlet NSWindow				*previewWin;
	IBOutlet NSTextView				*previewText;
	IBOutlet PDGradientView			*gradient;
	
	JournlerCollection				*_selected_collection;
	IBOutlet NSPopUpButton			*_collections_pop;
}

+ (id)sharedController;

- (JournlerJournal*)journal;
- (void) setJournal:(JournlerJournal*)aJournal;

- (JournlerCollection*) selectedCollection;
- (void) setSelectedCollection:(JournlerCollection*)selection;

- (IBAction) selectCollection:(id)sender;
- (IBAction) contextualCommand:(id) sender;

- (IBAction) _showPreview:(id)sender;
- (IBAction) _openEntryInNewWindow:(id)sender;
- (IBAction) _openEntryInSelectedTab:(id)sender;
- (IBAction) _openEntryInNewTab:(id)sender;

@end
