#import "MultipleEntryInfoController.h"

#import "JournlerJournal.h"
#import "JournlerEntry.h"
#import "BlogPref.h"

#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>
//#import "LabelPicker.h"
//#import "NSString+PDStringAdditions.h"

#import "Definitions.h"

@implementation MultipleEntryInfoController

- (id)init 
{
	return [self initWithEntries:nil];
}

- (id) initWithEntries:(NSArray*)initialEntries 
{
	 if ( self = [self initWithWindowNibName:@"MultipleEntryInfo"] ) 
	 {
		[self window];
		
		entries = [[NSArray alloc] init];
		if ( initialEntries != nil )
			[self setEntries:initialEntries];
			
		blogs = [[NSMutableArray alloc] init];
		
		 [self retain];
	 }
	 
	 return self;
}

- (void) dealloc 
{
	#ifdef __DEBUG__
	NSLog(@"%@ %s",[self className],_cmd);
	#endif
	
	[blogs release];
	[journal release];
	[entries release];
	[category release];
	[keywords release];
	[calDate release];
	[calDateModified release];
	[tagCompletions release];
	
	[super dealloc];
}

- (void) windowDidLoad 
{
	int i;
	NSArray *blogArray = [self valueForKeyPath:@"journal.blogs"];
	
	for ( i = 0; i < [blogArray count]; i++ ) 
	{
		if ( [[blogArray objectAtIndex:i] objectForKey:@"name"] != nil )
			[addBlogName addItemWithObjectValue:[[blogArray objectAtIndex:i] objectForKey:@"name"]];
	}
	
	if ( [addBlogName numberOfItems] > 0 )
		[addBlogName selectItemAtIndex:0];

	// don't forget to add our categories!
	NSArray *categoriesList = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Journler Categories List"];
	[categoryCombo addItemsWithObjectValues: 
			[categoriesList sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] ];
	
	[label setTag:4];
	[label setTarget:self];
	[label setAction:@selector(activateProperty:)];
	
	[addBlogType setAutoenablesItems:NO];
	[[addBlogType itemAtIndex:3] setEnabled:NO];
	
	[[self window] center];
}

- (void)windowWillClose:(NSNotification *)aNotification 
{
	[objectController unbind:@"contentObject"];
	[objectController setContent:nil];
	
	[blogListController unbind:@"contentArray"];
	//[blogListController setContent:nil];
	
	[self autorelease];
}

#pragma mark -

- (NSArray*) entries 
{ 
	return entries; 
}

- (void) setEntries:(NSArray*) newEntries 
{
	if ( entries != newEntries ) 
	{
		// a somewhat different setter - ensures each item is retained in the new array rather than copied
		[entries release];
		entries = [[NSArray alloc] initWithArray:newEntries];
		
		[self updateViewValues];
	}
}

- (JournlerJournal*)journal
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

