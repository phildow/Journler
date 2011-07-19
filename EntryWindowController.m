#import "EntryWindowController.h"
#import "Definitions.h"

#import "JournlerApplicationDelegate.h"

#import "JournlerEntry.h"
#import "JournlerCollection.h"
#import "JournlerJournal.h"


#import "EntryTabController.h"
#import "FullScreenWindow.h"
#import "LinksOnlyNSTextView.h"
#import "BrowseTableFieldEditor.h"
#import "NewEntryController.h"

#import "NSAlert+JournlerAdditions.h"
#import "NSAttributedString+JournlerAdditions.h"

#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>

@implementation EntryWindowController

- (id) init 
{
	static NSString *kNibName = @"EntryWindow";
	NSString *kNibName105 = [NSString stringWithFormat:@"%@_105",kNibName];
	NSString *theNib = nil;
	
	if ( [[NSBundle mainBundle] respondsToSelector:@selector(executableArchitectures)] 
			&& [[NSBundle mainBundle] pathForResource:kNibName105 ofType:@"nib"] != nil )
		theNib = kNibName105;
	else
		theNib = kNibName;

	if ( self = [super initWithWindowNibName:theNib] ) 
	{
		[self setWindowFrameAutosaveName:@"EntryWindow"];
		[self retain];
	}
	
	return self;
}

- (id) initWithJournal:(JournlerJournal*)aJournal
{
	static NSString *kNibName = @"EntryWindow";
	NSString *kNibName105 = [NSString stringWithFormat:@"%@_105",kNibName];
	NSString *theNib = nil;
	
	if ( [[NSBundle mainBundle] respondsToSelector:@selector(executableArchitectures)] 
			&& [[NSBundle mainBundle] pathForResource:kNibName105 ofType:@"nib"] != nil )
		theNib = kNibName105;
	else
		theNib = kNibName;
		
	if ( self = [super initWithWindowNibName:theNib] ) 
	{
		[self setWindowFrameAutosaveName:@"EntryWindow"];
		[self setJournal:aJournal];
		[self retain];
	}
	
	return self;
}

- (void) dealloc 
{	
	[browseTableFieldEditor release], browseTableFieldEditor = nil;
	[highlightButton release], highlightButton = nil;
	[dateTimeButton release], dateTimeButton = nil;
	
	[super dealloc];
}

- (void) windowDidLoad 
{	
	[super windowDidLoad];
	if ( [[self window] respondsToSelector:@selector(contentBorderThicknessForEdge:)] )
		[[self window] setContentBorderThickness:29.0 forEdge:NSMinYEdge];
	
	activeTabView = initalTabPlaceholder;
	
	// initiate the single tab
	EntryTabController *tab = [[[[self defaultTabClass] alloc] initWithOwner:self] autorelease];
	
	// move the tab into place
	[[tab tabContent] setFrame:[activeTabView frame]];
	[[activeTabView superview] replaceSubview:activeTabView with:[tab tabContent]];
	activeTabView = [tab tabContent];
	
	// restore the state
	NSDictionary *tabState = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"EntryWindowStateDictionary"];
	if ( tabState != nil ) [tab restoreLocalStateWithDictionary:tabState];
	
	[self setBookmarksHidden:![[NSUserDefaults standardUserDefaults] boolForKey:@"EntryWindowBookmarksVisible"]];
	
	// make the tab view and bookmarks view visible if requested by the user
	//[self setBookmarksHidden:![[NSUserDefaults standardUserDefaults] boolForKey:@"MainWindowBookmarksVisible"]];
	//[self setTabsHidden:![[NSUserDefaults standardUserDefaults] boolForKey:@"MainWindowTabsAlwaysVisible"]];
	
	// the custom field editor
	[browseTableFieldEditor retain];
	[browseTableFieldEditor setFieldEditor:YES];
	
	// set up the toolbar
	[self setupToolbar];
	
	// adjust content height if toolbar is hidden
	if ( ![[[self window] toolbar] isVisible] )
		[self toolbarDidHide:(PDToolbar*)[[self window] toolbar]];
	
	// take note of selection changes so that navigation may be updated
	[self startObservingTab:tab paths:[self observedPathsForTab:tab]];
	
	// add the tab to the array and select it
	[self addTab:tab atIndex:-1];
	[self setSelectedTabIndex:0];
}

#pragma mark -

- (Class) defaultTabClass
{
	// subclasses must override to return the class of default tab for that window
	return [EntryTabController class];
}

- (NSArray*) observedPathsForTab:(TabController*)aTab
{
	NSArray *observedPaths = [NSArray arrayWithObjects:@"selectedEntries", @"selectedResources", nil];
	return observedPaths;
}

