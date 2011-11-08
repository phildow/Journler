//
//  JournlerApplicationDelegate.m
//  Journler
//
//  Created by Philip Dow on 10/24/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
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

#import "JournlerApplicationDelegate.h"
#import "Debug_Macros.h"
#import "Definitions.h"

#import <Message/NSMailDelivery.h>
#import <SproutedUtilities/SproutedUtilities.h>

#import "JournlerJournal.h"
#import "JournlerEntry.h"
#import "JournlerCollection.h"
#import "JournlerResource.h"
#import "BlogPref.h"
#import "JournlerSearchManager.h"

#import "NSAlert+JournlerAdditions.h"
#import "JournlerKQueue.h"
#import "JournlerFileWatcher.h"
#import "NSURL+JournlerAdditions.h"
#import "NSAttributedString+JournlerAdditions.h"


#import "FlaggedTransformer.h"
#import "BloggedTransformer.h"
#import "LabelTransformer.h"
#import "AttachmentTransformer.h"

#import "JournlerWindowController.h"
#import "JournalWindowController.h"
#import "TabController.h"
#import "JournalTabController.h"

#import "JournalUpgradeController.h"
#import "LockoutController.h"
#import "AddressPanelController.h"
#import "QuickLinkController.h"
#import "PrefWindowController.h"
#import "PDAboutBoxController.h"
#import "EntryWindowController.h"
#import "ConsoleController.h"
#import "TermIndexWindowController.h"
#import "LoadErrorReporter.h"
#import "ActivityViewer.h"

#import "DropBoxDialog.h"
#import "ImportReviewController.h"
#import "BulkImportController.h"



#import "PageSetupController.h"

#import "PrintJournalController.h"
#import "ExportJournalController.h"
#import "EntryExportController.h"

#define JournlerLoadErrorQuit		NSAlertThirdButtonReturn
#define JournlerLoadErrorCreate		NSAlertSecondButtonReturn
#define JournlerLoadErrorLocate		NSAlertFirstButtonReturn

NSString *JournlerDidFinishImportNotification = @"JournlerDidFinishImportNotification";

/*
HIDDEN PREFERENCES

DropBoxWantsImmediateLockIn

*/

// #warning add an event date attribut to the entry
// #warning allow user to specify which kinds of documents are or are not indexed
// #warning classdump on NSDatePicker/Cell to see if I can change the stepper position
// #warning mid width on text tables to prevent image print problem: file:///Developer/ADC%20Reference%20Library/documentation/Cocoa/Conceptual/TextLayout/index.html#//apple_ref/doc/uid/10000158i
// #warning check overwrite when exporing multiple files (with open panel)
// #warning webkit contextual menu item?
// #warning blogging: atom api (typepad), movable type, google api http://googlemac.blogspot.com/2007/04/google-data-apis-connect-cocoa.html
// #warning improve keyword system - autocomplete, etc
// #warning new resources auto-organized in list by title
// #warning move all the object specific methods to their controllers (deleting resource, folder, entry, etc) and add delegate methods to inform the owner
// #warning make it possible to context-click an item without actually selecting it
// #warning move panel components to their own nibs: resource panel, folder panel, entry table panel
// #warning resource multi selection photo view is sectioned by document type
// #warning point entry context items to the entry controller rather than the tab controller
// #warning preference for deleting media when deleting link as well

// #warning emailing doesn't seem to email all attachments (journler resources, web links)
// #warning make new should support "in" option - in folder (subfolders, entries)
// #warning recent search terms are not saved
// #warning tab should move through lists, search field
// #warning date stepper should target the day first
// #warning add the File Import jrlr bulk import information to the import dialog
// #warning really would be good to indicate a longer smart folder operation somehow
// #warning kiosk mode or "editing disabled" mode
// #warning indicate when the document is dirty or not
// #warning folders in the bookmarks bar, better bookmarks organizing
// #warning mousedown on resource or folders begins edited its title
// #warning make it possible to ESC out of any control - PDControl poses as NSControl overrides cancelOperaation
// #warning typing to get to resource table item

// #warning web views in lexicon missing plural words
// #warning get rid of second journal load code, add option to re-instate journal via console (happens when not necessary)

// #warning custom table view and outline views posing don't always work properly


// #warning provide feedback when exporting
// #warning edit date from entry cell
// #warning user says cannot copy/paste - reboot fixed problem
// #warning generate page thumbs for a pdf document and put them in the outline view
// #warning drags to the calendar can go haywire
// #warning if no entry is selected after a drag, select that entry and that folder

// #warning make it possible for user to determine what kind of file to filter, using utis
// #warning save last scrolled position for an entry
// #warning make it possible to link to a specific location in an entry (can't follow rtf standard though)
// #warning what to mori people want? customizable meta data, multiple journals, their own entry ordering
// #warning drag to dock should respect media preference for files/documents
// #warning drag of folder to calendar should respect media preferences?
// #warning delete a sub-entry from the resource pane: prevent or act?
// #warning allow user to specify own document filter - using utis, could pick an example document and journler grabs the uti from that
// #warning linkback support
// #warning what about journler links when producing html?
// #warning lexicon: delete should add items to stopwords list
// #warning cache the searchable content for resources - getting string values, etc
// #warning recording volume at video startup does not reflect actual volume
// #warning preference for importing: don't put link inside entry
// #warning support attachments with embedded email messages - ha!
// #warning upgrade file resources not converted from 1.1x - no they aren't
// #warning system context menu that brings up database window like yojimbo for quick import of data
// #warning establish a searchable content for files (textRepresentation) - expand beyond Mail messages
// #warning mediabar for web files
// #warning bonjour tech talk : http://video.google.com/videoplay?docid=-7398680103951126462&q=Google+techtalks
// #warning do the accessibility stuff for 2.5.1
// #warning add an applescript viewer! -[NSAppleScript richTextSource]! awesome!

// #warning sorting in table should respect numeric values: (NSNumericSearch|NSCaseInsensitiveSearch)
// 0x25B8 - triangle used in finder tooltip to show path
// #warning incorrect word count with cryllic text even when spelling set to multilingual ie http://www.gramota.ru
// #warning service activity may include web archive data on the drag board - look into extracting url source
// #warning source entry property (ie url from which the file, text came)
// #warning better explain importing and linking
// #warning roman kurowiak has an excellent idea for embedding resources as objects inside an entry rather than image and link (NSTextAttachmentCell subclass)
// #warning url drags from camino don't work but TextEdit sees the string no problem.
// #warning set up tabs to work with moving around the lists and text
// #warning select the page created from the archive when web browsing
// #warning greek words don't highlight in lexicon
// #warning letters working better in lexicon
// #warning entry history, revert option, kiosk mode
// #warning make it possible to target the title, category or tags from the search menu, as well as content
// #warning easier way to create a smart folder from a filter
// #warning smart folder that shows all the emails associated with a particular AB contact
// #warning make it possible to run an alternate command via any menu item -- specify selector and tag, intercept somewhere
// #warning low light items only works if display is lcd - how to check for kind of display?
// #warning plugin that lets you view resources and entries or entries and entries right next to one another, hell even in fours
// #warning plugins for entry columns
// #warning maxing out the image size and scrolling further expands image - 128, there it is!
// #warning set up image view to take up exactly space available from paper
// #warning add debug code for every method and action that can occur
// #warning the favorite error warning leaves the favorite in a highlighted state
// #warning renaming JPanel import items at the filesystem level

// #warning check the keywords in the help files
// #warning would be cool to resize entry table as scroller appears and disappears
// #warning lexicon should not be able to select web sites - gets stuck on the terms
// #warning select item after pdf service
// #warning entry window could use better deliniation up top - single pixel line running all the way across
// #warning divider line in lexicon as well
// #warning JournlerSearchManager writeIndexToDisk - Could not flush the resource index
// #warning should be possible to completely change the name of a file - extension and everything
	// don't just change the title metadata for the resources. Change the filename itself. - at least use the title when copying the resource out
// #warning when importing a resource respect its label
// #warning the scroll on the lexicon resets when changing the window size

// #warning should be able to customize the context menus
// #warning copy as html or generating html should not convert the <> signs
// #warning web browsing should support tab commands
// #warning cant seem to use wordpress - default is rich editing instead of code and i can't switch
// #warning support wiki generation even for entries that haven't been created it, special url for it

// #warning get images drags in their original format - check for promised files
// #warning adding mail messages that are in sub sub folders

// #warning when the uti of a file cannot be determined, still add it to the journal...
// #warning problem doing searches when item has punctuation
// #warning webview/html with 0 margin is slightly cut off (all my -1 x positioning)
// #warning permit linking a file directly to a fodler (with entry of course)
// #warning journler ruby interface
// #warning built in (new command) file browser - can you drag a file to journler?
// #warning clean deleted resoures command for console (activity viewer errors)
// #warning better web printing
// #warning make it possible to collapse the folder view
// #warning table does not immediately re-order after editing the entry's attributes.

// #warning inserting a date in a table cell breaks the table, undo cannot fix
// #warning plugins: possible to run something during a restart, autosave, quit?
// #warning surround state restoration with a try block
// #warning PDFAnnotation
// #warning make it possible to associated a lower rank with a particular word - journler would rank it lower next time
// #warning smart folers that check for the presence of entries in other folders
// #warning toolbar button for check entry and fullscreen
// #warning right now the copy file operation dulicates a file that already exist in the journal (dif. original path)
	// give user the option to select the file from the same entry or any other already existing location (check filename)
//#warning crash when opening resource into floating window and then closing the window - has to do with utility mask
//#warning completely replace MediaViewer window -- still used in media controllers
//#warning blog preferences aren't saved?
//#warning recording - minute doesn't reset when longer than an hour
//#warning when appropriate first responder the caret goes to end of text but start of text is visible
//#warning is it possible to get the label names from the finder? - not with applescript

//#warning launched entries don't always get selected in journler

//#warning spellcheck autocorrects names as they are dropped from address book

//#warning remove extraneous conditions in all entry text smart criterion (is is the only one valid)

//#warning expanding window causes entry content split view to expand
//#warning hovering over a tab produces the full name 
//#warning derive textrepresentation for html files
//#warning make it possible to add a movie recording to iTunes and a photo to iPhoto
//#warning auto-expand the resource list when dragging an item into it so as to show the item
//#warning enable dragging to entries list
//#warning initURLWithFile nil string
//#warning resource appears twice in pane! -- "Successfully re-attached lost resource to new entry..."
	// - the owner isn't getting set apparently	
	// - anneliese's very strange problem

//#warning modifier to delete reverse entry link
//#warning display an error when a resource cannot be relocated
//#warning after the search is reset, the lexicon doesn't work. a re-launch is required
//#warning all documents with terms won't work in lexicon - doesn't work in new window?
//#warning smart folders that work on word count, paragraph count, character count
//#warning smart folder that work on the content of other smart folders
//#warning need a way to invalidate the highlight colors after they've changed

//#warning print margins are so big - why?
//#warning make it possible to link when doing a bulk import
//#warning make it possible to drag images out of rtfd instead (right now produces text clipping)
//#warning make it possible to completely remove a resoruce from every associated entry
//#warning make it possible to resize the attachments column a bit more
//#warning when saving journal as single file do an overwrite check from the save panel - not possible because it's open panel?
//#warning optimize preferences so that panes are loaded only as needed and release when the window closes or are no longer needed
//#warning shared controllers should be first requested from the app delegate by class name, which checks the window list
//#warning while logging in switch to another app, the journler login window doesn't go away? -- can't confirm
//#warning lucida grande 13 doesn't show up in styles bar font display - the 13size throws it off
//#warning move trash to bottom?

//#warning would be nice if you could specify page breaks on new entries when printing multiple ones to a single document
//#warning request: metadata for language of an entry, setLanguage on shared spell checker when entry is selected or comes to the fore

//#warning printing a single date won't print the entries on that date, ie July 4th, need to go back to July 3rd
//#warning "do not index" flag for entries/resources so that they don't appear in the lexicon or the search
//#warning autocorrection could work in an entry's header and other places ya know
// paste tabular data into an entry with preserved formatting
// contact book icons flip when dragging a contact into an entry, but not all the time?

// 2.5.4 interface changes
// #warning option to show numer of unique entries completely contained by a regular folder
// #warning context menu to hide the header
// #warning allow the title to be the focused item after creating a new entry
// #warning make it possible to select no folder when creating a new entry (cmd-click may not be obvious)

// #warning cool idea: drags to the menu bar - set a custom view on the status item
// #warning drags to the last, empty line of text dont' work unless the insertion point is already on the last line (custom drag loc code)
// #warning embedded lexicon doesn't work in lexicon, if must be the case, remove interface for it

//
// create a standard way for an object to pass its selection to another object, whatever kind of data that is
// the pasteboard is the ideal solution, but you don't always want to overwrite what's already there.
// in such circumstances you could use a custom pasteboard.
// an apple event could have the foucsed object put its data on the standard clipboard
//

// 2.5.1 - 
//
//	accessibility
//	keyboard shortcuts for the favorites bar and media bar
//	if a favorite selects a folder, set the row visible in the source list
//	
//
// ------

// 2.5.4 changes
//
// folder actions
// renaming files on disk
// custom text attachment cell for checkboxes, shortcut to insert checkbox [], [x], list auto-produces checkbox when necessary
//
//
// ------

/*
//
// 2.5.5 changes

- added iWeb option when adding a blog to an entry in the Info windows
- changed "Address Book Records" to "Address Book Contacts" in conditions view
- fixed a problem with smart folder and filter conditions
	- problem in German and Danish, English on 10.4?
	- see notes
	
-----------------

- fixed a potential crash problem when leaving a web page immediately after it has been selected and is loading
- fixed some of the alignments on the english conditions view
- added leopard ui elements in a number of places: pdf, web, toolbars, etc
- fixed a problem with the AB Contacts window Insert button on 10.4 Tiger

- fixed a problem with the danish and german translations introduced in b1
	-- Xcode has the annoying tendency to "forget" text encodings
	
- fixed it so that a double click on an entry link in the resource pane in an entry window takes you to the entry
	-- not sure why this was disabled, don't forsee any problems but keep an eye out
	-- beeps if you double click a folder link (folders can't be selected in an entry window)
	
-----------------

- added support for QuickLook previews of the files Journler cannot handle natively
	- incredibly, incredibly useful - view any document for which a quicklook plugin is available
	- only for registered users on Leopard

-----------------

- fixed a problem with url drags from Camino hosing Journler (Leopard only)
- now auomatically recognizing urls from Firefox once you've typed a space or hit return after the drag (Leopard only)

- this shouldn't affect url recognition for Safari, Camino or when typing urls directly into an entry
- the changes do not fix or otherwise affect any behavior on Tiger systems
 
 -----------------
 
- fixed a problem with the histoy buttons when changing the size of the toolbar
- removed an unnecessary space from the file export when saving without any header
- showing the toolbar if hidden when focusing the search field for a journal search
 
- moved a few more items into the utilities and interface frameworks
	- shouldn't cause any problems but let me know
	
- using the new Sprouted AVI framework for audio/video/image recording
	- fixes video/audio synching issue on Leopard
	- fixes memory leaks on Leoprd
	- should work flawlessly and just like it did in previous versions
	- definitely let me know if that's not the case

 -----------------
 
- fixed the problem with the date/time toolbar item that I introduced into the last version (b6)

------------------

- changed behavior so that even empty folders and subfolders dragged to finder are written out
- changed behavior so that linked Finder folders are opened rather than revealed if corresponding preference is set

- fixed problem with script bundles not automatically executing
- allowing script bundles to be chosen for the 3rd party weblog editor interface

- fixed problem with drop box applescript command taking a list of files
- modified help files to better describe what happens when you cancel a drop box import

- made it possible to create a new tab by double-clicking in empty tab space
- fixed problem with tabs more indicator not appearing when more tabs are active than visible
- fixed problem with tabs more menu not allowing duplicate titles

- fixed behavior so that if focus title preference is set but the header is hidden focus goes to the entry contents

- completed the Danish translations for the Sprouted AVI framework which Journler is now using
- added a couple of missing Danish translations when building smart folders and filtering

------------------

- wrapped up the missing German translations for the Sprouted AVI framework
- added a couple of missing German translations when building smart folders and filtering

- fixed problem with missing line between tab/favorites bar and window toolbar that occurs sometimes

------------------

- added a Journler Quick Look plugin that supports the .jobj files (those returned during Spotlight searches)

- fixed a problem with Address Book drags to entry content not working (Leopard)
- modified some KVO code in a few locations

------------------

- a few under-the-hood changes
- fixed problem with file packages being opened in the Finder if the folder media preference is set and you click on the link
- fixed the quicklook plugin so it generates multipage previews

------------------

- ha! Finally grabbing titles from FireFox favicon drags

------------------

*/

// ResourceListUseSmallIcons						editResourceProperty:		0
// ResourceTableShowJournlerLinks					setDisplayOption:			102
// ResourceTableShowFolders														101
// ResourceTableCollapseDocuments												103
// ResourceTableArrangedCollapsedDocumentsByKind								104

/*
AppleScripts:
- grab attachments from a Mail email

Additional Columns:
- source -> string
- emails -> array with token fields

*/

// #warning the date cell draws one pixel lower than the other custom text cells - only certain fonts?

/*
// -------------------------------------------------------------------
// RELEASE WARNINGS
#warning 0. enable PPC build
#warning 1. make sure debug is not enabled
#warning 2. remove all unused localizations
#warning 3. update the DefaultJournal.zip file if the journal version number has changed
#warning 4. change the appcast location from beta
// -------------------------------------------------------------------
*/

#warning commit changes when a new entry is selected
#warning modify 2.5.3 upgrade code to work with pre 2.5 journal


#warning creating new entry in smart folder: condition is "not checked" user wants entry flagged, smart removes the flag

#warning when saving journal what happens to file with the same name - overwritten, save cancelled?
#warning drawing resource icons a bit lower looks bad when using small icons, especially those representing internal links
#warning when a file doesn't return a default application nil the image out?

#warning iSight integration allows more than one selection, shouldn't be the case
#warning names of linked entries don't change when the link changes?

//#warning recognize recorded movies as audio files, or at least display them so
//#warning when opening an entry into a new tab, the currently selected folder is not saved

extern void QTSetProcessProperty(UInt32 type, UInt32 creator, size_t size, uint8_t *data);

@implementation JournlerApplicationDelegate

