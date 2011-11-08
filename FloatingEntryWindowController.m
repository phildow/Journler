//
//  FloatingEntryWindowController.m
//  Journler
//
//  Created by Philip Dow on 3/31/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

/*
 Redistribution and use in source and binary forms, with or without modification, are permitted
 provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions
 and the following disclaimer in the documentation and/or other materials provided with the
 distribution.
 
 * Neither the name of the author nor the names of its contributors may be used to endorse or
 promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// Basically, you can use the code in your free, commercial, private and public projects
// as long as you include the above notice and attribute the code to Philip Dow / Sprouted
// If you use this code in an app send me a note. I'd love to know how the code is used.

// Please also note that this copyright does not supersede any other copyrights applicable to
// open source code used herein. While explicit credit has been given in the Journler about box,
// it may be lacking in some instances in the source code. I will remedy this in future commits,
// and if you notice any please point them out.

#import "FloatingEntryWindowController.h"
#import "Definitions.h"
//#import "JUtility.h"

#import "JournlerApplicationDelegate.h"

#import "JournlerEntry.h"
#import "JournlerJournal.h"

#import "EntryTabController.h"
#import "FullScreenWindow.h"

#import "NSAttributedString+JournlerAdditions.h"
#import "NSAlert+JournlerAdditions.h"

#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>

#import "LinksOnlyNSTextView.h"
#import "BrowseTableFieldEditor.h"

@implementation FloatingEntryWindowController

- (id) init 
{
	if ( self = [super initWithWindowNibName:@"FloatingEntryWindow"] ) 
	{
		[self setWindowFrameAutosaveName:@"FloatingEntryWindow"];
		[self retain];
	}
	
	return self;
}

- (id) initWithJournal:(JournlerJournal*)aJournal
{
	if ( self = [super initWithWindowNibName:@"FloatingEntryWindow"] ) 
	{
		[self setWindowFrameAutosaveName:@"FloatingEntryWindow"];
		[self setJournal:aJournal];
		[self retain];
	}
	
	return self;
}

- (void) dealloc 
{	
	[browseTableFieldEditor release];
	[super dealloc];
}

- (void) windowDidLoad 
{	
	[super windowDidLoad];
	
	[[self window] setAlphaValue:0.96];
	[[self window] setOpaque:NO];
	
	[(NSPanel*)[self window] setFloatingPanel:YES];
	[[self window] setHidesOnDeactivate:NO];
	//[[self window] setReleasedWhenClosed:NO];
	
	activeTabView = initalTabPlaceholder;
	
	// initiate the single tab
	EntryTabController *tab = [[[[self defaultTabClass] alloc] initWithOwner:self] autorelease];
	
	// move the tab into place
	[[tab tabContent] setFrame:[activeTabView frame]];
	[[activeTabView superview] replaceSubview:activeTabView with:[tab tabContent]];
	activeTabView = [tab tabContent];
	
	// restore the state
	NSDictionary *tabState = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"FloatingEntryWindowStateDictionary"];
	if ( tabState != nil ) [tab restoreLocalStateWithDictionary:tabState];
	
	[self setBookmarksHidden:![[NSUserDefaults standardUserDefaults] boolForKey:@"FloatingEntryWindowBookmarksVisible"]];
	
	// make the tab view and bookmarks view visible if requested by the user
	//[self setBookmarksHidden:![[NSUserDefaults standardUserDefaults] boolForKey:@"MainWindowBookmarksVisible"]];
	//[self setTabsHidden:![[NSUserDefaults standardUserDefaults] boolForKey:@"MainWindowTabsAlwaysVisible"]];
	
	// the custom field editor
	[browseTableFieldEditor retain];
	[browseTableFieldEditor setFieldEditor:YES];
	
	// set up the toolbar
	//[self setupToolbar];
	
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
	return [NSString stringWithFormat:@"Journler - %@", [self valueForKeyPath:@"selectedTab.title"]];
}

#pragma mark -

- (void)windowWillClose:(NSNotification *)aNotification 
{
#ifdef __DEBUG__
	NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
	
	//[[self window] orderOut:self];
	//[[self selectedTab] setSelectedResources:nil];
	[super windowWillClose:aNotification];
	
	NSDictionary *tabState = [[self selectedTab] localStateDictionary];
	if ( tabState != nil ) [[NSUserDefaults standardUserDefaults] setObject:tabState forKey:@"FloatingEntryWindowStateDictionary"];
	
	// stop observing the tab
	[self stopObservingTab:[self selectedTab] paths:[self observedPathsForTab:[self selectedTab]]];
	
	[self autorelease];
}

- (BOOL)windowShouldClose:(id)sender
{
	// reset the content view to prevent a crash when the utility window flag is enabled
	[[self window] setContentView:[[[NSView alloc] init] autorelease]];
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
	else
	{
		return nil;
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

- (void) addTab:(TabController*)aTab atIndex:(NSUInteger)index 
{
	[super addTab:aTab atIndex:index];
	[aTab maximizeViewingArea];
}

/*
- (IBAction) navigateBack:(id)sender {

	if ( [[tabControllers objectAtIndex:[self selectedTabIndex]] respondsToSelector:@selector(navigateBack:)] ) {
	
		// pass the message to the selected tab and update interface
		[[tabControllers objectAtIndex:[self selectedTabIndex]] navigateBack:sender];
		[self updateNavInterface];
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
	}
	else {
		NSBeep();
	}
}
*/

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
	[[NSUserDefaults standardUserDefaults] setBool:!hidden forKey:@"FloatingEntryWindowBookmarksVisible"];
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
	
	else 
		enabled = [super validateMenuItem:menuItem];
	
	return enabled;
}

@end
