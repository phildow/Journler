//
//  JournalWindowController.m
//  Journler
//
//  Created by Philip Dow on 10/24/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import "JournlerWindowController.h"
#import "Definitions.h"

#import "JournlerObject.h"
#import "JournlerJournal.h"
#import "JournlerResource.h"
#import "JournlerCollection.h"
#import "JournlerEntry.h"

#import <SproutedUtilities/SproutedUtilities.h>
//#import "NSObject_JSAdditions.h"

#import "TabController.h"
#import "EntryWindowController.h"

#import "FullScreenController.h"

#import "NSAlert+JournlerAdditions.h"

static NSString *kJournlerWindowControllerObserver = @"JournlerWindowControllerObserver";

@implementation JournlerWindowController

- (id)initWithWindow:(NSWindow *)window
{
	if ( self = [super initWithWindow:window] )
	{
		// the tabs bar
		tabsBar = [[PDTabsView alloc] initWithFrame:NSMakeRect(0,0,200,22)];
		[tabsBar setDelegate:self];
		[tabsBar setDataSource:self];
		
		// the favorites bar
		favoritesBar = [[PDFavoritesBar alloc] initWithFrame:NSMakeRect(0,0,200,22)];
		[favoritesBar setTarget:self];
		[favoritesBar setDelegate:self];
		[favoritesBar setAction:@selector(selectFavorite:)];
		
		// set the initial favorites
		NSArray *theFavorites = [[NSUserDefaults standardUserDefaults] arrayForKey:@"PDFavoritesBar"];
		if ( theFavorites == nil ) theFavorites = [NSArray array];
		[favoritesBar setFavorites:theFavorites];
		
		tabControllers = [[NSArray alloc] init];
		selectedTabIndex = -1;
		
		bookmarksHidden = YES;
		tabsHidden = YES;
		
		[[NSNotificationCenter defaultCenter] addObserver:self 
				selector:@selector(performAutosave:) 
				name:PDAutosaveNotification 
				object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self 
				selector:@selector(journlerObjectValueDidChange:) 
				name:JournlerObjectDidChangeValueForKeyNotification 
				object:nil];
		
	}
	return self;
}

- (id) initWithJournal:(JournlerJournal*)aJournal
{
	// ** concrete subclasses must override **
	NSLog(@"%s - ** concrete subclasses must override **", __PRETTY_FUNCTION__);
	return nil;
}

- (void) windowDidLoad
{
	// subclasses should call super's implementation
	
	//register acceptable drag types
	[[self window] registerForDraggedTypes:[NSArray arrayWithObjects:PDEntryIDPboardType, PDFavoritePboardType, nil]];
	
	// rescan the favorites bar
	[favoritesBar rescanLabels];
}

- (void) dealloc 
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	if ( ![self respondsToSelector:@selector(isFullScreenController)] )
	{
		#ifdef __DEBUG__
		NSLog(@"%s - not full screen controller, releasing view components", __PRETTY_FUNCTION__);
		#endif
		
		[tabControllers release];
		[favoritesBar release];
		[tabsBar release];
	}
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PDAutosaveNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:JournlerObjectDidChangeValueForKeyNotification object:nil];
	[[self window] unregisterDraggedTypes];
	
	[super dealloc];
}

#pragma mark -

- (Class) defaultTabClass
{
	// subclasses must override to return the class of default tab for that window
	return NULL;
}

- (NSArray*) observedPathsForTab:(TabController*)aTab
{
	// subclasses must override this method to list the key paths they oberserve on the tab
	// these paths will be observed and unobserved for back/forward purposes automatically as tabs are created and destroyed
	NSLog(@"**** %s - subclasses must override this method ****", __PRETTY_FUNCTION__);
	return nil;
}

- (void) startObservingTab:(TabController*)aTab paths:(NSArray*)keyPaths
{
    for ( NSString *aPath in keyPaths )
		[aTab addObserver:self 
				forKeyPath:aPath 
				options:0 
				context:kJournlerWindowControllerObserver];
}

- (void) stopObservingTab:(TabController*)aTab paths:(NSArray*)keyPaths
{
    for ( NSString *aPath in keyPaths )
		[aTab removeObserver:self forKeyPath:aPath];
}

#pragma mark -

- (JournlerJournal*) journal
{
	return journal;
}

- (void) setJournal:(JournlerJournal*)aJournal
{
	journal = [aJournal retain];
}

- (unsigned int ) selectedTabIndex 
{
	return selectedTabIndex;
}

- (void) setSelectedTabIndex:(unsigned int)theSelection 
{
	selectedTabIndex = theSelection;
}

- (NSArray*) tabControllers 
{
	return tabControllers;
}

- (void) setTabControllers:(NSArray*)anArray 
{
	if ( tabControllers != anArray ) 
	{
		[tabControllers release];
		tabControllers = [anArray retain];
	}
}

#pragma mark -

// the code for determine origins and heights
// for the tab bar, favorites bar and contents
// is much too convoluted.

- (BOOL) tabsHidden 
{
	return tabsHidden;
}

- (void) setTabsHidden:(BOOL)hidden 
{
	// do nothing if the state is already the case
	if ( tabsHidden == hidden )
		return;
		
	tabsHidden = hidden;
	
	// reframe the tab content accordingly
	NSRect tabContentFrame = [activeTabView frame];
	NSRect windowContentFrame = [[[self window] contentView] frame];
	
	if ( tabsHidden )
		tabContentFrame.size.height+=22;
	else
		tabContentFrame.size.height-=22;
	
	[activeTabView setFrame:tabContentFrame];
	
	// show or hide the tab manager
	//[tabsBar retain];
	[tabsBar removeFromSuperview];
	
	if ( bookmarksHidden )
	{
		int theBorders[4] = {1,0,0,0};
		[tabsBar setBorders:theBorders];
	}
	else
	{
		int theBorders[4] = {0,0,0,0};
		[tabsBar setBorders:theBorders];
	}
	
	if ( !tabsHidden )
	{
		NSRect tabsBarFrame;
		
		if ( [self bookmarksHidden] )
			tabsBarFrame = NSMakeRect(0, windowContentFrame.size.height-22, windowContentFrame.size.width, 22);
		else
			tabsBarFrame = NSMakeRect(0, windowContentFrame.size.height-44, windowContentFrame.size.width, 22);
		
		[tabsBar setFrame:tabsBarFrame];
		[[[self window] contentView] addSubview:tabsBar];
		[tabsBar setNeedsDisplay:YES];
	}
}


- (BOOL) bookmarksHidden 
{
	return bookmarksHidden;
}