- (NSString*) windowTitle
{
	// subclasses should override to provide appropriate title
	return [self valueForKeyPath:@"selectedTab.title"];
}

#pragma mark -

- (void)windowWillClose:(NSNotification *)aNotification 
{
#ifdef __DEBUG__
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
	
	[super windowWillClose:aNotification];
	
	NSDictionary *tabState = [[self selectedTab] localStateDictionary];
	if ( tabState != nil ) [[NSUserDefaults standardUserDefaults] setObject:tabState forKey:@"EntryWindowStateDictionary"];
	
	// stop observing the tab
	// #warning don't remove when the observer isn't actually registered! - check other window controllers
	[self stopObservingTab:[self selectedTab] paths:[self observedPathsForTab:[self selectedTab]]];
	
	[self autorelease];
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
	else
	{
		return nil;
	}
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

- (IBAction) closeTab:(id)sender
{
	// pass the message to the tabs view which kindly handles it
	if ( [[self tabControllers] count] == 1 )
		[[self window] performClose:sender];
	else
		[super closeTab:sender];
}

#pragma mark -

- (IBAction) toggleRuler:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(toggleRuler:)] )
		[[self selectedTab] performSelector:@selector(toggleRuler:) withObject:sender];
	else
	{
		NSBeep();
	}
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

- (void) setBookmarksHidden:(BOOL)hidden
{
	[super setBookmarksHidden:hidden];
	[[NSUserDefaults standardUserDefaults] setBool:!hidden forKey:@"EntryWindowBookmarksVisible"];
}

#pragma mark -
#pragma mark Creating New Entries
// overriding these at the window level because they are meaningless at the tab level

- (IBAction) newEntry:(id)sender
{
	JournlerEntry *newEntry;
	NSArray *targetFolders = nil;
	
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"QuickEntryCreation"] )
	{
		// quickly create a new entry if the user wishes it
		newEntry = [[self selectedTab] newDefaultEntryWithSelectedDate:[NSCalendarDate calendarDate] overridePreference:YES];
		targetFolders = nil;
	}
	else
	{
		NSInteger result;
		NewEntryController *entryCreator = [[[NewEntryController alloc] initWithJournal:[self valueForKey:@"journal"]] autorelease];
		
		// the date depends on the preference -- no, takes today's date.
		[entryCreator setValue:[NSCalendarDate calendarDate] forKey:@"date"];
				
		// is there a selected folder?
		[entryCreator setSelectedFolders:nil];
		
		// tag completions
		[entryCreator setTagCompletions:[[[self journal] entryTags] allObjects]];
				
		// run the entry builder
		result = [entryCreator runAsSheetForWindow:[self window] attached:[[self window] isMainWindow]];
		
		if ( result != NSRunStoppedResponse )
			return;
		
		// prepare the new entry
		newEntry = [[[JournlerEntry alloc] init] autorelease];
		[newEntry setJournal:[self journal]];
		
		[newEntry setValue:[NSNumber numberWithInteger:[[self journal] newEntryTag]] forKey:@"tagID"];
		[newEntry setValue:[NSCalendarDate calendarDate] forKey:@"calDateModified"];
		[newEntry setValue:[entryCreator valueForKey:@"category"] forKey:@"category"];
		[newEntry setValue:[entryCreator valueForKey:@"tags"] forKey:@"tags"];
		[newEntry setValue:[[entryCreator valueForKey:@"date"] dateWithCalendarFormat:nil timeZone:nil] forKey:@"calDate"];
		[newEntry setValue:[entryCreator valueForKey:@"labelValue"] forKey:@"label"];
		[newEntry setValue:[entryCreator valueForKey:@"marking"] forKey:@"marked"];
		
		// date due
		if ( [entryCreator includeDateDue] )
			[newEntry setValue:[[entryCreator valueForKey:@"dateDue"] dateWithCalendarFormat:nil timeZone:nil] forKey:@"calDateDue"];
		
		// ensure a title
		NSString *title = [entryCreator valueForKey:@"title"];
		if ( title == nil || [title length] == 0 )
		{
			NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
			[formatter setDateStyle:NSDateFormatterLongStyle];
			[formatter setTimeStyle:NSDateFormatterNoStyle];
			
			NSString *dateString = [formatter stringFromDate:[entryCreator valueForKey:@"date"]];
			title = [NSString stringWithFormat:NSLocalizedString(@"dated untitled title", @""), dateString];
		}
		
		// default attributed content
		NSAttributedString *attributedContent = [[[NSAttributedString alloc] 
		initWithString:[NSString string] attributes:[JournlerEntry defaultTextAttributes]] autorelease];
		
		[newEntry setValue:title forKey:@"title"];
		[newEntry setValue:attributedContent forKey:@"attributedContent"];
		
		// add the entry to the journal and save it
		[[self journal] addEntry:newEntry];
		[[self journal] saveEntry:newEntry];
		
		// add the entry to the folder selected in the entry creator
		targetFolders = [entryCreator selectedFolders];
	}
	
	
	// add the entry to the selected folder(s)
    for ( JournlerCollection *aFolder in targetFolders )
	{
		if ( [aFolder isRegularFolder] )
			[aFolder addEntry:newEntry];
		else if ( [aFolder isSmartFolder] && [aFolder canAutotag:newEntry] )
			[aFolder autotagEntry:newEntry add:YES];
	}
	
	// save the entry once more now that it's been autotagged
	[[self journal] saveEntry:newEntry];
	
	// always put the new entry in a new window
	EntryWindowController *entryWindow = [[[EntryWindowController alloc] initWithJournal:[self journal]] autorelease];
	[entryWindow showWindow:self];
	
	// select the resource in the window
	[[entryWindow selectedTab] selectDate:nil folders:nil entries:[NSArray arrayWithObject:newEntry] resources:nil];
	[[entryWindow selectedTab] appropriateFirstResponderForNewEntry:[entryWindow window]];
	
}

