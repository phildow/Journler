//
//  JournlerApplicationDelegate.h
//  Journler
//
//  Created by Philip Dow on 10/24/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Sparkle/Sparkle.h>
#import <Pantomime/Pantomime.h>
#import <iMediaBrowser/iMedia.h>
#import <SproutedAVI/SproutedAVI.h>

#import "JournlerJournal.h"
#import "JournlerResource.h"

@class JournlerJournal;
@class JournlerEntry;
@class JournlerCollection;
@class JournlerResource;
@class BlogPref;

@class JournlerWindowController;
@class JournalWindowController;
@class LockoutController;

@class JournlerKQueue;

extern NSString *JournlerDidFinishImportNotification;

@interface JournlerApplicationDelegate : NSObject {
	
	IBOutlet NSMenu *labelMenu;
	IBOutlet NSMenu *highlightMenu;
	IBOutlet NSMenu	*scriptsMenu;
	IBOutlet NSMenu *findMenu;
	IBOutlet NSMenuItem *biggerItem;
	IBOutlet NSMenuItem *smallerItem;
	
	IBOutlet NSMenuItem *shortcutsMenuItem;
	
	BOOL lockout;
	BOOL wasFirstRun;
	BOOL displayInverted;
	BOOL dropBoxIsWaiting;
	int spellDocumentTag;
	
	JournalLoadFlag journalLoadResult;
	JournlerJournal *sharedJournal;
	JournalWindowController *journalWindowController;
	
	NSDictionary *autoCorrectWordList;
	NSSpeechRecognizer *speechRecognizer;
	
	NSArray *filesToOpenAtLaunch;
	NSMutableArray *entriesToShowAtLaunch;
	NSString *waitingDropBoxPaths;
	
	LockoutController *lockoutController;
	JournlerWindowController *mainWindowIgnoringActive;
	
	NSTimer *autosaveTimer;
	
	BOOL dropBoxing;
	JournlerKQueue	*dropBoxWatcher;
	
	NSArray *labelImages;
	NSArray *highlightImages;
}

- (JournlerJournal*) journal;
- (int) spellDocumentTag;
- (BOOL) dropBoxing;
- (JournalWindowController*) journalWindowController;

- (JournlerWindowController*) mainWindowIgnoringActive;
- (void) setMainWindowIgnoringActive:(JournlerWindowController*)aWindowController;

- (NSDictionary*) autoCorrectWordList;
- (void) setAutoCorrectWordList:(NSDictionary*)aDictionary;

- (IBAction) save:(id)sender;
- (IBAction) saveJournal:(id)sender;
- (void) performAutosave:(NSTimer*)aTimer;

- (void) dayDidChange:(NSTimer*)aTimer;
- (void) computerDidWake:(NSNotification*)aNotification;
- (void) regenerateDynamicDatePredicates;

- (JournalLoadFlag) loadJournal;
- (BOOL) handleSetup:(NSString*)path;

- (BOOL) openFile:(NSString*)filename;
- (JournlerEntry*) importFile:(NSString*)filename;
- (JournlerEntry*) importFile:(NSString*)filename operation:(NewResourceCommand)operation;

- (IBAction) runFileImporter:(id)sender;
- (BOOL) importFilesWithImporter:(NSArray*)filenames folder:(JournlerCollection*)targetFolder userInteraction:(BOOL)visual;

- (IBAction) showJournal:(id)sender;
- (IBAction) showContactsBrowser:(id)sender;
- (IBAction) showMediaBrowser:(id)sender;
- (IBAction) showCorrespondenceBrowser:(id)sender;
- (IBAction) showEntryBrowser:(id)sender;
- (IBAction) showPreferences:(id)sender;
- (IBAction) showAboutBox:(id)sender;
- (IBAction) donate:(id)sender;

- (IBAction) showTermIndex:(id)sender;

