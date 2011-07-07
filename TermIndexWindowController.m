//
//  TermIndexWindowController.m
//  Journler
//
//  Created by Philip Dow on 1/31/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import "TermIndexWindowController.h"
#import "TermIndexTab.h"
#import "EntryTabController.h"
#import "FullScreenController.h"

#import "IndexLetterView.h"

#import "JournlerJournal.h"
#import "JournlerSearchManager.h"

#import "JournlerIndexServer.h"

@implementation TermIndexWindowController

- (id) initWithJournal:(JournlerJournal*)aJournal
{
	if ( self = [super initWithWindowNibName:@"TermIndexWindow"] ) 
	{
		[self setShouldCascadeWindows:NO];
		[self setWindowFrameAutosaveName:@"TermIndexWindow"];
		[self setJournal:aJournal];
		
		indexServer = [[aJournal indexServer] retain];
		
		[self retain];
	}
	
	return self;
}

- (void) dealloc
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	[indexServer release];
	[super dealloc];
}

- (void) windowDidLoad 
{	
	[super windowDidLoad];
	
	[[self window] setMinSize:NSMakeSize(400,150)];
	[[self window] setFrameUsingName:@"TermIndexWindow"];
	
	if ( [[self window] respondsToSelector:@selector(contentBorderThicknessForEdge:)] )
		[[self window] setContentBorderThickness:28.0 forEdge:NSMinYEdge];
	else
		[[self window] setBackgroundColor:[NSColor colorWithCalibratedWhite:0.92 alpha:1.0]];
	
	activeTabView = initalTabPlaceholder;
	
	// compact and flush the index
	//[[[self journal] searchManager] compactIndex];
	[[[self journal] searchManager] writeIndexToDisk];
	
	// initiate the single tab
	TermIndexTab *tab = [[[[self defaultTabClass] alloc] initWithOwner:self] autorelease];
	
	// move the tab into place
	[[tab tabContent] setFrame:[activeTabView frame]];
	[[activeTabView superview] replaceSubview:activeTabView with:[tab tabContent]];
	activeTabView = [tab tabContent];
	
	// make the tab view and bookmarks view visible if requested by the user
	//[self setBookmarksHidden:![[NSUserDefaults standardUserDefaults] boolForKey:@"MainWindowBookmarksVisible"]];
	//[self setTabsHidden:![[NSUserDefaults standardUserDefaults] boolForKey:@"MainWindowTabsAlwaysVisible"]];
	
	// the custom field editor
	//[browseTableFieldEditor retain];
	//[browseTableFieldEditor setFieldEditor:YES];
	
	// set up the toolbar
	[self setupToolbar];
	
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
	return [TermIndexTab class];
}

- (NSArray*) observedPathsForTab:(TabController*)aTab
{
	NSArray *observedPaths = [NSArray arrayWithObjects:@"selectedDate", @"selectedFolders",
	@"selectedEntries", @"selectedResources", nil];
	return observedPaths;
}

#pragma mark -

- (void)windowWillClose:(NSNotification *)aNotification 
{
	if ( [self window] == [aNotification object] )
	{
		#ifdef __DEBUG__
		NSLog(@"%s",__PRETTY_FUNCTION__);
		#endif
		
		// stop observing the tab
		[self stopObservingTab:[self selectedTab] paths:[self observedPathsForTab:[self selectedTab]]];

		[super windowWillClose:aNotification];
		[indexServer releaseTermAndDocumentDictionaries];
		[self autorelease];
	}
}

- (BOOL)windowShouldClose:(id)sender
{
	return YES;
}

- (IBAction) closeTab:(id)sender
{
	
	// pass the message to the tabs view which kindly handles it
	if ( [[self tabControllers] count] == 1 )
		[[self window] performClose:sender];
	else
		[super closeTab:sender];
}

- (IBAction) newWebBrower:(id)sender
{
	TabController *aTab = [[[EntryTabController alloc] initWithOwner:self] autorelease];
	TabController *currentTab = [self selectedTab];
	
	[self addTab:aTab atIndex:[self selectedTabIndex]];
	
	[[aTab tabContent] setFrame:[activeTabView frame]];
	[aTab restoreLocalStateWithDictionary:[currentTab localStateDictionary]];
	[aTab selectDate:nil folders:nil entries:nil resources:nil];
	
	[self selectTabAtIndex:[self selectedTabIndex] force:YES];
	[aTab newWebBrower:sender];

}

