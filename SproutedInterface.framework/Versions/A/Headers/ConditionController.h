/* ConditionController */

#import <Cocoa/Cocoa.h>

#define kConditionViewHeight 26

#define PDConditionContains		0
#define PDConditionNotContains	1
#define PDConditionBeginsWith	2
#define PDConditionEndsWith		3
#define PDConditionIs			4

#define PDConditionBefore		0
#define PDConditionAfter		1
#define PDConditionBetween		2
#define PDConditionInTheLast	3
#define PDConditionInTheNext	4

#define PDConditionDay			0
#define PDConditionWeek			1
#define PDConditionMonth		2

@interface ConditionController : NSObject
{
    IBOutlet NSView	*conditionView;
	IBOutlet NSView	*specifiedConditionView;
	IBOutlet NSPopUpButton *keyPop;
	
	IBOutlet NSButton *removeButton;
	
	int tag;
	id target;
	
	BOOL _allowsEmptyCondition;
	BOOL _autogeneratesDynamicDates;
	BOOL _sendsLiveUpdate;
	
}

- (id) initWithTarget:(id)anObject;
- (void) setInitialPredicate:(NSPredicate*)aPredicate;
- (void) setInitialCondition:(NSString*)condition;

- (NSView*) conditionView;
- (NSPredicate*) predicate;
- (NSString*) predicateString;

- (int) tag;
- (void) setTag:(int)newTag;

- (id) target;
- (void) setTarget:(id)anObject;

- (BOOL) sendsLiveUpdate;
- (void) setSendsLiveUpdate:(BOOL)updates;

- (BOOL) autogeneratesDynamicDates;
- (void) setAutogeneratesDynamicDates:(BOOL)autogenerate;

- (BOOL) allowsEmptyCondition;
- (void) setAllowsEmptyCondition:(BOOL)allowsEmpty;

- (BOOL) removeButtonEnabled;
- (void) setRemoveButtonEnabled:(BOOL)enabled;

- (IBAction) addCondition:(id)sender;
- (IBAction) removeCondition:(id)sender;
- (IBAction) changeCondition:(id)sender;
- (IBAction) changeConditionKey:(id)sender;

- (id) selectableView;
- (void) appropriateFirstResponder:(NSWindow*)aWindow;
- (void) removeFromSuper;

- (void) _sendUpdateIfRequested;

// utility for creating spotlight based conditions - subclasses feel free to use
- (NSString*) _spotlightConditionStringWithAttribute:(NSString*)anAttribute condition:(NSString*)aCondition operation:(int)anOperation;
- (NSString*) _spotlightConditionStringWithAttributes:(NSArray*)theAttributes condition:(NSString*)aCondition operation:(int)anOperation;

- (BOOL) validatePredicate;
@end


#pragma mark -

@interface NSObject (ConditionControllerDelegate)

- (void) conditionDidChange:(id)condition;

@end