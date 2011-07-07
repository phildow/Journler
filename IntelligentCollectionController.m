#import "IntelligentCollectionController.h"
#import "JournlerConditionController.h"

#import "NSAlert+JournlerAdditions.h"

#import "Definitions.h"

@implementation IntelligentCollectionController

- (id)init 
{
	//NSLog(@"%s - beginning", __PRETTY_FUNCTION__);
	
	if ( self = [self initWithWindowNibName:@"IntelligentCollection"] ) 
	{
		//NSLog(@"if ( self = [self initWithWindowNibName:@\"IntelligentCollection\"] ) - beginning ");
		
		//NSLog(@"[self window]");
		[self window];

		conditions = [[NSMutableArray alloc] init];
		
		// add a single condition to our view
		
		//NSLog(@"[[JournlerConditionController alloc] initWithTarget:self]");
		JournlerConditionController *initialCondition = [[JournlerConditionController alloc] initWithTarget:self];
		
		[initialCondition setSendsLiveUpdate:YES];
		[initialCondition setRemoveButtonEnabled:NO];
		[initialCondition setAllowsEmptyCondition:YES];
		[conditions addObject:initialCondition];
		
		// clean up up - okay because the array now has ownership of this guy
		[initialCondition release];
		
		//NSLog(@"if ( self = [self initWithWindowNibName:@\"IntelligentCollection\"] ) - ending ");
    }
	
	//NSLog(@"%s - ending", __PRETTY_FUNCTION__);
    return self;
}

- (void) windowDidLoad 
{
	[containerView setBordered:NO];
	
	// we automatically calculate our keyloop
	[[self window] setAutorecalculatesKeyViewLoop:NO];
}

- (void) dealloc 
{
	[conditions release];
	[_predicates release];
	[_combinationStyle release];
	[_folderTitle release];
	[tagCompletions release];
	
	[super dealloc];
}

- (void)windowWillClose:(NSNotification *)aNotification {
	
}

#pragma mark -
#pragma mark Predicates

- (void) setInitialConditions:(NSArray*)initialConditions {
	
	int i;
	NSRect contentRect;
	
	// size our window to the appropriate height
	contentRect = [[[self window] contentView] frame];
	
	int newHeight = contentRect.size.height 
			+ ( kConditionViewHeight * ([initialConditions count]-1));
	contentRect.size.height = newHeight;
	
	NSRect newFrame = [[self window] frameRectForContentRect:contentRect];
	[[self window] setFrame:newFrame display:NO];

	
	// create one less than delivered taking into account the initial condition that is visible
	for ( i = 0; i < [initialConditions count]-1; i++ )
		[self addCondition:self];
	
	// update these guys
	for ( i = 0; i < [conditions count]; i++ )
		[[conditions objectAtIndex:i] setInitialCondition:[initialConditions objectAtIndex:i]];
	
}

- (NSArray*) conditions { return _predicates; }

- (void) setConditions:(NSArray*)predvalues {
	if ( _predicates != predvalues ) {
		[_predicates release];
		_predicates = [predvalues copyWithZone:[self zone]];
	}
}

#pragma mark -
#pragma mark Combination Style

- (void) setInitialCombinationStyle:(NSNumber*)style {
	[combinationPop selectItemWithTag:[style intValue]];
}

- (NSNumber*) combinationStyle { return _combinationStyle; }

- (void) setCombinationStyle:(NSNumber*)style {
	if ( _combinationStyle != style ) {
		[_combinationStyle release];
		_combinationStyle = [style copyWithZone:[self zone]];
	}
}

#pragma mark -
#pragma mark Title

- (void) setInitialFolderTitle:(NSString*)title {
	[folderName setStringValue:title];
}

- (NSString*) folderTitle { return _folderTitle; }

- (void) setFolderTitle:(NSString*)title {
	if ( _folderTitle != title ) {
		[_folderTitle release];
		_folderTitle = [title copyWithZone:[self zone]];
	}
}