- (void) updateViewValues 
{
	// looks at the content of the entries array and determines what values will be reflected by the view
	int i;
	int labelSelection;
	int markedSelection;
	NSString *aString;
	NSCalendarDate *aDate;
	NSArray *someBlogs;
	NSArray *theTags;
	
	// category
	aString = [[entries objectAtIndex:0] category];
	for ( i = 0; i < [entries count] - 1; i++ ) {
		if ( ![[[entries objectAtIndex:i] category] isEqualToString:[[entries objectAtIndex:i+1] category]] ) {
			aString = @"";
			break;
		}
	}
	[self setCategory:aString];
	
	// keywords
	aString = [[entries objectAtIndex:0] keywords];
	for ( i = 0; i < [entries count] - 1; i++ ) {
		if ( ![[[entries objectAtIndex:i] keywords] isEqualToString:[[entries objectAtIndex:i+1] keywords]] ) {
			aString = @"";
			break;
		}
	}
	[self setKeywords:aString];
	
	// tags
	theTags = [[entries objectAtIndex:0] tags];
	for ( i = 0; i < [entries count] - 1; i++ ) {
		
		NSArray *thisArray = [[entries objectAtIndex:i] tags];
		NSArray *thatArray = [[entries objectAtIndex:i+1] tags];
		
		if ( [thisArray count] != [thatArray count] )
		{
			theTags = nil;
			break;
		}
		else
		{
			NSSet *thisSet = [NSSet setWithArray:thisArray];
			NSSet *thatSet = [NSSet setWithArray:thatArray];
			if ( ![thisSet isEqualToSet:thatSet] )
			{
				theTags = nil;
				break;
			}
		}
	}
	[self setTags:theTags];
	
	// date created
	aDate = [(JournlerEntry*)[entries objectAtIndex:0] calDate];
	[self setCalDate:( aDate != nil ? aDate : [NSDate date] )];
	
	// date modified
	aDate = [(JournlerEntry*)[entries objectAtIndex:0] calDateModified];
	[self setCalDateModified:( aDate != nil ? aDate : [NSDate date] )];
	
	// date due
	aDate = [(JournlerEntry*)[entries objectAtIndex:0] calDateDue];
	[self setDateDue:( aDate != nil ? aDate : [NSDate date] )];
	if ( aDate == nil ) [self setClearsDateDue:YES];
	
	// event date
	//aDate = [(JournlerEntry*)[entries objectAtIndex:0] calEventDate];
	//[self setEventDate:( aDate != nil ? aDate : [NSDate date] )];
	
	// label
	labelSelection = [[entries objectAtIndex:0] labelInt];
	for ( i = 0; i < [entries count] - 1; i++ ) {
		if ( [[entries objectAtIndex:i] labelInt] != [[entries objectAtIndex:i+1] labelInt] ) {
			labelSelection = 0;
			break;
		}
	}
	[label setLabelSelection:labelSelection];
	
	// marked
	markedSelection = [[entries objectAtIndex:0] marked];
	for ( i = 0; i < [entries count] - 1; i++ ) {
		if ( [[entries objectAtIndex:i] marked] != [[entries objectAtIndex:i+1] marked] ) {
			markedSelection = 0;
			break;
		}
	}
	[self setMarked:markedSelection];
	
	// blogged
	someBlogs = [[entries objectAtIndex:0] blogs];
	for ( i = 0; i < [entries count] - 1; i++ ) {
		if ( ![[[entries objectAtIndex:i] blogs] isEqualToArray:[[entries objectAtIndex:i+1] blogs]] ) {
			someBlogs = [NSArray array];
			break;
		}
	}
	[self setBlogs:someBlogs];
	
	// num field
	[numField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"multi info num",@""), [entries count]]];
	
	// falsify all the edits
	[self setModifiedCat:NO];
	[self setModifiedKeywords:NO];
	[self setModifiedTags:NO];
	[self setModifiedCalDate:NO];
	[self setModifiedCalDateModified:NO];
	[self setModifiedLabel:NO];
	[self setModifiedMarked:NO];
	[self setModifiedBlogs:NO];
}

#pragma mark -

- (NSString*) category 
{ 
	return category; 
}

- (void) setCategory:(NSString*) newCategory 
{
	if ( category != newCategory ) 
	{
		[category release];
		category = [newCategory copyWithZone:[self zone]];
		
		if ( [category length] != 0 )
			[self setModifiedCat:YES];
	}
}

- (NSString*) keywords 
{ 
	return keywords; 
}

- (void) setKeywords:(NSString*) newKeywords 
{
	if ( keywords != newKeywords ) 
	{
		[keywords release];
		keywords = [newKeywords copyWithZone:[self zone]];
		
		if ( [keywords length] != 0 )
			[self setModifiedKeywords:YES];
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
		
		if ( [tags count] != 0 )
			[self setModifiedTags:YES];
	}
}

- (NSDate*) calDate 
{ 
	return calDate; 
}

- (void) setCalDate:(NSDate*)newCalDate 
{
	if ( calDate != newCalDate ) 
	{
		[calDate release];
		calDate = [newCalDate copyWithZone:[self zone]];
	}
}

- (NSDate*) dateDue
{
	return dateDue;
}

- (void) setDateDue:(NSDate*)newCalDate
{
	if ( dateDue != newCalDate )
	{
		[dateDue release];
		dateDue = [newCalDate copyWithZone:[self zone]];
	}
}

- (NSDate*) eventDate
{
	return eventDate;
}

- (void) setEventDate:(NSDate*)newCalDate
{
	if ( eventDate != newCalDate )
	{
		[eventDate release];
		eventDate = [newCalDate copyWithZone:[self zone]];
	}
}

- (NSDate*) calDateModified 
{ 
	return calDateModified; 
}

- (void) setCalDateModified:(NSDate*)newCalDateModified 
{
	if ( calDateModified != newCalDateModified ) 
	{
		[calDateModified release];
		calDateModified = [newCalDateModified copyWithZone:[self zone]];
	}
}

- (NSArray*) blogs 
{
	return blogs; 
}

- (void) setBlogs:(NSArray*)theBlogs 
{
	if ( blogs != theBlogs ) 
	{
		[blogs release];
		blogs = [theBlogs mutableCopyWithZone:[self zone]];
	}
}

- (int) marked 
{ 
	return marked; 
}

