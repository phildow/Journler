//
//  TabController.m
//  Journler
//
//  Created by Philip Dow on 10/24/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import "TabController.h"
#import "JournlerApplicationDelegate.h"

#import "Definitions.h"

#import "JournlerEntry.h"
#import "JournlerJournal.h"
#import "JournlerResource.h"

#import "NSAttributedString+JournlerAdditions.h"
#import "NSAlert+JournlerAdditions.h"
#import "NSArray_JournlerAdditions.h"

#import <SproutedInterface/SproutedInterface.h>
#import <SproutedUtilities/SproutedUtilities.h>

#import "JournlerWeblogInterface.h"

#import "JournlerWindowController.h"
#import "JournlerWindow.h"

#import "EntryCellController.h"
#import "EntryExportController.h"

#import "EntryInfoController.h"
#import "MultipleEntryInfoController.h"
#import "ResourceInfoController.h"
#import "FolderInfoController.h"

#import "EntryWindowController.h"
#import "FloatingEntryWindowController.h"
#import "JournlerMediaViewer.h"

@implementation TabController

// Debugging Aids
/*
- (void)addObserver:(NSObject *)anObserver forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
{
	NSLog(@"Tab %i ++ Observer: %@", [[self owner] indexOfObjectInJSTabs:self], keyPath);
	[super addObserver:anObserver forKeyPath:keyPath options:options context:context];
}

- (void)removeObserver:(NSObject *)anObserver forKeyPath:(NSString *)keyPath
{
	NSLog(@"Tab %i -- Observer: %@", [[self owner] indexOfObjectInJSTabs:self], keyPath);
	[super removeObserver:anObserver forKeyPath:keyPath];
}
*/

- (id) init 
{
	return [self initWithOwner:nil];
}

- (id) initWithOwner:(JournlerWindowController*)anObject 
{
	if ( self = [super init] ) 
	{
		// nav control
		recordNavigationEvent = YES;
		navigationManager = [[NSUndoManager alloc] init];
		
		// set the owner
		owner = anObject;
		journal = [anObject journal];
		
		// initial data
		selectedEntries = [[NSArray alloc] init];
		selectedFolders = [[NSArray alloc] init];
		selectedResources = [[NSArray alloc] init];
		selectedDate = [[NSDate date] retain];
		
		// asked to be notified of entry and resource deletion
		[[NSNotificationCenter defaultCenter] addObserver:self 
				selector:@selector(willDeleteEntry:) 
				name:JournalWillDeleteEntryNotification 
				object:journal];
		
		[[NSNotificationCenter defaultCenter] addObserver:self 
				selector:@selector(willDeleteResource:) 
				name:JournalWillDeleteResourceNotificiation 
				object:journal];
	}
	return self;
}

- (void) dealloc 
{	
#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
#endif
	
	[navigationManager release];
	[selectedEntries release];
	[selectedFolders release];
	[selectedResources release];
	[selectedDate release];
	
	// release the nib's top level objects
	[tabContent release];
	
#ifdef __DEBUG__
	NSLog(@"%s - ending",__PRETTY_FUNCTION__);
#endif
	
	[super dealloc];
}

#pragma mark -

- (JournlerWindowController*)owner 
{
	return owner;
}

- (void) setOwner:(JournlerWindowController*)anObject 
{
	owner = anObject;
	
	// the owner is responsible for the active journal and managed object context
	[self setJournal:[owner journal]];
}

- (JournlerJournal*) journal 
{
	return journal;
}

- (void) setJournal:(JournlerJournal*)aJournal 
{
	journal = aJournal;
}

#pragma mark -

- (NSView*) tabContent 
{
	// can be overridden by subclasses to return the main view used by the tab to display its content
	return tabContent;
}

- (NSString*) title 
{
	// can be overridden by subclasses to return a string which describes the tab's content.
	// the string may be used as a window title or as a tab title
	
	if ( [[self selectedResources] count] != 0 )
		return [[[self selectedResources] objectAtIndex:0] valueForKey:@"title"];
	else if ( [[self selectedEntries] count] != 0 )
		return [[[self selectedEntries] objectAtIndex:0] valueForKey:@"title"];
	else if ( [[self selectedFolders] count] != 0 )
		return [[[self selectedFolders] objectAtIndex:0] valueForKey:@"title"];
	else if ( [self selectedDate] != nil )
	{
		NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
		[formatter setDateStyle:NSDateFormatterLongStyle];
		[formatter setTimeStyle:NSDateFormatterNoStyle];
		return [formatter stringFromDate:[self selectedDate]];
	}
	else
		return [NSString string];
}

#pragma mark -

- (void) selectDate:(NSDate*)date folders:(NSArray*)folders entries:(NSArray*)entries resources:(NSArray*)resources 
{
	// subclasses must override this method to support back/forward navigation
}

#pragma mark -

//
// the following methods maintain the four possible items selected in the interface:
// date, folders, entries, and resources.
// subclasses may override as needed, calling super's method. it is not necessary to support each type of selection

- (NSArray*) selectedFolders 
{
	return selectedFolders;
}

- (void) setSelectedFolders:(NSArray*)anArray 
{
	if ( selectedFolders != anArray )
	{
		// prepare the undo action
		if ( recordNavigationEvent == YES )
			[[navigationManager prepareWithInvocationTarget:self]
					selectDate:[self selectedDate] folders:selectedFolders entries:[self selectedEntries] resources:[self selectedResources]];
		
		[selectedFolders release];
		selectedFolders = [anArray retain];
	}
}


- (NSArray*) selectedEntries 
{
	return selectedEntries;
}

- (void) setSelectedEntries:(NSArray*)anArray 
{	
	if ( selectedEntries != anArray ) 
	{
		// prepare the undo action
		if ( recordNavigationEvent == YES )
			[[navigationManager prepareWithInvocationTarget:self] selectDate:[self selectedDate] 
					folders:[self selectedFolders] 
					entries:selectedEntries 
					resources:[self selectedResources]];
		
		[selectedEntries release];
		selectedEntries = [anArray retain];
	}
}


- (NSArray*) selectedResources 
{
	return selectedResources;
}

- (void) setSelectedResources:(NSArray*)anArray 
{
	if ( selectedResources != anArray ) 
	{
		// prepare the undo action
		if ( recordNavigationEvent == YES )
			[[navigationManager prepareWithInvocationTarget:self] selectDate:[self selectedDate] 
					folders:[self selectedFolders] 
					entries:[self selectedEntries] 
					resources:selectedResources];
		
		[selectedResources release];
		selectedResources = [anArray retain];
	}
}

- (NSDate*) selectedDate 
{
	return selectedDate;
}

- (void) setSelectedDate:(NSDate*)aDate 
{
	if ( selectedDate != aDate ) 
	{
		// prepare the undo action
		if ( recordNavigationEvent == YES )
			[[navigationManager prepareWithInvocationTarget:self] selectDate:selectedDate 
					folders:[self selectedFolders] 
					entries:[self selectedEntries] 
					resources:[self selectedResources]];
		
		[selectedDate release];
		selectedDate = [aDate retain];
	}
}

#pragma mark -

- (BOOL) selectDate:(NSDate*)aDate
{
	// subclasses should override the "select" messages to provide any necessary, custom mechanism
	NSLog(@"%s - ** concrete subclasses must override **", __PRETTY_FUNCTION__);
	return NO;
}

- (BOOL) selectFolders:(NSArray*)anArray
{
	// subclasses should override the "select" messages to provide any necessary, custom mechanism
	NSLog(@"%s - ** concrete subclasses must override **", __PRETTY_FUNCTION__);
	return NO;
}

- (BOOL) selectEntries:(NSArray*)anArray
{
	// subclasses should override the "select" messages to provide any necessary, custom mechanism
	NSLog(@"%s - ** concrete subclasses must override **", __PRETTY_FUNCTION__);
	return NO;
}

- (BOOL) selectResources:(NSArray*)anArray
{
	// subclasses should override the "select" messages to provide any necessary, custom mechanism
	NSLog(@"%s - ** concrete subclasses must override **", __PRETTY_FUNCTION__);
	return NO;
}

#pragma mark -
#pragma mark Saving and Restoring State

// methods used to save and restore the tabs state, storing selected date, folders, entries and references
// subclasses may override to store additional data or only relevant data

- (NSDictionary*) stateDictionary 
{	
	NSDate *theDate = [self selectedDate];
	NSArray *theFolders = [[self selectedFolders] arrayProducingURIRepresentations:[self journal]];
	NSArray *theEntries = [[self selectedEntries] arrayProducingURIRepresentations:[self journal]];
	NSArray *theReferences = [[self selectedResources] arrayProducingURIRepresentations:[self journal]];
	
	NSMutableDictionary *stateDictionary = [NSMutableDictionary dictionaryWithCapacity:4];
	if ( theDate != nil ) [stateDictionary setObject:theDate forKey:@"selectedDate"];
	if ( theFolders != nil ) [stateDictionary setObject:theFolders forKey:@"selectedFolders"];
	if ( theEntries != nil ) [stateDictionary setObject:theEntries forKey:@"selectedEntries"];
	if ( theReferences != nil ) [stateDictionary setObject:theReferences forKey:@"selectedResources"];
	
	return stateDictionary;
}

- (void) restoreStateWithDictionary:(NSDictionary*)stateDictionary 
{
	id theDate = [stateDictionary objectForKey:@"selectedDate"];
	id theFolders = [[stateDictionary objectForKey:@"selectedFolders"] arrayProducingJournlerObjects:[self journal]];
	id theEntries = [[stateDictionary objectForKey:@"selectedEntries"] arrayProducingJournlerObjects:[self journal]];
	id theReferences = [[stateDictionary objectForKey:@"selectedResources"] arrayProducingJournlerObjects:[self journal]];
	
	[self selectDate:theDate folders:theFolders entries:theEntries resources:theReferences];
}

- (NSDictionary*) localStateDictionary
{
	// subclasses should override to return local state information
	return nil;
}

- (void) restoreLocalStateWithDictionary:(NSDictionary*)stateDictionary
{
	// subclasses should override to re-instate state information
}