- (NSArray*) tagCompletions
{
	return tagCompletions;
}

- (void) setTagCompletions:(NSArray*)anArray
{
	if ( tagCompletions != anArray )
	{
		[tagCompletions release];
		tagCompletions = [anArray copyWithZone:[self zone]];
	}
}

#pragma mark -
#pragma mark Other Methods

- (BOOL) cancelledChanges { return cancelledChanges; }

- (void) setCancelledChanges:(BOOL)didCancel {
	cancelledChanges = didCancel;
}

#pragma mark -
#pragma mark JournlerConditionController Delegate (NSTokenField)

- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring 
	indexOfToken:(int)tokenIndex indexOfSelectedItem:(int *)selectedIndex
{
	//NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self beginswith[cd] %@", substring];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self beginswith %@", substring];
	NSArray *completions = [[self tagCompletions] filteredArrayUsingPredicate:predicate];
	return completions;
}

#pragma mark -

- (IBAction)cancelFolder:(id)sender
{
	[self setCancelledChanges:YES];
	[NSApp abortModal];
}

- (IBAction)createFolder:(id)sender
{
	
	int i;
	BOOL valid = YES;
	
	//
	// check the available conditions
	for ( i = 0; i < [conditions count]; i++ ) {
		NSString *aPredicateString = [[conditions objectAtIndex:i] predicateString];
		if ( aPredicateString == nil ) { valid = NO; break; }
	}
	
	//
	// check to make sure that string prodcues a valid predicate
	if ( !valid ) {
		NSBeep();
		[[NSAlert badConditions] runModal];
		return;
		
	}
	
	[self setCancelledChanges:NO];
	[NSApp stopModal];
}

#pragma mark -

- (int) runAsSheetForWindow:(NSWindow*)window attached:(BOOL)sheet {
	
	int result;
	
	[self updateConditionsView];
	
	if ( sheet )
		[NSApp beginSheet: [self window] modalForWindow: window modalDelegate: nil
				didEndSelector: nil contextInfo: nil];
				
    result = [NSApp runModalForWindow: [self window]];
    
	// calculate the predicates
	
	int i;
	NSMutableArray *allPredicates = [[NSMutableArray alloc] init];
	
	for ( i = 0; i < [conditions count]; i++ ) 
	{
		NSString *aPredicateString = [[conditions objectAtIndex:i] predicateString];
		if ( aPredicateString != nil )
			[allPredicates addObject:aPredicateString];
	}
	
	// set internal copy of the values
	
	[self setConditions:[allPredicates autorelease]];
	[self setFolderTitle:[folderName stringValue]];
	[self setCombinationStyle:[NSNumber numberWithInt:[[combinationPop selectedItem] tag]]];
	
	if ( sheet )
		[NSApp endSheet: [self window]];
		
    [self close];
	return result;
}

- (void) updateConditionsView 
{
	// updates the ui display and recalculates the key view loop
	
	// for manually building the loop
	id lastInResponderLoop = folderName;
	
	// save our responder so we don't lose track of it
	NSResponder *theResponder = [[self window] firstResponder];
	
	int i;
	
	// make sure the predicates view knows how many rows to draw
	[predicatesView setNumConditions:[conditions count]];
	
	// remove all the subview
	for ( i = 0; i < [[predicatesView subviews] count]; i++ )
		[[[predicatesView subviews] objectAtIndex:i] removeFromSuperviewWithoutNeedingDisplay];
	
	// and add what's left or more according to our internal array
	for ( i = 0; i < [conditions count]; i++ ) {
		
		JournlerConditionController *aCondition = [conditions objectAtIndex:i];
		
		// reset the tag on each of these guys
		[aCondition setTag:i];
		
		// add the condition's view to our predicates view and position it
		[predicatesView addSubview:[aCondition conditionView]];
		[[aCondition conditionView] setFrameOrigin:NSMakePoint(0,(i*kConditionViewHeight))];
		
		if ( [aCondition selectableView] != nil ) {
			//
			// insert this to the responder chain
			[lastInResponderLoop setNextKeyView:[aCondition selectableView]];
			lastInResponderLoop = [aCondition selectableView];
		}
		
	}
	
	// make sure the predicates view knows to redraw itself, love those alternating rows
	[predicatesView setNeedsDisplay:YES];
	
	//
	// close the repsonder loop
	[lastInResponderLoop setNextKeyView:folderName];
	
	// is it okay to call this even if our responder is going away?
	[[self window] makeFirstResponder:theResponder];
	
}