- (void) setMarked:(int)newMark 
{
	marked = newMark;
}

#pragma mark -

- (BOOL) modifiedCat 
{
	return modifiedCat; 
}

- (void) setModifiedCat:(BOOL)modified 
{ 
	modifiedCat = modified; 
}

- (BOOL) modifiedKeywords 
{ 
	return modifiedKeywords; 
}

- (void) setModifiedKeywords:(BOOL)modified 
{ 
	modifiedKeywords = modified; 
}

- (BOOL) modifiedTags
{
	return modifiedTags;
}

- (void) setModifiedTags:(BOOL)modified
{
	modifiedTags = modified;
}

- (BOOL) modifiedCalDate 
{ 
	return modifiedCalDate;
}

- (void) setModifiedCalDate:(BOOL)modified 
{ 
	modifiedCalDate = modified; 
}

- (BOOL) modifiedCalDateModified
{
	return modifiedCalDateModified; 
}

- (void) setModifiedCalDateModified:(BOOL)modified 
{ 
	modifiedCalDateModified = modified; 
}

- (BOOL) modifiedLabel 
{ 
	return modifiedLabel; 
}

- (void) setModifiedLabel:(BOOL)modified 
{ 
	modifiedLabel = modified; 
}

- (BOOL) modifiedMarked 
{ 
	return modifiedMarked; 
}

- (void) setModifiedMarked:(BOOL)modified 
{ 
	modifiedMarked = modified; 
}

- (BOOL) modifiedBlogs 
{ 
	return modifiedBlogs; 
}

- (void) setModifiedBlogs:(BOOL)modified 
{ 
	modifiedBlogs = modified; 
}

- (BOOL) modifiedDateDue
{
	return modifiedDateDue;
}

- (void) setModifiedDateDue:(BOOL)modified
{
	modifiedDateDue = modified;
}

- (BOOL) modifiedEventDate
{
	return modifiedEventDate;
}

- (void) setModifiedEventDate:(BOOL)modified
{
	modifiedEventDate = modified;
}

- (BOOL) clearsDateDue
{
	return clearsDateDue;
}

- (void) setClearsDateDue:(BOOL)clears
{
	clearsDateDue = clears;
}

#pragma mark -
#pragma mark NSTokenField Delegation

- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring 
	indexOfToken:(int)tokenIndex indexOfSelectedItem:(int *)selectedIndex
{
	//NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self beginswith[cd] %@", substring];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self beginswith %@", substring];
	NSArray *completions = [[self tagCompletions] filteredArrayUsingPredicate:predicate];
	return completions;
}

- (NSArray *)tokenFieldCell:(NSTokenFieldCell *)tokenFieldCell shouldAddObjects:(NSArray *)tokens atIndex:(unsigned)index
{
	//NSLog(@"%@ %s - %@",[self className],_cmd,tokens);
	
	NSMutableArray *modifiedArray = [NSMutableArray array];
	
	NSString *aString;
	NSEnumerator *enumerator = [tokens objectEnumerator];
	
	while ( aString = [enumerator nextObject] )
	{
		if ( ![aString isOnlyWhitespace] )
			//[modifiedArray addObject:[aString lowercaseString]];
			[modifiedArray addObject:aString];
	}
	
	return modifiedArray;

}


#pragma mark -

- (IBAction)addBlog:(id)sender
{
	
	[NSApp beginSheet: addBlogSheet
            modalForWindow: [self window]
            modalDelegate: nil
            didEndSelector: nil
            contextInfo: nil];
    [NSApp runModalForWindow: addBlogSheet];
    // Sheet is up here.
    [NSApp endSheet: addBlogSheet];
    [addBlogSheet orderOut: self];

}

- (IBAction)editBlogList:(id)sender
{
	
	int clickedSegment = [sender selectedSegment];
    int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
	
	switch ( clickedSegmentTag ) {
		
		// remove blog
		case 0:
			[self removeBlog:self];
			break;
		
		// add blog
		case 1:
			[self addBlog:self];
			break;
		
	}
	
	[self setModifiedBlogs:YES];
	
}