- (id) init
{
	if ( self = [super init] )
	{
		dropBoxing = NO;
		dropBoxIsWaiting = NO;
		entriesToShowAtLaunch = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (void) awakeFromNib
{
	// preapre the label, highlight and scripts menu
	[self prepareLabelMenu:&labelMenu];
	[self prepareHighlightMenu:&highlightMenu];
	[self prepareScriptsMenu:&scriptsMenu];
	
	// ensure the scripts menu has the correct icon
	[[[NSApp mainMenu] itemWithTag:99] setImage:[NSImage imageNamed:@"ScriptMenu.png"]];
}

- (void) dealloc 
{
	[sharedJournal release];
	[journalWindowController release];
	[speechRecognizer release];
	
	[dropBoxWatcher setDelegate:nil];
	[dropBoxWatcher release];
	
	[super dealloc];
}

#pragma mark -

- (JournlerJournal*) journal
{
	return sharedJournal;
}

- (NSInteger) spellDocumentTag
{
	return spellDocumentTag;
}

- (BOOL) dropBoxing
{
	return dropBoxing;
}

- (JournalWindowController*) journalWindowController
{
	return journalWindowController;
}

- (JournlerWindowController*) mainWindowIgnoringActive
{
	return mainWindowIgnoringActive;
}

- (void) setMainWindowIgnoringActive:(JournlerWindowController*)aWindowController
{
	if ( mainWindowIgnoringActive != aWindowController )
	{
		[mainWindowIgnoringActive release];
		mainWindowIgnoringActive = [aWindowController retain];
	}
}

- (NSDictionary*) autoCorrectWordList
{
	return autoCorrectWordList;
}

- (void) setAutoCorrectWordList:(NSDictionary*)aDictionary
{
	if ( autoCorrectWordList != aDictionary )
	{
		[autoCorrectWordList release];
		autoCorrectWordList = [aDictionary retain];
	}
}

#pragma mark -

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification 
{
	// initiate the shared journal
	sharedJournal = [[JournlerJournal alloc] init];
	[sharedJournal setOwner:self];
	
	// immediately register the application to handle certain services
	[NSApp setServicesProvider: self];
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self 
			andSelector:@selector(getUrl:withReplyEvent:) 
			forEventClass:kInternetEventClass 
			andEventID:kAEGetURL];
		
	// set appwide behavior
	// #warning not quite working -- doesn't work in 64 bit environment, so on leopard?
	[PDTableView poseAsClass:[NSTableView class]];
	[PDOutlineView poseAsClass:[NSOutlineView class]];
	[PDCaseInsensitiveComboBoxCell poseAsClass:[NSComboBoxCell class]];
	[NSTBFTextBlock poseAsClass:[NSTextBlock class]];
	
	//[PDPrintedView poseAsClass:[NSView class]];
	//[PDToolbar poseAsClass:[NSToolbar class]];
	//[PDDatePicker poseAsClass:[NSDatePicker class]];
	//[CURLHandle curlHelloSignature:@"xxx" acceptAll:YES];
	
	[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	[NSNumberFormatter setDefaultFormatterBehavior:NSNumberFormatterBehavior10_4];
	
	// load the pantomime bundle
	NSBundle *mainBundle = [NSBundle mainBundle];
	NSString *pantomimePath = [NSBundle pathForResource:@"Pantomime" 
			ofType:@"framework" 
			inDirectory:[mainBundle privateFrameworksPath]];
	NSBundle *pantomimeBundle = [NSBundle bundleWithPath:pantomimePath];
	if ( pantomimePath != nil )
		[pantomimeBundle load];
	else
		NSLog(@"%s - unable to locate pantomime bundle, email preview unavailable", __PRETTY_FUNCTION__);
	
	// load the rbsplitview bundle before the imedia bundle has a chance
	/*
	NSString *mediaFrameworkPath = [NSBundle pathForResource:@"iMediaBrowser" ofType:@"framework" inDirectory:[mainBundle privateFrameworksPath]];
	NSBundle *mediaFrameworkBundle = [NSBundle bundleWithPath:mediaFrameworkPath];
	if ( mediaFrameworkBundle != nil )
		[mediaFrameworkBundle load];
	else
		NSLog(@"%s - unable to locate iMedia bundle, this could be bad!", __PRETTY_FUNCTION__);
	*/
	
	// recieve power up/down notifications - the date may have changed, re-evaluate dynamic date folders
	[[NSNotificationCenter defaultCenter] addObserver:self 
			selector:@selector(computerDidWake:) 
			name:PDPowerManagementNotification 
			object:[PDPowerManagement sharedPowerManagement]];
	
	//set up a timer to catch the day change
	NSCalendarDate *todaysDate = [NSCalendarDate calendarDate];
	NSCalendarDate *daychangeFireDate = [[NSCalendarDate dateWithYear:[todaysDate yearOfCommonEra] 
			month:[todaysDate monthOfYear] day:[todaysDate dayOfMonth] hour:0 minute:0 second:1 timeZone:nil]
			dateByAddingYears:0 months:0 days:1 hours:0 minutes:0 seconds:0];
	NSTimer *tempTimer = [[[NSTimer alloc] initWithFireDate:daychangeFireDate interval:86400 
			target:self selector:@selector(dayDidChange:) 
			userInfo:nil 
			repeats:YES] autorelease];
	[[NSRunLoop currentRunLoop] addTimer:tempTimer forMode:NSDefaultRunLoopMode];
	
	/*
	// install an uncaught exception handler - log and handle all uncaught exceptions
	[[NSExceptionHandler defaultExceptionHandler] setDelegate:self];
	
	#ifdef __DEBUG__
	
	[[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask:
			NSLogUncaughtExceptionMask|NSHandleUncaughtExceptionMask|NSLogUncaughtSystemExceptionMask|NSHandleUncaughtSystemExceptionMask];

	#else
		
	[[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask:
		NSLogUncaughtExceptionMask|NSHandleUncaughtExceptionMask|NSLogUncaughtSystemExceptionMask|NSHandleUncaughtSystemExceptionMask|
		NSLogUncaughtRuntimeErrorMask|NSHandleUncaughtRuntimeErrorMask|NSLogTopLevelExceptionMask|NSHandleTopLevelExceptionMask];
		
	#endif
	*/
	
	
	// tell spotlight to use default plugins
	SKLoadDefaultExtractorPlugIns();
	
	char *fairplay = "FairPlay";
	QTSetProcessProperty('dmmc', 'play', strlen(fairplay), (uint8_t *)fairplay);

	// install journler as the provider of certain services
	[self installPDFService];
	//[self installScriptMenu];
	[self installContextualMenu];
	
	// prepare a number of value transformers used in bindings
	id transformFlagged = [[[FlaggedTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformFlagged forName:@"FlaggedTransformer"];
	
	id transformBlogged = [[[BloggedTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformBlogged forName:@"BloggedTransformer"];
	
	id transformLabel = [[[LabelTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformLabel forName:@"LabelTransformer"];
	
	id transformAttachment = [[[AttachmentTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformAttachment forName:@"AttachmentTransformer"];
	
	// set a universal spellcheck document tag
	spellDocumentTag = [NSSpellChecker uniqueSpellDocumentTag];
	
	// the absence of path information in user defaults lets me know if this is a first run
	NSString *tempLoc = [[NSUserDefaults standardUserDefaults] objectForKey:@"Default Journal Location"];
	if ( tempLoc == nil ) 
	{
	
		NSLog(@"%s - default journal unavailable", __PRETTY_FUNCTION__);
		
		NSString *actualSetupPath = nil;
		NSString *defaultSetupPath = [[self documentsFolder] stringByAppendingPathComponent:@"Journler"];
		NSString *alternateSetupPath = [[self applicationSupportFolder] stringByAppendingPathComponent:@"Journler"];
		
		// if there's no journal in documents, there may still be a journal in app support (pre v2.5.4 -- changed for Leopard spotlight compatibility)
		if ( [[NSFileManager defaultManager] fileExistsAtPath:defaultSetupPath] == NO && [[NSFileManager defaultManager] fileExistsAtPath:alternateSetupPath] )
			actualSetupPath = alternateSetupPath;
		else
			actualSetupPath = defaultSetupPath;
		
		//if ( [[NSFileManager defaultManager] fileExistsAtPath:actualSetupPath] )
		//{
		//	// if journal data exists but preferences do not, ask the user what to do.
		//	// the safety check has been moved to handleSetup, where the data is not overwritten
		//}
		
		if ( ![self handleSetup:actualSetupPath] ) 
		{
			// critical setup error - cannot procede as there will not be a journal
			NSString *errorString = @"setup error";
			NSRunCriticalAlertPanel(@"Critical Error", NSLocalizedString( errorString, @""), nil,nil,nil);
			NSLog(@"%s - Critical error on first run, unable to setup the journal", __PRETTY_FUNCTION__);
			
		}
		
		wasFirstRun = YES;
		[[NSUserDefaults standardUserDefaults] setObject:actualSetupPath forKey:@"Default Journal Location"];
		//[[NSUserDefaults standardUserDefaults] synchronize];
	}
	
	// load the journal, checking first for the existence of a password
	NSString *journalLocation = [[[NSUserDefaults standardUserDefaults] stringForKey:@"Default Journal Location"] stringByStandardizingPath];
	NSString *journalProtectedPath = [journalLocation stringByAppendingPathComponent:PDJournalPasswordProtectedLoc];
	
	// this method checks for both the keychain password and the hidden password file
	if ( [AGKeychain checkForExistanceOfKeychainItem:@"NameJournlerKey" withItemKind:@"JournalPassword" forUsername:@"JournalPasswordLogin"] ||
			[[NSFileManager defaultManager] fileExistsAtPath:journalProtectedPath] ) 
	{
	
		//NSLog(@"%s -- have a password, beginning",__PRETTY_FUNCTION__);
		
		BOOL confirmed;
		NSString *password, *confirmedPassword;
		
		lockout = YES;
		lockoutController = nil;
		
		password = [AGKeychain getPasswordFromKeychainItem:@"NameJournlerKey" 
		withItemKind:@"JournalPassword" forUsername:@"JournalPasswordLogin"];
		
		if ( password != nil )
		{
			//NSLog(@"%s -- keychain password, beginning",__PRETTY_FUNCTION__);
			
			lockoutController = [[[LockoutController alloc] initWithPassword:password] autorelease];
			confirmed = [lockoutController confirmPassword];
			confirmedPassword = [lockoutController validatedPassword];
			
			//NSLog(@"%s -- keychain password, ending",__PRETTY_FUNCTION__);
		}
		else
		{
			//NSLog(@"%s -- file password, beginning",__PRETTY_FUNCTION__);
			
			NSError *error = nil;
			NSString *md5checksum = [NSString stringWithContentsOfFile:journalProtectedPath encoding:NSUnicodeStringEncoding error:&error];
			if ( md5checksum == nil || [md5checksum length] == 0 )
			{
				NSLog(@"%s - no checksum for file at path %@, error %@", __PRETTY_FUNCTION__, journalProtectedPath, error);
				confirmed = YES;
			}
			else
			{
				//NSLog(@"%s -- showing the controller, beginning",__PRETTY_FUNCTION__);
				
				lockoutController = [[[LockoutController alloc] initWithChecksum:md5checksum] autorelease];
				confirmed = [lockoutController confirmChecksum];
				confirmedPassword = [lockoutController validatedPassword];
				
				//NSLog(@"%s -- showing the controller, ending",__PRETTY_FUNCTION__);
			}
			
			//NSLog(@"%s -- file password, ending",__PRETTY_FUNCTION__);
		}
		
		if ( confirmed )
		{
			//NSLog(@"%s -- confirmed password, loading journal, beginning",__PRETTY_FUNCTION__);
			
			// indicate that the journal is being loaded -- freezes entire system on 10.5.2 with large journals
			//NSLog(@"%s -- [lockoutController showProgressIndicator:self]",__PRETTY_FUNCTION__);
			//if ( lockoutController != nil )
			//	[lockoutController showProgressIndicator:self];
			
			IntegrationCopyFiles *noticeWindow = nil;
			if ( lockoutController != nil )
			{
				noticeWindow = [[IntegrationCopyFiles alloc] init];
				[noticeWindow setNoticeText:NSLocalizedString(@"loading journal", @"")];
				[noticeWindow runNotice];
			}
			
			// load the journal with the password (password for 2.0 encryption support)
			//NSLog(@"%s -- [[self journal] setPassword:confirmedPassword]",__PRETTY_FUNCTION__);
			[[self journal] setPassword:confirmedPassword];
			
			//NSLog(@"%s -- [self loadJournal]",__PRETTY_FUNCTION__);
			journalLoadResult = [self loadJournal];
			
			// close the notice window
			if ( noticeWindow != nil )
			{
				[noticeWindow endNotice];
				[noticeWindow release];
				noticeWindow = nil;
			}
			
			// close the lockout window
			if ( lockoutController != nil )
			{
				//NSLog(@"%s -- confirmed password, hiding lockout controller, beginning",__PRETTY_FUNCTION__);
				
				//[lockoutController hideProgressIndicator:self];
				[lockoutController close];
				lockoutController = nil;
				
				lockout = NO;
				
				//NSLog(@"%s -- confirmed password, hiding lockout controller, ending",__PRETTY_FUNCTION__);
			}
			
			//NSLog(@"%s -- confirmed password, loading journal, ending",__PRETTY_FUNCTION__);
		}
		else
		{
			[NSApp terminate:self];
		}
		
		//NSLog(@"%s -- have a password, ending",__PRETTY_FUNCTION__);
	}
	
	else 
	{
		journalLoadResult = [self loadJournal];
	}
	
	// run the threaded resource file worker
	[[self journal] checkForModifiedResources:nil];
	
	// prepare some defaults
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"BlogModeWarningShown"];
	[[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"SelectedPreferencesPane"];
	
	if ( [[NSUserDefaults standardUserDefaults] integerForKey:@"EmbeddedImageMaxWidth"] == 0 )
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"EmbeddedImageUseFullSize"];
	
	// labels

}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	// initialize the ignored words list from the wikilinks
	NSArray *allwikikeys = [[self valueForKeyPath:@"journal.entryWikisDictionary"] allKeys];
	[[NSSpellChecker sharedSpellChecker] setIgnoredWords:allwikikeys inSpellDocumentWithTag:[self spellDocumentTag]];
	
	// ignore journler as an incorrectly spelled word
	[[NSSpellChecker sharedSpellChecker] ignoreWord:@"journler" inSpellDocumentWithTag:[self spellDocumentTag]];
	[[NSSpellChecker sharedSpellChecker] ignoreWord:@"Journler" inSpellDocumentWithTag:[self spellDocumentTag]];
	
	// prepare the autocorrect word list if requested
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryTextAutoCorrectSpelling"] &&
			[[NSUserDefaults standardUserDefaults] boolForKey:@"EntryTextAutoCorrectSpellingUseWordList"] )
	{
		NSString *wordlistPath = [[[self journal] journalPath] stringByAppendingPathComponent:PDJournalWordListLoc];
		if ( [[NSFileManager defaultManager] fileExistsAtPath:wordlistPath] )
		{
			NSDictionary *wordlist = [self autoCorrectDictionaryForFileAtPath:wordlistPath];
			if ( wordlist == nil )
			{
				// #warning let the user know
				NSLog(@"%s - unable to load wordlist from path %@", __PRETTY_FUNCTION__, wordlistPath);
			}
			else
			{
				autoCorrectWordList = [wordlist retain];
			}
		}
		else
		{
			NSLog(@"%s - no wordlist for auto-correct spelling", __PRETTY_FUNCTION__);
		}
	}
	
	// prepare the stopwords list if it is available
	NSString *theStopwords = [[NSUserDefaults standardUserDefaults] stringForKey:@"SearchStopWords"];
	if ( theStopwords != nil )
	{
		NSArray *theStopwordsArray = [theStopwords componentsSeparatedByString:@" "];
		if ( theStopwordsArray == nil )
		{
			NSLog(@"%s - unable to derive stopwords array from string %@", __PRETTY_FUNCTION__, theStopwords);
		}
		else
		{
			NSSet *theStopwordsSet = [NSSet setWithArray:theStopwordsArray];
			if ( theStopwordsSet == nil )
			{
				NSLog(@"%s - unable to derive stopwords set from array %@", __PRETTY_FUNCTION__, theStopwordsArray);
			}
			else
			{
				[[[self journal] searchManager] setStopWords:theStopwordsSet];
			}
		}
	}

	
	// launch the journal window
	journalWindowController = [[JournalWindowController sharedController] retain];
	[journalWindowController setJournal:[self journal]];
	[journalWindowController window];
	
	if ( wasFirstRun ) 
	{
		// resize the journal window so that it fills the screen
		// unless the screen is bigger than 1024x768
		
		NSRect maxFrame = NSMakeRect( 0, 0, 1280, 800 );
		NSRect visibleFrame = [[NSScreen mainScreen] visibleFrame];
		NSRect initialFrame = NSInsetRect(visibleFrame,20.0,20.0);
		
		if ( initialFrame.size.width > maxFrame.size.width && initialFrame.size.height > maxFrame.size.height )
		{
			initialFrame = NSMakeRect(	visibleFrame.origin.x + 40,
										visibleFrame.origin.y + visibleFrame.size.height - maxFrame.size.height - 40,
										maxFrame.size.width, maxFrame.size.height );
		}
		
		[[journalWindowController window] setFrame:initialFrame display:NO];
		
		[journalWindowController showFirstRunConfiguration];
		[(JournalTabController*)[journalWindowController selectedTab] showFirstRunConfiguration];
	}
	else
	{
		// restore the state unless a modifier is down
		if ( !( GetCurrentKeyModifiers() & shiftKey ) )
		{
			NSData *stateData = [self valueForKeyPath:@"journal.tabState"];
			if ( stateData != nil )
				[journalWindowController restoreStateFromData:stateData];
			else
			{
				[journalWindowController showFirstRunConfiguration];
				[(JournalTabController*)[journalWindowController selectedTab] showFirstRunTabConfiguration];
			}
		}
		else
		{
			[journalWindowController showFirstRunConfiguration];
			[(JournalTabController*)[journalWindowController selectedTab] showFirstRunTabConfiguration];
		}
	}
	
	// put the window on the screen
	[journalWindowController showWindow:self];
	
	// open any files the user is launching the app with
	if ( filesToOpenAtLaunch != nil )
	{
		for ( NSString *aFilename in filesToOpenAtLaunch )
			[self openFile:aFilename];
		
		[filesToOpenAtLaunch release];
		filesToOpenAtLaunch = nil;
	}
	
	if ( [entriesToShowAtLaunch count] != 0 )
	{
		// open the imported entry in a new window or into the main window, depending on preference
		if ( defaultBool(@"NewEntryImportNewWindow") )
		{
			// show each entry in its own window
			for ( JournlerEntry *anEntry in entriesToShowAtLaunch )
			{
				EntryWindowController *entryWindow = [[[EntryWindowController alloc] initWithJournal:[self journal]] autorelease];
				[entryWindow showWindow:self];
				
				// select the entry in the window
				[[entryWindow selectedTab] selectDate:nil 
						folders:nil 
						entries:[NSArray arrayWithObject:anEntry] 
						resources:nil];
						
				[[entryWindow selectedTab] appropriateFirstResponder:[entryWindow window]];
			}
		}
		else
		{
			// select the first entry
			[[[self journalWindowController] selectedTab] selectDate:nil 
					folders:nil 
					entries:[NSArray arrayWithObject:[entriesToShowAtLaunch objectAtIndex:0]] 
					resources:nil];
		}

	}
	
	[entriesToShowAtLaunch release];
	entriesToShowAtLaunch = nil;
	
	// launch the autosave timer - saves individual entries, not the store
	NSInteger saveInterval = [[NSUserDefaults standardUserDefaults] integerForKey:@"Auto Save Time"];
	if ( saveInterval == 0 )
		saveInterval = 8;
	
	autosaveTimer = [[NSTimer scheduledTimerWithTimeInterval:( 60 * saveInterval ) 
	target:self selector:@selector(performAutosave:) userInfo:nil repeats:YES] retain];
	
	// register for the preferences edited notification
	[[NSNotificationCenter defaultCenter] addObserver:self 
			selector:@selector(_preferencesDidEndEditing:) 
			name:PDPreferencesDidEndEditingNotification 
			object:nil];
	
	// check the crash reporter
	//if ([HDCrashReporter newCrashLogExists])
	//{
	//	[HDCrashReporter doCrashSubmitting];
	//}
	
	// check the drop box and sign up for watching
	[self installDropBoxService];
			
	// load errors? show them here
	if ( journalLoadResult & kJournalPathInitErrors )
	{
		LoadErrorReporter *errorReporter = [[[LoadErrorReporter alloc] initWithJournal:[self journal] errors:[[self journal] initErrors]] autorelease];
		[errorReporter showWindow:self];
	}

	// check for the option key to bring up the console
	if ( GetCurrentKeyModifiers() & optionKey )
		[self runConsole:self];
}

#pragma mark -


- (NSMenu *)applicationDockMenu:(NSApplication *)sender 
{
	// build a menu based on the currently visible items, tabbed and windowed	
	NSMenu *dockMenu = [[NSMenu alloc] initWithTitle:@"Dock Menu"];
	
	NSInteger i;
	NSArray *allWindows = [NSApp windows];
	
	for ( i = 0; i < [allWindows count]; i++ )
	{
		NSWindowController *aController = [[allWindows objectAtIndex:i] windowController];
		if ( [aController isKindOfClass:[JournlerWindowController class]] )
			[dockMenu addItem:[(JournlerWindowController*)aController dockMenuRepresentation]];
	}
	
	// additionally add a new entry and open item
	[dockMenu addItem:[NSMenuItem separatorItem]];
	
	NSMenuItem *newEntry = [[[NSMenuItem alloc] 
			initWithTitle:NSLocalizedString(@"new entry",@"") 
			action:@selector(newEntry:) 
			keyEquivalent:@""] autorelease];
	
	NSMenuItem *newEntryWithClipboard = [[[NSMenuItem alloc] 
			initWithTitle:NSLocalizedString(@"new entry with clipboard",@"") 
			action:@selector(newEntryWithClipboardContents:) 
			keyEquivalent:@""] autorelease];
	
	[newEntryWithClipboard setTarget:nil];
	[newEntry setTarget:nil];
	
	[dockMenu addItem:newEntryWithClipboard];
	[dockMenu addItem:newEntry];
	
	return [dockMenu autorelease];
}

#pragma mark -

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames 
{
	if ( ![sharedJournal isLoaded] )
	{
		// the open must be handled after the application launches
		filesToOpenAtLaunch = [filenames retain];
		[NSApp replyToOpenOrPrint:NSApplicationDelegateReplySuccess];
	}
	else
	{
		BOOL success = YES;
		for ( NSString *aFilename in filenames )
			success = ( [self openFile:aFilename] && success );
		
		[NSApp replyToOpenOrPrint:( success ? NSApplicationDelegateReplySuccess : NSApplicationDelegateReplyFailure )];
	}
}

- (BOOL)application:(NSApplication *)theApplication openTempFile:(NSString *)filename 
{
	return [self openFile:filename];
}

- (BOOL) openFile:(NSString*)filename
{
	// check to see if the file is a journler kind of file: entry, folder, metadata, blog, etc.
	// if not, check to see if the file is already a resource
	// if not, import the file
	
	static NSString *kEntryUTI = @"com.phildow.journler.jobj";
	static NSString *kCollectionUTI = @"com.phildow.journler.collection";
	//static NSString *kBlogUTI = @"com.phildow.journler.blog";
	
	// great for opening up to an entry from spotlight - side effect is anything on the find board gets registered
	NSString *findString = nil;
	NSPasteboard *findBoard = [NSPasteboard pasteboardWithName:NSFindPboard];
	if ( [findBoard availableTypeFromArray:[NSArray arrayWithObject:NSStringPboardType]] != nil )
		findString = [findBoard stringForType:NSStringPboardType];
	
	NSString *fileUTI = [[NSWorkspace sharedWorkspace] UTIForFile:[[NSWorkspace sharedWorkspace] resolveForAliases:filename]];
	
	if ( fileUTI == nil )
	{
		NSLog(@"%s - unable to derive uti for file, cannot process it: %@", __PRETTY_FUNCTION__, filename);
		return NO;
	}
	
	else if ( UTTypeConformsTo((CFStringRef)fileUTI,(CFStringRef)kEntryUTI) )
	{
		JournlerEntry *anEntry = [NSKeyedUnarchiver unarchiveObjectWithFile:filename];
		if ( anEntry == nil )
		{
			NSLog(@"%s - unable to decode entry at path %@", __PRETTY_FUNCTION__, filename);
			return NO;
		}
		
		JournlerEntry *actualEntry = [sharedJournal objectForURIRepresentation:[anEntry URIRepresentation]];
		if ( actualEntry == nil )
		{
			NSLog(@"%s - unable to derive actual entry for file at path %@", __PRETTY_FUNCTION__, filename);
			return NO;
		}
		
		if ( journalWindowController == nil )
		{
			[entriesToShowAtLaunch addObject:actualEntry];
        }
		else
		{
			// if we made it this far, launch the entry in a new window or open it into the main window
			if ( defaultBool(@"NewEntryImportNewWindow") )
			{
				EntryWindowController *entryWindow = [[[EntryWindowController alloc] initWithJournal:[self journal]] autorelease];
				[entryWindow showWindow:self];
				
				// select the resource in the window
				[[entryWindow selectedTab] selectDate:nil 
						folders:nil 
						entries:[NSArray arrayWithObject:actualEntry] 
						resources:nil];
						
				[[entryWindow selectedTab] appropriateFirstResponder:[entryWindow window]];
				if ( findString != nil ) [[entryWindow selectedTab] highlightString:findString];
			}
			else
			{
				[[[self journalWindowController] selectedTab] selectDate:nil 
						folders:nil 
						entries:[NSArray arrayWithObject:actualEntry] 
						resources:nil];
				
				[[self journalWindowController] showWindow:self];
				if ( findString != nil ) [[[self journalWindowController] selectedTab] highlightString:findString];
			}
		}
				
		return YES;
	}
	
	else if ( UTTypeConformsTo((CFStringRef)fileUTI,(CFStringRef)kCollectionUTI) )
	{
		JournlerCollection *aCollection = [NSKeyedUnarchiver unarchiveObjectWithFile:filename];
		if ( aCollection == nil )
		{
			NSLog(@"%s - unable to decode folder at path %@", __PRETTY_FUNCTION__, filename);
			return NO;
		}
		
		JournlerCollection *actualCollection = [sharedJournal objectForURIRepresentation:[aCollection URIRepresentation]];
		if ( actualCollection == nil )
		{
			NSLog(@"%s - unable to derive actual entry for file at path %@", __PRETTY_FUNCTION__, filename);
			return NO;
		}
		
		// if we made it this far, load the folder in the main window
		[[journalWindowController selectedTab] selectDate:nil folders:[NSArray arrayWithObject:actualCollection] entries:nil resources:nil];
		[[self journalWindowController] showWindow:self];
		
		return YES;
	}
	
	/*
	else if ( UTTypeConformsTo((CFStringRef)fileUTI,(CFStringRef)kBlogUTI) )
	{
		BlogPref *aBlog = [NSKeyedUnarchiver unarchiveObjectWithFile:filename];
		if ( aBlog == nil )
		{
			NSLog(@"%s - unable to decode blog at path %@", __PRETTY_FUNCTION__, filename);
			return NO;
		}
		
		BlogPref *actualBlog = [sharedJournal objectForURIRepresentation:[aBlog URIRepresentation]];
		if ( actualBlog == nil )
		{
			NSLog(@"%s - unable to derive actual blog for file at path %@", __PRETTY_FUNCTION__, filename);
			return NO;
		}
		
		// open the blog in preferences
		PrefWindowController *prefsController = (PrefWindowController*)[NSApp singletonControllerWithClass:[PrefWindowController class]];
		if ( prefsController == nil )
		{
			prefsController = [[[PrefWindowController alloc] init] autorelease];
			[prefsController setJournal:[self journal]];
		}
		[prefsController showWindow:self];
		[prefsController selectPanel:[NSNumber numberWithInteger:kPrefBlogging]];
		[prefsController selectBlog:actualBlog];
		
	}
	*/
	
	else
	{
		// a this point, dealing with a file that may need to be imported
		// but first see if the resource is already in the journal, and if it is open it in the main viewer
        JournlerResource *resourceToSelect = nil;
        
        for ( JournlerResource *aResource in [self valueForKeyPath:@"journal.resources"] )
		{
			if ( [aResource representsFile] && [[aResource originalPath] isEqualToString:filename] )
			{
				resourceToSelect = aResource;
				break;
			}
		}
		
		if ( resourceToSelect != nil )
		{
			if ( journalWindowController == nil )
			{
				[entriesToShowAtLaunch addObject:[resourceToSelect valueForKey:@"entry"]];
			}
			else
			{
				// put up an entry window for this resource if the preference dictates it, otherwise select in main window
				if ( defaultBool(@"NewEntryImportNewWindow") )
				{
					EntryWindowController *entryWindow = [[[EntryWindowController alloc] initWithJournal:[self journal]] autorelease];
					[entryWindow showWindow:self];
					
					// select the resource in the window
					[[entryWindow selectedTab] selectDate:nil 
							folders:nil 
							entries:[NSArray arrayWithObject:[resourceToSelect valueForKey:@"entry"]] 
							resources:[NSArray arrayWithObject:resourceToSelect]];
					
					[[entryWindow selectedTab] appropriateFirstResponder:[entryWindow window]];
					if ( findString != nil ) [[entryWindow selectedTab] highlightString:findString];
				}
				else
				{
					[[[self journalWindowController] selectedTab] selectDate:nil 
							folders:nil 
							entries:[NSArray arrayWithObject:[resourceToSelect valueForKey:@"entry"]] 
							resources:[NSArray arrayWithObject:resourceToSelect]];
					
					[[self journalWindowController] showWindow:self];
					if ( findString != nil ) [[[self journalWindowController] selectedTab] highlightString:findString];
				}
			}
			return YES;
		}
		
		else
		{
			// the file really is going to have to be imported
			JournlerEntry *importedEntry = [self importFile:filename];
			if ( importedEntry == nil )
			{
				NSBeep();
				[[NSAlert importError] runModal];
				NSLog(@"%s - unable to import file with path %@", __PRETTY_FUNCTION__, filename);
				return NO;
			}
			
			if ( journalWindowController == nil )
			{
				[entriesToShowAtLaunch addObject:importedEntry];
			}
			else
			{
				// open the imported entry in a new window or into the main window, depending on preference
				if ( defaultBool(@"NewEntryImportNewWindow") )
				{
					EntryWindowController *entryWindow = [[[EntryWindowController alloc] initWithJournal:[self journal]] autorelease];
					[entryWindow showWindow:self];
					
					// select the entry in the window
					[[entryWindow selectedTab] selectDate:nil folders:nil entries:[NSArray arrayWithObject:importedEntry] resources:nil];
					[[entryWindow selectedTab] appropriateFirstResponder:[entryWindow window]];
				}
				else
				{
					[[[self journalWindowController] selectedTab] selectDate:nil folders:nil 
							entries:[NSArray arrayWithObject:importedEntry] resources:nil];
					
					[[self journalWindowController] showWindow:self];
				}
			}
			return YES;
		}

	}
	
	return NO;
}

- (JournlerEntry*) importFile:(NSString*)filename
{
	// note that no alerts are presented to the user here. Check for a nil return and respond as you see fit
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	JournlerEntry *importedEntry = [[self importFile:filename operation:kNewResourceForceCopy] retain];
	[pool release];
	return [importedEntry autorelease];
}

- (JournlerEntry*) importFile:(NSString*)filename operation:(NewResourceCommand)operation
{
	NSInteger importOptions = 0;
	NSInteger kMaxWidth = ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EmbeddedImageUseFullSize"] 
			? 0 
			: [[NSUserDefaults standardUserDefaults] integerForKey:@"EmbeddedImageMaxWidth"] );
	
	NSSize maxPreviewSize = NSMakeSize(kMaxWidth,kMaxWidth);
	
	JournlerEntry *importedEntry = nil;
	
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"NewMediaLinkIncludeIcon"] )
		importOptions |= kEntryImportIncludeIcon;
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryImportSetDefaultResource"] )
		importOptions |= kEntryImportSetDefaultResource;
	
	importedEntry = [[JournlerEntry alloc] initWithImportAtPath:filename options:importOptions maxPreviewSize:maxPreviewSize];
	if ( importedEntry == nil ) 
	{
		NSLog(@"%s - unable to create entry from file at %@", __PRETTY_FUNCTION__, filename);
		goto bail;
	}
	
	// temporarily disable searching and indexing
	[[self journal] setSaveEntryOptions:kEntrySaveDoNotIndex|kEntrySaveDoNotCollect];
	
	// give the import an id
	[importedEntry setValue:[NSNumber numberWithInteger:[[self journal] newEntryTag]] forKey:@"tagID"];
	// add the import to the journal
	[[self journal] addEntry:importedEntry];
	
	// save the import to guarantee a file location
	if ( ![[self journal] saveEntry:importedEntry] )
	{
		NSLog(@"%s - unable to save entry imported from file at %@", __PRETTY_FUNCTION__, filename);
		[[self journal] setSaveEntryOptions:kEntrySaveIndexAndCollect];
		goto bail;
	}
	
	// attempt to complete the import
	if ( ![importedEntry completeImport:importOptions operation:operation maxPreviewSize:maxPreviewSize] )
	{
		NSLog(@"%s - unable to complete entry imported from file at %@", __PRETTY_FUNCTION__, filename);
		[[self journal] setSaveEntryOptions:kEntrySaveIndexAndCollect];
		[[self journal] deleteEntry:importedEntry];
		goto bail;
	}
	
	// set a default category and the current date
	if ( [[importedEntry category] length] == 0 )
		[importedEntry setValue:[JournlerEntry defaultCategory] forKey:@"category"];
	
	[importedEntry setValue:[NSCalendarDate calendarDate] forKey:@"calDate"];
	[importedEntry setValue:[NSCalendarDate calendarDate] forKey:@"calDateModified"];
	
	// save and index the completed entry
	[[self journal] setSaveEntryOptions:kEntrySaveIndexAndCollect];
	[[self journal] saveEntry:importedEntry];
	
bail:
	
	return [importedEntry autorelease];
}

#pragma mark -

-(void) watcher: (id<JournlerFileWatcher>)kq 
		receivedNotification:(NSString*)nm 
		forPath:(NSString*)fpath
{
	if ( !dropBoxing && [nm isEqualToString:UKFileWatcherWriteNotification] )
	{
		if ( lockout == YES )
		{
			// let the world know the drop box has new items (used when the lockout clears)
			dropBoxIsWaiting = YES;
			
			if ( waitingDropBoxPaths != nil )
				[waitingDropBoxPaths release];
			
			// which items are involved - could happen multiple times, but fpath is the same each time
			waitingDropBoxPaths = [fpath copyWithZone:[self zone]];
			
			// activate ourselves - enable this line to bring journler to the fore immediately
			if ( defaultBool(@"DropBoxWantsImmediateLockIn") )
				[NSApp activateIgnoringOtherApps:YES];
		}
		else
		{
			NSInteger fileCount;
			dropBoxing = YES;
			BOOL visually = defaultBool(@"UseVisualAidWherePossibleWhenImporting");
			BOOL success = [self _importContentsOfDropBox:fpath visually:visually filesAffected:&fileCount];
			 
			if ( !success )
			{
				// put up an alert
				NSLog(@"%s - problems importing some items from the drop box", __PRETTY_FUNCTION__);
				NSBeep();
				[[NSAlert dropboxError] runModal];
			}
		}
	}
}

- (BOOL) _importContentsOfDropBox:(NSString*)path 
		visually:(BOOL)showDialog  
		filesAffected:(NSInteger*)newEntryCount
{
	// DIRECTORY_ENUMERATION
    
    NSInteger successCount = 0;
	BOOL completeSuccess = YES;
	//NSFileManager *fm = [NSFileManager defaultManager];
	NSArray *contents = [[NSFileManager defaultManager] directoryContentsAtPath:path];
	
	NSString *aPath;
	NSString *aCompletePath;
	NSEnumerator *enumerator;
	NSMutableArray *validPaths;
	
	// first derive the valid paths
	enumerator = [contents objectEnumerator];
	validPaths = [NSMutableArray array];
	
	while ( aPath = [enumerator nextObject] )
	{
		if ( [aPath length] == 0 || [aPath characterAtIndex:0] == '.' || [aPath characterAtIndex:0] == '-'
			|| [aPath characterAtIndex:0] == '+' || [aPath isEqualToString:@"Icon\r"] )
			continue;
		
		aCompletePath = [path stringByAppendingPathComponent:aPath];
		[validPaths addObject:aCompletePath];
	}
	
	// bail if there isn't anything to import
	if ( [validPaths count] == 0 )
	{	
		dropBoxing = NO;
		return YES;
	}
	else
	{
		// run md import on each item to ensure that metadata is available to the drop box and journler
		static NSString *launchPath = @"/usr/bin/mdimport";
		//static NSString *taskOptions = @"";
		
		NSString *onePath;
		NSEnumerator *pathEnumerator = [validPaths objectEnumerator];
		
		while ( onePath = [pathEnumerator nextObject] )
		{
			NSArray *args = [NSArray arrayWithObjects: onePath, nil];
		
			NSTask *aTask = [NSTask launchedTaskWithLaunchPath:launchPath arguments:args];
			[aTask waitUntilExit];
		}
	}
	
	// put up the dialog knowing we have something, if requested
	if ( showDialog == YES )
	{
		DropBoxDialog *dropBoxDialog = [[[DropBoxDialog alloc] initWithJournal:[self journal] delegate:self
		 mode:0 didEndSelector:@selector(dropboxImport:didEndDialog:contents:)] autorelease];
		
		[dropBoxDialog setTagCompletions:[[[self journal] entryTags] allObjects]];
		if ( [validPaths count] == 1 )
		{
			// fill out the tags and category/subject
			MDItemRef mdItem = MDItemCreate(NULL,(CFStringRef)[validPaths objectAtIndex:0]);
			if ( mdItem != nil )
			{
				NSArray *mdTags = [(NSArray*)MDItemCopyAttribute(mdItem,kMDItemKeywords) autorelease];
				[dropBoxDialog setTags:mdTags];
				
				NSString *mdSubject = [(NSString*)MDItemCopyAttribute(mdItem, kMDItemSubject) autorelease];
				[dropBoxDialog setCategory:mdSubject];
				
				// pdf documents saved via the print panel in leopard use kMDItemDescription, but I don't think it's good to do that here.
				// metadata plugins, anyone?
				
				CFRelease(mdItem);
			}
		}
		
		[dropBoxDialog setRepresentedObject:validPaths];
		[dropBoxDialog setContent:[DropBoxDialog contentForFilenames:validPaths]];
		[dropBoxDialog showWindow:self];
		
	}
	else
	{
		// go ahead and perform the import without the visual aid
		
		// now perform the imports, putting up the notice
		IntegrationCopyFiles *notice = [[IntegrationCopyFiles alloc] init];
		[notice setNoticeText:NSLocalizedString(@"reading dropbox",@"")];
		[notice runNotice];
		
		NSInteger successCount;
		BOOL completeSuccess = YES;
		NSString *targetTags = nil;
		NSString *targetCategory = NSLocalizedString(@"dropbox category",@"");
		JournlerCollection *targetFolder = nil;
		
		NSString *aCompletePath;
		JournlerEntry *firstSelection = nil;
		NSEnumerator *enumerator = [validPaths objectEnumerator];
		NSFileManager *fm = [NSFileManager defaultManager];
		
		while ( aCompletePath = [enumerator nextObject] )
		{
			JournlerEntry *anImport = [self importFile:aCompletePath operation:kNewResourceForceCopy];
			
			if ( anImport == nil )
			{
				completeSuccess = NO;
				NSLog(@"%s - unable to produce entry for file at path %@", __PRETTY_FUNCTION__, aCompletePath);
				
				// note the problem with a minus sign
				NSString *movedPath = [NSString stringWithFormat:@"- %@",[aCompletePath lastPathComponent]];
				NSString *completeMovedPath = [[aCompletePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:movedPath];
				
				if ( [fm fileExistsAtPath:aCompletePath] && ![fm movePath:aCompletePath toPath:completeMovedPath handler:nil] )
					NSLog(@"%s - file still existed after import and could not be removed", __PRETTY_FUNCTION__);
				
			}
			else
			{
				if ( targetTags != nil )
					[anImport setValue:targetTags forKey:@"keywords"];
					
				if ( targetCategory != nil )
					[anImport setValue:targetCategory forKey:@"category"];
				else
					[anImport setValue:NSLocalizedString(@"dropbox category",@"") forKey:@"category"];
					
				if ( targetFolder != nil )
				{
					if ( [targetFolder isRegularFolder] )
						[targetFolder addEntry:anImport];
					else if ( [targetFolder isSmartFolder] && [targetFolder canAutotag:anImport] )
						[targetFolder autotagEntry:anImport add:YES];
				}
				
				// if the file still exists at the path, check it off
				NSString *movedPath = [NSString stringWithFormat:@"+ %@",[aCompletePath lastPathComponent]];
				NSString *completeMovedPath = [[aCompletePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:movedPath];
				
				if ( [fm fileExistsAtPath:aCompletePath] && ![fm movePath:aCompletePath toPath:completeMovedPath handler:nil] )
					NSLog(@"%s - file still existed after import and could not be removed", __PRETTY_FUNCTION__);
				
				// note the first selection
				if ( firstSelection == nil )
					firstSelection = anImport;
				
				successCount++;
			}
		}
		
		[notice endNotice];
		[notice release];
		
		// let the user know if there was a problem
		if ( completeSuccess == NO )
			[[NSAlert dropboxError] runModal];
		else
			[(NSSound*)[NSSound soundNamed:@"dropbox"] play];
		
		if ( firstSelection != nil )
		{
			[[[self journalWindowController] selectedTab] selectEntries:[NSArray arrayWithObject:firstSelection]];
		}
			
		dropBoxing = NO;
	}
	
	*newEntryCount = successCount;
	return completeSuccess;
}

- (void) dropboxImport:(DropBoxDialog*)aDialog didEndDialog:(NSInteger)result contents:(NSArray*)contents
{
	if ( result == NSRunAbortedResponse )
	{
		for ( NSDictionary *aDictionary in contents ) 
		{
			NSString *aCompletePath = [aDictionary objectForKey:@"representedObject"];
			
			NSString *movedPath = [NSString stringWithFormat:@"- %@",[aCompletePath lastPathComponent]];
			NSString *completeMovedPath = [[aCompletePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:movedPath];
			
			if ( [[NSFileManager defaultManager] fileExistsAtPath:aCompletePath] && ![[NSFileManager defaultManager] movePath:aCompletePath toPath:completeMovedPath handler:nil] )
				NSLog(@"%s - file still existed after import and could not be removed", __PRETTY_FUNCTION__);
		}
	}
	
	// return to the previous application
	if ( ![[[aDialog activeApplication] objectForKey:@"NSApplicationName"] isEqualToString:@"Journler"] )
	[[NSWorkspace sharedWorkspace] launchApplication:[[aDialog activeApplication] objectForKey:@"NSApplicationName"]];
	[aDialog performSelector:@selector(close) withObject:nil afterDelay:0.1];
	
	if ( result == NSRunStoppedResponse )
	{
		// now perform the imports, putting up the notice
		IntegrationCopyFiles *notice = [[IntegrationCopyFiles alloc] init];
		[notice setNoticeText:NSLocalizedString(@"reading dropbox",@"")];
		[notice runNotice];
		
		NSInteger successCount;
		BOOL completeSuccess = YES;
		NSArray *targetTags = [aDialog tags];
		NSString *targetCategory = [aDialog category];
		NSArray *targetFolders = [aDialog selectedFolders];
		 /* = [aDialog selectedFolder];*/
		
		
		JournlerEntry *firstSelection = nil;
		NSFileManager *fm = [NSFileManager defaultManager];
		
        for ( NSDictionary *aDictionary in contents )
		{
			NSString *aCompletePath = [aDictionary objectForKey:@"representedObject"];
			JournlerEntry *anImport = [self importFile:aCompletePath operation:kNewResourceForceCopy];
			
			if ( anImport == nil )
			{
				completeSuccess = NO;
				NSLog(@"%s - unable to produce entry for file at path %@", __PRETTY_FUNCTION__, aCompletePath);
				
				// note the problem with a minus sign
				NSString *movedPath = [NSString stringWithFormat:@"- %@",[aCompletePath lastPathComponent]];
				NSString *completeMovedPath = [[aCompletePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:movedPath];
				
				if ( [fm fileExistsAtPath:aCompletePath] && ![fm movePath:aCompletePath toPath:completeMovedPath handler:nil] )
					NSLog(@"%s - file still existed after import and could not be removed", __PRETTY_FUNCTION__);
				
			}
			else
			{
				// set the title on the resource and associated entry
				NSString *aTitle = [aDictionary objectForKey:@"title"];
				[anImport setValue:aTitle forKey:@"title"];
				
				if ( [[anImport resources] count] != 0 )
					[[[anImport resources] objectAtIndex:0] setValue:aTitle forKey:@"title"];
				
				if ( targetTags != nil )
					[anImport setValue:targetTags forKey:@"tags"];
					
				if ( targetCategory != nil )
					[anImport setValue:targetCategory forKey:@"category"];
				//else
				//	[anImport setValue:[JournlerEntry dropBoxCategory]];
				
				if ( targetFolders != nil )
				{
                    for ( JournlerCollection *targetFolder in targetFolders )
					{
						if ( [targetFolder isRegularFolder] )
							[targetFolder addEntry:anImport];
						else if ( [targetFolder isSmartFolder] && [targetFolder canAutotag:anImport] )
							[targetFolder autotagEntry:anImport add:YES];
					}
				}
				
				// if the file still exists at the path, check it off
				NSString *movedPath = [NSString stringWithFormat:@"+ %@",[aCompletePath lastPathComponent]];
				NSString *completeMovedPath = [[aCompletePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:movedPath];
				
				if ( [fm fileExistsAtPath:aCompletePath] && ![fm movePath:aCompletePath toPath:completeMovedPath handler:nil] )
					NSLog(@"%s - file still existed after import and could not be removed", __PRETTY_FUNCTION__);
				
				// note the first selection
				if ( firstSelection == nil )
					firstSelection = anImport;
				
				successCount++;
			}
		}
		
		[notice endNotice];
		[notice release];
		
		// let the user know if there was a problem
		if ( completeSuccess == NO )
			[[NSAlert dropboxError] runModal];
		else
			[(NSSound*)[NSSound soundNamed:@"dropbox"] play];
			
		// select an import
		if ( firstSelection != nil )
			[[[self journalWindowController] selectedTab] selectEntries:[NSArray arrayWithObject:firstSelection]];
	}
	
	dropBoxing = NO;
}

- (void) dropboxScriptCommand:(DropBoxDialog*)aDialog didEndDialog:(NSInteger)result contents:(NSArray*)contents
{
	// return to the previous application
	if ( ![[[aDialog activeApplication] objectForKey:@"NSApplicationName"] isEqualToString:@"Journler"] )
	[[NSWorkspace sharedWorkspace] launchApplication:[[aDialog activeApplication] objectForKey:@"NSApplicationName"]];
	[aDialog performSelector:@selector(close) withObject:nil afterDelay:0.1];
	
	if ( result == NSRunStoppedResponse )
	{
		// now perform the imports, putting up the notice
		IntegrationCopyFiles *notice = [[IntegrationCopyFiles alloc] init];
		[notice setNoticeText:NSLocalizedString(@"reading dropbox",@"")];
		[notice runNotice];
		
		NSInteger successCount;
		BOOL completeSuccess = YES;
		BOOL deleteOriginalFile = [aDialog shouldDeleteOriginal];
		NSArray *targetTags = [aDialog tags];
		NSString *targetCategory = [aDialog category];
		NSArray *targetFolders = [aDialog selectedFolders];
		 /* = [aDialog selectedFolder];*/
		
        JournlerEntry *firstSelection = nil;
        NSFileManager *fm = [NSFileManager defaultManager];
		
		for ( NSDictionary *aDictionary in contents )
		{
			NSString *aCompletePath = [aDictionary objectForKey:@"representedObject"];
			JournlerEntry *anImport = [self importFile:aCompletePath operation:kNewResourceForceCopy];
			
			if ( anImport == nil )
			{
				completeSuccess = NO;
				NSLog(@"%s - unable to produce entry for file at path %@", __PRETTY_FUNCTION__, aCompletePath);
			}
			else
			{
				// set the title on the entry and the resource
				NSString *aTitle = [aDictionary objectForKey:@"title"];
				[anImport setValue:aTitle forKey:@"title"];
				
				if ( [[anImport resources] count] != 0 )
					[[[anImport resources] objectAtIndex:0] setValue:aTitle forKey:@"title"];
				
				if ( targetTags != nil )
					[anImport setValue:targetTags forKey:@"tags"];
					
				if ( targetCategory != nil )
					[anImport setValue:targetCategory forKey:@"category"];
				//else
				//	[anImport setValue:NSLocalizedString(@"dropbox category",@"") forKey:@"category"];
				
				if ( targetFolders != nil )
				{
                    for ( JournlerCollection *targetFolder in targetFolders )
					{
						if ( [targetFolder isRegularFolder] )
							[targetFolder addEntry:anImport];
						else if ( [targetFolder isSmartFolder] && [targetFolder canAutotag:anImport] )
							[targetFolder autotagEntry:anImport add:YES];
					}
				}
				
				// if the file still exists at the path, check it off
				//NSString *movedPath = [NSString stringWithFormat:@"+ %@",[aCompletePath lastPathComponent]];
				//NSString *completeMovedPath = [[aCompletePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:movedPath];
				
				if ( [fm fileExistsAtPath:aCompletePath] && deleteOriginalFile && ![fm removeFileAtPath:aCompletePath handler:nil] )
					NSLog(@"%s - file could not be deleted at path %@", __PRETTY_FUNCTION__, aCompletePath);
				
				// note the first selection
				if ( firstSelection == nil )
					firstSelection = anImport;
				
				successCount++;
			}
		}
		
		[notice endNotice];
		[notice release];
		
		// let the user know if there was a problem
		if ( completeSuccess == NO )
			[[NSAlert dropboxError] runModal];
		else
			[(NSSound*)[NSSound soundNamed:@"dropbox"] play];
			
		// select an import
		if ( firstSelection != nil )
			[[[self journalWindowController] selectedTab] selectEntries:[NSArray arrayWithObject:firstSelection]];
	}
	
	else
	{
		// delete all those files anyway if we're supposed to
		if ( [aDialog shouldDeleteOriginal] )
		{
            NSFileManager *fm = [NSFileManager defaultManager];
			
            for ( NSDictionary *aDictionary in contents )
			{
				NSString *aCompletePath = [aDictionary objectForKey:@"representedObject"];
				
				if ( [fm fileExistsAtPath:aCompletePath] && ![fm removeFileAtPath:aCompletePath handler:nil] )
					NSLog(@"%s - file could not be deleted at path %@", __PRETTY_FUNCTION__, aCompletePath);
			}
		}
	}
	
	dropBoxing = NO;
}

// move the items to the trash
- (void) cleanupDropBox:(NSString*)path
{
	//NSFileManager *fm = [NSFileManager defaultManager];
	NSArray *contents = [[NSFileManager defaultManager] directoryContentsAtPath:path];
	
	NSString *aPath;
	NSString *aCompletePath;
	NSEnumerator *enumerator;
	NSMutableArray *validPaths;

	// first derive the valid paths
	enumerator = [contents objectEnumerator];
	validPaths = [NSMutableArray array];
	
	while ( aPath = [enumerator nextObject] )
	{
		if ( [aPath length] == 0 || [aPath characterAtIndex:0] == '.' || [aPath isEqualToString:@"Icon\r"] )
			continue;
		
		aCompletePath = [path stringByAppendingPathComponent:aPath];
		[validPaths addObject:aCompletePath];
	}
	
	// bail if there isn't anything to import
	if ( [validPaths count] != 0 )
	{
		enumerator = [validPaths objectEnumerator];
		while ( aCompletePath = [enumerator nextObject] )
			[[NSWorkspace sharedWorkspace] moveToTrash:aCompletePath];
	}
}


#pragma mark -

- (void) fadeOutAllWindows:(NSArray*)excluding
{
	NSMutableArray *allDictionaries = [NSMutableArray array];
   
    for ( NSWindow *aWindow in [NSApp windows] )
	{
		if ( [excluding containsObject:aWindow] )
			continue;
		
		NSDictionary *aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
		 aWindow, NSViewAnimationTargetKey,
		 NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey, nil];
		 
		[allDictionaries addObject:aDictionary];
	}
	
	NSViewAnimation *animation = [[[NSViewAnimation alloc] initWithViewAnimations:allDictionaries] autorelease];
	[animation setDuration:0.25];
	[animation startAnimation];

}

- (void) fadeInAllWindows:(NSArray*)excluding
{
	NSMutableArray *allDictionaries = [NSMutableArray array];

    for ( NSWindow *aWindow in [NSApp windows] )
	{
		if ( [excluding containsObject:aWindow] )
			continue;
		
		NSDictionary *aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
		 aWindow, NSViewAnimationTargetKey,
		 NSViewAnimationFadeInEffect, NSViewAnimationEffectKey, nil];
		 
		[allDictionaries addObject:aDictionary];
	}
	
	NSViewAnimation *animation = [[[NSViewAnimation alloc] initWithViewAnimations:allDictionaries] autorelease];
	[animation setDuration:0.25];
	[animation startAnimation];
}

#pragma mark -

- (IBAction) runFileImporter:(id)sender
{
	BOOL dir;
	NSInteger result;
	NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	
	[oPanel setCanChooseDirectories:YES];
    [oPanel setAllowsMultipleSelection:YES];
	[oPanel setPrompt:NSLocalizedString(@"choose button",@"")];
	
    result = [oPanel runModalForDirectory:nil file:nil types:nil];
    if (result != NSOKButton)
		return;
	
	NSArray *filesToOpen = nil;
	NSArray *selectedFiles = [oPanel filenames];
	
	if ( [selectedFiles count] == 1 && 
			[[NSFileManager defaultManager] fileExistsAtPath:[selectedFiles objectAtIndex:0] isDirectory:&dir] && dir && 
			![[NSWorkspace sharedWorkspace] isFilePackageAtPath:[selectedFiles objectAtIndex:0]] )
	{
        //DIRECTORY_ENUMERATION
		// if a single directory is selected, send the directory's contents to the importer
		NSString *aPath, *theDirectoryPath = [selectedFiles objectAtIndex:0];
		NSMutableArray *anArray = [[[NSMutableArray alloc] init] autorelease];
		
		NSEnumerator *enumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:theDirectoryPath] objectEnumerator];
		while ( aPath = [enumerator nextObject] )
			[anArray addObject:[theDirectoryPath stringByAppendingPathComponent:aPath]];
		
		filesToOpen = anArray;
	}
	else
	{
		// otherwise, send the selected files
		filesToOpen = selectedFiles;
	}
	
	// get the selected folder
	JournlerCollection *theSelectedFolder = nil;
	NSArray *frontSelectedFolders = [[mainWindowIgnoringActive selectedTab] selectedFolders];
	if ( [frontSelectedFolders count] > 0 ) theSelectedFolder = [frontSelectedFolders objectAtIndex:0];
	
	// run the import
	[self importFilesWithImporter:filesToOpen folder:theSelectedFolder userInteraction:YES];
	
	// post a notification that we've just finished a file import
	[[NSNotificationCenter defaultCenter] postNotificationName:JournlerDidFinishImportNotification object:self userInfo:nil];
}

- (BOOL) importFilesWithImporter:(NSArray*)filenames folder:(JournlerCollection*)targetFolder userInteraction:(BOOL)visual 
{
	NSInteger result;
		
	BulkImportController *importer;
	ImportReviewController *reviewer;
	
	NSMutableArray*importedFolders = [[[NSMutableArray alloc] init] autorelease];
	NSMutableArray *importedEntries = [[[NSMutableArray alloc] init] autorelease];

	// launch the importer
	importer = [[[BulkImportController alloc] initWithJournal:[self journal]] autorelease];
	
	// initial folder
	if ( targetFolder != nil && ( [targetFolder isRegularFolder] || ( [targetFolder isSmartFolder] && [targetFolder canAutotag:nil] ) ) )
		[importer setTargetCollection:targetFolder];
	
	// run the dialog
	[importer setUserInteraction:visual];
	result = [importer runAsSheetForWindow:nil attached:NO files:filenames folders:&importedFolders entries:&importedEntries];
	if ( result != NSRunStoppedResponse )
		return NO;
	
	// insert a separator 
	[importedFolders insertObject:[JournlerCollection separatorFolder] atIndex:0];
	
	// insert a library folder which contains all of the imported entries
	JournlerCollection *libraryFolder = [[[JournlerCollection alloc] init] autorelease];
	
	[libraryFolder setTypeID:[NSNumber numberWithInteger:PDCollectionTypeIDLibrary]];
	[libraryFolder setTitle:[[[self journal] libraryCollection] title]];
	[libraryFolder setIcon:[[[self journal] libraryCollection] icon]];
	[libraryFolder setEntries:importedEntries];
	
	[importedFolders insertObject:libraryFolder atIndex:0];
	
	// launch the bulk import review
	reviewer = [[[ImportReviewController alloc] 
			initWithJournal:[self journal] 
			folders:importedFolders 
			entries:importedEntries] autorelease];
	
	[reviewer setUserInteraction:visual];
	[reviewer setPreserveModificationDate:[importer preserveModificationDate]];
	
	result = [reviewer runAsSheetForWindow:nil attached:NO targetCollection:[importer targetCollection]];
	
	//if ( result != NSRunStoppedResponse )
	//	return NO;
		
	// save the journal
	//[self save:self];
	
	return YES;
}

#pragma mark -

- (void) dayDidChange:(NSTimer*)aTimer
{
	[self regenerateDynamicDatePredicates];
}

- (void) computerDidWake:(NSNotification*)aNotification 
{
	if ( [[[aNotification userInfo] objectForKey:PDPowerManagementMessage] integerValue] == PDPowerManagementPoweredOn )
	{
		[self regenerateDynamicDatePredicates];
	}
}

- (void) _preferencesDidEndEditing:(NSNotification*)aNotification
{
	// get the new value, compare it to the old value, reset the timer if necessary
	
	NSInteger saveInterval = [[NSUserDefaults standardUserDefaults] integerForKey:@"Auto Save Time"];
	if ( saveInterval == 0 )
		saveInterval = 8;
	
	if ( saveInterval != ( [autosaveTimer timeInterval] * 60 ) )
	{
		[autosaveTimer invalidate];
		[autosaveTimer release];
		
		autosaveTimer = [[NSTimer scheduledTimerWithTimeInterval:( 60 * saveInterval ) 
		target:self selector:@selector(performAutosave:) userInfo:nil repeats:YES] retain];
    }
}

- (void) regenerateDynamicDatePredicates
{
	//#warning put up a progress indicator?
	
    for ( JournlerCollection *aFolder in [self valueForKeyPath:@"journal.collections"] )
	{
		if ( [aFolder generateDynamicDatePredicates:NO] )
		{
			[aFolder invalidatePredicate:YES];
			[aFolder evaluateAndAct:[self valueForKeyPath:@"journal.entries"] considerChildren:YES];
		}
	}
}

#pragma mark -

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag 
{
	if ( lockout == NO )
	{
		// first check for full screen controllers
		BOOL hasFullScreen = NO;
		
        for ( NSWindowController *aController in [[NSApp windows] valueForKey:@"windowController"] )
		{
			if ( [aController respondsToSelector:@selector(isFullScreenController)] )
			{
				hasFullScreen = YES;
				break;
			}
		}
		
		if ( hasFullScreen == NO && [[journalWindowController window] isVisible] == NO )
			[journalWindowController showWindow:self];
	}
	
	
	return NO;
}

- (void)applicationDidUnhide:(NSNotification *)aNotification 
{
	if ( lockout && lockoutController != nil )
	{
		[lockoutController unhide:self];
	}
}

#pragma mark -

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	
	if ( [[self journal] isLoaded] )
	{
		// let the journal know we are shutting down properly
		[[self journal] setValue:[NSNumber numberWithBool:YES] forKey:@"shutDownProperly"];
		// write the journal store
		[self saveJournal:self];
	}
	
	// clean out the drop box
	[self cleanupDropBox:[[self journal] dropBoxPath]];
	
	// take down some stuff
	//[CURLHandle curlGoodbye];
	[[NSSpellChecker sharedSpellChecker] closeSpellDocumentWithTag:[self spellDocumentTag]];
	
	// sync the preferences
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	// disinvert the display
	if ( displayInverted )
		[self toggleLowLightDisplay:self];
	
	// disable the speech recognizer
	if ( speechRecognizer != nil )
		[speechRecognizer stopListening];
}

- (IBAction) performQuit:(id)sender
{
	// call terminate
	[NSApp terminate:sender];
}

/*
#pragma mark -

- (BOOL)exceptionHandler:(NSExceptionHandler *)sender shouldHandleException:(NSException *)exception mask:(NSUInteger)aMask
{
	return YES;
}

- (BOOL)exceptionHandler:(NSExceptionHandler *)sender shouldLogException:(NSException *)exception mask:(NSUInteger)aMask
{
	#warning see about emailing this trace
	[exception printStackTrace];
	return YES;
}
*/

#pragma mark -

- (NSString *)applicationIdentifier
{    
	return @"com.phildow.journler";
}

/*
- (BOOL)iMediaBrowser:(iMediaBrowser *)browser willLoadBrowser:(NSString *)browserClassname
{
	return YES;
}
 */

#pragma mark -

- (IBAction) save:(id)sender
{
	// equivalent to performing an autosave
	[[NSNotificationCenter defaultCenter] postNotificationName:PDAutosaveNotification object:self userInfo:nil];
}

- (IBAction) saveJournal:(id)sender
{
	// inital state
	NSError *error = nil;
	
	// save the main window state
	if ( journalWindowController != nil )
		[[self journal] setValue:[journalWindowController valueForKey:@"stateData"] forKey:@"tabState"];
		
	if ( ![[self journal] save:&error] )
	{
		NSLog(@"%s - error saving journal", __PRETTY_FUNCTION__);
		NSBeep();
		if ( error != nil )
			[journalWindowController presentError:error];
		else
			[[NSAlert saveError] runModal];
	}
}

- (void) performAutosave:(NSTimer*)aTimer
{
	[[NSNotificationCenter defaultCenter] postNotificationName:PDAutosaveNotification object:self userInfo:nil];
}

#pragma mark -

- (JournalLoadFlag) loadJournal {
	
	//
	// Actually loads the journal and search manager,
	// typically performed after the app has started or a file has been requested
	// checking of course for password and encryption protection
	//
	
	NSInteger jError = 0;
	JournalLoadFlag loadResult;
	
	//#warning check error codes
	NSString *journalLocation = [[[NSUserDefaults standardUserDefaults] stringForKey:@"Default Journal Location"] stringByStandardizingPath];
	
	// and load the journal
	loadResult = [sharedJournal loadFromPath:journalLocation error:&jError];
	
	if ( loadResult & kJournalNoSearchIndex )
	{
		if ( wasFirstRun ) 
		{
			// if this is the first journal and the error is a search error, reindex the entries
			[sharedJournal resetSearchManager];
		}
		else 
		{
			NSLog(@"%s - encountered entries index error, requesting action", __PRETTY_FUNCTION__);
			NSBeep();
			NSInteger result = [[NSAlert noSearchIndex] runModal];
			
			if ( result == NSAlertFirstButtonReturn ) 
			{
				NSLog(@"%s - resetting search index per user request", __PRETTY_FUNCTION__);
				//#warning put up a progress indicator
				[sharedJournal resetSearchManager];
			}
			else 
			{
				NSLog(@"%s - search disabled per user request", __PRETTY_FUNCTION__);
			}
		}
	}
	
	else if ( loadResult & kJournalWantsUpgrade )
	{
		if ( jError & kJournalWants250Upgrade )
		{
			NSLog(@"%s - journal wants 250 upgrade", __PRETTY_FUNCTION__);
			
			JournalUpgradeController *upgrader = [[JournalUpgradeController alloc] init];
			[upgrader run210To250Upgrade:[self journal]];
			[upgrader release];

		}
	}
	
	else if ( jError ) 
	{
		
		// possible jErrors
		//	PDNoJournalAtPath				- ask for new folder
		//	PDJournalFormatTooOld			- tell the user that the upgrade cannot proceed (first 1.17)
		//	PDUnreadableProperties			- something wrong with the journal plist
		//	PDJournalStoreAndPathFailure	- screwed somewhere, but not sure what happened
		
		// encountered an error loading the journal
		NSLog(@"%s - unable to load journal, asking user to locate journal or create a new one", __PRETTY_FUNCTION__);
		
		if  ( jError & PDJournalFormatTooOld )
		{
			NSBeep();
			NSInteger aResult = [[NSAlert journalFormatPre117] runModal];
			
			if ( aResult == NSAlertSecondButtonReturn ) // load the download page
				[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://journler.com/download/"]];
			
			[NSApp terminate:self];
			return loadResult;
		}
		
		NSInteger result = [[NSAlert criticalLoadError] runModal];
		
		if ( result == JournlerLoadErrorQuit ) 
		{
			NSLog(@"%s - quitting after error", __PRETTY_FUNCTION__);
			[NSApp terminate:self];
			return loadResult;
		}
		
		else if ( result == JournlerLoadErrorCreate ) 
		{
			// set up a new journal at the default path, backing up any journal already there?
			int	newError;
	
			//NSString *newPath = [[self applicationSupportFolder] stringByAppendingPathComponent:@"Journler"];
			NSString *newPath = [[self documentsFolder] stringByAppendingPathComponent:@"Journler"];
			
			NSLog(@"%s - attempting to create journal at path %@", __PRETTY_FUNCTION__, newPath);
			
			// make sure the user wants to proceeed of that path exists
			if ( [[NSFileManager defaultManager] fileExistsAtPath:newPath] ) 
			{
				NSLog(@"%s - found old journal at this path, asking user for further instructions", __PRETTY_FUNCTION__);
				
				NSBeep();
				NSInteger result = [[NSAlert overwritePreviousJournal] runModal];
				
				if ( result != NSAlertFirstButtonReturn ) 
				{
					NSLog(@"%s - user chose not to overwrite the old journal, quitting", __PRETTY_FUNCTION__);
					[NSApp terminate:self];
					return loadResult;
				}
				
				NSLog(@"%s - user chose to overwrite the old journal, proceeding with setup", __PRETTY_FUNCTION__);
				
			}
			
			// destroy the preferences at the old path if they exist
			//NSString	*oldPrefsPath = [@"~/Library/Preferences/com.phildow.journler.plist" stringByExpandingTildeInPath];
			//if ( [[NSFileManager defaultManager] fileExistsAtPath:oldPrefsPath] ) 
			//{
			//	NSLog(@"%s - found old preferences, removing them", __PRETTY_FUNCTION__);
			//	[[NSFileManager defaultManager] removeFileAtPath:oldPrefsPath handler:nil];
			//}
		
			
			// destroy the journal at the old path if it exists
			if ( [[NSFileManager defaultManager] fileExistsAtPath:newPath] ) 
			{
				NSLog(@"%s - found old journal, removing it", __PRETTY_FUNCTION__);
				[[NSFileManager defaultManager] removeFileAtPath:newPath handler:nil];
			}
			
			//
			// handle setup at this path
			if ( ![self handleSetup:newPath] ) 
			{
				// yet another error! at this point, it's too critical
				NSString *errorString = @"setup error";
				NSRunCriticalAlertPanel(@"Critical Error", NSLocalizedString( errorString, @""), nil,nil,nil);
				NSLog(@"%s - critical error setuping up journal, must quit", __PRETTY_FUNCTION__);
				[NSApp terminate:self];
				
			}
			else
			{
				wasFirstRun = YES;
				[[NSUserDefaults standardUserDefaults] setObject:newPath forKey:@"Default Journal Location"];
				//[[NSUserDefaults standardUserDefaults] synchronize];
			}
			
			//
			// initialize a new journal
			[sharedJournal loadFromPath:newPath error:&newError];
			if ( newError ) 
			{
				
				// yet another error! at this point, it's too critical
				NSLog(@"%s could't load journal, user requested new journal, still unable to load journal, quitting", __PRETTY_FUNCTION__);
				NSString *errorString = [NSString stringWithFormat:@"creation error %i", newError];
				NSRunCriticalAlertPanel(@"Critical Error", NSLocalizedString( errorString, @""), nil,nil,nil);
				[NSApp terminate:self];
				
			}
			
			// success, so set the new default path
			[[NSUserDefaults standardUserDefaults] setObject:[newPath stringByStandardizingPath] forKey:@"Default Journal Location"];
			[[NSUserDefaults standardUserDefaults] setObject:[sharedJournal title] forKey:@"Journler Journal Title"];
			
			NSLog(@"%s - setup completed with new journal", __PRETTY_FUNCTION__);
			
		}
		
		else if ( result == JournlerLoadErrorLocate ) 
		{
			// release the old journal, load with a new path, setup, make sure to set the shared journals like wake from nib
			
			NSInteger result;
			NSInteger newError;
			NSArray *filenames;
			NSOpenPanel *op = [NSOpenPanel openPanel];
			
			[op setCanChooseFiles:NO];
			[op setCanChooseDirectories:YES];
			[op setAllowsMultipleSelection:NO];
			[op setResolvesAliases:YES];
			
			[op setTitle:NSLocalizedStringFromTable(@"load error locate title", @"LoadError", @"")];
			[op setMessage:NSLocalizedStringFromTable(@"load error locate message", @"LoadError", @"")];
			
			result = [op runModalForDirectory:[self documentsFolder] file:@"Journler" types:nil];
			
			if ( result == NSCancelButton )
			{
				NSLog(@"%s - quitting after user cancelled locate request", __PRETTY_FUNCTION__);
				[NSApp terminate:self];
				return loadResult;
			}
			
			filenames = [op filenames];
			if ( !filenames || [filenames count] == 0 )
			{
				NSLog(@"%s - quitting after user cancelled locate request", __PRETTY_FUNCTION__);
				[NSApp terminate:self];
				return loadResult;
			}
			
			NSString *newPath = [filenames objectAtIndex:0];
			NSLog(@"%s - attempting to load journal at path %@", __PRETTY_FUNCTION__, newPath);
			
			// initialize a new journal
			[sharedJournal loadFromPath:newPath error:&newError];
			if ( newError ) 
			{
				// yet another error! at this point, it's too critical
				NSLog(@"%s - could't load journal, user specified different location, still unable to load journal, quitting", __PRETTY_FUNCTION__);
				NSString *errorString = [NSString stringWithFormat:@"creation error %i", newError];
				NSRunCriticalAlertPanel(@"Critical Error", NSLocalizedString( errorString, @""), nil,nil,nil);
				[NSApp terminate:self];
				#warning give the user all the options she would have on a first pass load
			}
			
			// success, so set the new default path and journal title
			[[NSUserDefaults standardUserDefaults] setObject:[newPath stringByStandardizingPath] forKey:@"Default Journal Location"];
			[[NSUserDefaults standardUserDefaults] setObject:[sharedJournal title] forKey:@"Journler Journal Title"];
			
			NSLog(@"%s - setup completed with old journal at user defined location", __PRETTY_FUNCTION__);
			
		}
	}
	
	// we made it all the way through, check for updates
	if ( [[sharedJournal version] integerValue] < 253 )
	{
		// remove unused variables, clear folder icons
		JournalUpgradeController *upgradeController = [[[JournalUpgradeController alloc] init] autorelease];
		[upgradeController perform250To253Upgrade:sharedJournal];
	}
	
	
	// -------------------------------------
	// move the journal out of app support to library if necessary: 2.5.4 for Leopard reasons (Spotlight)
	/*
	NSString *journalPath = [[self journal] journalPath];
	NSString *journalParentFolder = [journalPath stringByDeletingLastPathComponent];
	NSString *journlerPlist = [journalPath stringByAppendingPathComponent:PDJournalPropertiesLoc];
	NSString *userAppSupport = [self applicationSupportFolder];
	
	if ( [userAppSupport isEqualToString:journalParentFolder] && [[NSFileManager defaultManager] fileExistsAtPath:journlerPlist] )
	{
		BOOL success = NO;
		JournalUpgradeController *upgrader = [[JournalUpgradeController alloc] init];
		success = [upgrader moveJournalOutOfApplicationSupport:[self journal]];
		[upgrader release];
	}
	*/
	
	return loadResult;
}

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error movingItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath
{
	NSLog(@"%s - error moving at from %@ to %@, error: %@", __PRETTY_FUNCTION__, srcPath, dstPath, error);
	return NO;
}

- (BOOL)fileManager:(NSFileManager *)manager shouldProceedAfterError:(NSDictionary *)errorInfo
{
	NSLog(@"%s - file manager error: %@", __PRETTY_FUNCTION__, errorInfo);
	return NO;
}

- (BOOL) handleSetup:(NSString*)path 
{
	NSLog(@"%s - running Journler setup...", __PRETTY_FUNCTION__);
	
	// do nothing on a nil path
	if ( path == nil )
	{
		NSLog(@"%s - nil path, bailing", __PRETTY_FUNCTION__);
		return NO;
	}
	
	NSInteger c;
	
	NSNumber *unique_id;
	NSString *user_name = nil, *journal_title;
	
	NSFont *defaultEntryFont = [NSFont fontWithName:@"Georgia" size:12.0];
	if ( defaultEntryFont == nil ) 
		defaultEntryFont = [NSFont userFontOfSize:12.0];
	
	NSFont *defaultControlFont = [NSFont controlContentFontOfSize:11.0];
	if ( defaultControlFont == nil ) 
		defaultControlFont = [NSFont userFontOfSize:11.0];
	
	// Default Fonts
	NSArray *font_values = [[[NSArray alloc] initWithObjects:
			defaultEntryFont,		/* entry text font */
			defaultControlFont,		/* browser font */
			defaultControlFont,		/* folders font */
			defaultControlFont,		/* references font */
			nil] autorelease];
	
	NSArray *font_keys = [[[NSArray alloc] initWithObjects:
			@"DefaultEntryFont", 
			@"BrowserTableFont", 
			@"FoldersTableFont", 
			@"ReferencesTableFont", 
			nil] autorelease];
			
	
	// Highlight and Other Colors
	NSArray *highlight_values = [[[NSArray alloc] initWithObjects:
			[NSColor yellowColor],	// yellow highlight
			[NSColor blueColor],	// blue highlight
			[NSColor greenColor],	// green highlight
			[NSColor orangeColor],	// orange highlight
			[NSColor redColor],		// red highlight
			[NSColor blueColor],	// blue underline color
			[NSColor colorWithCalibratedWhite:0.75 alpha:1.0],	// header label
			[NSColor blackColor],	// header text
			[NSColor whiteColor],	// header background
			[NSColor whiteColor],	// entry background
			nil] autorelease];
	
	NSArray *highlight_keys = [[[NSArray alloc] initWithObjects:
			@"highlightYellow", 
			@"highlightBlue", 
			@"highlightGreen", 
			@"highlightOrange", 
			@"highlightRed", 
			@"EntryTextLinkColor",
			@"HeaderLabelColor",
			@"HeaderTextColor",
			@"HeaderBackgroundColor",
			@"EntryBackgroundColor",
			nil] autorelease];
	
	
	// the journal must know where the path is for archiving the entries and collections
	[sharedJournal setJournalPath:path];
	
	
	// what's the journal's title = for the plist
	user_name = NSFullUserName();
	if ( !user_name ) user_name = NSUserName();
	if ( !user_name ) user_name = @"New User";
	
	// the journal title
	journal_title = [user_name stringByAppendingString:@"'s Journal"];
	
	// create the new journal data, but only if no data already exists at this location
	if ( [[NSFileManager defaultManager] fileExistsAtPath:path] ) 
	{
		NSLog(@"%s - journal data already exists at %@, will attempt to load from that information", __PRETTY_FUNCTION__, path);
		
		// I should really split this into two functions:
		//	a. initialize the journal
		//	b. initialize the preferences
	}
	
	else
	{
		
		BOOL zipInstalSuccess = NO;
		NSString *zippedDefaultJournalPath = [[NSBundle mainBundle] pathForResource:@"DefaultJournal" ofType:@"zip"];
		if ( zippedDefaultJournalPath != nil )
		{
			// unzip the default journal directly to the application support folder
			if ( ![ZipUtilities unzipPath:zippedDefaultJournalPath toPath:[path stringByDeletingLastPathComponent]] )
			{
				zipInstalSuccess = NO;
				NSLog(@"%s - unable to unzip default journal to default installation directory", __PRETTY_FUNCTION__);
			}
			else
			{
				NSInteger anError;
				
				zipInstalSuccess = YES;
				NSLog(@"%s - successfully installed default journal", __PRETTY_FUNCTION__);
				
				unique_id = [NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]];
				
				// load up the journal temporarily
				[sharedJournal loadFromPath:path error:&anError];
				
				// set a few properties
				[sharedJournal setIdentifier:unique_id];
				[sharedJournal setTitle:journal_title];
				
				// reset the search manager
				[sharedJournal resetSearchManager];
				
				// prepare the wordlist
				NSString *wordlistDestination = [[sharedJournal journalPath] stringByAppendingPathComponent:PDJournalWordListLoc];
				NSString *wordlistSource = [[NSBundle mainBundle] pathForResource:@"AutoCorrectWordPairs" ofType:@"csv"];
				
				if ( wordlistSource != nil && wordlistDestination != nil && 
						![[NSFileManager defaultManager] copyPath:wordlistSource toPath:wordlistDestination handler:self] )
				{
					NSLog(@"%s - unable to copy wordlist from %@ to %@\n\n", __PRETTY_FUNCTION__, wordlistSource, wordlistDestination);
				}
				
				// a few entries will need modifying
				[[sharedJournal entries] setValue:[NSCalendarDate calendarDate] forKey:@"calDate"];
				[[sharedJournal entries] setValue:[NSCalendarDate calendarDate] forKey:@"calDateModified"];
				
				// the due date entry
				JournlerEntry *duedateExampleEntry = [sharedJournal entryForTagID:[NSNumber numberWithInteger:8]];
				NSCalendarDate *aDuedate = [[NSDate dateWithTimeIntervalSinceNow:(60*60*24*4)] dateWithCalendarFormat:nil timeZone:nil];
				[duedateExampleEntry setCalDateDue:aDuedate];
				
				// reset the icons on each of the folders
                for ( JournlerCollection *aFolder in [sharedJournal collections] )
					[aFolder setValue:[JournlerCollection defaultImageForID:[[aFolder valueForKey:@"typeID"] integerValue]] forKey:@"icon"];
				
				// save the changes
				[sharedJournal save:nil];
				
				// close the shared journal and re-alloc it
				[[sharedJournal searchManager] closeIndex];
				[sharedJournal release];
				
				sharedJournal = [[JournlerJournal alloc] init];
				[sharedJournal setOwner:self];
				
			}
		}
		
		
		if ( zipInstalSuccess == NO )
		{
			// fall back on the default installation
			NSLog(@"%s - unable to locate DefaultJournal.zip in application bundle", __PRETTY_FUNCTION__);
		
			BOOL didLoadSearchIndex;
			JournlerEntry *general_entry = nil;
			//JournlerResource *websiteResource = nil, *purchaseResource = nil, *termsResource = nil, *entriesResource = nil, *mediaResource = nil;
			JournlerCollection *journal_collection = nil, *trash_collection = nil;
		
			// actually create the files
			
			// the journal directory
			if ( ![[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil] ) 
			{
				// unable to create the journler directory at the application support folder - ask the user where
				NSLog(@"%s - Could not create support directory at path %@", __PRETTY_FUNCTION__, path);
				return NO;
				
			}
			
			// entries directory
			if ( ![[NSFileManager defaultManager] createDirectoryAtPath:[sharedJournal entriesPath] attributes:nil] ) 
			{
				NSLog(@"%s - Could not create entries directory at path %@", __PRETTY_FUNCTION__, [sharedJournal entriesPath]);
				return NO;
			}
			
			// collections directory
			if ( ![[NSFileManager defaultManager] createDirectoryAtPath:[sharedJournal collectionsPath] attributes:nil] ) 
			{
				NSLog(@"%s - Could not create collections directory at path %@", __PRETTY_FUNCTION__, [sharedJournal collectionsPath]);
				return NO;
			}
			
			// the blogs directory
			if ( ![[NSFileManager defaultManager] createDirectoryAtPath:[sharedJournal blogsPath] attributes:nil] ) 
			{
				NSLog(@"%s - Could not create blogs directory at path %@", __PRETTY_FUNCTION__, [sharedJournal blogsPath]);
				return NO;
			}
			
			// the resources directory
			if ( ![[NSFileManager defaultManager] createDirectoryAtPath:[sharedJournal resourcesPath] attributes:nil] )
			{
				NSLog(@"%s - Could not create resources directory at path %@", __PRETTY_FUNCTION__, [sharedJournal resourcesPath]);
				return NO;
			}
			
			
			// the journal's unique id
			unique_id = [NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]];
			
			// Prepare the three default entries
			//----------------------------------------------------------------
			
			NSCalendarDate *date_today = [NSCalendarDate calendarDate];
			
			// the general tutorial
			NSString *tutorial_general_path = [[NSBundle mainBundle] pathForResource:@"TutorialGeneral" ofType:@"xml"];
			NSMutableDictionary *tutorial_general_dic = [NSMutableDictionary dictionaryWithContentsOfFile:tutorial_general_path];
			
			// unique id
			[tutorial_general_dic setObject:unique_id forKey:PDJournalIdentifier];
			
			// date and time
			[tutorial_general_dic setObject:date_today forKey:PDEntryCalDate];
			[tutorial_general_dic setObject:date_today forKey:PDEntryCalDateModified];
			
			// localized title, category and keywords
			[tutorial_general_dic setObject:NSLocalizedString(@"tutorial general title",@"") forKey:PDEntryTitle];
			[tutorial_general_dic setObject:NSLocalizedString(@"tutorial category",@"") forKey:PDEntryCategory];
			[tutorial_general_dic setObject:NSLocalizedString(@"tutorial keywords",@"") forKey:PDEntryKeywords];
			
			// Grab the localized version of the default entry and set it
			NSString *general_content_path = [[NSBundle mainBundle] pathForResource:@"WelcomeEntry" ofType:@"rtfd"];
			NSAttributedString *general_content = [[[NSAttributedString alloc] initWithPath:general_content_path documentAttributes:nil] autorelease];
			
			if ( general_content == nil )
			{
				NSLog(@"%s - Could not load TutorialGeneral.rtfd", __PRETTY_FUNCTION__);
			}
			else 
			{
				[tutorial_general_dic setObject:general_content forKey:PDEntryAtttibutedContent];
			}
			
			general_entry = [[[JournlerEntry alloc] initWithProperties:tutorial_general_dic] autorelease];
			if ( general_entry == nil ) 
			{
				NSLog(@"%s - could not create the general tutorial entry", __PRETTY_FUNCTION__);
			}
			else
			{
				// add the entry to the journal
				[sharedJournal addEntry:general_entry];
				
				// add a couple of resources to the entry
				//if ( ( websiteResource = [general_entry resourceForURL:@"http://journler.com" title:@"journler.com"] ) == nil )
				//	NSLog(@"%s - could not create journler.com resource for general entry", __PRETTY_FUNCTION__);
				//if ( ( purchaseResource = [general_entry resourceForURL:@"http://journler.com/purchase/" title:@"donate/purchase"] ) == nil )
				//	NSLog(@"%s - could not create donations and licensing resource for general entry", __PRETTY_FUNCTION__);
			}
			
			// prepare the two resources, "editing entries" and "using media" - not added until the directories have all been created
			//NSString *termsOfUsePath = [[NSBundle mainBundle] pathForResource:@"Terms of Use" ofType:@"pdf"];
			//NSString *entriesTutorialPath = [[NSBundle mainBundle] pathForResource:@"Editing Entries" ofType:@"pdf"];
			//NSString *mediaTutorialPath = [[NSBundle mainBundle] pathForResource:@"Media" ofType:@"pdf"];
			
			// prepare the journal collection
			NSString *journal_collection_path = [[NSBundle mainBundle] pathForResource:@"JournalCollection" ofType:@"xml"];
			NSMutableDictionary *journal_collection_dic = [NSMutableDictionary dictionaryWithContentsOfFile:journal_collection_path];
			
			journal_collection = [[[JournlerCollection alloc] initWithProperties:journal_collection_dic] autorelease];
			if ( journal_collection == nil ) 
			{
				NSLog(@"%s - could not create the journal collection", __PRETTY_FUNCTION__);
			}
			else
			{
				// set the image on the journal dictionary
				[journal_collection determineIcon];
				// add the collection to the journal
				[sharedJournal addCollection:journal_collection];
			}
			
			
			// prepare the trash collection
			NSString *trash_collection_path = [[NSBundle mainBundle] pathForResource:@"TrashCollection" ofType:@"xml"];
			NSMutableDictionary *trash_collection_dic = [NSMutableDictionary dictionaryWithContentsOfFile:trash_collection_path];
			
			trash_collection = [[[JournlerCollection alloc] initWithProperties:trash_collection_dic] autorelease];
			if ( trash_collection == nil ) 
			{
				NSLog(@"%s - could not create the trash collection", __PRETTY_FUNCTION__);
			}
			else
			{
				// set the image and title the tutorial dictionary
				[trash_collection determineIcon];
				[trash_collection setTitle:NSLocalizedString(@"collection trash title",@"")];
				// add the collection to the journal
				[sharedJournal addCollection:journal_collection];
			}
			
			
			// prepare the journal plist
			NSString *journal_plist_path = [[NSBundle mainBundle] pathForResource:@"JournalPList" ofType:@"xml"];
			NSMutableDictionary *journal_plist_dic = [NSMutableDictionary dictionaryWithContentsOfFile:journal_plist_path];
			if ( journal_plist_dic == nil ) 
			{
				NSLog(@"%s- could not create the journal property list", __PRETTY_FUNCTION__);
			}
			
			// set the title and the identifier
			[journal_plist_dic setObject:journal_title forKey:PDJournalTitle];
			[journal_plist_dic setObject:unique_id forKey:PDJournalIdentifier];
					
			[sharedJournal setProperties:journal_plist_dic];
			
			// Create the support directory and write the initial journal data
			// ---------------------------------------------------------------
			
			// prepare the wordlist
			NSString *wordlistDestination = [[sharedJournal journalPath] stringByAppendingPathComponent:PDJournalWordListLoc];
			NSString *wordlistSource = [[NSBundle mainBundle] pathForResource:@"AutoCorrectWordPairs" ofType:@"csv"];
			
			
			
			// the search index
			if ( ![[sharedJournal searchManager] createIndexAtPath:path] ) 
			{
				NSLog(@"%s - Could not create journal search index at path %@", __PRETTY_FUNCTION__, path);
			}
			else 
			{
				if ( ![[sharedJournal searchManager] loadIndexAtPath:path] )
				{
					didLoadSearchIndex = NO;
					NSLog(@"%s - Could not load journal search index at path %@", __PRETTY_FUNCTION__, path);
				}
				else
				{
					didLoadSearchIndex = YES;
				}
			}
			
			// the word list
			if ( wordlistSource != nil && wordlistDestination != nil && 
					![[NSFileManager defaultManager] copyPath:wordlistSource toPath:wordlistDestination handler:self] )
			{
				NSLog(@"%s - unable to copy wordlist from %@ to %@\n\n", __PRETTY_FUNCTION__, wordlistSource, wordlistDestination);
			}
			
			// save the entry
			[sharedJournal saveEntry:general_entry];
			
			// add those two tutorial resources
			//if ( termsOfUsePath == nil || ( termsResource = [general_entry resourceForFile:termsOfUsePath operation:kNewResourceForceCopy] ) == nil )
			//	NSLog(@"%s - problem creating terms of use resource", __PRETTY_FUNCTION__);
			//if ( entriesTutorialPath == nil || ( entriesResource = [general_entry resourceForFile:entriesTutorialPath operation:kNewResourceForceCopy] ) == nil )
			//	NSLog(@"%s - problem creating entries tutorial resource", __PRETTY_FUNCTION__);
			//if ( mediaTutorialPath == nil || ( mediaResource = [general_entry resourceForFile:mediaTutorialPath operation:kNewResourceForceCopy] ) == nil )
			//	NSLog(@"%s - problem creating media tutorial resource", __PRETTY_FUNCTION__);
			
			// save the resources
			//[sharedJournal saveResource:websiteResource];
			//[sharedJournal saveResource:purchaseResource];
			//[sharedJournal saveResource:termsResource];
			//[sharedJournal saveResource:entriesResource];
			//[sharedJournal saveResource:mediaResource];
			
			// save the journal
			[sharedJournal save:nil];
			
			if ( didLoadSearchIndex )
			{	
				[[sharedJournal searchManager] indexEntry:general_entry];
				[[sharedJournal searchManager] closeIndex];
			}
		}
	}
	
	// Prepare the original default values
	//----------------------------------------------------------------
	
	NSMutableDictionary *standard_defaults;
	NSString *path_to_defaults = [[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"xml"];
	
	if ( path_to_defaults != nil )
	{
		standard_defaults = [NSMutableDictionary dictionaryWithContentsOfFile:path_to_defaults];
		if ( standard_defaults == nil )
		{
			standard_defaults = [NSMutableDictionary dictionary];
			NSLog(@"%s - problem initializing the standard defaults from path %@", __PRETTY_FUNCTION__, path_to_defaults);
		}
	}
	else
	{
		standard_defaults = [NSMutableDictionary dictionary];
		NSLog(@"%s - unable to locate the standard defaults file \"defaults.xml\"", __PRETTY_FUNCTION__);
	}
	
	[standard_defaults setObject:journal_title forKey:@"Journler Journal Title"];
	[standard_defaults setObject:[path stringByStandardizingPath] forKey:@"Default Journal Location"];
	[standard_defaults setObject:journal_title forKey:@"Default Album"];
	[standard_defaults setObject:NSFullUserName() forKey:@"Default Artist"];
	
	//Fonts and Colors
	for ( c = 0; c < [font_keys count]; c++ )
		[standard_defaults setObject:
		[NSArchiver archivedDataWithRootObject:[font_values objectAtIndex:c]] forKey:[font_keys objectAtIndex:c]];
	
	for ( c = 0; c < [highlight_keys count]; c++ )
		[standard_defaults setObject:
		[NSArchiver archivedDataWithRootObject:[highlight_values objectAtIndex:c]] forKey:[highlight_keys objectAtIndex:c]];
	
	// localized categories
	NSString *localized_categories_string = NSLocalizedString(@"localized categories", @"");
	NSArray *localized_categories_array = [localized_categories_string componentsSeparatedByString:@","];
	
	//NSString *localized_default_category = NSLocalizedString(@"localized default category",@"");
	
	[standard_defaults setObject:localized_categories_array forKey:@"Journler Categories List"];
	[standard_defaults setObject:@"-" forKey:@"Journler Default Category"];
	[standard_defaults setObject:@"-" forKey:@"Drop Box Category"];
	
	// the journal path
	[standard_defaults setObject:path forKey:@"Default Journal Location"];
	
	//and write out this entire temporary dictionary to user defaults
    for ( NSString *key in [standard_defaults allKeys] )
		[[NSUserDefaults standardUserDefaults] setObject:[standard_defaults objectForKey:key] forKey:key];
	
	// and immediately afterwards register our initial defaults
	//[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:standard_defaults];
	[[NSUserDefaults standardUserDefaults] registerDefaults:standard_defaults];
	//[[NSUserDefaults standardUserDefaults] synchronize];
	
	NSLog(@"%s - completed Journler setup", __PRETTY_FUNCTION__);
	return YES;
}

#pragma mark -
#pragma mark Window Menu

- (IBAction) showJournal:(id)sender
{
	[journalWindowController showWindow:self];
}

- (IBAction) showContactsBrowser:(id)sender
{
	[[AddressPanelController sharedAddressPanelController] showWindow:self];
}

- (IBAction) showMediaBrowser:(id)sender
{
	 NSBeep();
    [[NSAlert alertWithMessageText:@"The Media Browser has been disabled but may be re-enabled in a later beta update." 
                     defaultButton:@"OK"
                   alternateButton:nil
                       otherButton:nil 
         informativeTextWithFormat:@""] runModal];
   
    //[[iMediaBrowser sharedBrowserWithDelegate:self] showWindow:self];
}

- (IBAction) showCorrespondenceBrowser:(id)sender
{
	//[[TypedDocumentViewer sharedViewer] showViewer];
	return;
}

- (IBAction) showEntryBrowser:(id)sender
{
	[[QuickLinkController sharedController] setValue:[self valueForKey:@"journal"] forKey:@"journal"];
	[[QuickLinkController sharedController] showWindow:self];
}

- (IBAction) showPreferences:(id)sender
{
	//[[PrefWindowController sharedController] setJournal:[self valueForKey:@"journal"]];
	//[[PrefWindowController sharedController] showWindow:self];
	
	PrefWindowController *prefsController = (PrefWindowController*)[NSApp singletonControllerWithClass:[PrefWindowController class]];
	if ( prefsController == nil )
	{
		prefsController = [[[PrefWindowController alloc] init] autorelease];
		[prefsController setJournal:[self journal]];
	}
	[prefsController showWindow:self];
}

- (IBAction) showAboutBox:(id)sender
{
	[[PDAboutBoxController sharedController] showWindow:self];
}

- (IBAction) donate:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://journler.com/purchase/"]];
}

#pragma mark -
#pragma mark Help Menu

- (IBAction) showPlugInHelp:(id)sender
{
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"Plugins" inBook:@"JournlerHelp"];
}

- (IBAction) showKeyboardShortcuts:(id)sender
{
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"JournlerShortcuts" inBook:@"JournlerHelp"];
}

- (IBAction) reportBug:(id)sender
{
	NSDictionary *localInfoDictionary = (NSDictionary *)CFBundleGetLocalInfoDictionary( CFBundleGetMainBundle() );
	NSString *shortVersion = [localInfoDictionary objectForKey:@"CFBundleShortVersionString"];
	
	NSString *address = @"support@journler.com";
	NSString *subject = [NSString stringWithFormat:@"Journler Bug Report (v%@)",shortVersion];
	NSString *bugReport = NSLocalizedString(@"bug report", @"");
	
	//[JUtility sendRichMail:[[[NSAttributedString alloc] initWithString:bugReport] autorelease] 
	//to:address subject:subject isMIME:NO withNSMail:NO];
	
	[JournlerApplicationDelegate sendRichMail:[[[NSAttributedString alloc] initWithString:bugReport] autorelease] 
	to:address subject:subject isMIME:NO withNSMail:NO];
}

- (IBAction) gotoWiki:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://wiki.journler.com"]];
}

- (IBAction) gotoHelpForum:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://journler.com/community/forums/"]];
}