- (NSData*) stateData 
{	
	NSDictionary *stateDictionary = [self stateDictionary];
	NSData *stateData = [NSKeyedArchiver archivedDataWithRootObject:stateDictionary];
	return stateData;			
}


- (void) restoreStateWithData:(NSData*)stateData 
{	
	NSDictionary *stateDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:stateData];
	if ( stateDictionary == nil || ![stateDictionary isKindOfClass:[NSDictionary class]] )
		return;
	else
		[self restoreStateWithDictionary:stateDictionary];
}

#pragma mark - Recording Targets

- (void) sproutedVideoRecorder:(SproutedRecorder*)recorder insertRecording:(NSString*)path title:(NSString*)title
{
	NSLog(@"%s - **** subclasses must override ****", __PRETTY_FUNCTION__);
}

- (void) sproutedAudioRecorder:(SproutedRecorder*)recorder insertRecording:(NSString*)path title:(NSString*)title
{
	NSLog(@"%s - **** subclasses must override ****", __PRETTY_FUNCTION__);
}

- (void) sproutedSnapshot:(SproutedRecorder*)recorder insertRecording:(NSString*)path title:(NSString*)title
{
	NSLog(@"%s - **** subclasses must override ****", __PRETTY_FUNCTION__);
}

#pragma mark -

- (BOOL) isFiltering
{
	// subclasses should override to indicate if they are filtering entries
	return NO;
}

- (BOOL) canPerformNavigation:(int)direction {
	
	if ( direction == 0 )
		return [navigationManager canUndo];
	else if ( direction == 1 )
		return [navigationManager canRedo];
	else
		return NO;
}

- (IBAction) navigateBack:(id)sender {
	
	[navigationManager undo];
}

- (IBAction) navigateForward:(id)sender {

	[navigationManager redo];
}

#pragma mark -

- (JournlerEntry*) newDefaultEntryWithSelectedDate:(NSDate*)aDate overridePreference:(BOOL)forceDate
{
	// no dialog or nuthin, just create a new entry and select it
	// aDate is used only if the preferences calls for the currently selected date
	
	JournlerEntry *newEntry;
		
	// prepare the new entry
	newEntry = [[[JournlerEntry alloc] init] autorelease];
	[newEntry setJournal:[self journal]];
	
	[newEntry setValue:[NSNumber numberWithInt:[[self journal] newEntryTag]] forKey:@"tagID"];
	[newEntry setValue:[NSCalendarDate calendarDate] forKey:@"calDateModified"];
	[newEntry setValue:[JournlerEntry defaultCategory] forKey:@"category"];
	
	// the date depends on the preference
	if ( [[NSUserDefaults standardUserDefaults] integerForKey:@"DateForNewEntry"] == 0 && !forceDate )
		[newEntry setValue:[NSCalendarDate calendarDate] forKey:@"calDate"];
	else
		[newEntry setValue:[aDate dateWithCalendarFormat:nil timeZone:nil] forKey:@"calDate"];
	
	// prepare the untitled title
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setDateStyle:NSDateFormatterLongStyle];
	[formatter setTimeStyle:NSDateFormatterNoStyle];
	NSString *dateString = [formatter stringFromDate:[newEntry valueForKey:@"calDate"]];
	NSString *title = [NSString stringWithFormat:NSLocalizedString(@"dated untitled title", @""), dateString];
		
	// default attributed content
	NSAttributedString *attributedContent = [[[NSAttributedString alloc] 
			initWithString:[NSString string] attributes:[JournlerEntry defaultTextAttributes]] autorelease];
	
	[newEntry setValue:title forKey:@"title"];
	[newEntry setValue:attributedContent forKey:@"attributedContent"];
	
	// add the entry to the journal and save it
	[[self journal] addEntry:newEntry];
	[[self journal] saveEntry:newEntry];
	
	// if a regular folder is selected add it to that
	
	return newEntry;
}

- (void) printEntries:(NSDictionary*)printInfo
{
	// centralized print processing
		
	// get the print info
	NSPrintInfo *sharedPI = [[[NSPrintInfo sharedPrintInfo] copyWithZone:[self zone]] autorelease];
	[sharedPI setHorizontalPagination:NSFitPagination];
	[sharedPI setHorizontallyCentered:NO];
	[sharedPI setVerticallyCentered:NO];
	
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"PrintHeader"] == NO && [[NSUserDefaults standardUserDefaults] boolForKey:@"PrintFooter"] == NO )
		[[sharedPI dictionary] setValue:[NSNumber numberWithBool:NO] forKey:NSPrintHeaderAndFooter];
	else
		[[sharedPI dictionary] setValue:[NSNumber numberWithBool:YES] forKey:NSPrintHeaderAndFooter];
	
	int width = [sharedPI paperSize].width - ( [sharedPI rightMargin] + [sharedPI leftMargin] );
	int height = [sharedPI paperSize].height - ( [sharedPI topMargin] + [sharedPI bottomMargin] );
	
	// create a view based on that information
	PDPrintTextView *printView = [[[PDPrintTextView alloc] initWithFrame:NSMakeRect(0,0,width,height)] autorelease];
	
	// set a few properties for the print job
	[printView setPrintTitle:[self valueForKeyPath:@"journal.title"]];
	[printView setPrintHeader:[[NSUserDefaults standardUserDefaults] boolForKey:@"PrintHeader"]];
	[printView setPrintFooter:[[NSUserDefaults standardUserDefaults] boolForKey:@"PrintFooter"]];
		
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateStyle:NSDateFormatterLongStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	
	[printView setPrintDate:[dateFormatter stringFromDate:[NSDate date]]];
	
	// what exactly do I print?
	BOOL wTitle = [[NSUserDefaults standardUserDefaults] boolForKey:@"PrintEntryTitle"];
	BOOL wCategory = [[NSUserDefaults standardUserDefaults] boolForKey:@"PrintEntryCategory"];
	BOOL wDate = [[NSUserDefaults standardUserDefaults] boolForKey:@"PrintEntryDate"];
	
	// the entries to be printed
	NSArray *printArray = [printInfo objectForKey:@"entries"];
	
	//and build that view like no other
	int i;
	for ( i = 0; i < [printArray count]; i++ ) 
	{
		NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
		
		NSAttributedString *preppedEntry;
		
		// grab the entries text
		preppedEntry = [(JournlerEntry*)[printArray objectAtIndex:i] prepWithTitle:wTitle category:wCategory smallDate:wDate];
		
		// print browsed entries prints images by default
		[printView replaceCharactersInRange:NSMakeRange([[printView string] length],0) 
				withRTFD:[preppedEntry RTFDFromRange:NSMakeRange(0, [[preppedEntry string] length]) 
				documentAttributes:nil]];
		
		if ( i != [printArray count] - 1 )
			[printView replaceCharactersInRange:NSMakeRange([[printView string] length],0) withString:@"\n\n"];
			
		[innerPool release];
	}
	
	//grab the view to print and send it to the printer using the shared printinfo values
	NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView:printView printInfo:sharedPI];
	
	if ( [[[self owner] window] isMainWindow] )
		[printOperation runOperationModalForWindow:[[self owner] window] 
				delegate:nil 
				didRunSelector:nil 
				contextInfo:nil];
	else
		[printOperation runOperation];
}

#pragma mark -

- (JournlerEntry*) entryForRecording:(id)sender
{
	// subclasses may want to override
	
	NSArray *theEntries = [self selectedEntries];
	if ( theEntries == nil || [theEntries count] == 0 )
		return nil;
	else
		return [theEntries objectAtIndex:0];
}

- (void) servicesMenuAppendSelection:(NSPasteboard*)pboard desiredType:(NSString*)type
{
	// subclasses should override
	return;
}

- (void) appropriateFirstResponder:(NSWindow*)aWindow
{
	// subclasses should override
}

- (void) appropriateFirstResponderForNewEntry:(NSWindow*)aWindow
{
	// subclasses should override
	// same as above but special occasion when an entry is just being created
}

- (BOOL) performCustomKeyEquivalent:(NSEvent *)theEvent
{
	// subclasses may override
	return NO;
}

#pragma mark -
#pragma mark Working with Entries

- (IBAction) editEntryProperty:(id)sender
{	
	NSArray *theEntries = [self valueForKey:@"selectedEntries"];
	if ( theEntries == nil || [theEntries count] == 0 )
	{
		NSBeep(); return;
	}
	
	if ( [sender tag] == 331 ) // flag
	{
		[theEntries setValue:[NSNumber numberWithInt:
				( [[[theEntries objectAtIndex:0] valueForKey:@"marked"] intValue] == 1 ? 0 : 1 )] forKey:@"marked"];
	}
	else if ( [sender tag] == 334 ) // check
	{
		[theEntries setValue:[NSNumber numberWithInt:
				( [[[theEntries objectAtIndex:0] valueForKey:@"marked"] intValue] == 2 ? 0 : 2 )] forKey:@"marked"];
	}
}

- (IBAction) editEntryLabel:(id)sender
{
	NSArray *theEntries;
	
	// grab the available entries from the controller
	theEntries = [self selectedEntries];
	if ( theEntries == nil || [theEntries count] == 0 || [sender tag] == 10 ) {
		NSBeep(); return;
	}
	
	[theEntries setValue:[NSNumber numberWithInt:[sender tag]] forKey:@"label"];
}