- (void) setBookmarksHidden:(BOOL)hidden 
{
	if ( bookmarksHidden == hidden )
		return;
		
	bookmarksHidden = hidden;
	
	// reframe the tab content accordingly
	NSRect tabContentFrame = [activeTabView frame];
	NSRect windowContentFrame = [[[self window] contentView] frame];
	
	if ( bookmarksHidden )
		tabContentFrame.size.height+=22;
	else
		tabContentFrame.size.height-=22;
	
	[activeTabView setFrame:tabContentFrame];
	
	// reframe the tabs bar if necessary
	if ( ![self tabsHidden] )
	{
		NSRect tabsBarFrame = [tabsBar frame];
		
		if ( bookmarksHidden )
			tabsBarFrame.origin.y+=22;
		else
			tabsBarFrame.origin.y-=22;
		
		[tabsBar setFrame:tabsBarFrame];
		[tabsBar setNeedsDisplay:YES];
	}
	
	// show or hide the favorites manager
	//[favoritesBar retain];
	//[favoritesBar removeFromSuperview];
	
	if ( !bookmarksHidden )
	{
		NSRect bookmarksBarFrame;
		bookmarksBarFrame = NSMakeRect(0, windowContentFrame.size.height-22, windowContentFrame.size.width, 22);
		
		[favoritesBar setFrame:bookmarksBarFrame];
		[[[self window] contentView] addSubview:favoritesBar];
		
		[favoritesBar setNeedsDisplay:YES];
		
		int theBorders[4] = {0,0,0,0};
		[tabsBar setBorders:theBorders];
		
		//[favoritesBar release];
	}
	else
	{
		[favoritesBar removeFromSuperview];
		
		int theBorders[4] = {1,0,0,0};
		[tabsBar setBorders:theBorders];
	}
}

#pragma mark -

- (void) toolbarDidShow:(PDToolbar*)aToolbar
{
	/*
	NSLog(@"%s",__PRETTY_FUNCTION__);
	
	// none of this should be necessary
	// adjust the height of the content or one of the bars
	// depending on what is visible
	
	// adjust height of content, 10.5 only
	if ( [self respondsToSelector:@selector(cursorUpdate:)] )
	{
		NSRect tabContentFrame = [activeTabView frame];
		tabContentFrame.size.height--;
		[activeTabView setFrame:tabContentFrame];
		
		if ( !bookmarksHidden )
		{
			NSRect favoritesFrame = [favoritesBar frame];
			favoritesFrame.origin.y--;
			[favoritesBar setFrame:favoritesFrame];
		}
		
		if ( !tabsHidden )
		{
			NSRect tabsFrame = [tabsBar frame];
			tabsFrame.origin.y--;
			[tabsBar setFrame:tabsFrame];
		}
	}
	*/
}

- (void) toolbarDidHide:(PDToolbar*)aToolbar
{
	/*
	NSLog(@"%s",__PRETTY_FUNCTION__);
	
	// none of this should be necessary
	// adjust the height of the content or one of the bars
	// depending on what is visible
	
	// adjust height of content, 10.5 only
	if ( [self respondsToSelector:@selector(cursorUpdate:)] )
	{
		NSRect tabContentFrame = [activeTabView frame];
		tabContentFrame.size.height++;
		[activeTabView setFrame:tabContentFrame];
		
		if ( !bookmarksHidden )
		{
			NSRect favoritesFrame = [favoritesBar frame];
			favoritesFrame.origin.y++;
			[favoritesBar setFrame:favoritesFrame];
		}
		
		if ( !tabsHidden )
		{
			NSRect tabsFrame = [tabsBar frame];
			tabsFrame.origin.y++;
			[tabsBar setFrame:tabsFrame];
		}
	}
	*/
}

#pragma mark -

- (NSString*) windowTitle
{
	// subclasses should override to provide appropriate title
	return [NSString string];
}

- (TabController*) selectedTab
{
	if ( [self selectedTabIndex] >= 0 && [self selectedTabIndex] < [[self tabControllers] count] )
		return [[self tabControllers] objectAtIndex:[self selectedTabIndex]];
	else
		return nil;
}

- (NSSearchField*) searchOutlet
{
	// subclasses may override to provide a search outlet
	return nil;
}

- (NSMenuItem*) dockMenuRepresentation
{
	int i;
	NSArray *myTabs = [self tabControllers];
	
	NSString *myWindowTitle = [[self window] title];
	if ( myWindowTitle == nil ) myWindowTitle = [NSString string];
	
	NSMenu *subMenu = [[[NSMenu alloc] initWithTitle:[NSString string]] autorelease];
	NSMenuItem *myMenuItem = [[[NSMenuItem alloc] 
			initWithTitle:myWindowTitle
			action:@selector(performDockRequest:) 
			keyEquivalent:@""] autorelease];
	
	[myMenuItem setTarget:self];
	[myMenuItem setRepresentedObject:[NSNumber numberWithInt:-1]];
	
	for ( i = 0; i < [myTabs count]; i++ )
	{
		TabController *aTab = [myTabs objectAtIndex:i];
		NSString *tabTitle = [aTab title];
		if ( tabTitle == nil ) tabTitle = [NSString string];
		
		NSMenuItem *tabMenuItem = [[[NSMenuItem alloc] 
				initWithTitle:tabTitle
				action:@selector(performDockRequest:) 
				keyEquivalent:@""] autorelease];
		
		[tabMenuItem setTarget:self];
		[tabMenuItem setRepresentedObject:[NSNumber numberWithInt:i]];
		[subMenu addItem:tabMenuItem];
	}
	
	[myMenuItem setSubmenu:subMenu];
	return myMenuItem;
}

- (IBAction) performDockRequest:(id)sender
{
	// activate the application and bring our window to the front
	[NSApp activateIgnoringOtherApps:YES];
	[[self window] makeKeyAndOrderFront:self];
	
	int tabToSelect = [[sender representedObject] intValue];
	if ( tabToSelect != -1 )
		[self selectTabAtIndex:tabToSelect force:NO];
}

#pragma mark -

- (void)observeValueForKeyPath:(NSString *)keyPath 
		ofObject:(id)object 
		change:(NSDictionary *)change 
		context:(void *)context 
{
	if ( context == kJournlerWindowControllerObserver )
	{
		if ( object == [tabControllers objectAtIndex:[self selectedTabIndex]] )
		{
			[tabsBar setNeedsDisplayInRect:[tabsBar frameOfTabAtIndex:[self selectedTabIndex]]];
			[self updateNavInterface];	
			
			// update the window title
			[[self window] setTitle:[self windowTitle]];
		}
	}
	else
	{
		[super observeValueForKeyPath:keyPath 
				ofObject:object 
				change:change 
				context:context];
	}
}

#pragma mark -
#pragma mark Window Delegation

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
	if ( [aNotification object] == [self window] )
	{
		NSMenu *fileMenu = [[[NSApp mainMenu] itemWithTag:1] submenu];
		NSMenuItem *closeWindow = [fileMenu itemAtIndex:[fileMenu indexOfItemWithTarget:nil andAction:@selector(performClose:)]];
		NSMenuItem *closeTab = [fileMenu itemAtIndex:[fileMenu indexOfItemWithTarget:nil andAction:@selector(closeTab:)]];
		
		if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"CommandWClosesWindow"] )
		{
			[closeWindow setKeyEquivalent:@"w"];
			[closeTab setKeyEquivalent:@"W"];
		}
		else
		{
			[closeWindow setKeyEquivalent:@"W"];
			[closeTab setKeyEquivalent:@"w"];
		}
	}
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
	if ( [aNotification object] == [self window] )
	{
		NSMenu *fileMenu = [[[NSApp mainMenu] itemWithTag:1] submenu];
		NSMenuItem *closeWindow = [fileMenu itemAtIndex:[fileMenu indexOfItemWithTarget:nil andAction:@selector(performClose:)]];
		NSMenuItem *closeTab = [fileMenu itemAtIndex:[fileMenu indexOfItemWithTarget:nil andAction:@selector(closeTab:)]];
		
		[closeTab setKeyEquivalent:@""];
		[closeWindow setKeyEquivalent:@"w"];
	}
}

