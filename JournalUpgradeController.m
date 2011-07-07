#import "JournalUpgradeController.h"
#import "JournlerApplicationDelegate.h"

#import "BlogPref.h"
#import "JournlerEntry.h"
#import "JournlerJournal.h"
#import "JournlerCollection.h"
#import "JournlerResource.h"
#import "JournlerSearchManager.h"
#import "PDSingletons.h"

#import "QTInstallController.h"

#import "Definitions.h"
#import "NSString+JournlerAdditions.h"
#import "NSAlert+JournlerAdditions.h"
#import "NSURL+JournlerAdditions.h"

#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>

/*
#import "ZipUtilities.h"
#import "PDGradientView.h"
#import "NSWorkspace_PDCategories.h"
#import "NSString+PDStringAdditions.h"
#import "NSUserDefaults+PDDefaultsAdditions.h"
#import "AGKeychain.h"
*/

//#import "JUtility.h"

typedef enum 
{	
	kJNoErr = 0,
	kJNoCSMHandle,
	kJKeyFailure
}JUpgradeErrors;

static NSString *kLogFilepath = @"1.1 to 2.5 Upgrade Log.txt";
static NSString *kLogFilepath210 = @"2.0 to 2.5 Upgrade Log.txt";

static NSString *kJournlerABFileUTI = @"com.phildow.journler.jaduid";
static NSString *kJournlerABFileExtension = @"jaduid";

@implementation JournalUpgradeController

- (id) init 
{
	if ( self = [self initWithWindowNibName:@"JournalUpgrade"] ) 
	{
		[self loadWindow];
	}
	return self;
}	

- (void) windowDidLoad 
{	
	int borders[4] = {0,0,0,0};
	[container210 setBorders:borders];
	[container210 setBordered:NO];
	
	[progressIndicator210 setUsesThreadedAnimation:YES];
}

- (void) dealloc 
{	
	[super dealloc];
}

#pragma mark -
#pragma mark 1.17 -> 2.5 upgrade