- (IBAction) toggleFullScreen:(id)sender
{
	// subclasses may override to customize behavior
	
	// put the fullscreen controller up
	JournlerWindowController *fullScreenController = [[[FullScreenController alloc] initWithJournal:[self journal] callingController:self] autorelease];
	[FullScreenController enableFullscreenMode];
	
	// stop observing the tab
	[self stopObservingTab:[self selectedTab] paths:[self observedPathsForTab:[self selectedTab]]];
	
	NSView *completeContent = [[[self window] contentView] retain];
	PDTabsView *theTabsBar = [tabsBar retain];
	PDFavoritesBar *theFavoritesBar = [favoritesBar retain];
	
	[[self window] setContentView:[[[NSView alloc] initWithFrame:NSMakeRect(0,0,100,100)] autorelease]];
	[tabsBar release]; tabsBar = nil;
	[favoritesBar release]; favoritesBar = nil;
	
	[fullScreenController setTabControllers:[self tabControllers]];
	[[fullScreenController window] setContentView:completeContent];
	
	fullScreenController->activeTabView = activeTabView;
	fullScreenController->favoritesBar = theFavoritesBar;
	fullScreenController->tabsBar = theTabsBar;
	fullScreenController->bookmarksHidden = bookmarksHidden;
	fullScreenController->tabsHidden = tabsHidden;
	
	if ( [fullScreenController respondsToSelector:@selector(setIndexServer:)] )
		[fullScreenController performSelector:@selector(setIndexServer:) withObject:[self indexServer]];
	
	[theTabsBar setDelegate:fullScreenController];
	[theTabsBar setDataSource:fullScreenController];
	[theFavoritesBar setTarget:fullScreenController];
	[theFavoritesBar setDelegate:fullScreenController];
	
	[fullScreenController selectTabAtIndex:[self selectedTabIndex] force:YES];
	
	[fullScreenController showWindow:self];
	[[self window] orderOut:self];
	
}


/*
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context 
{
	if ( object == [tabControllers objectAtIndex:[self selectedTabIndex]] )
	{
		[tabsBar setNeedsDisplay:YES];
		[self updateNavInterface];	
		
		// update the window title
		[[self window] setTitle:[self windowTitle]];
	}
}
*/

#pragma mark -

- (JournlerIndexServer*) indexServer
{
	return indexServer;
}

- (void) setIndexServer:(JournlerIndexServer*)aServer
{
	if ( indexServer != aServer )
	{
		[indexServer release];
		indexServer = [aServer retain];
	}
}

#pragma mark -

- (IBAction) gotoLetter:(id)sender
{
	// note that the sender is actually a string with the specified letter
	if ( [[self selectedTab] respondsToSelector:@selector(gotoLetter:)] )
		[[self selectedTab] performSelector:@selector(gotoLetter:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) editSynonyms:(id)sender
{
	NSBeep(); return;
}

- (IBAction) showLexiconHelp:(id)sender
{
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"TheLexicon" inBook:@"JournlerHelp"];
}

#pragma mark -
#pragma mark Stop Words

- (IBAction) editStopWords:(id)sender
{
	NSString *spaceSeparatedStopWords = [[[[[[self indexServer] searchManager] stopWords] allObjects] 
	sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] componentsJoinedByString:@" "];
	if ( spaceSeparatedStopWords != nil ) [stopwordsTextView setString:spaceSeparatedStopWords];
	
	// put the sheet on the screen
	[NSApp beginSheet: stopwordsWindow
			modalForWindow: [self window]
			modalDelegate: self
			didEndSelector: @selector(stopwordsSheet:returnCode:contextInfo:)
			contextInfo: nil];
}

- (void) stopwordsSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
	if ( returnCode == NSRunStoppedResponse )
	{
		NSString *theStopwords = [[stopwordsTextView string] lowercaseString];
		[[NSUserDefaults standardUserDefaults] setObject:theStopwords forKey:@"SearchStopWords"];
		
		NSArray *theStopwordsArray = [theStopwords componentsSeparatedByString:@" "];
		if ( theStopwordsArray == nil )
		{
			NSLog(@"%s - unable to derive stopwords array from string %@", __PRETTY_FUNCTION__, theStopwords);
			return;
		}
		
		NSSet *theStopwordsSet = [NSSet setWithArray:theStopwordsArray];
		if ( theStopwordsSet == nil )
		{
			NSLog(@"%s - unable to derive stopwords set from array %@", __PRETTY_FUNCTION__, theStopwordsArray);
			return;
		}
		
		[[[self indexServer] searchManager] setStopWords:theStopwordsSet];
	}
	
	[stopwordsWindow orderOut:self];
}