- (void)windowDidBecomeMain:(NSNotification *)aNotification
{
	// inform the application delegate that a new window is main
	[NSApp tryToPerform:@selector(setMainWindowIgnoringActive:) with:self];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
#ifdef __DEBUG__
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
	
	// subclasses should call super's implementation or otherwise perform autosave themselves
	[self performAutosave:aNotification];
	
	// as well as notifying the tabs that they are about to close
	[[self tabControllers] makeObjectsPerformSelector:@selector(ownerWillClose)];
	
	// note that it is the responsibility of the subclasses to autorelease themselves when closed if they are retaining themselves at init
}

#pragma mark -
#pragma mark State Data

- (NSData*) stateData 
{	
	// replace array with dictionary?
	
	NSArray *stateArray = [self stateArray];
	NSNumber *theSelectedTab = [NSNumber numberWithInt:[self selectedTabIndex]];
	NSDictionary *stateDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
	 stateArray, @"stateArray",
	 theSelectedTab, @"selectedTab", nil];
	
	//return [NSKeyedArchiver archivedDataWithRootObject:stateArray];
	return [NSKeyedArchiver archivedDataWithRootObject:stateDictionary];
}

- (NSArray*) stateArray 
{	
	TabController *aTab;
	NSMutableArray *tabsStateData = [NSMutableArray arrayWithCapacity:[tabControllers count]];
	
	int i;
	for ( i = 0; i < [[self tabControllers] count]; i++ ) 
	{
		aTab = [[self tabControllers] objectAtIndex:i];
		NSData *stateData = [aTab stateData];
		
		if ( stateData != nil ) 
		{
			// add the tab's class name
			[tabsStateData addObject:[aTab className]];
			// add the state data returned by the tab
			[tabsStateData addObject:stateData];
		}
	}
	
	return tabsStateData;
}

- (void) restoreStateFromData:(NSData*)data 
{	
	id unarchivedState = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	
	if ( [unarchivedState isKindOfClass:[NSArray class]] )
		[self restoreStateFromArray:unarchivedState];
		
	else if ( [unarchivedState isKindOfClass:[NSDictionary class]] )
	{
		NSArray *stateArray = [unarchivedState objectForKey:@"stateArray"];
		NSNumber *theSelectedTab = [unarchivedState objectForKey:@"selectedTab"];
		
		if ( stateArray != nil )
			[self restoreStateFromArray:stateArray];
		if ( theSelectedTab != nil && [theSelectedTab intValue] < [[self tabControllers] count] )
			[self selectTabAtIndex:[theSelectedTab intValue] force:YES];
	}
	
	//NSArray *tabStateArray = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	//[self restoreStateFromArray:tabStateArray];	
	
	// somehow we have no tabs: bad
	if ( [[self tabControllers] count] == 0 )
	{
		TabController *aTabController = [[[[self defaultTabClass] alloc] initWithOwner:self] autorelease];
		[self addTab:aTabController atIndex:-1];
		[self selectTabAtIndex:0 force:YES];
		[[self selectedTab] appropriateFirstResponder:[self window]];
	}
}

- (void) restoreStateFromArray:(NSArray*)anArray 
{	
#warning woah, what the hell is going on here? does the info come in className / stateData pairs
    NSData *aStateData;
	NSString *tabClassName;
	NSEnumerator *enumerator = [anArray objectEnumerator];
	//BOOL firstTab = YES;
	
	// grab the tab's state data
	while ( tabClassName = [enumerator nextObject] ) {

		// grab the tab's class name
		aStateData = [enumerator nextObject];
		
		/*		
		if ( firstTab ) 
		{
			[[tabControllers objectAtIndex:0] restoreStateWithData:aStateData];
			firstTab = NO;
		}
		else 
		{
		*/
			// turn the tab's class into an interface (the other option would be to save the interface name!)
			Class tabClass = [[NSBundle mainBundle] classNamed:tabClassName];
			if ( tabClass == NULL ) 
			{
				NSLog(@"%s - unable to load interface for class %@", __PRETTY_FUNCTION__, tabClassName);
			}
			else
			{
				TabController *aTabController = [[[tabClass alloc] initWithOwner:self] autorelease];
				[aTabController restoreStateWithData:aStateData];
				[self addTab:aTabController atIndex:-1];
			}
		//}
		
		// select the first tab, could be a preference
		[self selectTabAtIndex:0 force:YES];
	}
	
	// if more than one tab has been opened, show the tabs bar
	if ( [[self tabControllers] count] > 1 )
		[self setTabsHidden:NO];
	
	// allow the tab to change the first responder
	[[self selectedTab] appropriateFirstResponder:[self window]];
}

#pragma mark -
#pragma mark TabsView DataSource

- (unsigned int) numberOfTabsInTabView:(PDTabsView*)aTabView 
{
	return [tabControllers count];
}

- (unsigned int) selectedTabIndexInTabView:(PDTabsView*)aTabView
{
	return [self selectedTabIndex];
}

- (NSString*) tabsView:(PDTabsView*)aTabView titleForTabAtIndex:(unsigned int)index 
{
	if ( index >= [tabControllers count] ) 
	{
		NSLog(@"%s - tabs view requesting tab beyond bounds", __PRETTY_FUNCTION__ );
		return nil;
	}

	return [[tabControllers objectAtIndex:index] title];
}

#pragma mark -
#pragma mark TabsView Delegation

- (void) tabsView:(PDTabsView*)aTabView removedTabAtIndex:(int)index 
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	if ( index == -1 || index >= [[self tabControllers] count] )
	{
		NSLog(@"%s - index either -1 or beyond bounds", __PRETTY_FUNCTION__);
	}
	else
	{
		
		[self removeTabAtIndex:index];
	}
}

- (void) tabsView:(PDTabsView*)aTabView selectedTabAtIndex:(int)index 
{	
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	if ( index == -1 || index >= [[self tabControllers] count] )
	{
		NSLog(@"%s - index either -1 or beyond bounds", __PRETTY_FUNCTION__);
	}
	else
	{
		[self selectTabAtIndex:index force:NO];
	}
}

#pragma mark -
#pragma mark Favorites Bar Delegation

- (int) favoritesBar:(PDFavoritesBar*)aFavoritesBar labelOfItemWithIdentifier:(id)anIdentifier
{
	//NSLog(@"%s - identifier: %@", __PRETTY_FUNCTION__, anIdentifier);
	if ( [anIdentifier isKindOfClass:[NSNumber class]] )
		anIdentifier = [NSString stringWithFormat:@"journler://entry/%@", anIdentifier];
		
	return [[[[self journal] objectForURIRepresentation:[NSURL URLWithString:anIdentifier]] valueForKey:@"label"] intValue];
}

- (void) journlerObjectValueDidChange:(NSNotification*)aNotification
{
	if ( [[[aNotification userInfo] objectForKey:JournlerObjectAttributeKey] isEqualToString:JournlerObjectAttributeLabelKey] )
	{
		PDFavorite *aFavorite = [favoritesBar favoriteWithIdentifier:[[aNotification object] URIRepresentationAsString]];
		if ( aFavorite != nil ) [favoritesBar setLabel:[[[aNotification object] valueForKey:@"label"] intValue] forFavorite:aFavorite];
	}
}

