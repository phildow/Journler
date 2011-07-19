/* ExportJournalController */

#import <Cocoa/Cocoa.h>

@interface ExportJournalController : NSObject
{
    IBOutlet NSView *_contentView;
    IBOutlet NSPopUpButton *_dataFormat;
    IBOutlet NSDatePicker *_dateFrom;
    IBOutlet NSDatePicker *_dateTo;
    IBOutlet NSMatrix *_fileMode;
	IBOutlet NSButton *_modifiesFileCreation;
	IBOutlet NSButton *_modifiesFileModified;
	IBOutlet NSButton *_includeHeaderCheck;
}

- (NSView*) contentView;

- (NSInteger) dataFormat;
- (void) setDataFormat:(NSInteger)format;

- (NSDate*) dateFrom;
- (void) setDateFrom:(NSDate*)date;

- (NSDate*) dateTo;
- (void) setDateTo:(NSDate*)date;

- (NSInteger) fileMode;
- (void) setFileMode:(NSInteger)mode;

- (BOOL) modifiesFileCreationDate;
- (void) setModifiesFileCreationDate:(BOOL)modifies;

- (BOOL) modifiesFileModifiedDate;
- (void) setModifiesFileModifiedDate:(BOOL)modifies;

- (BOOL) includeHeader;
- (void) setIncludeHeader:(BOOL)include;

@end
