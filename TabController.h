//
//  TabController.h
//  Journler
//
//  Created by Philip Dow on 10/24/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//
//	The tab controller is the base class for all tabs.
//	It manages the selection and interacts with the owning window controller

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

@class JournlerJournal;
@class JournlerEntry;
@class JournlerResource;
@class JournlerWindowController;

@interface TabController : NSObject {
	
	IBOutlet NSView *tabContent;
	
	// manages the back/forward history
	BOOL recordNavigationEvent;
	NSUndoManager *navigationManager;
	
	// manages the selected items
	NSArray *selectedEntries;
	NSArray *selectedFolders;
	NSArray *selectedResources;
	NSDate *selectedDate;
	
	// keeps a reference to the owning window and other necessary objects
	JournlerWindowController	*owner;
	JournlerJournal				*journal;

}

- (id) initWithOwner:(JournlerWindowController*)anObject;

- (JournlerWindowController*)owner;
- (void) setOwner:(JournlerWindowController*)anObject;

- (JournlerJournal*) journal;
- (void) setJournal:(JournlerJournal*)aJournal;


- (NSView*) tabContent;
- (NSString*) title;

- (NSArray*) selectedEntries;
- (void) setSelectedEntries:(NSArray*)anArray;
- (NSArray*) selectedFolders;
- (void) setSelectedFolders:(NSArray*)anArray;
- (NSArray*) selectedResources;
- (void) setSelectedResources:(NSArray*)anArray;
- (NSDate*) selectedDate;
- (void) setSelectedDate:(NSDate*)aDate;

- (void) selectDate:(NSDate*)date folders:(NSArray*)folders entries:(NSArray*)entries resources:(NSArray*)resources;

#pragma mark -

- (BOOL) selectDate:(NSDate*)aDate;
- (BOOL) selectFolders:(NSArray*)anArray;
- (BOOL) selectEntries:(NSArray*)anArray;
- (BOOL) selectResources:(NSArray*)anArray;

#pragma mark -

- (NSDictionary*) stateDictionary;
- (void) restoreStateWithDictionary:(NSDictionary*)stateDictionary;

- (NSDictionary*) localStateDictionary;
- (void) restoreLocalStateWithDictionary:(NSDictionary*)stateDictionary;

- (NSData*) stateData;
- (void) restoreStateWithData:(NSData*)stateData;

- (IBAction) navigateBack:(id)sender;
- (IBAction) navigateForward:(id)sender;

- (BOOL) isFiltering;
- (BOOL) canPerformNavigation:(NSInteger)direction;

- (void) ownerWillClose;
- (void) willDeleteEntry:(NSNotification*)aNotification;
- (void) willDeleteResource:(NSNotification*)aNotification;

- (JournlerEntry*) newDefaultEntryWithSelectedDate:(NSDate*)aDate overridePreference:(BOOL)forceDate;
- (void) printEntries:(NSDictionary*)printInfo;
- (void) performAutosave:(NSNotification*)aNotification;

- (IBAction) exportSelection:(id)sender;
- (IBAction) exportEntrySelection:(id)sender;
- (IBAction) exportResource:(id)sender;

- (IBAction) emailDocument:(id)sender;
- (IBAction) blogDocument:(id)sender;

- (IBAction) sendEntryToiWeb:(id)sender;
- (IBAction) sendEntryToiPod:(id)sender;

- (IBAction) emailEntrySelection:(id)sender;
- (IBAction) blogEntrySelection:(id)sender;

- (IBAction) emailResourceSelection:(id)sender;
- (IBAction) blogResourceSelection:(id)sender;

- (IBAction) editEntryProperty:(id)sender;
- (IBAction) editEntryLabel:(id)sender;

- (IBAction) revealEntryInFinder:(id)sender;

- (IBAction) getInfo:(id)sender;
- (IBAction) getEntryInfo:(id)sender;
- (IBAction) getFolderInfo:(id)sender;
- (IBAction) getResourceInfo:(id)sender;

- (IBAction) openEntryInNewTab:(id)sender;
- (IBAction) openEntryInNewWindow:(id)sender;
- (IBAction) openEntryInNewFloatingWindow:(id)sender;

- (void) openAnEntryInNewWindow:(JournlerEntry*)anEntry;
- (void) openAnEntryInNewTab:(JournlerEntry*)anEntry;

- (IBAction) openResourceInNewTab:(id)sender;
- (IBAction) openResourceInNewWindow:(id)sender;
- (IBAction) openResourceInNewFloatingWindow:(id)sender;

- (IBAction) revealResource:(id)sender;
- (IBAction) launchResource:(id)sender;

- (void) openAResourceWithFinder:(JournlerResource*)aResource;
- (void) openAResourceInNewTab:(JournlerResource*)aResource;
- (void) openAResourceInNewWindow:(JournlerResource*)aResource;

- (IBAction) setSelectionAsDefaultForEntry:(id)sender;
- (IBAction) rescanResourceIcon:(id)sender;
- (IBAction) rescanResourceUTI:(id)sender;

- (IBAction) editResourceLabel:(id)sender;
- (IBAction) editFolderLabel:(id)sender;

- (IBAction) newWebBrower:(id)sender;
- (IBAction) newWindowWithSelection:(id)sender;
- (IBAction) newFloatingWindowWithSelection:(id)sender;

- (JournlerEntry*) entryForRecording:(id)sender;
- (void) servicesMenuAppendSelection:(NSPasteboard*)pboard desiredType:(NSString*)type;

- (BOOL) performCustomKeyEquivalent:(NSEvent *)theEvent;
- (void) appropriateFirstResponder:(NSWindow*)aWindow;
- (void) appropriateFirstResponderForNewEntry:(NSWindow*)aWindow;

- (BOOL) highlightString:(NSString*)aString;

- (void) maximizeViewingArea;
- (void) setFullScreen:(BOOL)inFullScreen;

@end

@interface TabController (FindPanelSupport)

- (BOOL) handlesFindCommand;
- (void) performCustomFindPanelAction:(id)sender;

- (BOOL) handlesTextSizeCommand;
- (void) performCustomTextSizeAction:(id)sender;

@end

@interface TabController (JournlerScripting)

- (NSArray*) scriptVisibleEntries;

- (NSDate*) scriptSelectedDate;
- (void) setScriptSelectedDate:(NSDate*)aDate;

- (NSArray*) scriptSelectedFolders;
- (void) setScriptSelectedFolders:(NSArray*)anArray;

- (NSArray*) scriptSelectedEntries;
- (void) setScriptSelectedEntries:(NSArray*)anArray;

- (NSArray*) scriptSelectedResources;
- (void) setScriptSelectedResources:(NSArray*)anArray;

- (void) jsPrintTab:(NSScriptCommand *)command;

@end

@interface NSObject (TabControllerNotifications)

- (void) ownerWillSelectTab:(NSNotification*)aNotification;
- (void) ownerDidSelectTab:(NSNotification*)aNotification;
- (void) ownerWillDeselectTab:(NSNotification*)aNotification;
- (void) ownerDidDeselectTab:(NSNotification*)aNotification;

@end

@interface NSObject (TabControlleDelegate)

- (void) tabController:(TabController*)aController didChangeTitle:(NSString*)newTitle;

@end