- (void) run117To210Upgrade:(JournlerJournal*)journal 
{	
	_journal = journal;
	upgradeMode = 0;
	
	session210 = [NSApp beginModalSessionForWindow:[self window]];
	[[self window] display];
	[NSApp runModalSession:session210];
		
	int i;
	int lastFolderTag = 0;
	int lastEntryTag = 0;
	
	int serious_error = 0;
	//BOOL index_entries = YES;
	
	NSString *pname;
	NSArray	*allFiles;
	NSString *endMessage;
	
	entriesDictionary = [NSMutableDictionary dictionary];
	foldersDictionary = [NSMutableDictionary dictionary];
	
	NSMutableArray *journalEntries = [NSMutableArray array];
	NSMutableArray *journalFolders = [NSMutableArray array];
	NSMutableArray *journalBlogs = [NSMutableArray array];
	
	log117 = [[NSMutableString alloc] init];
	NSString *upgradeLogPath = [[_journal journalPath] stringByAppendingPathComponent:kLogFilepath];
	
	NSString *backupDir = [[[_journal journalPath] 
			stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Journler Backup"];
			
	NSString *backupPath = [backupDir stringByAppendingPathComponent:@"v1.1 to v2.5 Backup.zip"];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	NSFontManager *fontM = [NSFontManager sharedFontManager];
	
	//CSSM_KEY			cdsaKey;
	//CSSM_HANDLE		cssmHandle;
	
	// back up the journal
	// -----------------------------------------------------------------
	
	[progressIndicator210 setIndeterminate:YES];
	[progressIndicator210 startAnimation:self];
	[progressText210 setStringValue:NSLocalizedStringFromTable(@"backing up", @"UpgradeController", @"")];
	[NSApp runModalSession:session210];
		
	if ( ![fm fileExistsAtPath:backupDir] ) 
	{
		if ( ![fm createDirectoryAtPath:backupDir attributes:nil] ) 
		{
			// Unable to backup the journler directory, ask the user if he/she would like to continue
			[log117 appendString:[NSString stringWithFormat:
					@"** 2.5 Upgrade cannot backup journal: Unable to create backup directory at %@ **\n", backupPath]];
			
			// discontinue the upgrade
			if ( [[NSAlert upgradeCreateBackupDirectoryFailure] runModal] == NSAlertFirstButtonReturn ) 
			{
				NSError *error = nil;
				if ( ![log117 writeToFile:upgradeLogPath atomically:NO encoding:NSUnicodeStringEncoding error:&error] )
					NSLog(@"%s - unable to write upgrade log to %@, error %@", __PRETTY_FUNCTION__, upgradeLogPath, error);
				
				[log117 release];
				[self quit210Upgrade:self];
			}
		}
	}
	
	if ( [fm fileExistsAtPath:backupDir] ) 
	{
		// ensure the backup is not overwriting a previous save
		backupPath = [backupPath pathWithoutOverwritingSelf];
		
		//if ( ![JUtility zip:[_journal journalPath] toFile:backupPath] ) 
		if ( ![ZipUtilities zip:[_journal journalPath] toFile:backupPath] ) 
		{
			// if the zip failed
			[log117 appendString:[NSString stringWithFormat:@"** 2.5 Upgrade cannot backup journal: Unable to zip journal to %@ **\n", backupPath]];
			
			// discontinue the upgrade
			if ( [[NSAlert upgradeBackupOldEntriesFailure] runModal] == NSAlertFirstButtonReturn ) 
			{
				NSError *error = nil;
				if ( ![log117 writeToFile:upgradeLogPath atomically:NO encoding:NSUnicodeStringEncoding error:&error] )
					NSLog(@"%s - unable to write upgrade log to %@, error %@", __PRETTY_FUNCTION__, upgradeLogPath, error);
				
				[log117 release];
				[self quit210Upgrade:self];
			}
		}
	}		
	
	// before doing anything, check if the user's journal is encrypted and let them know that encryption is no longer supported
	BOOL check_for_encryption = ( [ud integerForKey:@"Encryption"] != 0 );
	if ( check_for_encryption ) 
	{
		[[NSAlert upgradeEncryptionNoLongerSupported] runModal];
		[self quit210Upgrade:self];
	}
	
	// check on the journal's identification and assign one if necessary
	// ----------------------------------------------------------
	
	if ( ![[_journal properties] objectForKey:PDJournalIdentifier] ) 
	{
		[log117 appendString:@"No journal identifier, assigning new ID.\n"];
		[_journal setIdentifier:[NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]]];
	}
	
	// create the resources directory
	if ( ![fm fileExistsAtPath:[_journal resourcesPath]] && ![fm createDirectoryAtPath:[_journal resourcesPath] attributes:nil] )
	{
		// critical error
		[log117 appendString:@"** Unable to create a resources directory **\n"];
		[[NSAlert upgradeCreateResourcesFolderFailure] runModal];
		
		NSError *error = nil;
		if ( ![log117 writeToFile:upgradeLogPath atomically:NO encoding:NSUnicodeStringEncoding error:&error] )
			NSLog(@"%s - unable to write upgrade log to %@, error %@", __PRETTY_FUNCTION__, error);
					
		[log117 release];
		[self quit210Upgrade:self];
	}
	
	// convert the collections
	// -----------------------------------------------------------------
	
	NSString *collectionsPath = [_journal collectionsPath];
	if ( ![fm fileExistsAtPath:collectionsPath] ) 
	{
		if ( ![fm createDirectoryAtPath:collectionsPath attributes:nil] ) 
		{
			// critical error
			[log117 appendString:[NSString stringWithFormat:@"**2.5 Upgrade cannot create a collections folder at %@\n**", collectionsPath]];
			[[NSAlert upgradeCreateCollectionsFolderFailure] runModal];
				
			NSError *error = nil;
			if ( ![log117 writeToFile:upgradeLogPath atomically:NO encoding:NSUnicodeStringEncoding error:&error] )
				NSLog(@"%s - unable to write upgrade log to %@, error %@", __PRETTY_FUNCTION__, upgradeLogPath, error);
			
			[log117 release];
			[self quit210Upgrade:self];
		}
	}
	
	// disable threaded indexing
	//[[_journal searchManager] setIndexesOnSeparateThread:NO];
	
	NSArray *oldCollectionDics = [[_journal properties] objectForKey:PDJournalCollections];
	
	[log117 appendString:@"Upgrading collections from 1.1 to 2.5 format.\n"];
	
	[progressText210 setStringValue:NSLocalizedStringFromTable(@"converting collections", @"UpgradeController", @"")];
	[progressIndicator210 stopAnimation:self];
	[progressIndicator210 setIndeterminate:NO];
	[progressIndicator210 setMinValue:0.0];
	[progressIndicator210 setMaxValue:[oldCollectionDics count]];
	[progressIndicator210 setDoubleValue:0.0];
	
	for ( i = 0; i < [oldCollectionDics count]; i++ ) 
	{
		NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
		JournlerCollection *aNode = [[[JournlerCollection alloc] initWithProperties:[oldCollectionDics objectAtIndex:i]] autorelease];
		
		// explicity set the parent to root
		[aNode setParentID:[NSNumber numberWithInt:-1]];
		
		// set the entry ids to what is in the entry field -- already tags
		[aNode setEntryIDs:[[aNode properties] objectForKey:PDCollectionEntries]];
		
		// explicity set the children ids to none
		[aNode setChildrenIDs:[NSArray array]];
		
		// set the journal id and version
		[aNode setVersion:[NSNumber numberWithInt:250]];
		[aNode setJournalID:[_journal identifier]];
		
		// establish a relationship to the journal
		[aNode setJournal:_journal];
		
		// convert the type to a typeID
		NSString *oldType = [aNode pureType];
		if ( [oldType isEqualToString:PDCollectionTypeFolder] )
			[aNode setTypeID:[NSNumber numberWithInt:PDCollectionTypeIDFolder]];
		else if ( [oldType isEqualToString:PDCollectionTypeSmart] )
			[aNode setTypeID:[NSNumber numberWithInt:PDCollectionTypeIDSmart]];
		else if ( [oldType isEqualToString:PDCollectionTypeLibrary] )
			[aNode setTypeID:[NSNumber numberWithInt:PDCollectionTypeIDLibrary]];
		else if ( [oldType isEqualToString:PDCollectionTypeTrash] )
			[aNode setTypeID:[NSNumber numberWithInt:PDCollectionTypeIDTrash]];
		else
			[aNode setTypeID:[NSNumber numberWithInt:PDCollectionTypeIDFolder]];
		
		// update the image to a standard value
		[aNode determineIcon];
		
		// remove old items from the collection that are not needed and upgrade the internal variables
		[aNode clearOldProperties];
		[aNode updateForTwoZero];
		
		// update last tag and count
		if ( lastFolderTag  < [[aNode tagID] intValue] )
			lastFolderTag = [[aNode tagID] intValue];
		
		// store in the array for sorting and ordering
		[journalFolders addObject:aNode];
		
		// store in the dictionary for link processing
		[foldersDictionary setObject:aNode forKey:[aNode valueForKey:@"tagID"]];
		
		// autorelease and run the modal session
		[progressIndicator210 incrementBy:1.0];
		[NSApp runModalSession:session210];
		[innerPool release];
	}
	
	// sort the collections
	// -----------------------------------------------------------------
	
	NSArray *defaultSort = [[[NSArray alloc] initWithObjects:
			[[[NSSortDescriptor alloc] 
			initWithKey:PDCollectionTypeID ascending:YES selector:@selector(compare:)] autorelease],
			[[[NSSortDescriptor alloc] 
			initWithKey:PDCollectionTitle ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] autorelease], 
			nil] autorelease];
	
	[journalFolders sortUsingDescriptors:defaultSort];
	
	[progressText210 setStringValue:NSLocalizedStringFromTable(@"saving collections", @"UpgradeController", @"")];
	[progressIndicator210 setMinValue:0.0];
	[progressIndicator210 setMaxValue:[oldCollectionDics count]];
	[progressIndicator210 setDoubleValue:0.0];
	
	for ( i = 0; i < [journalFolders count]; i++ ) 
	{
		NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
		JournlerCollection *aNode = [journalFolders objectAtIndex:i];
		
		// set the index on the node, now ordered in its proper place
		[aNode setValue:[NSNumber numberWithInt:i] forKey:@"index"];
		
		// autorelease and run the modal session
		[progressIndicator210 incrementBy:1.0];
		[NSApp runModalSession:session210];
		[innerPool release];
	}
	
		
	// reset the search index and disable during upgrade
	// -----------------------------------------------------------------
	
	[[_journal searchManager] closeIndex];
	[[_journal searchManager] deleteIndexAtPath:[_journal journalPath]];
	[_journal setSaveEntryOptions:kEntrySaveDoNotIndex|kEntrySaveDoNotCollect];
	
	/*
	[log117 appendString:@"Rebuilding search index\n"];
	if ( [[_journal searchManager] createIndexAtPath:[_journal journalPath]] && [[_journal searchManager] loadIndexAtPath:[_journal journalPath]] ) 
	{
		index_entries = YES;
		[log117 appendString:@"Successfully reset search index\n"];
	}
	else 
	{
		index_entries = NO;
		[log117 appendString:@"**Unable to reset search index**\n"];
		[[NSAlert upgradeRecreateSearchIndexFailure] runModal];
	}
	*/
	
	
	// load the entries, decrypting them if necessary
	// -----------------------------------------------------------------
	
	[log117 appendString:@"Upgrading entries from 1.1 to 2.5 format.\n"];
	
    // DIRECTORY_ENUMERATION
    NSEnumerator *direnum;
	allFiles = [fm directoryContentsAtPath:[_journal entriesPath]];
	direnum = [allFiles objectEnumerator];
	
	[progressText210 setStringValue:NSLocalizedStringFromTable(@"converting entries", @"UpgradeController", @"")];
	[progressIndicator210 setMinValue:0.0];
	[progressIndicator210 setMaxValue:[allFiles count]-2];
	[progressIndicator210 setDoubleValue:0.0];
			
	while ( pname = [direnum nextObject] ) 
	{
		if ([[pname pathExtension] isEqualToString:@"jobj"]) 
		{
			NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
			
			JournlerEntry *anEntry;
			NSString *entryPath = [[_journal entriesPath] stringByAppendingPathComponent:pname];
			
			// load the entry depending on the presence of encrypted entries
			//if ( check_for_encryption ) 
			//	anEntry = [[[JournlerEntry alloc] initWithEncryptedPath:entryPath CSSMHandle:&cssmHandle CSSMKey:&cdsaKey] autorelease];
			//else
				anEntry = [[[JournlerEntry alloc] initWithPath:entryPath] autorelease];
			
			if ( anEntry != nil ) 
			{
				
				// upgrade the entry to 2.5
				if ( [anEntry performOneTwoMaintenance:&log117] ) 
				{
					[log117 appendString:[NSString stringWithFormat:@"%@ successfully upgraded\n", [anEntry tagID]]];
					
					// note the cal date modified
					NSCalendarDate *dateModified = [[[anEntry valueForKey:@"calDateModified"] retain] autorelease];
					
					// assign the entry to this journal, establish a relationship to the journal
					[anEntry setJournalID:[_journal identifier]];
					[anEntry setJournal:_journal];
					
					// upgrade the entry's internal format
					[anEntry setValue:[NSNumber numberWithInt:250] forKey:@"version"];
					
					// perform maintenance on the entry (remove deprecated properties)
					[anEntry perform210Maintenance];
					
					// set the caldate modified back
					[anEntry setValue:dateModified forKey:@"calDateModified"];
					
					// add the entry to a temp array
					[journalEntries addObject:anEntry];
					
					// store in the dictionary for link processing
					[entriesDictionary setObject:anEntry forKey:[anEntry valueForKey:@"tagID"]];
					
					// increment the tag and count
					if ( lastEntryTag < [[anEntry tagID] intValue] )
						lastEntryTag = [[anEntry tagID] intValue];
				
				}
				else 
				{
					serious_error++;
					[log117 appendString:[NSString stringWithFormat:@"** Could not upgrade %@ **\n", [anEntry tagID]]];
				}
			}
			else 
			{
				serious_error++;
				[log117 appendString:[NSString stringWithFormat:@"** Unable to read entry for upgrade at path %@ **\n", entryPath]];
			}
			
			// delete the old entry no matter what
			if ( ![fm removeFileAtPath:entryPath handler:self] ) 
			{
				// error deleting the old file
				[log117 appendString:[NSString stringWithFormat:@"** Unable to delete old format entry at %@ **\n", entryPath]];
			}
			
			// autorelease pool
			[innerPool release];
		}
		
		// run the modal session
		[progressIndicator210 incrementBy:1.0];
		[NSApp runModalSession:session210];
	}
	
	// convert the links in the entry
	
	[progressText210 setStringValue:NSLocalizedStringFromTable(@"processing entries", @"UpgradeController", @"")];
	[progressIndicator210 setMinValue:0.0];
	[progressIndicator210 setMaxValue:[journalEntries count]];
	[progressIndicator210 setDoubleValue:0.0];
	
	JournlerEntry *entryForLinks;
	direnum = [journalEntries objectEnumerator];
	while ( entryForLinks = [direnum nextObject] )
	{
		// note the cal date modified
		NSCalendarDate *dateModified = [[[entryForLinks valueForKey:@"calDateModified"] retain] autorelease];
		
		// process the entry's links
		[self processResourcesLinksForEntry117To210:entryForLinks];
		
		// reset the date modified
		[entryForLinks setDateModified:dateModified];
		
		// write the entry back to disk
		if ( ![_journal saveEntry:entryForLinks] )
		{
			// error writing the file to disk
			[log117 appendString:[NSString stringWithFormat:@"** Unable to write new entry %@ **\n", [entryForLinks tagID]]];
		}

		// run the modal session
		[progressIndicator210 incrementBy:1.0];
		[NSApp runModalSession:session210];
	}
	
	//
	// process the entry ids into actual objects and save the folders
	
	for ( i = 0; i < [journalFolders count]; i++ ) 
	{
		JournlerCollection *aFolder = [journalFolders objectAtIndex:i];
		NSArray *actualEntries = [self entriesForTagIDs:[aFolder entryIDs]];
		
		[aFolder setEntries:actualEntries];
		
		// save the collection to disk and note
		if ( [_journal saveCollection:aFolder] )
			[log117 appendString:[NSString stringWithFormat:@"%@ collection successfully upgraded\n", [aFolder tagID]]];
		else
		{
			serious_error++;
			[log117 appendString:[NSString stringWithFormat:@"** Could not upgrade collection %@ **\n", [aFolder tagID]]];
		}
	}
	
	// convert and removed unneeded preferences
	// -----------------------------------------------------------------
	
	// convert the preferences blogs to actual blog preferences and save them in journler
	
	[progressText210 setStringValue:NSLocalizedStringFromTable(@"updating preferences", @"UpgradeController", @"")];
	[progressIndicator210 setIndeterminate:YES];
	[progressIndicator210 startAnimation:self];
	
	if ( ![[NSFileManager defaultManager] createDirectoryAtPath:[_journal blogsPath] attributes:nil] )
	{
		[log117 appendString:@"** Unable to create a blogs directory - you're blog preferences have been reset **\n"];
	}
	else 
	{
		// try to load the blogs from preferences, but if they aren't there, go for the journal
		NSArray *blog_preferences = [ud arrayForKey:@"Journler Blog Preferences"];
		if ( blog_preferences == nil || [blog_preferences count] == 0 )
			blog_preferences = [[_journal properties] objectForKey:@"Blogs"];
		
		if ( blog_preferences && [blog_preferences count] != 0 ) 
		{
			int b;
			for ( b = 0; b < [blog_preferences count]; b++ ) 
			{
				NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
				BlogPref *aBlog = [[[BlogPref alloc] initWithProperties:[blog_preferences objectAtIndex:b]] autorelease];
				
				if ( aBlog == nil ) 
					continue;
				
				// give the blog a unique id
				[aBlog setValue:[NSNumber numberWithInt:b] forKey:@"tagID"];

				// write the blog to disk
				if ( ![_journal saveBlog:aBlog] )
				{
					serious_error++;
					[log117 appendString:[NSString stringWithFormat:
							@"** Unable to save blog preference %@, the preferences has been reset **\n", [aBlog name]]];
				}
				
				// add the blog to the master list
				[journalBlogs addObject:aBlog];
				
				// autorelease pool
				[innerPool release];
			}
		}
		
		// run the modal session
		[NSApp runModalSession:session210];
	}
	
	[ud removeObjectForKey:@"Journler Blog Preferences"];

	
	// copy the wordlist if available to the user's support directory - that way the user can make changes without damaging original
	NSString *wordlistDestination = [[_journal journalPath] stringByAppendingPathComponent:PDJournalWordListLoc];
	NSString *wordlistSource = [[NSBundle mainBundle] pathForResource:@"AutoCorrectWordPairs" ofType:@"csv"];
	
	if ( wordlistSource != nil && wordlistDestination != nil )
	{
		if ( ![[NSFileManager defaultManager] copyPath:wordlistSource toPath:wordlistDestination handler:self] )
		{
			[log210 appendFormat:@"%s - unable to copy wordlist from %@ to %@\n\n", __PRETTY_FUNCTION__, wordlistSource, wordlistDestination];
			[ud setBool:NO forKey:@"EntryTextAutoCorrectSpelling"];
			[ud setBool:NO forKey:@"EntryTextAutoCorrectSpellingUseWordList"];
		}
		else
		{
			[ud setBool:YES forKey:@"EntryTextAutoCorrectSpelling"];
			[ud setBool:YES forKey:@"EntryTextAutoCorrectSpellingUseWordList"];
		}
	}
	
	// update the user's preferences
	[ud setBool:YES forKey:@"EntryExportIncludeHeader"];
	[ud setBool:YES forKey:@"EntryExportSetCreationDate"];
	[ud setBool:YES forKey:@"EntryExportSetModificationDate"];
	[ud setBool:NO forKey:@"ImportPreserveDateModified"];
	[ud setBool:NO forKey:@"EntryImportSetDefaultResource"];
	[ud setBool:YES forKey:@"SourceListShowsEntryCount"];
	
	[ud setBool:YES forKey:@"BlogsUseAdvancedHTMLGeneration"];
	[ud setBool:YES forKey:@"ExportsUseAdvancedHTMLGeneration"];
	[ud setBool:YES forKey:@"CopyingUseAdvancedHTMLGeneration"];
	
	[ud setObject:@"font, min-height" forKey:@"BlogsNoAttributeList"];
	[ud setObject:[NSString string] forKey:@"ExportsNoAttributeList"];
	[ud setObject:[NSString string] forKey:@"CopyingNoAttributeList"];
	
	[ud setBool:YES forKey:@"WebViewFindIgnoreCase"];
	[ud setBool:NO forKey:@"SearchSpaceMeansOr"];
	[ud setBool:NO forKey:@"NewEntryImportNewWindow"];
	[ud setBool:NO forKey:@"EditDatesWithGraphicalInterface"];
	[ud setBool:NO forKey:@"NewEntryWithDueDate"];
	
	[ud setBool:YES forKey:@"MainWindowBookmarksVisible"];
	[ud setBool:NO forKey:@"MainWindowTabsAlwaysVisible"];
	
	//[ud setBool:YES forKey:@"SearchIncludesEntries"];
	//[ud setBool:YES forKey:@"SearchIncludesResources"];
	[ud setBool:YES forKey:@"SearchMediaByDefault"];
	
	[ud setBool:YES forKey:@"EntryTextUseSmartQuotes"];
	[ud setBool:YES forKey:@"EntryTextShowWordCount"];
	[ud setBool:YES forKey:@"EntryTextEnableSpellChecking"];
	[ud setBool:YES forKey:@"EntryTextRecognizeWikiLinks"];
	[ud setBool:YES forKey:@"EntryTextRecognizeURLs"];
	
	[ud setBool:NO forKey:@"EntryTextAutoCorrectSpellingUseBuiltIn"];
	
	[ud setInteger:100 forKey:@"EntryTextDefaultZoom"];
	[ud setInteger:100 forKey:@"EntryTextFullscreenZoom"];
	[ud setInteger:0 forKey:@"EntryTextHorizontalInset"];
	[ud setInteger:100 forKey:@"EntryTextHorizontalInsetFullscreen"];
	[ud setInteger:80 forKey:@"PhotoViewPhotoSize"];
	
	[ud setBool:YES forKey:@"EntryTextLinkUnderlined"];
	[ud setColor:[NSColor blueColor] forKey:@"EntryTextLinkColor"];
	
	[ud setBool:YES forKey:@"ResourceTableShowFolders"];
	[ud setBool:YES forKey:@"ResourceTableShowJournlerLinks"];
	[ud setBool:NO forKey:@"ResourceTableCollapseDocuments"];
	[ud setBool:NO forKey:@"ResourceTableArrangedCollapsedDocumentsByKind"];
	
	[ud setColor:[NSColor whiteColor] forKey:@"HeaderBackgroundColor"];
	[ud setColor:[NSColor whiteColor] forKey:@"EntryBackgroundColor"];
	
	[ud setColor:[NSColor colorWithCalibratedWhite:0.75 alpha:1.0] forKey:@"HeaderLabelColor"];
	[ud setColor:[NSColor colorWithCalibratedWhite:0.00 alpha:1.0] forKey:@"HeaderTextColor"];
	
	[ud setFont:[NSFont controlContentFontOfSize:11]  forKey:@"BrowserTableFont"];
	[ud setFont:[NSFont controlContentFontOfSize:11]  forKey:@"FoldersTableFont"];
	[ud setFont:[NSFont controlContentFontOfSize:11]  forKey:@"ReferencesTableFont"];
	
	[ud setInteger:0 forKey:@"DefaultSnapshotFormat"];
	[ud setInteger:0 forKey:@"DefaultAudioCodec"];
	
	[ud removeObjectForKey:@"Lockout Enabled"];
	
	// convert font faces and sizes to actual font objects
	// ------------------------------------------------------------------------------------
	
	NSString *fontName;
	NSNumber *fontSize;
	NSData *fontData;
	NSFont *tempFont;
	
	tempFont = [NSFont systemFontOfSize:14.0];
	
	fontName = [ud objectForKey:@"Journler Default Font"];
	tempFont = [fontM convertFont:tempFont toFace:( fontName ? fontName : [[NSFont systemFontOfSize:14.0] fontName] )];
		
	fontSize = [ud objectForKey:@"Text Font Size"];
	tempFont = [fontM convertFont:tempFont toSize:( fontSize ? [fontSize floatValue] : 13.0 )]; 
	
	fontData = [NSArchiver archivedDataWithRootObject:tempFont];
	if ( fontData ) [ud setObject:fontData forKey:@"DefaultEntryFont"];
	else [log117 appendString:@"Unable to set the default entry text font.\n"];
	
	
	// remove old font data
	[ud removeObjectForKey:@"Datestamp Font"];
	[ud removeObjectForKey:@"Datestamp Font Size"];
	[ud removeObjectForKey:@"Title Font"];
	[ud removeObjectForKey:@"Title Font Size"];
	[ud removeObjectForKey:@"Category Font"];
	[ud removeObjectForKey:@"Category Font Size"];
	[ud removeObjectForKey:@"Keywords Font"];
	[ud removeObjectForKey:@"Keywords Font Size"];
	[ud removeObjectForKey:@"Journler Default Font"];
	[ud removeObjectForKey:@"Text Font Size"];
	
	// reset the toolbar
	[ud removeObjectForKey:@"NSToolbar Configuration My Document Toolbar Identifier"];
	[ud removeObjectForKey:@"NSToolbar Configuration Entry Window Toolbar"];
	[ud removeObjectForKey:@"NSToolbar Configuration Blog Center Toolbar ID"];

	// make sure the highlight colors are available
	if ( ![ud fontForKey:@"highlightYellow"] ) 
	{
		[ud setColor:[NSColor yellowColor] forKey:@"highlightYellow"];
		[ud setColor:[NSColor blueColor] forKey:@"highlightBlue"];
		[ud setColor:[NSColor greenColor] forKey:@"highlightGreen"];
		[ud setColor:[NSColor orangeColor] forKey:@"highlightOrange"];
		[ud setColor:[NSColor redColor] forKey:@"highlightRed"];
	
	}

	// further miscellaneous defaults
	[ud setBool:YES forKey:@"NewMediaLinkIncludeIcon"];
	[ud setBool:YES forKey:@"UseVisualAidWherePossibleWhenImporting"];
	[ud setBool:NO forKey:@"UpdateDateModifiedOnlyAfterTextChange"];
	[ud setBool:NO forKey:@"ConvertImportedURLsToWebArchives"];
	
	[ud setObject:[NSNumber numberWithBool:YES] forKey:@"AutoEnablePrefixSearching"];
	[ud setObject:[NSNumber numberWithBool:YES] forKey:@"QuickEntryCreation"];
	[ud setObject:[NSNumber numberWithBool:NO] forKey:@"CalendarUseButton"];
	[ud setObject:[NSNumber numberWithBool:NO] forKey:@"SearchMediaByDefault"];
	[ud setObject:[NSNumber numberWithBool:NO] forKey:@"SourceListUseSmallIcons"];
	[ud setObject:[NSNumber numberWithBool:NO] forKey:@"CommandWClosesWindow"];
	
	[ud setObject:[NSNumber numberWithInt:0] forKey:@"OpenMediaInto"];
	[ud setObject:[NSNumber numberWithInt:0] forKey:@"MediaPolicyFiles"];
	[ud setObject:[NSNumber numberWithInt:0] forKey:@"MediaPolicyDirectories"];
	[ud setObject:[NSNumber numberWithInt:0] forKey:@"DefaultVideoCodec"];
	[ud setObject:[NSNumber numberWithInt:0] forKey:@"CalendarStartDay"];
	[ud setObject:[NSNumber numberWithInt:0] forKey:@"LaunchToOption"];
	[ud setObject:[NSNumber numberWithInt:200] forKey:@"EmbeddedImageMaxWidth"];
	[ud setBool:NO forKey:@"EmbeddedImageUseFullSize"];
	
	[ud removeObjectForKey:@"BrowseSortIdentifier"];
	[ud removeObjectForKey:@"NSTableView Columns QuickLinkBrowserTable"];
	[ud removeObjectForKey:@"NSTableView Sort Ordering QuickLinkBrowserTable"];
	[ud removeObjectForKey:@"Date Format Index"];
	[ud removeObjectForKey:@"StylesBarVisible"];
	
	[ud setObject:@"Red" forKey:@"LabelName1"];
	[ud setObject:@"Orange" forKey:@"LabelName2"];
	[ud setObject:@"Yellow" forKey:@"LabelName3"];
	[ud setObject:@"Green" forKey:@"LabelName4"];
	[ud setObject:@"Blue" forKey:@"LabelName5"];
	[ud setObject:@"Purple" forKey:@"LabelName6"];
	[ud setObject:@"Gray" forKey:@"LabelName7"];
	
	[ud setInteger:0 forKey:@"AudioRecordingFormat"];
	[ud setInteger:0 forKey:@"ScriptsInstallationDirectory"];
	
	// Wrap things up
	// ------------------------------------------------------------------------------------
	
	// update the journal plist file -- WikiLinks, Blogs
	[_journal performOneTwoMaintenance];
	[_journal setVersion:[NSNumber numberWithInt:250]];
	
	// remove unneeded values from the properties dictionary
	NSMutableDictionary *properties = [[[_journal properties] mutableCopyWithZone:[self zone]] autorelease];

	[properties setObject:[NSNumber numberWithBool:YES] forKey:PDJournalProperShutDown];
	[properties removeObjectForKey:PDJournalCollections];
	[properties removeObjectForKey:PDJournalEncryptionState];
	[properties removeObjectForKey:@"WikiLinks"];
	[properties removeObjectForKey:@"Blogs"];
	
	[_journal setProperties:properties];
	[_journal saveProperties];
	
	// write the index to disk
	[[journal searchManager] writeIndexToDisk];
	
	// close the search index
	[[_journal searchManager] closeIndex];
	
	// set the journal's main objects
	[_journal setEntries:journalEntries];
	[_journal setCollections:journalFolders];
	[_journal setBlogs:journalBlogs];
	//[_journal setResources:[journalEntries valueForKey:@"resources"]];
	
	// no need to save the entries and whatnot again
	//[[_journal valueForKey:@"entries"] setValue:[NSNumber numberWithBool:NO] forKey:@"dirty"];
	[[_journal valueForKey:@"resources"] setValue:[NSNumber numberWithBool:YES] forKey:@"dirty"];
	//[[_journal valueForKey:@"collections"] setValue:[NSNumber numberWithBool:NO] forKey:@"dirty"];
	
	// disable searching - no need to index again
	//[_journal setSaveEntryOptions:kEntrySaveDoNotIndex|kEntrySaveDoNotCollect];
	
	// save the entire journal
	[_journal save:nil];
	
	// re-enable indexing
	//[_journal setSaveEntryOptions:kEntrySaveIndexAndCollect];
	
	// remove the old entries index
	if ( [[NSFileManager defaultManager] fileExistsAtPath:[[journal journalPath] stringByAppendingPathComponent:@"Entries Index"]] )
		[[NSFileManager defaultManager] removeFileAtPath:[[journal journalPath] stringByAppendingPathComponent:@"Entries Index"] handler:self];
	
	endMessage = NSLocalizedStringFromTable(@"upgrade complete", @"UpgradeController", @"");
	[progressText210 setStringValue:endMessage];

	
	// install the lame components
	// ------------------------------------------------------------------------------------
	
	[progressText210 setStringValue:NSLocalizedStringFromTable(@"installing lame", @"UpgradeController", @"")];
	[progressIndicator210 setIndeterminate:YES];
	[progressIndicator210 startAnimation:self];
	
	[self installLameComponents];
	
	// show the relaunch button and grab the users attention
	[progressIndicator210 setHidden:YES];
	[NSApp endModalSession:session210];
	[[self window] orderOut:self];
	
	[NSApp requestUserAttention:NSInformationalRequest];
	[NSApp runModalForWindow:licenseChanged210];
	
	// write out the upgrade log and release it
	[log117 appendString:@"Upgrade completed"];
	
	NSError *error = nil;
	if ( ![log117 writeToFile:upgradeLogPath atomically:NO encoding:NSUnicodeStringEncoding error:&error] )
		NSLog(@"%s - unable to write upgrade log to %@, error %@", __PRETTY_FUNCTION__, error);
						
	[log117 release];
	[NSApp relaunch:self];
}

- (BOOL) processResourcesLinksForEntry117To210:(JournlerEntry*)anEntry
{	
	//static NSString *httpScheme = @"http";
	
	BOOL completeSuccess = YES;
	NSMutableAttributedString *mutableContent = [[[anEntry valueForKey:@"attributedContent"] 
			mutableCopyWithZone:[self zone]] autorelease];
	
	id attr_value;
	NSRange effectiveRange;
	NSRange limitRange = NSMakeRange(0, [mutableContent length]);
	 
	while (limitRange.length > 0)
	{
		attr_value = [mutableContent attribute:NSLinkAttributeName atIndex:limitRange.location 
				longestEffectiveRange:&effectiveRange inRange:limitRange];
		
		//attr_value = [mutableContent attribute:NSLinkAttributeName atIndex:limitRange.location effectiveRange:&effectiveRange];
		
		if ( attr_value != nil ) 
		{
			NSURL *theURL;
			NSURL *replacementURL = nil;
			
			// make sure we're dealing with a url
			if ( [attr_value isKindOfClass:[NSURL class]] )
				theURL = attr_value;
			else if ( [attr_value isKindOfClass:[NSString class]] )
				theURL = [NSURL URLWithString:attr_value];
						
			// if the url is an entry or folder, generate a journler link for it
			if ( [theURL isJournlerEntry] || [theURL isJournlerFolder] )
			{
				[anEntry resourceForJournlerObject:[self objectForURIRepresentation:theURL]];
			}
			
			// if the url is an address book record
			else if ( [theURL isAddressBookUID] )
			{
				NSString *uniqueId = [[theURL absoluteString] substringFromIndex:17];
				ABPerson *aPerson = (ABPerson*)[[ABAddressBook sharedAddressBook] recordForUniqueId:uniqueId];
				
				if ( aPerson != nil )
				{
					// see about deriving a contact for it
					JournlerResource *abResource = [anEntry resourceForABPerson:aPerson];
					replacementURL = [abResource URIRepresentation];
				}
				else
				{
					// remove the attribute
					[mutableContent removeAttribute:NSLinkAttributeName range:effectiveRange];
				}
			}
			
			// if the url is an iPhoto ID, remove it
			else if ( [theURL isPhotoID] )
			{
				[mutableContent removeAttribute:NSLinkAttributeName range:effectiveRange];
			}
			
			// if a replacement is available, replace the current url with it
			if ( replacementURL != nil )
				[mutableContent addAttribute:NSLinkAttributeName value:replacementURL range:effectiveRange];
		}
	
		limitRange = NSMakeRange(NSMaxRange(effectiveRange), NSMaxRange(limitRange) - NSMaxRange(effectiveRange));
	}

	[anEntry setValue:mutableContent forKey:@"attributedContent"];
	return completeSuccess;
}


- (void) installLameComponents 
{	
	/*
	BOOL success = YES;
	NSFileManager *fm = [NSFileManager defaultManager];
	
	// check that the components to be installed exist
	if ( ![fm fileExistsAtPath:[QTInstallController LAMEFrameworkBundlePath]] ) 
	{
		NSLog(@"JournalUpgradeController lameUpgrade - no framework at bundle path %@", [QTInstallController LAMEFrameworkBundlePath]);
		success = NO; goto bail;
	}
	
	if ( ![fm fileExistsAtPath:[QTInstallController LAMEComponentBundlePath]] ) 
	{
		NSLog(@"JournalUpgradeController lameUpgrade - no component at bundle path %@", [QTInstallController LAMEComponentBundlePath]);
		success = NO; goto bail;
	}
	
	// delete the components at their installed paths
	if ( [fm fileExistsAtPath:[QTInstallController LAMEFrameworkInstallPath]] ) 
	{
		if ( ![fm removeFileAtPath:[QTInstallController LAMEFrameworkInstallPath] handler:self] ) 
		{
			NSLog(@"JournalUpgradeController lameUpgrade - cannot delete framework %@", [QTInstallController LAMEFrameworkInstallPath]);
			success = NO; goto bail;
		}
	}
	
	if ( [fm fileExistsAtPath:[QTInstallController LAMEComponentInstallPath]] ) 
	{
		if ( ![fm removeFileAtPath:[QTInstallController LAMEComponentInstallPath] handler:self] ) 
		{
			NSLog(@"JournalUpgradeController lameUpgrade - cannot delete component %@", [QTInstallController LAMEComponentInstallPath]);
			success = NO; goto bail;
		}
	}
	
	// actually copy the framework and component
	if ( ![fm copyPath:[QTInstallController LAMEFrameworkBundlePath] toPath:[QTInstallController LAMEFrameworkInstallPath] handler:self] ) 
	{
		NSLog(@"JournalUpgradeController lameUpgrade - cannot copy framework");
		success = NO; goto bail;
	}
	
	if ( ![fm copyPath:[QTInstallController LAMEComponentBundlePath] toPath:[QTInstallController LAMEComponentInstallPath] handler:self] )
	{
		NSLog(@"JournalUpgradeController lameUpgrade - cannot copy framework");
		success = NO; goto bail;
	}

bail:	

	if ( !success )
		[[NSAlert lameInstallFailure] runModal];
	
	*/
	
	BOOL success = [SproutedLAMEInstaller simplyInstallLameComponents];
	if ( !success ) [[NSAlert lameInstallFailure] runModal];
}

- (id) objectForURIRepresentation:(NSURL*)aURL
{
	id object = nil;
	
	NSString *abs = [aURL absoluteString];
	NSString *tagID = [abs lastPathComponent];
	NSString *objectType = [[abs stringByDeletingLastPathComponent] lastPathComponent];
	
	if ( [objectType isEqualToString:@"entry"] )
		object = [entriesDictionary objectForKey:[NSNumber numberWithInt:[tagID intValue]]];
	else if ( [objectType isEqualToString:@"folder"] )
		object = [foldersDictionary objectForKey:[NSNumber numberWithInt:[tagID intValue]]];
	
	return object;
}

- (NSArray*) entriesForTagIDs:(NSArray*)tagIDs {
	
	//
	// utility for turning an array of entry ids into the entries themselves
	
	int i;
	NSMutableArray *entries = [[NSMutableArray alloc] initWithCapacity:[tagIDs count]];
	for ( i = 0; i < [tagIDs count]; i++ ) {
		id anEntry = [entriesDictionary objectForKey:[tagIDs objectAtIndex:i]];
		if ( anEntry )
			[entries addObject:anEntry];
	}
	
	return [entries autorelease];
	
}

#pragma mark -
#pragma mark 2.0 -> 2.5 upgrade

- (int) run200To210Upgrade:(JournlerJournal*)journal
{
	//
	// 1. backup the journal
	// 2. create resource objects for each entry
	// 3. convert the urls in the rtfd to reflect those resource objects
	// 4. save the entry
	//		a. package takes number only, delete old package name
	//		b. rtfd stored separately
	//		c. metadata saved to separate location
	// 5. reset the search index, creating a resource index as well
	
	int result;
	BOOL completeSuccess = YES;
	_journal = journal;
	upgradeMode = 1;
	
	
	// before doing anything, check if the user's journal is encrypted and let them know that encryption is no longer supported
	if ( [[_journal encryptionState] intValue] != PDEncryptionNone )
	{
		[[NSAlert upgradeEncryptionNoLongerSupported] runModal];
		[self quit210Upgrade:self];
	}
	
	
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	
	log210 = [[NSMutableString alloc] init];
	[log210 appendFormat:@"%s - Beginning 2.0 to 2.5 Upgrade\n", __PRETTY_FUNCTION__];
	
	session210 = [NSApp beginModalSessionForWindow:[self window]];
	[[self window] display];
	[NSApp runModalSession:session210];
	
	// backup the journal
	NSString *backupDir = [[[_journal journalPath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Journler Backup"];
	NSString *backupPath = [backupDir stringByAppendingPathComponent:@"v2.0 to v2.5 Backup.zip"];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	
	[progressIndicator210 setIndeterminate:YES];
	[progressIndicator210 startAnimation:self];
	[progressText210 setStringValue:NSLocalizedStringFromTable(@"backing up", @"UpgradeController", @"")];
	[NSApp runModalSession:session210];
	
	[log210 appendFormat:@"%s - Backing up Journler 2.0 data to %@\n", __PRETTY_FUNCTION__, backupPath];
	
	if ( ![fm fileExistsAtPath:backupDir] ) 
	{
		if ( ![fm createDirectoryAtPath:backupDir attributes:nil] ) 
		{
			// discontinue the upgrade if the user wants it
			if ( [[NSAlert upgradeCreateBackupDirectoryFailure] runModal] == NSAlertFirstButtonReturn ) 
			{
				NSError *error = nil;
				NSString *logPath = [[_journal journalPath] stringByAppendingPathComponent:kLogFilepath210];
				
				[log210 appendFormat:@"%s - unable to create backup directory, quitting upgrade\n", __PRETTY_FUNCTION__];
				if ( ![log210 writeToFile:logPath atomically:NO encoding:NSUnicodeStringEncoding error:&error] )
					NSLog(@"%s - unable to write upgrade log to %@, error %@", __PRETTY_FUNCTION__, logPath, error);
				
				[log210 release];
				[self quit210Upgrade:self];
			}
		}
	}
	
	if ( [fm fileExistsAtPath:backupDir] ) 
	{
		// ensure that a file does not already exist here
		backupPath = [backupPath pathWithoutOverwritingSelf];
		if ( ![ZipUtilities zip:[_journal journalPath] toFile:backupPath] )
		{
			// discontinue the upgrade if the user wants it
			if ( [[NSAlert upgradeBackupOldEntriesFailure] runModal] == NSAlertFirstButtonReturn ) 
			{
				NSError *error = nil;
				NSString *logPath = [[_journal journalPath] stringByAppendingPathComponent:kLogFilepath210];
					
				[log210 appendFormat:@"%s - unable to backup entries, quitting upgrade\n", __PRETTY_FUNCTION__];
				if ( ![log210 writeToFile:logPath atomically:NO encoding:NSUnicodeStringEncoding error:&error] )
					NSLog(@"%s - unable to write upgrade log to %@, error %@", __PRETTY_FUNCTION__, logPath, error);
				
				[log210 release];
				[self quit210Upgrade:self];
			}
		}
	}
	
	// create the resources directory
	if ( ![fm fileExistsAtPath:[_journal resourcesPath]] && ![fm createDirectoryAtPath:[_journal resourcesPath] attributes:nil] )
	{
		// critical error
		[log210 appendString:@"** Unable to create a resources directory **\n"];
		[[NSAlert upgradeCreateResourcesFolderFailure] runModal];
				
		NSError *error = nil;
		NSString *logPath = [[_journal journalPath] stringByAppendingPathComponent:kLogFilepath210];
		if ( ![log210 writeToFile:logPath atomically:NO encoding:NSUnicodeStringEncoding error:&error] )
			NSLog(@"%s - unable to write upgrade log to %@, error %@", __PRETTY_FUNCTION__, logPath, error);
		
		[log210 release];
		[self quit210Upgrade:self];
	}
	
	// create the search indexes, deleting the old one
	[progressText210 setStringValue:NSLocalizedStringFromTable(@"creating search indexes", @"UpgradeController", @"")];
	[NSApp runModalSession:session210];
	
	// completely remove the search indexes
	[[journal searchManager] closeIndex];
	[[journal searchManager] deleteIndexAtPath:[journal journalPath]];
	[_journal setSaveEntryOptions:kEntrySaveDoNotIndex|kEntrySaveDoNotCollect];
	
	/*
	if ( [fm fileExistsAtPath:[[journal journalPath] stringByAppendingPathComponent:@"Entries Index"]] )
		[fm removeFileAtPath:[[journal journalPath] stringByAppendingPathComponent:@"Entries Index"] handler:self];
	
	if ( ![[journal searchManager] createIndexAtPath:[journal journalPath]] )
	{
		//#warning warn the user
		[log210 appendFormat:@"%s - unable to create search indexes at path %@\n", __PRETTY_FUNCTION__, [journal journalPath]];
	}
	if ( ![[journal searchManager] loadIndexAtPath:[journal journalPath]] )
	{
		//#warning warn the user
		[log210 appendFormat:@"%s - unable to load search indexes at path %@\n", __PRETTY_FUNCTION__, [journal journalPath]];
	}
	*/
	
	// disable threaded indexing
	//[[_journal searchManager] setIndexesOnSeparateThread:NO];
	
	// process the entries and their resources
	int i;
	NSArray *entries = [journal valueForKey:@"entries"];
	
	[progressIndicator210 stopAnimation:self];
	[progressIndicator210 setIndeterminate:NO];
	[progressIndicator210 setMinValue:0.0];
	[progressIndicator210 setMaxValue:[entries count]];
	[progressIndicator210 setDoubleValue:0.0];
	
	[progressText210 setStringValue:NSLocalizedStringFromTable(@"processing entries", @"UpgradeController", @"")];
	[NSApp runModalSession:session210];
	
	[log210 appendFormat:@"%s - Processing entries\n\n", __PRETTY_FUNCTION__, [journal journalPath]];
	
	// disable collection but not indexing
	//[_journal setSaveEntryOptions:kEntrySaveDoNotCollect];
	
	for ( i = 0; i < [entries count]; i++ )
	{
		[NSApp runModalSession:session210];
		
		NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
		
		JournlerEntry *anEntry = [entries objectAtIndex:i];
		NSCalendarDate *dateModified = [[[anEntry valueForKey:@"calDateModified"] retain] autorelease];
		
		// create resources for the entry
		if ( ![self processResourcesForEntry:anEntry] )
		{
			// #warning alert the user
			completeSuccess = NO;
			[log210 appendFormat:@"****\n%s - unable to process resources for entry %@\n****\n", __PRETTY_FUNCTION__, [anEntry valueForKey:@"tagID"]];
		}
		
		// convert the existing resource urls to new format urls
		if ( ![self processResourcesLinksForEntry:anEntry] )
		{
			// #warning alert the user
			completeSuccess = NO;
			[log210 appendFormat:@"****\n%s - unable to process resource links for entry %@\n****\n", __PRETTY_FUNCTION__, [anEntry valueForKey:@"tagID"]];
		}
		
		// upgrade the entry's internal format
		[anEntry setValue:[NSNumber numberWithInt:250] forKey:@"version"];
		
		// perform maintenance on the entry (remove deprecated properties)
		[anEntry perform210Maintenance];
		
		// rename the package
		if ( ![[NSFileManager defaultManager] movePath:[anEntry pathToPackage] toPath:[anEntry packagePath] handler:self] )
		{
			completeSuccess = NO;
			[log210 appendFormat:@"****\n%s - unable to rename entry %@\n****\n", __PRETTY_FUNCTION__, [anEntry valueForKey:@"tagID"]];
		}
		
		// only once the package is renamed is it possible to process file:// type links
		if ( ![self processFileLinksForEntry:anEntry] )
		{
			// #warning alert the user
			completeSuccess = NO;
			[log210 appendFormat:@"****\n%s - unable to process file links for entry %@\n****\n", __PRETTY_FUNCTION__, [anEntry valueForKey:@"tagID"]];
		}
		
		// delete the encrypted marking
		NSString *encryptedPath = [[anEntry packagePath] stringByAppendingPathComponent:PDEntryPackageEncrypted];
		if ( [[NSFileManager defaultManager] fileExistsAtPath:encryptedPath] )
			[fm removeFileAtPath:encryptedPath handler:self];
		
		// save the entry using the new method to preserve packaging
		if ( ![_journal saveEntry:anEntry] )
		{
			completeSuccess = NO;
			[log210 appendFormat:@"****\n%s - unable to save entry %@\n****\n", __PRETTY_FUNCTION__, [anEntry valueForKey:@"tagID"]];
		}
		
		[anEntry setValue:dateModified forKey:@"calDateModified"];
		[progressIndicator210 incrementBy:1.0];
		[innerPool release];
	}
	
	[progressText210 setStringValue:NSLocalizedStringFromTable(@"saving journal", @"UpgradeController", @"")];
	[progressIndicator210 setIndeterminate:YES];
	[progressIndicator210 startAnimation:self];
	[NSApp runModalSession:session210];
	
	[log210 appendFormat:@"%s - Saving Journal\n\n", __PRETTY_FUNCTION__, [journal journalPath]];
	
	// re-set the folder icons
	[[_journal valueForKey:@"collections"] makeObjectsPerformSelector:@selector(determineIcon)];
	
	// save the journal
	
	// write it to disk
	[[journal searchManager] writeIndexToDisk];
	
	// close the search manager
	[[journal searchManager] closeIndex];
	
	// no need to save the entries and whatnot again
	//[[_journal valueForKey:@"entries"] setValue:[NSNumber numberWithBool:NO] forKey:@"dirty"];
	[[_journal valueForKey:@"resources"] setValue:[NSNumber numberWithBool:YES] forKey:@"dirty"];
	//[[_journal valueForKey:@"collections"] setValue:[NSNumber numberWithBool:NO] forKey:@"dirty"];
	
	// update the journal's version info
	[_journal setValue:[NSNumber numberWithInt:250] forKey:@"version"];
	
	// remove unneeded values from the properties dictionary
	NSMutableDictionary *properties = [[[_journal properties] mutableCopyWithZone:[self zone]] autorelease];
	
	[properties setObject:[NSNumber numberWithBool:YES] forKey:PDJournalProperShutDown];
	[properties removeObjectForKey:PDJournalEncryptionState];
	[properties removeObjectForKey:@"WikiLinks"];
	[properties removeObjectForKey:@"Blogs"];
	
	[_journal setProperties:properties];
	
	// set password protection on the journal
	if ( [AGKeychain checkForExistanceOfKeychainItem:@"NameJournlerKey" withItemKind:@"JournalPassword" forUsername:@"JournalPasswordLogin"] )
	{
		// grab the password
		NSString *password = [AGKeychain getPasswordFromKeychainItem:@"NameJournlerKey" 
				withItemKind:@"JournalPassword" forUsername:@"JournalPasswordLogin"];
		if ( password == nil )
		{
			//#warning let the user know
			[log210 appendFormat:@"%s - unable to get password from keychain", __PRETTY_FUNCTION__];
		}
		else
		{
			// delete the keychain item
			[AGKeychain deleteKeychainItem:@"NameJournlerKey" withItemKind:@"JournalPassword" forUsername:@"JournalPasswordLogin"];
			
			// grab an md5 digest of the password
			NSString *passwordDigest = [password journlerMD5Digest];
			if ( passwordDigest == nil )
			{
				[log210 appendFormat:@"%s - unable to get digest of password", __PRETTY_FUNCTION__];
			}
			else
			{
				// save the digest to the appropriate location
				NSError *error = nil;
				NSString *encryptedFilename = [[_journal journalPath] stringByAppendingPathComponent:PDJournalPasswordProtectedLoc];
				
				if ( ![passwordDigest writeToFile:encryptedFilename atomically:YES encoding:NSUnicodeStringEncoding error:&error] )
					[log210 appendFormat:@"%s - unable to write password to path %@, error %@", __PRETTY_FUNCTION__, encryptedFilename, error];
			}
		}
	}
	
	// save the entire journal
	[_journal save:nil];
	
	// re-enable indexing
	//[_journal setSaveEntryOptions:kEntrySaveIndexAndCollect];
	
	// copy the wordlist if available to the user's support directory - that way the user can make changes without damaging original
	NSString *wordlistDestination = [[_journal journalPath] stringByAppendingPathComponent:PDJournalWordListLoc];
	NSString *wordlistSource = [[NSBundle mainBundle] pathForResource:@"AutoCorrectWordPairs" ofType:@"csv"];
	
	if ( wordlistSource != nil && wordlistDestination != nil )
	{
		if ( ![[NSFileManager defaultManager] copyPath:wordlistSource toPath:wordlistDestination handler:self] )
		{
			[log210 appendFormat:@"%s - unable to copy wordlist from %@ to %@\n\n", __PRETTY_FUNCTION__, wordlistSource, wordlistDestination];
			[ud setBool:NO forKey:@"EntryTextAutoCorrectSpelling"];
			[ud setBool:NO forKey:@"EntryTextAutoCorrectSpellingUseWordList"];
		}
		else
		{
			[ud setBool:YES forKey:@"EntryTextAutoCorrectSpelling"];
			[ud setBool:YES forKey:@"EntryTextAutoCorrectSpellingUseWordList"];
		}
	}
	
	// update the user's preferences
	[ud setBool:YES forKey:@"UseVisualAidWherePossibleWhenImporting"];
	[ud setBool:NO forKey:@"UpdateDateModifiedOnlyAfterTextChange"];
	[ud setBool:NO forKey:@"ConvertImportedURLsToWebArchives"];
	
	[ud setBool:YES forKey:@"EntryExportIncludeHeader"];
	[ud setBool:YES forKey:@"EntryExportSetCreationDate"];
	[ud setBool:YES forKey:@"EntryExportSetModificationDate"];
	[ud setBool:NO forKey:@"ImportPreserveDateModified"];
	[ud setBool:NO forKey:@"EntryImportSetDefaultResource"];
	[ud setBool:YES forKey:@"SourceListShowsEntryCount"];
	
	[ud setBool:YES forKey:@"BlogsUseAdvancedHTMLGeneration"];
	[ud setBool:YES forKey:@"ExportsUseAdvancedHTMLGeneration"];
	[ud setBool:YES forKey:@"CopyingUseAdvancedHTMLGeneration"];
	
	[ud setObject:@"font, min-height" forKey:@"BlogsNoAttributeList"];
	[ud setObject:[NSString string] forKey:@"ExportsNoAttributeList"];
	[ud setObject:[NSString string] forKey:@"CopyingNoAttributeList"];
	
	[ud setBool:YES forKey:@"WebViewFindIgnoreCase"];
	[ud setBool:NO forKey:@"SearchSpaceMeansOr"];
	[ud setBool:NO forKey:@"NewEntryImportNewWindow"];
	[ud setBool:NO forKey:@"EditDatesWithGraphicalInterface"];
	[ud setBool:NO forKey:@"NewEntryWithDueDate"];
	
	[ud setBool:YES forKey:@"MainWindowBookmarksVisible"];
	[ud setBool:NO forKey:@"MainWindowTabsAlwaysVisible"];
	
	[ud setBool:YES forKey:@"SearchIncludesEntries"];
	[ud setBool:YES forKey:@"SearchIncludesResources"];
	[ud setBool:YES forKey:@"SearchMediaByDefault"];
	
	[ud setBool:YES forKey:@"EntryTextUseSmartQuotes"];
	[ud setBool:YES forKey:@"EntryTextShowWordCount"];
	[ud setBool:YES forKey:@"EntryTextEnableSpellChecking"];
	[ud setBool:YES forKey:@"EntryTextRecognizeWikiLinks"];
	[ud setBool:YES forKey:@"EntryTextRecognizeURLs"];
	
	[ud setBool:NO forKey:@"EntryTextAutoCorrectSpellingUseBuiltIn"];
	
	[ud setInteger:100 forKey:@"EntryTextDefaultZoom"];
	[ud setInteger:100 forKey:@"EntryTextFullscreenZoom"];
	[ud setInteger:0 forKey:@"EntryTextHorizontalInset"];
	[ud setInteger:100 forKey:@"EntryTextHorizontalInsetFullscreen"];
	[ud setInteger:80 forKey:@"PhotoViewPhotoSize"];
	
	[ud setBool:YES forKey:@"EntryTextLinkUnderlined"];
	[ud setColor:[NSColor blueColor] forKey:@"EntryTextLinkColor"];
	
	[ud setBool:YES forKey:@"NewMediaLinkIncludeIcon"];
	[ud setBool:YES forKey:@"ResourceTableShowFolders"];
	[ud setBool:YES forKey:@"ResourceTableShowJournlerLinks"];
	[ud setBool:NO forKey:@"ResourceTableCollapseDocuments"];
	[ud setBool:NO forKey:@"ResourceTableArrangedCollapsedDocumentsByKind"];
	
	[ud setFont:[NSFont controlContentFontOfSize:11]  forKey:@"BrowserTableFont"];
	[ud setFont:[NSFont controlContentFontOfSize:11]  forKey:@"FoldersTableFont"];
	[ud setFont:[NSFont controlContentFontOfSize:11]  forKey:@"ReferencesTableFont"];
	
	//[ud removeObjectForKey:@"HeaderBackgroundColor"];
	//[ud removeObjectForKey:@"EntryBackgroundColor"];
	
	[ud setColor:[NSColor colorWithCalibratedWhite:0.75 alpha:1.0] forKey:@"HeaderLabelColor"];
	[ud setColor:[NSColor colorWithCalibratedWhite:0.00 alpha:1.0] forKey:@"HeaderTextColor"];
	
	[ud setInteger:0 forKey:@"DefaultSnapshotFormat"];
	[ud setInteger:0 forKey:@"DefaultAudioCodec"];
	[ud setObject:[NSNumber numberWithBool:NO] forKey:@"CommandWClosesWindow"];
	
	[ud removeObjectForKey:@"DateTimeFormat"];
	[ud removeObjectForKey:@"DateTimeFormatSystemPrefs"];
	[ud removeObjectForKey:@"Window Style"];
	
	[ud removeObjectForKey:@"DefaultDateFont"];
	[ud removeObjectForKey:@"Date Stamp Color"];
	[ud removeObjectForKey:@"DefaultTitleFont"];
	[ud removeObjectForKey:@"Entry Title Color"];
	[ud removeObjectForKey:@"DefaultCategoryFont"];
	[ud removeObjectForKey:@"Entry Title Color"];
	[ud removeObjectForKey:@"Category Color"];
	[ud removeObjectForKey:@"Keywords Color"];
	
	[ud removeObjectForKey:@"CalendarDayNoEntries"];
	[ud removeObjectForKey:@"CalendarDayToday"];
	[ud removeObjectForKey:@"CalendarDayWithEntries"];
	[ud removeObjectForKey:@"CalendarDaySelected"];
	[ud removeObjectForKey:@"CalendarUseButton"];
	
	[ud removeObjectForKey:@"Lockout Enabled"];
	
	[ud setObject:@"Red" forKey:@"LabelName1"];
	[ud setObject:@"Orange" forKey:@"LabelName2"];
	[ud setObject:@"Yellow" forKey:@"LabelName3"];
	[ud setObject:@"Green" forKey:@"LabelName4"];
	[ud setObject:@"Blue" forKey:@"LabelName5"];
	[ud setObject:@"Purple" forKey:@"LabelName6"];
	[ud setObject:@"Gray" forKey:@"LabelName7"];

	[ud setInteger:0 forKey:@"AudioRecordingFormat"];
	[ud setInteger:0 forKey:@"ScriptsInstallationDirectory"];
	
	[log210 appendFormat:@"%s - Completed 2.0 to 2.5 Upgrade\n\n", __PRETTY_FUNCTION__];
	
	[progressText210 setStringValue:NSLocalizedStringFromTable(@"upgrade complete", @"UpgradeController", @"")];
	
	// show the relaunch button and grab the users attention
	[progressIndicator210 setHidden:YES];
	[NSApp endModalSession:session210];
	[[self window] orderOut:self];
	
	[NSApp requestUserAttention:NSInformationalRequest];
	[NSApp runModalForWindow:licenseChanged210];
	
	[log210 appendFormat:@"%s - Relaunching Journler\n\n", __PRETTY_FUNCTION__];
	
	NSError *error = nil;
	NSString *logPath = [[_journal journalPath] stringByAppendingPathComponent:kLogFilepath210];
	if ( ![log210 writeToFile:logPath atomically:YES encoding:NSUnicodeStringEncoding error:&error] )
		NSLog(@"%s - unable to write upgrade log to %@, error %@", __PRETTY_FUNCTION__, logPath, error);
	
	[log210 release];
	[NSApp relaunch:self];
	return result;
}

- (BOOL) processResourcesForEntry:(JournlerEntry*)anEntry
{	
	BOOL completeSuccess = YES;
	
	NSString *resourcePath = [anEntry pathToResourcesCreatingIfNecessary:NO];
	if ( resourcePath == nil || ![[NSFileManager defaultManager] fileExistsAtPath:resourcePath] )
		return YES;
	
	NSArray *resources = [[NSFileManager defaultManager] directoryContentsAtPath:resourcePath];
	if ( resources == nil || [resources count] == 0 )
		return YES;
	
	int i;
	for ( i = 0; i < [resources count]; i++ )
	{
		JournlerResource *aResource = nil;
		NSString *path = [resourcePath stringByAppendingPathComponent:[resources objectAtIndex:i]];
		
		NSString *uti = [[NSWorkspace sharedWorkspace] UTIForFile:[[NSWorkspace sharedWorkspace] resolveForAliases:path]];
		NSString *extension = [path pathExtension];
		
		// if the resource path is an address book record, create the appropriate resource and delete the file
		if ( uti != nil && UTTypeEqual((CFStringRef)uti,(CFStringRef)kJournlerABFileUTI) || [extension isEqualToString:kJournlerABFileExtension] )
		{
			NSError *error = nil;
			NSString *uniqueId = [NSString stringWithContentsOfFile:path usedEncoding:NULL error:&error];
			if ( uniqueId == nil )
				NSLog(@"%s - there was a problem reading the unique id at path %@, error %@", __PRETTY_FUNCTION__, path, error);
			else
				aResource = [anEntry resourceForABPerson:(ABPerson*)[[ABAddressBook sharedAddressBook] recordForUniqueId:uniqueId]];
		}
		
		// otherwise create a file resource
		else
		{
			if ( uti == nil )
				[log210 appendFormat:@"****\n%s - unknown uti for file at path %@\n****\n", __PRETTY_FUNCTION__, path];
			
			aResource = [[JournlerResource alloc] initFileResource:path];				
			[aResource setValue:[NSNumber numberWithInt:[_journal newResourceTag]] forKey:@"tagID"];
			
			[anEntry addResource:aResource];
			[[anEntry valueForKey:@"journal"] addResource:aResource];
		}
		
		// take action depending on the successful creation of the resource
		if ( aResource == nil )
		{
			completeSuccess = NO;
			[log210 appendFormat:@"****\n%s - unable to create resource for file at path %@\n****\n", __PRETTY_FUNCTION__, path];
		}
		else
		{
			// set the resource to search, ignoring previous settings
			[aResource setValue:[NSNumber numberWithBool:YES] forKey:@"searches"];
		}
	}
	
	return completeSuccess;
}

- (BOOL) processResourcesLinksForEntry:(JournlerEntry*)anEntry
{	
	//static NSString *httpScheme = @"http";
	
	BOOL completeSuccess = YES;
	NSMutableAttributedString *mutableContent = [[[anEntry valueForKey:@"attributedContent"] 
			mutableCopyWithZone:[self zone]] autorelease];
	
	id attr_value;
	NSRange effectiveRange;
	NSRange limitRange = NSMakeRange(0, [mutableContent length]);
	 
	while (limitRange.length > 0)
	{
		attr_value = [mutableContent attribute:NSLinkAttributeName atIndex:limitRange.location 
				longestEffectiveRange:&effectiveRange inRange:limitRange];
		
		if ( attr_value != nil ) 
		{
			NSURL *theURL = nil;
			NSURL *replacementURL = nil;
			
			// make sure we're dealing with a url
			if ( [attr_value isKindOfClass:[NSURL class]] )
				theURL = attr_value;
			else if ( [attr_value isKindOfClass:[NSString class]] )
				theURL = [NSURL URLWithString:attr_value];
			
			// if the url is a resource, provide a replacement
			if ( [theURL isOldJournlerResource] ) 
			{
				// prepare the string for editing
				NSString *originalURLString = [[theURL absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				
				int i;
				JournlerResource *theResource = nil;
				NSString *filename = [originalURLString lastPathComponent];
				
				// take care to make sure this resource belongs to the entry in question
				NSNumber *urlTag = [NSNumber numberWithInt:[[[[theURL absoluteString] stringByDeletingLastPathComponent] lastPathComponent] intValue]];
				
				NSArray *entryResources;
				JournlerEntry *targetEntry;
				
				if ( [urlTag isEqualToNumber:[anEntry valueForKey:@"tagID"]] )
				{
					#ifdef __DEBUG__
					NSLog(@"resource belongs to this entry");
					#endif
					
					targetEntry = anEntry;
					entryResources = [targetEntry valueForKey:@"resources"];
				}
				else
				{
					#ifdef __DEBUG__
					NSLog(@"resource does not belong to this entry");
					#endif
					
					targetEntry = [_journal entryForTagID:urlTag];
					entryResources = [targetEntry valueForKey:@"resources"];
				}
				
				// discover the reference this link refers to
				for ( i = 0; i < [entryResources count]; i++ ) 
				{
					JournlerResource *aResource = [entryResources objectAtIndex:i];
					
					if ( [[filename pathExtension] isEqualToString:kJournlerABFileExtension] )
					{
						// special processing for address book links
						if ( [aResource type] != kResourceTypeABRecord )
							continue;
						
						NSString *uniqueId = [NSString stringWithContentsOfURL:[targetEntry fileURLForResourceURL:theURL]];
						if ( [uniqueId isEqualToString:[aResource valueForKey:@"uniqueId"]] )
							theResource = aResource;
						
						NSString *abPath = [[targetEntry fileURLForResourceURL:theURL] path];
						if ( abPath != nil && [[NSFileManager defaultManager] fileExistsAtPath:abPath] )
							[[NSFileManager defaultManager] removeFileAtPath:[[targetEntry fileURLForResourceURL:theURL] path] 
									handler:self];
							
						break;
					}
					else if ( [[aResource valueForKey:@"filename"] isEqualToString:filename] ) 
					{
						// otherwise just looking for a filename match
						theResource = aResource;
						break;
					}
				}
				
				// report any errors
				if ( theResource == nil ) 
				{
					completeSuccess = NO;
					[log210 appendFormat:@"****\n%s - unable to derive new resource link for old resource link %@\n****\n", 
							__PRETTY_FUNCTION__, originalURLString];
				}
				else 
				{
					// otherwise, prepare the replacment url
					replacementURL = [theResource URIRepresentation];
					
					#ifdef __DEBUG__
					[log210 appendFormat:@"\n%@\n%@\n", originalURLString, [replacementURL absoluteString]];
					#endif
				}
			}
			
			// if the url is a web url, generate a bookmark for it
			/*
			else if ( [[theURL scheme] isEqualToString:httpScheme] )
			{
				NSString *urlTitle = [[mutableContent string] substringWithRange:effectiveRange];
				[anEntry resourceForURL:[theURL absoluteString] title:urlTitle];
			}
			*/
			
						
			// if the url is an entry or folder, generate a journler link for it
			else if ( [theURL isJournlerEntry] || [theURL isJournlerFolder] )
			{
				[anEntry resourceForJournlerObject:[_journal objectForURIRepresentation:theURL]];
			}
			
			// if the url is an address book record
			else if ( [theURL isAddressBookUID] )
			{
				NSString *uniqueId = [[theURL absoluteString] substringFromIndex:17];
				ABPerson *aPerson = (ABPerson*)[[ABAddressBook sharedAddressBook] recordForUniqueId:uniqueId];
				
				if ( aPerson != nil )
				{
					// see about deriving a contact for it
					JournlerResource *abResource = [anEntry resourceForABPerson:aPerson];
					replacementURL = [abResource URIRepresentation];
				}
				else
				{
					// remove the attribute
					[mutableContent removeAttribute:NSLinkAttributeName range:effectiveRange];
				}
			}
			
			// if the url is an iPhoto ID, remove it
			else if ( [theURL isPhotoID] )
			{
				[mutableContent removeAttribute:NSLinkAttributeName range:effectiveRange];
			}
			
			// if a replacement is available, replace the current url with it
			if ( replacementURL != nil )
				[mutableContent addAttribute:NSLinkAttributeName value:replacementURL range:effectiveRange];
		}
	
		limitRange = NSMakeRange(NSMaxRange(effectiveRange), NSMaxRange(limitRange) - NSMaxRange(effectiveRange));
	}

	[anEntry setValue:mutableContent forKey:@"attributedContent"];
	return completeSuccess;
}

- (BOOL) processFileLinksForEntry:(JournlerEntry*)anEntry
{
	BOOL completeSuccess = YES;
	NSMutableAttributedString *mutableContent = [[[anEntry valueForKey:@"attributedContent"] 
			mutableCopyWithZone:[self zone]] autorelease];
			
	// for converting file resources
	NSMutableDictionary *pathToResourceDictionary = [NSMutableDictionary dictionary];
	
	id attr_value;
	NSRange effectiveRange;
	NSRange limitRange = NSMakeRange(0, [mutableContent length]);
	 
	while (limitRange.length > 0)
	{
		attr_value = [mutableContent attribute:NSLinkAttributeName atIndex:limitRange.location 
				longestEffectiveRange:&effectiveRange inRange:limitRange];
		
		if ( attr_value != nil ) 
		{
			NSURL *theURL = nil;
			NSURL *replacementURL = nil;
			
			// make sure we're dealing with a url
			if ( [attr_value isKindOfClass:[NSURL class]] )
				theURL = attr_value;
			else if ( [attr_value isKindOfClass:[NSString class]] )
				theURL = [NSURL URLWithString:attr_value];

			// check for a file url
			if ( [theURL isFileURL] )
			{
				// fist see if this filepath has already yielded a resource
				JournlerResource *theResource = [pathToResourceDictionary objectForKey:theURL];
				if ( theResource != nil )
				{
					// easy, the replacement url is the resource uri rep
					replacementURL = [theResource URIRepresentation];
				}
				else
				{
					// produce a file resource for this object, forcing a link
					theResource = [anEntry resourceForFile:[theURL path] operation:kNewResourceForceLink];
					if ( theResource == nil )
					{
						completeSuccess = NO;
						[log210 appendFormat:@"****\n%s - unable to produce new resource for entry %@ with path %@\n****\n", 
								__PRETTY_FUNCTION__, [anEntry tagID], [theURL path]];
					}
					else
					{
						// easy, the replacement url is the resource uri rep
						replacementURL = [theResource URIRepresentation];
						[pathToResourceDictionary setObject:theResource forKey:theURL];
						
						#ifdef __DEBUG__
						[log210 appendFormat:@"\n%@\n%@\n", [theURL absoluteString], [replacementURL absoluteString]];
						#endif
					}
				}
			}
			
			// if a replacement is available, replace the current url with it
			if ( replacementURL != nil )
				[mutableContent addAttribute:NSLinkAttributeName value:replacementURL range:effectiveRange];
		}
	
		limitRange = NSMakeRange(NSMaxRange(effectiveRange), NSMaxRange(limitRange) - NSMaxRange(effectiveRange));
	}

	[anEntry setValue:mutableContent forKey:@"attributedContent"];
	return completeSuccess;

}

#pragma mark -

- (IBAction) relaunchJournler:(id)sender
{
	[NSApp stopModal];
}

- (IBAction)quit210Upgrade:(id)sender
{
	[self close];
	[NSApp terminate:self];
}

#pragma mark -
#pragma mark 2.1 -> 2.5 Upgrade

- (void) run210To250Upgrade:(JournlerJournal*)aJournal
{
	// should be simple
	// 1. establish the resources directory
	// 2. set the version number
	// 3. mark every object as dirty
	// 4. set the resources array to the single owner for each resource
	// 5. estalish the all-utis property
	// 6. save the journal
	// 7. show the license info and relaunch
	
	NSModalSession session250 = [NSApp beginModalSessionForWindow:[self window]];
	[[self window] display];
	[NSApp runModalSession:session250];
	
	[progressIndicator210 setIndeterminate:YES];
	[progressIndicator210 startAnimation:self];
	[progressText210 setStringValue:NSLocalizedStringFromTable(@"210250 upgrade", @"UpgradeController", @"")];
	[NSApp runModalSession:session250];
	
	// 1. establish the resource directory
	
	NSString *resourcesPath = [aJournal resourcesPath];
	if ( ![[NSFileManager defaultManager] fileExistsAtPath:resourcesPath]
		&& ![[NSFileManager defaultManager] createDirectoryAtPath:resourcesPath attributes:nil] )
	{
		NSBeep();
		NSLog(@"%s - unable to create resources path at %@", __PRETTY_FUNCTION__, resourcesPath);
	}
	
	// 2. set the journal version
	
	[aJournal setVersion:[NSNumber numberWithInt:250]];
	
	// disable threaded indexing
	//[[aJournal searchManager] setIndexesOnSeparateThread:NO];
	
	// 4. set the resources array to the single owner for each resource
	//		b. set the utis conforming option as well
	
    for ( JournlerResource *aResource in [aJournal resources] )
	{
		JournlerEntry *theOwner = [aResource entry];
		if ( theOwner == nil )
			NSLog(@"%s - resource %@ does not have an owning entry", __PRETTY_FUNCTION__, [aResource tagID]);
		else
			[aResource setEntries:[NSArray arrayWithObject:theOwner]];
		
		NSString *theUTI = [aResource uti];
		NSArray *allUTIsArray;
		if ( [[JournlerResource definedUTIs] containsObject:theUTI] )
			allUTIsArray = [NSArray array];
		else
			allUTIsArray = [[NSWorkspace sharedWorkspace] allParentsAsArrayForUTI:theUTI];
		
		#ifdef __DEBUG__
		NSLog([allUTIsArray description]);
		#endif
		
		[aResource setUtisConforming:allUTIsArray];
		
		[NSApp runModalSession:session250];
	}
	
	// 5. estalish the all-utis property
	
	// 6. save the journal, disabling search
	//	- save each object one at a time, run the modal session, then save the journal
	
	[aJournal setSaveEntryOptions:kEntrySaveDoNotIndex|kEntrySaveDoNotCollect];
	
	NSNumber *yesDirty = [NSNumber numberWithBool:YES];
	
    for ( id anObject in [aJournal resources] )
	{
		[anObject setDirty:yesDirty];
		[aJournal saveResource:anObject];
		[NSApp runModalSession:session250];
	}
	
    for ( id anObject in [aJournal entries] )
	{
		[anObject setDirty:yesDirty];
		[aJournal saveEntry:anObject];
		[NSApp runModalSession:session250];
	}
	
    for ( id anObject in [aJournal collections] )
	{
		[anObject setDirty:yesDirty];
		[aJournal saveCollection:anObject];
		[NSApp runModalSession:session250];
	}
	
    for ( id anObject in [aJournal blogs] )
	{
		[anObject setDirty:yesDirty];
		[aJournal saveBlog:anObject];
		[NSApp runModalSession:session250];
	}
	
	[aJournal setDirty:yesDirty];
	BOOL success = [aJournal save:nil];
	
	[aJournal setSaveEntryOptions:kEntrySaveIndexAndCollect];
	
	if ( success == NO )
	{
		NSLog(@"%s - there was a problem saving the journal", __PRETTY_FUNCTION__);
	}
	
	// 7. show the license request and relaunch
	
	[NSApp endModalSession:session250];
	[[self window] orderOut:self];
	
	[NSApp requestUserAttention:NSInformationalRequest];
	[NSApp runModalForWindow:licenseChanged210];
	
	[NSApp relaunch:self];
	
}

#pragma mark -
#pragma mark 2.5.0 -> 2.5.3

- (BOOL) perform250To253Upgrade:(JournlerJournal*)aJournal
{	
	// remove unused variables from entries, save every entry
	// remove unused variables from resources, save every resource
	// save folder images, remove folder images, reload folder images, save folders
	// update the version number, save the journal
	
	NSLog(@"%s",__PRETTY_FUNCTION__);
	NSLog(@"Performing 2.5.3 upgrade...");
	
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert setMessageText:NSLocalizedStringFromTable(@"253 reset folder icons msg", @"UpgradeController", @"")];
	[alert setInformativeText:NSLocalizedStringFromTable(@"253 reset folder icons info", @"UpgradeController", @"")];
	[alert runModal];
	
	[[self window] setTitle:NSLocalizedStringFromTable(@"253 upgrade window title", @"UpgradeController", @"")];
	
	[progressIndicator210 setUsesThreadedAnimation:YES];
	[progressIndicator210 setIndeterminate:YES];
	[progressIndicator210 startAnimation:self];
		
	session253 = [NSApp beginModalSessionForWindow:[self window]];
	[[self window] display];
	[NSApp runModalSession:session253];
	
	// prepare the desktop 
	NSArray *desktopPossibilities = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory,NSUserDomainMask,YES);
	NSString *desktop = ( [desktopPossibilities count] > 0 ? [desktopPossibilities objectAtIndex:0] : @"~/Desktop/" );
	NSString *folderIconsPath = [desktop stringByAppendingPathComponent:@"Journler Folder Icons"];
	
	if ( ![[NSFileManager defaultManager] fileExistsAtPath:folderIconsPath] && ![[NSFileManager defaultManager] createDirectoryAtPath:folderIconsPath attributes:nil] )
		NSLog(@"%s - unable to create folder at path %@", __PRETTY_FUNCTION__, folderIconsPath);
	
	// do not index or collect entries while saving them
	[aJournal setSaveEntryOptions:kEntrySaveDoNotIndex|kEntrySaveDoNotCollect];
	
    for ( JournlerEntry *anEntry in [aJournal entries] )
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		[anEntry perform253Maintenance];
		[anEntry setDirty:BooleanNumber(YES)];

		[NSApp runModalSession:session253];
		[pool release];
	}
   
    for ( JournlerResource *aResource in [aJournal resources] )
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		[aResource perform253Maintenance];
		[aResource setDirty:BooleanNumber(YES)];

		[NSApp runModalSession:session253];		
		[pool release];
	}
	
    for ( JournlerCollection *aFolder in [aJournal collections] )
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		NSImage *theIcon = [aFolder icon];
		NSData *tiffRepresentation = [theIcon TIFFRepresentation];
		NSString *thePath = [[[folderIconsPath stringByAppendingPathComponent:[[aFolder title] pathSafeString]] 
		stringByAppendingPathExtension:@"tif"] pathWithoutOverwritingSelf];
		
		if ( ![tiffRepresentation writeToFile:thePath options:0 error:nil] )
			NSLog(@"%s - unable to write icon for folder %@ to path %@", __PRETTY_FUNCTION__, [aFolder title], thePath);
		
		[aFolder perform253Maintenance];
		[aFolder setDirty:BooleanNumber(YES)];
		
		[NSApp runModalSession:session253];
		[pool release];
	}
	
	// save the journal
	[aJournal setVersion:[NSNumber numberWithInt:253]];
	[aJournal setValue:[NSNumber numberWithBool:YES] forKey:@"shutDownProperly"];
	[aJournal save:nil];
	
	// a trick to prevent the main window controller from resaving the journal
	[aJournal setLoaded:NO];
	
	// return indexing and collecting to normal
	[aJournal setSaveEntryOptions:kEntrySaveIndexAndCollect];

	[headerText210 setStringValue:NSLocalizedStringFromTable(@"upgrade complete", @"UpgradeController", @"")];
	[headerText210 display];
	[progressIndicator210 stopAnimation:self];
	[progressIndicator210 setHidden:YES];
	
	[relaunch210 setHidden:NO];
	[NSApp endModalSession:session253];
	
	[NSApp runModalForWindow:[self window]];
	
	[[self window] orderOut:self];
	[NSApp relaunch:self];
	
	return YES;
}

#pragma mark -
#pragma mark Moving the Journal out of app support

- (BOOL) moveJournalOutOfApplicationSupport:(JournlerJournal*)aJournal
{

// -------------------------------------
	// move the journal out of app support to library
	//
	// checkForModifiedResources - what is this doing. i should wait for it to finish before changing the folder's location, then run it again, or?
	// resetRelativePaths
	// resetSearchManager
	// dirty the journal and touch everything
	// save the journal
	
	BOOL success = NO;
	NSString *journalPath = [aJournal journalPath];
	//NSString *journalParentFolder = [journalPath stringByDeletingLastPathComponent];
	
	//NSString *userLibrary = [self libraryFolder];
	NSString *userDocuments = [self documentsFolder];
	//NSString *userAppSupport = [self applicationSupportFolder];
	
	//NSLog(@"%s\napp support:%@\n library: %@\njournal parent: %@", __PRETTY_FUNCTION__, userLibrary, userAppSupport, journalParentFolder );
	
	if ( userDocuments == nil )
	{
		success = NO;
		NSLog(@"%s - unable to locate user's documents folder, journal move cancelled", __PRETTY_FUNCTION__);
	}
	else
	{
	
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *journalInDocumentsFolder = [userDocuments stringByAppendingPathComponent:@"Journler"];
		
		NSLog(@"%s - need to move the journal out of app support at %@", __PRETTY_FUNCTION__, [NSDate date]);
		
		NSInteger alertResult = [[self alertForMovingJournalOutOfApplicationSupport] runModal];
		if ( alertResult == NSAlertSecondButtonReturn )
		{
			// user canceled the operation
			[NSApp terminate:self];
		}
		else
		{
			// make sure no file already exists in this directory
			if ( [fileManager fileExistsAtPath:journalInDocumentsFolder] )
			{
				[[self alertWhenFolderNamedJournalAlreadyExistsInLibrary] runModal];
				[NSApp terminate:self];
			}
			else
			{			
				[progressIndicator210 setUsesThreadedAnimation:YES];
				[progressIndicator210 setIndeterminate:YES];
				[progressIndicator210 startAnimation:self];
				
				[progressText210 setStringValue:NSLocalizedStringFromTable(@"Some time may be required", @"UpgradeController", @"")];
				[[self window] setTitle:NSLocalizedStringFromTable(@"Data Storage Update", @"UpgradeController", @"")];
				[[self window] center];
				[self showWindow:self];
							
				if ( [fileManager respondsToSelector:@selector(moveItemAtPath:toPath:error:)] )
				{
					// 10.5 fork
					NSError *error = nil;
					success = [fileManager moveItemAtPath:journalPath toPath:journalInDocumentsFolder error:&error];
				}
				else
				{
					// 10.4 fork
					success = [fileManager movePath:journalPath toPath:journalInDocumentsFolder handler:self];
				}
				
				
				if ( success == YES )
				{
					// note the new journal path in the journal
					[aJournal setJournalPath:journalInDocumentsFolder];
					
					// note the new journal path in preferences
					[[NSUserDefaults standardUserDefaults] setObject:journalInDocumentsFolder forKey:@"Default Journal Location"];
					
					// reset the relative paths on the resources
					[aJournal resetRelativePaths];
					
					// reset the search index
					[aJournal resetSearchManager];
					
					// dirty the journal and write it out to disk without indexing or collecting
					{
						NSError *error = nil;
						NSNumber *dirty = [NSNumber numberWithBool:YES];
						[[aJournal entries] setValue:dirty forKey:@"dirty"];
						[[aJournal collections] setValue:dirty forKey:@"dirty"];
						[[aJournal resources] setValue:dirty forKey:@"dirty"];
						[[aJournal blogs] setValue:dirty forKey:@"dirty"];
						
						[aJournal setSaveEntryOptions:(kEntrySaveDoNotIndex|kEntrySaveDoNotCollect)];
						
						if ( [aJournal save:&error] )
						{
							// success
						}
						else
						{
							NSLog(@"%s - error saving journal", __PRETTY_FUNCTION__);
							
							NSBeep();
							if ( error != nil ) [NSApp presentError:error];
							else [[NSAlert saveError] runModal];
						}
						
						[aJournal setSaveEntryOptions:(kEntrySaveIndexAndCollect)];
					}
					
					// note the success and let the user know
					NSLog(@"%s - move from %@ to %@ successful", __PRETTY_FUNCTION__, journalPath, journalInDocumentsFolder);
					[[self alertWhenDataStoreMoveSucceeds] runModal];
				}
				else
				{
					// note the problem and put up an alert
					NSLog(@"*** %s - move from %@ to %@ not successful! ***", __PRETTY_FUNCTION__, journalPath, journalInDocumentsFolder);
					[[self alertWhenDataStoreMoveFails] runModal];
				}
				
				[progressIndicator210 stopAnimation:self];
				[[self window] orderOut:self];
			}
		}
			
		NSLog(@"%s - finished moving the journal out of app support at %@", __PRETTY_FUNCTION__, [NSDate date]);
	}
	
	return success;
}

- (NSAlert*) alertForMovingJournalOutOfApplicationSupport
{
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	
	[alert setMessageText:NSLocalizedStringFromTable(@"2.5.4 store move message", @"UpgradeController", @"")];
	[alert setInformativeText:NSLocalizedStringFromTable(@"2.5.4 store move info", @"UpgradeController", @"")];  
	
	[alert setDelegate:self];
	[alert setShowsHelp:YES];
	[alert setHelpAnchor:@"http://wiki.journler.com/index.php?title=Datastorage_Update"];
	
	[alert addButtonWithTitle:NSLocalizedStringFromTable(@"2.5.4 store move ok", @"UpgradeController", @"")];
	[alert addButtonWithTitle:NSLocalizedStringFromTable(@"2.5.4 store move cancel", @"UpgradeController", @"")];
	
	return alert;
}

- (NSAlert*) alertWhenFolderNamedJournalAlreadyExistsInLibrary
{
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	
	[alert setMessageText:NSLocalizedStringFromTable(@"2.5.4 store already in library message", @"UpgradeController", @"")];
	[alert setInformativeText:NSLocalizedStringFromTable(@"2.5.4 store already in library info", @"UpgradeController", @"")];  
	
	[alert setDelegate:self];
	[alert setShowsHelp:YES];
	[alert setHelpAnchor:@"http://wiki.journler.com/index.php?title=Datastorage_Update"];
	
	[alert addButtonWithTitle:NSLocalizedStringFromTable(@"2.5.4 store already in library quit", @"UpgradeController", @"")];
	
	return alert;
}

- (NSAlert*) alertWhenDataStoreMoveSucceeds
{
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	
	[alert setMessageText:NSLocalizedStringFromTable(@"2.5.4 store moved successfully message", @"UpgradeController", @"")];
	[alert setInformativeText:NSLocalizedStringFromTable(@"2.5.4 store moved successfully info", @"UpgradeController", @"")];  
	[alert addButtonWithTitle:NSLocalizedStringFromTable(@"2.5.4 store moved successfully ok", @"UpgradeController", @"")];
	
	return alert;
}

- (NSAlert*) alertWhenDataStoreMoveFails
{
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	
	[alert setMessageText:NSLocalizedStringFromTable(@"2.5.4 store moved failure message", @"UpgradeController", @"")];
	[alert setInformativeText:NSLocalizedStringFromTable(@"2.5.4 store moved failure info", @"UpgradeController", @"")];  
	
	[alert setDelegate:self];
	[alert setShowsHelp:YES];
	[alert setHelpAnchor:@"http://wiki.journler.com/index.php?title=Datastorage_Update"];
	
	[alert addButtonWithTitle:NSLocalizedStringFromTable(@"2.5.4 store moved failure ok", @"UpgradeController", @"")];
	
	return alert;
}

- (BOOL)alertShowHelp:(NSAlert *)alert
{
	if ( [[alert helpAnchor] isEqualToString:@"http://wiki.journler.com/index.php?title=Datastorage_Update"] )
	{
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://wiki.journler.com/index.php?title=Datastorage_Update"]];
		return YES;
	}
	else
	{
		return NO;
	}
}

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

#pragma mark -
#pragma mark File Manager Delegation

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error 
   movingItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath
{
	NSString *errorString;
	NSString *localizedDescription = [error localizedDescription];
	if ( localizedDescription != nil )
		errorString = [NSString stringWithFormat:@"****\n%s - Encountered file manager error: %@\n****\n", __PRETTY_FUNCTION__, localizedDescription];
	else
		errorString = [NSString stringWithFormat:@"****\n%s - Encountered file manager error: no description\n****\n", __PRETTY_FUNCTION__];
	
	if ( upgradeMode == 0 ) [log117 appendString:errorString];
	else if ( upgradeMode == 1 ) [log210 appendString:errorString];
	else NSLog(@"%@",errorString);
	
	return NO;
}


- (BOOL)fileManager:(NSFileManager *)manager shouldProceedAfterError:(NSDictionary *)errorInfo 
{
	// log the error and return no
	NSString *errorString = [NSString stringWithFormat:@"****\n%s - Encountered file manager error: %@\n****\n", __PRETTY_FUNCTION__, errorInfo];
	
	if ( upgradeMode == 0 ) [log117 appendString:errorString];
	else if ( upgradeMode == 1 ) [log210 appendString:errorString];
	else NSLog(@"%@",errorString);
	
	return NO;
}

@end
