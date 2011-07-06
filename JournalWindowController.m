//
//  JournalWindowController.m
//  Journler
//
//  Created by Phil Dow on 10/24/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "JournalWindowController.h"
#import "JournlerApplicationDelegate.h"

#import "JournlerCollection.h"

#import "JournalTabController.h"

#import "EntriesTableView.h"
#import "BrowseTableFieldEditor.h"

#import <SproutedInterface/SproutedInterface.h>
#import <SproutedUtilities/SproutedUtilities.h>

@implementation JournalWindowController

+ (id) sharedController 
{
    static JournalWindowController *sharedController = nil;
    if (!sharedController) 
	{
        sharedController = [[JournalWindowController allocWithZone:NULL] init];
    }

    return sharedController;
}

#pragma mark -

- (id) init 
{
	static NSString *kNibName = @"Journal";
	NSString *kNibName105 = [NSString stringWithFormat:@"%@_105",kNibName];
	NSString *theNib = nil;
	
	if ( [[NSBundle mainBundle] respondsToSelector:@selector(executableArchitectures)] 
			&& [[NSBundle mainBundle] pathForResource:kNibName105 ofType:@"nib"] != nil )
		theNib = kNibName105;
	else
		theNib = kNibName;
	
	if ( self = [super initWithWindowNibName:theNib] )
	{
		[self setWindowFrameAutosaveName:@"JournalWindow"];
	}
	return self;
}

- (void) windowDidLoad 
{
	[super windowDidLoad];
	if ( [[self window] respondsToSelector:@selector(contentBorderThicknessForEdge:)] )
		[[self window] setContentBorderThickness:29.0 forEdge:NSMinYEdge];
		
	//[[self window] setAutorecalculatesKeyViewLoop:NO];
	
	activeTabView = initalTabPlaceholder;
	
	// initiate the single tab
	/*
	JournalTabController *tab = [[[[self defaultTabClass] alloc] initWithOwner:self] autorelease];
	
	// move the tab into place
	[[tab tabContent] setFrame:[activeTabView frame]];
	[[activeTabView superview] replaceSubview:activeTabView with:[tab tabContent]];
	activeTabView = [tab tabContent];
	*/
	
	// make the tab view and bookmarks view visible if requested by the user
	[self setBookmarksHidden:![[NSUserDefaults standardUserDefaults] boolForKey:@"MainWindowBookmarksVisible"]];
	[self setTabsHidden:![[NSUserDefaults standardUserDefaults] boolForKey:@"MainWindowTabsAlwaysVisible"]];
	
	// the custom field editor
	[browseTableFieldEditor retain];
	[browseTableFieldEditor setFieldEditor:YES];
	
	// set up the toolbar
	[self setupToolbar];
	
	// adjust content height if toolbar is hidden
	if ( ![[[self window] toolbar] isVisible] )
		[self toolbarDidHide:(PDToolbar*)[[self window] toolbar]];
	
	/*
	// take note of selection changes so that navigation may be updated
	[self startObservingTab:tab paths:[self observedPathsForTab:tab]];
	
	// add the tab to the array and select it
	[self addTab:tab atIndex:-1];
	[self setSelectedTabIndex:0];
	*/
}

- (void) dealloc 
{	
	[browseTableFieldEditor release], browseTableFieldEditor = nil;
	[highlightButton release], highlightButton = nil;
	[dateTimeButton release], dateTimeButton = nil;
	
	[super dealloc];
}

- (void)windowWillClose:(NSNotification *)aNotification
{	
	// don't do anything because the window just hides and that's it, otherwise remaining "active" so to speak
	
	// [self stopObservingTab:[self selectedTab] paths:[self observedPathsForTab:[self selectedTab]]];
	// [super windowWillClose:aNotification];
}

#pragma mark -

- (Class) defaultTabClass
{
	// subclasses must override to return the class of default tab for that window
	return [JournalTabController class];
}

- (NSArray*) observedPathsForTab:(TabController*)aTab
{
	NSArray *observedPaths = [NSArray arrayWithObjects:@"selectedDate", @"selectedFolders", 
	@"selectedEntries", @"selectedResources", nil];
	return observedPaths;
}

- (NSString*) windowTitle
{
	// subclasses should override to provide appropriate title
	return [self valueForKeyPath:@"journal.title"];
}

#pragma mark -

- (BOOL)windowShouldClose:(id)sender 
{	
	// store the state data in the journal
	NSData *stateData = [self stateData];
	[[self journal] setValue:stateData forKey:@"tabState"];

	return YES;	
}

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject {
	
	if ( [self window] != sender ) 
		return nil;
			
	if ( [anObject isKindOfClass:[PDAutoCompleteTextField class]] )
	{
		[browseTableFieldEditor setCompletions:[[NSUserDefaults standardUserDefaults] arrayForKey:@"Journler Categories List"]];
		[browseTableFieldEditor setCompletes:YES];
		return browseTableFieldEditor;
	}
	
	else if ( [anObject isKindOfClass:[EntriesTableView class]] )
	{
		if ( [(EntriesTableView*)anObject editingCategory] )
		{
			[browseTableFieldEditor setCompletions:[[NSUserDefaults standardUserDefaults] arrayForKey:@"Journler Categories List"]];
			[browseTableFieldEditor setCompletes:YES];
			
			return browseTableFieldEditor;
		}
		else
		{
			return nil;
		}
		/*
		else
		{
			[browseTableFieldEditor setCompletions:nil];
			[browseTableFieldEditor setCompletes:NO];
		}
		return browseTableFieldEditor;
		*/
	}
	
	else
	{
		return nil;
	}
}