#pragma mark -
#pragma mark Tab Controller Delegation

- (void) tabController:(TabController*)aController didChangeTitle:(NSString*)newTitle
{
	int theIndex = [[self tabControllers] indexOfObject:aController];
	if ( theIndex != NSNotFound )
		[tabsBar setNeedsDisplayInRect:[tabsBar frameOfTabAtIndex:theIndex]];
}

#pragma mark -
#pragma mark Managing the Interface & Tabs

- (void) addTab:(TabController*)aTab atIndex:(unsigned int)index 
{	
	if ( index == -1 )
		index = [tabControllers count];
	
	NSMutableArray *theTabs = [[[self tabControllers] mutableCopyWithZone:[self zone]] autorelease];
	
	// if this is the currently selected index we'll need to deregister observers on the selected tab and set observes on the new tab
	if ( index == [self selectedTabIndex] )
	{
		[self stopObservingTab:[theTabs objectAtIndex:index] paths:[self observedPathsForTab:[theTabs objectAtIndex:index]]];
		[self startObservingTab:aTab paths:[self observedPathsForTab:aTab]];
	}
	
	// insert the object and reset the local variable
	[theTabs insertObject:aTab atIndex:index];
	[self setTabControllers:theTabs];
	
	// show the tabs if they are invisible
	if ( [self tabsHidden] && [theTabs count] > 1 )
		[self setTabsHidden:NO];
	
	// update the tab's display
	//NSRect invalidatedRect = [tabsBar frameOfTabAtIndex:index];
	//invalidatedRect.size.width = [tabsBar bounds].size.width - invalidatedRect.origin.x;
	//[tabsBar setNeedsDisplayInRect:invalidatedRect];
	[tabsBar setNeedsDisplay:YES];

}

- (void) removeTabAtIndex:(unsigned int)index 
{	
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	int tabToSelect = -99;
	NSMutableArray *theTabs = [[[self tabControllers] mutableCopyWithZone:[self zone]] autorelease];
	
	//NSRect invalidatedRect = [tabsBar frameOfTabAtIndex:index];
	//invalidatedRect.size.width = [tabsBar bounds].size.width - invalidatedRect.origin.x;
	
	// save the tab before it is removed
	[[[self tabControllers] objectAtIndex:index] performAutosave:nil];
	
	if ( index == [self selectedTabIndex] )
	{
		int tabCount = [tabControllers count] - 1;
	
		if ( index == tabCount ) 
		{
			// select the previous tab if we are closing the last tab
			[self selectTabAtIndex:index-1 force:NO];
		}
		
		else 
		{
			// select the next tab if not (and there is one after index)
			[self selectTabAtIndex:index+1 force:NO];
			// special treatment
			tabToSelect = index;
		}
	}
	else if ( index < [self selectedTabIndex] ) 
	{
		// if this close is before the currently selected tab,  then we need to move our selection down by one
		tabToSelect = [self selectedTabIndex] - 1;
		
		// deregister ourselves from the current tab
		// [self stopObservingTab:[theTabs objectAtIndex:index] paths:[self observedPathsForTab:[theTabs objectAtIndex:index]]];
	}
	
	// deregister ourselves from the closing tab (should already be deregistered but just in case) -- NO! don't double deregister
	// [self stopObservingTab:[theTabs objectAtIndex:index] paths:[self observedPathsForTab:[theTabs objectAtIndex:index]]];
	
	[[theTabs objectAtIndex:index] ownerWillClose];
	[theTabs removeObjectAtIndex:index];
	
	[self setTabControllers:theTabs];
	
	if ( tabToSelect != -99 )
		[self setSelectedTabIndex:tabToSelect];

	if ( [tabControllers count] == 1 && ![[NSUserDefaults standardUserDefaults] boolForKey:@"MainWindowTabsAlwaysVisible"] )
		[self setTabsHidden:YES];
	
	// update the tab's display
	[tabsBar setNeedsDisplay:YES];
	//[tabsBar setNeedsDisplayInRect:invalidatedRect];
	
	#ifdef __DEBUG__
	NSLog(@"%s - ending",__PRETTY_FUNCTION__);
	#endif
	
}

- (void) replaceTabAtIndex:(unsigned int)index withTab:(TabController*)aTab 
{	
	// the current tab, checking bounds
	if ( index > [tabControllers count] ) 
	{
		NSLog(@"%s - index out of bounds", __PRETTY_FUNCTION__);
		return;
	}
	
	TabController *currentTabController = [tabControllers objectAtIndex:[self selectedTabIndex]];
	
	if ( [currentTabController isMemberOfClass:[aTab class]] ) 
	{
		NSLog(@"%s - user requested same tab", __PRETTY_FUNCTION__);
		NSBeep(); return;
	}
	
	// save the tab about to be replacd
	[currentTabController performAutosave:nil];
	
	// move the single tab into place
	[[aTab tabContent] setFrame:[activeTabView frame]];
	[[activeTabView superview] replaceSubview:activeTabView with:[aTab tabContent]];
	activeTabView = [aTab tabContent];
	
	// stop and start observing as needed
	[self stopObservingTab:currentTabController paths:[self observedPathsForTab:currentTabController]];
	[self startObservingTab:aTab paths:[self observedPathsForTab:aTab]];
		
	// replace the current tab with the new tab
	NSMutableArray *mutableCopy = [[[self tabControllers] mutableCopyWithZone:[self zone]] autorelease];
	[mutableCopy replaceObjectAtIndex:index withObject:aTab];
	[self setTabControllers:mutableCopy];
	
	// update the tab's display
	[tabsBar setNeedsDisplayInRect:[tabsBar frameOfTabAtIndex:index]];
	
}

- (void) selectTabAtIndex:(unsigned int)index force:(BOOL)force
{	
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	if ( index == -1 )
		index = [tabControllers count] - 1;
	
	if ( index == [self selectedTabIndex] && force == NO )
		return;
	
	NSRect previousRect = [tabsBar frameOfTabAtIndex:[self selectedTabIndex]];
	[tabsBar setNeedsDisplayInRect:previousRect];
	
	// grab the current tab and the one which will be replacing it
	TabController *currentTabController = ( [self selectedTabIndex] == - 1  ? nil : [tabControllers objectAtIndex:[self selectedTabIndex]] );
	TabController *replacingTabController = [tabControllers objectAtIndex:index];
	
	// save the tab about to be taken out of view
	[currentTabController performAutosave:nil];
	
	// post will deselect and select notifications to the tabs
	if ( currentTabController != nil )
	{
		if ( [currentTabController respondsToSelector:@selector(ownerWillDeselectTab:)] )
			[currentTabController ownerWillDeselectTab:nil];
		if ( [replacingTabController respondsToSelector:@selector(ownerWillSelectTab:)] )
			[replacingTabController ownerWillSelectTab:nil];
	}
	
	// move the new tab into place
	[[replacingTabController tabContent] setFrame:[activeTabView frame]];
	[[activeTabView superview] replaceSubview:activeTabView with:[replacingTabController tabContent]];
	activeTabView = [replacingTabController tabContent];
	
	// deregister ourselves from the current tab
	if ( currentTabController != nil )
		[self stopObservingTab:currentTabController paths:[self observedPathsForTab:currentTabController]];
	
	// register ourselves with the new tab
	[self startObservingTab:replacingTabController paths:[self observedPathsForTab:replacingTabController]];
	
	// reset the selected tab index
	[self setSelectedTabIndex:index];
	
	// post did deselect and select notifications to the tabs
	if ( currentTabController != nil ) 
	{
		if ( [currentTabController respondsToSelector:@selector(ownerDidDeselectTab:)] )
			[currentTabController ownerDidDeselectTab:nil];
		if ( [replacingTabController respondsToSelector:@selector(ownerDidSelectTab:)] )
			[replacingTabController ownerDidSelectTab:nil];
	}
	
	// update the nav interface
	[self updateNavInterface];
	
	// update the window title
	[[self window] setTitle:[self windowTitle]];
	
	// re-appropriate the first responder
	[replacingTabController appropriateFirstResponder:[self window]];
	
	// update the tab's display?
	[tabsBar setNeedsDisplayInRect:[tabsBar frameOfTabAtIndex:index]];
}


