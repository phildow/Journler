/* JournalUpgradeController */

#import <Cocoa/Cocoa.h>
#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>
#import <SproutedAVI/SproutedAVI.h>

@class BlogPref;
@class JournlerEntry;
@class JournlerJournal;
@class JournlerCollection;

@interface JournalUpgradeController : NSWindowController
{
	IBOutlet PDGradientView			*container210;
	IBOutlet NSProgressIndicator	*progressIndicator210;
	IBOutlet NSBox					*box210;
	
	IBOutlet NSTextField			*headerText210;
	IBOutlet NSTextField			*progressText210;
	
	IBOutlet NSButton				*relaunch210;
	
	IBOutlet NSWindow				*licenseChanged210;
	
	NSModalSession session210;
	NSModalSession session253;
	NSMutableString *log210;
	NSMutableString	*log117;
	
	NSInteger  upgradeMode;
	JournlerJournal		*_journal;
	
	NSMutableDictionary *entriesDictionary;
	NSMutableDictionary *foldersDictionary;
}

- (void) run117To210Upgrade:(JournlerJournal*)journal;
- (BOOL) processResourcesLinksForEntry117To210:(JournlerEntry*)anEntry;
- (void) installLameComponents;
- (id) objectForURIRepresentation:(NSURL*)aURL;
- (NSArray*) entriesForTagIDs:(NSArray*)tagIDs;

#pragma mark -

- (int) run200To210Upgrade:(JournlerJournal*)journal;
- (BOOL) processResourcesForEntry:(JournlerEntry*)anEntry;
- (BOOL) processResourcesLinksForEntry:(JournlerEntry*)anEntry;
- (BOOL) processFileLinksForEntry:(JournlerEntry*)anEntry;

- (IBAction) relaunchJournler:(id)sender;
- (IBAction) quit210Upgrade:(id)sender;

#pragma mark -

- (void) run210To250Upgrade:(JournlerJournal*)aJournal;

#pragma mark -

- (BOOL) perform250To253Upgrade:(JournlerJournal*)aJournal;

#pragma mark -

- (BOOL) moveJournalOutOfApplicationSupport:(JournlerJournal*)aJournal;

- (NSAlert*) alertForMovingJournalOutOfApplicationSupport;
- (NSAlert*) alertWhenFolderNamedJournalAlreadyExistsInLibrary;
- (NSAlert*) alertWhenDataStoreMoveSucceeds;
- (NSAlert*) alertWhenDataStoreMoveFails;

- (NSString *) applicationSupportFolder;
- (NSString*) documentsFolder;
- (NSString*) libraryFolder;

@end