#pragma mark -

- (NSSearchField*) searchOutlet
{
	return searchOutlet;
}

#pragma mark -

- (void) updateNavInterface 
{	
	[super updateNavInterface];
	
	if ( [[tabControllers objectAtIndex:[self selectedTabIndex]] respondsToSelector:@selector(canPerformNavigation:)] ) 
	{
		if ( [[NSBundle mainBundle] respondsToSelector:@selector(executableArchitectures)] )
		{
			[navBackForward setEnabled:[[tabControllers objectAtIndex:[self selectedTabIndex]] canPerformNavigation:0] forSegment:0];
			[navBackForward setEnabled:[[tabControllers objectAtIndex:[self selectedTabIndex]] canPerformNavigation:1] forSegment:1];
		}
		else
		{
			[navBack setEnabled:[[tabControllers objectAtIndex:[self selectedTabIndex]] canPerformNavigation:0]];
			[navForward setEnabled:[[tabControllers objectAtIndex:[self selectedTabIndex]] canPerformNavigation:1]];
			
			[navBack setImage:[NSImage imageNamed:
					([[tabControllers objectAtIndex:[self selectedTabIndex]] 
					canPerformNavigation:0]?@"ToolbarItemBack.png":@"ToolbarItemBackDisabled.png")]];
			[navForward setImage:[NSImage imageNamed:
					([[tabControllers objectAtIndex:[self selectedTabIndex]] 
					canPerformNavigation:1]?@"ToolbarItemForward.png":@"ToolbarItemForwardDisabled.png")]];
		}
	}
	else
	{
		// completely disable navigation
		if ( [[NSBundle mainBundle] respondsToSelector:@selector(executableArchitectures)] )
		{
			[navBackForward setEnabled:NO forSegment:0];
			[navBackForward setEnabled:NO forSegment:1];
		}
		else
		{
			[navBack setEnabled:NO];
			[navForward setEnabled:NO];
			
			[navBack setImage:[NSImage imageNamed:@"ToolbarItemBackDisabled.png"]];
			[navForward setImage:[NSImage imageNamed:@"ToolbarItemForwardDisabled.png"]];
		}
	}
}

#pragma mark -

- (void) setBookmarksHidden:(BOOL)hidden
{
	[super setBookmarksHidden:hidden];
	[[NSUserDefaults standardUserDefaults] setBool:!hidden forKey:@"MainWindowBookmarksVisible"];
}

- (IBAction) toggleRuler:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(toggleRuler:)] )
		[[self selectedTab] performSelector:@selector(toggleRuler:) withObject:sender];
	else
	{
		NSBeep();
	}
}

#pragma mark -
#pragma mark Navigating the Calendar

- (IBAction) toToday:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(toToday:)] )
		[[self selectedTab] performSelector:@selector(toToday:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) dayToRight:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(dayToRight:)] )
		[[self selectedTab] performSelector:@selector(dayToRight:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) dayToLeft:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(dayToLeft:)] )
		[[self selectedTab] performSelector:@selector(dayToLeft:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) monthToRight:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(monthToRight:)] )
		[[self selectedTab] performSelector:@selector(monthToRight:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) monthToLeft:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(monthToLeft:)] )
		[[self selectedTab] performSelector:@selector(monthToLeft:) withObject:sender];
	else
	{
		NSBeep();
	}
}

#pragma mark -
#pragma mark Hidden Keyboard Shortcuts

- (IBAction) emptyTrash:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(emptyTrash:)] )
		[[self selectedTab] performSelector:@selector(emptyTrash:) withObject:sender];
	else
	{
		NSBeep();
	}
}

#pragma mark -
#pragma mark Searching

- (IBAction) clearSearch:(id)sender
{
	if ( [[searchOutlet stringValue] length] != 0 )
	{
		[searchOutlet setStringValue:[NSString string]];
		[self performToolbarSearch:searchOutlet];
	}
}

- (IBAction) changeSearchOption:(id)sender
{
	if ( [sender tag] == 1 )
		[[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:@"SearchSpaceMeansOr"] forKey:@"SearchSpaceMeansOr"];
	
	if ( [[searchOutlet stringValue] length] != 0 )
		[self performToolbarSearch:searchOutlet];
}

- (IBAction) setAutoenablePrefixSearching:(id)sender
{
	BOOL value = [[NSUserDefaults standardUserDefaults] boolForKey:@"AutoEnablePrefixSearching"];
	[[NSUserDefaults standardUserDefaults] setBool:!value forKey:@"AutoEnablePrefixSearching"];
	
	if ( [[searchOutlet stringValue] length] != 0 )
		[self performToolbarSearch:searchOutlet];
}

- (IBAction) setSearchedContent:(id)sender
{
	/*
	if ( [sender tag] == 0 )
	{
		BOOL value = [[NSUserDefaults standardUserDefaults] boolForKey:@"SearchIncludesEntries"];
		[[NSUserDefaults standardUserDefaults] setBool:!value forKey:@"SearchIncludesEntries"];
	}
	else if ( [sender tag] == 1 )
	{
		BOOL value = [[NSUserDefaults standardUserDefaults] boolForKey:@"SearchIncludesResources"];
		[[NSUserDefaults standardUserDefaults] setBool:!value forKey:@"SearchIncludesResources"];
	}
	
	if ( [[searchOutlet stringValue] length] != 0 )
		[self performToolbarSearch:searchOutlet];
	*/
	
	return;
}