- (IBAction) revealEntryInFinder:(id)sender
{
	NSArray *theEntries = [self valueForKey:@"selectedEntries"];
	if ( theEntries == nil || [theEntries count] == 0 )
	{
		NSBeep(); return;
	}
	
	int i;
	for ( i = 0; i < [theEntries count]; i++ )
	{
		NSString *path = [[theEntries objectAtIndex:0] packagePath];
		[[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:[path stringByDeletingLastPathComponent]];
	}
}

#pragma mark -

- (IBAction) getInfo:(id)sender
{
	// working from resources backwards - subclasses should take into account keyboard focus
	
	if ( [[self selectedResources] count] != 0 )
		[self getResourceInfo:sender];
	else if ( [[self selectedEntries] count] != 0 )
		[self getEntryInfo:sender];
	else if ( [[self selectedFolders] count] != 0 )
		[self getFolderInfo:sender];
	else
		NSBeep();
}

- (IBAction) getEntryInfo:(id)sender
{
	NSArray *theEntries = [self valueForKey:@"selectedEntries"];
	if ( theEntries == nil || [theEntries count] == 0 )
	{
		NSBeep(); return;
	}
	else
	{
		if ( [theEntries count] == 1 )
		{
			EntryInfoController *controller = [[[EntryInfoController alloc] init] autorelease];
			[controller setValue:[self valueForKey:@"journal"] forKey:@"journal"];
			[controller setValue:[theEntries objectAtIndex:0] forKey:@"entry"];
			[controller setEntryLocation:[[theEntries objectAtIndex:0] packagePath]];
			[controller setTagCompletions:[[[self journal] entryTags] allObjects]];
			
			[controller showWindow:sender];
		}
		else
		{
			MultipleEntryInfoController *controller = [[[MultipleEntryInfoController alloc] init] autorelease];
			[controller setValue:[self valueForKey:@"journal"] forKey:@"journal"];
			[controller setValue:theEntries forKey:@"entries"];
			[controller setTagCompletions:[[[self journal] entryTags] allObjects]];
			
			[controller showWindow:sender];
		}
	}
}

- (IBAction) getResourceInfo:(id)sender
{
	if ( [[self selectedResources] count] == 0 )
	{
		NSBeep(); return;
	}
	
	BOOL first = YES;
	
    for ( JournlerResource *aResource in [self selectedResources] )
	{
		ResourceInfoController *infoController = [[[ResourceInfoController alloc] init] autorelease];
	
		[infoController setViewAlignment:ResourceInfoAlignLeft];
		[infoController setResource:aResource];
	
		//[[infoController window] setFrameTopLeftPoint:photoInScreenOrigin];
		if ( first )
		{
			[[infoController window] center];
			first = NO;
		}
		
		[infoController showWindow:sender];
	}
}

- (IBAction) getFolderInfo:(id)sender
{
	
	if ( [[self selectedFolders] count] == 0 )
	{
		NSBeep(); return;
	}
	
	BOOL first = YES;
	
    for ( JournlerCollection *aFolder in [self selectedFolders] )
	{
		FolderInfoController *folderInfo = [[[FolderInfoController alloc] init] autorelease];
		
		[folderInfo setValue:[self valueForKey:@"journal"] forKey:@"journal"];
		[folderInfo setValue:aFolder forKey:@"collection"];
		
		if ( first )
		{
			[[folderInfo window] center];
			first = NO;
		}
		
		[folderInfo showWindow:sender];
	}
}

#pragma mark -

- (IBAction) exportSelection:(id)sender
{
	// forks depending on the selection: export resources or export entries
	if ( [[self selectedResources] count] != 0 )
		[self exportResource:sender];
	else if ( [[self selectedEntries] count] != 0 )
		[self exportEntrySelection:sender];
	else
	{
		NSBeep(); return;
	}
}

- (IBAction) exportEntrySelection:(id)sender
{
	// #warning should resources or folder be exported as well?
	NSArray *theEntries = [self selectedEntries];
	
	if ( theEntries == nil || [theEntries count] == 0 )
	{
		NSBeep();
		return;
	}
	
	EntryExportController *exportController = [[[EntryExportController alloc] init] autorelease];
	
	// export a single entry
	if ( [theEntries count] == 1 ) 
	{
		int runResult;
		NSSavePanel *sp = [NSSavePanel savePanel];
		
		// add the accessory panel
		[sp setAccessoryView:[exportController contentView]];
		[sp setCanSelectHiddenExtension:YES];
		
		// set up new attributes - handles required extension
		[exportController setFileMode:2]; // force mode to "together in single file"
		[exportController setChoosesFileMode:NO];
		[exportController setUpdatesFileExtension:YES];

		
		// display the NSSavePanel
		runResult = [sp runModalForDirectory:nil file:[[theEntries objectAtIndex:0] pathSafeTitle]];
		
		// if successful, save file under designated name
		if (runResult == NSOKButton) 
		{
			if ( ![exportController commitEditing] )
				NSLog(@"%s - unable to commit editing", __PRETTY_FUNCTION__);
			
			int flags = kEntrySetLabelColor;
			if ( [exportController includeHeader] )
				flags |= kEntryIncludeHeader;
			if ( [exportController modifiesFileCreationDate] )
				flags |= kEntrySetFileCreationDate;
			if ( [exportController modifiesFileModifiedDate] )
				flags |= kEntrySetFileModificationDate;
			if ( [sp isExtensionHidden] )
				flags |= kEntryHideExtension;
			
			if ( ![[theEntries objectAtIndex:0] writeToFile:[sp filename] as:[exportController dataFormat] flags:flags] )
			{
				NSBeep();
				[[NSAlert entryExportError] runModal];
				NSLog(@"%s - error writing file to %@", __PRETTY_FUNCTION__, [sp filename]);
			}
		}
	}
	
	// export more than one entry
	else
	{
		int runResult;
		NSOpenPanel *sp = [NSOpenPanel openPanel];
		
		// set up new attributes
		[sp setAccessoryView:[exportController contentView]];
		[sp setCanCreateDirectories:YES];
		[sp setCanChooseDirectories:YES];
		[sp setCanSelectHiddenExtension:YES];
		[sp setCanChooseFiles:NO];
		[sp setMessage:NSLocalizedString(@"export panel text",@"")];
		[sp setTitle:NSLocalizedString(@"export panel title",@"")];
		[sp setPrompt:NSLocalizedString(@"export panel prompt",@"")];
		
		// display the save panel
		runResult = [sp runModalForDirectory:nil file:[self valueForKeyPath:@"journal.title"] types:nil];

		// if successful, save file under designated name
		if (runResult == NSOKButton) 
		{
			if ( ![exportController commitEditing] )
				NSLog(@"%s - unable to commit editing", __PRETTY_FUNCTION__);
			
			BOOL include_header = [exportController includeHeader];
			BOOL mods_creation_date = [exportController modifiesFileCreationDate];
			BOOL mods_modification_date = [exportController modifiesFileModifiedDate];
			int dataFormat = [exportController dataFormat];
			int folderPref = [exportController fileMode];
			
			BOOL success = YES;
			NSString *rootDir = [sp directory];
			
			if ( folderPref == kExportByFolder ) 
			{
				int flags = kEntrySetLabelColor|kEntryDoNotOverwrite;
				if ( include_header )
					flags |= kEntryIncludeHeader;
				if ( mods_creation_date )
					flags |= kEntrySetFileCreationDate;
				if ( mods_modification_date )
					flags |= kEntrySetFileModificationDate;
				if ( [sp isExtensionHidden] )
					flags |= kEntryHideExtension;
				
				int i;
				for ( i = 0; i < [theEntries count]; i++ ) 
				{
					NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
					
					JournlerEntry *anEntry = [theEntries objectAtIndex:i];
					//NSString *saveLoc = [NSString stringWithFormat:@"%@/%@ %@", rootDir, [anEntry valueForKey:@"tagID"], [anEntry pathSafeTitle]];
					NSString *saveLoc = [rootDir stringByAppendingPathComponent:[anEntry pathSafeTitle]];
					[anEntry writeToFile:saveLoc as:dataFormat flags:flags];
					
					[innerPool release];
				}
			}
			
			else if ( folderPref == kExportBySingleFile ) 
			{
			
				// every entry should be placed in a single file and saved
				NSString *filename = [rootDir stringByAppendingPathComponent:NSLocalizedString(@"journal",@"")];
				
				NSError *error;
				NSString *saveWithExtension;
				NSFileWrapper *rtfWrapper;
						
				NSPrintInfo *printInfo;
				//NSPrintInfo *sharedInfo;
				NSPrintOperation *printOp;
				//NSMutableDictionary *printInfoDict;
				//NSMutableDictionary *sharedDict;

				printInfo = [[[NSPrintInfo sharedPrintInfo] copyWithZone:[self zone]] autorelease];
				[printInfo setJobDisposition:NSPrintSaveJob];
				[[printInfo dictionary]  setObject:[filename stringByAppendingPathExtension:@"pdf"] forKey:NSPrintSavePath];
				[[printInfo dictionary] setValue:[NSNumber numberWithBool:NO] forKey:NSPrintHeaderAndFooter];
				
				[printInfo setHorizontalPagination: NSAutoPagination];
				[printInfo setVerticalPagination: NSAutoPagination];
				[printInfo setVerticallyCentered:NO];
				
				//should give me the width and height
				int width = [printInfo paperSize].width - ( [printInfo rightMargin] + [printInfo leftMargin] );
				int height = [printInfo paperSize].height - ( [printInfo topMargin] + [printInfo bottomMargin] );
				
				PDPrintTextView *printView = [[[PDPrintTextView alloc] initWithFrame:NSMakeRect(0,0,width,height)] autorelease];
				
				// set a few properties for the print job
				[printView setPrintHeader:NO];
				[printView setPrintFooter:NO];
				
				// include the header?
				BOOL withHeader = [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryExportIncludeHeader"];
				
				// set all the entries
				
				int i;
				NSSortDescriptor *descriptor = [[[NSSortDescriptor alloc] initWithKey:@"calDate" ascending:YES] autorelease];
				NSArray *sortedEntries = [theEntries sortedArrayUsingDescriptors:[NSArray arrayWithObject:descriptor]];
				
				for ( i = 0; i < [sortedEntries count]; i++ ) 
				{
					NSAutoreleasePool *innerpool = [[NSAutoreleasePool alloc] init];
					JournlerEntry *anEntry = [sortedEntries objectAtIndex:i];
					
					// handle the entry
					NSAttributedString *preppedEntry = [[anEntry prepWithTitle:withHeader category:withHeader smallDate:withHeader] 
							attributedStringWithoutJournlerLinks];
					
					[printView replaceCharactersInRange:NSMakeRange([[printView textStorage] length],0) 
							withRTFD:[preppedEntry RTFDFromRange:NSMakeRange(0, [preppedEntry length]) 
							documentAttributes:nil]];
					
					[printView replaceCharactersInRange:NSMakeRange([[printView textStorage] length],0) withString:@"\n\n"];
					
					[innerpool release];
				}
					
				// with the view ready, determine the format and save accordingly
				switch ( dataFormat ) {
					
					case kEntrySaveAsRTF:
						
						saveWithExtension = [filename stringByAppendingPathExtension:@"rtf"];
						rtfWrapper = [[[NSFileWrapper alloc] initRegularFileWithContents:[[printView textStorage] 
								RTFFromRange:NSMakeRange(0, [[printView textStorage] length]) documentAttributes:nil]] autorelease];

						if ( ![rtfWrapper writeToFile:saveWithExtension atomically:YES updateFilenames:YES] ) 
						{
							NSLog(@"%s - unable to write entries to location %@", __PRETTY_FUNCTION__, saveWithExtension);
							success = NO;
						}
						
						break;
					
					case kEntrySaveAsWord:
						
						saveWithExtension = [filename stringByAppendingPathExtension:@"doc"];
						NSData *docData = [[printView textStorage] docFormatFromRange:NSMakeRange(0, [[printView textStorage] length]) 
								documentAttributes:nil];
						
						if ( ![docData writeToFile:saveWithExtension atomically:YES] ) 
						{
							NSLog(@"%s - unable to write entries to location %@", __PRETTY_FUNCTION__, saveWithExtension);
							success = NO;
						}

						break;
					
					case kEntrySaveAsRTFD:
						
						saveWithExtension = [filename stringByAppendingPathExtension:@"rtfd"];
						NSFileWrapper *rtfdWrapper = [[printView textStorage] RTFDFileWrapperFromRange:NSMakeRange(0, [[printView textStorage] length])
								documentAttributes:nil];

						if ( ![rtfdWrapper writeToFile:saveWithExtension atomically:YES updateFilenames:YES] ) 
						{
							NSLog(@"%s - unable to write entries to location %@", __PRETTY_FUNCTION__, saveWithExtension);
							success = NO;
						}

						break;
					
					case kEntrySaveAsPDF:
						
						saveWithExtension = [filename stringByAppendingPathExtension:@"pdf"];
						[printView sizeToFit];
					
						printOp = [NSPrintOperation printOperationWithView:printView printInfo:printInfo];
						//[printOp setShowPanels:NO]; DEPRECATED
                        [printOp setShowsProgressPanel:NO];
                        [printOp setShowsPrintPanel:NO];
						
						if ( ![printOp runOperation] ) 
						{
							NSLog(@"%s - unable to write entries to location %@", __PRETTY_FUNCTION__, saveWithExtension);
							success = NO;
						}
						
						break;
					
					case kEntrySaveAsHTML:
						
						saveWithExtension = [filename stringByAppendingPathExtension:@"html"];
							
						NSString *html_to_export;
						
						if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"ExportsUseAdvancedHTMLGeneration"] )
							html_to_export = [[[printView textStorage] attributedStringWithoutJournlerLinks]
								attributedStringAsHTML:kUseSystemHTMLConversion|kConvertSmartQuotesToRegularQuotes 
								documentAttributes:[NSDictionary dictionaryWithObject:[self valueForKeyPath:@"journal.title"] forKey:NSTitleDocumentAttribute]
								avoidStyleAttributes:[[NSUserDefaults standardUserDefaults] stringForKey:@"ExportsNoAttributeList"]];
								
						else
							html_to_export = [[[[printView textStorage] attributedStringWithoutJournlerLinks] 
									attributedStringAsHTML:kUseJournlerHTMLConversion|kConvertSmartQuotesToRegularQuotes
									documentAttributes:nil avoidStyleAttributes:nil] 
									stringAsHTMLDocument:[self valueForKeyPath:@"journal.title"]];
						
					
						if ( ![html_to_export writeToFile:saveWithExtension atomically:YES encoding:NSUTF8StringEncoding error:&error] )
						//if ( ![processedText writeToFile:saveWithExtension atomically:YES] ) 
						{
							NSLog(@"%s - unable to write entries to location %@, error: %@", __PRETTY_FUNCTION__, saveWithExtension, error);
							success = NO;
						}

						break;
					
					case kEntrySaveAsText:
						
						saveWithExtension = [filename stringByAppendingPathExtension:@"txt"];
						NSString *textString = [printView string];
						NSError *error = nil;
										
						//if ( ![textString writeToFile:saveWithExtension atomically:YES] ) 
						if ( ![textString writeToFile:saveWithExtension atomically:YES encoding:NSUnicodeStringEncoding error:&error] )
						{
							NSLog(@"%s - unable to write entries to location %@, error: %@", __PRETTY_FUNCTION__, saveWithExtension, error);
							success = NO;
						}
						
						break;
				}
				
				if ( success ) 
				{
					NSDictionary *tempDict = [[[NSDictionary alloc] initWithObjectsAndKeys:
								[NSNumber numberWithBool:[sp isExtensionHidden]], @"NSFileExtensionHidden", nil] autorelease];
					[[NSFileManager defaultManager] changeFileAttributes:tempDict atPath:saveWithExtension];
				}
			}
			
			// let the user know we're finished
			if ( !success )
			{
				NSBeep();
				[[NSAlert entryExportError] runModal];
				NSLog(@"%s - errors while exporting multiple entries", __PRETTY_FUNCTION__);
			}
		}
	}
	
	[exportController ownerWillClose:nil];
}