- (IBAction) saveStopwordsChanges:(id)sender
{
	[NSApp endSheet:stopwordsWindow returnCode:NSRunStoppedResponse];
}

- (IBAction) cancelStopwordsChanges:(id)sender
{
	[NSApp endSheet:stopwordsWindow returnCode:NSRunAbortedResponse];
}

#pragma mark -
#pragma mark Menu Validation

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	BOOL enabled;
	int itemTag = [menuItem tag];
	SEL action = [menuItem action];
	
	if ( action == @selector(closeTab:) )
		enabled = YES;
		
	else if ( action == @selector(changeSearchOption:) )
	{
		enabled = YES;
		[menuItem setState:( [[NSUserDefaults standardUserDefaults] integerForKey:@"LexiconFilterCondition"] == itemTag ? NSOnState : NSOffState )];
	}
	
	else 
		enabled = [super validateMenuItem:menuItem];
	
	return enabled;
}

@end

#pragma mark -

@implementation TermIndexWindowController (Toolbars)

static NSString	*kTermIndexWindowToolbar		= @"kTermIndexWindowToolbar";

//static NSString *kNavToolbarItem				= @"kNavToolbarItem";
static NSString *kLettersToolbarItem			= @"kLettersToolbarItem";
static NSString *kSynonymsToolbarItem			= @"kSynonymsToolbarItem";
static NSString *kStopListToolbarItems			= @"kStopListToolbarItems";

- (void) setupToolbar 
{
	[navOutlet retain];
	[navOutlet removeFromSuperview];
	
	[letterView retain];
	[letterView removeFromSuperview];
	
	[letterView setTarget:self];
	[letterView setAction:@selector(gotoLetter:)];
	
	[[navBack cell] setImageDimsWhenDisabled:NO];
	[[navForward cell] setImageDimsWhenDisabled:NO];
	
	//building and displaying the toolbar
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier: kTermIndexWindowToolbar];
	
    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
	[toolbar setAllowsUserCustomization:NO];
	[toolbar setAutosavesConfiguration:NO];
    [toolbar setDelegate: self];
	
    [[self window] setToolbar: toolbar];
	
	//clean up
	[toolbar release];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar 
		itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted 
{	
	NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
	
	/*
	if ( [itemIdent isEqual:kNavToolbarItem] )
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"nav label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"nav label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"nav tip", @"Toolbar", @"")];
		
		[toolbarItem setView: navOutlet];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([navOutlet frame]), NSHeight([navOutlet frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([navOutlet frame]),NSHeight([navOutlet frame]))];
	}
		
	else */ if ( [itemIdent isEqual:kSynonymsToolbarItem]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"synonyms label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"synonyms label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"synonyms tip", @"Toolbar", @"")];
		[toolbarItem setImage:[NSImage imageNamed:@"ToolbarItemSynonyms.tif"]];
		
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(editSynonyms:)];
	}
	
	else if ( [itemIdent isEqual:kStopListToolbarItems]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"stoplist label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"stoplist label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"stoplist tip", @"Toolbar", @"")];
		[toolbarItem setImage:[NSImage imageNamed:@"ToolbarItemStopWords.tif"]];
		
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(editStopWords:)];
	}
	
	else if ( [itemIdent isEqual:kLettersToolbarItem]) 
	{
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"letters label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"letters label", @"Toolbar", @"")];
		
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"letters tip", @"Toolbar", @"")];
		
		[toolbarItem setView: letterView];
		[toolbarItem setMinSize:NSMakeSize(265, NSHeight([letterView frame]))];
		[toolbarItem setMaxSize:NSMakeSize(10000, NSHeight([letterView frame]))];
	}
	
	return [toolbarItem autorelease];
}

#pragma mark -

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar 
{
	return [NSArray arrayWithObjects:/*kSynonymsToolbarItem,*/
	kStopListToolbarItems, NSToolbarSeparatorItemIdentifier, kLettersToolbarItem, nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar 
{
	return [NSArray arrayWithObjects:/*kSynonymsToolbarItem,*/ 
	kStopListToolbarItems, kLettersToolbarItem, NSToolbarSeparatorItemIdentifier, nil];
}

#pragma mark -

- (void) toolbarWillAddItem: (NSNotification *) aNotification 
{
	return;
}

- (void) toolbarDidRemoveItem: (NSNotification *) aNotification 
{
	return;
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem 
{	
	BOOL enabled = YES;
	//NSString *identifier = [toolbarItem itemIdentifier];
	
	return enabled;
}

@end