- (IBAction) setSearchSystem:(id)sender
{
	if ( [sender tag] == 0 )
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"UsePantherSearch"];
	else if ( [sender tag] == 1 )
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"UsePantherSearch"];
	
	if ( [[searchOutlet stringValue] length] != 0 )
		[self performToolbarSearch:searchOutlet];
}

- (IBAction) focusSearchField:(id)sender
{
	if ( ![[[self window] toolbar] isVisible] )
		[[[self window] toolbar] setVisible:YES];
		
	[[self window] makeFirstResponder:searchOutlet];
}

- (IBAction) performToolbarSearch:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(performToolbarSearch:)] )
		[[self selectedTab] performSelector:@selector(performToolbarSearch:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) filterEntries:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(filterEntries:)] )
		[[self selectedTab] performSelector:@selector(filterEntries:) withObject:sender];
	else
	{
		NSBeep();
	}
}

#pragma mark -

- (IBAction) showSearchHelp:(id)sender
{
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"JournlerSearchingTheBestResults" inBook:@"JournlerHelp"];
}

#pragma mark -

- (IBAction) saveSearchResults:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(saveSearchResults:)] )
		[[self selectedTab] performSelector:@selector(saveSearchResults:) withObject:searchOutlet];
	else
	{
		NSBeep();
	}
}

- (IBAction) saveFilterResults:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(saveFilterResults:)] )
		[[self selectedTab] performSelector:@selector(saveFilterResults:) withObject:sender];
	else
	{
		NSBeep();
	}
}

#pragma mark -
#pragma mark Appearance

