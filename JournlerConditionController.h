/* JournlerConditionController */

#import <Cocoa/Cocoa.h>
#import <SproutedInterface/SproutedInterface.h>

#define kConditionViewHeight 26

@class LabelPicker;

@interface JournlerConditionController : ConditionController
{
    //IBOutlet NSView			*conditionView;
	//IBOutlet NSView			*specifiedConditionView;
	//IBOutlet NSPopUpButton	*keyPop;
	
	//IBOutlet NSButton		*removeButton;
	IBOutlet NSSegmentedControl *addAndRemoveButton;
	
	IBOutlet NSView			*stringConditionView;
	IBOutlet NSTextField	*stringConditionValue;
	IBOutlet NSPopUpButton	*stringOperationPop;
	
	IBOutlet NSView			*dateConditionView;
	IBOutlet NSPopUpButton	*dateOperationPop;
	
	IBOutlet NSView			*dateDetailsPlaceholder;
	NSView	*dateDetailsView;
	
	IBOutlet NSView			*dateDatedView;
	IBOutlet NSTextField	*dateAndLabel;
    IBOutlet NSDatePicker	*dateConditionAValue;
    IBOutlet NSDatePicker	*dateConditionBValue;
	
	IBOutlet NSView			*dateNumberedView;
	IBOutlet NSTextField	*dateNumberedValue;
	IBOutlet NSPopUpButton	*dateNumberedPop;
    
	IBOutlet NSView			*labelConditionView;
	IBOutlet LabelPicker	*labelPicker;
	IBOutlet NSPopUpButton	*labelOperationPop;
	
	IBOutlet NSView			*markingConditionView;
	IBOutlet NSPopUpButton	*markingOperationPop;
	
	IBOutlet NSView			*resourcesConditionView;
	IBOutlet NSPopUpButton	*resourcesOperationPop;
	IBOutlet NSPopUpButton	*resourcesTypePop;
	
	IBOutlet NSView			*tagsView;
	IBOutlet NSPopUpButton	*tagsOperationPop;
	IBOutlet NSTokenField	*tagsField;
	
	//id		target;
	
	//NSInteger tag;
	
	//BOOL _allowsEmptyCondition;
	//BOOL _autogeneratesDynamicDates;
	//BOOL _sendsLiveUpdate;
	
}

- (id) initWithTarget:(id)anObject;
- (void) setInitialCondition:(NSString*)condition;

- (NSInteger) tag;
- (void) setTag:(NSInteger)newTag;

- (BOOL) sendsLiveUpdate;
- (void) setSendsLiveUpdate:(BOOL)updates;

- (BOOL) autogeneratesDynamicDates;
- (void) setAutogeneratesDynamicDates:(BOOL)autogenerate;

- (BOOL) allowsEmptyCondition;
- (void) setAllowsEmptyCondition:(BOOL)allowsEmpty;

- (NSView*) conditionView;
- (void) appropriateFirstResponder:(NSWindow*)aWindow;

- (IBAction) addCondition:(id)sender;
- (IBAction) removeCondition:(id)sender;

- (IBAction) addOrRemoveCondition:(id)sender;

- (IBAction) changeConditionKey:(id)sender;
- (IBAction) changeDateCondition:(id)sender;
- (IBAction) changeStringCondition:(id)sender;
- (IBAction) changeMarkingCondition:(id)sender;
- (IBAction) changeTagsCondition:(id)sender;

- (void) setRemoveButtonEnabled:(BOOL)enabled;

- (NSString*) predicateString;

- (id) selectableView;

- (void) removeFromSuper;

- (IBAction) changeCondition:(id)sender;
- (void) _sendUpdateIfRequested;

@end


#pragma mark -

@interface NSObject (JournlerConditionControllerDelegate)

- (void) conditionDidChange:(id)condition;

- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring 
	indexOfToken:(NSInteger)tokenIndex indexOfSelectedItem:(NSInteger*)selectedIndex;

@end