#pragma mark -
#pragma mark Make a Recording

- (IBAction) recordAudio:(id)sender
{
	// convert over some of the user default values (2.5.4 -> 2.5.5)
	if ( [[NSUserDefaults standardUserDefaults] stringForKey:@"DefaultAlbum"] == nil )
		[[NSUserDefaults standardUserDefaults] setObject:[[NSUserDefaults standardUserDefaults] stringForKey:@"Default Album"] 
				forKey:@"DefaultAlbum"];
	if ( [[NSUserDefaults standardUserDefaults] stringForKey:@"DefaultArtist"] == nil )
		[[NSUserDefaults standardUserDefaults] setObject:[[NSUserDefaults standardUserDefaults] stringForKey:@"Default Artist"] 
				forKey:@"DefaultArtist"];
	if ( [[NSUserDefaults standardUserDefaults] stringForKey:@"DefaultPlaylist"] == nil )
		[[NSUserDefaults standardUserDefaults] setObject:[[NSUserDefaults standardUserDefaults] stringForKey:@"Default Playlist"] 
				forKey:@"DefaultPlaylist"];
	
	// note the recording title and date
	NSString *recordingTitle;
	NSCalendarDate *recordingDate;
	
	JournlerEntry *theGoodEntry = nil;
	id theGoodTarget = [NSApp targetForAction:@selector(entryForRecording:) to:nil from:self];
	
	if ( theGoodTarget != nil && ( ( theGoodEntry = [theGoodTarget entryForRecording:self] ) != nil ) )
	{
		recordingTitle = [theGoodEntry valueForKey:@"title"];
		recordingDate = [theGoodEntry valueForKey:@"calDate"];
	}
	else
	{
		recordingTitle = NSLocalizedString(@"untitled title",@"");
		recordingDate = [NSCalendarDate calendarDate];
	}
	
	NSDictionary *recordingAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
			recordingTitle, kSproutedAudioRecordingTitleKey,
			recordingDate, kSproutedAudioRecordingDateKey, nil];
	
	
	[[SproutedAVIController sharedController] setDelegate:self];
	[[SproutedAVIController sharedController] showWindow:self];
	[[[SproutedAVIController sharedController] window] setTitle:NSLocalizedString(@"Journler AVI", @"")];
	
	[[SproutedAVIController sharedController] setAudioRecordingAttributes:recordingAttributes];
	[[SproutedAVIController sharedController] recordAudio:self];
}