- (IBAction) toggleUsesAlternatingRows:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(toggleUsesAlternatingRows:)] )
		[[self selectedTab] performSelector:@selector(toggleUsesAlternatingRows:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) toggleDrawsLabelBackground:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(toggleDrawsLabelBackground:)] )
		[[self selectedTab] performSelector:@selector(toggleDrawsLabelBackground:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) showEntryTableColumn:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(showEntryTableColumn:)] )
		[[self selectedTab] performSelector:@selector(showEntryTableColumn:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) sortEntryTableByColumn:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(sortEntryTableByColumn:)] )
		[[self selectedTab] performSelector:@selector(sortEntryTableByColumn:) withObject:sender];
	else
	{
		NSBeep();
	}

}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	BOOL enabled = YES;
	int tag = [menuItem tag];
	SEL action = [menuItem action];
	
	if ( action == @selector(toggleUsesAlternatingRows:) )
	{
		enabled = [[self selectedTab] respondsToSelector:@selector(toggleUsesAlternatingRows:)];
		[menuItem setState:( [[NSUserDefaults standardUserDefaults] boolForKey:@"BrowseTableAlternatingRows"] == YES ? NSOnState : NSOffState )];
	}
	
	else if ( action == @selector(toggleDrawsLabelBackground:) )
	{
		enabled = [[self selectedTab] respondsToSelector:@selector(toggleDrawsLabelBackground:)];
		//BOOL noBackground = [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryTableNoLabelBackground"];
		[menuItem setState:( [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryTableNoLabelBackground"] == YES ? NSOffState : NSOnState )];
	}
	
	else if ( action == @selector(setAutoenablePrefixSearching:) )
	{
		//enabled = [[self selectedTab] respondsToSelector:@selector(performToolbarSearch:)];
		//if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"UsePantherSearch"] )
		//{
		//	enabled = NO;
		//	[menuItem setState:NSOnState];
		//}
		//else
		//{
			enabled = [[self selectedTab] respondsToSelector:@selector(performToolbarSearch:)];
			[menuItem setState:( [[NSUserDefaults standardUserDefaults] boolForKey:@"AutoEnablePrefixSearching"] )];
		//}
	}
	
	/*
	else if ( action == @selector(setSearchedContent:) )
	{
		enabled = [[self selectedTab] respondsToSelector:@selector(performToolbarSearch:)];
		if ( tag == 0 )
			[menuItem setState:( [[NSUserDefaults standardUserDefaults] boolForKey:@"SearchIncludesEntries"] )];
		else if ( tag == 1 )
			[menuItem setState:( [[NSUserDefaults standardUserDefaults] boolForKey:@"SearchIncludesResources"] )];
	}
	*/
	
	else if ( action == @selector(setSearchSystem:) )
	{
		enabled = [[self selectedTab] respondsToSelector:@selector(performToolbarSearch:)];
		if ( tag == 0 )
			[menuItem setState:( ![[NSUserDefaults standardUserDefaults] boolForKey:@"UsePantherSearch"] )];
		else if ( tag == 1 )
			[menuItem setState:( [[NSUserDefaults standardUserDefaults] boolForKey:@"UsePantherSearch"] )];
	}
	
	else if ( action == @selector(focusSearchField:) )
	{
		NSString *theTitle = NSLocalizedString( 
		( ( [[[self selectedTab] selectedFolders] count] == 0 || 
		( [[[self selectedTab] selectedFolders] count] == 1 && [[[[self selectedTab] selectedFolders] objectAtIndex:0] isLibrary] ) )
		? @"find in journal" : @"find in folder" ), @"" );
		
		[menuItem setTitle:theTitle];
		enabled = YES;
	}
	
	else if ( action == @selector(showSearchHelp:) )
		enabled = YES;
	
	else if ( action == @selector(changeSearchOption:) )
	{
		enabled = YES;
		if ( tag == 1 )
			[menuItem setState:( [[NSUserDefaults standardUserDefaults] boolForKey:@"SearchSpaceMeansOr"] ? NSOnState : NSOffState )];
	}
	
	else if ( action == @selector(emptyTrash:) )
		enabled = ( [[self selectedTab] respondsToSelector:@selector(emptyTrash:)] ? [[self selectedTab] validateMenuItem:menuItem] : NO );
	
	else
		enabled = [super validateMenuItem:menuItem];
			
	return enabled;
}

- (IBAction) newWebBrower:(id)sender
{
	TabController *aTab = [[[[self defaultTabClass] alloc] initWithOwner:self] autorelease];
	TabController *currentTab = [self selectedTab];
	
	[self addTab:aTab atIndex:[self selectedTabIndex]];
	
	[[aTab tabContent] setFrame:[activeTabView frame]];
	[aTab restoreLocalStateWithDictionary:[currentTab localStateDictionary]];
	[aTab selectDate:nil folders:nil entries:nil resources:nil];
	
	[self selectTabAtIndex:[self selectedTabIndex] force:YES];
	[aTab newWebBrower:sender];

}

- (void) showFirstRunConfiguration
{
	// just make a tab and stick it in there
	TabController *aTabController = [[[[self defaultTabClass] alloc] initWithOwner:self] autorelease];
	[self addTab:aTabController atIndex:-1];
	[self selectTabAtIndex:0 force:YES];
	[[self selectedTab] appropriateFirstResponder:[self window]];
}

@end

#pragma mark -

@implementation JournalWindowController (Toolbar)

static NSString	*kJournalWindowToolbar			= @"kJournalWindowToolbar";
static NSString	*kSearchToolbarItem				= @"kSearchToolbarItem";
static NSString *kIMediaToolbarItem				= @"kIMediaToolbarItem";
//static NSString *kCorrespondenceToolbarItem		= @"kCorrespondenceToolbarItem";
static NSString *kNavToolbarItem				= @"kNavToolbarItem";
static NSString *kAddressBookToolarItem			= @"kAddressBookToolarItem";
static NSString	*kFilterToolarIdentifier		= @"kFilterToolarIdentifier";

static NSString	*kNewEntryToolbarItem			= @"kNewEntryToolbarItem";
static NSString	*kNewFolderToolbarItem			= @"kNewFolderToolbarItem";
static NSString	*kNewSmartFolderToolbarItem		= @"kNewSmartFolderToolbarItem";
static NSString	*kNewTabToolbarItem				= @"kNewTabToolbarItem";
static NSString	*kDeleteToolbarItem				= @"kDeleteToolbarItem";

static NSString	*kExportToolbarItem				= @"kExportToolbarItem";
static NSString	*kBlogToolbarItem				= @"kBlogToolbarItem";
static NSString	*kEmailToolbarItem				= @"kEmailToolbarItem";
static NSString	*kiWebToolbarItem				= @"kiWebToolbarItem";
static NSString	*kiPodToolbarItem				= @"kiPodToolbarItem";

static NSString	*kRecordAudioToolbarItem		= @"kRecordAudioToolbarItem";
static NSString	*kRecordVideoToolbarItem		= @"kRecordVideoToolbarItem";
static NSString *kRecordSnapshotToolarItem		= @"kRecordSnapshotToolarItem";

static NSString	*kHeaderToolbarItem				= @"kHeaderToolbarItem";
static NSString	*kRulerToolbarItem				= @"kRulerToolbarItem";

static NSString	*kEntryInfoToolbarItem			= @"kEntryInfoToolbarItem";
static NSString	*kFlagEntryToolbarItem			= @"kFlagEntryToolbarItem";

static NSString	*kSubscriptToolbarItem			= @"kSubscriptToolbarItem";
static NSString	*kSuperscriptToolbarItem		= @"kSuperscriptToolbarItem";
static NSString	*kHighlightToolbarItem			= @"kHighlightToolbarItem";
static NSString	*kBlockQuoteToolbarItem			= @"kBlockQuoteToolbarItem";

static NSString *kInsertCheckoxToolbarItem		= @"kInsertCheckoxToolbarItem";
static NSString *kInsertTableToolbarItem		= @"kInsertTableToolbarItem";
static NSString *kInsertListToolbarItem			= @"kInsertListToolbarItem";
static NSString *kInsertDateTimeToolbarItem		= @"kInsertDateTimeToolbarItem";
static NSString *kInsertLinkToolbarItem			= @"kInsertLinkToolbarItem";

static NSString *kLexiconToolbarItem			= @"kLexiconToolbarItem";
static NSString	*kLockoutToolbarItem			= @"kLockoutToolbarItem";

- (void) setupToolbar {

	//the search outlet
	[searchOutlet retain];
    [searchOutlet removeFromSuperview]; 
	
	// nav outlet
	[navOutlet retain];
	[navOutlet removeFromSuperview];
	
	if ( ![[NSBundle mainBundle] respondsToSelector:@selector(executableArchitectures)] )
	{
		[[navBack cell] setImageDimsWhenDisabled:NO];
		[[navForward cell] setImageDimsWhenDisabled:NO];
	}
	
	// date time popup and highlight pop
	[self setupDateTimePopUpButton];
	[self setupHighlightPopUpButton];
	
	//building and displaying the toolbar
    PDToolbar *toolbar = [[[PDToolbar alloc] initWithIdentifier: kJournalWindowToolbar] autorelease];
	
    [toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration:YES];
    [toolbar setDelegate: self];
	
    [[self window] setToolbar: toolbar];
}

- (void) setupDateTimePopUpButton
{
	NSMenuItem *pulldownItem;
	NSMenuItem *insertDateItem;
	NSMenuItem *insertTimeItem;
	NSMenuItem *insertDateTimeItem;
	
	dateTimeButton = [[PDPopUpButtonToolbarItem alloc] initWithFrame: NSMakeRect(0,0,32,32) pullsDown:YES];
	[[dateTimeButton cell] setArrowPosition:NSPopUpArrowAtBottom];
	
	pulldownItem = [[[NSMenuItem alloc] initWithTitle:[NSString string] 
			action:nil 
			keyEquivalent:[NSString string]] autorelease];
	[pulldownItem setImage:[NSImage imageNamed:@"ToolbarItemInsertDateTime.tif"]];
	
	insertDateItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Insert Date",@"") 
			action:@selector(insertDateTime:) 
			keyEquivalent:[NSString string]] autorelease];
	[insertDateItem setTarget:nil];
	[insertDateItem setTag:120];
	
	insertTimeItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Insert Time",@"") 
			action:@selector(insertDateTime:) 
			keyEquivalent:[NSString string]] autorelease];
	[insertTimeItem setTarget:nil];
	[insertTimeItem setTag:121];
	
	insertDateTimeItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Insert Date & Time",@"") 
			action:@selector(insertDateTime:) 
			keyEquivalent:[NSString string]] autorelease];
	[insertDateTimeItem setTarget:nil];
	[insertDateTimeItem setTag:122];
	
	[[dateTimeButton menu] addItem:pulldownItem];
	[[dateTimeButton menu] addItem:insertDateItem];
	[[dateTimeButton menu] addItem:insertTimeItem];
	[[dateTimeButton menu] addItem:insertDateTimeItem];	
}