- (IBAction) exportResource:(id)sender
{
#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
#endif
	
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	
	[openPanel setCanCreateDirectories:YES];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	[openPanel setMessage:NSLocalizedString(@"export resources panel text",@"")];
	[openPanel setTitle:NSLocalizedString(@"export resources panel title",@"")];
	[openPanel setPrompt:NSLocalizedString(@"export resources panel prompt",@"")];
	
	if ( [openPanel runModalForDirectory:nil file:nil types:nil] == NSOKButton )
	{
		NSString *path = [openPanel directory];
		
        for ( JournlerResource *aResource in [self selectedResources] )
			[aResource createFileAtDestination:path];
	}
}

#pragma mark -

- (IBAction) emailResourceSelection:(id)sender
{
	static NSString *mainHandler = @"prepare_mail_message";
	
	NSDictionary *errors = [NSDictionary dictionary];
	NSArray *resources = [self selectedResources];
	
	if ( !resources || [resources count] == 0 ) 
	{
		NSBeep(); return;
	}
	
	// do we use mail or the default mailer for emails
	int mailPreference = [[NSUserDefaults standardUserDefaults] integerForKey:@"UseMailForEmailing"];
	if ( mailPreference == 0 )
	{
		// ask the user what their preference is
		NSBeep();
		int result = [[NSAlert requestMailPreference] runModal];
		if ( result == 1000 ) mailPreference = 1;
		else mailPreference = 2;
		
		[[NSUserDefaults standardUserDefaults] setInteger:mailPreference forKey:@"UseMailForEmailing"];
	}
	
	
	if ( mailPreference == 1 )
	{
		// use Mail messaging
		
		// grab the script's path
		NSString *path = [[NSBundle mainBundle] pathForResource:@"SendEmailWithAttachments" ofType:@"scpt"];
		if ( !path ) 
		{
			NSBeep();
			NSLog(@"%s - unable to locate SendEmailWithAttachments.scpt", __PRETTY_FUNCTION__);
			return;
		}
		
		NSURL *url = [NSURL fileURLWithPath:path];
		if ( !url ) 
		{
			NSBeep();
			NSLog(@"%s - unable to create URL with path %@", __PRETTY_FUNCTION__, path);
			return;
		}
		
		// load the script
		NSAppleScript *script = [[[NSAppleScript alloc] initWithContentsOfURL:url error:&errors] autorelease];
		if ( !script ) 
		{
			NSBeep();
			NSLog(@"%s - unable to create script for path %@, errors: %@", __PRETTY_FUNCTION__, [url path], [errors description]);
			return;
		}
		
		// put together the file paths and content
		static NSString *content = @"\n\n";
		NSString *subject = nil;
		NSNumber *prompt = [NSNumber numberWithBool:NO];
		NSMutableArray *resourcePaths = [NSMutableArray arrayWithCapacity:[resources count]];
		
        for ( JournlerResource *aResource in resources )
		{
			if ( [aResource representsFile] )
				[resourcePaths addObject:[aResource originalPath]];
			else
			{
				NSString *destination = TempDirectory();
				NSString *aPath = [aResource createFileAtDestination:destination];
				if ( aPath != nil )
					[resourcePaths addObject:aPath];
				else
					NSLog(@"%s - unable to get a path for resource %@ - %@", __PRETTY_FUNCTION__, [aResource tagID], [aResource title]);
			}
			
			if ( subject == nil )
				subject = [aResource title];
		}
		
		if ( [script executeHandler:mainHandler error:&errors withParameters: content, resourcePaths, prompt, subject, nil] == nil 
			&& [[errors objectForKey:NSAppleScriptErrorNumber] intValue] != kScriptWasCancelledError )
		{
			NSLog(@"%s - executeHandler returned error: %@", __PRETTY_FUNCTION__, errors);
			
			id theSource = [script richTextSource];
			if ( theSource == nil ) theSource = [script source];
			AppleScriptAlert *scriptAlert = [[[AppleScriptAlert alloc] initWithSource:theSource error:errors] autorelease];
			
			NSBeep();
			[scriptAlert showWindow:self];
		}
	}
	else
	{
		// put up an error explaining that emailing resources is not possible, offer to change to Mail
		NSBeep();
	}
}

- (IBAction) blogResourceSelection:(id)sender
{
	NSBeep(); return;
}

#pragma mark -

- (IBAction) emailDocument:(id)sender
{
	// routes the command depending on the selection
	
	if ( [[self selectedResources] count] != 0 )
		[self emailResourceSelection:sender];
		
	else if ( [[self selectedEntries] count] != 0 )
		[self emailEntrySelection:sender];
	
	else
		NSBeep();
}