- (IBAction) recordVideo:(id)sender
{
	[[SproutedAVIController sharedController] setDelegate:self];
	[[SproutedAVIController sharedController] showWindow:self];
	[[[SproutedAVIController sharedController] window] setTitle:NSLocalizedString(@"Journler AVI", @"")];
	[[SproutedAVIController sharedController] recordVideo:self];
}

- (IBAction) captureSnapshot:(id)sender
{
	[[SproutedAVIController sharedController] setDelegate:self];
	[[SproutedAVIController sharedController] showWindow:self];
	[[[SproutedAVIController sharedController] window] setTitle:NSLocalizedString(@"Journler AVI", @"")];
	[[SproutedAVIController sharedController] takeSnapshot:self];
}

#pragma mark -

- (NSNumber*) validateYourself:(SproutedAVIController*)aController
{
	NSBundle *framework = [NSBundle bundleWithIdentifier:@"com.sprouted.avi"];
	NSString *executablePath = [framework executablePath];
	
	NSNumber *executableSize = [[[NSFileManager defaultManager] 
			fileAttributesAtPath:executablePath 
			traverseLink:NO]
			objectForKey:NSFileSize];
	
	return executableSize;
}

#pragma mark -

- (IBAction) toggleContinuousSpellcheckingAppwide:(id)sender
{
	BOOL value = [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryTextEnableSpellChecking"];
	[[NSUserDefaults standardUserDefaults] setBool:!value forKey:@"EntryTextEnableSpellChecking"];
}

- (IBAction) toggleLowLightDisplay:(id)sender
{
	CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)55, true); // command
	CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)58, true); // option
	CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)59, true); // ctrl
	//CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)56, true); // shift
	
	CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)28, true); // number 8
	CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)28, false);
	
	//CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)56, false); // shift
	CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)59, false);
	CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)58, false);
	CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)55, false);
	
	displayInverted = !displayInverted;
}

- (IBAction) lockJournal:(id)sender
{
	// save the journal
	[self saveJournal:sender];
	
	BOOL confirmed;
	NSString *confirmedPassword;
	lockoutController = nil;
	
	NSInteger i;
	NSMutableArray *visibleWindows;
	NSWindow *keyWindow;
	
	NSString *journalProtectedPath = [[[self journal] journalPath] stringByAppendingPathComponent:PDJournalPasswordProtectedLoc];
	if ( ![[NSFileManager defaultManager] fileExistsAtPath:journalProtectedPath] )
	{
		NSLog(@"%s - no password protection file at expected path %@", __PRETTY_FUNCTION__, journalProtectedPath);
		NSBeep();
		return;
	}
	
	NSError *error = nil;
	NSString *md5checksum = [NSString stringWithContentsOfFile:journalProtectedPath encoding:NSUnicodeStringEncoding error:&error];
	if ( md5checksum == nil || [md5checksum length] == 0 )
	{
		NSLog(@"%s - no checksum for file at path %@, error %@", __PRETTY_FUNCTION__, journalProtectedPath, error);
		NSBeep();
		return;
	}
	
	// let the app know we are going lockout
	lockout = YES;
	
	// note our visible windows;
	visibleWindows = [[NSMutableArray alloc] init];
	for ( i = 0; i < [[NSApp windows] count]; i++ ) {
		if ( [[[NSApp windows] objectAtIndex:i] isVisible] )
			[visibleWindows addObject:[[NSApp windows] objectAtIndex:i]];
	}
	
	// I need to note the key window as well
	keyWindow = [NSApp keyWindow];
	
	// Hide our windows
	[NSApp makeWindowsPerform:@selector(orderOut:) inOrder:YES];
	
	// disable the menus
	for ( i = 0; i < [[NSApp mainMenu] numberOfItems]; i++ )
	{
		[[[NSApp mainMenu] itemAtIndex:i] setEnabled:NO];
	}
	
	// check for the option key to bring also hide the rest of the application
	if ( GetCurrentKeyModifiers() & optionKey )
	{
		[NSApp hide:self];
	}
	
	// put the lockout controller on the screen
	lockoutController = [[[LockoutController alloc] initWithChecksum:md5checksum] autorelease];
	[lockoutController enableLockedOutControls:self];
	
	confirmed = [lockoutController confirmChecksum];
	confirmedPassword = [lockoutController validatedPassword];
	
	if ( !confirmed )
	{
		[NSApp terminate:self];
	}
	else
	{
		// close the lockout controller
		[lockoutController close];
		
		//re-enable the menus
		for ( i = 0; i < [[NSApp mainMenu] numberOfItems]; i++ )
			[[[NSApp mainMenu] itemAtIndex:i] setEnabled:YES];
		
		// reactivate those windows
		for ( i = [visibleWindows count]-1; i >= 0; i-- )
			[[visibleWindows objectAtIndex:i] orderFront:self];
		
		// and bring our former key window to the front
		[keyWindow makeKeyAndOrderFront:self];
		
		// clean up
		[visibleWindows release];
		lockoutController = nil;
		
		lockout = NO;
		
		// if files are waiting in the drop box, run it
		if ( dropBoxIsWaiting == YES )
		{
			NSInteger fileCount;
			dropBoxing = YES;
			BOOL visually = defaultBool(@"UseVisualAidWherePossibleWhenImporting");
			BOOL success = [self _importContentsOfDropBox:waitingDropBoxPaths visually:visually filesAffected:&fileCount];
			 
			if ( !success )
			{
				// put up an alert
				NSLog(@"%s - problems importing some items from the drop box", __PRETTY_FUNCTION__);
				NSBeep();
				[[NSAlert dropboxError] runModal];
			}
			
			// clean up
			[waitingDropBoxPaths release];
			waitingDropBoxPaths = nil;
			dropBoxIsWaiting = NO;
		}
	}
}

- (IBAction) toggleSpeakableItems:(id)sender
{
	if ( speechRecognizer ) 
	{
		[speechRecognizer stopListening];
		[speechRecognizer release];
		speechRecognizer = nil;
	}
	else 
	{
		NSArray *cmds = [[[NSArray alloc] initWithObjects:
				@"Create New Entry", @"Create New Tab", @"Create New Folder", @"Create New Smart Folder",
				@"New Tab with this Entry", @"New Window with this Entry",
				@"Email Selection", @"Blog this Entry", @"Print Selection",@"Export Selection", 
				@"Send Entry to iWeb", @"Send Entry to iPod", 
				@"Record Audio", @"Record Video", @"Take a Picture", @"Show Media", @"Show Contacts",
				@"Import Files", @"Print Journal",  @"Export Journal",
				@"Go to Tomorrow", @"Go to Today", @"Go to Yesterday", @"Go to Previous Month", @"Go to Next Month",
				@"Save", @"Close Window",
				nil] autorelease];
		
        speechRecognizer = [[NSSpeechRecognizer alloc] init];
        [speechRecognizer setCommands:cmds];
        [speechRecognizer setDelegate:self];
		[speechRecognizer startListening];
	}
}

- (void)speechRecognizer:(NSSpeechRecognizer *)sender didRecognizeCommand:(id)aCmd 
{	
	NSString *command = (NSString*)aCmd;
	
	// Creating New Objects --------------------------------------------------------
	
    if ([command isEqualToString:@"Create New Entry"])
		[NSApp sendAction:@selector(newEntry:) to:nil from:self];
	  
	else if ([command isEqualToString:@"Create New Tab"])
		[NSApp sendAction:@selector(newTab:) to:nil from:self];
		
	else if ([command isEqualToString:@"Create New Folder"])
		[NSApp sendAction:@selector(newFolder:) to:nil from:self];
		
	else if ([command isEqualToString:@"Create New Smart Folder"])
		[NSApp sendAction:@selector(newSmartFolder:) to:nil from:self];
	
	
	// Working with an Entry --------------------------------------------------------
	
	else if ([command isEqualToString:@"New Tab with this Entry"])
		[NSApp sendAction:@selector(openEntryInNewTab:) to:nil from:self];

	else if ([command isEqualToString:@"New Window with this Entry"])
		[NSApp sendAction:@selector(openEntryInNewWindow:) to:nil from:self];


	else if ([command isEqualToString:@"Blog this Entry"])
		[NSApp sendAction:@selector(blogDocument:) to:nil from:self];
		
	else if ([command isEqualToString:@"Email Selection"])
		[NSApp sendAction:@selector(emailDocument:) to:nil from:self];

	else if ([command isEqualToString:@"Print Selection"])
		[NSApp sendAction:@selector(printDocument:) to:nil from:self];

	else if ([command isEqualToString:@"Export Selection"])
		[NSApp sendAction:@selector(exportSelection:) to:nil from:self];
		

	else if ( [command isEqualToString:@"Send Entry to iWeb"])
		[NSApp sendAction:@selector(sendEntryToiWeb:) to:nil from:self];
	
	else if ([command isEqualToString:@"Send Entry to iPod"])
		[NSApp sendAction:@selector(sendEntryToiPod:) to:nil from:self];
		
	
	// Adding media an Entry --------------------------------------------------------
	
	else if ([command isEqualToString:@"Record Audio"])
		[NSApp sendAction:@selector(recordAudio:) to:nil from:self];
	
	else if ([command isEqualToString:@"Record Video"])
		[NSApp sendAction:@selector(recordVideo:) to:nil from:self];
		
	else if ([command isEqualToString:@"Take a Picture"])
		[NSApp sendAction:@selector(captureSnapshot:) to:nil from:self];
		
	else if ([command isEqualToString:@"Show Media"])
		[NSApp sendAction:@selector(showMediaBrowser:) to:nil from:self];
	
	else if ([command isEqualToString:@"Show Contacts"])
		[NSApp sendAction:@selector(showContactsBrowser:) to:nil from:self];
		
	
	// Bulk Operations --------------------------------------------------------
	
	else if ([command isEqualToString:@"Import Files"])
		[NSApp sendAction:@selector(runFileImporter:) to:nil from:self];
		
	else if ([command isEqualToString:@"Print Journal"])
		[NSApp sendAction:@selector(printJournal:) to:nil from:self];
	
	else if ([command isEqualToString:@"Export Journal"])
		[NSApp sendAction:@selector(exportJournal:) to:nil from:self];
	
	
	// Calendar Navigation --------------------------------------------------------
	
	else if ([command isEqualToString:@"Go to Today"])
		[NSApp sendAction:@selector(toToday:) to:nil from:self];
		
	else if ([command isEqualToString:@"Go to Tomorrow"])
		[NSApp sendAction:@selector(dayToRight:) to:nil from:self];
		
	else if ([command isEqualToString:@"Go to Yesterday"])
		[NSApp sendAction:@selector(dayToLeft:) to:nil from:self];
		
	else if ([command isEqualToString:@"Go to Next Month"])
		[NSApp sendAction:@selector(monthToRight:) to:nil from:self];
		
	else if ([command isEqualToString:@"Go to Previous Month"])
		[NSApp sendAction:@selector(monthToLeft:) to:nil from:self];
	
	
	// File Commands --------------------------------------------------------
	
	else if ([command isEqualToString:@"Close Window"])
		[NSApp sendAction:@selector(performClose:) to:nil from:self];
	
	else if ([command isEqualToString:@"Save"])
		[NSApp sendAction:@selector(save:) to:nil from:self];
	
}

#pragma mark -

- (IBAction) doPageSetup:(id) sender 
{
	NSPageLayout *pageLayout = [NSPageLayout pageLayout];
	[pageLayout setAccessoryView:[[PageSetupController sharedPageSetup] contentView]];
	
	if ( [[journalWindowController window] isMainWindow] )
		[pageLayout beginSheetWithPrintInfo:[NSPrintInfo sharedPrintInfo] modalForWindow:[journalWindowController window] 
				delegate:nil didEndSelector:nil contextInfo:nil];
	else
		[pageLayout runModalWithPrintInfo:[NSPrintInfo sharedPrintInfo]];
}

- (IBAction) printJournal:(id)sender
{
	NSInteger result;
	PrintJournalController *printController = [[[PrintJournalController alloc] init] autorelease];
	
	[printController setDateFrom:[NSCalendarDate calendarDate]];
	[printController setDateTo:[NSCalendarDate calendarDate]];
	
	result = [printController runAsSheetForWindow:[journalWindowController window] attached:NO];
	if ( result != NSRunStoppedResponse ) 
		return;
	
	// the user set a few preferences for printing the journal
	NSInteger printMode = [printController printMode];
	NSDate *fromDate = [printController dateFrom];
	NSDate *toDate = [printController dateTo];
	
	// grab the shared printer info
	NSPrintInfo *sharedPI = [[[NSPrintInfo sharedPrintInfo] copyWithZone:[self zone]] autorelease];
	
	[sharedPI setHorizontalPagination:NSFitPagination];
	[sharedPI setHorizontallyCentered:NO];
	[sharedPI setVerticallyCentered:NO];
	
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"PrintHeader"] == NO && [[NSUserDefaults standardUserDefaults] boolForKey:@"PrintFooter"] == NO )
		[[sharedPI dictionary] setValue:[NSNumber numberWithBool:NO] forKey:NSPrintHeaderAndFooter];
	else
		[[sharedPI dictionary] setValue:[NSNumber numberWithBool:YES] forKey:NSPrintHeaderAndFooter];
	
	// determine view size
	NSInteger width = [sharedPI paperSize].width - ( [sharedPI rightMargin] + [sharedPI leftMargin] );
	NSInteger height = [sharedPI paperSize].height - ( [sharedPI topMargin] + [sharedPI bottomMargin] );
	
	// create a view with that information
	PDPrintTextView *printView = [[[PDPrintTextView alloc] initWithFrame:NSMakeRect(0,0,width,height)] autorelease];
	
	// set a few properties for the print job
	[printView setPrintTitle:[self valueForKeyPath:@"journal.title"]];
	[printView setPrintHeader:[[NSUserDefaults standardUserDefaults] boolForKey:@"PrintHeader"]];
	[printView setPrintFooter:[[NSUserDefaults standardUserDefaults] boolForKey:@"PrintFooter"]];
	
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateStyle:NSDateFormatterLongStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	
	[printView setPrintDate:[dateFormatter stringFromDate:[NSDate date]]];
	
	// exactly what itemts are printed?
	BOOL wTitle = [[NSUserDefaults standardUserDefaults] boolForKey:@"PrintEntryTitle"];
	BOOL wCategory = [[NSUserDefaults standardUserDefaults] boolForKey:@"PrintEntryCategory"];
	BOOL wDate = [[NSUserDefaults standardUserDefaults] boolForKey:@"PrintEntryDate"];
	
	NSInteger i;
	NSSortDescriptor *descriptor = [[[NSSortDescriptor alloc] initWithKey:@"calDate" ascending:YES] autorelease];
	NSArray *entriesArray = [[self valueForKeyPath:@"journal.entries"] sortedArrayUsingDescriptors:[NSArray arrayWithObject:descriptor]];
	
	for ( i = 0; i < [entriesArray count]; i++ ) 
	{
		JournlerEntry *anEntry = [entriesArray objectAtIndex:i];
		
		// do not print if the entry is in the trash
		if ( [[anEntry valueForKey:@"markedForTrash"] boolValue] ) 
			continue;
		
		// only print the entry if it falls in the range of the specified dates
		NSDate *entryDate = [anEntry valueForKey:@"calDate"];
		if ( [entryDate compare:fromDate] != NSOrderedAscending && [entryDate compare:toDate] != NSOrderedDescending ) 
		{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			// handle the entry's text
			NSAttributedString *preppedEntry = [[entriesArray objectAtIndex:i] prepWithTitle:wTitle category:wCategory smallDate:wDate];
			
			//text only or pictures as well?
			if ( printMode == kPrintModeText )
				[printView replaceCharactersInRange:NSMakeRange([[printView string] length],0) 
						withRTF:[preppedEntry RTFFromRange:NSMakeRange(0, [[preppedEntry string] length]) documentAttributes:nil]];
			else
				[printView replaceCharactersInRange:NSMakeRange([[printView string] length],0) 
						withRTFD:[preppedEntry RTFDFromRange:NSMakeRange(0, [[preppedEntry string] length]) documentAttributes:nil]];
			
			[printView replaceCharactersInRange:NSMakeRange([[printView string] length],0) withString:@"\n\n"];
			[pool release];
		}
	}
	
	//grab the view to print and send it to the printer using the shared printinfo values
	NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView:printView printInfo:sharedPI];
	
	if ( [[journalWindowController window] isMainWindow] )
		[printOperation runOperationModalForWindow: [journalWindowController window] delegate: nil didRunSelector: nil contextInfo: nil];
	else
		[printOperation runOperation];
}