#pragma mark -
#pragma mark Window Dragging

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	[[NSCursor arrowCursor] set];
	
	if ( [sender draggingSource] == favoritesBar ) 
	{
		NSPoint winMouseLoc = [sender draggingLocation];
		NSPoint screenMouseLoc = [[self window] convertBaseToScreen:winMouseLoc];
		NSShowAnimationEffect(NSAnimationEffectDisappearingItemDefault, screenMouseLoc, NSZeroSize, nil, nil, nil);
		
		return YES;
	}
	else 
	{
		return NO;
	}
}

- (unsigned int)dragOperationForDraggingInfo:(id <NSDraggingInfo>)dragInfo type:(NSString *)type 
{
	if ( [dragInfo draggingSource] == favoritesBar ) 
	{
		return NSDragOperationDelete;
	}
	else 
	{
		return NSDragOperationNone;
	}
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	if ( [sender draggingSource] == favoritesBar ) 
	{
		// update the cursor if applicable
		if ( [NSCursor currentCursor] != [NSCursor disappearingItemCursor] )
			[[NSCursor disappearingItemCursor] set];
		
		return NSDragOperationDelete;
	}
	else 
	{
		return NSDragOperationNone;
	}
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    // update the cursor is applicable
	if ( [NSCursor currentCursor] != [NSCursor arrowCursor] )
		[[NSCursor arrowCursor] set];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	if ( [sender draggingSource] == favoritesBar ) 
	{
		return NSDragOperationDelete;
	}
	else 
	{
		return NSDragOperationNone;
	}
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	if ( [sender draggingSource] == favoritesBar )
		return YES;
	else
		return NO;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
   
}

- (BOOL)ignoreModifierKeysWhileDragging 
{
	return YES;
}

#pragma mark -
#pragma mark Actions

- (IBAction) navigateBack:(id)sender {

	if ( [[tabControllers objectAtIndex:[self selectedTabIndex]] respondsToSelector:@selector(navigateBack:)] ) {
	
		// pass the message to the selected tab and update interface
		[[tabControllers objectAtIndex:[self selectedTabIndex]] navigateBack:sender];
		[self updateNavInterface];
		
		// update the window title
		[[self window] setTitle:[self windowTitle]];
	}
	else {
		NSBeep();
	}
}

- (IBAction) navigateForward:(id)sender {
	
	if ( [[tabControllers objectAtIndex:[self selectedTabIndex]] respondsToSelector:@selector(navigateForward:)] ) {
	
		// pass the message to the selected tab and update interface
		[[tabControllers objectAtIndex:[self selectedTabIndex]] navigateForward:sender];
		[self updateNavInterface];
		
		// update the window title
		[[self window] setTitle:[self windowTitle]];
	}
	else {
		NSBeep();
	}
}

- (IBAction) navigateBackOrForward:(id)sender
{
	// same as navigateForward and navigateBackward
	// except performed by a segmented cell
	
	int clickedSegment = [sender selectedSegment];
    int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
	
	if ( clickedSegmentTag == 0 )
	{	// navigate back
		if ( [[tabControllers objectAtIndex:[self selectedTabIndex]] respondsToSelector:@selector(navigateBack:)] ) {
	
			// pass the message to the selected tab and update interface
			[[tabControllers objectAtIndex:[self selectedTabIndex]] navigateBack:sender];
			[self updateNavInterface];
			
			// update the window title
			[[self window] setTitle:[self windowTitle]];
		}
		else {
			NSBeep();
		}
	}
	else if ( clickedSegmentTag == 1 )
	{	// navigate forward
		if ( [[tabControllers objectAtIndex:[self selectedTabIndex]] respondsToSelector:@selector(navigateForward:)] ) {
	
			// pass the message to the selected tab and update interface
			[[tabControllers objectAtIndex:[self selectedTabIndex]] navigateForward:sender];
			[self updateNavInterface];
			
			// update the window title
			[[self window] setTitle:[self windowTitle]];
		}
		else {
			NSBeep();
		}
	}
	else
	{
		NSBeep();
	}
}

- (void) updateNavInterface {
	
	// default implementation asks the tabs view to redisplay itself if showing
	// if a subclass want's this functionality it should call super's implementation
	
	if ( ![self tabsHidden] )
		[tabsBar setNeedsDisplayInRect:[tabsBar frameOfTabAtIndex:[self selectedTabIndex]]];
}

#pragma mark -

- (IBAction) newTab:(id)sender {
	
	// create an instance of tab and adds it to the array
	// subclasses may want to override this method. Refer to -defaultTabClass for more information
	
	TabController *tab = [[[[self defaultTabClass] alloc] initWithOwner:self] autorelease];
	TabController *currentTab = [self selectedTab];
	
	[[tab tabContent] setFrame:[activeTabView frame]];
	[tab restoreLocalStateWithDictionary:[[self selectedTab] localStateDictionary]];
	
	//[tab selectDate:[currentTab selectedDate] folders:[currentTab selectedFolders] 
	//entries:[currentTab selectedEntries] resources:[currentTab selectedResources]];
	
	[tab selectDate:[currentTab selectedDate] folders:[currentTab selectedFolders] entries:nil resources:nil];
	
	[self addTab:tab atIndex:-1];
}

- (IBAction) closeTab:(id)sender
{
	// pass the message to the tabs view which kindly handles it
	if ( [[self tabControllers] count] == 1 )
		NSBeep();
	else
		[tabsBar closeTab:[self selectedTabIndex]];
}

- (IBAction) selectNextTab:(id)sender 
{
	unsigned int newIndex = [self selectedTabIndex] + 1;
	if ( newIndex >= [[self tabControllers] count] )
		newIndex = 0;
	
	[self selectTabAtIndex:newIndex force:NO];
}

- (IBAction) selectPreviousTab:(id)sender 
{
	unsigned int newIndex = [self selectedTabIndex] - 1;
	if ( newIndex < 0 )
		newIndex = [[self tabControllers] count] - 1;
	
	[self selectTabAtIndex:newIndex force:NO];
}

#pragma mark -

- (IBAction) toggleTabBar:(id)sender
{
	[self setTabsHidden:![self tabsHidden]];
}

- (IBAction) toggleBookmarksBar:(id)sender
{
	[self setBookmarksHidden:![self bookmarksHidden]];
}

#pragma mark -