- (IBAction) blogDocument:(id)sender
{
	// routes the command depending on the selection
	
	if ( [[self selectedResources] count] != 0 )
		NSBeep();
		
	else if ( [[self selectedEntries] count] != 0 )
		[self blogEntrySelection:sender];
	
	else
		NSBeep();
}

- (IBAction) printDocument:(id)sender
{
	// subclasses should override, dispatching as necesary
	NSLog(@"%s - ** subclasses must override **", __PRETTY_FUNCTION__);
}

#pragma mark -

- (IBAction) emailEntrySelection:(id)sender
{
	// subclasses may want to override in order to handle text selection on a single entry
	NSArray *theEntries;
	
	// grab the available entries from the controller
	theEntries = [self selectedEntries];
	if ( theEntries == nil || [theEntries count] == 0 ) {
		NSBeep(); return;
	}
	
	// do we use mail or the default mailer for emails
	int mailPreference = [[NSUserDefaults standardUserDefaults] integerForKey:@"UseMailForEmailing"];
	if ( mailPreference == 0 )
	{
		// ask the user what their preference is
		NSBeep();
		int result = [[NSAlert requestMailPreference] runModal];
		if ( result == 1000 ) mailPreference = 1;
		else mailPreference = 2;
		
		[[NSUserDefaults standardUserDefaults] setInteger:mailPreference forKey:@"UseMailForEmailing"];	
	}
	
	 
	if ( mailPreference == 1 )
	{
		// use Mail messaging
		
		NSNumber *prompt = [NSNumber numberWithBool:NO];
		static NSString *mainHandler = @"prepare_mail_message";
		
		NSDictionary *errors = [NSDictionary dictionary];
				
		// grab the script's path
		NSString *path = [[NSBundle mainBundle] pathForResource:@"SendEmailWithAttachments" ofType:@"scpt"];
		if ( !path ) 
		{
			NSBeep();
			NSLog(@"%s - unable to locate SendEmailWithAttachments.scpt", __PRETTY_FUNCTION__);
			return;
		}
		
		NSURL *url = [NSURL fileURLWithPath:path];
		if ( !url ) 
		{
			NSBeep();
			NSLog(@"%s - unable to create URL with path %@", __PRETTY_FUNCTION__, path);
			return;
		}
		
		// load the script
		NSAppleScript *script = [[[NSAppleScript alloc] initWithContentsOfURL:url error:&errors] autorelease];
		if ( !script ) 
		{
			NSBeep();
			NSLog(@"%s - unable to create script for path %@, errors: %@", __PRETTY_FUNCTION__, [url path], [errors description]);
			return;
		}
		
        for ( JournlerEntry *anEntry in theEntries )
		{
			// put together the file paths and content
			
			NSDictionary *errors = nil;
			
			NSString *subject = [anEntry title];
			NSString *content = [anEntry content];
			//NSAttributedString *content = [[[anEntry attributedContent] attributedStringWithoutJournlerLinks] attributedStringWithoutTextAttachments];
			NSArray *resources = [anEntry resources];
			NSMutableArray *resourcePaths = [NSMutableArray arrayWithCapacity:[resources count]];
			
            for ( JournlerResource *aResource in resources )
			{
				if ( [aResource representsFile] )
					[resourcePaths addObject:[aResource originalPath]];
				else
				{
					NSString *destination = TempDirectory();
					NSString *aPath = [aResource createFileAtDestination:destination];
					if ( aPath != nil )
						[resourcePaths addObject:aPath];
					else
						NSLog(@"%s - unable to get a path for resource %@ - %@", __PRETTY_FUNCTION__, [aResource tagID], [aResource title]);
				}
			}
			
			if ( [script executeHandler:mainHandler error:&errors withParameters: content, resourcePaths, prompt, subject, nil] == nil )
			{
				NSBeep();
				NSLog(@"%s - executeHandler returned error: %@", __PRETTY_FUNCTION__, errors);
			}
		}
	}
	else
	{
		// use default messaging
        for ( JournlerEntry *anEntry in theEntries )
		{
			NSAttributedString *content = [anEntry valueForKey:@"attributedContent"];
			NSString *title = [anEntry valueForKey:@"title"];
			
			[JournlerApplicationDelegate sendRichMail:content to:@"" subject:title isMIME:YES withNSMail:NO];
		}
	}
}

- (IBAction) blogEntrySelection:(id)sender
{
	//NSBeep();
	//NSLog(@"%s - this method has been deprecated", __PRETTY_FUNCTION__);
	
	NSArray *theEntries = [self valueForKey:@"selectedEntries"];
	if ( !theEntries || [theEntries count] == 0 ) {
		NSBeep();
		return;
	}
	
	// make sure a weblog editor has been selected
	// A. it is an applescript
	//	- run the applescript
	// B. it is an application
	//	- try the weblog editor protocol
	//	- write out a temp rtfd file and send it to the application
	
	NSString *weblogEditor = [[NSUserDefaults standardUserDefaults] objectForKey:@"PreferredWeblogEditor"];
	if ( weblogEditor == nil || ![[NSFileManager defaultManager] fileExistsAtPath:weblogEditor] )
	{
		// choose a weblog editor
		JournlerWeblogInterface *webInterface = [[JournlerWeblogInterface alloc] init];
		[webInterface choosePreferredEditor:self didEndSelector:@selector(didChoosePreferredEditor:returnCode:editor:) modalForWindow:[[self owner] window]];
	}
	else
	{
		int options = 0;
		id error = nil; // error can be a dictionary or an error object
		NSDictionary *supportedEditors = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"SupportedWeblogEditorsBundleIdentifiers"];
		
		JournlerWeblogInterface *webInterface = [[JournlerWeblogInterface alloc] init];
		[webInterface setWeblogEditorIdentifiers:supportedEditors];
		
		// defaults write com.phildow.journler SendHTMLToWeblogEditor 1
		if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"SendHTMLToWeblogEditor"] )
			options |= kJournlerWeblogInterfaceSendHTML;
		
		if ( ![webInterface sendEntries:theEntries toPreferredEditor:weblogEditor options:options error:&error] )
		{
			if ( [error isKindOfClass:[NSDictionary class]] )
			{
				// applescript error
				NSMutableDictionary *standardizedError = [[error mutableCopyWithZone:[self zone]] autorelease];
				[standardizedError removeObjectForKey:kPDAppleScriptErrorDictionaryScriptSource];
				
				AppleScriptAlert *scriptAlert = [[[AppleScriptAlert alloc] initWithSource:
				[error objectForKey:kPDAppleScriptErrorDictionaryScriptSource] error:standardizedError] autorelease];
			
				NSBeep();
				[scriptAlert showWindow:self];
			}
			else if ( [error isKindOfClass:[NSError class]] )
			{
				// standard error
				[NSApp presentError:error];
			}
			else
			{
				// no or unknown error information
				NSLog(@"%s - an unknown error occurred while sending entries to weblog editor", __PRETTY_FUNCTION__);
			}
		}
	}
}

- (void) didChoosePreferredEditor:(JournlerWeblogInterface*)weblogInterface returnCode:(int)returnCode editor:(NSString*)filename
{
	if ( returnCode == NSOKButton )
	{
		[[NSUserDefaults standardUserDefaults] setObject:filename forKey:@"PreferredWeblogEditor"];
		[self blogEntrySelection:self];
	}
	
	// release now that we're finished with it
	[weblogInterface release];
}