- (IBAction) exportJournal:(id)sender
{
	NSOpenPanel *sp;
	NSInteger runResult;
	
	ExportJournalController *exportController = [[ExportJournalController alloc] init];
	
	// create or get the shared instance of NSSavePanel
	sp = [NSOpenPanel openPanel];
	
	// set up new attributes
	[sp setAccessoryView:[exportController contentView]];
	[sp setCanCreateDirectories:YES];
	[sp setCanChooseDirectories:YES];
	[sp setCanSelectHiddenExtension:YES];
	[sp setCanChooseFiles:NO];
	[sp setMessage:NSLocalizedString(@"export panel text",@"")];
	[sp setTitle:NSLocalizedString(@"export panel title",@"")];
	[sp setPrompt:NSLocalizedString(@"export panel prompt",@"")];
	
	// display the NSSavePanel
	runResult = [sp runModalForDirectory:nil file:[self valueForKeyPath:@"journal.title"] types:nil];

	// if successful, save file under designated name
	if (runResult == NSOKButton) 
	{
		BOOL success = YES;
		
		NSString *rootDir = [sp directory];
		NSDate *fromDate = [exportController dateFrom];
		NSDate *toDate = [exportController dateTo];
		
		BOOL mods_creation_date = [exportController modifiesFileCreationDate];
		BOOL mods_modification_date = [exportController modifiesFileModifiedDate];
		BOOL include_header = [exportController includeHeader];
				
		NSInteger dataFormat = [exportController dataFormat];
		NSInteger folderPref = [exportController fileMode];
		
		NSInteger flags = kEntrySetLabelColor|kEntryDoNotOverwrite;
		if ( include_header )
			flags |= kEntryIncludeHeader;
		if ( mods_creation_date )
			flags |= kEntrySetFileCreationDate;
		if ( mods_modification_date )
			flags |= kEntrySetFileModificationDate;
		if ( [sp isExtensionHidden] )
				flags |= kEntryHideExtension;
		
		//create a year - month - day - entries directory structure, use localized months
		NSArray *monthNames = [[NSUserDefaults standardUserDefaults] objectForKey:NSMonthNameArray];
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		NSInteger i;
		NSSortDescriptor *descriptor = [[[NSSortDescriptor alloc] initWithKey:@"calDate" ascending:YES] autorelease];
		NSPredicate *dateFilter = [NSPredicate predicateWithFormat:@"calDate > %@ && calDate < %@", fromDate, toDate];
		
		NSArray *entriesArray = [[[self valueForKeyPath:@"journal.entries"] filteredArrayUsingPredicate:dateFilter]
				sortedArrayUsingDescriptors:[NSArray arrayWithObject:descriptor]];
		
		if ( folderPref == kExportByFolder || folderPref == kExportBySortedFolders ) 
		{
			for ( i = 0; i < [entriesArray count]; i++ ) 
			{
				NSAutoreleasePool *innerpool = [[NSAutoreleasePool alloc] init];
				JournlerEntry *anEntry = [entriesArray objectAtIndex:i];
				
				// do not export if the entry is in the trash
				if ( [[anEntry valueForKey:@"markedForTrash"] boolValue] ) 
					continue;
				
				NSString *saveLoc;
				NSCalendarDate *entryDate = [anEntry valueForKey:@"calDate"];
				
				// recursive or not?
				if ( folderPref == kExportBySortedFolders ) 
				{
					//make sure we have created folders at this location
					NSString *yearLoc = [rootDir stringByAppendingPathComponent:
							[NSString stringWithFormat:@"%i", [entryDate yearOfCommonEra]]];
					NSString *monthLoc = [yearLoc stringByAppendingPathComponent:
							[NSString stringWithFormat:@"%i %@", [entryDate monthOfYear], [monthNames objectAtIndex:[entryDate monthOfYear]-1]]];
					NSString *dayLoc = [monthLoc stringByAppendingPathComponent:
							[NSString stringWithFormat:@"%i", [entryDate dayOfMonth]]];
										
					if (![fileManager fileExistsAtPath:yearLoc])
						[fileManager createDirectoryAtPath:yearLoc attributes:nil];
					if (![fileManager fileExistsAtPath:monthLoc])
						[fileManager createDirectoryAtPath:monthLoc attributes:nil];
					if (![fileManager fileExistsAtPath:dayLoc])
						[fileManager createDirectoryAtPath:dayLoc attributes:nil];
					
					NSString *title = [anEntry valueForKey:@"title"];
					if ( title == nil || [title length] == 0 ) 
					{
						saveLoc = [dayLoc stringByAppendingPathComponent:NSLocalizedString(@"untitled title", @"")];
					}
					else
					{
						saveLoc = [dayLoc stringByAppendingPathComponent:[anEntry pathSafeTitle]];
					}
				}
				else 
				{
					saveLoc = [rootDir stringByAppendingPathComponent:[anEntry pathSafeTitle]];
				}
				
				if ( saveLoc!= nil )
				{
					[[entriesArray objectAtIndex:i] writeToFile:saveLoc as:dataFormat flags:flags];
				}
				else
				{
					NSLog(@"%s - Unable to save entry: %@ %@", __PRETTY_FUNCTION__, [anEntry valueForKey:@"tagID"], [anEntry title]);
				}
				
				[innerpool release];
			}
		}
		
		else if ( folderPref == kExportBySingleFile ) 
		{
			// put every entry in a single file and save that - much like a single print job.
			
			NSString *filename = [rootDir stringByAppendingPathComponent:[[self valueForKeyPath:@"journal.title"] pathSafeString]];
			
			NSError *error = nil;
			NSString *saveWithExtension;
			NSFileWrapper *rtfWrapper;
					
			NSPrintInfo *printInfo;

			printInfo = [[[NSPrintInfo sharedPrintInfo] copyWithZone:[self zone]] autorelease];
			[printInfo setJobDisposition:NSPrintSaveJob];
			[[printInfo dictionary]  setObject:[filename stringByAppendingPathExtension:@"pdf"] forKey:NSPrintSavePath];

			[printInfo setHorizontalPagination: NSAutoPagination];
			[printInfo setVerticalPagination: NSAutoPagination];
			[printInfo setVerticallyCentered:NO];
			[[printInfo dictionary] setValue:[NSNumber numberWithBool:NO] forKey:NSPrintHeaderAndFooter];
			
			//should give me the width and height
			NSInteger width = [printInfo paperSize].width - ( [printInfo rightMargin] + [printInfo leftMargin] );
			NSInteger height = [printInfo paperSize].height - ( [printInfo topMargin] + [printInfo bottomMargin] );
			
			PDPrintTextView *printView = [[[PDPrintTextView alloc] initWithFrame:NSMakeRect(0,0,width,height)] autorelease];
			
			// set a few properties for the print job
			[printView setPrintHeader:NO];
			[printView setPrintFooter:NO];
			
			// with the header?
			BOOL withHeader = [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryExportIncludeHeader"];
			
			for ( i = 0; i < [entriesArray count]; i++ ) 
			{
				NSAutoreleasePool *innerpool = [[NSAutoreleasePool alloc] init];
				JournlerEntry *anEntry = [entriesArray objectAtIndex:i];
				
				// do not export if the entry is in the trash
				if ( [[anEntry valueForKey:@"markedForTrash"] boolValue] ) 
					continue;
									
				// handle the entry
				NSAttributedString *preppedEntry = [[[entriesArray objectAtIndex:i] 
						prepWithTitle:withHeader category:withHeader smallDate:withHeader] attributedStringWithoutJournlerLinks];
				
				[printView replaceCharactersInRange:NSMakeRange([[printView textStorage] length],0) 
						withRTFD:[preppedEntry RTFDFromRange:NSMakeRange(0, [preppedEntry length]) 
						documentAttributes:nil]];
				
				[printView replaceCharactersInRange:NSMakeRange([[printView textStorage] length],0) withString:@"\n\n"];
				
				[innerpool release];
			}
				
			// with the view ready, determine the format and save accordingly
			
			switch ( dataFormat ) 
			{
				
			case kEntrySaveAsRTF:
				
				saveWithExtension = [[filename stringByAppendingPathExtension:@"rtf"] pathWithoutOverwritingSelf];
				rtfWrapper = [[[NSFileWrapper alloc] initRegularFileWithContents:[[printView textStorage] 
						RTFFromRange:NSMakeRange(0, [[printView textStorage] length]) documentAttributes:nil]] autorelease];

				if ( rtfWrapper == nil || ![rtfWrapper writeToFile:saveWithExtension atomically:YES updateFilenames:YES] ) 
				{
					NSLog(@"Unable to write journal to location %@", saveWithExtension);
					success = NO;
				}
			
				break;
			
			case kEntrySaveAsWord:
				
				saveWithExtension = [[filename stringByAppendingPathExtension:@"doc"] pathWithoutOverwritingSelf];
				NSData *docData = [[printView textStorage] docFormatFromRange:NSMakeRange(0, [[printView textStorage] length]) 
						documentAttributes:nil];
				
				if ( docData == nil || ![docData writeToFile:saveWithExtension atomically:YES] ) 
				{
					NSLog(@"Unable to write journal to location %@", saveWithExtension);
					success = NO;
				}

				break;
			
			case kEntrySaveAsRTFD:
				
				saveWithExtension = [[filename stringByAppendingPathExtension:@"rtfd"] pathWithoutOverwritingSelf];
				NSFileWrapper *rtfdWrapper = [[printView textStorage] RTFDFileWrapperFromRange:NSMakeRange(0, [[printView textStorage] length])
						documentAttributes:nil];

				if ( rtfdWrapper == nil || ![rtfdWrapper writeToFile:saveWithExtension atomically:YES updateFilenames:YES] ) 
				{
					NSLog(@"Unable to write journal to location %@", saveWithExtension);
					success = NO;
				}

				break;
			
			case kEntrySaveAsPDF:
				
				saveWithExtension = [[filename stringByAppendingPathExtension:@"pdf"] pathWithoutOverwritingSelf];
				[printView sizeToFit];
				
				NSPrintOperation *printOp = [NSPrintOperation printOperationWithView:printView printInfo:printInfo];
				//[printOp setShowPanels:NO]; DEPRECATED
                [printOp setShowsProgressPanel:NO];
                [printOp setShowsPrintPanel:NO];
				
				if ( ![printOp runOperation] ) 
				{
					NSLog(@"Unable to write journal to location %@", saveWithExtension);
					success = NO;
				}
				
				break;
			
			case kEntrySaveAsHTML:
				
				saveWithExtension = [[filename stringByAppendingPathExtension:@"html"] pathWithoutOverwritingSelf];
				NSString *html_to_export;
				
				if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"ExportsUseAdvancedHTMLGeneration"] )
					html_to_export = [[[printView textStorage] attributedStringWithoutJournlerLinks]
							attributedStringAsHTML:kUseSystemHTMLConversion|kConvertSmartQuotesToRegularQuotes
							documentAttributes:[NSDictionary dictionaryWithObject:[self valueForKeyPath:@"journal.title"] forKey:NSTitleDocumentAttribute]
							avoidStyleAttributes:[[NSUserDefaults standardUserDefaults] stringForKey:@"ExportsNoAttributeList"]];
				
				else
					html_to_export = [[[[printView textStorage] attributedStringWithoutJournlerLinks] attributedStringAsHTML:kUseJournlerHTMLConversion|kConvertSmartQuotesToRegularQuotes 
							documentAttributes:nil avoidStyleAttributes:nil] stringAsHTMLDocument:[self valueForKeyPath:@"journal.title"]];
				
				if ( ![html_to_export writeToFile:saveWithExtension atomically:YES encoding:NSUTF8StringEncoding error:&error] )
				{
					NSLog(@"Unable to write journal to location %@", saveWithExtension);
					success = NO;
				}

				break;
			
			case kEntrySaveAsText:
				
				saveWithExtension = [[filename stringByAppendingPathExtension:@"txt"] pathWithoutOverwritingSelf];
				NSString *textString = [printView string];
							
				if ( ![textString writeToFile:saveWithExtension atomically:YES encoding:NSUnicodeStringEncoding error:&error] )
				{
					NSLog(@"Unable to write journal to location %@", saveWithExtension);
					success = NO;
				}
				
				break;
			
			case kEntrySaveAsWebArchive:
				
				saveWithExtension = [[filename stringByAppendingPathExtension:@"webarchive"] pathWithoutOverwritingSelf];
				NSDictionary *archiveAttributes = [NSDictionary dictionaryWithObject:NSWebArchiveTextDocumentType 
						forKey:NSDocumentTypeDocumentAttribute];
				NSFileWrapper *archiveWrapper = [[printView textStorage] fileWrapperFromRange:NSMakeRange(0,[[printView textStorage] length])
						documentAttributes:archiveAttributes error:&error];
				
				if ( ![archiveWrapper writeToFile:saveWithExtension atomically:YES updateFilenames:YES] )
				{
					NSLog(@"%s - unable to write entry as webarchive to location '%@'", __PRETTY_FUNCTION__, saveWithExtension);
					success = NO;
				}
				
				break;
				
			}
			
			if ( success ) 
			{
				// hide the extension - this overrides the user preference?
				NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] initWithDictionary:
						[[NSFileManager defaultManager] fileAttributesAtPath:saveWithExtension traverseLink:YES]];
						
				[tempDict setObject:[NSNumber numberWithBool:[sp isExtensionHidden]] forKey:@"NSFileExtensionHidden"];
				[[NSFileManager defaultManager] changeFileAttributes:tempDict atPath:saveWithExtension];
				
				[tempDict release];
			}
			else
			{
				// need to be putting up an error
				#warning put up an error here
				if ( error != nil ) [NSApp presentError:error];
				else { ; }
			}
		}
	}
}

#pragma mark -

- (void) prepareLabelMenu:(NSMenu**)aMenu 
{	
	NSMenu *menu = *aMenu;
	
	if ( labelImages == nil )
	{
		// prepare the label images and the array
		NSMutableArray *labelImagesBuilding = [NSMutableArray arrayWithCapacity:8];
		
		// necessary rectangles
		NSRect clearRect = NSMakeRect(0,0,17,16);
			
		NSRect redRect = NSMakeRect(22,0,17,16);
		NSRect orangeRect = NSMakeRect(40,0,17,16);
		NSRect yellowRect = NSMakeRect(58,0,17,16);
		
		NSRect greenRect = NSMakeRect(76,0,17,16);
		NSRect blueRect = NSMakeRect(94,0,17,16);
		NSRect purpleRect = NSMakeRect(112,0,17,16);
		NSRect greyRect = NSMakeRect(130,0,17,16);

		// the entire label image
		NSImage *allLabels = BundledImageWithName(@"labelall.tif", @"com.sprouted.interface");
		
		// individual labels
		NSImage *clearLabel = [[[NSImage alloc] initWithSize:NSMakeSize(17,16)] autorelease];
		NSImage *redLabel = [[[NSImage alloc] initWithSize:NSMakeSize(17,16)] autorelease];
		NSImage *orangeLabel = [[[NSImage alloc] initWithSize:NSMakeSize(17,16)] autorelease];
		NSImage *yellowLabel = [[[NSImage alloc] initWithSize:NSMakeSize(17,16)] autorelease];
		NSImage *greenLabel = [[[NSImage alloc] initWithSize:NSMakeSize(17,16)] autorelease];
		NSImage *blueLabel = [[[NSImage alloc] initWithSize:NSMakeSize(17,16)] autorelease];
		NSImage *purpleLabel = [[[NSImage alloc] initWithSize:NSMakeSize(17,16)] autorelease];
		NSImage *greyLabel = [[[NSImage alloc] initWithSize:NSMakeSize(17,16)] autorelease];
		
		// draw into each individual label
		[clearLabel lockFocus];
		[allLabels drawInRect:clearRect fromRect:clearRect operation:NSCompositeSourceOver fraction:1.0];
		[clearLabel unlockFocus];
		
		[labelImagesBuilding addObject:clearLabel];
		
		[redLabel lockFocus];
		[allLabels drawInRect:clearRect fromRect:redRect operation:NSCompositeSourceOver fraction:1.0];
		[redLabel unlockFocus];
		
		[labelImagesBuilding addObject:redLabel];
		
		[orangeLabel lockFocus];
		[allLabels drawInRect:clearRect fromRect:orangeRect operation:NSCompositeSourceOver fraction:1.0];
		[orangeLabel unlockFocus];
		
		[labelImagesBuilding addObject:orangeLabel];
		
		[yellowLabel lockFocus];
		[allLabels drawInRect:clearRect fromRect:yellowRect operation:NSCompositeSourceOver fraction:1.0];
		[yellowLabel unlockFocus];
		
		[labelImagesBuilding addObject:yellowLabel];
		
		[greenLabel lockFocus];
		[allLabels drawInRect:clearRect fromRect:greenRect operation:NSCompositeSourceOver fraction:1.0];
		[greenLabel unlockFocus];
		
		[labelImagesBuilding addObject:greenLabel];
		
		[blueLabel lockFocus];
		[allLabels drawInRect:clearRect fromRect:blueRect operation:NSCompositeSourceOver fraction:1.0];
		[blueLabel unlockFocus];
		
		[labelImagesBuilding addObject:blueLabel];
		
		[purpleLabel lockFocus];
		[allLabels drawInRect:clearRect fromRect:purpleRect operation:NSCompositeSourceOver fraction:1.0];
		[purpleLabel unlockFocus];
		
		[labelImagesBuilding addObject:purpleLabel];
		
		[greyLabel lockFocus];
		[allLabels drawInRect:clearRect fromRect:greyRect operation:NSCompositeSourceOver fraction:1.0];
		[greyLabel unlockFocus];
		
		[labelImagesBuilding addObject:greyLabel];
		
		labelImages = [labelImagesBuilding copyWithZone:[self zone]];
	
	}
	
	// set the image to our menu items from the two menus
	[[menu itemWithTag:0] setImage:[labelImages objectAtIndex:0]];
	[[menu itemWithTag:1] setImage:[labelImages objectAtIndex:1]];
	[[menu itemWithTag:2] setImage:[labelImages objectAtIndex:2]];
	[[menu itemWithTag:3] setImage:[labelImages objectAtIndex:3]];
	[[menu itemWithTag:4] setImage:[labelImages objectAtIndex:4]];
	[[menu itemWithTag:5] setImage:[labelImages objectAtIndex:5]];
	[[menu itemWithTag:6] setImage:[labelImages objectAtIndex:6]];
	[[menu itemWithTag:7] setImage:[labelImages objectAtIndex:7]];
	
}

- (void) prepareHighlightMenu:(NSMenu**)aMenu 
{
	
	NSMenu *menu = *aMenu;
	
	if ( highlightImages == nil )
	{
		NSMutableArray *theHighlightImages = [NSMutableArray arrayWithCapacity:5];
		
		NSUserDefaults *myDefaults = [NSUserDefaults standardUserDefaults];
		
		// set up the highlight colors
		NSImage *yellowImage = [[[NSImage alloc] initWithSize:NSMakeSize(12,12)] autorelease];
		NSImage *blueImage = [[[NSImage alloc] initWithSize:NSMakeSize(12,12)] autorelease];
		NSImage *greenImage = [[[NSImage alloc] initWithSize:NSMakeSize(12,12)] autorelease];
		NSImage *orangeImage = [[[NSImage alloc] initWithSize:NSMakeSize(12,12)] autorelease];
		NSImage *redImage = [[[NSImage alloc] initWithSize:NSMakeSize(12,12)] autorelease];
		
		NSColor *colorYellow = [myDefaults colorForKey:@"highlightYellow"];
		NSColor *colorBlue = [myDefaults colorForKey:@"highlightBlue"];
		NSColor *colorGreen = [myDefaults colorForKey:@"highlightGreen"];
		NSColor *colorOrange = [myDefaults colorForKey:@"highlightOrange"];
		NSColor *colorRed = [myDefaults colorForKey:@"highlightRed"];
		
		if ( colorYellow == nil ) colorYellow = [NSColor yellowColor];
		if ( colorBlue == nil ) colorBlue = [NSColor blueColor];
		if ( colorGreen == nil ) colorGreen = [NSColor greenColor];
		if ( colorOrange == nil ) colorOrange = [NSColor orangeColor];
		if ( colorRed == nil ) colorRed = [NSColor redColor];
			
		NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(1,1,10,10)];
		
		// 351y 352b 353g 354o 355r
		
		// yellow
		[yellowImage lockFocus];
		[colorYellow set];
		[path fill];
		[[colorYellow shadowWithLevel:0.3] set];
		[path stroke];
		[yellowImage unlockFocus];
		
		[theHighlightImages addObject:yellowImage];
		
		[blueImage lockFocus];
		[colorBlue set];
		[path fill];
		[[colorBlue shadowWithLevel:0.3] set];
		[path stroke];
		[blueImage unlockFocus];
		
		[theHighlightImages addObject:blueImage];
		
		[greenImage lockFocus];
		[colorGreen set];
		[path fill];
		[[colorGreen shadowWithLevel:0.3] set];
		[path stroke];
		[greenImage unlockFocus];
		
		[theHighlightImages addObject:greenImage];
		
		[orangeImage lockFocus];
		[colorOrange set];
		[path fill];
		[[colorOrange shadowWithLevel:0.3] set];
		[path stroke];
		[orangeImage unlockFocus];
		
		[theHighlightImages addObject:orangeImage];
		
		[redImage lockFocus];
		[colorRed set];
		[path fill];
		[[colorRed shadowWithLevel:0.3] set];
		[path stroke];
		[redImage unlockFocus];
		
		[theHighlightImages addObject:redImage];
		
		highlightImages = [theHighlightImages copyWithZone:[self zone]];
	}
	
	[[menu itemWithTag:355] setImage:[highlightImages objectAtIndex:4]];
	[[menu itemWithTag:354] setImage:[highlightImages objectAtIndex:3]];
	[[menu itemWithTag:353] setImage:[highlightImages objectAtIndex:2]];
	[[menu itemWithTag:352] setImage:[highlightImages objectAtIndex:1]];
	[[menu itemWithTag:351] setImage:[highlightImages objectAtIndex:0]];
}

- (NSDictionary*) autoCorrectDictionaryForFileAtPath:(NSString*)filename
{
	NSError *error = nil;
	//#warning would definitely be preferable with the unicode encoding -- need to check on the localization?
	NSString *dictionaryList = [NSString stringWithContentsOfFile:filename usedEncoding:NULL error:&error];
	if ( dictionaryList == nil )
	{
		// try forcing the encoding
		NSInteger i;
		NSStringEncoding encodings[2] = { NSMacOSRomanStringEncoding, NSUnicodeStringEncoding };
		
		for ( i = 0; i < 2; i++ )
		{
			dictionaryList = [NSString stringWithContentsOfFile:filename encoding:encodings[i] error:&error];
			if ( dictionaryList != nil )
				break;
		}

		if ( dictionaryList == nil )
		{
			NSLog(@"%s - problem reading the autocorrect ditionary at path %@, error %@", __PRETTY_FUNCTION__, filename, error);
			return nil;
		}
	}
		
	
    NSArray *wordPairs = [dictionaryList componentsSeparatedByString:@"\r"];
	if ( wordPairs == nil || [wordPairs count] <= 1 )
	{
		wordPairs = [dictionaryList componentsSeparatedByString:@"\n"];
		
		// if pairs are still not available return an empty dictionary
		if ( wordPairs == nil || [wordPairs count] <= 1 )
			return [NSDictionary dictionary];
	}
    
    NSMutableDictionary *pairDictionary = [NSMutableDictionary dictionaryWithCapacity:[wordPairs count]];
	
    for ( NSString *aPair in wordPairs )
	{
		NSArray *theWords = [aPair componentsSeparatedByString:@","];
		if ( [theWords count] != 2 )
		{
			NSLog(@"%s - word pair count not equal to 2: %@", __PRETTY_FUNCTION__, aPair);
			continue;
		}
		
		NSString *incorrectWord = [[theWords objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		NSString *correctWord = [[theWords objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
		if ( [incorrectWord rangeOfString:@","].location != NSNotFound )
		{
			NSLog(@"%s - word pair contains extraneous commas: %@", __PRETTY_FUNCTION__, aPair);
			continue;
		}
		
		if ( [correctWord rangeOfString:@","].location != NSNotFound )
		{
			NSLog(@"%s - word pair contains extraneous commas: %@", __PRETTY_FUNCTION__, aPair);
			continue;
		}
		
		[pairDictionary setObject:correctWord forKey:incorrectWord];
	}
	
	return pairDictionary;
}

- (IBAction) toggleAutoCorrectSpelling:(id)sender
{
	BOOL enabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryTextAutoCorrectSpelling"];
	[[NSUserDefaults standardUserDefaults] setBool:!enabled forKey:@"EntryTextAutoCorrectSpelling"];
}

#pragma mark -
#pragma mark The Console

- (IBAction) showActivity:(id)sender
{
	ActivityViewer *activityViewer = [ActivityViewer sharedActivityViewer];
	[activityViewer setJournal:[self journal]];
	[activityViewer showWindow:self];
}

- (IBAction) runConsole:(id)sender 
{
	// run the command prompt
	ConsoleController *console = [[[ConsoleController alloc] init] autorelease];
	
	[console setDelegate:self];
	[console runAsSheetForWindow:[journalWindowController window] attached:NO];
}

- (NSString*) runConsoleCommand:(NSString*)command 
{
	static NSString *kResetDateModified = @"reset entry date modified";
	static NSString *kSetUserDefault = @"set user default";
	static NSString *kResetSmartFolders = @"reset smart folders";
	static NSString *kCreateResourcesForLinkedFiles = @"create resources for linked files";
	static NSString *kResetFolderIcons = @"reset folder icons";
	static NSString *kRemoveDuplicateLibraryAndTrash = @"remove duplicate library and trash";
	static NSString *kSaveJournal = @"save journal";
	static NSString *kUpdateJournlerResourceTitles = @"update journler resources titles";
	static NSString *kResetResourceText = @"reset resource text";
	static NSString *kResetSearchIndex = @"reset search index";
	static NSString *kInvalidateLicense = @"invalidate license";
	static NSString *kResetRelativePaths = @"reset relative paths";
	static NSString *kActivityViewer = @"activity viewer";
	
	static NSString *kShowOrphanedResources = @"show orphaned resources";
	static NSString *kDeleteOrphanedResources = @"delete orphaned resources";
	
	NSString *returnString = nil;
	
	if ( [command rangeOfString:kResetDateModified options:NSCaseInsensitiveSearch].location != NSNotFound ) 
	{
		if ( [[self journal] resetEntryDateModified] )
			returnString = @"successfully reset date modified property of journal entries";
		else
			returnString = @"unable to reset date modified property of journal entries";
	}
	
	else if ( [command rangeOfString:kInvalidateLicense options:NSCaseInsensitiveSearch].location != NSNotFound )
	{
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LicenseName"];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LicenseCode"];
		
		returnString = @"successfully invalidated license";
	}
	
	else if ( [command rangeOfString:kResetRelativePaths options:NSCaseInsensitiveSearch].location != NSNotFound ) 
	{
		if ( [[self journal] resetRelativePaths] )
			returnString = @"all relative paths for file resources successfully reset";
		else
			returnString = @"some relative paths could not be established, refer to the console log for details";
	}
	
	else if ( [command rangeOfString:kResetSmartFolders options:NSCaseInsensitiveSearch].location != NSNotFound ) 
	{
		if ( [[self journal] resetSmartFolders] )
			returnString = @"smart folders should be reset and contain all relevant entries";
		else
			returnString = @"unable to reset smart folders";
	}
	
	else if ( [command rangeOfString:kActivityViewer options:NSCaseInsensitiveSearch].location != NSNotFound )
	{
		[self showActivity:self];
	}
	
	else if ( [command rangeOfString:kUpdateJournlerResourceTitles options:NSCaseInsensitiveSearch].location != NSNotFound )
	{
		if ( [[self journal] updateJournlerResourceTitles] )
			returnString = @"successfully update journler object resource titles";
		else
			returnString = @"unable to update journler object resources titles";
	}
	
	else if ( [command rangeOfString:kResetResourceText options:NSCaseInsensitiveSearch].location != NSNotFound )
	{
		if ( [[self journal] resetResourceText] )
			returnString = @"successfully reset resource text";
		else
			returnString = @"unable to reset resource text";
	}
	
	else if ( [command rangeOfString:kResetSearchIndex options:NSCaseInsensitiveSearch].location != NSNotFound )
	{
		if ( [[self journal] resetSearchManager] )
			returnString = @"successfully reset search index";
		else
			returnString = @"unable to reset search index";
	}
	
	else if ( [command rangeOfString:kSaveJournal options:NSCaseInsensitiveSearch].location != NSNotFound )
	{
		// mark everything for dirty and save the journal
		NSNumber *dirty = [NSNumber numberWithBool:YES];
		[[[self journal] entries] setValue:dirty forKey:@"dirty"];
		[[[self journal] collections] setValue:dirty forKey:@"dirty"];
		[[[self journal] resources] setValue:dirty forKey:@"dirty"];
		[[[self journal] blogs] setValue:dirty forKey:@"dirty"];
		
		[[self journal] setSaveEntryOptions:(kEntrySaveDoNotIndex|kEntrySaveDoNotCollect)];
		
		if ( [[self journal] save:nil] )
			returnString = @"successfully resaved journal";
		else
			returnString = @"unable to save journal";
			
		[[self journal] setSaveEntryOptions:(kEntrySaveIndexAndCollect)];
	}
	
	else if ( [command rangeOfString:kCreateResourcesForLinkedFiles options:NSCaseInsensitiveSearch].location != NSNotFound ) 
	{
		if ( [[self journal] createResourcesForLinkedFiles] )
			returnString = @"created new resources for file:// style links";
		else
			returnString = @"there were problems creating resources for file:// style links, please refer to the console log for more information";
	}
	
	else if ( [command rangeOfString:kResetFolderIcons options:NSCaseInsensitiveSearch].location != NSNotFound )
	{
        for ( JournlerCollection *aFolder in [[self journal] collections] )
			[aFolder determineIcon];
		
		if ( [[self journal] save:nil] )
			returnString = @"folders icons reset to default value and saved";
		else
			returnString = @"unable to reset the folder icons, there was a problem saving the changes.";
	}
	
	else if ( [command rangeOfString:kRemoveDuplicateLibraryAndTrash options:NSCaseInsensitiveSearch].location != NSNotFound )
	{
		BOOL didRemove = NO;
		
		JournlerCollection *theLibrary = [[self journal] libraryCollection];
		JournlerCollection *theTrash = [[self journal] trashCollection];
		
        for ( JournlerCollection *aFolder in [[self journal] collections] )
		{
			if ( ( [aFolder isLibrary] && aFolder != theLibrary ) || ( [aFolder isTrash] && aFolder != theTrash ) )
			{
				didRemove = YES;
				[[self journal] deleteCollection:aFolder deleteChildren:YES];
			}
		}
		
		if ( [[theLibrary index] integerValue] != 0 )
			[[[self journal] rootCollection] moveChild:theLibrary toIndex:0];
		
		if ( [[theTrash index] integerValue] != 1 )
			[[[self journal] rootCollection] moveChild:theLibrary toIndex:1];
		
		[[self journal] setRootFolders:[[self journal] rootFolders]];
		[[self journal] save:nil];
		
		if ( didRemove == YES )
			returnString = @"duplicate folders were removed - you may need to restart Journler to see the changes";
		else
			returnString = @"no duplicate folders were found.";
	}
	
	else if ( [command rangeOfString:kSetUserDefault options:NSCaseInsensitiveSearch].location != NSNotFound ) 
	{
		// must do a little bit of parsing
		//	ie >> set user default : PDiPhotoLibraryLoc : /directory/directory/directory/file
		
		NSArray *components = [command componentsSeparatedByString:@":"];
		if ( [components count] != 3 )
			returnString = @"could not process command: bad syntax";
		else 
		{
			
			NSMutableString *key = [[components objectAtIndex:1] mutableCopyWithZone:[self zone]];
			NSMutableString *val = [[components objectAtIndex:2] mutableCopyWithZone:[self zone]];
			
			@try
			{
				// clip the front and end of key
				[key replaceCharactersInRange:NSMakeRange(0,1) withString:@""];
				[key replaceCharactersInRange:NSMakeRange([key length]-1,1) withString:@""];
				
				// clip the front of value
				[val replaceCharactersInRange:NSMakeRange(0,1) withString:@""];
				
				// check for nil val and remove/set the default
				if ( [val isEqualToString:@"nil"] ) 
				{
					[[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
					// provide some feedback
					returnString = [NSString stringWithFormat:@"user default %@ successfully removed", key];
				}
				else 
				{
					[[NSUserDefaults standardUserDefaults] setObject:val forKey:key];
					// provide some feedback
					returnString = [NSString stringWithFormat:@"user default %@ successfully set to %@", key, val];
				}
			}
			
			@catch (NSException *localException)
			{
				// handle an exception
				if ( [[localException name] isEqualToString:NSRangeException] )
					returnString = @"could not process command: bad syntax";
				else
					returnString = @"could not process command: bad syntax";
			}
			@finally
			{
				// empty
			}
		}
	}
	else if ( [command rangeOfString:kShowOrphanedResources options:NSCaseInsensitiveSearch].location != NSNotFound )
	{
		NSArray *orphanedResources = [[self journal] orphanedResources];
		
		if ( [orphanedResources count] > 0 )
		{
			NSMutableString *tempString = [NSMutableString string];
            
            for ( JournlerResource *aResource in orphanedResources )
			{
				NSString *aTitle = [aResource valueForKey:@"title"];
				if ( aTitle == nil ) aTitle = @"** no title **";
				
				NSString *aUTI = [aResource valueForKey:@"uti"];
				if ( aUTI == nil ) aUTI = @"** no type **";
				else {
					aUTI = [(NSString*)UTTypeCopyDescription((CFStringRef)aUTI) autorelease];
					if ( aUTI == nil ) aUTI = @"** no type **";
				}
				
				NSString *thisInfo = [NSString stringWithFormat:@"%@, %@\n", aTitle, aUTI];
				[tempString appendString:thisInfo];
				
			}
			
			returnString = [[tempString copyWithZone:[self zone]] autorelease];			
		}
		else
			returnString = @"You do not have any orphaned resources in your journal.";
	}
	
	else if ( [command rangeOfString:kDeleteOrphanedResources options:NSCaseInsensitiveSearch].location != NSNotFound )
	{
		NSArray *orphanedResources = [[self journal] orphanedResources];
		if ( [orphanedResources count] > 0 )
		{
			BOOL success = [[self journal] deleteOrphanedResources:orphanedResources];
			[[self journal] save:nil];
			
			if ( success == YES )
				returnString = @"The orphaned resources in your journal were successfully deleted";
			else
				returnString = @"There were some problems deleted the orphaned resources";
		}
		else
			returnString = @"You do not have any orphaned resources in your journal.";
	}
	
	else 
	{
		returnString = @"unknown command";
	}
	
	return returnString;
}


#pragma mark -
#pragma mark Script Handling

- (void) prepareScriptsMenu:(NSMenu**)aMenu
{
	NSString *userScripts =	 @"Library/Scripts/Journler/";
	NSString *userApplicationsScripts = @"Library/Scripts/Applications/Journler";
	
	BOOL dir;
	NSInteger indexLoc = 0;
	
	BOOL gotScripts = NO;
	NSMenu *theMenu = *aMenu;
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *userScriptsFolder = [NSHomeDirectory() stringByAppendingPathComponent:userScripts];

	// see about adding scripts from the user's script folder for journler
	if ( userScriptsFolder && [fm fileExistsAtPath:userScriptsFolder isDirectory:&dir] && dir ) 
	{
		// grab the menu for this folder
		NSMenu *aMenu = [JournlerApplicationDelegate menuForFolder:userScriptsFolder menuTarget:self targetSelector:@selector(runScript:)];
		
		// for each item in the menu, add it to the scripts menu
		if ( aMenu && [[aMenu itemArray] count] != 0 ) 
		{
			NSInteger i;
			NSArray *items = [aMenu itemArray];
			for ( i = 0; i < [items count]; i++ )
				[theMenu insertItem:[[[items objectAtIndex:i] copyWithZone:[self zone]] autorelease] atIndex:indexLoc++];
				
			gotScripts = YES;
		}
	}
	
	// try in the second location
	
	if ( gotScripts == NO )
	{
		userScriptsFolder = [NSHomeDirectory() stringByAppendingPathComponent:userApplicationsScripts];
		
		// see about adding scripts from the user's script folder for journler
		if ( userScriptsFolder && [fm fileExistsAtPath:userScriptsFolder isDirectory:&dir] && dir ) 
		{
			// grab the menu for this folder
			NSMenu *aMenu = [JournlerApplicationDelegate menuForFolder:userScriptsFolder menuTarget:self targetSelector:@selector(runScript:)];
			
			// for each item in the menu, add it to the scripts menu
			if ( aMenu && [[aMenu itemArray] count] != 0 ) 
			{
				NSInteger i;
				NSArray *items = [aMenu itemArray];
				for ( i = 0; i < [items count]; i++ )
					[theMenu insertItem:[[[items objectAtIndex:i] copyWithZone:[self zone]] autorelease] atIndex:indexLoc++];
			}
		}
	}
}

- (IBAction) runScript:(id)sender 
{
	// depending on a modified key, work with the script
	//static const double kUnknownError = -1;
	
	// handle the execution of this file differently depending on whether it is a script or something else
	NSURL *fileURL = [sender representedObject];
	
	if ( GetCurrentKeyModifiers() & shiftKey ) 
	{
		// if the shift key is down, reveal the item in the finder
		[[NSWorkspace sharedWorkspace] selectFile:[fileURL path] inFileViewerRootedAtPath:nil];
	}
	
	else if ( GetCurrentKeyModifiers() & optionKey ) 
	{
		// if the sender represents a script, open it in script editor
		[[NSWorkspace sharedWorkspace] openFile:[fileURL path] withApplication:@"Script Editor"];
	}
	
	else 
	{
		NSArray *exectuableUTIs = [NSArray arrayWithObjects: @"com.apple.applescript.text", @"com.apple.applescript.script", nil];
		NSArray *executableExtensions = [NSArray arrayWithObjects:@"scpt", @"scptd", nil];
		
		// run the script
		if ( [[NSWorkspace sharedWorkspace] file:[fileURL path] confromsToUTIInArray:exectuableUTIs] 
				|| [executableExtensions containsObject:[[fileURL path] pathExtension]] )
		{
			BOOL success = YES;
			NSDictionary *errorInfo;
			NSAppleEventDescriptor *aeDescriptor;
			
			NSAppleScript *script = [[NSAppleScript alloc] initWithContentsOfURL:fileURL error:&errorInfo];
			
			if ( ![script isCompiled] )
				success = [script compileAndReturnError:&errorInfo];
			
			if ( !success ) 
			{
				id theSource = [script richTextSource];
				if ( theSource == nil ) theSource = [script source];
				AppleScriptAlert *scriptAlert = [[[AppleScriptAlert alloc] initWithSource:theSource error:errorInfo] autorelease];
			
				NSBeep();
				[scriptAlert showWindow:self];

				return;
			}
			
			aeDescriptor = [script executeAndReturnError:&errorInfo];
			
			if ( aeDescriptor == nil && [[errorInfo objectForKey:NSAppleScriptErrorNumber] integerValue] != kScriptWasCancelledError )  
			{
				id theSource = [script richTextSource];
				if ( theSource == nil ) theSource = [script source];
				AppleScriptAlert *scriptAlert = [[[AppleScriptAlert alloc] initWithSource:theSource error:errorInfo] autorelease];
			
				NSBeep();
				[scriptAlert showWindow:self];
				return;
			}
			
			[script release];
		}
		
		// open up whatever else
		else 
		{
			[[NSWorkspace sharedWorkspace] openFile:[fileURL path]];
		}
	}
}

- (IBAction) aboutScripts:(id)sender 
{
	// help files or webpage
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"JournlerAppleScript" inBook:@"JournlerHelp"];
}

- (void) runAppleScript:(NSAppleScript*)appleScript showErrors:(BOOL)withErrors
{
	NSDictionary *errorInfo;
	NSAppleEventDescriptor *aeDescriptor;
	
	aeDescriptor = [appleScript executeAndReturnError:&errorInfo];
			
	if ( aeDescriptor == nil && [[errorInfo objectForKey:NSAppleScriptErrorNumber] integerValue] != kScriptWasCancelledError ) 
	{
		if ( withErrors )
		{
			id theSource = [appleScript richTextSource];
			if ( theSource == nil ) theSource = [appleScript source];
			AppleScriptAlert *scriptAlert = [[[AppleScriptAlert alloc] initWithSource:theSource error:errorInfo] autorelease];
		
			NSBeep();
			[scriptAlert showWindow:self];
		}
		else
		{
			NSBeep();
		}
	}
}

- (void) runAppleScriptAtPath:(NSString*)path showErrors:(BOOL)withErrors
{
	if ( path == nil )
	{
		NSLog(@"%s - script path is nil", __PRETTY_FUNCTION__);
		return;
	}
	
	NSDictionary *errorInfo;
	NSURL *fileURL = [NSURL fileURLWithPath:path];
	
	if ( fileURL == nil)
	{
		AppleScriptAlert *scriptAlert = [[[AppleScriptAlert alloc] initWithSource:path error:nil] autorelease];
		
		NSBeep();
		[scriptAlert showWindow:self];
		return;
	}
	
	NSAppleScript *script = [[[NSAppleScript alloc] initWithContentsOfURL:fileURL error:&errorInfo] autorelease];
	if ( script == nil )
	{
		AppleScriptAlert *scriptAlert = [[[AppleScriptAlert alloc] initWithSource:path error:nil] autorelease];
		
		NSBeep();
		[scriptAlert showWindow:self];
		return;
	}
	
	if ( ![script isCompiled] && ![script compileAndReturnError:&errorInfo] && [[errorInfo objectForKey:NSAppleScriptErrorNumber] integerValue] != kScriptWasCancelledError ) 
	{
		id theSource = [script richTextSource];
		if ( theSource == nil ) theSource = [script source];
		AppleScriptAlert *scriptAlert = [[[AppleScriptAlert alloc] initWithSource:theSource error:errorInfo] autorelease];
		
		NSBeep();
		[scriptAlert showWindow:self];
	}
	else
	{
		[self runAppleScript:script showErrors:withErrors];
	}
}

#pragma mark -
#pragma mark Installing Services

- (BOOL) installPDFService 
{
	NSArray *paths; 
	BOOL isDir = NO, exists = NO, success = NO; 
	NSFileManager *fileManager = [NSFileManager defaultManager]; 
	NSString *pdfServiceDirectoryPath, *myAppPath, *myAppPDFAppPath, *myAppPDFScriptPath;

	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"DoNotInstallPDFService"] )
		return NO;

	paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES); 	
	if ( [paths count] > 0 )  
	{
		// only looking for one file/directory 
		pdfServiceDirectoryPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"PDF Services"]; 
		exists = [fileManager fileExistsAtPath:pdfServiceDirectoryPath isDirectory:&isDir]; 
		if ( !isDir ) 
		{ 
			// There is no PDF Services directory so create it 
			success = [fileManager createDirectoryAtPath:pdfServiceDirectoryPath attributes:nil]; 
			if (!success) 
			{ 
				NSLog(@"%s - Unable to create PDF Services directory at %@", __PRETTY_FUNCTION__, pdfServiceDirectoryPath);
			} 
		} 
		
		// path for the pdf script application
		myAppPDFAppPath = [[pdfServiceDirectoryPath stringByAppendingPathComponent:NSLocalizedString(@"pdf service filename",@"")]
		 stringByAppendingPathExtension:@"app"]; 
		 
		// path for the pdf script
		myAppPDFScriptPath = [[pdfServiceDirectoryPath stringByAppendingPathComponent:
		 NSLocalizedString(@"pdf service filename",@"")] stringByAppendingPathExtension:@"scpt"]; 
		
		// delete the old, troublesome script script
		if ( [fileManager fileExistsAtPath:myAppPDFScriptPath] ) 
			[fileManager removeFileAtPath:myAppPDFScriptPath handler:nil];
		
		if ( ![fileManager fileExistsAtPath:myAppPDFAppPath] )
		{ 
			// There is no alias to myApp so create it 
			myAppPath = [[NSBundle mainBundle] pathForResource:@"Save PDF to Journler" ofType:@"app"];
			if ( myAppPath == nil )
			{
				NSLog(@"%s - unable to locate Save PDF to Journler.app in Journler bundle", __PRETTY_FUNCTION__);
				success = NO;
			}
			else
			{
				
				success = [fileManager copyPath:myAppPath toPath:myAppPDFAppPath handler:nil];
				if ( success ) // hide the extension if successful
				{
					NSLog(@"%s - installed self as pdf service to %@", __PRETTY_FUNCTION__, myAppPDFAppPath);
					[fileManager changeFileAttributes:[NSDictionary dictionaryWithObject:
					 [NSNumber numberWithBool:YES] forKey:NSFileExtensionHidden] atPath:myAppPDFAppPath];
				}
			}
		} 
	}
	else
	{
		NSLog(@"%s - unable to install self as pdf service to %@", __PRETTY_FUNCTION__, myAppPDFAppPath);
	}
	
	return success;
}

