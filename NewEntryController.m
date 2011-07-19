#import "NewEntryController.h"
#import "Definitions.h"

#import "JournlerCollection.h"
#import "JournlerJournal.h"
#import "JournlerEntry.h"
#import "JournlerCondition.h"

#import "DropBoxFoldersController.h"
#import "DropBoxSourceList.h"

#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>

/*
#import "LabelPicker.h"
#import "PDGradientView.h"
#import "NSOutlineView_Extensions.h"
#import "NSOutlineView_ProxyAdditions.h"
#import "NSString+PDStringAdditions.h"
*/

@implementation NewEntryController

static NSSortDescriptor *FoldersByIndexSortPrototype()
{
	static NSSortDescriptor *descriptor = nil;
	if ( descriptor == nil )
	{
		descriptor = [[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES selector:@selector(compare:)];
	}
	return descriptor;
}

#pragma mark -

- (id) init
{
	return [self initWithJournal:nil];
}

- (id)initWithJournal:(JournlerJournal*)aJournal
{    
	if ( self = [self initWithWindowNibName:@"NewEntry"] ) 
	{
		journal = aJournal;
		
		title = [NSLocalizedString(@"untitled title", @"") retain];
		category = [[NSString alloc] init];
		tags = [[NSArray alloc] init];
		date = [[NSDate date] retain];
		dateDue = [[NSDate date] retain];
		marking = [NSNumber numberWithInteger:0];
		
		alreadyEditedCategory = NO;
		
		[self window];
    }
    return self;
}

- (void) windowDidLoad 
{
	[[self window] setAutorecalculatesKeyViewLoop:YES];
	[containerView setBordered:NO];
	
	// prepare the collections
	/*
	NSMenu *collectionsMenu = [[[NSMenu alloc] init] autorelease];
	[[self valueForKeyPath:@"journal.rootCollection"] flatMenuRepresentation:&collectionsMenu 
			target:self action:@selector(selectFolder:) smallImages:YES inset:0];
	
	[collectionsMenu setAutoenablesItems:NO];
	
	// go through the menu and disable anything that isn't a folder
	NSInteger i;
	for ( i = [collectionsMenu numberOfItems]-1; i >= 0; i-- ) 
	{
		if ( [[collectionsMenu itemAtIndex:i] representedObject] == nil )
			[[collectionsMenu itemAtIndex:i] setEnabled:NO];
		
		//else if ( [[[[collectionsMenu itemAtIndex:i] representedObject] valueForKey:@"typeID"] integerValue] != PDCollectionTypeIDFolder )
		//	[[collectionsMenu itemAtIndex:i] setEnabled:NO];
		
		if ( [[[collectionsMenu itemAtIndex:i] representedObject] isSmartFolder] && ![[[collectionsMenu itemAtIndex:i] representedObject] canAutotag:nil] )
			[[collectionsMenu itemAtIndex:i] setEnabled:NO];
		
		if ( [[[[collectionsMenu itemAtIndex:i] representedObject] valueForKey:@"typeID"] integerValue] == PDCollectionTypeIDLibrary )
			[collectionsMenu removeItemAtIndex:i];
			
		else if ( [[[[collectionsMenu itemAtIndex:i] representedObject] valueForKey:@"typeID"] integerValue] == PDCollectionTypeIDTrash )
			[collectionsMenu removeItemAtIndex:i];
	}
	
	[collectionsMenu insertItem:[NSMenuItem separatorItem] atIndex:0];
	[collectionsMenu insertItemWithTitle:NSLocalizedString(@"no selection",@"") action:nil keyEquivalent:@"" atIndex:0];
	
	[collectionField setMenu:collectionsMenu];
	*/

	// prepare the categories and select the default
	NSArray *categoriesList = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Journler Categories List"];
	
	[categoryField addItemsWithObjectValues: 
			[categoriesList sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] ];
	
	[self setCategory:[JournlerEntry defaultCategory]];
					
	if ( [categoryField numberOfVisibleItems] > [categoryField numberOfItems] )
		[categoryField setNumberOfVisibleItems:[categoryField numberOfItems]];
	
	// disclose if last selection asked for it
	[disclose setState:[[NSUserDefaults standardUserDefaults] integerForKey:@"NewEntryDiscloseState"]];
	[self disclose:disclose];
	
	[self bind:@"includeDateDue" toObject:[NSUserDefaultsController sharedUserDefaultsController] 
			withKeyPath:@"values.NewEntryWithDueDate" options:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithBool:NO], NSNullPlaceholderBindingOption, nil]];
		
		
	// the folders controller must know the actual root (vs. the roots children)
	[sourceController setRootCollection:[[self journal] valueForKey:@"rootCollection"]];
	
	// populate the list with regular and smart folders
	NSPredicate *folderFilter = [NSPredicate predicateWithFormat:@"isRegularFolder == YES OR isSmartFolder == YES"];
	NSArray *filteredFolders = [[[self journal] rootFolders] filteredArrayUsingPredicate:folderFilter];
	[sourceController setContent:filteredFolders];
	
	// set the sort descriptors on the source list
	[sourceController setSortDescriptors:[NSArray arrayWithObject:FoldersByIndexSortPrototype()]];
	
	// appearance bindings
	/*
	[sourceList bind:@"font" toObject:[NSUserDefaultsController sharedUserDefaultsController] 
			withKeyPath:@"values.FoldersTableFont" options:[NSDictionary dictionaryWithObjectsAndKeys:
			@"NSUnarchiveFromData", NSValueTransformerNameBindingOption,
			[NSFont controlContentFontOfSize:11], NSNullPlaceholderBindingOption, nil]];
	*/
			
	[sourceList bind:@"backgroundColor" toObject:[NSUserDefaultsController sharedUserDefaultsController] 
			withKeyPath:@"values.FolderBackgroundColor" options:[NSDictionary dictionaryWithObjectsAndKeys:
			@"NSUnarchiveFromData", NSValueTransformerNameBindingOption,
			[NSColor colorWithCalibratedHue:234.0/400.0 saturation:1.0/100.0 brightness:97.0/100.0 alpha:1.0], NSNullPlaceholderBindingOption, nil]];

	// source list state
	NSArray *sourceListState;
	NSData *sourceListStateData;
	if ( ( sourceListStateData = [[NSUserDefaults standardUserDefaults] dataForKey:@"NewEntrySourceListState"] ) != nil 
		&& ( sourceListState = [NSKeyedUnarchiver unarchiveObjectWithData:sourceListStateData] ) != nil )
		[sourceList restoreStateFromArray:sourceListState];
}

