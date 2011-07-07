//
//  EntryFullScreenController.m
//  Journler
//
//  Created by Phil Dow on 3/27/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "EntryFullScreenController.h"

#import "Definitions.h"
//#import "JUtility.h"

#import "JournlerEntry.h"
#import "JournlerJournal.h"

#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>

/*
#import "PDFavoritesBar.h"
#import "KFAppleScriptHandlerAdditionsCore.h"
#import "PDAutoCompleteTextField.h"
*/

#import "EntryTabController.h"
#import "FullScreenWindow.h"


#import "NSAttributedString+JournlerAdditions.h"

#import "NSAlert+JournlerAdditions.h"

#import "LinksOnlyNSTextView.h"
#import "BrowseTableFieldEditor.h"


@implementation EntryFullScreenController

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


#pragma mark -

- (void)windowWillClose:(NSNotification *)aNotification 
{
	//Intentionally not calling super
	//[super windowWillClose:aNotification];
	
	NSResponder *theFirstResponder = [[self window] firstResponder];
	[[self window] makeFirstResponder:nil];
	
	// subclasses should call super's implementation or otherwise perform autosave themselves
	[self performAutosave:aNotification];
	
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
	
	[[self callingController] setSelectedTabIndex:-1];
	[[self callingController] selectTabAtIndex:[self selectedTabIndex] force:YES];
	[[[self callingController] window] makeFirstResponder:theFirstResponder];
	
	TabController *aTab;
	NSEnumerator *enumerator = [[[self callingController] tabControllers] objectEnumerator];
	while ( aTab = [enumerator nextObject] )
		[aTab setFullScreen:NO];
		
	[[self callingController] showWindow:self];
	
	SetSystemUIMode(kUIModeNormal, 0);
	[self autorelease];
}

#pragma mark -

- (BOOL) textViewIsInFullscreenMode:(LinksOnlyNSTextView*)aTextView
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	return YES;
}

- (void) addTab:(TabController*)aTab atIndex:(unsigned int)index
{
	[aTab setFullScreen:YES];
	[super addTab:aTab atIndex:index];
}

#pragma mark -

- (IBAction) toggleFullScreen:(id)sender 
{
	[self close];
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


@end
