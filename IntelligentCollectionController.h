/* IntelligentCollectionController */

#import <Cocoa/Cocoa.h>
#import <SproutedInterface/SproutedInterface.h>

@class JournlerConditionController;
@interface IntelligentCollectionController : NSWindowController
{
    IBOutlet NSPopUpButton				*combinationPop;
    IBOutlet NSTextField				*folderName;
    IBOutlet CollectionManagerView		*predicatesView;
	
	IBOutlet PDGradientView *containerView;
	
	NSMutableArray			*conditions;
	
	NSArray					*_predicates;
	NSNumber				*_combinationStyle;
	NSString				*_folderTitle;
	
	BOOL					cancelledChanges;
	
	NSArray *tagCompletions;
}

// ------ predicates ------------------------------------------

- (void) setInitialConditions:(NSArray*)initialConditions;

- (NSArray*) conditions;
- (void) setConditions:(NSArray*)predvalues;

// ------ combination -----------------------------------------

- (void) setInitialCombinationStyle:(NSNumber*)style;

- (NSNumber*) combinationStyle;
- (void) setCombinationStyle:(NSNumber*)style;

// ------ title ------------------------------------------------

- (void) setInitialFolderTitle:(NSString*)title;

- (NSString*) folderTitle;
- (void) setFolderTitle:(NSString*)title;

- (NSArray*) tagCompletions;
- (void) setTagCompletions:(NSArray*)anArray;

// ------ other methods ----------------------------------------

- (BOOL) cancelledChanges;
- (void) setCancelledChanges:(BOOL)didCancel;

- (IBAction)cancelFolder:(id)sender;
- (IBAction)createFolder:(id)sender;

- (int) runAsSheetForWindow:(NSWindow*)window attached:(BOOL)sheet;

- (void) updateConditionsView;
- (void) updateKeyViewLoop;

- (void) addCondition:(id)sender;
- (void) removeCondition:(id)sender;

- (IBAction) showFoldersHelp:(id)sender;

@end