- (IBAction) showPlugInHelp:(id)sender;
- (IBAction) showKeyboardShortcuts:(id)sender;
- (IBAction) reportBug:(id)sender;
- (IBAction) gotoWiki:(id)sender;
- (IBAction) gotoHelpForum:(id)sender;

- (IBAction) toggleContinuousSpellcheckingAppwide:(id)sender;
- (IBAction) toggleSpeakableItems:(id)sender;
- (IBAction) toggleLowLightDisplay:(id)sender;
- (IBAction) lockJournal:(id)sender;

- (IBAction) recordAudio:(id)sender;
- (IBAction) recordVideo:(id)sender;
- (IBAction) captureSnapshot:(id)sender;

- (IBAction) doPageSetup:(id)sender;
- (IBAction) performQuit:(id)sender;

- (IBAction) printJournal:(id)sender;
- (IBAction) exportJournal:(id)sender;

- (IBAction) toggleAutoCorrectSpelling:(id)sender;

- (NSArray*) entriesForPasteboardData:(NSPasteboard*)pboard visual:(BOOL)showDialog preferredTypes:(NSArray*)types;
- (NSArray*) _mailMessagePathsFromPasteboard:(NSPasteboard*)pboard;
- (void) serviceSelection:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error;

- (void) prepareLabelMenu:(NSMenu**)aMenu;
- (void) prepareHighlightMenu:(NSMenu**)aMenu;
- (NSDictionary*) autoCorrectDictionaryForFileAtPath:(NSString*)filename;

- (void) prepareScriptsMenu:(NSMenu**)aMenu;
- (IBAction) runScript:(id)sender;
- (IBAction) aboutScripts:(id)sender;

- (void) runAppleScript:(NSAppleScript*)appleScript showErrors:(BOOL)withErrors;
- (void) runAppleScriptAtPath:(NSString*)path showErrors:(BOOL)withErrors;

- (BOOL) installPDFService;
- (BOOL) installScriptMenu;
- (BOOL) installContextualMenu;
- (BOOL) installDropBoxService;

- (IBAction) runConsole:(id)sender;
- (IBAction) showActivity:(id)sender;

- (BOOL) _importContentsOfDropBox:(NSString*)path visually:(BOOL)showDialog filesAffected:(int*)newEntryCount;
- (void) cleanupDropBox:(NSString*)path;

- (void) fadeOutAllWindows:(NSArray*)excluding;
- (void) fadeInAllWindows:(NSArray*)excluding;

- (NSString *) applicationSupportFolder;
- (NSString*) documentsFolder;
- (NSString*) libraryFolder;

@end


@interface JournlerApplicationDelegate (ApplicationUtilities)

+ (NSMenu*) menuForFolder:(NSString*)path menuTarget:(id)target targetSelector:(SEL)selector;
+ (BOOL) sendRichMail:(NSAttributedString *)richBody to:(NSString *)to subject:(NSString *)subject isMIME:(BOOL)isMIME withNSMail:(BOOL)wM;

@end

/*
@interface JournlerApplicationDelegate (FindPanelSupport)

- (IBAction) performCustomFindPanelAction:(id)sender;
- (void) setFindPanelPerformsCustomAction:(NSNumber*)perfomCustomAction;

- (IBAction) performCustomTextSizeAction:(id)sender;
- (void) setTextSizePerformsCustomAction:(NSNumber*)performCustomAction;

@end
*/

@interface JournlerApplicationDelegate (JournlerScripting)

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key;

- (NSWindow*) JSJournalViewer;

- (NSDate*) scriptSelectedDate;
- (void) setScriptSelectedDate:(NSDate*)aDate;

- (NSArray*) scriptSelectedFolders;
- (void) setScriptSelectedFolders:(NSArray*)anArray;

- (NSArray*) scriptSelectedEntries;
- (void) setScriptSelectedEntries:(NSArray*)anArray;

- (NSArray*) scriptSelectedResources;
- (void) setScriptSelectedResources:(NSArray*)anArray;

#pragma mark -

