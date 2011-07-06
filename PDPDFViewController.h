/* PDPDFViewController */

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <SproutedInterface/SproutedInterface.h>

#import "JournlerMediaContentController.h"

typedef unsigned int PDFMediaOutlineState;
 
enum {
	kPDFMediaNoOutline = 0,
	kPDFMediaDocumentOutline = 1,
	kPDFMediaSearchOutline = 2
};

@class JournlerMediaViewer;
@class IndexServerPDFView;

@interface PDPDFViewController : JournlerMediaContentController
{
    IBOutlet IndexServerPDFView *pdfView;
	IBOutlet RBSplitView *splitView;
	IBOutlet NSOutlineView *outline;

	IBOutlet NSTextField *pageNum;
	
	IBOutlet NSButton *back;
	IBOutlet NSButton *forward;
	IBOutlet NSSegmentedControl *backForward;
	
	IBOutlet NSButton *zoomIn;
	IBOutlet NSButton *zoomOut;
	IBOutlet NSButton *actualSize;
	IBOutlet NSSegmentedControl *zoomInOut;
	
	IBOutlet NSPopUpButton	*display;
	IBOutlet NSButton		*showOutline;
	IBOutlet NSSearchField *searchField;
	
	IBOutlet JournlerGradientView *unlockView;
	IBOutlet NSSecureTextField *passwordField;
	IBOutlet NSTextField *unlockNoticeField;
	
	NSLock *searchLock;
	NSMutableArray *searchResults;
	
	PDFOutline *rootNode;
	PDFDocument *selectedDocument;
	
	BOOL autoselectSearchResults;
	BOOL _outlineChange;
	float _outlineIndentation;
	PDFMediaOutlineState outlineState;
}

- (PDFDocument*) pdfDocument;
- (void) restoreLastDisplaySettings;

- (PDFMediaOutlineState) outlineState;
- (void) setOutlineState:(PDFMediaOutlineState)state;

- (IBAction) toggleOutline:(id)sender;
- (IBAction) goToNextPage:(id)sender;
- (IBAction) goToPreviousPage:(id)sender;
- (IBAction) goToNextOrPreviousPage:(id)sender;

- (IBAction) changeDisplayMode:(id)sender;
- (IBAction) scaleToActual:(id)sender;
- (IBAction) scaleView:(id)sender;
- (IBAction) zoomInOrOut:(id)sender;
- (void) _updateScaleOptions;
- (IBAction) barSearch:(id)sender;

- (IBAction) previousPage:(id)sender;
- (IBAction) nextPage:(id)sender;
- (IBAction) gotoPage:(id)sender;

- (IBAction) unlockDocument:(id)sender;

- (void) updateNavButtons;
- (void) pageChanged:(NSNotification*)aNotification;
- (void) displayStoppedTracking:(NSNotification*)aNotification;

- (IBAction) openInNewWindow:(id)sender;

@end