- (BOOL) installScriptMenu
{
	BOOL success = NO;
	NSInteger installOption = [[NSUserDefaults standardUserDefaults] integerForKey:@"ScriptsInstallationDirectory"];
	
	NSString *theDirectory = nil;
	
	if ( installOption == 0 )
	{
		// install in ~/Library/Scripts/Journler
		NSString *scriptsDirectory = [@"~/Library/Scripts" stringByExpandingTildeInPath];
		NSString *journlerScriptsDirectory = [@"~/Library/Scripts/Journler" stringByExpandingTildeInPath];
		
		if ( ![[NSFileManager defaultManager] fileExistsAtPath:scriptsDirectory] 
			&& ![[NSFileManager defaultManager] createDirectoryAtPath:scriptsDirectory attributes:nil] )
		{
			NSLog(@"%s - unable to create scripts directory at path %@", __PRETTY_FUNCTION__, scriptsDirectory);
			goto bail;
		}
		
		if ( ![[NSFileManager defaultManager] fileExistsAtPath:journlerScriptsDirectory]
			&& ![[NSFileManager defaultManager] createDirectoryAtPath:journlerScriptsDirectory attributes:nil] )
		{
			NSLog(@"%s - unable to create journler scripts directory at path %@", __PRETTY_FUNCTION__, scriptsDirectory);
			goto bail;
		}
		
		theDirectory = journlerScriptsDirectory;
	}
	
	else if ( installOption == 1 )
	{
		// install in ~/Library/Scripts/Applications/Journler
		NSString *scriptsDirectory = [@"~/Library/Scripts" stringByExpandingTildeInPath];
		NSString *applicationScriptsDirectory = [@"~/Library/Scripts/Applications/" stringByExpandingTildeInPath];
		NSString *journlerScriptsDirectory = [@"~/Library/Scripts/Applications/Journler" stringByExpandingTildeInPath];
		
		if ( ![[NSFileManager defaultManager] fileExistsAtPath:scriptsDirectory] 
			&& ![[NSFileManager defaultManager] createDirectoryAtPath:scriptsDirectory attributes:nil] )
		{
			NSLog(@"%s - unable to create scripts directory at path %@", __PRETTY_FUNCTION__, scriptsDirectory);
			goto bail;
		}
		
		if ( ![[NSFileManager defaultManager] fileExistsAtPath:applicationScriptsDirectory] 
			&& ![[NSFileManager defaultManager] createDirectoryAtPath:applicationScriptsDirectory attributes:nil] )
		{
			NSLog(@"%s - unable to create scripts directory at path %@", __PRETTY_FUNCTION__, scriptsDirectory);
			goto bail;
		}
		
		if ( ![[NSFileManager defaultManager] fileExistsAtPath:journlerScriptsDirectory]
			&& ![[NSFileManager defaultManager] createDirectoryAtPath:journlerScriptsDirectory attributes:nil] )
		{
			NSLog(@"%s - unable to create journler scripts directory at path %@", __PRETTY_FUNCTION__, scriptsDirectory);
			goto bail;
		}
		
		theDirectory = journlerScriptsDirectory;
	}
	
	// and install a few scripts?
	
bail:
	
	success = YES;
	return success;
}

- (BOOL) installContextualMenu
{	
	NSArray *paths; 
	BOOL isDir = NO, exists = NO, success = NO; 
	NSFileManager *fileManager = [NSFileManager defaultManager]; 
	NSString *contextualItemsDirectoryPath, *installedItemPath, *bundledContextualItemPath; 
	
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"DoNotInstallContextualMenuItem"] )
		return NO;
	
	paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES); 
	if ( [paths count] > 0 )  
	{
		// only looking for one file/directory 
		contextualItemsDirectoryPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Contextual Menu Items"]; 
		exists = [fileManager fileExistsAtPath:contextualItemsDirectoryPath isDirectory:&isDir]; 
		if ( !isDir ) 
		{ 
			// There is no PDF Services directory so create it 
			success = [fileManager createDirectoryAtPath:contextualItemsDirectoryPath attributes:nil]; 
			if (!success) 
			{ 
				NSLog(@"%s - Unable to create Contextual Menu Items directory at %@", __PRETTY_FUNCTION__, contextualItemsDirectoryPath);
			} 
		} 

		installedItemPath = [contextualItemsDirectoryPath stringByAppendingPathComponent:@"JournlerCMI.plugin"]; 
		exists = [fileManager fileExistsAtPath:installedItemPath];
		
		if ( !exists ) 
		{ 
			// There is no alias to myApp so create it 
			bundledContextualItemPath = [[NSBundle mainBundle] pathForResource:@"JournlerCMI" ofType:@"plugin"];
			success = [fileManager copyPath:bundledContextualItemPath toPath:installedItemPath handler:nil]; 
			if (success) 
			{ 
				NSLog(@"%s - successfully installed contextual menu item", __PRETTY_FUNCTION__);
			}
			else 
			{ 
				NSLog(@"%s - unable to install contextual menu item to %@", __PRETTY_FUNCTION__, installedItemPath);
			} 
		} 
	}
	else
	{
		NSLog(@"%s - unable to install contextual menu item to %@", __PRETTY_FUNCTION__, installedItemPath);
	}
	
	return success;
}

- (BOOL) installDropBoxService
{
	// checks for the existence of the drop box, creating and aliasing if necessary
	// imports the contents of the drop box if there is something there
	
	NSString *dropBoxPath = [sharedJournal dropBoxPath];
	
	if ( ![[NSFileManager defaultManager] fileExistsAtPath:dropBoxPath] )
	{
		if ( ![[NSFileManager defaultManager] createDirectoryAtPath:dropBoxPath attributes:nil] )
			NSLog(@"%s - no dropbox and unable to create at path %@", __PRETTY_FUNCTION__, dropBoxPath);
		else
		{
			//NSLog(@"%s - created drop box at path %@", __PRETTY_FUNCTION__, dropBoxPath);
			
			// set the icon
			NSImage *dropboxIcon = [NSImage imageNamed:@"DropBox"];
			if ( dropboxIcon != nil ) [[NSWorkspace sharedWorkspace] setIcon:dropboxIcon forFile:dropBoxPath 
			 options:NSExcludeQuickDrawElementsIconCreationOption];
			 
			// alias the drop box
			NSString *desktopDropBox = [@"~/Desktop/Journler Drop Box" stringByExpandingTildeInPath];
			
			if ( ![[NSFileManager defaultManager] fileExistsAtPath:desktopDropBox]
				&& ![[NSWorkspace sharedWorkspace] createAliasForPath:dropBoxPath toPath:desktopDropBox] )
				NSLog(@"%s - unable to create desktop alias to drop box from %@ at %@", __PRETTY_FUNCTION__, dropBoxPath, desktopDropBox);
			//else
			//	NSLog(@"%s - created drop box alias at path %@", __PRETTY_FUNCTION__, desktopDropBox);
			
			// watch the path
			dropBoxWatcher = [[JournlerKQueue alloc] init];
			[dropBoxWatcher setDelegate:self];
			[dropBoxWatcher addPath:dropBoxPath];
		}
	}	
	
	else if ( !dropBoxing )
	{
		NSInteger fileCount;
		BOOL visually = defaultBool(@"UseVisualAidWherePossibleWhenImporting"); 
		// && !( (GetCurrentKeyModifiers() & shiftKey) && (GetCurrentKeyModifiers() & controlKey) ) );
		
		dropBoxing = YES;
		BOOL success = [self _importContentsOfDropBox:dropBoxPath visually:visually filesAffected:&fileCount];
		
		if ( !success )
		{
			// put up an alert
			NSLog(@"%s - problems importing some items from the drop box", __PRETTY_FUNCTION__);
			NSBeep();
			[[NSAlert dropboxError] runModal];
		}
		
		// watch the path
		dropBoxWatcher = [[JournlerKQueue alloc] init];
		[dropBoxWatcher setDelegate:self];
		[dropBoxWatcher addPath:dropBoxPath];
	}
	
	return YES;
}

#pragma mark -
#pragma mark URLs, Services

- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	NSURL *url = [NSURL URLWithString:urlString];
	
	if ( ![url isJournlerURI] )
	{
		NSBeep();
		[[NSAlert uriError] runModal];
		NSLog(@"%s - url does not refer to Journler object %@", __PRETTY_FUNCTION__, [url absoluteString]);
		return;
	}
	
	if ( [url isJournlerHelpURI] )
	{
		NSString *helpAnchor = [[url path] lastPathComponent];
		if ( helpAnchor == nil ) NSBeep();
		else if ( [helpAnchor isEqualToString:@"JournlerHelpIndex"] ) [NSApp showHelp:self];
		else [[NSHelpManager sharedHelpManager] openHelpAnchor:helpAnchor inBook:@"JournlerHelp"];
	}
	else if ( [url isJournlerLicenseURI] )
	{
		NSString *path = [url path];
		NSArray *licenseComponents = [path componentsSeparatedByString:@"/"];
		
		NSMutableString *name = nil;
		NSMutableString *code = nil;
		
		BOOL invalidating = NO;

		if ( [licenseComponents count] == 2 )
		{
			if ( [[[licenseComponents objectAtIndex:1] lowercaseString] isEqualToString:@"invalidate"] )
			{
				// invalidate the license
				[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LicenseName"];
				[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LicenseCode"];
				
				invalidating = YES;
				name = [NSMutableString string];
				code = [NSMutableString string];
			}
			else
			{
				// derive the code
				name = [[[licenseComponents objectAtIndex:0] mutableCopyWithZone:[self zone]] autorelease];
				code = [[[licenseComponents objectAtIndex:1] mutableCopyWithZone:[self zone]] autorelease];
			}
		}
		else if ( [licenseComponents count] == 3 )
		{
			// derive the license
			name = [[[licenseComponents objectAtIndex:1] mutableCopyWithZone:[self zone]] autorelease];
			code = [[[licenseComponents objectAtIndex:2] mutableCopyWithZone:[self zone]] autorelease];
		}
		
		if ( name != nil && code != nil )
		{
			//NSLog(@"%@ %@",name,code);
			
			[name replaceOccurrencesOfString:@"%20" withString:@" " options:NSLiteralSearch range:NSMakeRange(0,[name length])];
			[code replaceOccurrencesOfString:@"-" withString:@"" options:NSLiteralSearch range:NSMakeRange(0,[code length])];
			
			// grab preferences
			PrefWindowController *prefsController = (PrefWindowController*)[NSApp singletonControllerWithClass:[PrefWindowController class]];
			if ( prefsController == nil )
			{
				prefsController = [[[PrefWindowController alloc] init] autorelease];
				[prefsController setJournal:[self journal]];
			}
			
			// show preferernces and license panel
			[prefsController showWindow:self];
			[prefsController selectPanel:[NSNumber numberWithInteger:kPrefDonations]];
			
			// fork depending on invalidating key
			if ( invalidating == YES )
			{
				// show the panel
				//[prefsController enterLicense:self];
				[prefsController loadLicenseViewer];
			}
			else
			{
				// check the license
				[prefsController checkLicenseName:name code:code];
				[prefsController loadLicenseViewer];
			}
		}
	}
	else
	{
		id theObject = [[self journal] objectForURIRepresentation:url];
		if ( theObject == nil )
		{
			NSBeep();
			[[NSAlert uriError] runModal];
			NSLog(@"%s - unable to location Journler object for url %@", __PRETTY_FUNCTION__, [url absoluteString]);
			return;
		}
		
		JournlerWindowController *mainWindow = [self mainWindowIgnoringActive];
		if ( mainWindow == nil || [theObject isKindOfClass:[JournlerCollection class]] )
			mainWindow = journalWindowController;
		
		TabController *theTab = [mainWindow selectedTab];
		
		if ( [theObject isKindOfClass:[JournlerEntry class]] )
			[theTab selectDate:nil folders:nil entries:[NSArray arrayWithObject:theObject] resources:nil];
		else if ( [theObject isKindOfClass:[JournlerCollection class]] )
			[theTab selectDate:nil folders:[NSArray arrayWithObject:theObject] entries:nil resources:nil];
		else if ( [theObject isKindOfClass:[JournlerResource class]] )
			[theTab selectDate:nil folders:nil entries:[NSArray arrayWithObject:[theObject valueForKey:@"entry"]] resources:nil];
	}
}

- (NSArray*) _mailMessagePathsFromPasteboard:(NSPasteboard*)pboard
{
	IntegrationCopyFiles *notice = [[IntegrationCopyFiles alloc] init];
	[notice setNoticeText:NSLocalizedString(@"integration reading messages",@"")];
	[notice runNotice];
	
	// get the path, get the selection via applescript, build the full paths
	static NSString *selectionIDsSource = @"tell application \"Mail\"\nset mailSelection to the selection\nset allIDs to {}\nrepeat with aMail in mailSelection\nset allIDs to allIDs & {{the id of aMail, the subject of aMail}}\nend repeat\nreturn allIDs\nend tell";
	
	NSString *mboxPath = [pboard stringForType:kMailMessagePboardType];
		
	NSDictionary *errorDictionary;
	NSAppleEventDescriptor *eventDescriptor;
	NSAppleScript *script;
	NSString *scriptPath = [[NSBundle mainBundle] pathForResource:@"GetMailSelection" ofType:@"scpt"];
	
	NSMutableArray *messagePaths = [NSMutableArray array];
		
	if (scriptPath == nil )
		script = [[[NSAppleScript alloc] initWithSource:selectionIDsSource] autorelease];
	else
		script = [[[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:scriptPath] error:&errorDictionary] autorelease];
	
	if ( script == nil )
	{
		NSLog(@"%s - unable to initialize the mail message script: %@", __PRETTY_FUNCTION__, errorDictionary);
		messagePaths = nil;
	}
	else
	{
	
		eventDescriptor = [script executeAndReturnError:&errorDictionary];
		if ( eventDescriptor == nil && [[errorDictionary objectForKey:NSAppleScriptErrorNumber] integerValue] != kScriptWasCancelledError ) 
		{
			NSLog(@"%s - problem compiling mail message selection script: %@", __PRETTY_FUNCTION__, errorDictionary);
			
			id theSource = [script richTextSource];
			if ( theSource == nil ) theSource = [script source];
			AppleScriptAlert *scriptAlert = [[[AppleScriptAlert alloc] initWithSource:theSource error:errorDictionary] autorelease];
			
			NSBeep();
			[scriptAlert showWindow:self];
			
			messagePaths = nil;
		}
		else if ( [eventDescriptor numberOfItems] == 0 )
		{
			NSLog(@"%s - mail messasge drag, the return event descriptor contains no items: %@", __PRETTY_FUNCTION__, eventDescriptor);
			messagePaths = nil;
		}
		else
		{
			NSInteger i, totalItems = [eventDescriptor numberOfItems];
			for ( i = 1; i <= totalItems; i++ )
			{
				NSAppleEventDescriptor *itemDescriptor = [eventDescriptor descriptorAtIndex:i];
				
				if ( [itemDescriptor numberOfItems] != 2 )
					continue;
				
				// each event descriptor is itself an array of two items: id, subject
				NSInteger anID = [[itemDescriptor descriptorAtIndex:1] int32Value];
				//NSString *aSubject = [[itemDescriptor descriptorAtIndex:2] stringValue];
				
				NSString *aMessagePath = [[mboxPath stringByAppendingPathComponent:@"Messages"] 
						stringByAppendingPathComponent:[NSString stringWithFormat:@"%i.emlx", anID]];
				
				// add it to the array
				[messagePaths addObject:aMessagePath];
			}
		
		}
	}
	
	[notice endNotice];
	[notice release];
	
	if ( [messagePaths count] == 0 )
		return nil;
	else
		return messagePaths;
}


- (NSArray*) entriesForPasteboardData:(NSPasteboard*)pboard 
		visual:(BOOL)showDialog 
		preferredTypes:(NSArray*)types
{
	static NSString *http_scheme = @"http://";
	static NSString *secure_http_scheme = @"https://";
	//static NSString *file_scheme = @"file://";

	static NSString *kPDUTTypeURLName = @"public.url-name";

	NSMutableArray *returnEntries = [NSMutableArray array];
	
	if ( types == nil )
		types = [NSArray arrayWithObjects: kMailMessagePboardType, NSTIFFPboardType, 
				NSPICTPboardType, NSRTFDPboardType, 
				NSRTFPboardType, WebURLsWithTitlesPboardType, 
				kMailMessagePboardType, NSFilenamesPboardType, 
				NSURLPboardType, NSStringPboardType, 
				kPDUTTypeURLName, nil];
	
	/*
	//NSArray *types = [NSArray arrayWithObjects: kMailMessagePboardType, NSTIFFPboardType, NSPICTPboardType, 
	//		NSRTFDPboardType, NSRTFPboardType, WebURLsWithTitlesPboardType, kMailMessagePboardType, 
	//		NSFilenamesPboardType, NSURLPboardType, NSStringPboardType, kPDUTTypeURLName, nil];
	
	// moved filenames up, but what is the consequence of that for other operations?
	// I need a standard arrangement here
	NSArray *types = [NSArray arrayWithObjects: kMailMessagePboardType, NSFilenamesPboardType, 
			NSTIFFPboardType, NSPICTPboardType, 
			NSRTFDPboardType, NSRTFPboardType, WebURLsWithTitlesPboardType, kMailMessagePboardType, 
			NSURLPboardType, NSStringPboardType, kPDUTTypeURLName, nil];
	*/
	
	NSString *desiredType = [pboard availableTypeFromArray:types];
	NSArray *availableTypes = [pboard types];
	
	//NSString *pboardName = [pboard name];
	//NSLog(pboardName);
	
	BOOL forceResourceTitle = NO;
	
	NSString *title = nil;
	NSString *keywords = nil;
	NSString *category = nil;
	
	NSArray	*destinationPaths = nil;
	NSString *destinationFolder = TempDirectory();
	
	if ( [desiredType isEqualToString:kMailMessagePboardType] )
	{
		// pass this off to a subhandler for sure
		destinationPaths = [self _mailMessagePathsFromPasteboard:pboard];
	}
	
	else if ( [desiredType isEqualToString:NSRTFDPboardType] ) 
	{
		NSData *service_data = [pboard dataForType:desiredType];
		NSAttributedString *attributed_service = [[[NSAttributedString alloc] initWithRTFD:service_data documentAttributes:nil] autorelease];
		
		if ( attributed_service == nil ) 
		{
			NSLog(@"%s - unable to derive attributed string from pasteboard rtfd", __PRETTY_FUNCTION__);
			destinationPaths = nil;
			goto bail;
		}
		
		NSFileWrapper *attributed_wrapper = [attributed_service RTFDFileWrapperFromRange:
		NSMakeRange(0,[attributed_service length]) documentAttributes:nil];
		
		destinationPaths = [NSArray arrayWithObject: [[destinationFolder 
		stringByAppendingPathComponent:NSLocalizedString(@"untitled title", @"")] stringByAppendingPathExtension:@"rtfd"] ];

		if ( ![attributed_wrapper writeToFile:[destinationPaths objectAtIndex:0] atomically:NO updateFilenames:YES] ) 
		{
			NSLog(@"%s - unable to write service rtfd data to %@", __PRETTY_FUNCTION__, [destinationPaths objectAtIndex:0]);
			destinationPaths = nil;
			goto bail;
		}
	}
	
	else if ( [desiredType isEqualToString:NSRTFPboardType] ) 
	{
		NSError *error = nil;
		NSData *service_data = [pboard dataForType:desiredType];
		
		destinationPaths = [NSArray arrayWithObject: [[destinationFolder 
		stringByAppendingPathComponent:NSLocalizedString(@"untitled title", @"")] stringByAppendingPathExtension:@"rtf"] ];
		
		if ( ![service_data writeToFile:[destinationPaths objectAtIndex:0] options:0 error:&error] )
		{
			NSLog(@"%s - unable to write service rich text data to %@, error %@", __PRETTY_FUNCTION__, [destinationPaths objectAtIndex:0], error);
			destinationPaths = nil;
			goto bail;
		}
	}
	
	else if ( [desiredType isEqualToString:NSTIFFPboardType] || [desiredType isEqualToString:NSPICTPboardType] ) 
	{
		NSError *error = nil;
		NSData *tiff_rep;
		NSData *service_data = [pboard dataForType:desiredType];
		NSImage *service_image = [[[NSImage alloc] initWithData:service_data] autorelease];
		
		if ( service_image == nil ) 
		{
			NSLog(@"%s - unable to derive image from pasteboard image data", __PRETTY_FUNCTION__);
			destinationPaths = nil;
			goto bail;
		}
		
		tiff_rep = [service_image TIFFRepresentation];
		destinationPaths = [NSArray arrayWithObject: [[destinationFolder 
		stringByAppendingPathComponent:NSLocalizedString(@"untitled title", @"")] stringByAppendingPathExtension:@"tif"] ];
		
		if ( ![tiff_rep writeToFile:[destinationPaths objectAtIndex:0] options:0 error:&error] )
		{
			NSLog(@"%s - unable to write service tiff data to %@, error %@", __PRETTY_FUNCTION__, [destinationPaths objectAtIndex:0], error);
			destinationPaths = nil;
			goto bail;
		}
	}

	else if ( [desiredType isEqualToString:NSStringPboardType] 
		&& ![[pboard stringForType:NSStringPboardType] rangeOfString:http_scheme options:NSCaseInsensitiveSearch].location == 0 
		&& ![[pboard stringForType:NSStringPboardType] rangeOfString:secure_http_scheme options:NSCaseInsensitiveSearch].location == 0 ) 
	{
		NSError *error = nil;
		NSString *service_string = [pboard stringForType:NSStringPboardType];
				
		destinationPaths = [NSArray arrayWithObject: [[destinationFolder 
		stringByAppendingPathComponent:NSLocalizedString(@"untitled title", @"")] stringByAppendingPathExtension:@"txt"] ];
		
		if ( ![service_string writeToFile:[destinationPaths objectAtIndex:0] atomically:NO encoding:NSUnicodeStringEncoding error:&error] )
		{
			NSLog(@"%s - unable to write service plain text data to %@, error %@", __PRETTY_FUNCTION__, [destinationPaths objectAtIndex:0], error);
			destinationPaths = nil;
			goto bail;
		}
	}
	
	else if ( [desiredType isEqualToString:NSURLPboardType] || [desiredType isEqualToString:WebURLsWithTitlesPboardType] ||
			( [desiredType isEqualToString:NSStringPboardType] && 
			( [[pboard stringForType:NSStringPboardType] rangeOfString:http_scheme options:NSCaseInsensitiveSearch].location == 0
			|| [[pboard stringForType:NSStringPboardType] rangeOfString:secure_http_scheme options:NSCaseInsensitiveSearch].location == 0 ) ) )
	{
		
		BOOL iIntegration = NO;
		NSURL *url = nil;
		
		if ( [desiredType isEqualToString:NSURLPboardType] )
		{
			url = [NSURL URLFromPasteboard:pboard];
			
			if ( [url isFileURL] )
			{
				destinationPaths = [NSArray arrayWithObject: [url path] ];
				url = nil;
				keywords = [url absoluteString];
			}
			
			else
			{
				if ( [availableTypes containsObject:kPDUTTypeURLName] )
					title = [pboard stringForType:kPDUTTypeURLName];
				else
					title = [url absoluteString];
					
				keywords = [url absoluteString];
			}
			
		}
		else if ( [desiredType isEqualToString:WebURLsWithTitlesPboardType] )
		{
			NSArray *pbArray = [pboard propertyListForType:WebURLsWithTitlesPboardType];
			NSArray *URLArray = [pbArray objectAtIndex:0];
			NSArray *titleArray = [pbArray objectAtIndex:1];
			
			url = ( [URLArray count] > 0 ? [NSURL URLWithString:[URLArray objectAtIndex:0]] : nil );
			
			title = ( [titleArray count] > 0 ? [titleArray objectAtIndex:0] : nil );
			keywords = ( [URLArray count] > 0 ? [URLArray objectAtIndex:0] : nil );
			
			// check for iIntegration or Mail drag
			if ( [availableTypes containsObjects:[NSArray arrayWithObjects:kiLifeIntegrationPboardType, NSFilenamesPboardType, nil]] ) 
			{
				url = nil;
				iIntegration = YES;
				NSLog(@"%s - requesting import of iLife or Message file, only single items accepted", __PRETTY_FUNCTION__);
				
				NSArray *filenames = [pboard propertyListForType:NSFilenamesPboardType];
				destinationPaths = filenames;
			}
		}
		else if ( [desiredType isEqualToString:NSStringPboardType] )
		{
			// first check the drag pasteboard to see if there's equivalence -- the pasteboard we have here is a "special" one
			
			NSString *originalString = [pboard stringForType:NSStringPboardType], *dragString = nil;
			NSPasteboard *dragBoard = [NSPasteboard pasteboardWithName:NSDragPboard];
			
			if ( [[dragBoard types] containsObject:NSStringPboardType]
					&& [ ( dragString = [dragBoard stringForType:NSStringPboardType] ) isEqualToString:originalString] )
			{
				// equivalence -- the drag board has this string and it matches what we're working with here
				
				if ( [[dragBoard types] containsObject:WebURLsWithTitlesPboardType] )
				{
					NSArray *pbArray = [dragBoard propertyListForType:WebURLsWithTitlesPboardType];
					NSArray *URLArray = [pbArray objectAtIndex:0];
					NSArray *titleArray = [pbArray objectAtIndex:1];
					
					url = ( [URLArray count] > 0 ? [NSURL URLWithString:[URLArray objectAtIndex:0]] : nil );
					title = ( [titleArray count] > 0 ? [titleArray objectAtIndex:0] : nil );
					keywords = ( [URLArray count] > 0 ? [URLArray objectAtIndex:0] : nil );
					
					// fall back to original pasteboard
					if ( url == nil )
					{
						url = [NSURL URLWithString:[pboard stringForType:NSStringPboardType]];
						title = [url absoluteString];
						keywords = [url absoluteString];
					}
				}
				
				else if ( [[dragBoard types] containsObject:kPDUTTypeURLName] )
				{
					url = [NSURL URLWithString:[pboard stringForType:NSStringPboardType]];
					keywords = [url absoluteString];
					
					#warning grabbing the firefox title here
					
					if ( [[dragBoard types] containsObject:kPDUTTypeURLName] )
						title = [dragBoard stringForType:kPDUTTypeURLName];
					else
						title = [url absoluteString];
				}
				
				else
				{
					url = [NSURL URLWithString:[pboard stringForType:NSStringPboardType]];
					keywords = [url absoluteString];
					title = [url absoluteString];
				}
			}
			
			/*
			if ( [[dragBoard types] containsObject:NSStringPboardType] && [[dragBoard types] containsObject:WebURLsWithTitlesPboardType]
				&& [ ( dragString = [dragBoard stringForType:NSStringPboardType] ) isEqualToString:originalString] )
			{
				// take what's on the drag board
				
				NSArray *pbArray = [dragBoard propertyListForType:WebURLsWithTitlesPboardType];
				NSArray *URLArray = [pbArray objectAtIndex:0];
				NSArray *titleArray = [pbArray objectAtIndex:1];
				
				url = ( [URLArray count] > 0 ? [NSURL URLWithString:[URLArray objectAtIndex:0]] : nil );
				title = ( [titleArray count] > 0 ? [titleArray objectAtIndex:0] : nil );
				keywords = ( [URLArray count] > 0 ? [URLArray objectAtIndex:0] : nil );
				
				// fall back to original pasteboard
				if ( url == nil )
				{
					url = [NSURL URLWithString:[pboard stringForType:NSStringPboardType]];
					title = [url absoluteString];
					keywords = [url absoluteString];
				}
			}
			*/
			
			else
			{
				// take what's on the standard pboard
				url = [NSURL URLWithString:[pboard stringForType:NSStringPboardType]];
				keywords = [url absoluteString];
				
				if ( [[dragBoard types] containsObject:kPDUTTypeURLName] )
					title = [dragBoard stringForType:kPDUTTypeURLName];
				else
					title = [url absoluteString];
			}
		}
		
		// skip ahead to the import if we're dealing with file integration
		if ( iIntegration )
			goto bail;
	
		// otherwise, a nil url is a serious problem
		else if ( url == nil  )
		{
			NSLog(@"%s - unable to derive url from pasteboard", __PRETTY_FUNCTION__);
			destinationPaths = nil;
			goto bail;
		}
		
		else if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"ConvertImportedURLsToWebArchives"] )
		{
			// download the url as a web archive
			
			IntegrationCopyFiles *notice = [[IntegrationCopyFiles alloc] init];
			[notice setNoticeText:NSLocalizedString(@"integration creating archive",@"")];
			[notice runNotice];
			
			// see about downloading the url for a webarchive?	
			NSURLRequest *url_request = [[NSURLRequest alloc] initWithURL:url];
			WebView *web_view = [[WebView alloc] initWithFrame:NSMakeRect(0,0,100,100)];
			PDWebDelegate *web_delegate = [[PDWebDelegate alloc] initWithWebView:web_view];
			
			[[web_view mainFrame] loadRequest:url_request];
			[web_delegate waitForView:15.0];
			
			[notice endNotice];
			[notice release];
			
			if ( [[[web_view mainFrame] dataSource] isLoading] )
			{
				[[web_view mainFrame] stopLoading];
				NSLog(@"%s - operation timed out loading url %@", __PRETTY_FUNCTION__, [url absoluteString] );
				destinationPaths = nil;
				goto bail;
			}
			
			NSError *error = nil;
			WebArchive *services_archive = [[[web_view mainFrame] DOMDocument] webArchive];
			
			forceResourceTitle = YES;
			title = [[[web_view mainFrame] dataSource] pageTitle];
			if ( title == nil || [title length] == 0 ) title = NSLocalizedString(@"untitled title", @"");
			
			if ( services_archive == nil ) 
			{
				NSLog(@"%s - unable to derive webarchive from url %@", __PRETTY_FUNCTION__, [url absoluteString] );
				destinationPaths = nil;
				goto bail;
			}
			
			destinationPaths = [NSArray arrayWithObject: [[destinationFolder 
			stringByAppendingPathComponent:[title pathSafeString]] stringByAppendingPathExtension:@"webarchive"] ];
			
			if ( ![[services_archive data] writeToFile:[destinationPaths objectAtIndex:0] options:NSAtomicWrite error:&error] ) 
			{
				NSLog(@"%s - unable to write webarchive to %@, error %@", __PRETTY_FUNCTION__, [destinationPaths objectAtIndex:0], error);
				destinationPaths = nil;
				goto bail;
			}
		}
		else
		{
			// just webloc it
			PDWeblocFile *weblocFile = [PDWeblocFile weblocWithURL:url];
			
			if ( title == nil ) title = [url absoluteString];
			forceResourceTitle = YES;
			[weblocFile setDisplayName:title];
			
			NSString *theDestination = [[destinationFolder stringByAppendingPathComponent:[title pathSafeString]] 
			stringByAppendingPathExtension:[PDWeblocFile weblocExtension]];
			
			destinationPaths = [NSArray arrayWithObject:theDestination];
			
			if ( ![weblocFile writeToFile:theDestination] )
			{
				NSLog(@"%s - unable to write webloc to %@", __PRETTY_FUNCTION__, theDestination);
				destinationPaths = nil;
				goto bail;
			}
		}
	}
	
	else if ( [desiredType isEqualToString:NSFilenamesPboardType] )
	{
		NSInteger i;
		BOOL isDirectory = NO;
		NSArray *filenames = [pboard propertyListForType:NSFilenamesPboardType];
		
		for ( i = 0; i < [filenames count]; i++ )
		{
			if ( [[NSFileManager defaultManager] fileExistsAtPath:[filenames objectAtIndex:i] isDirectory:&isDirectory] && isDirectory )
			{
				// let the user know that there's a folder, it's contents won't be imported, etc.
				NSBeep();
				NSInteger result = [[NSAlert pasteboardFolderWarning] runModal];
				if ( result != NSAlertFirstButtonReturn )
				{
					destinationPaths = nil;
					goto bail;
				}
			}
		}
		
		destinationPaths = filenames;
	}

