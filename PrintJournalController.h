/* PrintJournalController */

#import <Cocoa/Cocoa.h>

#define kPrintModeText	1
#define kPrintModeTextAndImages	2

@interface PrintJournalController : NSWindowController
{
    IBOutlet NSDatePicker *_dateFrom;
    IBOutlet NSDatePicker *_dateTo;
    IBOutlet NSImageView *_modeImageView;
    IBOutlet NSMatrix *_printMode;
}

- (int) runAsSheetForWindow:(NSWindow*)window attached:(BOOL)sheet;

- (NSDate*) dateFrom;
- (void) setDateFrom:(NSDate*)date;

- (NSDate*) dateTo;
- (void) setDateTo:(NSDate*)date;

- (int) printMode;

- (IBAction)cancelPrint:(id)sender;
- (IBAction)changeMode:(id)sender;
- (IBAction)continuePrint:(id)sender;

@end
