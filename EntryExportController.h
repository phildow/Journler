/* EntryExportController */

#import <Cocoa/Cocoa.h>

typedef enum {
	kExportFormatRTF = 0,
	kExportFormatDOC = 1,
	kExportFormatRTFD = 2,
	kExportFormatPDF = 3,
	kExportFormatHTML = 4,
	kExportFormatTXT = 5
} EntryExportFormat;

typedef enum {
	kExportBySortedFolders = 0,
	kExportByFolder = 1,
	kExportBySingleFile = 2
} EntryExportMode;

@interface EntryExportController : NSObject
{
    IBOutlet NSView *_contentView;
	IBOutlet NSObjectController *objectController;
	
    IBOutlet NSPopUpButton *_dataFormat;
    IBOutlet NSMatrix *_fileMode;
	IBOutlet NSButton *_modifiesFileCreation;
	IBOutlet NSButton *_modifiesFileModified;
	IBOutlet NSButton *_includeHeaderCheck;
	
	BOOL updatesFileExtension;
	
	int fileMode;
	int dataFormat;
	BOOL includeHeader;
	BOOL modifiesFileCreationDate;
	BOOL modifiesFileModifiedDate;
}

- (NSView*) contentView;
- (void) ownerWillClose:(NSNotification*)aNotification;

- (int) dataFormat;
- (void) setDataFormat:(int)format;

- (int) fileMode;
- (void) setFileMode:(int)mode;

- (BOOL) updatesFileExtension;
- (void) setUpdatesFileExtension:(BOOL)updates;

- (BOOL) modifiesFileCreationDate;
- (void) setModifiesFileCreationDate:(BOOL)modifies;

- (BOOL) modifiesFileModifiedDate;
- (void) setModifiesFileModifiedDate:(BOOL)modifies;

- (BOOL) includeHeader;
- (void) setIncludeHeader:(BOOL)include;

- (BOOL) choosesFileMode;
- (void) setChoosesFileMode:(BOOL)chooses;

- (IBAction) changeFileMode:(id)sender;
- (IBAction) changeFileType:(id)sender;

- (BOOL) commitEditing;

@end
