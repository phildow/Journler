#import "FullScreenController.h"

#import "JournalWindowController.h"
#import "EntryWindowController.h"
#import "TermIndexWindowController.h"
#import "FloatingEntryWindowController.h"

#import "JournalFullScreenController.h"
#import "EntryFullScreenController.h"
#import "LexiconFullScreenController.h"

#import "Definitions.h"
//#import "JUtility.h"

#import "JournlerEntry.h"
#import "JournlerJournal.h"

#import "EntryTabController.h"
#import "FullScreenWindow.h"
#import "LinksOnlyNSTextView.h"
#import "BrowseTableFieldEditor.h"

#import "NSAttributedString+JournlerAdditions.h"
#import "NSAlert+JournlerAdditions.h"

#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>

/*
#import "PDFavoritesBar.h"
#import "KFAppleScriptHandlerAdditionsCore.h"
#import "PDAutoCompleteTextField.h"
*/

@implementation FullScreenController

- (id) init 
{
	if ( self = [super initWithWindowNibName:@"FullScreenWindow"] ) 
	{
		[self retain];
	}
	
	return self;
}

- (id) initWithJournal:(JournlerJournal*)aJournal
{
	if ( self = [super initWithWindowNibName:@"FullScreenWindow"] ) 
	{
		[self setJournal:aJournal];
		[self retain];
	}
	
	return self;
}

- (id) initWithJournal:(JournlerJournal*)aJournal callingController:(JournlerWindowController*)aController
{
	Class aClass = nil;
	
	if ( [aController isKindOfClass:[JournalWindowController class]] )
		aClass = [JournalFullScreenController class];
	else if ( [aController isKindOfClass:[EntryWindowController class]] )
		aClass = [EntryFullScreenController class];
	else if ( [aController isKindOfClass:[FloatingEntryWindowController class]] )
		aClass = [EntryFullScreenController class];
	else if ( [aController isKindOfClass:[TermIndexWindowController class]] )
		aClass = [LexiconFullScreenController class];
	
	if ( aClass == nil )
	{
		[self release];
		self = nil;
	}
	else 
	{
		[self release];
		
		if ( self = [[aClass alloc] initWithWindowNibName:@"FullScreenWindow"] ) 
		{
			[self setJournal:aJournal];
			[self setCallingController:aController];
			[self retain];
		}
	}
	
	return self;
}

- (id)initWithWindow:(NSWindow *)window
{
	if ( self = [super initWithWindow:window] )
	{
		// don't need it
		[tabsBar release];
		[favoritesBar release];				
	}
	return self;
}

- (void) dealloc 
{
	[callingController release];
	//[browseTableFieldEditor release];
	
	//[[NSNotificationCenter defaultCenter] removeObserver:self name:PDAutosaveNotification object:nil];
	//[[self window] unregisterDraggedTypes];
	
	//[super dealloc];
	[super dealloc];
}

- (void) windowDidLoad 
{	
	//[super windowDidLoad];
	
	// the custom field editor
	[browseTableFieldEditor retain];
	[browseTableFieldEditor setFieldEditor:YES];
	
	activeTabView = initalTabPlaceholder;
	[(FullScreenWindow*)[self window] completelyFillScreen];
	[[self window] registerForDraggedTypes:[NSArray arrayWithObjects:PDEntryIDPboardType, PDFavoritePboardType, nil]];
	//activeTabView = initalTabPlaceholder;
	
	/*
	// initiate the single tab
	EntryTabController *tab = [[[[self defaultTabClass] alloc] initWithOwner:self] autorelease];
	
	// move the tab into place
	[[tab tabContent] setFrame:[activeTabView frame]];
	[[activeTabView superview] replaceSubview:activeTabView with:[tab tabContent]];
	activeTabView = [tab tabContent];
	
	// the custom field editor
	[browseTableFieldEditor retain];
	[browseTableFieldEditor setFieldEditor:YES];
	
	// make the tab view and bookmarks view visible if requested by the user
	//[self setBookmarksHidden:![[NSUserDefaults standardUserDefaults] boolForKey:@"MainWindowBookmarksVisible"]];
	//[self setTabsHidden:![[NSUserDefaults standardUserDefaults] boolForKey:@"MainWindowTabsAlwaysVisible"]];
	
	// set up the toolbar
	//[self setupToolbar];
	
	// take note of selection changes so that navigation may be updated
	[self startObservingTab:tab paths:[self observedPathsForTab:aTab]];
	
	// add the tab to the array and select it
	[self addTab:tab atIndex:-1];
	[self setSelectedTabIndex:0];
	
	*/
	
	// ensure the tab knows we are fullscreen
	//if ( [tab respondsToSelector:@selector(setFullScreen:)] )
	//	[tab setFullScreen:YES];
}

#pragma mark -

- (JournlerWindowController*) callingController
{
	return callingController;
}