- (IBAction) selectFavorite:(id)sender
{
	if ( ![sender isKindOfClass:[PDFavoritesBar class]] )
	{
		NSLog(@"%s - request coming from bogus object of class %@", __PRETTY_FUNCTION__, [sender className]);
		NSBeep(); return;
	}
	
	NSDictionary *favoritesDictionary = [sender eventFavorite];
	unsigned int flags = [[NSApp currentEvent] modifierFlags];
	
	NSURL *link = nil;
	id favorite_id = [favoritesDictionary objectForKey:PDFavoriteID];
	
	// backwards compatibility
	if ( [favorite_id isKindOfClass:[NSString class]] )
		link = [NSURL URLWithString:favorite_id];
	else if ( [favorite_id isKindOfClass:[NSNumber class]] )
		link = [NSURL URLWithString:[NSString stringWithFormat:@"journler://entry/%@",favorite_id]];
	
	// derive the object
	id theObject = [[self journal] objectForURIRepresentation:link];
	if ( theObject == nil )
	{
		NSBeep();
		[[NSAlert favoriteError] runModal];
		NSLog(@"%s - unable to derive object for uri representation %@", __PRETTY_FUNCTION__, [link absoluteString]);
		return;
	}
	
	if ( ( flags & NSCommandKeyMask ) && ( flags & NSAlternateKeyMask ) )
	{
		// open the object in a new window
		EntryWindowController *entryWindow = [[[EntryWindowController alloc] initWithJournal:[self journal]] autorelease];
		[entryWindow showWindow:self];
	
		// set it's selection to our current selection
		if ( [theObject isKindOfClass:[JournlerEntry class]] )
			[[entryWindow selectedTab] selectDate:nil folders:nil entries:[NSArray arrayWithObject:theObject] resources:nil];
		else if ( [theObject isKindOfClass:[JournlerCollection class]] )
			[[entryWindow selectedTab] selectDate:nil folders:[NSArray arrayWithObject:theObject] entries:nil resources:nil];
		else if ( [theObject isKindOfClass:[JournlerResource class]] )
			[[entryWindow selectedTab] selectDate:nil folders:nil entries:nil resources:[NSArray arrayWithObject:theObject]];
	}
	else
	{
		if ( [theObject isKindOfClass:[JournlerResource class]] && ( flags & NSAlternateKeyMask ) )
		{
			// open the resource with the finder
			[(JournlerResource*)theObject openWithFinder];
		}
		else
		{
			// open the object in this tab, a new tab, or a new window
			TabController *theTab;
			
			if ( flags & NSCommandKeyMask )
			{
				[self newTab:self];
				theTab = [[self tabControllers] lastObject];
			}
			else
			{
				theTab = [self selectedTab];
			}
			
			if ( [theObject isKindOfClass:[JournlerEntry class]] )
				[theTab selectDate:nil folders:nil entries:[NSArray arrayWithObject:theObject] resources:nil];
			else if ( [theObject isKindOfClass:[JournlerCollection class]] )
				[theTab selectDate:nil folders:[NSArray arrayWithObject:theObject] entries:nil resources:nil];
			else if ( [theObject isKindOfClass:[JournlerResource class]] )
				[theTab selectDate:nil folders:nil entries:nil resources:[NSArray arrayWithObject:theObject]];
			
			if ( ( flags & NSShiftKeyMask ) && theTab != [self selectedTab] )
				[self selectTabAtIndex:-1 force:NO];
				// select the tab
		}
	}
}

- (IBAction) toggleFullScreen:(id)sender
{
	// subclasses may override to customize behavior
	
	// put the fullscreen controller up
	JournlerWindowController *fullScreenController = [[[FullScreenController alloc] initWithJournal:[self journal] callingController:self] autorelease];
	if ( fullScreenController == nil )
	{
		NSLog(@"%s - fullscreen not supported for my class: %@", __PRETTY_FUNCTION__, [self className]);
		NSBeep();
		return;
	}
	
	NSResponder *theFirstResponder = [[self window] firstResponder];
	
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
	[[fullScreenController tabControllers] setValue:fullScreenController forKeyPath:@"owner"];
	[[fullScreenController window] setContentView:completeContent];
	
	fullScreenController->activeTabView = activeTabView;
	fullScreenController->favoritesBar = theFavoritesBar;
	fullScreenController->tabsBar = theTabsBar;
	fullScreenController->bookmarksHidden = bookmarksHidden;
	fullScreenController->tabsHidden = tabsHidden;
	
	[theTabsBar setDelegate:fullScreenController];
	[theTabsBar setDataSource:fullScreenController];
	[theFavoritesBar setTarget:fullScreenController];
	[theFavoritesBar setDelegate:fullScreenController];
	
	[fullScreenController selectTabAtIndex:[self selectedTabIndex] force:YES];
	
    for ( TabController *aTab in [fullScreenController tabControllers] )
		[aTab setFullScreen:YES];
	
	[fullScreenController showWindow:self];
	[[fullScreenController window] makeFirstResponder:theFirstResponder];
	
	[[self window] orderOut:self];
	//[fullScreenController setTabControllers:[self tabControllers]];
	//[self setTabControllers:nil];
	
	/*
	
	// set it's selection to our current selection
	TabController *theSelectedTab = [self selectedTab];
	
	NSArray *theSelectedEntries = [theSelectedTab valueForKey:@"selectedEntries"];
	NSArray *theSelectedResources = [theSelectedTab valueForKey:@"selectedResources"];	
	
	// first try to open resources into full screen
	if ( [theSelectedResources count] > 0 )
	{
		int i = 0;
		JournlerResource *aResource;
		NSEnumerator *enumerator = [theSelectedResources objectEnumerator];
		
		while ( aResource = [enumerator nextObject] )
		{
			TabController *theTab = nil;
			if ( i == 0 )
			{
				theTab = [fullScreenController selectedTab];
				[theTab restoreLocalStateWithDictionary:[[self selectedTab] localStateDictionary]];
			}
			else
			{
				[fullScreenController newTab:sender];
				theTab = [[fullScreenController tabControllers] lastObject];
			}
			
			[theTab selectDate:nil folders:nil entries:[NSArray arrayWithObject:[aResource valueForKey:@"entry"]] 
					resources:[NSArray arrayWithObject:aResource]];
			i++;
		}

	}
	
	// then try to open entries into full screen
	else if ( [theSelectedEntries count] > 0 )
	{
		
		int i = 0;
		JournlerEntry *anEntry;
		NSEnumerator *enumerator = [theSelectedEntries objectEnumerator];
		
		while ( anEntry = [enumerator nextObject] )
		{
			TabController *theTab = nil;
			if ( i == 0 )
			{
				theTab = [fullScreenController selectedTab];
				[theTab restoreLocalStateWithDictionary:[[self selectedTab] localStateDictionary]];
			}
			else
			{
				[fullScreenController newTab:sender];
				theTab = [[fullScreenController tabControllers] lastObject];
			}
			
			[theTab selectDate:nil folders:nil entries:[NSArray arrayWithObject:anEntry] resources:nil];
			i++;
		}
	}
	else
	{
		NSLog(@"%s - no resource or entry selection for full screen mode", __PRETTY_FUNCTION__);
		
		
		//[[fullScreenController selectedTab] selectDate:[theSelectedTab valueForKey:@"selectedDate"] 
		//		folders:[theSelectedTab valueForKey:@"selectedFolders"] entries:[theSelectedTab valueForKey:@"selectedEntries"] 
		//		resources:[theSelectedTab valueForKey:@"selectedResources"]];
		
	}
	
	*/
	
}

