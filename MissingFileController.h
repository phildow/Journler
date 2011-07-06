/* MissingFileController */

#import <Cocoa/Cocoa.h>

@class JournlerResource;
@class JournlerGradientView;

@interface MissingFileController : NSObject
{
    IBOutlet JournlerGradientView *errorBar;
    IBOutlet NSView *errorContent;
    IBOutlet NSView *locateAccessory;
    IBOutlet NSMatrix *locateOption;
    IBOutlet NSImageView *missingFileImageView;
	
	id delegate;
	JournlerResource *resource;
}

- (id) initWithResource:(JournlerResource*)aResource;

- (id) delegate;
- (void) setDelegate:(id)anObject;

- (JournlerResource*) resource;
- (void) setResource:(JournlerResource*)aResource;

- (NSView*) contentView;

- (IBAction)deleteMissingFile:(id)sender;
- (IBAction)locateMissingFile:(id)sender;
- (IBAction)searchForMissingFile:(id)sender;
- (IBAction)returnToEntry:(id)sender;

@end

@interface NSObject (MissingFileControllerDelegate)

- (void) fileController:(MissingFileController*)aFileController willDeleteResource:(JournlerResource*)aResource;
- (void) fileController:(MissingFileController*)aFileController didRelocateResource:(JournlerResource*)aResource;
- (void) fileController:(MissingFileController*)aFileController wantsToNavBack:(JournlerResource*)aResource;

@end