- (void) updateKeyViewLoop
{
	// for manually recalculating the keyview loop
	id lastInResponderLoop = folderName;
	
	// save our responder so we don't lose track of it
	NSResponder *theResponder = [[self window] firstResponder];

	int i;
	// and add what's left or more according to our internal array
	for ( i = 0; i < [conditions count]; i++ ) 
	{
		JournlerConditionController *aCondition = [conditions objectAtIndex:i];
		if ( [aCondition selectableView] != nil ) {
			// insert this to the responder chain
			[lastInResponderLoop setNextKeyView:[aCondition selectableView]];
			lastInResponderLoop = [aCondition selectableView];
		}
	}
	
	// close the repsonder loop
	[lastInResponderLoop setNextKeyView:folderName];
	
	// is it okay to call this even if our responder is going away?
	[[self window] makeFirstResponder:theResponder];
}

- (void) conditionDidChange:(id)condition 
{
	[self updateKeyViewLoop];
}

#pragma mark -

- (void) addCondition:(id)sender {
	
	//
	// resize the window positive by our condition view height
	// and add a new condition to our view
	//
	
	// add a new condition to our view
	JournlerConditionController *aCondition = [[JournlerConditionController alloc] initWithTarget:self];
	[aCondition setSendsLiveUpdate:YES];
	[aCondition setAllowsEmptyCondition:YES];
	
	if ( sender == self )
		[conditions addObject:aCondition];
	else
		[conditions insertObject:aCondition atIndex:[sender tag]+1];

	// clean up - okay because the array now has ownership of this guy
	[aCondition release];

	// update our display
	[self updateConditionsView];
	
	// and resize
	if ( sender != self ) {
	
		//int newHeight = [[self window] frame].size.height + kConditionViewHeight;

		NSRect contentRect = [[self window] contentRectForFrameRect:[[self window] frame]];
		
		int newHeight = contentRect.size.height + kConditionViewHeight;
		
		contentRect.origin.y = contentRect.origin.y + contentRect.size.height - newHeight;
		contentRect.size.height = newHeight;
		NSRect newFrame = [[self window] frameRectForContentRect:contentRect];
		[[self window] setFrame:newFrame display:YES animate:YES];
	
	}
	
}

- (void) removeCondition:(id)sender {
	
	//
	// resize the window negative by our condition view height
	// and remove the condition at the index of this tag
	//
	
	// get rid of the subview first
	[[[conditions objectAtIndex:[sender tag]] conditionView] removeFromSuperviewWithoutNeedingDisplay];
	
	// and the condition second
	[conditions removeObjectAtIndex:[sender tag]];
	
	// update the conditions view, this subview already removed
	[self updateConditionsView];
	
	// resize the window and the conditions view with it
	//int newHeight = [[self window] frame].size.height - kConditionViewHeight;

	NSRect contentRect = [[self window] contentRectForFrameRect:[[self window] frame]];
	
	int newHeight = contentRect.size.height - kConditionViewHeight;
	
	contentRect.origin.y = contentRect.origin.y + contentRect.size.height - newHeight;
	contentRect.size.height = newHeight;
	NSRect newFrame = [[self window] frameRectForContentRect:contentRect];
	[[self window] setFrame:newFrame display:YES animate:YES];
}

#pragma mark -

- (IBAction) showFoldersHelp:(id)senderp {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"SmartFolders" inBook:@"JournlerHelp"];
}

@end
