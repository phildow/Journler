#import "EntryInfoController.h"
#import "Definitions.h"

#import "JournlerJournal.h"
#import "JournlerEntry.h"
#import "BlogPref.h"

#import <SproutedUtilities/SproutedUtilities.h>
//#import "NSString+PDStringAdditions.h"

@implementation EntryInfoController

- (id)init 
{
	if ( self = [super initWithWindowNibName:@"EntryInfo"] ) 
	{
		blogs = [[NSMutableArray alloc] init];
		entryLocation = [[NSString alloc] init];
		
		entryDate = [[NSCalendarDate calendarDate] retain];
		entryDateDue = [[NSCalendarDate calendarDate] retain];
		
		[self retain];
    }
	
    return self;
}

- (void) dealloc 
{
	#ifdef __DEBUG__
		NSLog(@"%@ %s",[self className],_cmd);
	#endif
	
	[entryLocation release];
	[blogs release];
	[tagCompletions release];
	[entryDate release];
	[entry release];
	[representedEntry release];
	[journal release];
	
	[super dealloc];
}

- (void)windowDidLoad 
{
	
	// go ahead and add our blog types and names to the combo box
	int i;
	
	NSArray *blogArray = [self valueForKeyPath:@"journal.blogs"];
	
	for ( i = 0; i < [blogArray count]; i++ ) {
		if ( [[blogArray objectAtIndex:i] objectForKey:@"name"] != nil )
			[addBlogName addItemWithObjectValue:[[blogArray objectAtIndex:i] objectForKey:@"name"]];
	}
	
	if ( [addBlogName numberOfItems] > 0 )
		[addBlogName selectItemAtIndex:0];
	
	// don't forget to add our categories!
	NSArray *categoriesList = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Journler Categories List"];
	[category addItemsWithObjectValues: 
			[categoriesList sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] ];
	
	//
	// 1.1.5
	[addBlogType setAutoenablesItems:NO];
	[[addBlogType itemAtIndex:3] setEnabled:NO];
	
	[[self window] center];
	
}

- (void)windowWillClose:(NSNotification *)aNotification 
{
	[blogListController unbind:@"contentArray"];
	//[blogListController setContent:nil];
	
	[objectController unbind:@"contentObject"];
	[objectController setContent:nil];
	
	[self autorelease];
}

#pragma mark -
#pragma mark Key-Value Coding

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

- (NSString*) entryLocation 
{ 
	return entryLocation; 
}

- (void) setEntryLocation:(NSString*)string 
{
	if ( entryLocation != string ) 
	{
		[entryLocation release];
		entryLocation = [string copyWithZone:[self zone]];
	}
}

- (NSCalendarDate*) entryDate 
{ 
	return entryDate; 
}

- (void) setEntryDate:(NSCalendarDate*)date 
{
	if ( entryDate != date ) 
	{
		[entryDate release];
		entryDate = [date copyWithZone:[self zone]];
	}
}

- (NSCalendarDate*) entryDateDue
{
	return entryDateDue;
}

- (void) setEntryDateDue:(NSCalendarDate*)aDate
{
	if ( entryDateDue != aDate )
	{
		[entryDateDue release];
		entryDateDue = [aDate copyWithZone:[self zone]];
	}
}

- (JournlerEntry*) entry 
{ 
	return entry; 
}

- (void) setEntry:(JournlerEntry*)object 
{
	
	if ( ![self isWindowLoaded] )
		[self window];
	
	// --------- 1.0.2 compatability: clear out old blogs ----------
	// - sorry!
	
	int i;
	NSMutableArray *tempBlogArray = [[NSMutableArray alloc] init];
	
	for ( i = 0; i < [[object blogs] count]; i++ ) {
		if ( ![[[object blogs] objectAtIndex:i] isKindOfClass:[NSString class]] )
			[tempBlogArray addObject:[[object blogs] objectAtIndex:i]];
	}
	
	[object setBlogs:tempBlogArray];
	
	// --------------------------------------------------------------
	
	// weak reference
	entry = [object retain];
	
	// copy is also necessary for saving
	[self setRepresentedEntry:object];
	
	// blogs and time
	[self setBlogs:[object blogs]];
	[self setEntryDate:[entry calDate]];
	[self setEntryDateDue:[entry calDateDue]];
	if ( [entry calDateDue] == nil )
		[self setClearsDateDue:YES];

	// labels
	[label setLabelSelection:[object labelInt]];
	
	// clean up
	[tempBlogArray release];
}

- (JournlerEntry*) representedEntry 
{ 
	return representedEntry; 
}