- (void) setupHighlightPopUpButton
{
	NSMenu *highlightButtonMenu;
	NSMenuItem *pulldownItem;
	NSMenuItem *separatorItem;
	NSMenuItem *yellowItem, *blueItem, *greenItem, *orangeItem, *redItem;
	NSMenuItem *removeHighlightItem;
	
	highlightButton = [[PDPopUpButtonToolbarItem alloc] initWithFrame: NSMakeRect(0,0,32,32) pullsDown:YES];
	[[highlightButton cell] setArrowPosition:NSPopUpArrowAtBottom];
	
	pulldownItem = [[[NSMenuItem alloc] initWithTitle:[NSString string] 
			action:nil 
			keyEquivalent:[NSString string]] autorelease];
	[pulldownItem setImage:[NSImage imageNamed:@"ToolbarItemHighlight.png"]];
	
	yellowItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Yellow",@"") 
			action:@selector(highlightSelection:) 
			keyEquivalent:[NSString string]] autorelease];
	[yellowItem setTarget:nil];
	[yellowItem setTag:351];
	
	blueItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Blue",@"") 
			action:@selector(highlightSelection:) 
			keyEquivalent:[NSString string]] autorelease];
	[blueItem setTarget:nil];
	[blueItem setTag:352];
	
	greenItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Green",@"") 
			action:@selector(highlightSelection:) 
			keyEquivalent:[NSString string]] autorelease];
	[greenItem setTarget:nil];
	[greenItem setTag:353];
	
	orangeItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Orange",@"") 
			action:@selector(highlightSelection:) 
			keyEquivalent:[NSString string]] autorelease];
	[orangeItem setTarget:nil];
	[orangeItem setTag:354];
	
	redItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Red",@"") 
			action:@selector(highlightSelection:) 
			keyEquivalent:[NSString string]] autorelease];
	[redItem setTarget:nil];
	[redItem setTag:355];
	
	separatorItem = [NSMenuItem separatorItem];
	
	removeHighlightItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Remove Highlight",@"") 
			action:@selector(highlightSelection:) 
			keyEquivalent:[NSString string]] autorelease];
	[removeHighlightItem setTarget:nil];
	[removeHighlightItem setTag:356];
	
	[[highlightButton menu] addItem:pulldownItem];
	[[highlightButton menu] addItem:yellowItem];
	[[highlightButton menu] addItem:blueItem];
	[[highlightButton menu] addItem:greenItem];
	[[highlightButton menu] addItem:orangeItem];
	[[highlightButton menu] addItem:redItem];
	
	[[highlightButton menu] addItem:separatorItem];
	[[highlightButton menu] addItem:removeHighlightItem];	
	
	highlightButtonMenu = [highlightButton menu];
	[[NSApp delegate] prepareHighlightMenu:&highlightButtonMenu];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar 
		itemForItemIdentifier:(NSString *)itemIdent 
		willBeInsertedIntoToolbar:(BOOL) willBeInserted 
{	
	NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
	
	if ( [itemIdent isEqual:kSearchToolbarItem]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"search label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"search label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"search tip", @"Toolbar", @"")];
		
		[toolbarItem setView: searchOutlet];
		[toolbarItem setMinSize:NSMakeSize(30, NSHeight([searchOutlet frame]))];
		[toolbarItem setMaxSize:NSMakeSize(200,NSHeight([searchOutlet frame]))];
		
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(performToolbarSearch:)];
    }
	else if ( [itemIdent isEqual:kNavToolbarItem] )
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"nav label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"nav label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"nav tip", @"Toolbar", @"")];
		
		[toolbarItem setView: navOutlet];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([navOutlet frame]), NSHeight([navOutlet frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([navOutlet frame]),NSHeight([navOutlet frame]))];
	}
	else if ( [itemIdent isEqual:kIMediaToolbarItem]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"ilife label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"ilife label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"ilife tip", @"Toolbar", @"")];
		[toolbarItem setImage:[NSImage imageByReferencingImageNamed:@"ToolbarItemiLife.tiff"]];
		
		[toolbarItem setTarget: nil];
		[toolbarItem setAction: @selector(showMediaBrowser:)];
    }
	/*
	else if ( [itemIdent isEqual:kCorrespondenceToolbarItem]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"correspondence label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"correspondence label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"correspondence tip", @"Toolbar", @"")];
		[toolbarItem setImage:[NSImage imageByReferencingImageNamed:@"ToolbarItemCorrespondence.png"]];
		
		[toolbarItem setTarget: nil];
		[toolbarItem setAction: @selector(showCorrespondenceBrowser:)];
    }
	*/
	else if ( [itemIdent isEqual:kAddressBookToolarItem] ) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"address label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"address label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"address tip", @"Toolbar", @"")];
		[toolbarItem setImage:[NSImage imageByReferencingImageNamed:@"ToolbarItemAddressBook.tiff"]];
		
		[toolbarItem setTarget: nil];
		[toolbarItem setAction: @selector(showContactsBrowser:)];
	}
	else if ( [itemIdent isEqual:kFilterToolarIdentifier] ) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"filter label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"filter label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"filter tip", @"Toolbar", @"")];
		[toolbarItem setImage:[NSImage imageByReferencingImageNamed:@"ToolbarItemFilter.tif"]];
		
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(filterEntries:)];
	}
	
	
	else if ( [itemIdent isEqual: kNewEntryToolbarItem] ) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"entry label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedStringFromTable(@"entry label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"entry tip", @"Toolbar", @"")];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemNewEntry.tif"]];
		
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(newEntry:)];
	}
	else if ( [itemIdent isEqual: kDeleteToolbarItem] ) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"delete label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedStringFromTable(@"delete label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"delete tip", @"Toolbar", @"")];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemDelete.tif"]];
		
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(deleteSelectedEntries:)];
	}
	else if ([itemIdent isEqual: kNewFolderToolbarItem]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"newfolder label", @"Toolbar", @"") ];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"newfolder label", @"Toolbar", @"") ];
		
		[toolbarItem setToolTip:NSLocalizedStringFromTable(@"newfolder tip", @"Toolbar", @"") ];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemNewFolder.png"]];
		
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(newFolder:)];
	}
	else if ([itemIdent isEqual: kNewSmartFolderToolbarItem]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"newsmartfolder label", @"Toolbar", @"") ];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"newsmartfolder label", @"Toolbar", @"") ];
		
		[toolbarItem setToolTip:NSLocalizedStringFromTable(@"newsmartfolder tip", @"Toolbar", @"") ];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemNewSmartFolder.png"]];
		
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(newSmartFolder:)];
	}
	else if ([itemIdent isEqual:kNewTabToolbarItem]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"newtab label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"newtab label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"newtab tip", @"Toolbar", @"")];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarNewTab.png"]];
		
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(newTab:)];
	}
	
	
	else if ( [itemIdent isEqual: kExportToolbarItem] )
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"export label", @"Toolbar", @"") ];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"export label", @"Toolbar", @"") ];
		
		[toolbarItem setToolTip:NSLocalizedStringFromTable(@"export tip", @"Toolbar", @"") ];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemExport.png"]];
		
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(exportSelection:)];
	}
	
	else if ( [itemIdent isEqual: kEmailToolbarItem] ) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"email label", @"Toolbar", @"") ];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"email label", @"Toolbar", @"") ];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"email tip", @"Toolbar", @"") ];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemEmail.tif"]];
		
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(emailDocument:)];
	}
	
	else if ( [itemIdent isEqual: kBlogToolbarItem] ) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"blog label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedStringFromTable(@"blog label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"blog tip", @"Toolbar", @"")];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemBlog.tiff"]];
		
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(blogDocument:)];
	}
	
	else if ( [itemIdent isEqualToString:kiWebToolbarItem] ) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"iweb label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"iweb label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"iweb tip", @"Toolbar", @"")];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemiWeb.png"]];
		
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(sendEntryToiWeb:)];
	}
	else if ( [itemIdent isEqualToString:kiPodToolbarItem] ) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"ipod label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"ipod label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"ipod tip", @"Toolbar", @"")];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemIPod.png"]];
		
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(sendEntryToiPod:)];
	}
	
	
	else if ( [itemIdent isEqual: kRecordAudioToolbarItem] ) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"record label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedStringFromTable(@"record label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"record tip", @"Toolbar", @"")];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemRecordAudio.png"]];
		
		[toolbarItem setTarget: nil];
		[toolbarItem setAction: @selector(recordAudio:)];
	}
	else if ([itemIdent isEqual:kRecordVideoToolbarItem]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"record video label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"record video label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"record video tip", @"Toolbar", @"")];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemRecordVideo.png"]];
		
		[toolbarItem setTarget: nil];
		[toolbarItem setAction: @selector(recordVideo:)];
	}
	else if ([itemIdent isEqual:kRecordSnapshotToolarItem]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"snapshot label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"snapshot label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"snapshot tip", @"Toolbar", @"")];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemSnapshot.png"]];
		
		[toolbarItem setTarget: nil];
		[toolbarItem setAction: @selector(captureSnapshot:)];
	}


	else if ( [itemIdent isEqual: kHeaderToolbarItem] ) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"header label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedStringFromTable(@"header label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"header tip", @"Toolbar", @"")];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemHeader.tif"]];
		
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(toggleHeader:)];
	}
	else if([itemIdent isEqual: kRulerToolbarItem]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"ruler label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"ruler label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"ruler tip", @"Toolbar", @"")];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemRuler.tif"]];
		
		[toolbarItem setTarget: nil];
		[toolbarItem setAction: @selector(toggleRuler:)];
	}
	
	
	else if([itemIdent isEqual: kEntryInfoToolbarItem]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"entryinfo label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"entryinfo label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"entryinfo tip", @"Toolbar", @"")];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemDetails.tif"]];
		
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(getEntryInfo:)];
	}
	else if([itemIdent isEqual: kFlagEntryToolbarItem]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"flag label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"flag label", @"Toolbar", @"")];
		
		[toolbarItem setTag:331];
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"flag tip", @"Toolbar", @"")];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemFlag.tif"]];
		
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(editEntryProperty:)];
	}
	
	
	else if([itemIdent isEqual: kSubscriptToolbarItem]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"subscript label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"subscript label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"subscript tip", @"Toolbar", @"")];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemSubscript.tif"]];
		
		[toolbarItem setTarget:nil];
		[toolbarItem setAction: @selector(subscript:)];
	}
	else if([itemIdent isEqual: kSuperscriptToolbarItem]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"superscript label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"superscript label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"superscript tip", @"Toolbar", @"")];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemSuperscript.tif"]];
		
		[toolbarItem setTarget:nil];
		[toolbarItem setAction: @selector(superscript:)];
	}
	else if([itemIdent isEqual: kBlockQuoteToolbarItem]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"blockquote label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"blockquote label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"blockquote tip", @"Toolbar", @"")];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemBlockQuote.png"]];
		
		[toolbarItem setTarget:nil];
		[toolbarItem setAction:@selector(makeBlockQuote:)];
	}
	
	else if([itemIdent isEqual: kHighlightToolbarItem]) 
	{
		[toolbarItem release];
		toolbarItem = [[PDSelfValidatingToolbarItem alloc] initWithItemIdentifier:itemIdent];
	
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"highlight label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"highlight label", @"Toolbar", @"")];

		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"highlight tip", @"Toolbar", @"")];
		[toolbarItem setView:highlightButton];
		
		[toolbarItem setMinSize:NSMakeSize(NSWidth([highlightButton frame]), NSHeight([highlightButton frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([highlightButton frame]), NSHeight([highlightButton frame]))];
		
		[toolbarItem setTarget:nil];
		[toolbarItem setAction: @selector(highlightSelection:)];
	}
	else if([itemIdent isEqual: kInsertDateTimeToolbarItem]) 
	{
		[toolbarItem release];
		toolbarItem = [[PDSelfValidatingToolbarItem alloc] initWithItemIdentifier:itemIdent];
	
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"insert datetime label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"insert datetime label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"insert datetime tip", @"Toolbar", @"")];
		[toolbarItem setView:dateTimeButton];
		
		[toolbarItem setMinSize:NSMakeSize(NSWidth([dateTimeButton frame]), NSHeight([dateTimeButton frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([dateTimeButton frame]), NSHeight([dateTimeButton frame]))];
		
		[toolbarItem setTarget:nil];
		[toolbarItem setAction: @selector(insertDateTime:)];
	}

	
	else if([itemIdent isEqual: kInsertCheckoxToolbarItem]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"insert checkbox label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"insert checkbox label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"insert checkbox tip", @"Toolbar", @"")];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemInsertCheckbox.tif"]];
		
		[toolbarItem setTarget:nil];
		[toolbarItem setAction: @selector(insertCheckbox:)];
	}
	else if([itemIdent isEqual: kInsertTableToolbarItem]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"insert table label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"insert table label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"insert table tip", @"Toolbar", @"")];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemInsertTable.tif"]];
		
		[toolbarItem setTarget:nil];
		[toolbarItem setAction: @selector(orderFrontTablePanel:)];
	}
	else if([itemIdent isEqual: kInsertListToolbarItem]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"insert list label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"insert list label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"insert list tip", @"Toolbar", @"")];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemInsertList.tif"]];
		
		[toolbarItem setTarget:nil];
		[toolbarItem setAction: @selector(orderFrontListPanel:)];
	}
	else if([itemIdent isEqual: kInsertLinkToolbarItem]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"insert link label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"insert link label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"insert link tip", @"Toolbar", @"")];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemInsertLink.tif"]];
		
		[toolbarItem setTarget:nil];
		[toolbarItem setAction: @selector(insertLink:)];
	}
	else if ([itemIdent isEqual:kLexiconToolbarItem]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"lexicon label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"lexicon label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"lexicon tip", @"Toolbar", @"")];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemLexicon.png"]];
		
		[toolbarItem setTarget: nil];
		[toolbarItem setAction: @selector(showTermIndex:)];
	}
	
	else if ([itemIdent isEqual:kLockoutToolbarItem]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"lockout label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"lockout label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"lockout tip", @"Toolbar", @"")];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarLockout.tif"]];
		
		[toolbarItem setTarget: nil];
		[toolbarItem setAction: @selector(lockJournal:)];
	}
	
	else 
	{
		[toolbarItem release];
		toolbarItem = nil;
	}
	
	return [toolbarItem autorelease];
}