- (int) indexOfObjectInJSEntries:(JournlerEntry*)anEntry;
- (unsigned int) countOfJSEntries;
- (JournlerEntry*) objectInJSEntriesAtIndex:(unsigned int)i;
- (JournlerEntry*) valueInJSEntriesWithUniqueID:(NSNumber*)idNum;

- (void) insertObject:(JournlerEntry*)anEntry inJSEntriesAtIndex:(unsigned int)index;
- (void) insertInJSEntries:(JournlerEntry*)anEntry;
- (void) JSAddNewEntry:(JournlerEntry*)anEntry atIndex:(unsigned int)index;

- (void) removeObjectFromJSEntriesAtIndex:(unsigned int)index; 
- (void) removeFromSJSEntriesAtIndex:(unsigned int)index;
- (void) JSDeleteEntry:(JournlerEntry*)anEntry;

#pragma mark -

- (int) indexOfObjectInJSFolders:(JournlerCollection*)aFolder;
- (unsigned int) countOfJSFolders;
- (JournlerCollection*) objectInJSFoldersAtIndex:(unsigned int)i;
- (JournlerCollection*) valueInJSFoldersWithUniqueID:(NSNumber*)idNum;

- (void) insertObject:(JournlerCollection*)aFolders inJSFoldersAtIndex:(unsigned int)index;
- (void) insertInJSFolders:(JournlerCollection*)aFolder;
- (void) JSAddNewFolder:(JournlerCollection*)aFolder atIndex:(unsigned int)index;

- (void) removeObjectFromJSFoldersAtIndex:(unsigned int)index;
- (void) removeFromJSFoldersAtIndex:(unsigned int)index;
- (void) JSDeleteFolder:(JournlerCollection*)aFolder;

#pragma mark -

- (int) indexOfObjectInJSReferences:(JournlerResource*)aReference;
- (unsigned int) countOfJSReferences;
- (JournlerResource*) objectInJSReferencesAtIndex:(unsigned int)i;
- (JournlerResource*) valueInJSReferencesWithUniqueID:(NSNumber*)idNum;

- (void) insertObject:(JournlerResource*)aReference inJSReferencesAtIndex:(unsigned int)index;
- (void) insertInJSReferences:(JournlerResource*)aReference;
- (void) JSAddNewReference:(JournlerResource*)aReference atIndex:(unsigned int)index;

- (void) removeObjectFromJSReferencesAtIndex:(unsigned int)index;
- (void) removeFromJSReferencesAtIndex:(unsigned int)index;
- (void) JSDeleteReference:(JournlerResource*)aResource;

#pragma mark -

- (int) indexOfObjectInJSBlogs:(BlogPref*)aBlog;
- (unsigned int) countOfJSBlogs;
- (BlogPref*) objectInJSBlogsAtIndex:(unsigned int)i;
- (BlogPref*) valueInJSBlogsWithUniqueID:(NSNumber*)idNum;

- (void) insertObject:(BlogPref*)aBlog inJSBlogsAtIndex:(unsigned int)index;
- (void) insertInJSBlogs:(BlogPref*)aBlog;
- (void) JSAddNewBlog:(BlogPref*)aBlog atIndex:(unsigned int)index;

- (void) removeObjectFromJSBlogsAtIndex:(unsigned int)index;
- (void) removeFromJSBlogsAtIndex:(unsigned int)index;
- (void) JSDeleteBlog:(BlogPref*)aBlog;

@end

#pragma mark -

@interface JournlerScriptingImportCommand : NSScriptCommand

@end

@interface JourlerScriptingMakeCommand : NSCreateCommand

@end

@interface JournlerScriptingSaveChangesCommand : NSScriptCommand

@end

@interface JournlerScriptingHighlightCommand : NSScriptCommand

@end

@interface JournlerScriptingFindInJournal : NSScriptCommand

@end

@interface JournlerDropBoxCommand : NSScriptCommand

@end