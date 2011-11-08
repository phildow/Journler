
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

#import "QuickLinkController.h"

#import "JournlerEntry.h" 

#import "JournlerApplicationDelegate.h"
#import "JournlerWindowController.h"
#import "JournalWindowController.h"

#import "EntryWindowController.h"
#import "TabController.h"

@implementation QuickLinkController

+ (id)sharedController 
{
    static QuickLinkController *sharedQuickLinkController = nil;
    if (!sharedQuickLinkController) 
	{
        sharedQuickLinkController = [[QuickLinkController allocWithZone:NULL] init];
    }

    return sharedQuickLinkController;
}

- (id)init 
{
    if (self = [self initWithWindowNibName:@"QuickLink"]) 
	{
		// grab a reference to the app controller
		[self setWindowFrameAutosaveName:@"QuickLinkBrowser"];
	}
	
    return self;
}

- (void)windowDidLoad 
{
	[entryController setFilterKey:@"title"];
	
	[entriesTable setTarget:self];
	[entriesTable setDoubleAction:@selector(_openEntryInSelectedTab:)];
	
	NSMenu *collectionsMenu = [[[NSMenu alloc] init] autorelease];
	[[[self journal] rootCollection] flatMenuRepresentation:&collectionsMenu 
			target:self action:@selector(selectCollection:) smallImages:YES inset:0];
	
	[collectionsMenu setAutoenablesItems:NO];
	[_collections_pop setMenu:collectionsMenu];
	[self selectCollection:[[_collections_pop menu] itemAtIndex:0]];
	
	NSInteger borders[4] = {0,0,0,0};
	[gradient setBorders:borders];
	[gradient setBordered:NO];
	
	// tags token field cell
	PDTokenFieldCell *tokenCell = [[[PDTokenFieldCell alloc] init] autorelease];
	
	[tokenCell setFont:[NSFont controlContentFontOfSize:11]];
	[tokenCell setControlSize:NSSmallControlSize];
	[tokenCell setDelegate:self];
	[tokenCell setBezeled:NO];
	[tokenCell setBordered:NO];
	
	[[entriesTable tableColumnWithIdentifier:@"tags"] setDataCell:tokenCell];
}

- (void) dealloc 
{
	[_selected_collection release];
	[super dealloc];
}

#pragma mark -

- (JournlerJournal*)journal
{
	return journal;
}

- (void) setJournal:(JournlerJournal*)aJournal
{
	journal = aJournal;
}

- (JournlerCollection*) selectedCollection 
{ 
	return _selected_collection; 
}

- (void) setSelectedCollection:(JournlerCollection*)selection 
{
	if ( _selected_collection != selection )
	{
		[_selected_collection release];
		_selected_collection = [selection retain];
	}
}

#pragma mark -

- (IBAction) contextualCommand:(id) sender 
{
	JournlerEntry *entry = [[entryController selectedObjects] objectAtIndex:0];
	if ( !entry ) {
		NSBeep();
		return;
	}
	
	switch ( [sender tag] ) 
	{
	case 0:
		// preview
		[self _showPreview:sender];		
		break;
	
	case 1:
		// open entry to selected tab
		[self _openEntryInSelectedTab:sender];
		break;
	
	case 2:
		// open entry in new tab
		[self _openEntryInNewTab:sender];
		break;
	
	case 3:
		// open entry in new window
		[self _openEntryInNewWindow:sender];
		break;
	
	default:
		NSBeep();
		break;
	}
}

- (IBAction) _showPreview:(id)sender
{
	JournlerEntry *entry = [[entryController selectedObjects] objectAtIndex:0];
	if ( !entry ) 
	{
		NSBeep(); return;
	}
	
	NSAttributedString *attr = [entry attributedContent];
	if ( !attr )
		attr = [[[NSAttributedString alloc] initWithString:[NSString string]] autorelease];
	
	[[previewText textStorage] beginEditing];
	[[previewText textStorage] setAttributedString:attr];
	[[previewText textStorage] endEditing];

	[NSApp runModalForWindow:previewWin];
	[previewWin orderOut:self];
}

- (IBAction) _openEntryInNewWindow:(id)sender
{
    for ( JournlerEntry *anEntry in [entryController selectedObjects] )
	{
		// put the fullscreen controller up
		EntryWindowController *entryWindow = [[[EntryWindowController alloc] initWithJournal:[self journal]] autorelease];
		[entryWindow showWindow:self];
		
		// set it's selection to our current selection
		[[entryWindow selectedTab] selectDate:nil folders:nil entries:[NSArray arrayWithObject:anEntry] resources:nil];
		[[entryWindow selectedTab] appropriateFirstResponder:[entryWindow window]];
	}

}

- (IBAction) _openEntryInSelectedTab:(id)sender
{
	JournlerEntry *anEntry = [[entryController selectedObjects] objectAtIndex:0];
	if ( anEntry == nil ) 
	{
		NSBeep(); return;
	}

	JournlerWindowController *mainWindow = [[NSApp delegate] mainWindowIgnoringActive];
	if ( mainWindow == nil )
		mainWindow = [[NSApp delegate] journalWindowController];
	
	TabController *theTab = [mainWindow selectedTab];
	[theTab selectDate:nil folders:nil entries:[NSArray arrayWithObject:anEntry] resources:nil];
}

- (IBAction) _openEntryInNewTab:(id)sender
{
	
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem 
{
	return ( [[entryController selectedObjects] count] > 0 );
}

- (BOOL)windowShouldClose:(id)sender 
{
	if ( sender == previewWin )
		[NSApp stopModal];
	
	return YES;
}

- (IBAction) selectCollection:(id)sender 
{
	[self setSelectedCollection:[sender representedObject]];
}

@end