- (IBAction)removeBlog:(id)sender
{
	
	// only proceed if a blog is selected
	if ( [blogListController selectionIndex] == NSNotFound ) {
		NSBeep();
		return;
	}
	
	//prep the sheet
	[deleteBlogType setStringValue:
			[[[blogListController selectedObjects] objectAtIndex:0] objectForKey:@"type"]];
	[deleteBlogName setStringValue:
			[[[blogListController selectedObjects] objectAtIndex:0] objectForKey:@"blog"]];
	[deleteBlogJournal setStringValue:
			[[[blogListController selectedObjects] objectAtIndex:0] objectForKey:@"blogJournal"]];
	
	[NSApp beginSheet: deleteBlogSheet
            modalForWindow: [self window]
            modalDelegate: nil
            didEndSelector: nil
            contextInfo: nil];
    [NSApp runModalForWindow: deleteBlogSheet];
    // Sheet is up here.
    [NSApp endSheet: deleteBlogSheet];
    [deleteBlogSheet orderOut: self];
}

- (IBAction) cancelBlogAdd:(id)sender {
	[NSApp abortModal];
}

- (IBAction) confirmBlogAdd:(id)sender {
	
	NSDictionary *blogDict = [[NSDictionary alloc] initWithObjectsAndKeys:
			[addBlogType stringValue], @"type", 
			[addBlogName stringValue], @"blog",
			[addBlogJournal stringValue], @"blogJournal", nil];
	
	BlogPref *new_blog = [[BlogPref alloc] initWithProperties:blogDict];
	
	[blogListController addObject:new_blog];
	
	[NSApp stopModal];
	
	// clean up dict
	[new_blog release];
	[blogDict release];
	
	modifiedBlogs = YES;

}

- (IBAction) cancelBlogDelete:(id)sender {
	[NSApp abortModal];
}

- (IBAction) confirmBlogDelete:(id)sender {
	
	[blogListController remove:self];
	[NSApp stopModal];
	
	modifiedBlogs = YES;
	
}

#pragma mark -

- (IBAction)activateProperty:(id)sender
{
	//
	// depending on the sender's tag, note that this property needs to be saved
	
	switch ( [sender tag] ) {
		
		case 0:
			[self setModifiedCat:YES];
			break;
		case 1:
			[self setModifiedKeywords:YES];
			break;
		case 2:
			[self setModifiedCalDate:YES];
			break;
		case 3:
			[self setModifiedCalDateModified:YES];
			break;
		case 4:
			[self setModifiedLabel:YES];
			break;
		case 5:
			[self setModifiedMarked:YES];
			break;
		case 6:
			[self setModifiedBlogs:YES];
			break;
		case 7:
			[self setModifiedEventDate:YES];
			break;
		case 8:
			[self setModifiedDateDue:YES];
			break;
		case 9:
			[self setModifiedDateDue:YES];
			break;
		default:
			break;
		
	}
}

- (IBAction)showWindow:(id)sender 
{
	[self updateViewValues];
	[super showWindow:sender];
}


#pragma mark -

- (IBAction)cancelChanges:(id)sender
{
	[[self window] close];
}

- (IBAction)saveChanges:(id)sender
{
	if ( ![objectController commitEditing] )
		NSLog(@"%@ %s - unable to commit editing", [self className], _cmd);
	
	if ( modifiedCat )
		[entries setValue:category forKey:@"category"];
	
	if ( modifiedKeywords )
		[entries setValue:keywords forKey:@"keywords"];
	
	if ( modifiedTags )
		[entries setValue:tags forKey:@"tags"];
	
	if ( modifiedLabel )
		[entries setValue:[NSNumber numberWithInt:[label labelSelection]] forKey:@"label"];
			
	if ( modifiedMarked )
		[entries setValue:[NSNumber numberWithInt:marked] forKey:@"marked"];
	
	if ( modifiedBlogs )
		[entries setValue:blogs forKey:@"blogs"];
	
	if ( modifiedCalDate )
		[entries setValue:[calDate dateWithCalendarFormat:nil timeZone:nil] forKey:@"calDate"];
		
	//if ( modifiedEventDate )
	//	[entries makeObjectsPerformSelector:@selector(setCalEventDate:) withObject:[eventDate dateWithCalendarFormat:nil timeZone:nil]];
	
	if ( modifiedDateDue )
	{
		if ( [self clearsDateDue] )
			[entries setValue:nil forKey:@"calDateDue"];
		else
			[entries setValue:[dateDue dateWithCalendarFormat:nil timeZone:nil] forKey:@"calDateDue"];
	}
		
	// date modified on the entries
	if ( ![JournlerEntry modsDateModdedOnlyOnTextualChange] )
		[entries setValue:[NSCalendarDate calendarDate] forKey:@"calDateModified"];
	
	// save the entries
	JournlerEntry *anEntry;
	NSEnumerator *enumerator = [entries objectEnumerator];
	
	while ( anEntry = [enumerator nextObject] )
		[[self valueForKey:@"journal"] saveEntry:anEntry];
	
	// stop everything and quit
	[[self window] close];
}

@end