- (IBAction) newEntryWithClipboardContents:(id)sender
{
	NSArray *pasteboardEntries = [[NSApp delegate] entriesForPasteboardData:[NSPasteboard generalPasteboard] visual:NO preferredTypes:nil];
	if ( pasteboardEntries == nil )
	{
		NSBeep();
		[[NSAlert pasteboardImportFailure] runModal];
	}
	else
	{
		// always put up a new window
        for ( JournlerEntry *anEntry in pasteboardEntries )
		{
		
			// put up an entry window for this resource
			EntryWindowController *entryWindow = [[[EntryWindowController alloc] initWithJournal:[self journal]] autorelease];
			[entryWindow showWindow:self];
			
			// select the resource in the window
			[[entryWindow selectedTab] selectDate:nil folders:nil entries:[NSArray arrayWithObject:anEntry] resources:nil];
			[[entryWindow selectedTab] appropriateFirstResponder:[entryWindow window]];
		
		}
	}
}


/*
- (IBAction) toggleResources:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(toggleResources:)] )
		[[self selectedTab] performSelector:@selector(toggleResources:) withObject:sender];
	else
	{
		NSBeep();
	}
}
*/

#pragma mark -

/*
- (void) modifyEntryViaPlugin:(JournlerPlugin*)plugin {
	
	//
	// called by the plugin manager
	// - load the plugin and pass the current entry to it
	// - take care to account for modifications to the entry's content
	//
	
	NSString		*feedback;
	JournlerEntry	*originalEntry;
	JournlerEntry	*modifiedEntry;
	
	if ( ![_entryCell entry] ) {
		NSBeep();
		return;
	}
	
	originalEntry = [_entryCell entry];
	modifiedEntry = (JournlerEntry*)[plugin handleEntry:[[originalEntry copyWithZone:[self zone]] autorelease] 
			notification:&feedback];
	
	// preserve the encrypted and tag variables
	NSNumber *encrypted = [originalEntry valueForKey:@"encrypted"];
	NSNumber *tagID = [originalEntry valueForKey:@"tagID"];
	
	// move over all the properties
	[originalEntry setProperties:[modifiedEntry properties]];
	
	// keep those that must be preserved
	[originalEntry setValue:encrypted forKey:@"encrypted"];
	[originalEntry setValue:tagID forKey:@"tagID"];
	
	[[self journal] saveEntry:originalEntry];
	
	if ( feedback ) [self updateNotification:feedback];
	
}
*/

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	BOOL enabled;
	SEL action = [menuItem action];
	
	if ( action == @selector(closeTab:) )
		enabled = YES;
	
	else if ( action == @selector(newEntry:) )
		enabled = YES;
		
	else if ( action == @selector(newEntryWithClipboardContents:) )
		enabled = YES;
	
	else 
		enabled = [super validateMenuItem:menuItem];
	
	return enabled;
}

@end

#pragma mark -

@implementation EntryWindowController (Toolbars)

static NSString	*kEntryWindowToolbar			= @"kEntryWindowToolbar";

static NSString *kIMediaToolbarItem				= @"kIMediaToolbarItem";
static NSString *kNavToolbarItem				= @"kNavToolbarItem";
static NSString *kAddressBookToolarItem			= @"kAddressBookToolarItem";
//static NSString *kCorrespondenceToolbarItem		= @"kCorrespondenceToolbarItem";

