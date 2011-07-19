/* DateSelectionController */

#import <Cocoa/Cocoa.h>
#import <SproutedInterface/SproutedInterface.h>

@class PDDatePicker;

@interface DateSelectionController : NSWindowController
{
	IBOutlet NSObjectController *objectController;
	
	IBOutlet PDGradientView *gradient;
	IBOutlet PDGradientView *gradientB;
	
	IBOutlet NSWindow *graphicalWindow;
	IBOutlet NSWindow *textualWindow;
	
	IBOutlet PDDatePicker *datePicker;
	
	NSWindow *targetWindow;
	
	id delegate;
	id representedObject;
	
	BOOL clearDateHidden;
	BOOL isSheet;
	NSRect sheetFrame;
	
	NSString *key;
	NSDate *date;
	
	BOOL usesGraphicalEditor;
}

- (id) initWithDate:(NSDate*)aDate key:(NSString*)aKey;

- (BOOL) usesGraphicalEditor;
- (void) setUsesGraphicalEditor:(BOOL)graphical;

- (NSDate*) date;
- (void) setDate:(NSDate*)aDate;

- (NSString*) key;
- (void) setKey:(NSString*)aString;

- (id) delegate;
- (void) setDelegate:(id)anObject;

- (id) representedObject;
- (void) setRepresentedObject:(id)anObject;

- (BOOL) clearDateHidden;
- (void) setClearDateHidden:(BOOL)hidden;

- (void) runAsSheetForWindow:(NSWindow*)window attached:(BOOL)sheet location:(NSRect)frame;
- (void) sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void  *)contextInfo;

- (IBAction) saveDate:(id)sender;
- (IBAction) cancelDate:(id)sender;
- (IBAction) clearDate:(id)sender;

@end

@interface NSObject (DateSelectionDelegate)

- (void) dateSelectorDidCancelDateSelection:(DateSelectionController*)aDateSelector;
- (void) dateSelector:(DateSelectionController*)aDateSelector didClearDateForKey:(NSString*)aKey;
- (void) dateSelector:(DateSelectionController*)aDateSelector didSaveDate:(NSDate*)aDate key:(NSString*)aKey;

@end