- (void) dealloc 
{
	#ifdef __DEBUG__
		NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	[category release];
	[title release];
	[tags release];
	[date release];
	[marking release];
	[tagCompletions release];
	
	[super dealloc];
}

- (void)windowWillClose:(NSNotification *)aNotification {
	
	NSArray *sourceListState = [sourceList stateArray];
	NSData *sourceListStateData = [NSKeyedArchiver archivedDataWithRootObject:sourceListState];
	[[NSUserDefaults standardUserDefaults] setObject:sourceListStateData forKey:@"EntryEntrySourceListState"];
	
	[sourceList setDelegate:nil];
	[self unbind:@"includeDateDue"];
	[objectController unbind:@"contentObject"];
	[objectController setContent:nil];
}

#pragma mark -

- (JournlerJournal*) journal
{
	return journal;
}

- (void) setJournal:(JournlerJournal*)aJournal
{
	journal = aJournal;
}

- (NSString*) title 
{ 
	return title; 
}

- (void) setTitle:(NSString*)aString
{
	if ( title != aString ) 
	{
		[title release];
		title = [aString copyWithZone:[self zone]];
	}
}

- (NSDate*) date 
{ 	
	return date;	
}

- (void) setDate:(NSDate*)aDate 
{
	if ( date != aDate ) 
	{
		[date release];
		date = [aDate copyWithZone:[self zone]];
	}
}

- (NSDate*) dateDue
{
	return dateDue;
}

- (void) setDateDue:(NSDate*)aDate
{
	if ( dateDue != aDate )
	{
		[dateDue release];
		dateDue = [aDate copyWithZone:[self zone]];
	}
}

- (BOOL) includeDateDue
{
	return includeDateDue;
}

- (void) setIncludeDateDue:(BOOL)include
{
	includeDateDue = include;
}

- (NSArray*) tags
{
	return tags;
}

- (void) setTags:(NSArray*)anArray
{
	if ( tags != anArray )
	{
		[tags release];
		tags = [anArray copyWithZone:[self zone]];
	}
}

- (NSString*) category 
{ 
	return category; 
}

- (void) setCategory:(NSString*)aString 
{
	if ( category != aString ) 
	{
		[category release];
		category = [aString copyWithZone:[self zone]];
	}
}


- (NSNumber*) marking
{
	return marking;
}

- (void) setMarking:(NSNumber*)aNumber
{
	if ( marking != aNumber )
	{
		[marking release];
		marking = [aNumber copyWithZone:[self zone]];
	}
}



