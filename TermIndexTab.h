/* TermIndexTab */

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <SproutedInterface/SproutedInterface.h>

#import "TabController.h"


@class EntryCellController;
@class ResourceCellController;

@class IndexNode;
@class IndexColumn;
@class IndexBrowser;

@class JournlerJournal;
@class JournlerIndexServer;

@interface TermIndexTab : TabController
{
	IBOutlet RBSplitView *mainSplit;
	IBOutlet IndexBrowser *indexBrowser;
	IBOutlet WebView *contentPlaceholder;
	
	IBOutlet NSMenu *documentContextMenu;
	IBOutlet NSMenu *termContextMenu;
	
	EntryCellController *entryCellController;
	ResourceCellController *resourceCellController;
	
	NSView *activeContentView;
	
	NSArray *selectedDocuments;
	NSMutableDictionary *termToDocumentsDictionary;
	NSMutableDictionary *documentToTermsDictionary;
	
	JournlerIndexServer *indexServer;
	
	NSLock *termsForObjectsLock;
	NSArray *loadingDocuments;
	BOOL _breakTermLoadingThread;
}

- (NSArray*) selectedDocuments;
- (void) setSelectedDocuments:(NSArray*)anArray;

- (JournlerIndexServer*) indexServer;
- (void) setIndexServer:(JournlerIndexServer*)aServer;

//- (void) setSelectedDocumentsOnSeparateThread:(NSArray*)anArray;

- (NSView*) activeContentView;
- (void) setActiveContentView:(NSView*)aView;

- (IBAction) gotoLetter:(id)sender;

//- (IBAction) openDocumentInNewTab:(id)sender;
- (IBAction) openDocumentInNewWindow:(id)sender;

- (IBAction) revealDocumentInFinder:(id)sender;
- (IBAction) openDocumentInFinder:(id)sender;

- (IBAction) addTermsToStopList:(id)sender;

@end

@interface NSObject (TermIndexTabExtras)

- (JournlerIndexServer*) indexServer;

@end