- (IBAction) sendEntryToiWeb:(id)sender
{
	static NSString *imageHandlerName = @"send_images";
	static NSString *audioHandlerName = @"send_podcast";
	static NSString *videoHandlerName = @"send_movie";
	
	NSDictionary *errors = [NSDictionary dictionary];
	
	int i;
	NSArray *entries = [self selectedEntries];
	if ( !entries || [entries count] == 0 ) 
	{
		NSBeep(); return;
	}
	
	// ensure that iweb is installed
	if ( [[NSWorkspace sharedWorkspace] fullPathForApplication:@"iWeb"] == nil ) 
	{
		NSBeep();
		[[NSAlert iWebNotFound] runModal];
		return;
	}
	
	// grab the script's path
	NSString *path = [[NSBundle mainBundle] pathForResource:@"SendToiWeb" ofType:@"scpt"];
	if ( !path ) 
	{
		NSBeep();
		NSLog(@"%s - unable to locate SendToiWeb.scpt", __PRETTY_FUNCTION__);
		return;
	}
	
	NSURL *url = [NSURL fileURLWithPath:path];
	if ( !url ) 
	{
		NSBeep();
		NSLog(@"%s - unable to create URL with path %@", __PRETTY_FUNCTION__, path);
		return;
	}
	
	// load the script
	NSAppleScript *script = [[[NSAppleScript alloc] initWithContentsOfURL:url error:&errors] autorelease];
	if ( !script ) 
	{
		NSBeep();
		NSLog(@"%s - unable to create script for path %@, errors: %@", __PRETTY_FUNCTION__, [url path], [errors description]);
		return;
	}
	
	// each entry has a chance to be sent to iweb
	for ( i = 0; i < [entries count]; i++ ) 
	{
		// 1 = photocast, 2 = podcast, 3 = videocast
		unsigned int castType = 1;
		NSString *castPath = nil;
		
		// first try to get one of the entry's resources, an image resource
		
		
		int j;
		NSArray *entryResources = [[entries objectAtIndex:i] valueForKey:@"resources"];
		for ( j = 0; j < [entryResources count]; j++ )
		{
			JournlerResource *aResource = [entryResources objectAtIndex:j];
			if ( [aResource representsFile] )
			{
				/* // The audio file must be aac - and is there a special bundle?
				if ( UTTypeConformsTo((CFStringRef)[aResource valueForKey:@"uti"],kUTTypeAudio) )
				{
					castType = 2;
					castPath = [aResource originalPath];
				}
				*/
				if ( UTTypeConformsTo((CFStringRef)[aResource valueForKey:@"uti"],(CFStringRef)@"public.movie") )
				{
					castType = 3;
					castPath = [aResource originalPath];
				}
				else if ( UTTypeConformsTo((CFStringRef)[aResource valueForKey:@"uti"],kUTTypeImage) )
				{
					castType = 1;
					castPath = [aResource originalPath];
				}
			}
		}
		
		
		if ( castPath == nil )
		{
			castType = 1;
			
			// try to grab any image that's in the entry
			NSData *imageData = [[[entries objectAtIndex:i] attributedContent] 
					firstImageData:NSMakeRange(0,[[[entries objectAtIndex:i] attributedContent] length]) fileType:NSPNGFileType];
			
			if ( imageData == nil ) 
			{
				// prepare the placeholder image path
				castPath = [[NSBundle mainBundle] pathForResource:@"iWebPlaceholder" ofType:@"png"];
				if ( castPath == nil ) 
				{
					// #warning an alert
					NSBeep();
					NSLog(@"%s - unable to locate the iWebPlaceholder image", __PRETTY_FUNCTION__);
					return;
				}
			}
			else 
			{
				// write the image to a temporary file and use that
				NSString *ran_string = [NSString stringWithFormat:@"%f.png", [NSDate timeIntervalSinceReferenceDate]];
				NSString *full_path = [TempDirectory() stringByAppendingPathComponent:ran_string];
				
				if ( [imageData writeToFile:full_path atomically:YES] )
					castPath = full_path;
					
				else 
				{
					castPath = [[NSBundle mainBundle] pathForResource:@"iWebPlaceholder" ofType:@"png"];
					if ( castPath == nil ) 
					{
						// #warning an alert
						NSBeep();
						NSLog(@"%s - unable to locate the iWebPlaceholder image", __PRETTY_FUNCTION__);
						return;
					}
				}
			}
		}
		
    #ifdef __DEBUG__
		NSLog(@"%s - castPath: %@", __PRETTY_FUNCTION__, castPath);
    #endif
		
		if ( castType == 1 )
		{
			NSNumber *totalCount = [NSNumber numberWithInt:1];
			NSArray *images = [NSArray arrayWithObjects:castPath,nil];
			NSArray *titles = [NSArray arrayWithObjects:[[entries objectAtIndex:i] title], nil];
			NSArray *contents = [NSArray arrayWithObjects:[[entries objectAtIndex:i] stringValue], nil];
			
			if ( ![script executeHandler:imageHandlerName error:&errors withParameters: totalCount, images, titles, contents, nil] 
				&& [[errors objectForKey:NSAppleScriptErrorNumber] intValue] != kScriptWasCancelledError )
			{
				NSLog(@"%s - unable to execute image handler, error %@", __PRETTY_FUNCTION__, errors);
				
				id theSource = [script richTextSource];
				if ( theSource == nil ) theSource = [script source];
				AppleScriptAlert *scriptAlert = [[[AppleScriptAlert alloc] initWithSource:theSource error:errors] autorelease];
			
				NSBeep();
				[scriptAlert showWindow:self];
			}
		}
		else if ( castType == 2 )
		{
			if ( ![script executeHandler:audioHandlerName error:&errors withParameters: castPath, nil] 
				&& [[errors objectForKey:NSAppleScriptErrorNumber] intValue] != kScriptWasCancelledError )
			{
				NSLog(@"%s - unable to execute image handler, error %@", __PRETTY_FUNCTION__, errors);
				
				id theSource = [script richTextSource];
				if ( theSource == nil ) theSource = [script source];
				AppleScriptAlert *scriptAlert = [[[AppleScriptAlert alloc] initWithSource:theSource error:errors] autorelease];
			
				NSBeep();
				[scriptAlert showWindow:self];
			}
		}
		else if ( castType == 3 )
		{
			NSString *castTitle = [[entries objectAtIndex:i] valueForKey:@"title"];
			if ( ![script executeHandler:videoHandlerName error:&errors withParameters: castPath, castTitle, nil]
				&& [[errors objectForKey:NSAppleScriptErrorNumber] intValue] != kScriptWasCancelledError )
			{
				NSLog(@"%s - unable to execute image handler, error %@", __PRETTY_FUNCTION__, errors);
				
				id theSource = [script richTextSource];
				if ( theSource == nil ) theSource = [script source];
				AppleScriptAlert *scriptAlert = [[[AppleScriptAlert alloc] initWithSource:theSource error:errors] autorelease];
			
				NSBeep();
				[scriptAlert showWindow:self];
			}
		}
	}
}

- (IBAction) sendEntryToiPod:(id)sender
{
	// get and check the selection
	NSArray *theEntries = [self selectedEntries];
	if ( !theEntries || [theEntries count] == 0 ) 
	{
		NSBeep(); return;
	}
	
	// find the ipod
	L0iPod *device;
	NSArray* alliPods = [L0iPod allMountedDevices];
	if ( !alliPods || [alliPods count] == 0 ) 
	{
		[[NSAlert iPodNotConnected] runModal];
		return;
	}
	
	// take the first device
	device = [alliPods objectAtIndex:0];
	NSString* iPodPath = [device path];
	if (!iPodPath) 
	{
		[[NSAlert iPodNotConnected] runModal];
		return;
	}
	
	// ensure the iPod Notes folder is available
	NSString *notesPath = [iPodPath stringByAppendingPathComponent:@"Notes"];
	if ( ![[NSFileManager defaultManager] fileExistsAtPath:notesPath] ) 
	{
		[[NSAlert iPodNoNotes] runModal];
		return;
	}
	
	// ensure the is a Journler subdirectory at this point
	NSString *journlerPath = [notesPath stringByAppendingPathComponent:@"Journler"];
	if ( ![[NSFileManager defaultManager] fileExistsAtPath:journlerPath] ) 
	{
		if ( ![[NSFileManager defaultManager] createDirectoryAtPath:journlerPath attributes:nil] ) 
		{
			[[NSAlert iPodNoJournlerFolder] runModal];
			return;
		}
	}
	
	// actually export the entries to the iPod
    BOOL completeSucces = YES;
    
    for ( JournlerEntry *anEntry in theEntries )
		completeSucces = ( [anEntry writeToFile:journlerPath as:6 flags:kEntryIncludeHeader] && completeSucces );
	
	//#warning report errors?
}

#pragma mark -

- (IBAction) openEntryInNewTab:(id)sender
{
	
    for ( JournlerEntry *anEntry in [self selectedEntries] )
	{
		[[self valueForKey:@"owner"] newTab:sender];
		TabController *theTab =[[self valueForKeyPath:@"owner.tabControllers"] lastObject];
		[theTab selectDate:[anEntry valueForKey:@"calDate"] folders:nil entries:[NSArray arrayWithObject:anEntry] resources:nil];
		
		// select the tab if shift is down
		if ( [[NSApp currentEvent] modifierFlags] & NSShiftKeyMask )
			[[self valueForKey:@"owner"] selectTabAtIndex:-1 force:NO];
	}
}

- (IBAction) openEntryInNewWindow:(id)sender
{
    for ( JournlerEntry *anEntry in [self selectedEntries] )
	{
		// put the  controller up
		EntryWindowController *entryWindow = [[[EntryWindowController alloc] initWithJournal:[self journal]] autorelease];
		[entryWindow showWindow:self];
		
		// set it's selection to our current selection
		[[entryWindow selectedTab] selectDate:[self valueForKey:@"selectedDate"] 
				folders:[self valueForKey:@"selectedFolders"] entries:[NSArray arrayWithObject:anEntry]
				resources:[self valueForKey:@"selectedResources"]];
		
		[[entryWindow selectedTab] appropriateFirstResponder:[entryWindow window]];
	}
}

- (IBAction) openEntryInNewFloatingWindow:(id)sender
{
    for ( JournlerEntry *anEntry in [self selectedEntries] )
	{
		// put the  controller up
		FloatingEntryWindowController *entryWindow = [[[FloatingEntryWindowController alloc] initWithJournal:[self journal]] autorelease];		
		[entryWindow showWindow:self];
		
		// set it's selection to our current selection
		[[entryWindow selectedTab] selectDate:[self valueForKey:@"selectedDate"] 
				folders:[self valueForKey:@"selectedFolders"] entries:[NSArray arrayWithObject:anEntry]
				resources:[self valueForKey:@"selectedResources"]];
		
		[[entryWindow selectedTab] appropriateFirstResponder:[entryWindow window]];
	}
}


#pragma mark -

- (void) openAnEntryInNewWindow:(JournlerEntry*)anEntry
{
	// put the  controller up
	//EntryWindowController *entryWindow = [[[EntryWindowController alloc] init] autorelease];
	//[entryWindow setJournal:[self journal]];
	EntryWindowController *entryWindow = [[[EntryWindowController alloc] initWithJournal:[self journal]] autorelease];
	[entryWindow showWindow:self];
	
	// set its selection to our current selection
	[[entryWindow selectedTab] selectDate:nil folders:nil entries:[NSArray arrayWithObject:anEntry] resources:nil];
	[[entryWindow selectedTab] appropriateFirstResponder:[entryWindow window]];
}

- (void) openAnEntryInNewTab:(JournlerEntry*)anEntry
{
	[[self valueForKey:@"owner"] newTab:self];
	TabController *theTab =[[self valueForKeyPath:@"owner.tabControllers"] lastObject];
	
	[theTab selectDate:[anEntry valueForKey:@"calDate"] folders:nil entries:[NSArray arrayWithObject:anEntry] resources:nil];
}

#pragma mark -

- (void) openAResourceWithFinder:(JournlerResource*)aResource
{
	[aResource openWithFinder];
}

- (void) openAResourceInNewTab:(JournlerResource*)aResource
{
	[[self valueForKey:@"owner"] newTab:self];
	TabController *theTab = [[self valueForKeyPath:@"owner.tabControllers"] lastObject];
	
	[theTab selectDate:[aResource valueForKeyPath:@"entry.calDate"] 
			folders:nil 
			entries:[NSArray arrayWithObject:[aResource valueForKey:@"entry"]] 
			resources:[NSArray arrayWithObject:aResource]];
}

