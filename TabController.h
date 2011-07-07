//
//  TabController.h
//  Journler
//
//  Created by Philip Dow on 10/24/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//
//	The tab controller is the base class for all tabs.
//	It manages the selection and interacts with the owning window controller

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
- (BOOL) canPerformNavigation:(int)direction;

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