- (void) setCallingController:(JournlerWindowController*)aWindowController
{
	if ( callingController != aWindowController )
	{
		[callingController release];
		callingController = [aWindowController retain];
	}
}

#pragma mark -

+ (void) enableFullscreenMode
{
	BOOL showMenuBar = [[NSUserDefaults standardUserDefaults] boolForKey:@"FullScreenShowMenuBar"];
	if ( showMenuBar ) 
	{
		SetSystemUIMode(kUIModeNormal, 0);
	}
	else 
	{
		SetSystemUIMode(kUIModeAllHidden, 0);
	}
}

- (BOOL) isFullScreenController
{
	// to be used *only* by full screen controllers
	return YES;
}

/*
- (Class) defaultTabClass
{
	// subclasses must override to return the class of default tab for that window
	return [EntryTabController class];
}
*/

#pragma mark -

- (void)windowWillClose:(NSNotification *)aNotification 
{
	//Intentionally not calling super
	//[super windowWillClose:aNotification];
	
	NSResponder *theFirstResponder = [[self window] firstResponder];
	[[self window] makeFirstResponder:nil];
	
	// subclasses should call super's implementation or otherwise perform autosave themselves
	[self performAutosave:aNotification];
	
	// as well as notifying the tabs that they are about to close -- not calling super for this reason
	//[[self tabControllers] makeObjectsPerformSelector:@selector(ownerWillClose)];
	
	// stop observing the tab
	[self stopObservingTab:[self selectedTab] paths:[self observedPathsForTab:[self selectedTab]]];
	
	NSView *completeContent = [[[self window] contentView] retain];
	PDTabsView *theTabsBar = [tabsBar retain];
	PDFavoritesBar *theFavoritesBar = [favoritesBar retain];
	
	[[self window] setContentView:[[[NSView alloc] initWithFrame:NSMakeRect(0,0,100,100)] autorelease]];
	[tabsBar release]; tabsBar = nil;
	[favoritesBar release]; favoritesBar = nil;

	
	[[[self callingController] window] setContentView:completeContent];
	[[self callingController] setTabControllers:[self tabControllers]];
	[[[self callingController] tabControllers] setValue:[self callingController] forKeyPath:@"owner"];
	
	callingController->activeTabView = activeTabView;
	callingController->favoritesBar = theFavoritesBar;
	callingController->tabsBar = theTabsBar;
	callingController->bookmarksHidden = bookmarksHidden;
	callingController->tabsHidden = tabsHidden;
	
	[theTabsBar setDelegate:callingController];
	[theTabsBar setDataSource:callingController];
	[theFavoritesBar setTarget:callingController];
	[theFavoritesBar setDelegate:callingController];
	
	[[self callingController] selectTabAtIndex:[self selectedTabIndex] force:YES];
	[[[self callingController] window] makeFirstResponder:theFirstResponder];
    
    for ( TabController *aTab in [[self callingController] tabControllers] )
		[aTab setFullScreen:NO];
	
	[[self callingController] showWindow:self];
		
	SetSystemUIMode(kUIModeNormal, 0);
	[self autorelease];
}

/*
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
*/

#pragma mark -

- (BOOL) textViewIsInFullscreenMode:(LinksOnlyNSTextView*)aTextView
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	return YES;
}

- (void) addTab:(TabController*)aTab atIndex:(NSUInteger)index
{
	[aTab setFullScreen:YES];
	[super addTab:aTab atIndex:index];
}

#pragma mark -

/*
- (IBAction) closeTab:(id)sender
{
	// pass the message to the tabs view which kindly handles it
	if ( [[self tabControllers] count] == 1 )
		[[self window] performClose:sender];
	else
		[super closeTab:sender];
}
*/

- (IBAction) toggleFullScreen:(id)sender 
{
	//NSView *completeContent = [[[self window] contentView] retain];
	[self close];
	//[[[self callingController] window] setContentView:completeContent];
	//[[self callingController] showWindow:self];
}

- (void)keyDown:(NSEvent *)theEvent
{
	if ( [theEvent keyCode] == 53 )
	{ 
		// escape key ends fullscreen mode
		[self toggleFullScreen:self];
	}
	else
	{ 
		// anything else is passed to super for the next responder to handle
		[super keyDown:theEvent];
	}
}

#pragma mark -

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

/*
- (IBAction) toggleRuler:(id)sender
{
	if ( [[self selectedTab] respondsToSelector:@selector(toggleRuler:)] )
		[[self selectedTab] performSelector:@selector(toggleRuler:) withObject:sender];
	else
	{
		NSBeep();
	}
}
*/

/*
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

/*
- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	BOOL enabled;
	SEL action = [menuItem action];
	
	if ( action == @selector(closeTab:) )
		enabled = YES;
	
	else 
		enabled = [super validateMenuItem:menuItem];
	
	return enabled;
}
*/


@end