- (NSNumber*) labelValue
{ 
	return [NSNumber numberWithInteger:[labelPicker labelSelection]];
}

- (void) setLabelValue:(NSNumber*)aNumber
{
	[labelPicker setLabelSelection:[aNumber integerValue]];
	[labelPicker setNeedsDisplay:YES];
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

// DEPRECATED
- (JournlerCollection*) selectedCollection 
{	
	return [[collectionField selectedItem] representedObject];	
}

// DEPRECATED
- (void) setSelectedCollection:(JournlerCollection*)aCollection 
{
	// go through the menu looking at the represented items, select the appropriate one
	if ( ![self isWindowLoaded] ) [self window];
	
	if ( aCollection ) 
	{
		[collectionField selectItemWithTag:[[aCollection valueForKey:@"tagID"] integerValue]];
		[self selectFolder:[collectionField selectedItem]];
	}
}

- (NSArray*) selectedFolders
{
	return [sourceController selectedObjects];
}

- (void) setSelectedFolders:(NSArray*)anArray
{
	if ( anArray == nil ) return;
	if ( ![self isWindowLoaded] ) [self window];
	
	BOOL firstSelection = YES;
	
    for ( JournlerCollection *aFolder in anArray )
	{
		if ( [aFolder isRegularFolder] || ( [aFolder isSmartFolder] && [aFolder canAutotag:nil] ) )
		{
			[sourceController selectCollection:aFolder byExtendingSelection:YES];
			
			if ( firstSelection == YES )
			{
				[sourceList scrollRowToVisible:[sourceList rowForOriginalItem:aFolder]];
				firstSelection = NO;
			}
		}
	}
}

#pragma mark -

// DEPRECATED
- (IBAction) selectFolder:(id)sender
{
	// gives me a chance to update our visual cues based on the folders conditions
	// support or conditioning so that the list number of conditions are set
	
	if ( YES )
	{
		return;
	}
		
	JournlerCollection *theFolder = [sender representedObject];
	if ( theFolder == nil )
	{
		NSBeep(); return;
	}
	
	// attempt to autotag the entry based on my conditions and the conditions of my parents
	// this should be a category on ns predicate
	
	BOOL added = YES;
	
	NSArray *allConditions = [theFolder allConditions:YES];
	#ifdef __DEBUG __
	NSLog([allConditions description]);
	#endif
	
	// clear the category field if this folder edits the category
	if ( alreadyEditedCategory == NO && [theFolder autotagsKey:@"category"] )
	{
		alreadyEditedCategory = YES;
		[self setCategory:[NSString string]];
	}
	
	// supported conditions:
	// 1. title	2. category	3. keywords 4. label 5. mark
	
    for ( NSDictionary *aDictionary in allConditions )
	{
		NSArray *localConditions = [aDictionary objectForKey:@"conditions"];
		NSNumber *localCombination = [aDictionary objectForKey:@"combinationStyle"];
		
		BOOL alreadyAddedLocal = NO;
		
        for ( NSString *aCondition in localConditions )
		{
			NSDictionary *conditionOp = [JournlerCondition operationForCondition:aCondition entry:nil];
			#ifdef __DEBUG_
			NSLog([conditionOp description]); 
			#endif
			
			if ( conditionOp == nil )
			{
				// don't worry about it, a later condition will suffice (we already checked for canAutotag, so it should be there)
				if ( [localCombination integerValue] == 0 )
					continue;
				
				// otherwise, we're finished
				else if ( [localCombination integerValue] == 1 )
				{
					added = NO;
					goto bail;
				}
			}
			
			// we're finished if one of the conditions from this set has already been added and the op is any
			else if ( alreadyAddedLocal == YES && [localCombination integerValue] == 0 )
				continue;
		
			id theOriginalValue;
			
			id theValue = [conditionOp objectForKey:kOperationDictionaryKeyValue];
			NSString *theKey = [conditionOp objectForKey:kOperationDictionaryKeyKey];
			NSInteger theOperation = [[conditionOp objectForKey:kOperationDictionaryKeyOperation] integerValue];
			
			// make some modifications to the key to support our keys
			//if ( [theKey isEqualToString:@"keywords"] )
			//	theKey = @"tags";
				
			if ( [theKey isEqualToString:@"marked"] )
				theKey = @"marking";
			
			else if ( [theKey isEqualToString:@"label"] )
				theKey = @"labelValue";
			
			switch ( theOperation )
			{
			case kKeyOperationNilOut:
				// the simplest operation, for use with tags right now
				[self setValue:nil forKey:theKey];
				break;
				
			case kKeyOperationAddObjects:
				theOriginalValue = (NSMutableArray*)[[[self valueForKey:theKey] mutableCopyWithZone:[self zone]] autorelease];
				[(NSMutableArray*)theOriginalValue addObjectsFromArray:theValue];
				[self setValue:theOriginalValue forKey:theKey];
				break;
			
			case kKeyOperationRemoveObjects:
				theOriginalValue = (NSMutableArray*)[[[self valueForKey:theKey] mutableCopyWithZone:[self zone]] autorelease];
				[(NSMutableArray*)theOriginalValue removeObjectsInArray:theValue];
				[self setValue:theOriginalValue forKey:theKey];
				break;
				
			case kKeyOperationSetString:
				
				theOriginalValue = (NSMutableString*)[[[self valueForKey:theKey] mutableCopyWithZone:[self zone]] autorelease];
				[(NSMutableString*)theOriginalValue setString:theValue];
				[self setValue:theOriginalValue forKey:theKey];
				break;
			
			case kKeyOperationSetNumber:
				
				// easy
				[self setValue:theValue forKey:theKey];
				break;
			
			case kKeyOperationSetAttributedString:
				
				//theOriginalValue = [[[NSAttributedString alloc] initWithString:theValue attributes:[JournlerEntry defaultTextAttributes]] autorelease];
				//[self setValue:theOriginalValue forKey:theKey];
				break;
			
			case kKeyOperationAppendString:
				
				theOriginalValue = (NSMutableString*)[[[self valueForKey:theKey] mutableCopyWithZone:[self zone]] autorelease];
				
				if ( [theOriginalValue length] == 0 )
					[(NSMutableString*)theOriginalValue setString:theValue];
				else if ( [theOriginalValue rangeOfString:theValue options:NSCaseInsensitiveSearch range:NSMakeRange(0,[theOriginalValue length])].location == NSNotFound )
					[(NSMutableString*)theOriginalValue appendFormat:@" %@", theValue];
					
				[self setValue:theOriginalValue forKey:theKey];
				break;
			
			case kKeyOperationRemoveString:
				
				theOriginalValue = (NSMutableString*)[[[self valueForKey:theKey] mutableCopyWithZone:[self zone]] autorelease];
				[(NSMutableString*)theOriginalValue replaceOccurrencesOfString:theValue 
						withString:[NSString string] options:NSCaseInsensitiveSearch range:NSMakeRange(0,[theOriginalValue length])];
						
						
				[self setValue:theOriginalValue forKey:theKey];
				break;
			
			case kKeyOperationPrependString:
				
				theOriginalValue = (NSMutableString*)[[[self valueForKey:theKey] mutableCopyWithZone:[self zone]] autorelease];
				
				if ( [theOriginalValue length] == 0 )
					[(NSMutableString*)theOriginalValue setString:theValue];
				else if ( [theOriginalValue rangeOfString:theValue options:NSCaseInsensitiveSearch range:NSMakeRange(0,[theOriginalValue length])].location != 0 )
					[(NSMutableString*)theOriginalValue insertString:[NSString stringWithFormat:@"%@ ", theValue] atIndex:0];
					
				[self setValue:theOriginalValue forKey:theKey];
				break;
			
			case kKeyOperationAppendAttributedString:
				
				/*
				theOriginalValue = (NSMutableAttributedString*)[[[anEntry valueForKey:theKey] mutableCopyWithZone:[self zone]] autorelease];
				if ( [theOriginalValue length] == 0 )
					[(NSMutableAttributedString*)theOriginalValue setAttributedString:
					[[[NSAttributedString alloc] initWithString:theValue attributes:[JournlerEntry defaultTextAttributes]] autorelease]];
				else
					[(NSMutableAttributedString*)theOriginalValue replaceCharactersInRange:NSMakeRange([theOriginalValue length],0) withString:[NSString stringWithFormat:@" %@", theValue]];
				
				[anEntry setValue:theOriginalValue forKey:theKey];
				*/
				break;
			
			case kKeyOperationRemoveAttributedString:
				
				/*
				theOriginalValue = (NSMutableAttributedString*)[[[anEntry valueForKey:theKey] mutableCopyWithZone:[self zone]] autorelease];
				//else if ( [[(NSMutableAttributedString*) theOriginalValue string] rangeOfString:theValue options:NSCaseInsensitiveSearch range:NSMakeRange(0,[theOriginalValue length])].location != 0 )
				//	[(NSMutableAttributedString*)theOriginalValue 
				#warning get the else here working
				
				[anEntry setValue:theOriginalValue forKey:theKey];
				*/
				break;
			
			case kKeyOperationPrependAttributedString:
				/*
				theOriginalValue = (NSMutableAttributedString*)[[[anEntry valueForKey:theKey] mutableCopyWithZone:[self zone]] autorelease];
				if ( [theOriginalValue length] == 0 )
					[(NSMutableAttributedString*)theOriginalValue setAttributedString:
					[[[NSAttributedString alloc] initWithString:theValue attributes:[JournlerEntry defaultTextAttributes]] autorelease]];
				else
					[(NSMutableAttributedString*)theOriginalValue replaceCharactersInRange:NSMakeRange(0,0) withString:[NSString stringWithFormat:@"%@ ", theValue]];
					
				[anEntry setValue:theOriginalValue forKey:theKey];
				*/
				break;
			}
			
			alreadyAddedLocal = YES;
		}
	}

bail:
	
	return;
}

- (IBAction) didChangeCategory:(id)sender
{
	alreadyEditedCategory = YES;
}

- (void)comboBoxSelectionDidChange:(NSNotification *)aNotification
{
	if ( [aNotification object] == categoryField )
		[self didChangeCategory:categoryField];
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
	if ( [aNotification object] == categoryField )
		[self didChangeCategory:categoryField];
}

#pragma mark -

- (NSInteger) runAsSheetForWindow:(NSWindow*)window attached:(BOOL)sheet
{
	NSInteger result;
	
	if ( sheet )
		[NSApp beginSheet: [self window] modalForWindow: window modalDelegate: nil
				didEndSelector: nil contextInfo: nil];
	
    result = [NSApp runModalForWindow: [self window]];
	
	if ( ![objectController commitEditing] )
		NSLog(@"%s - unable to commit editing", __PRETTY_FUNCTION__);
	
	if ( sheet )
		[NSApp endSheet: [self window]];
		
	[self close];
	return result;
}

#pragma mark -

- (IBAction)cancel:(id)sender
{
	[NSApp abortModal];
}

- (IBAction)okay:(id)sender
{
	
	[NSApp stopModal];
}

- (IBAction)disclose:(id)sender
{	
	NSRect newFrame;
	NSRect contentRect;
	
	// expand the window
	switch ( [sender state] ) 
	{
	case NSOnState:

		//height = 288 resize the window
		contentRect = [[self window] contentRectForFrameRect:[[self window] frame]];
		contentRect.origin.y = contentRect.origin.y + contentRect.size.height - 412;
		contentRect.size.height = 412;
		newFrame = [[self window] frameRectForContentRect:contentRect];
		
		[[self window] setFrame:newFrame display:YES animate:YES];
		
		[advancedView setFrame:NSMakeRect(0,45,390,250)];
		[containerView addSubview:advancedView];
		
		break;
	
	case NSOffState:

		//height = 172 resize the window
		
		[advancedView removeFromSuperview];
		
		contentRect = [[self window] contentRectForFrameRect:[[self window] frame]];
		contentRect.origin.y = contentRect.origin.y + contentRect.size.height - 172;
		contentRect.size.height = 172;
		newFrame = [[self window] frameRectForContentRect:contentRect];
		
		[[self window] setFrame:newFrame display:YES animate:YES];
		
		break;
	
	}
	
	[[self window] recalculateKeyViewLoop];
	[[NSUserDefaults standardUserDefaults] setInteger:[sender state] forKey:@"NewEntryDiscloseState"];
}

- (IBAction)help:(id)sender
{
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"EntryCreation" inBook:@"JournlerHelp"];
}

#pragma mark -
#pragma mark NSTokenFieldCell Delegation

- (BOOL)tokenField:(NSTokenField *)tokenField hasMenuForRepresentedObject:(id)representedObject
{
	return NO;
}

- (NSMenu *)tokenField:(NSTokenField *)tokenField menuForRepresentedObject:(id)representedObject
{
	return nil;
}

- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring 
	indexOfToken:(NSInteger)tokenIndex indexOfSelectedItem:(NSInteger*)selectedIndex
{
	//NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self beginswith[cd] %@", substring];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self beginswith %@", substring];
	NSArray *completions = [[self tagCompletions] filteredArrayUsingPredicate:predicate];
	return completions;
}

- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(NSUInteger)index
{
	NSMutableArray *modifiedArray = [NSMutableArray array];
	
    for ( NSString *aString in tokens )
	{
		if ( ![aString isOnlyWhitespace] )
			//[modifiedArray addObject:[aString lowercaseString]];
			[modifiedArray addObject:aString];
	}
	
	return modifiedArray;
}

@end
