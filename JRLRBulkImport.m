#import "JRLRBulkImport.h"

#import "JournlerCollection.h"
#import "JournlerJournal.h"
#import "JournlerCondition.h"
#import "JournlerEntry.h"

#import <SproutedInterface/SproutedInterface.h>

@implementation JRLRBulkImport

- (id) init 
{	
	return [self initWithJournal:nil];
}

- (id) initWithJournal:(JournlerJournal*)aJournal
{
	if ( self = [super init] ) 
	{
		journal = [aJournal retain];
		
		title = [[NSString alloc] init];
		category = [[NSString alloc] init];
		tags = [[NSArray alloc] init];
		date = [[NSDate date] retain];
		marking = [NSNumber numberWithInteger:0];
		comments = [[NSString alloc] init];
		
		alreadyEditedCategory = NO;
		[NSBundle loadNibNamed:@"BulkImport" owner:self];
	}
	
	return self;
}

- (void) awakeFromNib 
{	
	// prepare the date
	//[datePicker setDateValue:[NSDate date]];
	
	// prepare the categories and select the default
	NSArray *categoriesList = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Journler Categories List"];
	
	[categories addItemsWithObjectValues: 
			[categoriesList sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] ];
	
	[self setCategory:[JournlerEntry defaultCategory]];
					
	if ( [categories numberOfVisibleItems] > [categories numberOfItems] )
		[categories setNumberOfVisibleItems:[categories numberOfItems]];

	// prepare the collections
	NSMenu *collectionsMenu = [[NSMenu alloc] init];
	[[[self journal] rootCollection] flatMenuRepresentation:&collectionsMenu 
			target:self action:@selector(selectFolder:) smallImages:YES inset:0];
	
	[collectionsMenu setAutoenablesItems:NO];
	
	// go through the menu and disable anything that isn't a folder
	
	NSInteger i;
	for ( i = [collectionsMenu numberOfItems]-1; i >= 0; i-- ) 
	{
		if ( ![[collectionsMenu itemAtIndex:i] representedObject] )
			[[collectionsMenu itemAtIndex:i] setEnabled:NO];
		
		//else if ( [[[[collectionsMenu itemAtIndex:i] representedObject]valueForKey:@"typeID"] integerValue] != PDCollectionTypeIDFolder )
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

}

- (void) dealloc 
{	
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	[view release];
	[journal release];
	
	[objectController release];
	
	[category release];
	[title release];
	[tags release];
	[date release];
	[marking release];
	[comments release];
	
	[super dealloc];
}

- (void)ownerWillClose:(NSNotification *)aNotification 
{
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
	if ( journal != aJournal )
	{
		[journal release];
		journal = [aJournal retain];
	}
}

- (NSInteger) datePreference 
{ 
	return [datePreference selectedTag]; 
}

- (BOOL) preserveFolderStructure
{
	return ( [preserveFolders state] == NSOnState );
}

- (BOOL) preserveDateModified
{
	return ( [preserveDateModifiedCheck state] == NSOnState );
}

- (NSCalendarDate*) date 
{ 
	return [date dateWithCalendarFormat:nil timeZone:nil]; 
}

- (void) setDate:(NSDate*)aDate
{
	if ( date != aDate )
	{
		[date release];
		date = [aDate copyWithZone:[self zone]];
	}
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

- (NSString*) comments
{
	return comments;
}

- (void) setComments:(NSString*)theComments
{
	if ( comments != theComments )
	{
		[comments release];
		comments = [theComments retain];
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

- (void) setTargetDate:(NSCalendarDate*)aDate 
{	
	[datePicker setDateValue:aDate];	
}

- (JournlerCollection*) targetCollection 
{
	return [[collectionField selectedItem] representedObject];
}

- (void) setTargetCollection:(JournlerCollection*)aFolder 
{
	if ( aFolder != nil ) 
	{
		[collectionField selectItemWithTag:[[aFolder valueForKey:@"tagID"] integerValue]];
		[self selectFolder:[collectionField selectedItem]];
	}
}

#pragma mark -

- (NSView*) view 
{ 
	return view; 
}

- (IBAction) selectFolder:(id)sender
{
	// gives me a chance to update our visual cues based on the folders conditions
	// support or conditioning so that the list number of conditions are set
	
	JournlerCollection *theFolder = [sender representedObject];
	if ( theFolder == nil )
	{
		NSBeep(); return;
	}
	
	// attempt to autotag the entry based on my conditions and the conditions of my parents
	// this should be a category on ns predicate
	
	BOOL added = YES;
	
	NSArray *allConditions = [theFolder allConditions:YES];
	#ifdef __DEBUG__
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
			if ( [theKey isEqualToString:@"keywords"] )
				theKey = @"comments";
				
			if ( [theKey isEqualToString:@"marked"] )
				theKey = @"marking";
			
			else if ( [theKey isEqualToString:@"label"] )
				theKey = @"labelValue";
			
			else if ( [theKey isEqualToString:@"flagged"] )
				theKey = @"marking";
			
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

- (BOOL) commitEditing
{
	BOOL success = [objectController commitEditing];
	if ( !success ) NSLog(@"%s - unable to commit editing", __PRETTY_FUNCTION__);
	return success;
}

#pragma mark -
#pragma mark JournlerConditionController Delegate (NSTokenField)

- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring 
	indexOfToken:(NSInteger)tokenIndex indexOfSelectedItem:(NSInteger*)selectedIndex
{
	//NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self beginswith[cd] %@", substring];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self beginswith %@", substring];
	NSArray *completions = [[[[self journal] entryTags] allObjects] filteredArrayUsingPredicate:predicate];
	return completions;
}


@end
