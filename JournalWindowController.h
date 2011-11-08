//
//  JournalWindowController.h
//  Journler
//
//  Created by Philip Dow on 10/24/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//
//	The JournalWindowController manages the presentation of the main journal window

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

#import <Cocoa/Cocoa.h>
#import <SproutedAVI/SproutedAVI.h>

#import "JournlerWindowController.h"

@class PDPopUpButtonToolbarItem;
@class BrowseTableFieldEditor;

@interface JournalWindowController : JournlerWindowController {
	
	IBOutlet NSView *initalTabPlaceholder;
	
	IBOutlet NSView *navOutlet;
	IBOutlet NSButton *navBack;
	IBOutlet NSButton *navForward;
	IBOutlet NSSegmentedControl *navBackForward;
	
	IBOutlet NSSearchField *searchOutlet;
	PDPopUpButtonToolbarItem *dateTimeButton;
	PDPopUpButtonToolbarItem *highlightButton;
	
	IBOutlet BrowseTableFieldEditor	*browseTableFieldEditor;
}

+ (id) sharedController;

//- (IBAction) toggleResources:(id)sender;

- (IBAction) clearSearch:(id)sender;
- (IBAction) changeSearchOption:(id)sender;
- (IBAction) setAutoenablePrefixSearching:(id)sender;
- (IBAction) setSearchedContent:(id)sender;
- (IBAction) setSearchSystem:(id)sender;
- (IBAction) focusSearchField:(id)sender;
- (IBAction) performToolbarSearch:(id)sender;
- (IBAction) filterEntries:(id)sender;

- (IBAction) showSearchHelp:(id)sender;

- (IBAction) saveSearchResults:(id)sender;
- (IBAction) saveFilterResults:(id)sender;

- (IBAction) showEntryTableColumn:(id)sender;
- (IBAction) sortEntryTableByColumn:(id)sender;

- (void) showFirstRunConfiguration;

@end

@interface JournalWindowController (Toolbar)

- (void) setupToolbar;
- (void) setupDateTimePopUpButton;
- (void) setupHighlightPopUpButton;

@end