- (void) setRepresentedEntry:(JournlerEntry*)object 
{
	if ( representedEntry != object ) 
	{
		[representedEntry release];
		representedEntry = [[JournlerEntry alloc] initWithProperties:[object properties]];
		//representedEntry = [object copyWithZone:[self zone]];
	}
}

- (NSArray*) blogs 
{ 
	return blogs; 
}

- (void) setBlogs:(NSArray*)newBlogs 
{
	if ( blogs != newBlogs ) 
	{
		[blogs release];
		blogs = [newBlogs mutableCopyWithZone:[self zone]];
	}
}

- (BOOL) clearsDateDue
{
	return clearsDateDue;
}

- (void) setClearsDateDue:(BOOL)clears
{
	clearsDateDue = clears;
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

- (IBAction)cancelChanges:(id)sender
{
	[[self window] close];
}

- (IBAction)saveChanges:(id)sender
{
	if ( ![objectController commitEditing] )
		NSLog(@"%@ %s - unable to commit editing", [self className], _cmd);
	
	NSCalendarDate *newDate, *newDateDue;
	
	// interpret our date and time
	//newDate = (NSCalendarDate*)[dateAndTime dateValue];
	newDate = [[self entryDate] dateWithCalendarFormat:nil timeZone:nil];
	[representedEntry setCalDate:newDate];
	
	newDateDue = [[self entryDateDue] dateWithCalendarFormat:nil timeZone:nil];
	[representedEntry setCalDateDue:newDateDue];
		
	// copy the information from our representedentry into our entry
	[entry setCalDate:[representedEntry calDate]];
	[entry setTitle:[representedEntry title]];
	[entry setCategory:[representedEntry category]];
	[entry setKeywords:[representedEntry keywords]];
	[entry setFlagged:[representedEntry flagged]];
	[entry setTags:[representedEntry tags]];
	
	if ( [self clearsDateDue] )
		[entry setCalDateDue:nil];
	else
		[entry setCalDateDue:[representedEntry calDateDue]];
	
	// grab the blogs from ourself though
	[entry setBlogs:[self blogs]];
	
	// grab the label - 1.1.5
	[entry setLabel:[NSNumber numberWithInt:[label labelSelection]]];
	
	// date modified
	if ( ![JournlerEntry modsDateModdedOnlyOnTextualChange] )
		[entry setCalDateModified:[NSCalendarDate calendarDate]];
	
	// write the entry to disk
	[[self valueForKey:@"journal"] saveEntry:entry];
	
	// and get out
	[[self window] close];
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
	
	switch ( clickedSegmentTag ) 
	{
	// remove blog
	case 0:
		[self removeBlog:self];
		break;
	
	// add blog
	case 1:
		[self addBlog:self];
		break;
	}
}

- (IBAction)removeBlog:(id)sender
{
	// only proceed if a blog is selected
	if ( [blogListController selectionIndex] == NSNotFound ) 
	{
		NSBeep();
		return;
	}
	
	id selected_blog = [[blogListController selectedObjects] objectAtIndex:0];
	[deleteBlogType setStringValue:
			( [selected_blog objectForKey:@"type"] ? [selected_blog objectForKey:@"type"] : [NSString string] )];
	[deleteBlogName setStringValue:
			( [selected_blog objectForKey:@"type"] ? [selected_blog objectForKey:@"blog"] : [NSString string] )];
	[deleteBlogJournal setStringValue:
			( [selected_blog objectForKey:@"type"] ? [selected_blog objectForKey:@"blogJournal"] : [NSString string] )];
	
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

- (IBAction) cancelBlogAdd:(id)sender 
{
	[NSApp abortModal];
}

- (IBAction) confirmBlogAdd:(id)sender 
{
	NSMutableDictionary *blogDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
			[addBlogType titleOfSelectedItem], @"type", 
			[addBlogName stringValue], @"blog",
			[addBlogJournal stringValue], @"blogJournal", nil];
	
	BlogPref *new_blog = [[BlogPref alloc] initWithProperties:blogDict];
	[blogListController addObjects:[NSArray arrayWithObjects:new_blog,nil]];
	
	[NSApp stopModal];
	
	// clean up dict
	[new_blog release];
	[blogDict release];
}

- (IBAction) cancelBlogDelete:(id)sender 
{
	[NSApp abortModal];
}

- (IBAction) confirmBlogDelete:(id)sender 
{
	[blogListController remove:self];
	[NSApp stopModal];
}

- (IBAction)showHelp:(id)sender
{
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"JournlerEntryInfo" inBook:@"JournlerHelp"];
}

@end