#pragma mark -
#pragma mark Actions 
// subclasses may want to override - subclasses should certainly check for valid menu items

- (IBAction) newEntry:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(newEntry:)] )
		[[self selectedTab] performSelector:@selector(newEntry:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) newEntryWithClipboardContents:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(newEntryWithClipboardContents:)] )
		[[self selectedTab] performSelector:@selector(newEntryWithClipboardContents:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) newFolder:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(newFolder:)] )
		[[self selectedTab] performSelector:@selector(newFolder:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) newSmartFolder:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(newSmartFolder:)] )
		[[self selectedTab] performSelector:@selector(newSmartFolder:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) deleteSelectedEntries:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(deleteSelectedEntries:)] )
		[[self selectedTab] performSelector:@selector(deleteSelectedEntries:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) gotoRandomEntry:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(gotoRandomEntry:)] )
		[[self selectedTab] performSelector:@selector(gotoRandomEntry:) withObject:sender];
	else
	{
		NSBeep();
	}
}

#pragma mark -

- (IBAction) revealEntryInFinder:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(revealEntryInFinder:)] )
		[[self selectedTab] performSelector:@selector(revealEntryInFinder:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) openEntryInNewTab:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(openEntryInNewTab:)] )
		[[self selectedTab] performSelector:@selector(openEntryInNewTab:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) openEntryInNewWindow:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(openEntryInNewWindow:)] )
		[[self selectedTab] performSelector:@selector(openEntryInNewWindow:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) newWindowWithSelection:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(newWindowWithSelection:)] )
		[[self selectedTab] performSelector:@selector(newWindowWithSelection:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) newFloatingWindowWithSelection:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(newFloatingWindowWithSelection:)] )
		[[self selectedTab] performSelector:@selector(newFloatingWindowWithSelection:) withObject:sender];
	else
	{
		NSBeep();
	}
}

#pragma mark -

- (IBAction) exportSelection:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(exportSelection:)] )
		[[self selectedTab] performSelector:@selector(exportSelection:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) printDocument:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(printDocument:)] )
		[[self selectedTab] performSelector:@selector(printDocument:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) emailDocument:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(emailDocument:)] )
		[[self selectedTab] performSelector:@selector(emailDocument:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) blogDocument:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(blogDocument:)] )
		[[self selectedTab] performSelector:@selector(blogDocument:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) emailEntrySelection:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(emailEntrySelection:)] )
		[[self selectedTab] performSelector:@selector(emailEntrySelection:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) blogEntrySelection:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(blogEntrySelection:)] )
		[[self selectedTab] performSelector:@selector(blogEntrySelection:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) sendEntryToiWeb:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(sendEntryToiWeb:)] )
		[[self selectedTab] performSelector:@selector(sendEntryToiWeb:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) sendEntryToiPod:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(sendEntryToiPod:)] )
		[[self selectedTab] performSelector:@selector(sendEntryToiPod:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) duplicateEntry:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(duplicateEntry:)] )
		[[self selectedTab] performSelector:@selector(duplicateEntry:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) showEntryForSelectedResource:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(showEntryForSelectedResource:)] )
		[[self selectedTab] performSelector:@selector(showEntryForSelectedResource:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) newWebBrower:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(newWebBrower:)] )
		[[self selectedTab] performSelector:@selector(newWebBrower:) withObject:sender];
	else
	{
		NSBeep();
	}

}

#pragma mark -

- (IBAction) editEntryLabel:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(editEntryLabel:)] )
		[[self selectedTab] performSelector:@selector(editEntryLabel:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) editEntryProperty:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(editEntryProperty:)] )
		[[self selectedTab] performSelector:@selector(editEntryProperty:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) getEntryInfo:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(getEntryInfo:)] )
		[[self selectedTab] performSelector:@selector(getEntryInfo:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) getInfo:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(getInfo:)] )
		[[self selectedTab] performSelector:@selector(getInfo:) withObject:sender];
	else
	{
		NSBeep();
	}
}

#pragma mark -
#pragma mark Appearance

- (IBAction) toggleHeader:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(toggleHeader:)] )
		[[self selectedTab] performSelector:@selector(toggleHeader:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) toggleFooter:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(toggleFooter:)] )
		[[self selectedTab] performSelector:@selector(toggleFooter:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) toggleResources:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(toggleResources:)] )
		[[self selectedTab] performSelector:@selector(toggleResources:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) insertContact:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(insertContact:)] )
		[[self selectedTab] performSelector:@selector(insertContact:) withObject:sender];
	else
	{
		NSBeep();
	}
}

#pragma mark -
#pragma mark Audio/Video Actions

- (JournlerEntry*) entryForRecording:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(entryForRecording:)] )
		return [[self selectedTab] entryForRecording:sender];
	else
		return nil;
}	

- (void) sproutedVideoRecorder:(SproutedRecorder*)recorder insertRecording:(NSString*)path title:(NSString*)title
{
	if ( [[self selectedTab] respondsToSelector:@selector(sproutedVideoRecorder:insertRecording:title:)] )
		[[self selectedTab] sproutedVideoRecorder:recorder insertRecording:path title:title];
	else
	{
		NSBeep();
	}
}

- (void) sproutedAudioRecorder:(SproutedRecorder*)recorder insertRecording:(NSString*)path title:(NSString*)title
{
	if ( [[self selectedTab] respondsToSelector:@selector(sproutedAudioRecorder:insertRecording:title:)] )
		[[self selectedTab] sproutedAudioRecorder:recorder insertRecording:path title:title];
	else
	{
		NSBeep();
	}
}

- (void) sproutedSnapshot:(SproutedRecorder*)recorder insertRecording:(NSString*)path title:(NSString*)title
{
	if ( [[self selectedTab] respondsToSelector:@selector(sproutedSnapshot:insertRecording:title:)] )
		[[self selectedTab] sproutedSnapshot:recorder insertRecording:path title:title];
	else
	{
		NSBeep();
	}
}

/*
- (IBAction) captureSnapshot:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(captureSnapshot:)] )
		[[self selectedTab] performSelector:@selector(captureSnapshot:)];
	else
	{
		NSBeep();
	}

}
*/

#pragma mark -

- (void) performAutosave:(NSNotification*)aNotification
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	// iterate through each tab, saving the selected entries
	[[self tabControllers] makeObjectsPerformSelector:@selector(performAutosave:) withObject:aNotification];
}

- (BOOL) performCustomKeyEquivalent:(NSEvent *)theEvent
{
	// subclasses may override although generally speaking it should be left to the tab
	if ( [[self selectedTab] respondsToSelector:@selector(performCustomKeyEquivalent:)] )
		return [[self selectedTab] performCustomKeyEquivalent:theEvent];
	else
		return NO;
}

- (void) servicesMenuAppendSelection:(NSPasteboard*)pboard desiredType:(NSString*)type
{
	if ( [[self selectedTab] respondsToSelector:@selector(servicesMenuAppendSelection:desiredType:)] )
		[[self selectedTab] servicesMenuAppendSelection:pboard desiredType:type];
	else
	{
		NSBeep();
	}

}

#pragma mark -