#pragma mark -

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar 
{
	return [NSArray arrayWithObjects:
			kNavToolbarItem, NSToolbarSeparatorItemIdentifier, kNewEntryToolbarItem, kDeleteToolbarItem, NSToolbarSeparatorItemIdentifier, 
			NSToolbarShowColorsItemIdentifier, NSToolbarShowFontsItemIdentifier, NSToolbarSeparatorItemIdentifier,
			kRecordAudioToolbarItem, kRecordVideoToolbarItem, kRecordSnapshotToolarItem, NSToolbarFlexibleSpaceItemIdentifier, 
			kIMediaToolbarItem, kSearchToolbarItem, kFilterToolarIdentifier, NSToolbarSeparatorItemIdentifier, kLexiconToolbarItem, nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar 
{
	return [NSArray arrayWithObjects:
			kNavToolbarItem, kNewEntryToolbarItem, kDeleteToolbarItem,
			kNewFolderToolbarItem, kNewSmartFolderToolbarItem, kNewTabToolbarItem, 
			NSToolbarShowColorsItemIdentifier, NSToolbarShowFontsItemIdentifier, kRulerToolbarItem, 
			kSubscriptToolbarItem, kSuperscriptToolbarItem, kHighlightToolbarItem, kBlockQuoteToolbarItem, 
			kInsertDateTimeToolbarItem, kInsertCheckoxToolbarItem, kInsertTableToolbarItem, kInsertLinkToolbarItem, kInsertListToolbarItem,
			kExportToolbarItem, NSToolbarPrintItemIdentifier, kEmailToolbarItem, kiWebToolbarItem, kiPodToolbarItem, kBlogToolbarItem,
			kRecordAudioToolbarItem, kRecordVideoToolbarItem, kRecordSnapshotToolarItem,
			kEntryInfoToolbarItem, kFlagEntryToolbarItem, kHeaderToolbarItem,
			kIMediaToolbarItem, /*kCorrespondenceToolbarItem,*/ kAddressBookToolarItem,
			kSearchToolbarItem, kFilterToolarIdentifier, kLexiconToolbarItem, kLockoutToolbarItem,
			NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, 
			NSToolbarSeparatorItemIdentifier, NSToolbarCustomizeToolbarItemIdentifier, nil];
}


#pragma mark -

- (void) toolbarWillAddItem: (NSNotification *) aNotification 
{
    NSToolbarItem *addedItem = [[aNotification userInfo] objectForKey: @"item"];
    
	if ( [[addedItem itemIdentifier] isEqual: NSToolbarPrintItemIdentifier] ) 
	{
		[addedItem setToolTip: NSLocalizedStringFromTable(@"print tip", @"Toolbar", @"")];
		[addedItem setTarget: self];
		[addedItem setAction:@selector(printDocument:)];
    }
}

- (void) toolbarDidRemoveItem: (NSNotification *) aNotification 
{

}

- (void) toolbarDidChangeSizeMode:(PDToolbar*)aToolbar
{
	int sizeTeil = ( [aToolbar sizeMode] == NSToolbarSizeModeSmall ? 24 : 32 );
	[dateTimeButton setIconSize:NSMakeSize(sizeTeil,sizeTeil)];
	[highlightButton setIconSize:NSMakeSize(sizeTeil,sizeTeil)];
}

- (void) toolbarDidChangeDisplayMode:(PDToolbar*)aToolbar
{
	return;
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem 
{	
	BOOL enabled = YES;
	NSString *identifier = [toolbarItem itemIdentifier];
	
	if ( [identifier isEqualToString:kSearchToolbarItem] ) 
	{
		if ( ![[tabControllers objectAtIndex:[self selectedTabIndex]] respondsToSelector:@selector(performToolbarSearch:)] )
			enabled = NO;
	}
	else if ( [[toolbarItem itemIdentifier] isEqual:kFilterToolarIdentifier] ) 
	{
		if ( ![[self selectedTab] respondsToSelector:@selector(filterEntries:)] )
			enabled = NO;
		else
		{
			[toolbarItem setImage:[NSImage imageNamed:
					( [[self selectedTab] isFiltering] ? @"ToolbarItemFilterActive.tif" : @"ToolbarItemFilter.tif" ) ]];
		}
	}
	
	return enabled;
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	if ( [anItem action] == @selector(insertDateTime:) )
		return [[[self window] firstResponder] respondsToSelector:@selector(insertDateTime:)];
		
	return YES;
}

@end