- (void) openAResourceInNewWindow:(JournlerResource*)aResource
{
	EntryWindowController *aWindow = [[[EntryWindowController alloc] initWithJournal:[self journal]] autorelease];
	[aWindow showWindow:self];
	
	[[aWindow selectedTab] selectDate:nil folders:nil entries:[NSArray arrayWithObject:[aResource valueForKey:@"entry"]] 
	 resources:[NSArray arrayWithObject:aResource]];
	 
	[[aWindow selectedTab] appropriateFirstResponder:[aWindow window]];
	
	/*
	// open the resource in a new window if that's possible, finder otherwise
	if ( [JournlerMediaViewer canDisplayMediaOfType:[aResource valueForKey:@"uti"] 
			url:( ( [aResource representsFile] && [aResource originalPath] != nil ) ? [NSURL fileURLWithPath:[aResource originalPath]] : nil )] )
	{
		NSURL *mediaURL;
		if ( [aResource representsURL] )
			mediaURL = [NSURL URLWithString:[aResource valueForKey:@"urlString"]];
		else if ( [aResource representsABRecord] )
			mediaURL = [NSURL URLWithString:[aResource valueForKey:@"uniqueId"]];
		else if ( [aResource representsFile] )
			mediaURL = [NSURL fileURLWithPath:[aResource originalPath]];
			
		JournlerMediaViewer *mediaViewer = [[[JournlerMediaViewer alloc] initWithURL:mediaURL uti:[aResource valueForKey:@"uti"]] autorelease];
		if ( mediaViewer == nil )
		{
			NSLog(@"%s - problem allocating media viewer for url %@", __PRETTY_FUNCTION__, mediaURL);
			[[NSWorkspace sharedWorkspace] openURL:mediaURL];
		}
		else
		{
			[mediaViewer setRepresentedObject:aResource];
			[mediaViewer showWindow:self];
		}

	}
	else 
	{
		[aResource openWithFinder];
	}
	*/
}

#pragma mark -
#pragma mark Working With Resources

- (IBAction) editResourceLabel:(id)sender
{
	NSArray *theResources = [self selectedResources];
	if ( theResources == nil || [theResources count] == 0 || [sender tag] == 10 ) {
		NSBeep(); return;
	}
	
	[theResources setValue:[NSNumber numberWithInt:[sender tag]] forKey:@"label"];
}

- (IBAction) revealResource:(id)sender
{

	NSArray *theResourceSelection = [self selectedResources];
	if ( theResourceSelection == nil || [theResourceSelection count] == 0 )
	{
		NSBeep();
		return;
	}
#warning why not just call makeObjectsPerformSelector on the array?
    for ( JournlerResource *aResource in theResourceSelection )
		[aResource revealInFinder];
}

- (IBAction) launchResource:(id)sender
{
	NSArray *theResourceSelection = [self selectedResources];
	if ( theResourceSelection == nil || [theResourceSelection count] == 0 )
	{
		NSBeep();
		return;
	}
	
    for ( JournlerResource *aResource in theResourceSelection )
		[aResource openWithFinder];
	
}

- (IBAction) openResourceInNewTab:(id)sender
{
	[[self valueForKey:@"owner"] newTab:sender];
	TabController *theTab =[[self valueForKeyPath:@"owner.tabControllers"] lastObject];
	[theTab selectDate:[self valueForKey:@"selectedDate"] folders:[self valueForKey:@"selectedFolders"] 
			entries:[self valueForKey:@"selectedEntries"] resources:[self valueForKey:@"selectedResources"]];
	
	// select the tab if shift is down
	if ( [[NSApp currentEvent] modifierFlags] & NSShiftKeyMask )
		[[self valueForKey:@"owner"] selectTabAtIndex:-1 force:NO];
}

- (IBAction) openResourceInNewWindow:(id)sender
{
	if ( [[self selectedResources] count] == 0 )
	{
		NSBeep(); return;
	}
	
    for ( JournlerResource *aResource in [self selectedResources] )
	{
		// put the  controller up
		EntryWindowController *entryWindow = [[[EntryWindowController alloc] initWithJournal:[self journal]] autorelease];		
		[entryWindow showWindow:self];
		
		// set its selection to our current selection
		[[entryWindow selectedTab] selectDate:nil folders:nil entries:[self selectedEntries] resources:[NSArray arrayWithObject:aResource]];
		[[entryWindow selectedTab] appropriateFirstResponder:[entryWindow window]];
		
		/*
		// open the resource in a new window if that's possible, finder otherwise
		if ( [JournlerMediaViewer canDisplayMediaOfType:[aResource valueForKey:@"uti"] 
				url:( ( [aResource representsFile] && [aResource originalPath] != nil ) ? [NSURL fileURLWithPath:[aResource originalPath]] : nil )] )
		{
			NSURL *mediaURL;
			if ( [aResource representsURL] )
				mediaURL = [NSURL URLWithString:[aResource valueForKey:@"urlString"]];
			else if ( [aResource representsABRecord] )
				mediaURL = [NSURL URLWithString:[aResource valueForKey:@"uniqueId"]];
			else if ( [aResource representsFile] )
				mediaURL = [NSURL fileURLWithPath:[aResource originalPath]];
				
			JournlerMediaViewer *mediaViewer = [[[JournlerMediaViewer alloc] initWithURL:mediaURL uti:[aResource valueForKey:@"uti"]] autorelease];
			if ( mediaViewer == nil )
			{
				NSLog(@"%s - problem allocating media viewer for url %@", __PRETTY_FUNCTION__, mediaURL);
				[[NSWorkspace sharedWorkspace] openURL:mediaURL];
			}
			else
			{
				[mediaViewer setRepresentedObject:aResource];
				[mediaViewer showWindow:self];
			}

		}
		else 
		{
			[aResource openWithFinder];
		}
		*/
	}
}

- (IBAction) openResourceInNewFloatingWindow:(id)sender
{
    for ( JournlerEntry *aResource in [self selectedResources] )
	{
		// put the  controller up
		FloatingEntryWindowController *entryWindow = [[[FloatingEntryWindowController alloc] initWithJournal:[self journal]] autorelease];		
		[entryWindow showWindow:self];
		
		// set its selection to our current selection
		[[entryWindow selectedTab] selectDate:nil folders:nil entries:[self selectedEntries] resources:[NSArray arrayWithObject:aResource]];
		[[entryWindow selectedTab] appropriateFirstResponder:[entryWindow window]];
	}
}

- (IBAction) setSelectionAsDefaultForEntry:(id)sender
{
	if ( [[self selectedResources] count] != 1 || [[self selectedEntries] count] != 1 )
	{
		NSBeep(); return;
	}
	
	JournlerResource *theResource = [[self selectedResources] objectAtIndex:0];
	
	if ( [theResource valueForKeyPath:@"entry.selectedResource"] == theResource )
		[[theResource valueForKey:@"entry"] setValue:nil forKey:@"selectedResource"];
	else
		[[theResource valueForKey:@"entry"] setValue:theResource forKey:@"selectedResource"];
}

- (IBAction) rescanResourceIcon:(id)sender
{
	if ( [[self selectedResources] count] == 0 )
	{
		NSBeep(); return;
	}
	
    for ( JournlerResource *aResource in [self selectedResources] )
	{
		[aResource setValue:nil forKey:@"icon"];
		[aResource reloadIcon];
	}
}

- (IBAction) rescanResourceUTI:(id)sender
{
	if ( [[self selectedResources] count] == 0 )
	{
		NSBeep(); return;
	}
	
    for ( JournlerResource *aResource in [self selectedResources] )
	{
		if ( [aResource representsFile] )
			[aResource setValue:[[NSWorkspace sharedWorkspace] UTIForFile:[aResource originalPath]] forKey:@"uti"];
	}
}

#pragma mark -
#pragma mark Working With Folders

- (IBAction) editFolderLabel:(id)sender
{
	NSArray *theFolders = [self selectedFolders];
	if ( theFolders == nil || [theFolders count] == 0 ) {
		NSBeep(); return;
	}
	
	[theFolders setValue:[NSNumber numberWithInt:[sender tag]] forKey:@"label"];
}

#pragma mark -

- (void) ownerWillClose 
{
#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
#endif
	
	// subclases should override this method to perform any pre-deallocation maintenance, calling super
	// ie undoing bindings to guarantee that the object will deallocate in the first place
	
	// remove ourselves from the notification center for entry and resource deletions from the journal
	[[NSNotificationCenter defaultCenter] removeObserver:self name:JournalWillDeleteEntryNotification object:journal];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:JournalWillDeleteResourceNotificiation object:journal];
	
}

- (void) willDeleteEntry:(NSNotification*)aNotification
{	
	JournlerEntry *theEntry = [[aNotification userInfo] objectForKey:@"entry"];
	if ( [[self selectedEntries] containsObject:theEntry] )
	{
		NSMutableArray *mySelectedEntries = [[[self selectedEntries] mutableCopyWithZone:[self zone]] autorelease];
		[mySelectedEntries removeObject:theEntry];
		[self setSelectedEntries:mySelectedEntries];
	}
}

- (void) willDeleteResource:(NSNotification*)aNotification
{
	JournlerResource *theResource = [[aNotification userInfo] objectForKey:@"resource"];
	if ( [[self selectedResources] containsObject:theResource] )
	{
		NSMutableArray *mySelectedResources = [[[self selectedResources] mutableCopyWithZone:[self zone]] autorelease];
		[mySelectedResources removeObject:theResource];
		[self setSelectedResources:mySelectedResources];
	}
}

- (void) ownerWillDeselectTab:(NSNotification*)aNotification
{
#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
#endif
	
	// autosave the current selection
	[self performAutosave:nil];
}