bail:
	
	// armed with a valid destination path, import the entry
	if ( destinationPaths != nil )
	{
		if ( [[self journal] isLoaded] )
		{
            for ( NSString *aPath in destinationPaths )
			{
			
				// if the journal is loaded, go ahead and import the entry, launching it in its own window
				JournlerEntry *servicedEntry = [self importFile:aPath];
				if ( servicedEntry == nil )
				{
					NSLog(@"%s - unable to produce entry for serviced content at path %@", __PRETTY_FUNCTION__, aPath);
					goto bail;
				}
				
				// set a few variables on the entry if they are available
				if ( title != nil )
				{
					[servicedEntry setValue:title forKey:@"title"];
					if ( forceResourceTitle == YES && [[servicedEntry resources] count] > 0 )
						[[servicedEntry resources] setValue:title forKey:@"title"];
				}
				
				else if ( [[servicedEntry title] length] == 0 || [[servicedEntry title] isEqualToString:NSLocalizedString(@"untitled title",@"")] )
				{
					// use the first few words of the content
					NSString *content = [[servicedEntry valueForKey:@"attributedContent"] string];
					if ( content != nil && [content length] > 0 )
					{
						NSInteger i;// ,whitespaceIndex = -1;
						NSInteger startingIndex = ( 50 < [content length] ? 50 : [content length] - 1 );
						NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
						NSCharacterSet *controlSet = [NSCharacterSet controlCharacterSet];
						
						// try to break at the first newline or control character
						for ( i = 0; i < startingIndex; i++ )
						{
							if ( [controlSet characterIsMember:[content characterAtIndex:i]] )
								break;
						}
						
						// if we made it to the end, go backwards looking for a space
						if ( i == startingIndex )
						{
							for ( i = startingIndex; i > 0; i-- )
							{
								if ( [whitespaceSet characterIsMember:[content characterAtIndex:i]] )
									break;
							}
						}
						
						if ( i > 0 )
						{
							NSString *titleSubstring = [content substringToIndex:i];
							if ( i < 50 ) titleSubstring = [titleSubstring stringByAppendingString:@" ..."];
							[servicedEntry setValue:titleSubstring forKey:@"title"];
						}
					
					}
				}
					
				if ( keywords != nil && [[servicedEntry keywords] length] == 0 )
					[servicedEntry setValue:keywords forKey:@"keywords"];
				if ( category != nil && [[servicedEntry category] length] == 0 )
					[servicedEntry setValue:category forKey:@"category"];
				
				[returnEntries addObject:servicedEntry];
			}
			
			// nil out the return entries if there aren't any
			if ( [returnEntries count] == 0 )
				returnEntries = nil;
		}
		
		else
		{
			// if not, save the entry for an import once we are finished launching
			filesToOpenAtLaunch = [destinationPaths retain];
			returnEntries = nil;
		}
	}
	
	else
	{
		returnEntries = nil;
	}
	
	return returnEntries;
}

- (void) serviceSelection:(NSPasteboard *)pboard 
		userData:(NSString *)userData 
		error:(NSString **)error
{
	static NSString *kPDUTTypeURLName = @"public.url-name";
	NSArray *types = [NSArray arrayWithObjects: kMailMessagePboardType, NSFilenamesPboardType, 
			NSTIFFPboardType, NSPICTPboardType, 
			NSRTFDPboardType, NSRTFPboardType, WebURLsWithTitlesPboardType, kMailMessagePboardType, 
			NSURLPboardType, NSStringPboardType, kPDUTTypeURLName, nil];
	
	NSArray *pasteboardEntries = [self entriesForPasteboardData:pboard 
			visual:NO 
			preferredTypes:types];
	
	if ( pasteboardEntries != nil )
	{
		if ( defaultBool(@"UseVisualAidWherePossibleWhenImporting") )
		{
			// clear out the categories
			[pasteboardEntries setValue:nil forKey:@"category"];
			
			// run the visual aid if requested
			DropBoxDialog *dropBoxDialog = [[[DropBoxDialog alloc] initWithJournal:[self journal] delegate:self
			 mode:1 didEndSelector:@selector(servicesImport:didEndDialog:contents:)] autorelease];
			
			[dropBoxDialog setTagCompletions:[[[self journal] entryTags] allObjects]];
			if ( [pasteboardEntries count] == 1 )
				[dropBoxDialog setTags:[[pasteboardEntries objectAtIndex:0] valueForKey:@"tags"]];
			
			[dropBoxDialog setRepresentedObject:pasteboardEntries];
			[dropBoxDialog setContent:[DropBoxDialog contentForEntries:pasteboardEntries]];
			[dropBoxDialog showWindow:self];
		
		}
		else
		{
			// use the default drop box category
			[pasteboardEntries setValue:[JournlerEntry dropBoxCategory] forKey:@"category"];
			
			// just select the entry
			JournlerEntry *servicedEntry = [pasteboardEntries objectAtIndex:0];
			[[[self journalWindowController] selectedTab] selectEntries:[NSArray arrayWithObject:servicedEntry]];
					//selectDate:nil folders:nil entries:[NSArray arrayWithObject:servicedEntry] resources:nil];
			
			[(NSSound*)[NSSound soundNamed:@"dropbox"] play];
			dropBoxing = NO;
		}
}
	else
	{
		// throw up a warning, letting the user know the service encountered problems
		NSBeep();
		[[NSAlert servicesMenuFailure] runModal];
	}
	
}

- (void)appendSelection:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error
{
	NSArray *types = [NSArray arrayWithObjects: NSTIFFPboardType, NSPICTPboardType, 
			NSRTFDPboardType, NSRTFPboardType, WebURLsWithTitlesPboardType, NSURLPboardType, NSStringPboardType, nil];
	
	NSString *desiredType = [pboard availableTypeFromArray:types];
	
	JournlerWindowController *mainWindow = [self mainWindowIgnoringActive];
	if ( mainWindow == nil )
		mainWindow = journalWindowController;
	
	[mainWindow servicesMenuAppendSelection:pboard desiredType:desiredType];
}

- (void) servicesImport:(DropBoxDialog*)aDialog didEndDialog:(NSInteger)result contents:(NSArray*)contents
{
	NSArray *targetTags = [aDialog tags];
	NSString *targetCategory = [aDialog category];
	NSArray *targetFolders = [aDialog selectedFolders];
	
	if ( result == NSRunAbortedResponse )
	{
		// user canceled, completely remove the import having just created it
		for ( NSDictionary *aDictionary in contents )
        {
			JournlerEntry *anEntry = [aDictionary objectForKey:@"representedObject"];
			[[self journal] deleteEntry:anEntry];
		}
	}
	
	else if ( result == NSRunStoppedResponse )
	{
		for ( NSDictionary *aDictionary in contents )
        {
			JournlerEntry *anEntry = [aDictionary objectForKey:@"representedObject"];
			
			// the title
			NSString *aTitle = [aDictionary objectForKey:@"title"];
			[anEntry setValue:aTitle forKey:@"title"];
			
			if ( [[anEntry resources] count] != 0 )
				[[[anEntry resources] objectAtIndex:0] setValue:aTitle forKey:@"title"];
			
			if ( targetTags != nil )
			{
				/*
				NSString *newTags;
				if ( [[anEntry keywords] length] > 0 )
					newTags = [NSString stringWithFormat:@"%@ %@", [anEntry keywords], targetTags];
				else
					newTags = targetTags;
				*/
				#warning need to convert document keywords to tags and not put in comments field?
				[anEntry setValue:targetTags forKey:@"tags"];
			}
				
			if ( targetCategory != nil && ![[anEntry category] isEqualToString:targetCategory] )
			{
				NSString *newCategory;
				if ( [[anEntry category] length] > 0 )
					newCategory = [NSString stringWithFormat:@"%@ %@", [anEntry category], targetCategory];
				else
					newCategory = targetCategory;
				[anEntry setValue:newCategory forKey:@"category"];
			}
				
			if ( targetFolders != nil )
			{
                for ( JournlerCollection *targetFolder in targetFolders )
				{
					if ( [targetFolder isRegularFolder] )
						[targetFolder addEntry:anEntry];
					else if ( [targetFolder isSmartFolder] && [targetFolder canAutotag:anEntry] )
						[targetFolder autotagEntry:anEntry add:YES];
				}
			}
		}
		
		// select the entry
		JournlerEntry *servicedEntry = [[aDialog representedObject] objectAtIndex:0];
		[[[self journalWindowController] selectedTab] selectEntries:[NSArray arrayWithObject:servicedEntry]];
			//	selectDate:nil folders:nil entries:[NSArray arrayWithObject:servicedEntry] resources:nil];
		
		[(NSSound*)[NSSound soundNamed:@"dropbox"] play];
	}
	
	// return to the previous application
	if ( ![[[aDialog activeApplication] objectForKey:@"NSApplicationName"] isEqualToString:@"Journler"] )
	[[NSWorkspace sharedWorkspace] launchApplication:[[aDialog activeApplication] objectForKey:@"NSApplicationName"]];
	dropBoxing = NO; 
	[aDialog performSelector:@selector(close) withObject:nil afterDelay:0.1];	
}

#pragma mark -

- (IBAction) newEntry:(id)sender
{
	[[self journalWindowController] performSelector:@selector(newEntry:) withObject:sender];
}

- (IBAction) newEntryWithClipboardContents:(id)sender
{
	[[self journalWindowController] performSelector:@selector(newEntryWithClipboardContents:) withObject:sender];
}

#pragma mark -

- (IBAction) showTermIndex:(id)sender
{
	TermIndexWindowController *indexViewer = [[[TermIndexWindowController alloc] initWithJournal:[self journal]] autorelease];
	[indexViewer showWindow:self];
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	BOOL enabled = YES;
	//NSInteger tag = [menuItem tag];
	SEL action = [menuItem action];
	
	if ( action == @selector(toggleContinuousSpellcheckingAppwide:) )
		[menuItem setState:( [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryTextEnableSpellChecking"] )];
	
	else if ( action == @selector(lockJournal:) )
		enabled = [[NSFileManager defaultManager] fileExistsAtPath:[[[self journal] journalPath] stringByAppendingPathComponent:PDJournalPasswordProtectedLoc]];
		
	else if ( action == @selector(toggleAutoCorrectSpelling:) )
		enabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryTextAutoCorrectSpelling"];
	
	else if ( action == @selector(newEntry:) )
		[menuItem setTitle:NSLocalizedString( ( [[NSUserDefaults standardUserDefaults] boolForKey:@"QuickEntryCreation"] 
		? @"menuitem new entry quick" : @"menuitem new entry extended" ), @"")];
	
	/*
	else if ( action == @selector(performCustomFindPanelAction:) )
	{
		// first look for a target that responds to the normal find action
		#warning could very well cause an endless loop (see Adam Bell's note)
		
		id aTarget = [NSApp targetForAction:@selector(performFindPanelAction:) to:nil from:menuItem];
		if ( aTarget != nil )
		{
			[menuItem setAction:@selector(performFindPanelAction:)];
			
			if ( [aTarget respondsToSelector:@selector(validateMenuItem:)] )
				enabled = [aTarget validateMenuItem:menuItem];
			else
				enabled = YES;
			
			[menuItem setAction:@selector(performCustomFindPanelAction:)];
			
			if ( enabled == NO )
			{
				// try for a target that responds to the regular find action
				id aTarget = [NSApp targetForAction:@selector(performCustomFindPanelAction:) to:nil from:menuItem];
				if ( aTarget == nil ) 
					enabled = NO;
				else if ( [aTarget respondsToSelector:@selector(validateMenuItem:)] )
					enabled = [aTarget validateMenuItem:menuItem];
				else
					enabled = YES;
			}
		}

		else
		{
			// try for a target that responds to the regular find action
			id aTarget = [NSApp targetForAction:@selector(performCustomFindPanelAction:) to:nil from:menuItem];
			if ( aTarget == nil ) 
				enabled = NO;
			else if ( [aTarget respondsToSelector:@selector(validateMenuItem:)] )
				enabled = [aTarget validateMenuItem:menuItem];
			else
				enabled = YES;
		}
	}
	
	else if ( action == @selector(performCustomTextSizeAction:) )
	{
		// first look for a target that responds to the normal modifyFont font panel action
		id aTarget = [NSApp targetForAction:@selector(changeFont:) to:nil from:menuItem];
		if ( aTarget != nil )
		{
			[menuItem setAction:@selector(changeFont:)];
			
			if ( [aTarget respondsToSelector:@selector(validateMenuItem:)] )
				enabled = [aTarget validateMenuItem:menuItem];
			else
				enabled = YES;
			
			[menuItem setAction:@selector(performCustomTextSizeAction:)];
			
			if ( enabled == NO )
			{
				// try for a target that responds to the regular find action
				id aTarget = [NSApp targetForAction:@selector(performCustomTextSizeAction:) to:nil from:menuItem];
				if ( aTarget == nil ) 
					enabled = NO;
				else if ( [aTarget respondsToSelector:@selector(validateMenuItem:)] )
					enabled = [aTarget validateMenuItem:menuItem];
				else
					enabled = YES;
			}
		}

		else
		{
			// try for a target that responds to the regular find action
			id aTarget = [NSApp targetForAction:@selector(performCustomTextSizeAction:) to:nil from:menuItem];
			if ( aTarget == nil ) 
				enabled = NO;
			else if ( [aTarget respondsToSelector:@selector(validateMenuItem:)] )
				enabled = [aTarget validateMenuItem:menuItem];
			else
				enabled = YES;
		}
	}
	*/
	
	return enabled;
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem 
{	
	BOOL enabled = YES;
	//NSString *identifier = [toolbarItem itemIdentifier];
	
	if ( [toolbarItem action] == @selector(lockJournal:) )
	{
		enabled = [[NSFileManager defaultManager] fileExistsAtPath:[[[self journal] journalPath] stringByAppendingPathComponent:PDJournalPasswordProtectedLoc]];
	}
	
	return enabled;
}

#pragma mark -

- (NSString *)applicationSupportFolder {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
	return basePath;
}

- (NSString*) libraryFolder {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
	return basePath;
}

- (NSString*) documentsFolder {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
	return basePath;
}

@end

#pragma mark -

@implementation JournlerApplicationDelegate (ApplicationUtilities)

+ (BOOL)sendRichMail:(NSAttributedString *)richBody to:(NSString *)to subject:(NSString *)subject isMIME:(BOOL)isMIME withNSMail:(BOOL)wM
{
	NSMutableDictionary *toFromDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
	to,@"to",subject,@"subject",NSFullUserName(),@"from",NULL];

	NSString *from = [[NSUserDefaults standardUserDefaults] objectForKey:@"IDEmail"];
	if (from) [toFromDict setObject:from forKey:@"from"];
	
	BOOL success = YES;

	// 1. Attempt to send a mail using the delivery framework ----------------

	// Can we even use the mail framework?
	
	if ( wM && [NSMailDelivery hasDeliveryClassBeenConfigured]) {
		
		// we use error handling in case there is trouble in the NSMailDelivery framework

		@try 
		{
			// first we try SMPT, then if that fails, we try sendmail:
			if ( ![NSMailDelivery deliverMessage:richBody headers:toFromDict 
					format:isMIME?NSMIMEMailFormat:NSASCIIMailFormat protocol:NSSMTPDeliveryProtocol] )
				[NSMailDelivery deliverMessage:richBody headers:toFromDict 
				format:isMIME?NSMIMEMailFormat:NSASCIIMailFormat protocol:NSSendmailDeliveryProtocol];
		}

		@catch (NSException *localException) 
		{
			NSLog(@"NSMailDelivery: an exception was raised: %@",[localException reason]);
			success = NO;
		}
		@finally
		{
		
		}
	
	}
	else {
		success = NO;
	}
	
	// 2. Check the result here, if failure, attempt to send using nsurl ------------
	
	if ( !success ) {
		
		NSInteger result = NSAlertFirstButtonReturn;
		
		if ( wM ) {
			
			//only display the alert panel if we originally tried to send with nsmail
			
			NSAlert *mailAlert = [NSAlert alertWithMessageText:@"Unable to send entry to Blogger.com" 
				defaultButton:@"Send" alternateButton:@"Cancel" otherButton:nil 
				informativeTextWithFormat:@"Journler was unable to send an email using your system settings. Would you like send this entry with your default mail client?"];
				
			[mailAlert setShowsHelp:YES];
			[mailAlert setHelpAnchor:@"Journler Blog Help"];
				
			result = [mailAlert runModal];
			
		}
		
		if ( result == NSAlertFirstButtonReturn || result == 1 ) {
			
			//construct the nsurl using our dictionary
			
			//prepre the body text
			NSMutableString *parsed = [[NSMutableString alloc] initWithString:[richBody string]];
			//get rid of attachment plus new line
			[parsed replaceOccurrencesOfString:[NSString stringWithCharacters:(const unichar[]) {NSAttachmentCharacter, '\n'} length:2] 
				withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [parsed length])];
			[parsed replaceOccurrencesOfString:[NSString stringWithCharacters:(const unichar[]) {NSAttachmentCharacter, '\r'} length:2] 
				withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [parsed length])];
			//get rid of attachment alone
			[parsed replaceOccurrencesOfString:[NSString stringWithCharacters:(const unichar[]) {NSAttachmentCharacter} length:1] 
				withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [parsed length])];
			
			//
			// MEMORY LEAK HERE WITH CFURLCREATESTRINGBYADDINGPERCENTESCAPES
			
			//encode the url
			NSMutableString *encodedBody = [[NSMutableString alloc] initWithFormat:@"BODY=%@", 
				(NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)parsed, NULL,NULL, kCFStringEncodingUTF8)];
			[encodedBody replaceOccurrencesOfString:@"&" withString:@"%26" options:NSLiteralSearch range:NSMakeRange(0, [parsed length])];
			
			NSMutableString *encodedSubject = [[NSMutableString alloc] initWithFormat:@"SUBJECT=%@", 
				(NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)subject, NULL,NULL, kCFStringEncodingUTF8)];
			[encodedSubject replaceOccurrencesOfString:@"&" withString:@"%26" options:NSLiteralSearch range:NSMakeRange(0, [encodedSubject length])];
			
			NSString *encodedURLString = [[NSString alloc] initWithFormat:@"mailto:%@?%@&%@", to, encodedSubject, encodedBody]; 
			NSURL *mailtoURL = [[NSURL alloc] initWithString:encodedURLString]; 
			if ( !mailtoURL )
			{
				success = NO;
				NSLog(@"%s - unable to create URL from encoded string %@", __PRETTY_FUNCTION__, encodedURLString);
			}
			
			//send it off to default mail client
			if ( ![[NSWorkspace sharedWorkspace] openURL:mailtoURL] )
			{
				success = NO;
				NSLog(@"%s - unable to launch URL %@", __PRETTY_FUNCTION__, mailtoURL);
			}
			
			//clean up
			[mailtoURL release];
			[encodedURLString release];
			[parsed release];
			[encodedBody release];
			[encodedSubject release];
			
			success = YES;
		}
		else {
			success = NO;
		}
	}
	
	return success;
}

+ (NSMenu*) menuForFolder:(NSString*)path menuTarget:(id)target targetSelector:(SEL)selector 
{
	// recursive construction of a menu based on the contents of the folder at path
	
	NSInteger i;
	BOOL dir;
	NSArray *pathContents;
	NSFileManager *fm = [NSFileManager defaultManager];
	
	NSString *lastPathComponent = [path lastPathComponent];
	if ( lastPathComponent == nil ) lastPathComponent = [NSString string];
	NSMenu *returnMenu = [[[NSMenu alloc] initWithTitle:lastPathComponent] autorelease];
	
	// make sure we are dealing with a directory
	if ( ![fm fileExistsAtPath:path isDirectory:&dir] || !dir )
		return nil;
	
	// set the menu's target - set the target of each item as well
	
	// get the directory's contents
	pathContents = [fm directoryContentsAtPath:path];
	
	// iterate through each item in the directory
	for ( i = 0; i < [pathContents count]; i++ ) 
	{
		// skip this item if it is invisible
		if ( [[pathContents objectAtIndex:i] characterAtIndex:0] == '.' )
			continue;
		
		// get the working path
		NSString *workingPath = [path stringByAppendingPathComponent:[pathContents objectAtIndex:i]];
		NSString *workingPathLastComponent = [[workingPath lastPathComponent] stringByDeletingPathExtension];
		if ( workingPathLastComponent == nil ) workingPathLastComponent = [NSString string];
		
		// set up a menu item
		NSMenuItem *menuItem = [[[NSMenuItem alloc] 
				initWithTitle:workingPathLastComponent 
				action:selector 
				keyEquivalent:@""] autorelease];
		
		// target and represented object
		[menuItem setTarget:target];
		[menuItem setRepresentedObject:[NSURL fileURLWithPath:workingPath]];
			
		// menu icon
		NSImage *subIcon = [[NSWorkspace sharedWorkspace] iconForFile:workingPath];
		[subIcon setScalesWhenResized:YES];
		[subIcon setSize:NSMakeSize(16,16)];
			
		[menuItem setImage:subIcon];
		
		// if this item is a directory but not a package, recursion and set up a submenu for the item
		if ( [fm fileExistsAtPath:workingPath isDirectory:&dir] && dir && ![[NSWorkspace sharedWorkspace] isFilePackageAtPath:workingPath] ) 
		{
			//NSMenu *submenu = [JUtility menuForFolder:workingPath menuTarget:target targetSelector:selector];
			NSMenu *submenu = [JournlerApplicationDelegate menuForFolder:workingPath menuTarget:target targetSelector:selector];
			if ( submenu != nil ) [menuItem setSubmenu:submenu];
		}
		
		// add the menu item to the menu
		[returnMenu addItem:menuItem];
	}
	
	// return the menu autoreleased
	return returnMenu;
}

@end

