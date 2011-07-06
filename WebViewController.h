/* WebViewController */

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <SproutedInterface/SproutedInterface.h>

#import "JournlerMediaContentController.h"

@class JournlerMediaViewer;

@interface WebViewController : JournlerMediaContentController
{
    IBOutlet WebView *webView;
	IBOutlet RBSplitView *urlSplit;
	IBOutlet PDURLTextField	*urlField;
	
	IBOutlet NSMenu	*_contextual_menu;
	
	IBOutlet NSButton *homeButton;
	IBOutlet NSButton *stopRestart;
	
	IBOutlet NSButton *back;
	IBOutlet NSButton *forward;
	IBOutlet NSSegmentedControl *backForward;

	IBOutlet PDGradientView *statusBar;
	
	IBOutlet NSProgressIndicator *statusIndicator;
	IBOutlet NSTextField *statusField;
	
	IBOutlet NSWindow *webviewFindPanel;
	IBOutlet NSTextField *webviewFindQueryField;
	
	BOOL closing;
	BOOL blockPopup;
	NSTimer *statusFader;
}

- (WebView*) webView;
- (NSURL*) webBrowsedURL;
- (NSString*) browserTitle;

- (IBAction)goBackOrForward:(id)sender;
- (IBAction)addURLAsArchive:(id)sender;
- (IBAction)goHome:(id)sender;
- (IBAction)search:(id)sender;

- (IBAction)performWebViewFindPanelAction:(id)sender;

- (void) setStatusText:(NSString*)aString;
- (void) fadeStatusText:(NSTimer*)aTimer;
- (void) setStatusProgressHidden:(NSNumber*)aNumber;

- (void) _updateButtonsReloads:(BOOL)reloads;

- (void) progressEstimateChanged:(NSNotification*)aNotification;
- (void) progressFinished:(NSNotification*)aNotification;

- (IBAction) appendLinkToEntry:(id)sender;
- (IBAction) appendSelectionToEntry:(id)sender;
- (IBAction) appendSiteArchiveToEntry:(id)sender;
- (IBAction) appendImageToEntry:(id)sender;

- (IBAction) newEntryWithArchive:(id)sender;

- (IBAction) openInNewWindow:(id)sender;
- (IBAction) openInBrowser:(id)sender;

- (IBAction) loadWebAddress:(id)sender;

@end

@interface NSObject (WebViewControllerDelegate)

- (void) webViewController:(WebViewController*)aController appendPasteboardLink:(NSPasteboard*)pboard;
- (void) webViewController:(WebViewController*)aController appendPasteboardContents:(NSPasteboard*)pboard;
- (void) webViewController:(WebViewController*)aController appendPasetboardWebArchive:(NSPasteboard*)pboard;
	
@end