- (void) performAutosave:(NSNotification*)aNotification
{
#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
#endif
	
	// save the entries, save the folders
	// if objects are contained in user info, those objects are saved. otherwise the current selection
	
	NSArray *theEntries = nil, *theFolders = nil, *theResources = nil;
	
	if ( aNotification != nil )
	{
		NSDictionary *aDictionary = [aNotification userInfo];
		theEntries = [aDictionary objectForKey:@"entries"];
		theFolders = [aDictionary objectForKey:@"folders"];
		theResources = [aDictionary objectForKey:@"resources"];
	}
	
	// iterate through the entries, saving if dirty
	JournlerEntry *anEntry;
	NSEnumerator *enumerator;
	
	if ( theEntries == nil )
		enumerator = [[self selectedEntries] objectEnumerator];
	else
		enumerator = [theEntries objectEnumerator];
	
	while ( anEntry = [enumerator nextObject] )
	{
		if ( [[anEntry valueForKey:@"dirty"] boolValue] )
			[[self journal] saveEntry:anEntry];
	}
	
	// iterate through the folders, saving if dirty
	JournlerCollection *aFolder;
	
	if ( theFolders == nil )
		enumerator = [[self selectedFolders] objectEnumerator];
	else
		enumerator = [theFolders objectEnumerator];
	
	while ( aFolder = [enumerator nextObject] )
	{
		if ( [[aFolder valueForKey:@"dirty"] boolValue] )
			[[self journal] saveCollection:aFolder];
	}
	
	// iterate through the resources, saving if dirty
	JournlerResource *aResource;
	
	if ( theResources == nil )
		enumerator = [[self selectedResources] objectEnumerator];
	else
		enumerator = [theResources objectEnumerator];
	
	while ( aResource = [enumerator nextObject] )
	{
		if ( [[aResource valueForKey:@"dirty"] boolValue] )
			[[self journal] saveResource:aResource];
	}
}

- (BOOL) highlightString:(NSString*)aString
{
	// subclasses should override to highlight the string in their active view
	NSLog(@"%s - *** subclasses must override ***", __PRETTY_FUNCTION__);
	return NO;
}

- (IBAction) newWebBrower:(id)sender
{
	// subclasses should override to provide a new web browser in their viewing area
	NSLog(@"%s - *** subclasses must override ***", __PRETTY_FUNCTION__);
	return;
}

- (IBAction) newWindowWithSelection:(id)sender
{
	// subclasses may override
	if ( [[self selectedResources] count] > 0 ) 
	{
        for ( JournlerResource *aResource in [self selectedResources] )
		{
			// select the entry in a new window
			EntryWindowController *entryWindow = [[[EntryWindowController alloc] initWithJournal:[self journal]] autorelease];
			[entryWindow showWindow:self];
		
			// set it's selection to our current selection
			[[entryWindow selectedTab] selectDate:nil folders:nil 
			entries:[NSArray arrayWithObject:( [[self selectedEntries] count] == 1 ? [[self selectedEntries] objectAtIndex:0] : [aResource valueForKey:@"entry"] )]
			resources:[NSArray arrayWithObject:aResource]];
			
			[[entryWindow selectedTab] appropriateFirstResponder:[entryWindow window]];
			//[[entryWindow selectedTab] highlightString:aTerm];
		}

	}
	else if ( [[self selectedEntries] count] > 0 )
	{
        for ( JournlerEntry *anEntry in [self selectedEntries] )
		{
			// select the entry in a new window
			EntryWindowController *entryWindow = [[[EntryWindowController alloc] initWithJournal:[self journal]] autorelease];
			[entryWindow showWindow:self];
		
			// set it's selection to our current selection
			[[entryWindow selectedTab] selectDate:nil folders:nil entries:[NSArray arrayWithObject:anEntry] resources:nil];
			[[entryWindow selectedTab] appropriateFirstResponder:[entryWindow window]];
			//[[entryWindow selectedTab] highlightString:aTerm];
		}
	}
	else
	{
		NSBeep();
	}
}
- (IBAction) newFloatingWindowWithSelection:(id)sender
{
	// subclasses may override
	if ( [[self selectedResources] count] > 0 ) 
	{
        for ( JournlerResource *aResource in [self selectedResources] )
		{
			// select the entry in a new window
			FloatingEntryWindowController *entryWindow = [[[FloatingEntryWindowController alloc] initWithJournal:[self journal]] autorelease];
			[entryWindow showWindow:self];
		
			// set it's selection to our current selection
			[[entryWindow selectedTab] selectDate:nil folders:nil 
			entries:[NSArray arrayWithObject:( [[self selectedEntries] count] == 1 ? [[self selectedEntries] objectAtIndex:0] : [aResource valueForKey:@"entry"] )]
			resources:[NSArray arrayWithObject:aResource]];
			
			[[entryWindow selectedTab] appropriateFirstResponder:[entryWindow window]];
			//[[entryWindow selectedTab] highlightString:aTerm];
		}

	}
	else if ( [[self selectedEntries] count] > 0 )
	{
        for ( JournlerEntry *anEntry in [self selectedEntries] )
		{
			// select the entry in a new window
			FloatingEntryWindowController *entryWindow = [[[FloatingEntryWindowController alloc] initWithJournal:[self journal]] autorelease];
			[entryWindow showWindow:self];
		
			// set it's selection to our current selection
			[[entryWindow selectedTab] selectDate:nil folders:nil entries:[NSArray arrayWithObject:anEntry] resources:nil];
			[[entryWindow selectedTab] appropriateFirstResponder:[entryWindow window]];
			//[[entryWindow selectedTab] highlightString:aTerm];
		}
	}
	else
	{
		NSBeep();
	}

}

- (void) maximizeViewingArea
{
	// subclasses should override to get the most viewing space out of their content area, ie removing buttons along the bottom
	// once this operation has been executed it cannot be undone
	
	NSLog(@"%s - *** subclasses must override ***", __PRETTY_FUNCTION__);
	return;
}

- (void) setFullScreen:(BOOL)inFullScreen
{
	NSLog(@"%s - *** subclasses must override ***", __PRETTY_FUNCTION__);
	return;
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	BOOL enabled = YES;
	int tag = [menuItem tag];
	SEL action = [menuItem action];
	
	if ( action == @selector(copyLinkToJournlerObject:) )
	{
		if ( tag == 0 )
			enabled = ( [[self selectedEntries] count] != 0 );
		else if ( tag == 1 )
			enabled = ( [[self selectedResources] count] != 0 );
		else if ( tag == 2 )
			enabled = ( [[self selectedFolders] count] != 0 );
	}
	
	else if ( action == @selector(exportSelection:) )
	{
		if ( [[self selectedResources] count] != 0 )
		{
			enabled = YES;
			[menuItem setTitle:NSLocalizedString(@"menuitem export resources",@"")];
		}
		else if ( [[self selectedEntries] count] != 0 )
		{
			enabled = YES;
			[menuItem setTitle:NSLocalizedString(@"menuitem export entries",@"")];
		}
		else
		{
			enabled = NO;
			[menuItem setTitle:NSLocalizedString(@"menuitem export",@"")];
		}
	}
	
	else if ( action == @selector(editEntryLabel:) )
	{
		//NSLog(@"%s - tag: %i",__PRETTY_FUNCTION__,tag);
		//not called when the title is bound to user defaults!
		
		unsigned entryCount = [[self selectedEntries] count];
		enabled = ( entryCount > 0 );
		
		if ( tag == 0 || tag == 10 )
			[menuItem setState:NSOffState];
		else
		{
			// set the state
			[menuItem setState: [[[self selectedEntries] valueForKey:@"labelValue"] stateForInteger:tag] ];
			
			// set the title -- would bind but does not work in Leopard 10.5.2 at the very least
			NSString *defaultsKey = [NSString stringWithFormat:@"LabelName%i",tag];
			NSString *itemTitle = [[NSUserDefaults standardUserDefaults] stringForKey:defaultsKey];
			if ( itemTitle != nil ) [menuItem setTitle:itemTitle];
		}
	}
	
	else if ( action == @selector(revealEntryInFinder:) )
		enabled = ( [[self selectedEntries] count] != 0 );
		
	else if ( action == @selector(newFloatingWindowWithSelection:) )
		enabled = ( [[self selectedEntries] count] != 0 || [[self selectedResources] count] != 0 );
	
	else if ( action == @selector(newWindowWithSelection:) )
		enabled = ( [[self selectedEntries] count] != 0 || [[self selectedResources] count] != 0 );
	
	return enabled;
}

@end


@implementation TabController (FindPanelSupport)

- (BOOL) handlesFindCommand
{
	// subclasses should override if they do
	return NO;
}

- (void) performCustomFindPanelAction:(id)sender
{
	// subclasses should override
	NSLog(@"%s - **** not supported: subclasses must override ****", __PRETTY_FUNCTION__);
}

- (BOOL) handlesTextSizeCommand
{
	// subclasses should override if they do
	return NO;
}

- (void) performCustomTextSizeAction:(id)sender
{
	// subclasses should override
	NSLog(@"%s - **** not supported: subclasses must override ****", __PRETTY_FUNCTION__);
}

@end


@implementation TabController (JournlerScripting)

- (NSScriptObjectSpecifier *)objectSpecifier 
{
	NSIndexSpecifier *specifier = [[NSIndexSpecifier alloc] initWithContainerClassDescription:
			(NSScriptClassDescription *)[(JournlerWindow*)[owner window] classDescription]
			containerSpecifier: [(JournlerWindow*)[owner window] objectSpecifier] 
			key: @"JSTabs" index:[(JournlerWindow*)[owner window] indexOfObjectInJSTabs: self]];
	
	return [specifier autorelease];
}

#pragma mark -

- (NSArray*) scriptVisibleEntries
{
	// subclasses should override to return the list of entries currently visible in the tab
	return nil;
}

#pragma mark -

- (NSDate*) scriptSelectedDate
{
	return [self selectedDate];
}

- (void) setScriptSelectedDate:(NSDate*)aDate
{
	[self selectDate:aDate];
}

- (NSArray*) scriptSelectedFolders
{
	return [self selectedFolders];
}

- (void) setScriptSelectedFolders:(NSArray*)anArray
{
	[self selectFolders:anArray];
}

- (NSArray*) scriptSelectedEntries
{
	return [self selectedEntries];
}

- (void) setScriptSelectedEntries:(NSArray*)anArray
{
	[self selectEntries:anArray];
}

- (NSArray*) scriptSelectedResources
{
	return [self selectedResources];
}

- (void) setScriptSelectedResources:(NSArray*)anArray
{
	[self selectResources:anArray];
}

#pragma mark -

- (void) jsPrintTab:(NSScriptCommand *)command
{
	NSDictionary *args = [command evaluatedArguments];
	NSLog(@"%@",[args description]);
}

@end