/*
#pragma mark -

@implementation JournlerApplicationDelegate (FindPanelSupport)

- (IBAction) performCustomFindPanelAction:(id)sender
{
	// try for a target that responds to the standard find panel action
	id aTarget = [NSApp targetForAction:@selector(performFindPanelAction:) to:nil from:sender];
	
	// prevent any web view classes from taking the find command
	if ( [[aTarget className] rangeOfString:@"Web" options:NSCaseInsensitiveSearch].location != NSNotFound )
		aTarget = nil;
	
	if ( aTarget != nil )
	{
		// found one, perform it
		[sender setAction:@selector(performFindPanelAction:)];
		[aTarget performSelector:@selector(performFindPanelAction:) withObject:sender];
		[sender setAction:@selector(performCustomFindPanelAction:)];
	}
	else
	{
		// if we made it this far, retarget the first responder
		aTarget = [NSApp targetForAction:@selector(performCustomFindPanelAction:) to:nil from:sender];
		if ( aTarget == nil )
			NSBeep();
		else [aTarget performSelector:@selector(performCustomFindPanelAction:) withObject:sender];
	}

}

- (void) setFindPanelPerformsCustomAction:(NSNumber*)perfomCustomAction
{
	SEL oldSelector = ( [perfomCustomAction boolValue] ? @selector(performFindPanelAction:) : @selector(performCustomFindPanelAction:) );
	SEL newSelector = ( [perfomCustomAction boolValue] ? @selector(performCustomFindPanelAction:) : @selector(performFindPanelAction:) );
	
	NSMenuItem *menuItem;
	NSEnumerator *enumerator = [[findMenu itemArray] objectEnumerator];
	
	while ( menuItem = [enumerator nextObject] )
	{
		if ( [menuItem action] == oldSelector )
			[menuItem setAction:newSelector];
	}
}


- (IBAction) performCustomTextSizeAction:(id)sender
{
	// modifyFont: to the shared font manager
	// first reponder must respond to changeFont:
	
	// try for a target that responds to the standard changeFont font panel action
	id aTarget = [NSApp targetForAction:@selector(changeFont:) to:nil from:sender];
	
	// prevent any web view classes from taking the find command
	//if ( [[aTarget className] rangeOfString:@"Web" options:NSCaseInsensitiveSearch].location != NSNotFound )
	//	aTarget = nil;
	
	if ( aTarget != nil )
	{
		// found one, perform the font panel action
		[[NSFontManager sharedFontManager] modifyFont:sender];
		//[sender setAction:@selector(performFindPanelAction:)];
		//[aTarget performSelector:@selector(performFindPanelAction:) withObject:sender];
		//[sender setAction:@selector(performCustomFindPanelAction:)];
	}
	else
	{
		// if we made it this far, retarget the first responder
		aTarget = [NSApp targetForAction:@selector(performCustomTextSizeAction:) to:nil from:sender];
		if ( aTarget == nil )
			NSBeep();
		else [aTarget performSelector:@selector(performCustomTextSizeAction:) withObject:sender];
	}

}

- (void) setTextSizePerformsCustomAction:(NSNumber*)performCustomAction
{
	
	if ( [performCustomAction boolValue] )
	{
		[biggerItem setTarget:nil];
		[smallerItem setTarget:nil];
		[biggerItem setAction:@selector(performCustomTextSizeAction:)];
		[smallerItem setAction:@selector(performCustomTextSizeAction:)];
	}
	else
	{
		[biggerItem setTarget:[NSFontManager sharedFontManager]];
		[smallerItem setTarget:[NSFontManager sharedFontManager]];
		[biggerItem setAction:@selector(modifyFont:)];
		[smallerItem setAction:@selector(modifyFont:)];
	}
	
}

@end
*/

#pragma mark -

@implementation JournlerApplicationDelegate (JournlerScripting)

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key 
{ 
	if ([key isEqualToString: @"JSTab"])
		return YES;
	else if ([key isEqualToString: @"JSFolders"])
		return YES;
	else if ([key isEqualToString:@"JSEntries"])
		return YES;
	else if ( [key isEqualToString:@"JSBlogs"] )
		return YES;
	else if ( [key isEqualToString:@"JSReferences"] )
		return YES;
	else if ([key isEqualToString:@"JSSelectedEntry"])
		return YES;
	else if ([key isEqualToString:@"JSSelectedFolder"])
		return YES;
	else if ([key isEqualToString:@"JSSelectedTab"])
		return YES;
	else if ([key isEqualToString:@"JSSelectedDate"])
		return YES;
	else if ([key isEqualToString:@"JSJournalFolder"])
		return YES;
	else if ([key isEqualToString:@"JSJournalVersion"])
		return YES;
	else if ([key isEqualToString:@"JSJournalName"])
		return YES;
	else if ( [key isEqualToString:@"JSJournalViewer"] )
		return YES;
	else if ( [key isEqualToString:@"JSCategories"] )
		return YES;
		
	else if ([key isEqualToString:@"scriptSelectedEntries"])
		return YES;
	else if ([key isEqualToString:@"scriptSelectedDate"])
		return YES;
	else if ([key isEqualToString:@"scriptSelectedFolders"])
		return YES;
	else if ([key isEqualToString:@"scriptSelectedResources"])
		return YES;	
	
	else
		return NO; 
		
}

#pragma mark -
#pragma mark Some Properties

- (NSWindow*) JSJournalViewer
{
	return [[self journalWindowController] window];
}

- (NSString*) JSJournalVersion
{
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

- (NSArray*) JSCategories
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"Journler Categories List"];
}

- (void) setJSCategories:(NSArray*)categories
{
	[[NSUserDefaults standardUserDefaults] setObject:[categories sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] 
	forKey:@"Journler Categories List"];
}

#pragma mark -

- (NSDate*) scriptSelectedDate
{
	return [[[self mainWindowIgnoringActive] selectedTab] selectedDate];
}

- (void) setScriptSelectedDate:(NSDate*)aDate
{
	[[[self mainWindowIgnoringActive] selectedTab] selectDate:aDate];
}

- (NSArray*) scriptSelectedFolders
{
	return [[[self mainWindowIgnoringActive] selectedTab] selectedFolders];
}

- (void) setScriptSelectedFolders:(NSArray*)anArray
{
	NSArray *theActualObjects = nil;
	
	if ( [anArray count] > 0 && [[anArray objectAtIndex:0] respondsToSelector:@selector(objectsByEvaluatingSpecifier)] )
		theActualObjects = [anArray valueForKey:@"objectsByEvaluatingSpecifier"];
	else
		theActualObjects = anArray;

	[[[self mainWindowIgnoringActive] selectedTab] selectFolders:theActualObjects];
}

- (NSArray*) scriptSelectedEntries
{
	return [[[self mainWindowIgnoringActive] selectedTab] selectedEntries];
}

- (void) setScriptSelectedEntries:(NSArray*)anArray
{
	NSArray *theActualObjects = nil;
	
	if ( [anArray count] > 0 && [[anArray objectAtIndex:0] respondsToSelector:@selector(objectsByEvaluatingSpecifier)] )
		theActualObjects = [anArray valueForKey:@"objectsByEvaluatingSpecifier"];
	else
		theActualObjects = anArray;
		
	[[[self mainWindowIgnoringActive] selectedTab] selectEntries:theActualObjects];
}

- (NSArray*) scriptSelectedResources
{
	return [[[self mainWindowIgnoringActive] selectedTab] selectedResources];
}

- (void) setScriptSelectedResources:(NSArray*)anArray
{
	NSArray *theActualObjects = nil;
	
	if ( [anArray count] > 0 && [[anArray objectAtIndex:0] respondsToSelector:@selector(objectsByEvaluatingSpecifier)] )
		theActualObjects = [anArray valueForKey:@"objectsByEvaluatingSpecifier"];
	else
		theActualObjects = anArray;

	[[[self mainWindowIgnoringActive] selectedTab] selectResources:theActualObjects];
}

#pragma mark -
#pragma mark Scripting Entries

//
// by implementing this kind of keyvalue coding, we prevent applescript from directly accessing the arrays 

- (NSInteger) indexOfObjectInJSEntries:(JournlerEntry*)anEntry 
{
	return [[self valueForKeyPath:@"journal.entries"] indexOfObject:anEntry];
}

- (NSUInteger) countOfJSEntries 
{
	return [[self valueForKeyPath:@"journal.entries"] count];
}

- (JournlerEntry*) objectInJSEntriesAtIndex:(NSUInteger)i 
{
	if ( i >= [[self valueForKeyPath:@"journal.entries"] count] ) 
	{
		[self returnError:OSAIllegalIndex string:nil];
		return nil;
	}
	else
	{
		return [[self valueForKeyPath:@"journal.entries"] objectAtIndex:i];
	}
}

- (JournlerEntry*) valueInJSEntriesWithUniqueID:(NSNumber*)idNum 
{
	return [[self valueForKeyPath:@"journal.entriesDictionary"] objectForKey:idNum];
}

#pragma mark -

- (void) insertObject:(JournlerEntry*)anEntry inJSEntriesAtIndex:(NSUInteger)index 
{
	[self JSAddNewEntry:anEntry atIndex:index];
}

- (void) insertInJSEntries:(JournlerEntry*)anEntry 
{
	[self JSAddNewEntry:anEntry atIndex:0];
}

- (void) JSAddNewEntry:(JournlerEntry*)anEntry atIndex:(NSUInteger)index 
{
	
	// ensure the unique id
	[anEntry setTagID:[NSNumber numberWithInteger:[[self journal] newEntryTag]]];
	
	// check the date - will prduce incorrect date (an entry always has a date)
	if ( ![anEntry calDate] ) 
		[anEntry setCalDate:[NSCalendarDate calendarDate]];
	
	// set the date modified
	[anEntry setCalDateModified:[NSCalendarDate calendarDate]];	
	
	// check the category
	//if ( ![anEntry category] || [[anEntry category] length] == 0 )
	//	[anEntry setCategory:NSLocalizedString(@"applescript category", @"")];
	
	// prepare the untitled title
	if ( ![anEntry title] || [[anEntry title] length] == 0 ) 
	{
		
		NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
		[formatter setDateStyle:NSDateFormatterLongStyle];
		[formatter setTimeStyle:NSDateFormatterNoStyle];
		NSString *dateString = [formatter stringFromDate:[anEntry valueForKey:@"calDate"]];
		NSString *title = [NSString stringWithFormat:NSLocalizedString(@"dated untitled title", @""), dateString];
		
		[anEntry setValue:title forKey:@"title"];
	}
	
	// check the content, but only after the entry has been saved
	if ( ![anEntry attributedContent] || [[anEntry attributedContent] length] == 0 )
	{
		// default attributed content
		NSAttributedString *attributedContent = [[[NSAttributedString alloc] 
				initWithString:[NSString string] attributes:[JournlerEntry defaultTextAttributes]] autorelease];
		
		[anEntry setValue:attributedContent forKey:@"attributedContent"];
	}
	else 
	{
		// apply the default fonts to the content (not yet possible to work with attributed content)
	
		NSDictionary *default_attrs = [JournlerEntry defaultTextAttributes];
		NSMutableAttributedString *validatedContent = [[[NSMutableAttributedString alloc] 
				initWithAttributedString:[anEntry attributedContent]] autorelease];
		
		[validatedContent setAttributes:default_attrs range:NSMakeRange(0,[validatedContent length])];
		[anEntry setAttributedContent:validatedContent];
	}
	
	// set the journal so that link processing works
	[anEntry setJournal:[self journal]];
	
	// process the content for links and whatnot now that it has a journal
	if ( [[anEntry attributedContent] respondsToSelector:@selector(URLAtIndex:effectiveRange:)] && [anEntry journal] != nil 
				&& ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryTextRecognizeURLs"] 
				|| [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryTextRecognizeWikiLinks"] ) )
	{
		NSAttributedString *processedAttributedContent = [anEntry processScriptSetContentsForLinks:[anEntry attributedContent]];
		[anEntry setAttributedContent:processedAttributedContent];
	}
	
	// add the entry to the journal 
	[[self journal] addEntry:anEntry];
		
	// save the entry
	[[self journal] saveEntry:anEntry];
}

#pragma mark -

-(void) removeObjectFromJSEntriesAtIndex:(NSUInteger)index 
{
	if ( index >= [[self valueForKeyPath:@"journal.entries"] count] ) 
	{
		// raise an error
		[self returnError:OSAIllegalIndex string:nil]; 
		return;
	}
	
	[self JSDeleteEntry:[[self valueForKeyPath:@"journal.entries"] objectAtIndex:index]];
	
} 
-(void) removeFromSJSEntriesAtIndex:(NSUInteger)index 
{ 
	if ( index >= [[self valueForKeyPath:@"journal.entries"] count] ) 
	{
		// raise an error
		[self returnError:OSAIllegalIndex string:nil]; 
		return;
	}
	
	[self JSDeleteEntry:[[self valueForKeyPath:@"journal.entries"] objectAtIndex:index]];

} 

- (void) JSDeleteEntry:(JournlerEntry*)anEntry 
{
	[[self journal] markEntryForTrash:anEntry];
}

#pragma mark -
#pragma mark Scripting Folders

- (NSInteger) indexOfObjectInJSFolders:(JournlerCollection*)aFolder 
{
	return [[self valueForKeyPath:@"journal.collections"] indexOfObject:aFolder];
}

- (NSUInteger) countOfJSFolders
{ 
	return [[self valueForKeyPath:@"journal.collections"] count];
}

- (JournlerCollection*) objectInJSFoldersAtIndex:(NSUInteger)i 
{
	if ( i >= [[self valueForKeyPath:@"journal.collections"] count] ) 
	{
		[self returnError:OSAIllegalIndex string:nil];
		return nil;
	}
	else
	{
		return [[self valueForKeyPath:@"journal.collections"] objectAtIndex:i];
	}
}

- (JournlerCollection*) valueInJSFoldersWithUniqueID:(NSNumber*)idNum
{
	return [[self valueForKeyPath:@"journal.collectionsDictionary"] objectForKey:idNum];
}

#pragma mark -

- (void)insertObject:(JournlerCollection*)aFolder inJSFoldersAtIndex:(NSUInteger)index 
{
	[self JSAddNewFolder:aFolder atIndex:index];
}

- (void)insertInJSFolders:(JournlerCollection*)aFolder 
{
	[self JSAddNewFolder:aFolder atIndex:0];
}

- (void) JSAddNewFolder:(JournlerCollection*)aFolder atIndex:(NSUInteger)index 
{
	// ensure the folder has a valid id
	[aFolder setTagID:[NSNumber numberWithInteger:[[self journal] newFolderTag]]];
	
	// ensure the folder's title is valid
	if ( [aFolder title] == nil || [[aFolder title] length] == 0 )
		[aFolder setTitle:@"New Collection"];
		
	// ensure the type id is valid
	if ( [[aFolder typeID] integerValue] == 0 || [[aFolder typeID] integerValue] == PDCollectionTypeIDLibrary || 
			[[aFolder typeID] integerValue] == PDCollectionTypeIDTrash )
		[aFolder setTypeID:[NSNumber numberWithInteger:PDCollectionTypeIDFolder]];
		
	// ensure the icon matches the type id
	[aFolder determineIcon];

	// add the folder to the root collection
	[[[self journal] rootCollection] addChild:aFolder atIndex:-1];
	
	// add the folder to the journal
	[[self journal] addCollection:aFolder];
	
	// collect the entries if this is a smart folder
	if ( [aFolder isSmartFolder] )
		[aFolder evaluateAndAct:[self valueForKeyPath:@"journal.entries"] considerChildren:NO];
	
	// ensure the various key-value observers are informed of what's going on
	[[self journal] setRootFolders:nil];

}

#pragma mark -

- (void) removeObjectFromJSFoldersAtIndex:(NSUInteger)index 
{
	if ( index >= [[self valueForKeyPath:@"journal.collections"] count] ) 
	{
		// raise an error
		[self returnError:OSAIllegalIndex string:nil]; 
		return;
	}
	
	[self JSDeleteFolder:[[self valueForKeyPath:@"journal.collections"] objectAtIndex:index]];
	
}

- (void) removeFromJSFoldersAtIndex:(NSUInteger)index 
{
	if ( index >= [[self valueForKeyPath:@"journal.collections"] count] ) 
	{
		// raise an error
		[self returnError:OSAIllegalIndex string:nil]; 
		return;
	}
	
	[self JSDeleteFolder:[[self valueForKeyPath:@"journal.collections"] objectAtIndex:index]];
	
}

- (void) JSDeleteFolder:(JournlerCollection*)aFolder 
{
	if ( [aFolder isLibrary] || [aFolder isTrash] )
	{
		// raise an error - do not delete the library collection or the trash
		[self returnError:OSAIllegalAccess string:@"Cannot delete the journal collection"];
		return;
	}
	
	[[self journal] deleteCollection:aFolder deleteChildren:YES];
	
	// ensure the various key-value observers are informed of what's going on
	//[[self journal] setRootFolders:nil];

}

#pragma mark -
#pragma mark Scripting References

- (NSInteger) indexOfObjectInJSReferences:(JournlerResource*)aReference
{
	return [[self valueForKeyPath:@"journal.resources"] indexOfObject:aReference];
}

- (NSUInteger) countOfJSReferences
{ 
	return [[self valueForKeyPath:@"journal.resources"] count];
}

- (JournlerResource*) objectInJSReferencesAtIndex:(NSUInteger)i
{
	if ( i >= [[self valueForKeyPath:@"journal.resources"] count] ) 
	{
		[self returnError:OSAIllegalIndex string:nil];
		return nil;
	}
	else
	{
		return [[self valueForKeyPath:@"journal.resources"] objectAtIndex:i];
	}
}

- (JournlerResource*) valueInJSReferencesWithUniqueID:(NSNumber*)idNum
{
	return [[self valueForKeyPath:@"journal.resourcesDictionary"] objectForKey:idNum];
}

#pragma mark -

- (void) insertObject:(JournlerResource*)aReference inJSReferencesAtIndex:(NSUInteger)index
{
	[self JSAddNewReference:aReference atIndex:index];
}

- (void) insertInJSReferences:(JournlerResource*)aReference
{
	[self JSAddNewReference:aReference atIndex:0];
}

- (void) JSAddNewReference:(JournlerResource*)aResource atIndex:(NSUInteger)index
{
	// a rather complex process verifying the validity of the resource - everything must be set at the get go
	// actually, we may never make it this far
	
	NSLog(@"%s",__PRETTY_FUNCTION__);
}


#pragma mark -

- (void) removeObjectFromJSReferencesAtIndex:(NSUInteger)index
{
	if ( index >= [[self valueForKeyPath:@"journal.resources"] count] ) 
	{
		// raise an error
		[self returnError:OSAIllegalIndex string:nil]; 
		return;
	}
	
	[self JSDeleteReference:[[self valueForKeyPath:@"journal.resources"] objectAtIndex:index]];
	
}

- (void) removeFromJSReferencesAtIndex:(NSUInteger)index
{
	if ( index >= [[self valueForKeyPath:@"journal.resources"] count] ) 
	{
		// raise an error
		[self returnError:OSAIllegalIndex string:nil]; 
		return;
	}
	
	[self JSDeleteReference:[[self valueForKeyPath:@"journal.resources"] objectAtIndex:index]];
	
}

- (void) JSDeleteReference:(JournlerResource*)aReference
{
	[[self journal] deleteResource:aReference];
}

#pragma mark -
#pragma mark Scripting Blogs

- (NSInteger) indexOfObjectInJSBlogs:(BlogPref*)aBlog
{
	return [[self valueForKeyPath:@"journal.blogs"] indexOfObject:aBlog];
}

- (NSUInteger) countOfJSBlogs
{
	return [[self valueForKeyPath:@"journal.blogs"] count];
}

- (BlogPref*) objectInJSBlogsAtIndex:(NSUInteger)i
{
	if ( i >= [[self valueForKeyPath:@"journal.blogs"] count] ) 
	{
		[self returnError:OSAIllegalIndex string:nil];
		return nil;
	}
	else
	{
		return [[self valueForKeyPath:@"journal.blogs"] objectAtIndex:i];
	}
}

- (BlogPref*) valueInJSBlogsWithUniqueID:(NSNumber*)idNum
{
	return [[self valueForKeyPath:@"journal.blogsDictionary"] objectForKey:idNum];
}

#pragma mark -

- (void) insertObject:(BlogPref*)aBlog inJSBlogsAtIndex:(NSUInteger)index
{
	[self JSAddNewBlog:aBlog atIndex:index];
}

- (void) insertInJSBlogs:(BlogPref*)aBlog
{
	[self JSAddNewBlog:aBlog  atIndex:0];
}

- (void) JSAddNewBlog:(BlogPref*)aBlog atIndex:(NSUInteger)index
{
	[aBlog setTagID:[NSNumber numberWithInteger:[[self journal] newBlogTag]]];
	[[self journal] addBlog:aBlog];
	[[self journal] saveBlog:aBlog];
}

#pragma mark -

- (void) removeObjectFromJSBlogsAtIndex:(NSUInteger)index
{
	if ( index >= [[self valueForKeyPath:@"journal.blogs"] count] ) 
	{
		// raise an error
		[self returnError:OSAIllegalIndex string:nil]; 
		return;
	}
	
	[self JSDeleteBlog:[[self valueForKeyPath:@"journal.blogs"] objectAtIndex:index]];
}

- (void) removeFromJSBlogsAtIndex:(NSUInteger)index
{
	if ( index >= [[self valueForKeyPath:@"journal.blogs"] count] ) 
	{
		// raise an error
		[self returnError:OSAIllegalIndex string:nil]; 
		return;
	}
	
	[self JSDeleteBlog:[[self valueForKeyPath:@"journal.blogs"] objectAtIndex:index]];
}

- (void) JSDeleteBlog:(BlogPref*)aBlog
{
	[[self journal] deleteBlog:aBlog];
}

@end

#pragma mark -

@implementation JournlerScriptingImportCommand

-(id)performDefaultImplementation 
{
	
	// the application delegate is required = evaluatedReceivers and subjectsSpecifier don't seem to work with nil target
	JournlerApplicationDelegate *target = [NSApp delegate];
	
	// the actual path to be imported
	NSString *path;
	id pathURL = [self evaluatedDirectParameters];
	
	// arguments - ie error reporting
	NSDictionary *arguments = [self evaluatedArguments];
	
	// error reporting
	NSNumber *presentsError = [arguments objectForKey:@"presentsError"];
	if ( presentsError == nil )
		presentsError = [NSNumber numberWithBool:YES];
	
	// make sure the target is a valid one
	if ( target == nil ) 
	{
		// raise an error
		NSLog(@"Scriptability : nil journal but journal is required");
		if ( [presentsError boolValue] )
			[self returnError:errOSACantAssign string:@"No journal specified but journal is required"];
		return nil;
	}
	
	// check for existence of path
	if ( pathURL == nil || ![pathURL isKindOfClass:[NSURL class]] || ![(NSURL*)pathURL isFileURL] ) 
	{
		// raise an error
		NSLog(@"Scriptability : nil path but path is required");
		if ( [presentsError boolValue] )
			[self returnError:errOSACantAssign string:@"No path specified but path is required"];
		return nil;
		
	}
	
	path = [pathURL path];
	
	// make sure the file exists
	if ( ![[NSFileManager defaultManager] fileExistsAtPath:path] ) 
	{
		// raise an error
		NSLog(@"Scriptability : no file at requested import path");
		if ( [presentsError boolValue] )
			[self returnError:errOSACantAssign string:@"No file at path"];
		return nil;
	}
	
	//
	// attempt to import the entry
	id importedObject = [target importFile:path];
	
	if ( importedObject == nil || ![importedObject isKindOfClass:[JournlerEntry class]] )
	{
		if ( [presentsError boolValue] == YES ) 
		{
			// raise an error
			if ( [presentsError boolValue] )
				NSLog(@"Scriptability : unable to import entry");
			[self returnError:errOSACantAssign string:[NSString stringWithFormat:@"Unable to import entry at path %@",path]];
		}
		
		return nil;
	}
	
	// continue with a few additional properties
	NSMutableString *aCategory = [[[importedObject valueForKey:@"category"] mutableCopyWithZone:[self zone]] autorelease];
	[aCategory insertString:@"AppleScript Import " atIndex:0];
	[importedObject setValue:aCategory forKey:@"category"];
	
	// save the entry
	[[target journal] saveEntry:importedObject];
	
	// return the entry
	return importedObject;

}

@end

#pragma mark -

@implementation JourlerScriptingMakeCommand : NSCreateCommand

- (id)performDefaultImplementation
{
	id returnObject;
	
	//NSDictionary *resolvedKeyDictionary = [self resolvedKeyDictionary];
	NSScriptClassDescription *classDescription = [self createClassDescription];
	
	if ( [[classDescription className] isEqualToString:@"resource"] )
	{
		// arguments and keys
		NSDictionary *keys = [self resolvedKeyDictionary];
		
		// ensure a target entry is specified
		JournlerEntry *targetEntry = [[keys objectForKey:@"entry"] objectsByEvaluatingSpecifier];
		if ( targetEntry == nil || ![targetEntry isKindOfClass:[JournlerEntry class]] )
		{
			[self returnError:OSAIllegalAccess string:@"A new resource must be associated with an entry"];
			return nil;
		}
		
		// fork depending on the type of resource requested
		NSNumber *typeNumber = [keys objectForKey:@"scriptType"];
		if ( typeNumber == nil )
		{
			[self returnError:OSAIllegalAccess string:@"A new resource must have a type"];
			return nil;
		}
		
		JournlerResource *aResource = nil;
		id internalObject;
		NSString *urlString, *contactID, *uriString, *originalPath;
		ABPerson *contact;
		NSNumber *aliased;
		NewResourceCommand resourceCommand;
		
		OSType osType = [typeNumber integerValue];
		switch ( osType )
		{
		case 'rtME': // file
			
			originalPath = [keys objectForKey:@"originalPath"];
			if ( originalPath == nil || ![[NSFileManager defaultManager] fileExistsAtPath:originalPath] )
			{
				[self returnError:OSAIllegalAccess string:@"A media reference must include an existing file's path"];
				return nil;
			}
			
			// a file resource must be linked or aliased
			aliased = [keys objectForKey:@"scriptAliased"];
			if ( aliased == nil || ![aliased isKindOfClass:[NSNumber class]] )
			{
				[self returnError:OSAIllegalAccess string:@"You must specify whether the file is linked or copied (aliased parameter)"];
				return nil;
			}
			
			resourceCommand = ( [aliased boolValue] ? kNewResourceForceLink : kNewResourceForceCopy );
			aResource = [targetEntry resourceForFile:originalPath operation:resourceCommand];
			if ( aResource == nil )
			{
				[self returnError:OSAIllegalAccess string:@"There was an error creating the resource. Check the console logs."];
				return nil;
			}
			
			returnObject = [aResource objectSpecifier];
			break;

		case 'rtWE': // website/url
			
			urlString = [keys objectForKey:@"urlString"];
			if ( urlString == nil )
			{
				[self returnError:OSAIllegalAccess string:@"A website reference must include the website's url"];
				return nil;
			}
			
			aResource = [targetEntry resourceForURL:urlString title:urlString];
			if ( aResource == nil )
			{
				[self returnError:OSAIllegalAccess string:@"There was an error creating the resource. Check the console logs."];
				return nil;
			}
			
			returnObject = [aResource objectSpecifier];
			break;
			
		case 'rtCO': // AB contact
			
			contactID = [keys objectForKey:@"uniqueId"];
			if ( contactID == nil )
			{
				[self returnError:OSAIllegalAccess string:@"A contact reference must include the contact's unique id"];
				return nil;
			}
			
			contact = (ABPerson*)[[ABAddressBook sharedAddressBook] recordForUniqueId:contactID];
			if ( contact == nil || ![contact isKindOfClass:[ABPerson class]])
			{
				[self returnError:OSAIllegalAccess string:@"No contact for specified unique id"];
				return nil;
			}
			
			aResource = [targetEntry resourceForABPerson:contact];
			if ( aResource == nil )
			{
				[self returnError:OSAIllegalAccess string:@"There was an error creating the resource. Check the console logs."];
				return nil;
			}
			
			returnObject = [aResource objectSpecifier];
			break;
		
		case 'rtIN': // journler link
			
			uriString = [keys objectForKey:@"uriString"];
			if ( uriString == nil )
			{
				[self returnError:OSAIllegalAccess string:@"An internal reference must include the journler object's uri"];
				return nil;
			}
			
			internalObject = [[targetEntry journal] objectForURIRepresentation:[NSURL URLWithString:uriString]];
			if ( internalObject == nil || [internalObject isKindOfClass:[JournlerResource class]] )
			{
				[self returnError:OSAIllegalAccess string:@"Journler was unable to derive a valid object from the uri provided. The uri must represent a folder or entry in Journler."];
				return nil;
			}
			
			aResource = [targetEntry resourceForJournlerObject:internalObject];
			if ( aResource == nil )
			{
				[self returnError:OSAIllegalAccess string:@"There was an error creating the resource. Check the console logs."];
				return nil;
			}
			
			returnObject = [aResource objectSpecifier];
			break;
		
		default:
			
			[self returnError:OSAIllegalAccess string:@"Invalid resource type"];
			return nil;
			break;
					
		}
		
		// save the associated resource
		[[(JournlerApplicationDelegate*)[NSApp delegate] journal] saveEntry:targetEntry];
	}
	else
	{
		// go ahead and allow super to perform its implementation
		returnObject = [super performDefaultImplementation];
		
		/*
		if ( [[classDescription className] isEqualToString:@"entry"] )
		{
			// respect the 'in' property to add the entry to any specified folder
			NSLog([resolvedKeyDictionary description]);
		}
		
		else if ( [[classDescription className] isEqualToString:@"folder"] )
		{
			// respect the 'in' property to add the entry to any specified folder
			NSLog([resolvedKeyDictionary description]);
		}
		*/
	}
	
	// return the object
	return returnObject;
}

@end

@implementation JournlerScriptingSaveChangesCommand : NSScriptCommand

-(id)performDefaultImplementation 
{
	[[(JournlerApplicationDelegate*)[NSApp delegate] journal] save:nil];
	return [super performDefaultImplementation];
}

@end

@implementation JournlerScriptingHighlightCommand : NSScriptCommand

-(id)performDefaultImplementation
{
	NSString *theText = nil;
	id targetText = [self evaluatedDirectParameters];
	//id evaluatedReceivers = [self evaluatedReceivers];
	
	if ( [targetText isKindOfClass:[NSString class]] )
		theText = targetText;
	else if ( [targetText isKindOfClass:[NSAttributedString class]] )
		theText = [targetText string];
	else
	{
		[self returnError:OSAIllegalAccess string:@"You must provide text to this command"];
		return nil;
	}
	
	JournlerWindowController *aWindowController = [(JournlerApplicationDelegate*)[NSApp delegate] mainWindowIgnoringActive];
	if ( aWindowController == nil )
	{
		[self returnError:OSAIllegalAccess string:@"There is no front window that supports this action"];
		return nil;
	}
	
	TabController *theSelectedTab = [aWindowController selectedTab];
	if ( theSelectedTab == nil )
	{
		[self returnError:OSAIllegalAccess string:@"The selected tab does not support this action"];
		return nil;
	}
	
	[theSelectedTab highlightString:theText];
	return nil;
}

@end

@implementation JournlerScriptingFindInJournal : NSScriptCommand
	
-(id)performDefaultImplementation
{
	NSString *theText = nil;
	id targetText = [self evaluatedDirectParameters];
	//id evaluatedReceivers = [self evaluatedReceivers];
	
	if ( [targetText isKindOfClass:[NSString class]] )
		theText = targetText;
	else if ( [targetText isKindOfClass:[NSAttributedString class]] )
		theText = [targetText string];
	else
	{
		[self returnError:OSAIllegalAccess string:@"You must provide text to this command"];
		return nil;
	}
	
	JournalWindowController *theWindowController = [(JournlerApplicationDelegate*)[NSApp delegate] journalWindowController];
	
	[[theWindowController selectedTab] selectFolders:[NSArray arrayWithObject:[[theWindowController journal] libraryCollection]]];
	
	[[theWindowController searchOutlet] setStringValue:theText];
	[theWindowController performToolbarSearch:[theWindowController searchOutlet]];
	
	return nil;
}
	
@end

@implementation JournlerDropBoxCommand : NSScriptCommand

-(id)performDefaultImplementation
{
	NSArray *filenames;
	id fileParameter = [self evaluatedDirectParameters];
	
	NSDictionary *args = [self evaluatedArguments];
	NSNumber *deletesOriginal = [args objectForKey:@"deletesOriginal"];
	BOOL doDelete = ( deletesOriginal == nil ? NO : [deletesOriginal boolValue] );
	
	if ( [fileParameter isKindOfClass:[NSString class]] )
	{
		filenames = [NSArray arrayWithObject:fileParameter];
	}
	else if ( [fileParameter isKindOfClass:[NSURL class]] )
	{
		filenames = [NSArray arrayWithObject:[fileParameter path]];
	}
	else if ( [fileParameter isKindOfClass:[NSArray class]] )
	{
		filenames = [NSMutableArray arrayWithCapacity:[fileParameter count]];
	
        for ( id aFilename in (NSArray*)fileParameter )
		{
			if ( [aFilename isKindOfClass:[NSString class]] )
				[(NSMutableArray*)filenames addObject:aFilename];
			else if ( [aFilename isKindOfClass:[NSURL class]] )
				[(NSMutableArray*)filenames addObject:[aFilename path]];
		}
	}
	else
	{
		[self returnError:OSAIllegalAccess string:@"You must provide a file or list of files"];
		return nil;
	}

	// simply run the drop box - the application delegate expects a particular selector
	DropBoxDialog *dropBoxDialog = [[[DropBoxDialog alloc] initWithJournal:[(JournlerApplicationDelegate*)[NSApp delegate] journal] 
			delegate:[NSApp delegate] 
			mode:0 
			didEndSelector:@selector(dropboxScriptCommand:didEndDialog:contents:)] autorelease];
	
	[dropBoxDialog setTagCompletions:[[[[NSApp delegate] journal] entryTags] allObjects]];
	if ( [filenames count] == 1 )
	{
		// fill out the tags
		MDItemRef mdItem = MDItemCreate(NULL,(CFStringRef)[filenames objectAtIndex:0]);
		if ( mdItem != nil )
		{
			NSArray *mdTags = [(NSArray*)MDItemCopyAttribute(mdItem,kMDItemKeywords) autorelease];
			[dropBoxDialog setTags:mdTags];
			
			NSString *mdSubject = [(NSString*)MDItemCopyAttribute(mdItem, kMDItemSubject) autorelease];
			[dropBoxDialog setCategory:mdSubject];
			
			CFRelease(mdItem);
		}
	}
	
	[dropBoxDialog setRepresentedObject:filenames];
	[dropBoxDialog setShouldDeleteOriginal:doDelete];
	[dropBoxDialog setContent:[DropBoxDialog contentForFilenames:filenames]];
	[dropBoxDialog showWindow:self];
	
	return nil;
}

@end