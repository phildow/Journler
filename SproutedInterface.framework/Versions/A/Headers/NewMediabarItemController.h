/* NewMediabarItemController */


#import <Cocoa/Cocoa.h>

@class JournlerGradientView;
@class MediabarItemApplicationPicker;

@interface NewMediabarItemController : NSWindowController
{
    IBOutlet MediabarItemApplicationPicker *applicationField;
    IBOutlet NSTextView *scriptText;
	IBOutlet NSTextField *titleField;
	
	IBOutlet NSTextField *appnameField;
	IBOutlet NSImageView *appImageView;
	
	IBOutlet NSObjectController *objectController;
	
	BOOL isSheet;
	NSRect sheetFrame;
	
	id delegate;
	NSWindow *targetWindow;
	
	NSImage *icon;
	NSString *title;
	NSString *helptip;
	NSString *filepath;
	NSAttributedString *scriptSource;
	
	id representedObject;
	
	BOOL wantsScript;
	BOOL wantsFile;
}

- (id) initWithDictionaryRepresentation:(NSDictionary*)aDictionary;
- (NSDictionary*) dictionaryRepresentation;

- (id) delegate;
- (void) setDelegate:(id)anObject;

- (NSImage *)icon;
- (void) setIcon:(NSImage*)anImage;

- (NSString *)title;
- (void) setTitle:(NSString*)aString;

- (NSString *)helptip;
- (void) setHelptip:(NSString*)aString;

- (NSString *)filepath;
- (void) setFilepath:(NSString*)aString;

- (NSAttributedString *)scriptSource;
- (void) setScriptSource:(NSAttributedString*)anAttributedString;

- (id) representedObject;
- (void) setRepresentedObject:(id)anObject;

- (BOOL) wantsScript;
- (void) setWantsScript:(BOOL)aBool;

- (BOOL) wantsFile;
- (void) setWantsFile:(BOOL)aBool;

- (IBAction)cancel:(id)sender;
- (IBAction)chooseApplication:(id)sender;
- (IBAction)help:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction) verifyDraggedImage:(id)sender;

- (void) runAsSheetForWindow:(NSWindow*)window attached:(BOOL)sheet location:(NSRect)frame;
- (void) sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;

@end

@interface NSObject (MediaBarItemCreatorDelegate)

- (void) mediabarItemCreateDidCancelAction:(NewMediabarItemController*)mediabarItemCreator;
- (void) mediabarItemCreateDidSaveAction:(NewMediabarItemController*)mediabarItemCreator;

@end