static NSString	*kNewTabToolbarItem				= @"kNewTabToolbarItem";

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

static NSString *kLexiconToolbarItem = @"kLexiconToolbarItem";

- (void) setupToolbar 
{
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
    PDToolbar *toolbar = [[PDToolbar alloc] initWithIdentifier: kEntryWindowToolbar];
	
    [toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration:YES];
    [toolbar setDelegate: self];
	
    [[self window] setToolbar: toolbar];
	
	//clean up
	[toolbar release];
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
	[pulldownItem setImage:[NSImage imageNamed:@"ToolbarItemHighlight.tif"]];
	
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
		willBeInsertedIntoToolbar:(BOOL)willBeInserted 
{	
	NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
	
	if ( [itemIdent isEqual:kNavToolbarItem] )
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
	
	else if([itemIdent isEqual: kInsertCheckoxToolbarItem]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"insert checkbox label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"insert checkbox label", @"Toolbar", @"")];
		
		//[toolbarItem setTag:351];
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"insert checkbox tip", @"Toolbar", @"")];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemInsertCheckbox.tif"]];
		
		[toolbarItem setTarget:nil];
		[toolbarItem setAction: @selector(insertCheckbox:)];
	}
	else if([itemIdent isEqual: kInsertTableToolbarItem]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"insert table label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"insert table label", @"Toolbar", @"")];
		
		//[toolbarItem setTag:351];
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"insert table tip", @"Toolbar", @"")];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemInsertTable.tif"]];
		
		[toolbarItem setTarget:nil];
		[toolbarItem setAction: @selector(orderFrontTablePanel:)];
	}
	else if([itemIdent isEqual: kInsertListToolbarItem]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"insert list label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"insert list label", @"Toolbar", @"")];
		
		//[toolbarItem setTag:351];
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"insert list tip", @"Toolbar", @"")];
		[toolbarItem setImage: [NSImage imageByReferencingImageNamed: @"ToolbarItemInsertList.tif"]];
		
		[toolbarItem setTarget:nil];
		[toolbarItem setAction: @selector(orderFrontListPanel:)];
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
	else if([itemIdent isEqual: kInsertLinkToolbarItem]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"insert link label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"insert link label", @"Toolbar", @"")];
		
		//[toolbarItem setTag:351];
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
			kNavToolbarItem, NSToolbarSeparatorItemIdentifier, 
			NSToolbarShowColorsItemIdentifier, NSToolbarShowFontsItemIdentifier, NSToolbarSeparatorItemIdentifier,
			kRecordAudioToolbarItem, kRecordVideoToolbarItem, kRecordSnapshotToolarItem, NSToolbarFlexibleSpaceItemIdentifier, 
			kIMediaToolbarItem, nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar 
{
	return [NSArray arrayWithObjects:
			kNavToolbarItem,kNewTabToolbarItem, 
			NSToolbarShowColorsItemIdentifier, NSToolbarShowFontsItemIdentifier, kRulerToolbarItem, 
			kSubscriptToolbarItem, kSuperscriptToolbarItem, kHighlightToolbarItem, kBlockQuoteToolbarItem,
			kInsertDateTimeToolbarItem, kInsertCheckoxToolbarItem, kInsertTableToolbarItem, kInsertLinkToolbarItem, kInsertListToolbarItem,	
			kExportToolbarItem, NSToolbarPrintItemIdentifier, kEmailToolbarItem, kiWebToolbarItem, kiPodToolbarItem, kBlogToolbarItem,
			kRecordAudioToolbarItem, kRecordVideoToolbarItem, kRecordSnapshotToolarItem,
			kEntryInfoToolbarItem, kFlagEntryToolbarItem, kHeaderToolbarItem,
			kIMediaToolbarItem, /*kCorrespondenceToolbarItem,*/ kAddressBookToolarItem, kLexiconToolbarItem,
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

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem 
{	
	BOOL enabled = YES;
	//NSString *identifier = [toolbarItem itemIdentifier];
	
	return enabled;
}

- (void) toolbarDidChangeSizeMode:(PDToolbar*)aToolbar
{
	NSInteger sizeTeil = ( [aToolbar sizeMode] == NSToolbarSizeModeSmall ? 24 : 32 );
	[dateTimeButton setIconSize:NSMakeSize(sizeTeil,sizeTeil)];
	[highlightButton setIconSize:NSMakeSize(sizeTeil,sizeTeil)];
}

- (void) toolbarDidChangeDisplayMode:(PDToolbar*)aToolbar
{
	
}

@end

