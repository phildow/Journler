/* JournlerConditionController */

/*
 Redistribution and use in source and binary forms, with or without modification, are permitted
 provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions
 and the following disclaimer in the documentation and/or other materials provided with the
 distribution.
 
 * Neither the name of the author nor the names of its contributors may be used to endorse or
 promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// Basically, you can use the code in your free, commercial, private and public projects
// as long as you include the above notice and attribute the code to Philip Dow / Sprouted
// If you use this code in an app send me a note. I'd love to know how the code is used.

// Please also note that this copyright does not supersede any other copyrights applicable to
// open source code used herein. While explicit credit has been given in the Journler about box,
// it may be lacking in some instances in the source code. I will remedy this in future commits,
// and if you notice any please point them out.

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