/*
- (IBAction) performFindPanelAction:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(performFindPanelAction:)] )
		[[self selectedTab] performSelector:@selector(performFindPanelAction:) withObject:sender];
	else
		NSBeep();
}
*/

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	BOOL enabled = YES;
	int theTag = [menuItem tag];
	SEL action = [menuItem action];
	
	// check menu items that are specifically handled by me
	if ( action == @selector(closeTab:) )
		enabled = ( [[self tabControllers] count] > 1 );
		
	else if ( action == @selector(toggleFullScreen:) )
		enabled = YES;
		
	else if ( action == @selector(newTab:) )
		enabled = YES;
	
	else if ( action == @selector(selectNextTab:) || action == @selector(selectPreviousTab:) )
		enabled = ( [[self tabControllers] count] > 1 );
	
	else if ( action == @selector(performDockRequest:) )
		enabled = YES;
	
	else if ( action == @selector(toggleTabBar:) )
	{
		enabled = YES;
		[menuItem setState:![self tabsHidden]];
	}
	
	else if ( action == @selector(toggleBookmarksBar:) )
	{
		enabled = YES;
		[menuItem setState:![self bookmarksHidden]];
	}
	
	// ---
	
	else if ( action == @selector(performCustomFindPanelAction:) )
	{
		if ( [[self selectedTab] handlesFindCommand] )
			enabled = [[self selectedTab] validateMenuItem:menuItem];
		else
			enabled = NO;
	}
	
	else if ( action == @selector(performCustomTextSizeAction:) )
	{
		if ( [[self selectedTab] handlesTextSizeCommand] )
			enabled = [[self selectedTab] validateMenuItem:menuItem];
		else
			enabled = NO;
	}
	
	else if ( action == @selector(performFindPanelAction:) )
	{
		if ( [[self selectedTab] handlesFindCommand] )
			enabled = [[self selectedTab] validateMenuItem:menuItem];
		else
			enabled = NO;
	}
	
	else if ( action == @selector(modifyFont:) )
	{
		if ( [[NSFontManager sharedFontManager] respondsToSelector:@selector(validateMenuItem:)] )
			enabled = [[NSFontManager sharedFontManager] validateMenuItem:menuItem];
		
		// if we got a no on enabled then ask the tab
		if ( enabled == NO && ( theTag == 3 || theTag == 4 || theTag == 99 ) && [self handlesFindCommand] )
			enabled = [[self selectedTab] validateMenuItem:menuItem];
	}
	
	// ---

	else if ( action == @selector(newEntry:) )
	{
		[menuItem setTitle:NSLocalizedString( ( [[NSUserDefaults standardUserDefaults] boolForKey:@"QuickEntryCreation"] 
		? @"menuitem new entry quick" : @"menuitem new entry extended" ), @"")];
		
		enabled = ( [[self selectedTab] respondsToSelector:action] ? [[self selectedTab] validateMenuItem:menuItem] : NO );
	}
	
	else if ( action == @selector(newFloatingWindowWithSelection:) )
		enabled = ( [[self selectedTab] respondsToSelector:action] ? [[self selectedTab] validateMenuItem:menuItem] : NO );
	
	else if ( action == @selector(newWindowWithSelection:) )
		enabled = ( [[self selectedTab] respondsToSelector:action] ? [[self selectedTab] validateMenuItem:menuItem] : NO );
	
	else
	{
		if ( [[self selectedTab] respondsToSelector:action] )
			enabled = [[self selectedTab] validateMenuItem:menuItem];
		else
			enabled = NO;
	}
	
	return enabled;	
}

@end

@implementation JournlerWindowController (FindPanelSupport)

- (void)performCustomFindPanelAction:(id)sender
{
	// the first responder should only make it this far under special circumstances
	if ( [[self selectedTab] respondsToSelector:@selector(performCustomFindPanelAction:)] && [[self selectedTab] handlesFindCommand] )
		[[self selectedTab] performSelector:@selector(performCustomFindPanelAction:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (void) performCustomTextSizeAction:(id)sender
{
	// the first responder should only make it this far under special circumstances
	if ( [[self selectedTab] respondsToSelector:@selector(performCustomTextSizeAction:)] && [[self selectedTab] handlesTextSizeCommand] )
		[[self selectedTab] performSelector:@selector(performCustomTextSizeAction:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (BOOL) handlesFindCommand
{
	BOOL handles = NO;
	if ( [self selectedTab] != nil )
		handles = [[self selectedTab] handlesFindCommand];
	
	return handles;
}

- (void) performFindPanelAction:(id)sender
{
	if ( [self handlesFindCommand] )
		[[self selectedTab] performCustomFindPanelAction:sender];
}

- (BOOL) handlesTextSizeCommand
{
	BOOL handles = NO;
	if ( [self selectedTab] != nil )
		handles = [[self selectedTab] handlesTextSizeCommand];
	
	return handles;
}

- (void) modifyFont:(id)sender
{
	if ( [self handlesTextSizeCommand] )
		[[self selectedTab] performCustomTextSizeAction:sender];
}

@end

#pragma mark -

@implementation JournlerWindowController (JournlerScripting)

- (TabController*) scriptSelectedTab
{
	return [self selectedTab];
}

#pragma mark -
#pragma mark Handling Tabs

- (int) indexOfObjectInJSTabs:(TabController*)aTab
{
	return [[self valueForKey:@"tabControllers"] indexOfObject:aTab];
}

- (unsigned int) countOfJSTabs
{ 
	return [[self valueForKey:@"tabControllers"] count];
}

- (TabController*) objectInJSTabsAtIndex:(unsigned int)i
{
	if ( i >= [[self valueForKey:@"tabControllers"] count] ) 
	{
		[self returnError:OSAIllegalIndex string:nil];
		return nil;
	}
	else
	{
		return [[self valueForKey:@"tabControllers"] objectAtIndex:i];
	}
}

#pragma mark -

- (void) insertObject:(TabController*)aTab inJSTabsAtIndex:(unsigned int)index
{
	[self JSAddNewTab:aTab atIndex:index];
}

- (void) insertInJSTabs:(TabController*)aTab
{
	[self JSAddNewTab:aTab atIndex:0];
}

- (void) JSAddNewTab:(TabController*)aTab atIndex:(unsigned int)index
{
	[self newTab:self];
}

#pragma mark -

- (void) removeObjectFromJSTabsAtIndex:(unsigned int)index 
{
	if ( index >= [[self valueForKey:@"tabControllers"] count]  || [[self valueForKey:@"tabControllers"] count] == 1 ) 
	{
		// raise an error
		[self returnError:OSAIllegalIndex string:nil]; 
		return;
	}
	
	[self JSDeleteTab:[[self valueForKey:@"tabControllers"] objectAtIndex:index]];
	
}

- (void) removeFromJSTabsAtIndex:(unsigned int)index
{
	if ( index >= [[self valueForKey:@"tabControllers"] count] || [[self valueForKey:@"tabControllers"] count] == 1 ) 
	{
		// raise an error
		[self returnError:OSAIllegalIndex string:nil]; 
		return;
	}
	
	[self JSDeleteTab:[[self valueForKey:@"tabControllers"] objectAtIndex:index]];
	
}

- (void) JSDeleteTab:(TabController*)aTab
{
	[self removeTabAtIndex:[[self tabControllers] indexOfObjectIdenticalTo:aTab]];
}

@end