#import "JournlerJournal.h"
#import "JournlerEntry.h"
#import "JournlerCollection.h"
#import "JournlerResource.h"
#import "BlogPref.h";
#import "JournlerSearchManager.h"
#import "JournlerIndexServer.h"

#import <SproutedUtilities/SproutedUtilities.h>
#import "NSURL+JournlerAdditions.h"

#import "PDSingletons.h"
#import "Definitions.h"

#import "JournalUpgradeController.h"

//#import "NSString+PDStringAdditions.h"
//#import "NSArray_PDAdditions.h"
//#import "AGKeychain.h"

//#import "JournlerApplicationDelegate.h"

@implementation JournlerJournal

// ============================================================
// Birth and Death
// ============================================================

+ (JournlerJournal*) sharedJournal 
{
    static JournlerJournal *sharedJournal = nil;
    if (!sharedJournal) 
	{
        sharedJournal = [[JournlerJournal allocWithZone:NULL] init];
    }

    return sharedJournal;
}

+ (JournlerJournal*) defaultJournal:(NSError**)error
{
	int jError = 0;
	JournalLoadFlag loadResult;
	NSString *defaultPath = [JournlerJournal defaultJournalPath];
	
	// estalish the shared journal
	JournlerJournal *aJournal = [JournlerJournal sharedJournal];
	
	// and load the journal
	loadResult = [aJournal loadFromPath:defaultPath error:&jError];
	
	// do error checking and all that good stuff
	return aJournal;
}

+ (NSString*) defaultJournalPath
{
	NSDictionary *journlerDefaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.phildow.jourlner"];
	if ( journlerDefaults == nil )
		return nil;
	
	NSString *defaultPath = [[journlerDefaults objectForKey:@"Default Journal Location"] stringByStandardizingPath];
	return defaultPath;
}

- (id) init {
	
	//
	// Designated initializer
	// - ensures that required variables are at least initialized
	//
	
	if ( self = [super init] ) {
		
		//CSSM_RETURN			crtn;
		
		//
		// v1.0.2 and v1.0.3 implementation
		_journalPath =	[[NSString alloc] init];
		
		_properties =	[[NSMutableDictionary alloc] init];
		
		_entries = [[NSMutableArray allocWithZone:[self zone]] init];
		_collections = [[NSMutableArray allocWithZone:[self zone]] init];
		_blogs = [[NSMutableArray allocWithZone:[self zone]] init];
		resources = [[NSMutableArray alloc] init];
				
		_rootCollection = [[JournlerCollection alloc] init];
		
		//
		// dictionaries for quick access
		_entriesDic = [[NSMutableDictionary allocWithZone:[self zone]] init];
		_collectionsDic = [[NSMutableDictionary allocWithZone:[self zone]] init];
		_blogsDic = [[NSMutableDictionary allocWithZone:[self zone]] init];
		resourcesDic = [[NSMutableDictionary alloc] init];
		
		entryWikis = [[NSMutableDictionary alloc] init];
		entryTags = [[NSMutableSet alloc] init];
		
		// the search manager belongs to the journal
		searchManager = [[JournlerSearchManager alloc] initWithJournal:self];
		
		// the index server needs the search manager
		indexServer = [[JournlerIndexServer alloc] initWithSearchManager:searchManager];
		
		_do_not_index_and_collect = NO;
		saveEntryOptions = kEntrySaveIndexAndCollect;
		
		//
		// by default no encryption
		password =		nil;
		_keySchonGenerated = NO;
		
		[self setValue:[NSNumber numberWithBool:NO] forKey:@"encrypted"];
		
		lastTag	=		0;
		lastFolderTag = 0;
		lastBlogTag = 0;
		lastResourceTag = 0;

		error =			0;
		
		initErrors = [[NSMutableArray alloc] init];
		activity = [[NSMutableString alloc] init];
		
		//
		// open up communication with the encryption mechanism
		/*
		crtn = cdsaCspAttach(&_cspHandle);
		if ( crtn ) {
			NSLog(@"Unable to connect to cdsa encryption mechanism");
		}
		*/
		
		_loaded = NO;
		
	}
	return self;
}

- (void) dealloc 
{
	[entryWikis release], entryWikis = nil;
	[entryTags release], entryTags = nil;
	
	// 1.0.2 changes ------------------
	[_journalPath release], _journalPath = nil;
	[_properties release], _properties = nil;
		
	// 1.0.3 changes
	[_entries release], _entries = nil;
	[_collections release], _collections = nil;
	
	[_entriesDic release], _entriesDic = nil;
	[_collectionsDic release], _collectionsDic = nil;
	
	[resources release], resources = nil;
	[resourcesDic release], resourcesDic = nil;
	
	[_blogs release], _blogs = nil;
	[_blogsDic release], _blogsDic = nil;
	
	[searchManager release], searchManager = nil;
	[indexServer release], indexServer = nil;
	
	[dirty release], dirty = nil;
	[initErrors release], initErrors = nil;
	[activity release], activity = nil;
	
	[contentMemoryManagerTimer invalidate];
	[contentMemoryManagerTimer release], contentMemoryManagerTimer = nil;
	
	// encryption
	//if ( _keySchonGenerated ) cdsaFreeKey(_cspHandle, &_generatedKey);
	//cdsaCspDetach(_cspHandle);
	
	// and deregister ourselves from the notification center
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

#pragma mark -

- (NSNumber*) dirty
{
	return dirty;
}

- (void) setDirty:(NSNumber*)aNumber
{
	if ( ![dirty isEqualToNumber:aNumber] )
	{
		[dirty release];
		dirty = [aNumber retain];
	}
}

- (NSNumber*) version 
{ 
	return [_properties objectForKey:PDJournalVersion]; 
}

- (void) setVersion:(NSNumber*)newVersion 
{
	// IS THIS SUPPOSED TO BE 120?
	[_properties setObject:(newVersion?newVersion:[NSNumber numberWithInt:120]) forKey:PDJournalVersion];
}

- (NSNumber*) shutDownProperly
{
	return [_properties objectForKey:PDJournalProperShutDown]; 
}	

- (void) setShutDownProperly:(NSNumber*)aNumber
{
	[_properties setObject:(aNumber?aNumber:[NSNumber numberWithBool:NO]) forKey:PDJournalProperShutDown];
}

- (NSNumber*) identifier 
{ 
	return [_properties objectForKey:PDJournalIdentifier]; 
}

- (void) setIdentifier:(NSNumber*)jid 
{
	[_properties setObject:(jid?jid:[NSNumber numberWithDouble:0]) forKey:PDJournalIdentifier];
}

// DEPRECATED
- (NSNumber*) encrypted
{
	return [_properties objectForKey:PDJournalEncrypted];
}

// DEPRECATED
- (void) setEncrypted:(NSNumber*)aNumber
{
	[_properties setObject:( aNumber ? aNumber : [NSNumber numberWithBool:NO] ) forKey:PDJournalEncrypted];
}

// DEPRECATED
- (NSNumber*) encryptionState 
{ 
	return [_properties objectForKey:PDJournalEncryptionState]; 
}

// DEPRECATED
- (void) setEncryptionState:(NSNumber*)state 
{
	[_properties setObject:( state ? state : [NSNumber numberWithInt:PDEncryptionNone] ) forKey:PDJournalEncryptionState];
}

- (NSData*) tabState
{
	return [_properties objectForKey:PDJournalMainWindowState];
}

- (void) setTabState:(NSData*)data
{
	[_properties setObject:( data ? data : [NSData data] ) forKey:PDJournalMainWindowState];
}

#pragma mark -

- (int) error { return error; }

- (void) setError:(int)err {
	error = err;
}

#pragma mark -


- (NSArray*) entries 
{
	return _entries; 
}

- (void) setEntries:(NSArray*)newEntries 
{
	if ( _entries != newEntries ) 
	{
		[_entries release];
		_entries = [newEntries mutableCopyWithZone:[self zone]];
	}
}

- (NSArray*) resources
{
	return resources;
}

- (void) setResources:(NSArray*)newResources
{
	if ( resources != newResources ) 
	{
		[resources release];
		resources = [newResources mutableCopyWithZone:[self zone]];
	}
}

- (NSArray*) collections 
{ 
	return _collections; 
}

- (void) setCollections:(NSArray*)newCollections 
{
	if ( _collections != newCollections ) 
	{
		[_collections release];
		_collections = [newCollections mutableCopyWithZone:[self zone]];
	}
}

- (NSArray*) blogs { 
	return _blogs; 
}

- (void) setBlogs:(NSArray*)newObject 
{
	if ( _blogs != newObject ) 
	{
		[_blogs release];
		_blogs = [newObject copyWithZone:[self zone]];
	}
}

#pragma mark -


- (NSString*) title 
{ 
	return [_properties objectForKey:PDJournalTitle]; 
}

- (void) setTitle:(NSString*)newObject 
{
	[_properties setObject:( newObject ? newObject : [NSString string] ) forKey:PDJournalTitle];
}

#pragma mark -

- (NSArray*) categories 
{ 
	return [_properties objectForKey:PDJournalCategories]; 
}

- (void) setCategories:(NSArray*)newObject 
{
	[_properties setObject:( newObject ? newObject : [NSArray array] ) forKey:PDJournalCategories];
}

#pragma mark -

- (NSDictionary*) properties 
{ 
	return _properties; 
}

- (void) setProperties:(NSDictionary*)newObject 
{
	if ( _properties != newObject ) 
	{
		[_properties release];
		_properties = [newObject mutableCopyWithZone:[self zone]];
	}
}

#pragma mark -

- (NSString*) journalPath 
{ 
	return _journalPath; 
}

- (void) setJournalPath:(NSString*)newObject 
{
	if ( _journalPath != newObject ) 
	{
		[_journalPath release];
		_journalPath = [newObject copyWithZone:[self zone]];
	}
}

#pragma mark -

- (NSString*) activity
{
	return activity;
}

- (void) setActivity:(NSString*)aString
{
	if ( activity != aString )
	{
		[activity release];
		activity = [aString mutableCopyWithZone:[self zone]];
	}
}

- (NSArray*) initErrors
{
	return initErrors;
}

#pragma mark -

- (BOOL) isLoaded 
{ 
	return _loaded; 
}

- (void) setLoaded:(BOOL)loaded
{
	_loaded = loaded;
}

- (JournlerSearchManager*)searchManager 
{ 
	return searchManager; 
}

- (JournlerIndexServer*) indexServer
{
	return indexServer;
}

#pragma mark -

- (id) objectForURIRepresentation:(NSURL*)aURL
{
	id object = nil;
	
	NSString *abs = [aURL absoluteString];
	NSString *tagID = [abs lastPathComponent];
	NSString *objectType = [[abs stringByDeletingLastPathComponent] lastPathComponent];
	
	if ( [objectType isEqualToString:@"entry"] )
		object = [_entriesDic objectForKey:[NSNumber numberWithInt:[tagID intValue]]];
	else if ( [objectType isEqualToString:@"reference"] )
		object = [resourcesDic objectForKey:[NSNumber numberWithInt:[tagID intValue]]];
	else if ( [objectType isEqualToString:@"folder"] )
		object = [_collectionsDic objectForKey:[NSNumber numberWithInt:[tagID intValue]]];
	else if ( [objectType isEqualToString:@"blog"] )
		object = [_blogsDic objectForKey:[NSNumber numberWithInt:[tagID intValue]]];
	
	return object;
}

- (BlogPref*) blogForTagID:(NSNumber*)tagNumber 
{
	return ( tagNumber != nil ? [_blogsDic objectForKey:tagNumber] : nil );
}

- (JournlerEntry*) entryForTagString:(NSString*)tagString 
{
	return [self entryForTagID:[NSNumber numberWithInt:[tagString intValue]]];
}


- (JournlerEntry*) entryForTagID:(NSNumber*)tagNumber 
{
	return ( tagNumber != nil ? [_entriesDic objectForKey:tagNumber] : nil );
}

- (NSArray*) entriesForTagIDs:(NSArray*)tagIDs 
{	
	// utility for turning an array of entry ids into the entries themselves
	
	int i;
	NSMutableArray *theEntries = [[NSMutableArray alloc] initWithCapacity:[tagIDs count]];
	for ( i = 0; i < [tagIDs count]; i++ ) {
		id anEntry = [_entriesDic objectForKey:[tagIDs objectAtIndex:i]];
		if ( anEntry != nil ) [theEntries addObject:anEntry];
	}
	
	return [theEntries autorelease];
	
}

- (NSArray*) resourcesForTagIDs:(NSArray*)tagIDs
{
	// utility for turning an array of entry ids into the entries themselves
	
	int i;
	NSMutableArray *theResources = [[NSMutableArray alloc] initWithCapacity:[tagIDs count]];
	for ( i = 0; i < [tagIDs count]; i++ ) {
		id aResource = [resourcesDic objectForKey:[tagIDs objectAtIndex:i]];
		if ( aResource != nil ) [theResources addObject:aResource];
	}
	
	return [theResources autorelease];
}

- (JournlerEntry*) objectForTagString:(NSString*)tagString 
{	
	//
	// Takes an unparsed tag string, determines whether we're dealing with an entry or topic,
	// and sends the request to the appropriate tag string searcher
	
	NSArray *components = [tagString componentsSeparatedByString:@";"];
	if ( [components count] != 2 ) return nil;
	
	if ( [[components objectAtIndex:0] isEqualToString:@"entry"] )
		return [self entryForTagString:[components objectAtIndex:1]];
	else
		return nil;
	
}

#pragma mark -

- (int) newEntryTag 
{
	return ++lastTag;
}

- (int) newFolderTag 
{
	return ++lastFolderTag;
}

- (int) newBlogTag 
{
	return ++lastBlogTag;
}

- (int) newResourceTag
{
	return ++lastResourceTag;
}

#pragma mark -
#pragma mark Loading 1.0.2 and 1.0.3 Style -> 1.2 style

- (JournalLoadFlag) loadFromPath:(NSString*)path error:(int*)err 
{	
	//
	// distinguish initialization and loading so that the journal can
	// be initialized without being loaded, and thus loaded after 
	// the password has gone through
	//
	// the loading code is a piece. 
	// upgrading should be completely distinguished from loading
	
	JournalLoadFlag loadResult = kJournalLoadedNormally;
	
	[activity appendFormat:@"Loading journal from path %@\n", path];
	
	int i;
	error = 0;
	
	BOOL dir;
	
	*err = PDJournalNoError;
		
	// Complete failure if there is no directory at this path
	// ----------------------------------------------------------
    
	if ( ![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&dir] || !dir ) {
		NSLog(@"%s - critical Error : Unable to create journal : No journal at path %@", __PRETTY_FUNCTION__, path);
		[self setError:PDNoJournalAtPath];
		*err = PDNoJournalAtPath;
		return kJournalCouldNotLoad;
	}
	
	// go ahead and set our path if a directory does in fact exist here
	[self setJournalPath:path];
	
	// Check for the existense of the journal plist file
	// ----------------------------------------------------------

	if ( ![[NSFileManager defaultManager] fileExistsAtPath:[self propertiesPath]] ) {
		
		NSLog(@"%@ %s - critical error: journal is in old format, requires 1.17 update", [self className], _cmd);
		[self setError:PDJournalFormatTooOld];
		*err = PDJournalFormatTooOld;
		return kJournalCouldNotLoad;
	}

	// Load the properties and check the version number
	// ----------------------------------------------------------

	[self setProperties:[NSDictionary dictionaryWithContentsOfFile:[self propertiesPath]]];
	if ( [self title] == nil ) [self setTitle:[NSString string]];

	int versionNumber;
	id jVersionObj = [_properties objectForKey:PDJournalVersion];
	if ( [jVersionObj isKindOfClass:[NSString class]] ) {
		NSMutableString *journalVersion = [[_properties objectForKey:PDJournalVersion] mutableCopy];
		if ( !journalVersion ) {
			NSLog(@"%@ %s - critical Error : no journal version at %@", [self className], _cmd, [self propertiesPath]);
			[self setError:PDUnreadableProperties];
			*err = PDUnreadableProperties;
			return kJournalCouldNotLoad;
		}
		
		[journalVersion replaceOccurrencesOfString:@"." withString:@"" options:NSLiteralSearch range:NSMakeRange(0,[journalVersion length])];
		versionNumber = [journalVersion intValue];
		
		[journalVersion release];
	}
	else
	{
		versionNumber = [jVersionObj intValue];
	}
	
	if ( versionNumber < 112 ) 
	{
		NSLog(@"%@ %s - critical error: journal is in old format, requires 1.17 update", [self className], _cmd);
		[self setError:PDJournalFormatTooOld];
		*err = PDJournalFormatTooOld;
		return kJournalCouldNotLoad;
	}
	
	else if ( versionNumber < 120 ) 
	{
		// the journal must be converted, but a simple enough process really		
		JournalUpgradeController *upgrader = [[JournalUpgradeController alloc] init];
		[upgrader run117To210Upgrade:self];
		[upgrader release];
		
		loadResult |= kJournalUpgraded; 
		versionNumber = 250;
	}
	
	else if ( versionNumber < 250 )
	{
		loadResult |= kJournalWantsUpgrade;
		*err |= kJournalWants250Upgrade;
	}
	
	// actually load the journal
	// ----------------------------------------------------------
	BOOL loadSuccess = YES;
	
	if ( [[NSFileManager defaultManager] fileExistsAtPath:[self storePath]] )
	{
		if ( ![[self shutDownProperly] boolValue] )
		{
			// if the journal did not properly shut down, load from the directory
			int directoryError;
			JournalLoadFlag directoryLoadResult;
			
			loadResult |= kJournalCrashed;
			directoryLoadResult = [self loadFromDirectoryIgnoringEntryFolders:NO error:&directoryError];
			
			if ( directoryLoadResult != kJournalLoadedNormally )
				loadSuccess = NO;
		}
		else
		{
			// if journler did shut down successfully, first try to load from the store
			int storeError;
			JournalLoadFlag storeLoadResult = [self loadFromStore:&storeError];
			
			// attempt to load from the directory if a store load fails
			if ( storeLoadResult != kJournalLoadedNormally )
			{
				int directoryError;
				JournalLoadFlag directoryLoadResult = [self loadFromDirectoryIgnoringEntryFolders:NO error:&directoryError];
				
				if ( directoryLoadResult != kJournalLoadedNormally )
					loadSuccess = NO;
			}
		}
	}
	else
	{
		// load only those entries that are in the 200 format, in case the user runs a failed upgrade the second time
		int directoryError;
		JournalLoadFlag directoryLoadResult = [self loadFromDirectoryIgnoringEntryFolders:( versionNumber < 210 ) error:&directoryError];
		
		if ( directoryLoadResult != kJournalLoadedNormally )
			loadSuccess = NO;
	}
	
	if ( !loadSuccess )
	{
		//#warning indicate the error
		NSLog(@"%@ %s - unable to initialize journal from path %@", [self className], _cmd, path);
		*err = PDJournalStoreAndPathFailure;
		return kJournalCouldNotLoad;
	}
		
	// set every collections parent and children - after loading only
	for ( i = 0; i < [_collections count]; i++ ) 
	{
		JournlerCollection *aNode = [_collections objectAtIndex:i];
		
		// note a few special collections
		if ( [[aNode valueForKey:@"typeID"] intValue] == PDCollectionTypeIDTrash )
			_trashCollection = aNode;
			
		else if ( [[aNode valueForKey:@"typeID"] intValue] == PDCollectionTypeIDLibrary )
			_libraryCollection = aNode;

		// set the collection's relationship to other collections
		JournlerCollection *theParent = [self collectionForID:[aNode parentID]];
		[aNode setParent:( theParent != nil ? theParent : _rootCollection )];
		[aNode setChildren:[self collectionsForIDs:[aNode childrenIDs]]];
		
		// autosort the collections's children by their index value
		[aNode sortChildrenByIndex];
		
		// add the root collections to the root node
		if ( [aNode parent] == _rootCollection )
			[_rootCollection addChild:aNode];
	}
	
	// look for children attached to parents who have lost them and add them to the root folder
	for ( i = 0; i < [_collections count]; i++ ) 
	{
		JournlerCollection *aNode = [_collections objectAtIndex:i];
		JournlerCollection *theParent = [aNode parent];
		
		if ( theParent == _rootCollection )
			continue;
		
		NSArray *parentsChildren = [theParent children];
		if ( ![parentsChildren containsObject:aNode] )
		{
			[activity appendFormat:@"Attaching lost folder to root list, title: %@, ID: %@\n", [aNode valueForKey:@"title"], [aNode valueForKey:@"tagID"]];
			[_rootCollection addChild:aNode];
		}
	}
	
	// make sure we have a trash collection and library collection
	if ( _libraryCollection == nil ) 
	{
		// prepare the journal collection
		JournlerCollection *journal_collection;
		NSString *journal_collection_path = [[NSBundle mainBundle] pathForResource:@"JournalCollection" ofType:@"xml"];
		NSMutableDictionary *journal_collection_dic = [NSMutableDictionary dictionaryWithContentsOfFile:journal_collection_path];
	
		journal_collection = [[JournlerCollection alloc] initWithProperties:journal_collection_dic];
		if ( !journal_collection ) NSLog(@"%@ %s - could not create the journal collection", [self className], _cmd);
	
		// set the image on the journal dictionary
		[journal_collection determineIcon];
		
		// set the id
		[journal_collection setValue:[NSNumber numberWithInt:[self newFolderTag]] forKey:@"tagID"];
		
		// the position and parent
		[journal_collection setValue:[NSNumber numberWithInt:0] forKey:@"index"];
		[journal_collection setParentID:[NSNumber numberWithInt:-1]];
		[journal_collection setParent:_rootCollection];
		
		// add it and clean up
		[_rootCollection addChild:journal_collection atIndex:0];
		[_collections addObject:journal_collection];
		
		_libraryCollection = journal_collection;
		[self writeJournalCollection:_libraryCollection];
		[journal_collection release];

	}
	
	if ( _trashCollection == nil ) 
	{
		// prepare the trash collection - collection tutorials
		JournlerCollection *trash_collection;
		NSString *trash_collection_path = [[NSBundle mainBundle] pathForResource:@"TrashCollection" ofType:@"xml"];
		NSMutableDictionary *trash_collection_dic = [NSMutableDictionary dictionaryWithContentsOfFile:trash_collection_path];
		
		trash_collection = [[JournlerCollection alloc] initWithProperties:trash_collection_dic];
		if ( !trash_collection ) NSLog(@"%@ %s - could not create the trash collection", [self className], _cmd);
		
		// set the image and title the tutorial dictionary
		[trash_collection determineIcon];
		[trash_collection setTitle:NSLocalizedString(@"collection trash title",@"")];
		
		// set the id
		[trash_collection setValue:[NSNumber numberWithInt:[self newFolderTag]] forKey:@"tagID"];
		
		// the position and parent
		[trash_collection setValue:[NSNumber numberWithInt:1] forKey:@"index"];
		[trash_collection setParentID:[NSNumber numberWithInt:-1]];
		[trash_collection setParent:_rootCollection];
		
		// add it and clean up
		[_rootCollection addChild:trash_collection atIndex:1];
		[_collections addObject:trash_collection];
		
		_trashCollection = trash_collection;
		[self writeJournalCollection:_trashCollection];
		[trash_collection release];
	}
	
	// sort the root node
	[_rootCollection sortChildrenByIndex];
	
	int foo;
	NSMutableArray *entriesTrashed = [NSMutableArray array];
	NSMutableArray *entriesNotTrashed = [NSMutableArray array];
	
	// trash/untrash entries and re-establish the relationship between the entry resources and the journal
	for ( foo = 0; foo < [_entries count]; foo++ ) {
		
		int g;
		JournlerEntry *anEntry = [_entries objectAtIndex:foo];
		
		// establish the entry -> resource relationships depending on version number
		
		if ( [[self version] intValue] < 250)
		{
			NSArray *entryResources = [anEntry valueForKey:@"resources"];
			[entryResources setValue:self forKey:@"journal"];
					
			[resources addObjectsFromArray:entryResources];
			for ( g = 0; g < [entryResources count]; g++ )
			{
				[resourcesDic setObject:[entryResources objectAtIndex:g] forKey:[[entryResources objectAtIndex:g] valueForKey:@"tagID"]];
				
				if ( [[[entryResources objectAtIndex:g] valueForKey:@"tagID"] intValue] > lastResourceTag )
					lastResourceTag = [[[entryResources objectAtIndex:g] valueForKey:@"tagID"] intValue];
			}
		}
		
		else
		{
			NSArray *theResourceIDs = [anEntry resourceIDs];
			NSArray *theResources = [self resourcesForTagIDs:theResourceIDs];
			
			JournlerResource *lastResourceSelection = nil;
			NSNumber *lastResourceSelectionID = [anEntry lastResourceSelectionID];
			if ( lastResourceSelectionID != nil ) lastResourceSelection = [resourcesDic objectForKey:lastResourceSelectionID];
			
			//#ifdef __DEBUG__
			//NSLog(@"Entry %@ has Resources %@", [anEntry tagID], [theResourceIDs componentsJoinedByString:@","]);
			//#endif
			
			// estalish the entry -> resources relationship
			[anEntry setResources:theResources];
			
			// establish the entry -> selected resource relationship
			[anEntry setSelectedResource:lastResourceSelection];
			
			// nil out those relational load values to release them
			[anEntry setResourceIDs:nil];
			[anEntry setLastResourceSelectionID:nil];
		}
		
		// the entry belongs in the library or the trash
		if ( [[anEntry valueForKey:@"markedForTrash"] boolValue] )
			[entriesTrashed addObject:anEntry];
		else
			[entriesNotTrashed addObject:anEntry];
		
		// add the entry to the wiki dictionary
		NSString *wikiTitle = [anEntry wikiTitle];
		if ( wikiTitle != nil )
			[entryWikis setValue:[anEntry URIRepresentation] forKey:wikiTitle];
	}
	
	// go through the resources and establish the resource -> entry relationships as well as the owner
	
	JournlerResource *aResource;
	NSEnumerator *resourceEnumerator = [resources objectEnumerator];
	
	while ( aResource = [resourceEnumerator nextObject] )
	{
		// establish the resource -> entry relationship for each resource here
		NSNumber *owningEntryID = [aResource owningEntryID];
		NSArray *theEntryIDs = [aResource entryIDs];
		
		JournlerEntry *theOwningEntry = [_entriesDic objectForKey:owningEntryID];
		NSArray *allAssociatedEntries = [self entriesForTagIDs:theEntryIDs];
		
		#ifdef __DEBUG_
		NSLog(@"Resource %@ is owned by %@ has Entries %@", [aResource tagID], owningEntryID, [theEntryIDs componentsJoinedByString:@","]);
		#endif
		
		// establish the resource -> owning entry relationship
		[aResource setEntry:theOwningEntry];
		
		// establish the resource -> entries relationship
		[aResource setEntries:allAssociatedEntries];
		
		// nil out the relational load values
		[aResource setOwningEntryID:nil];
		[aResource setEntryIDs:nil];
		
		// once the relatinoships are established, make sure the resource does in fact have an owning entry
		if ( theOwningEntry == nil )
		{
			// this is a stray resource, associate it with a document, preferably one of the entries it already belongs to
			JournlerEntry *bestOwner = [self bestOwnerForResource:aResource];
			if ( bestOwner == nil )
			{
				// #warning attach stray resources to a dedicated entry
				// note the problem to the activity log
				[activity appendFormat:@"** Permanently lost resource, cannot find any associated entries...\n\t-- Name: %@\n\t-- ID: %@\n", [aResource valueForKey:@"title"], [aResource valueForKey:@"tagID"]];
				if ( [aResource representsFile] ) [activity appendFormat:@"\t-- Filename: %@\n",  [aResource filename]];
			}
			else
			{
				// re-establish the entry relationship - establish the entries relationship itself
				[aResource setEntry:bestOwner];
				
				// ensure the entry contains this resource, re-establishing if necessary
				[bestOwner addResource:aResource];
				
				// note the success to the activity log
				[activity appendFormat:@"Successfully re-attached lost resource to new entry...\n\t-- Name: %@\n\t-- ID: %@\n\t-- New Parent Entry Name: %@\n\tNew Parent Entry ID: %@\n", [aResource valueForKey:@"title"], [aResource valueForKey:@"tagID"], [bestOwner valueForKey:@"title"], [bestOwner valueForKey:@"tagID"]];
				if ( [aResource representsFile] ) [activity appendFormat:@"\t-- Filename: %@\n",  [aResource filename]];
			}
			
			// try bestOwnerForResource
			// if it returns a best owner, be sure to add it to the entry's genera resources array
			
			
		}

	}

	// establish the folder <-> entry relationships and other folder properties
	NSMutableArray *dynamicallyUpdatedSmartFolders = [NSMutableArray array];
	
	for ( i = 0; i < [_collections count]; i++ ) {
		
		JournlerCollection *aNode = [_collections objectAtIndex:i];
		
		// convert the entry ids into actual entries, all entries for library
		if ( [[aNode typeID] intValue] == PDCollectionTypeIDLibrary )
			[aNode setEntries:entriesNotTrashed];
			
		// a few entries for the trash
		else if ( [[aNode typeID] intValue] == PDCollectionTypeIDTrash )
			[aNode setEntries:entriesTrashed];
			
		// the rest of the entries in their respective folders, noting the folder as well
		else
		{
			NSArray *actualEntries = [self entriesForTagIDs:[aNode entryIDs]];
			JournlerEntry *anEntry;
			NSEnumerator *entryEnumerator = [actualEntries objectEnumerator];
			
			while ( anEntry = [entryEnumerator nextObject] )
			{
				NSMutableArray *entryFolders = [[[anEntry valueForKey:@"collections"] mutableCopyWithZone:[self zone]] autorelease];
				if ( entryFolders == nil )
					entryFolders = [NSMutableArray array];
				
				if ( [entryFolders indexOfObjectIdenticalTo:aNode] == NSNotFound )
				{
					[entryFolders addObject:aNode];
					[anEntry setValue:entryFolders forKey:@"collections"];
				}
			}
			
			[aNode setEntries:actualEntries];
		}
		
		// handle dyamically generated dates and note which folders have been changed
		if ( [aNode generateDynamicDatePredicates:NO] )
		{
			[dynamicallyUpdatedSmartFolders addObject:aNode];
		}
	}
	
	// re-evaluately the entries against any dynamically updated smart folders
	// this is done only after all of the smart folders have had their dynamic date conditions updated
	for ( i = 0; i < [dynamicallyUpdatedSmartFolders count]; i++ )
	{
		[[dynamicallyUpdatedSmartFolders objectAtIndex:i] invalidatePredicate:YES];
		[[dynamicallyUpdatedSmartFolders objectAtIndex:i] evaluateAndAct:[self entries] considerChildren:YES];
	}
	
	// derive all of the available tags
	[entryTags addObjectsFromArray:[self valueForKeyPath:@"entries.@distinctUnionOfArrays.tags"]];
	//NSLog([entryTags description]);

	// Upgrade the loaded journal to the 2.10 format, only after the load!
	
	if ( versionNumber < 210 )
	{
		JournalUpgradeController *upgrader = [[JournalUpgradeController alloc] init];
		[upgrader run200To210Upgrade:self];
		[upgrader release];
		
		loadResult |= kJournalUpgraded;
	}

	
	// Prepare Journal Searching 
	// ----------------------------------------------------------

	if ( ![searchManager loadIndexAtPath:[self journalPath]] )
	{
		#warning - flags an error on locate journal that prevents the app from loading
		NSLog(@"%@ %s - Unable to get or create the search indexes", [self className], _cmd);
		*err = PDJournalNoSearchIndexError;
		loadResult |= kJournalNoSearchIndex;
	}
	else 
	{
		//#warning compact the search index
		//[searchManager compactIndex];
	}
	
	//
	// check for the existence of a journal id
	if ( ![self identifier] || [self identifier] == 0 )
		[self setIdentifier:[NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]]];
	
	// let all our object know that they have just been loaded, so they are not dirty
	NSNumber *notDirty = BooleanNumber(NO);
	
	[[self entries] setValue:notDirty forKey:@"dirty"];
	[[self collections] setValue:notDirty forKey:@"dirty"];
	[[self resources] setValue:notDirty forKey:@"dirty"];
	[self setValue:notDirty forKey:@"dirty"];
	
	_loaded = YES;
	
	// mark the journal as running for crash recovery
	[_properties setObject:[NSNumber numberWithBool:NO] forKey:PDJournalProperShutDown];
	[self saveProperties];
	
	// check for initialization errors and note them
	if ( [initErrors count] != 0 )
		loadResult |= kJournalPathInitErrors;
	
	// log the activity
	[activity appendString:@"Finished loading journal\n"];
	[self setActivity:activity];
	
	// start up the memory manager
	contentMemoryManagerTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:10*60] 
	interval:10*60 target:self selector:@selector(checkMemoryUse:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:contentMemoryManagerTimer forMode:NSDefaultRunLoopMode];
	
	// let our caller know that an update was necessary
	return loadResult;
	
}

- (JournalLoadFlag) loadFromStore:(int*)err
{	
	#ifdef __DEBUG__
	NSLog(@"%@ %s",[self className],_cmd);
	#endif
	
	int i, c;
	JournalLoadFlag storeLoadFlag = kJournalLoadedNormally;
	
	NSArray *encodedEntries = nil, *encodedBlogs = nil, *encodedCollections = nil, *encodedResources = nil;
	NSMutableArray *theEntries, *theBlogs, *theCollections, *theResources;
	
	NSDictionary *store = [NSDictionary dictionaryWithContentsOfFile:[self storePath]];
	
	if ( store == nil )
	{
		NSLog(@"%@ %s - unable to initialize store dictionary from path %@", [self className], _cmd, [self storePath]);
		return kJournalCouldNotLoad;
	}
	
	encodedEntries = [store valueForKey:@"Entries"];
	if ( encodedEntries == nil )
	{
		NSLog(@"%@ %s - store does not contain any entries", [self className], _cmd);
		return kJournalCouldNotLoad;
	}
	
	encodedBlogs = [store valueForKey:@"Blogs"];
	if ( encodedBlogs == nil )
	{
		NSLog(@"%@ %s - store does not contain any blogs", [self className], _cmd);
		return kJournalCouldNotLoad;
	}
	
	encodedCollections = [store valueForKey:@"Collections"];
	if ( encodedCollections == nil )
	{
		NSLog(@"%@ %s - store does not contain any collections", [self className], _cmd);
		return kJournalCouldNotLoad;
	}
	
	if ( [[self version] intValue] >= 250 )
	{
		encodedResources = [store valueForKey:@"Resources"];
		if ( encodedResources == nil )
		{
			NSLog(@"%@ %s - store does not contain any resources", [self className], _cmd);
			return kJournalCouldNotLoad;
		}
	}
	
	// DECODE THE ENTRIES
	c = 0;
	theEntries = [NSMutableArray arrayWithCapacity:[encodedEntries count]];
	for ( i = 0; i < [encodedEntries count]; i++ )
	{
		JournlerEntry *anEntry = nil;
		NSDictionary *entryDict = [encodedEntries objectAtIndex:i];
		NSData *rawData = [entryDict objectForKey:@"Data"]; 
		
		if ( rawData == nil )
		{
			NSLog(@"%@ %s - no data for entry %i in store", [self className], _cmd, i);
			continue;
		}
		
		@try
		{
			anEntry = [NSKeyedUnarchiver unarchiveObjectWithData:rawData];
		}
		@catch (NSException *localException)
		{
			anEntry = nil;
			NSLog(@"%@ %s - unable to unarchive entry %i in store, exception %@", [self className], _cmd, i, localException);
			[initErrors addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:0], @"objectType",
					[NSString stringWithFormat:@"Entry %i in Store", i], @"errorString",
					localException, @"localException", nil]];
		}
		@finally
		{
			if ( anEntry == nil )
			{
				NSLog(@"%@ %s - error unarchiving entry %i in store", [self className], _cmd, i);
				continue;
			}
			else
			{
				[anEntry setScriptContainer:owner];
				[anEntry setValue:self forKey:@"journal"];
				
				// add it to the dictionary
				[_entriesDic setObject:anEntry forKey:[anEntry tagID]];
				
				// add it to the temporary array
				[theEntries addObject:anEntry];
				
				// increment the tag and count
				c++;
				if ( lastTag < [[anEntry tagID] intValue] )
					lastTag = [[anEntry tagID] intValue];
			}
		}
	}
	
	//  set our entries array and numbers
	[self setEntries:theEntries];
	
	// DECODE THE FOLDERS
	c = 0;
	theCollections = [NSMutableArray arrayWithCapacity:[encodedCollections count]];
	for ( i = 0; i < [encodedCollections count]; i++ )
	{
		JournlerCollection *aCollection = nil;
		NSData *collectionData = [encodedCollections objectAtIndex:i];
		
		@try
		{
			aCollection = [NSKeyedUnarchiver unarchiveObjectWithData:collectionData];
		}
		@catch (NSException *localException)
		{
			aCollection = nil;
			NSLog(@"%@ %s - unable to unarchive folder %i in store, exception %@", [self className], _cmd, i, localException);
			[initErrors addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:1], @"objectType",
					[NSString stringWithFormat:@"Folder %i in Store", i], @"errorString",
					localException, @"localException", nil]];
		}
		@finally
		{
			if ( aCollection == nil )
			{
				NSLog(@"%@ %s - error unarchiving collection %i in store", [self className], _cmd, i);
				continue;
			}
			else
			{
				[aCollection setScriptContainer:owner];
				[aCollection setValue:self forKey:@"journal"];
				
				// add the collection to the collections dictionary
				[_collectionsDic setObject:aCollection forKey:[aCollection tagID]];
				
				// add the collection to the temp collections array
				[theCollections addObject:aCollection];
					
				// update last tag and count
				c++;
				if ( lastFolderTag  < [[aCollection tagID] intValue] )
					lastFolderTag = [[aCollection tagID] intValue];
			}
		}
	}
	
	// set the collections array and number
	NSSortDescriptor *childSort = [[[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES selector:@selector(compare:)] autorelease];
	[self setCollections:[theCollections sortedArrayUsingDescriptors:[NSArray arrayWithObject:childSort]]];
	
	// DECODE THE RESOURCES
	if ( [[self version] intValue] >= 250 )
	{
		c = 0;
		theResources = [NSMutableArray arrayWithCapacity:[encodedResources count]];
		for ( i = 0; i < [encodedResources count]; i++ )
		{
			JournlerResource *aResource = nil;
			NSData *resourceData = [encodedResources objectAtIndex:i];
			
			if ( resourceData == nil )
			{
				NSLog(@"%@ %s - no data for resource %i in store", [self className], _cmd, i);
				continue;
			}
			
			@try
			{
				aResource = [NSKeyedUnarchiver unarchiveObjectWithData:resourceData];
			}
			@catch (NSException *localException)
			{
				aResource = nil;
				NSLog(@"%@ %s - unable to unarchive resource %i in store, exception %@", [self className], _cmd, i, localException);
				[initErrors addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						[NSNumber numberWithInt:3], @"objectType",
						[NSString stringWithFormat:@"Resource %i in Store", i], @"errorString",
						localException, @"localException", nil]];
			}
			@finally
			{
				if ( aResource == nil )
				{
					NSLog(@"%@ %s - error unarchiving resource %i in store", [self className], _cmd, i);
					continue;
				}
				else
				{
					[aResource setScriptContainer:owner];
					[aResource setValue:self forKey:@"journal"];
					
					// add it to the dictionary
					[resourcesDic setObject:aResource forKey:[aResource tagID]];
					
					// add it to the temporary array
					[theResources addObject:aResource];
					
					// increment the tag and count
					c++;
					if ( lastResourceTag < [[aResource tagID] intValue] )
						lastResourceTag = [[aResource tagID] intValue];
				}
			}
		}
		
		[self setResources:theResources];
	}
	
	// DECODE THE BLOGS
	c = 0;
	theBlogs = [NSMutableArray arrayWithCapacity:[encodedBlogs count]];
	for ( i = 0; i < [encodedBlogs count]; i++ )
	{
		BlogPref *aBlog = nil;
		NSData *blogData = [encodedBlogs objectAtIndex:i];
		
		@try
		{
			aBlog = [NSKeyedUnarchiver unarchiveObjectWithData:blogData];
		}
		@catch (NSException *localException)
		{
			aBlog = nil;
			NSLog(@"%@ %s - unable to unarchive blog %i in store, exception %@", [self className], _cmd, i, localException);
			[initErrors addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:2], @"objectType",
					[NSString stringWithFormat:@"Blog %i in Store", i], @"errorString",
					localException, @"localException", nil]];
		}
		@finally
		{
			if ( aBlog == nil )
			{
				NSLog(@"%@ %s - error unarchiving blog %i in store", [self className], _cmd, i);
				continue;
			}
			else
			{
				//[aBlog setMyContainer:owner];
				//[aBlog setValue:self forKey:@"theJournal"];
				[aBlog setValue:self forKey:@"journal"];
				
				// load the password for the blog from the keychain
				NSString *keychainUserName = [NSString stringWithFormat:@"%@-%@-%@", [aBlog blogType], [aBlog name], [aBlog login]];
			
				if ( [AGKeychain checkForExistanceOfKeychainItem:@"NameJournlerKey" 
						withItemKind:@"BlogPassword" forUsername:keychainUserName] ) 
				{
					//set the password
					NSString *blog_password = [AGKeychain getPasswordFromKeychainItem:@"NameJournlerKey" 
							withItemKind:@"BlogPassword" forUsername:keychainUserName];
							
					[aBlog setPassword:blog_password];
				}
				
				// the temp array
				[theBlogs addObject:aBlog];
				
				// the dictionary
				[_blogsDic setObject:aBlog forKey:[aBlog tagID]];
				
				// last count
				c++;
				if ( lastBlogTag < [[aBlog valueForKey:@"tagID"] intValue] )
					lastBlogTag = [[aBlog valueForKey:@"tagID"] intValue];	
			}
		}
	}
	
	// set the blogs array
	[self setBlogs:theBlogs];
	
	
	return storeLoadFlag;
}

- (JournalLoadFlag) loadFromDirectoryIgnoringEntryFolders:(BOOL)ignore210Entries error:(int*)err
{
		
	#ifdef __DEBUG__
	NSLog(@"%@ %s",[self className],_cmd);
	#endif
	
	int c;
	JournalLoadFlag directoryLoadFlag = kJournalLoadedNormally;
	
	NSString *pname;
	NSMutableArray *tempEntries = [[[NSMutableArray alloc] init] autorelease];
	NSMutableArray *tempCollections = [[[NSMutableArray alloc] init] autorelease];
	NSMutableArray *tempBlogs = [[[NSMutableArray alloc] init] autorelease];
	NSMutableArray *tempResources = [[[NSMutableArray alloc] init] autorelease];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	
	NSEnumerator *contentsEnumerator;
	
	// LOAD THE BLOGS
	contentsEnumerator = [[fm directoryContentsAtPath:[self blogsPath]] objectEnumerator];

	c = 0;
	while ( pname = [contentsEnumerator nextObject] ) 
	{
		if ( [[pname pathExtension] isEqualToString:@"jblog"] ) 
		{
			BlogPref *aBlog = [self unarchiveBlogAtPath:[[self blogsPath] stringByAppendingPathComponent:pname]];
			if ( aBlog != nil ) 
			{
				
				// scriptability
				//[aBlog setMyContainer:owner];
				
				//[aBlog setValue:self forKey:@"theJournal"];
				[aBlog setValue:self forKey:@"journal"];
				
				// load the password for the blog from the keychain
				NSString *keychainUserName = [NSString stringWithFormat:@"%@-%@-%@", [aBlog blogType], [aBlog name], [aBlog login]];
			
				if ( [AGKeychain checkForExistanceOfKeychainItem:@"NameJournlerKey" 
						withItemKind:@"BlogPassword" forUsername:keychainUserName] ) 
				{
					//set the password
					NSString *blog_password = [AGKeychain getPasswordFromKeychainItem:@"NameJournlerKey" 
							withItemKind:@"BlogPassword" forUsername:keychainUserName];
					[aBlog setPassword:blog_password];
				
				}
				
				// the temp array
				[tempBlogs addObject:aBlog];
				
				// the dictionary
				[_blogsDic setObject:aBlog forKey:[aBlog tagID]];
				
				// last count
				if ( lastBlogTag < [[aBlog valueForKey:@"tagID"] intValue] )
					lastBlogTag = [[aBlog valueForKey:@"tagID"] intValue];
				
				c++;
				
			}
			else 
			{
				NSLog(@"%@ %s - Unable to read blog at path %@", [self className], _cmd, [[self blogsPath] stringByAppendingPathComponent:pname]);
			}
		}
	}
	
	[self setBlogs:tempBlogs];
	
	// LOAD THE ENTRIES
	contentsEnumerator = [[fm directoryContentsAtPath:[self entriesPath]] objectEnumerator];
	
	c = 0;
	while ( pname = [contentsEnumerator nextObject] ) 
	{
		if ([[pname pathExtension] isEqualToString:@"jentry"]) 
		{
			// load an entry in the 2.0 data format
			JournlerEntry *readEntry = [self unpackageEntryAtPath:[[self entriesPath] stringByAppendingPathComponent:pname]];
			if ( readEntry != nil) 
			{
				// Scriptability and journal relationship
				[readEntry setScriptContainer:owner];
				[readEntry setValue:self forKey:@"journal"];

				// add it to the temp array
				[tempEntries addObject:readEntry];

				// add it to the dictionary
				[_entriesDic setObject:readEntry forKey:[readEntry tagID]];

				// increment the tag and count
				if ( lastTag < [[readEntry tagID] intValue] )
				lastTag = [[readEntry tagID] intValue];

				c++;
			}
			else 
			{
				NSLog(@"%@ %s - Unable to load entry at path %@", [self className], _cmd, [[self entriesPath] stringByAppendingPathComponent:pname]);
			}
		}
		
		else if ( ignore210Entries == NO && [pname rangeOfString:@"Entry"].location != NSNotFound )
		{
			// load an entry in the 2.1 format
			
			JournlerEntry *readEntry = nil;
			
			NSString *propertiesPath;
			NSArray *propertiesPossibilities = [[fm directoryContentsAtPath:[[self entriesPath] stringByAppendingPathComponent:pname]] 
					pathsMatchingExtensions:[NSArray arrayWithObject:@"jobj"]];
					
			if ( [propertiesPossibilities count] == 1 )
				propertiesPath = [[[self entriesPath] stringByAppendingPathComponent:pname] stringByAppendingPathComponent:[propertiesPossibilities objectAtIndex:0]];
			else
				propertiesPath = [[[self entriesPath] stringByAppendingPathComponent:pname] stringByAppendingPathComponent:PDEntryPackageEntryContents];
			
			@try
			{
				readEntry = [NSKeyedUnarchiver unarchiveObjectWithFile:propertiesPath];
			}
			@catch (NSException *localException)
			{
				readEntry = nil;
				NSLog(@"%@ %s - unable to unarchive entry at path %@, exception %@", [self className], _cmd, [[self entriesPath] stringByAppendingPathComponent:pname], localException);
				[initErrors addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						[NSNumber numberWithInt:0], @"objectType",
						[[self entriesPath] stringByAppendingPathComponent:pname], @"errorString",
						localException, @"localException", nil]];
			}
			@finally
			{
				if ( readEntry != nil) 
				{
					// Scriptability and journal relationship
					[readEntry setScriptContainer:owner];
					[readEntry setValue:self forKey:@"journal"];

					// add it to the temp array
					[tempEntries addObject:readEntry];

					// add it to the dictionary
					[_entriesDic setObject:readEntry forKey:[readEntry tagID]];

					// increment the tag and count
					if ( lastTag < [[readEntry tagID] intValue] )
					lastTag = [[readEntry tagID] intValue];

					c++;
				}
				else 
				{
					NSLog(@"%@ %s - Unable to load entry at path %@", [self className], _cmd, [[self entriesPath] stringByAppendingPathComponent:pname]);
					readEntry = nil;
				}
			}
		}
	}

	//  set our entries array and numbers
	[self setEntries:tempEntries];
	
	
	// handle collections for 1.2 - the root node
	// ----------------------------------------------------------	
	contentsEnumerator = [[fm directoryContentsAtPath:[self collectionsPath]] objectEnumerator];
	
	c = 0;
	while ( pname = [contentsEnumerator nextObject] ) 
	{
		if ([[pname pathExtension] isEqualToString:@"jcol"]) 
		{
			JournlerCollection *aNode = (JournlerCollection*)[self unarchiveCollectionAtPath:[[self collectionsPath] stringByAppendingPathComponent:pname]];
			if ( aNode != nil ) 
			{
				// Scriptability and relationship to journal
				[aNode setScriptContainer:owner];
				[aNode setValue:self forKey:@"journal"];
				
				// add the collection to the temp collections array
				[tempCollections addObject:aNode];
				
				// add the collection to the collections dictionary
				[_collectionsDic setObject:aNode forKey:[aNode tagID]];
					
				// update last tag and count
				if ( lastFolderTag  < [[aNode tagID] intValue] )
					lastFolderTag = [[aNode tagID] intValue];

				c++;
			}
			else 
			{
				NSLog(@"%@ %s - Unable to load collection at path %@", [self className], _cmd, [[self collectionsPath] stringByAppendingPathComponent:pname]);
			}
		}
	}
	
	// set the collections array and number
	NSSortDescriptor *childSort = [[[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES selector:@selector(compare:)] autorelease];
	[self setCollections:[tempCollections sortedArrayUsingDescriptors:[NSArray arrayWithObject:childSort]]];
	
	
	// LOAD THE RESOURCES
	if ( [[self version] intValue] >= 250 )
	{
		contentsEnumerator = [[fm directoryContentsAtPath:[self resourcesPath]] objectEnumerator];
	
		c = 0;
		while ( pname = [contentsEnumerator nextObject] ) 
		{
			if ([[pname pathExtension] isEqualToString:@"jresource"]) 
			{
				JournlerResource *aResource = (JournlerResource*)[self unarchiveResourceAtPath:
				[[self resourcesPath] stringByAppendingPathComponent:pname]];
				
				if ( aResource != nil ) 
				{
					// Scriptability and relationship to journal
					[aResource setScriptContainer:owner];
					[aResource setValue:self forKey:@"journal"];
					
					// add the resource to the temp resources array
					[tempResources addObject:aResource];
					
					// add the resource to the resources dictionary
					[resourcesDic setObject:aResource forKey:[aResource tagID]];
						
					// update last tag and count
					if ( lastResourceTag  < [[aResource tagID] intValue] )
						lastResourceTag = [[aResource tagID] intValue];

					c++;
				}
				else 
				{
					NSLog(@"%@ %s - Unable to load resource at path %@", [self className], _cmd, [[self resourcesPath] stringByAppendingPathComponent:pname]);
				}
			}
		}
		
		// set the resources
		[self setResources:tempResources];

	}
	
	
	return directoryLoadFlag;
}

#pragma mark -

- (BOOL) calIntHasEntries:(int)dayAsInt 
{
	int i;
	int count = 0;
	
	for ( i = [_entries count] - 1; i >= 0; i-- ) {
		if ( dayAsInt == [[_entries objectAtIndex:i] dateInt]  && 
			![[[_entries objectAtIndex:i] valueForKey:@"markedForTrash"] boolValue] ) {
			count = 1;
			break;
		}
	}
	
	return count;
}

- (void) entry:(JournlerEntry*)anEntry didChangeTitle:(NSString*)oldTitle
{
	// #warning if an entry takes on the name of another entry while the user is changing the title...
	
	// remove the old wiki title
	[entryWikis removeObjectForKey:oldTitle];
	
	// get the new title
	NSString *newWikiTitle = [anEntry wikiTitle];
	
	if ( newWikiTitle != nil )
	{
		[entryWikis setValue:[anEntry URIRepresentation] forKey:newWikiTitle];
		
		// don't mark the wiki title as needing spell correction
		if ( [[NSApp delegate] respondsToSelector:@selector(spellDocumentTag)] )
			[[NSSpellChecker sharedSpellChecker] ignoreWord:newWikiTitle inSpellDocumentWithTag:[[NSApp delegate] spellDocumentTag]];
	}
	
	// check all journler object resources and change their titles if necessary
	//NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type == %i AND uriString MATCHES %@", kResourceTypeJournlerObject, [anEntry URIRepresentationAsString]];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type == %i AND uriString == %@", kResourceTypeJournlerObject, [anEntry URIRepresentationAsString]];
	NSArray *filteredArray = [[self resources] filteredArrayUsingPredicate:predicate];
	
	if ( [filteredArray count] > 0 )
	{
		#ifdef __DEBUG__
		NSLog(@"%@ %s - updating the title on %i resources", [self className], _cmd, [filteredArray count]);
		#endif
		
		JournlerResource *aResources;
		NSEnumerator *enumerator = [filteredArray objectEnumerator];
		
		while ( aResources = [enumerator nextObject] )
			[aResources setValue:[anEntry valueForKey:@"title"] forKey:@"title"];
	}
}

- (void) entry:(JournlerEntry*)anEntry didChangeTags:(NSArray*)oldTags
{
	// dif the tags to discover which were removed and which were added
	// added tags may be immediately added to the set
	// for each removed tag, find out if there are still entries with that particular tag, if not, remove the tag from the set
	
	NSSet *currentTags = [NSSet setWithArray:[anEntry valueForKey:@"tags"]];
	NSSet *previousTags = [NSSet setWithArray:oldTags];
	
	NSMutableSet *addedItems = [NSMutableSet setWithSet:currentTags];
	NSMutableSet *removedItems = [NSMutableSet setWithSet:previousTags];
	
	[addedItems minusSet:previousTags];
	[removedItems minusSet:currentTags];
	
	[entryTags unionSet:addedItems];
	
	NSString *aTag;
	NSEnumerator *enumerator = [removedItems objectEnumerator];
	
	while ( aTag = [[enumerator nextObject] lowercaseString] )
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%@ in tags.lowercaseString AND markedForTrash == NO",aTag];
		if ( [[[self entries] filteredArrayUsingPredicate:predicate] count] == 0 )
			[entryTags removeObject:aTag];
	}
	
	//NSLog([entryTags description]);
}

#pragma mark -

- (void) saveProperties 
{		
	// write and log any errors
	if ( ![_properties writeToFile:[self propertiesPath] atomically:YES] )
		NSLog(@"Unable to write journal properties to path %@", [self propertiesPath]);
}

- (void) saveCollections 
{	
	[self writeJournalCollection:[_collectionsDic allValues]];	
}



#pragma mark -

- (void) saveBlogs 
{
	int i;
	for ( i = 0; i < [_blogs count]; i++ )
		[self saveBlog:[_blogs objectAtIndex:i]];
}

- (void) addBlog:(BlogPref*)aBlog 
{	
	// don't add the blog if we already have it
	if ( [_blogs indexOfObjectIdenticalTo:aBlog] != NSNotFound ) return;
	
	// make sure the blog has an approrpiate id
	if ( [[aBlog valueForKey:@"tagID"] intValue] == -1 ) 
		[aBlog setValue:[NSNumber numberWithInt:[self newBlogTag]] forKey:@"tagID"];
	
	// set its container
	//[aBlog setMyContainer:owner];
	
	//[aBlog setValue:self forKey:@"theJournal"];
	[aBlog setValue:self forKey:@"journal"];
	
	// add the necessary keychain informaiton
	
	// add the blog to the array
	NSMutableArray *temp = [[self blogs] mutableCopyWithZone:[self zone]];
	
	[temp addObject:aBlog];
	[self setBlogs:temp];
	
	[temp release];
	
	// update the dictionary
	[_blogsDic setObject:aBlog forKey:[aBlog tagID]];
	
}

#pragma mark -

- (void) updateIndexAndCollections:(id)object 
{	
	//
	// and entry is still searchable if it is marked for deletion
	// do not update the collections with this entry if it is marked for delete
	
	if ( [object isKindOfClass:[JournlerEntry class]] ) 
	{
		//
		// a single entry, act accordingly
		
		[self _updateIndex:object];
		[self _updateCollections:object];
	
	}
	else if ( [object isKindOfClass:[NSArray class]] )  
	{
		//
		// an array of entries, act accordingly
		int i;
		for ( i = 0; i < [object count]; i++ ) {
			[self _updateIndex:[object objectAtIndex:i]];
			[self _updateCollections:[object objectAtIndex:i]];
		}
		
	}
}

- (void) _updateIndex:(JournlerEntry*)entry 
{
	// do not index entries that are marked for the trash
	if ( [[entry valueForKey:@"markedForTrash"] boolValue] )
		return;
		
	[searchManager indexEntry:entry];	
}

- (void) _updateCollections:(JournlerEntry*)entry 
{	
	// do not update the collections with the entry if it is marked for trash
	if ( [[entry valueForKey:@"markedForTrash"] boolValue] )
		return;
	
	[_libraryCollection addEntry:entry];
	[_rootCollection evaluateAndAct:entry considerChildren:YES];
}

#pragma mark -

- (NSArray*) collectionsForTypeID:(int)type 
{	
	int i;
	NSArray *collections = [_collectionsDic allValues];
	NSMutableArray *returnArray = [[NSMutableArray alloc] initWithCapacity:[collections count]];
	
	for ( i = 0; i < [collections count]; i++ ) {
		
		if ( [[(JournlerCollection*)[collections objectAtIndex:i] valueForKey:@"typeID"] intValue] == type )
			[returnArray addObject:[collections objectAtIndex:i]];
		
	}
	
	return [returnArray autorelease];
}

- (JournlerCollection*) libraryCollection 
{
	return _libraryCollection;
}

- (JournlerCollection*) trashCollection 
{
	return _trashCollection;
}

#pragma mark -
#pragma mark Console Utilities

- (BOOL) resetSmartFolders
{
	int i;
	NSArray *allEntries = [self entries];
	for ( i = 0; i < [allEntries count]; i++ )
		[self _updateCollections:[allEntries objectAtIndex:i]];
	
	return YES;
}

- (BOOL) resetSearchManager 
{
	NSLog(@"%@ %s - Rebuilding search index", [self className], _cmd);
	
	// Clear out the old manager
	if ( searchManager ) 
	{
		[searchManager release];
		searchManager = nil;
	}
	
	// Realloc
	searchManager = [[JournlerSearchManager alloc] initWithJournal:self];
	if ( !searchManager ) {
		NSLog(@"%@ %s - Unable to reallocate search manager, searching disabled", [self className], _cmd);
		return NO;
	}
	
	// Delete any existing indexes and re-create them
	[searchManager deleteIndexAtPath:[self journalPath]];

	// reload the index
	if ( ![searchManager createIndexAtPath:[self journalPath]] || ![searchManager loadIndexAtPath:[self journalPath]] )
	{
		NSLog(@"%@ %s - Unable to recreate or reload index at journal path %@", [self className], _cmd, [self journalPath]);
		return NO;
	}
	
	// rederive the textual representations
	JournlerResource *aResource;
	NSEnumerator *enumerator = [[self resources] objectEnumerator];
	while ( aResource = [enumerator nextObject] )
		[aResource _deriveTextRepresentation:nil];
	
	// Rebuild the indexes
	[searchManager rebuildIndex];
		
	NSLog(@"%@ %s - Search reset successful", [self className], _cmd);
	return YES;
}

- (BOOL) resetEntryDateModified 
{	
	int i;
	
	NSLog(@"Resetting date modified property of journal entry objects");
	
	for ( i = 0; i < [_entries count]; i++ ) {
		
		// reset the date
		[(JournlerEntry*)[_entries objectAtIndex:i] 
				setCalDateModified:[(JournlerEntry*)[_entries objectAtIndex:i] calDate]];
		
		// update the entry against collections testing the date modified property
		[self _updateCollections:[_entries objectAtIndex:i]];
		
		// write the entry to disk
		[self saveEntry:[_entries objectAtIndex:i]];
		
	}
	
	NSLog(@"Completed reset");
	return YES;
}

- (BOOL) createResourcesForLinkedFiles
{
	// parse each entry for file:// style links and create
	
	BOOL completeSuccess = YES;
	JournlerEntry *anEntry;
	NSEnumerator *enumerator = [[self entries] objectEnumerator];
	
	while ( anEntry = [enumerator nextObject] )
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSMutableAttributedString *mutableContent = [[[anEntry attributedContent] mutableCopyWithZone:[self zone]] autorelease];
		
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
				NSURL *theURL;
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
							NSLog(@"%@ %s - unable to produce new resource for entry %@ with path %@",
									[self className], _cmd, [anEntry tagID], [theURL path]);
						}
						else
						{
							// easy, the replacement url is the resource uri rep
							replacementURL = [theResource URIRepresentation];
							[pathToResourceDictionary setObject:theResource forKey:theURL];
							
							#ifdef __DEBUG__
							NSLog(@"%@ -> %@", [theURL absoluteString], [replacementURL absoluteString]);
							#endif
						}
					}
					
					// and finally, set the replacement url in place of the current url
					if ( replacementURL != nil )
						[mutableContent addAttribute:NSLinkAttributeName value:replacementURL range:effectiveRange];
				}
			}
			
			limitRange = NSMakeRange(NSMaxRange(effectiveRange), NSMaxRange(limitRange) - NSMaxRange(effectiveRange));
		}
		
		[anEntry setValue:mutableContent forKey:@"attributedContent"];
		[pool release];
	}
	
	return ( [self save:nil] && completeSuccess );
}

- (BOOL) updateJournlerResourceTitles
{
	// looks at the available resources and updates their titles to match the titles of the entries they represent
	NSPredicate *typePredicate = [NSPredicate predicateWithFormat:@"type == %i", kResourceTypeJournlerObject];
	NSArray *filteredResources = [[self resources] filteredArrayUsingPredicate:typePredicate];
	
	JournlerResource *aResource;
	NSEnumerator *enumerator = [filteredResources objectEnumerator];
	
	while ( aResource = [enumerator nextObject] )
	{
		JournlerEntry *representedEntry = [aResource journlerObject];
		if ( representedEntry == nil )
		{
			NSLog(@"%@ %s - unable to produce entry for uri %@", [self className], _cmd, [aResource uriString]);
			continue;
		}
		
		[aResource setValue:[representedEntry valueForKey:@"title"] forKey:@"title"];
	}
	
	return [self save:nil];
}

- (BOOL) resetResourceText
{
	JournlerResource *aResource;
	NSEnumerator *enumerator = [[self resources] objectEnumerator];
	
	while ( aResource = [enumerator nextObject] )
		[aResource _deriveTextRepresentation:nil];
	
	return [self save:nil];
}

- (BOOL) resetRelativePaths
{
	BOOL completeSucces = YES;
	JournlerResource *aResource;
	NSEnumerator *enumerator = [[self resources] objectEnumerator];
	
	while ( aResource = [enumerator nextObject] )
	{
		if ( [aResource type] != kResourceTypeFile )
			continue;
		
		NSString *originalPath = [aResource originalPath];
		if ( originalPath != nil )
		{
			NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:originalPath traverseLink:YES];
			
			[aResource setValue:[fileAttributes objectForKey:NSFileModificationDate] forKey:@"underlyingModificationDate"];
			[aResource setValue:[originalPath stringByAbbreviatingWithTildeInPath] forKey:@"relativePath"];
		}
		else
		{
			completeSucces = NO;
			NSLog(@"%@ %s - original file missing for resource %@-%@ %@", [self className], _cmd, 
			[[aResource entry] tagID], [aResource tagID], [aResource title]);
		}
	}
	
	return ( [self save:nil] && completeSucces );
}

- (NSArray*) orphanedResources
{
	// returns an array of resources that don't have any owner
	NSMutableArray *orphanedResources = [NSMutableArray array];
	NSEnumerator *enumerator = [[self resources] objectEnumerator];
	JournlerResource *aResource;
	
	while ( aResource = [enumerator nextObject] )
	{
		if ( [aResource entry] == nil )
			[orphanedResources addObject:aResource];
		
		if ( [aResource entry] == nil && [[aResource entries] count] > 0 )
			NSLog(@"%@ %s - resource %@:%@ does not have an owner but does belong to entries", [self className], _cmd, [aResource tagID], [aResource title]);
	}
	
	return orphanedResources;
}

- (BOOL) deleteOrphanedResources:(NSArray*)theResources
{
	BOOL completeSuccess = YES;
	JournlerResource *aResource;
	NSEnumerator *enumerator = ( theResources != nil ? [theResources objectEnumerator] : [[self orphanedResources] objectEnumerator] );
	
	while ( aResource = [enumerator nextObject] )
	{
		BOOL localSuccess = [self deleteResource:aResource];
		completeSuccess = ( completeSuccess && localSuccess );
	}
	
	return completeSuccess;
}

#pragma mark -

//
// a 1.15 addition - trashing
- (void) markEntryForTrash:(JournlerEntry*)entry 
{
	
	if ( entry == nil )
		return;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JournalWillTrashEntryNotification object:self 
	userInfo:[NSDictionary dictionaryWithObject:entry forKey:@"entry"]];
	
	[entry retain];
	
	// mark it for trashing
	[entry setValue:BooleanNumber(YES) forKey:@"markedForTrash"];
	
	// remove it from every collection but the trash, making sure it is in the trash
	[_rootCollection removeEntry:entry considerChildren:YES];
	[_trashCollection addEntry:entry];
	
	// entries marked for trash should not be searched
	[searchManager removeEntry:entry];
	
	// write it out
	[self saveEntry:entry];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JournalDidTrashEntryNotification object:self 
	userInfo:[NSDictionary dictionaryWithObject:entry forKey:@"entry"]];
	
	[entry release];
}

- (void) unmarkEntryForTrash:(JournlerEntry*)entry {
	
	if ( entry == nil )
		return;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JournalWillUntrashEntryNotification object:self 
	userInfo:[NSDictionary dictionaryWithObject:entry forKey:@"entry"]];
	
	[entry retain];
	
	// if the entry is marked for trash, unmark for trash
	[entry setValue:BooleanNumber(NO) forKey:@"markedForTrash"];
	
	// remove the entry from the trash
	[_trashCollection removeEntry:entry];
		
	// add the entry back to the journal and save
	[self addEntry:entry];
	[self saveEntry:entry];
		
	[[NSNotificationCenter defaultCenter] postNotificationName:JournalDidUntrashEntryNotification object:self 
	userInfo:[NSDictionary dictionaryWithObject:entry forKey:@"entry"]];
		
	[entry release];
	
}

#pragma mark -
#pragma mark Deprecated Methods

// DEPRECATED
- (NSURL*) urlForResourcePath:(NSString*)path entryID:(NSString*)entryTag {
	JournlerEntry *entry = [self entryForTagString:entryTag];
	if ( !entry )
		return nil;
	
	return [entry fileURLForResourceFilename:path];
}

// DEPRECATED
- (void) saveScriptChanges 
{
	[self save:nil];
}


// DEPRECATED
- (NSString*) password 
{ 
	return password; 
}

- (void) setPassword:(NSString*)encryptionPassword 
{
	
	if ( password != encryptionPassword ) 
	{
		[password release];
		password = [encryptionPassword copyWithZone:[self zone]];
	}
	
	// mark the key as needing to be regenerated
	//if ( _keySchonGenerated ) cdsaFreeKey(_cspHandle, &_generatedKey);
	//_keySchonGenerated = NO;
	
}

// DEPRECATED
- (void) addEntry:(JournlerEntry*)entry threaded:(BOOL)thread {
	
	//
	// ensure the entry has an appropriate id
	if ( [[entry valueForKey:@"tagID"] intValue] == 0 )
		[entry setValue:[NSNumber numberWithInt:[self newEntryTag]] forKey:@"tagID"];
	
	//
	// scriptability	-- an entry's container is always the journal collection
	[entry setScriptContainer:owner];
	[entry setValue:self forKey:@"journal"];

	//
	// add the entries to our entries array if its not there
	if ( [_entries indexOfObjectIdenticalTo:entry] == NSNotFound ) {
	
		NSMutableArray *tempEntries = [[self entries] mutableCopyWithZone:[self zone]];
		
		[tempEntries addObject:entry];
		[self setEntries:tempEntries];

		// clean up
		[tempEntries release];
	
	}
	
	// add the entry to the dictionary
	if ( [_entriesDic objectForKey:[entry tagID]] == nil )
		[_entriesDic setObject:entry forKey:[entry tagID]];
		
	// finally write the entry to file
	[self saveEntry:entry];
	
}


// DEPRECATED
/*
- (BOOL) deleteObject:(id)entry {
	
	//
	// 1.0.2 implementation
	// Physically remove the entry when we have requested a delete
	//
	
	int i;
	BOOL complete_success = YES;
	NSArray *deleteArray;
	
	if ( [entry isKindOfClass:[JournlerEntry class]] )
		deleteArray = [NSArray arrayWithObject:entry];
	else if ( [entry isKindOfClass:[NSArray class]] )
		deleteArray = entry;
	
	for ( i = 0; i < [deleteArray count]; i++ ) {
		
		NSString *full_path;
		JournlerEntry *anEntry = [deleteArray objectAtIndex:i];
		
		// path info for the physical delete
		NSString *title_path = [anEntry previouslySavedTitle];
		if ( title_path == nil ) title_path = [anEntry pathSafeTitle];
		
		full_path = [[self entriesPath] stringByAppendingPathComponent:
			[NSString stringWithFormat:@"%@ - %@.jentry", [anEntry tagID], title_path]];
		
		// remove the file from searching
		[searchManager removeEntry:anEntry];
		
		// remove the file from any collections	-- recursively
		[_rootCollection removeEntry:anEntry considerChildren:YES];
		
		// remove the entry from the dictionary
		[_entriesDic removeObjectForKey:[anEntry tagID]];
		
		// physically delete the file
		complete_success = ( [[NSFileManager defaultManager] removeFileAtPath:full_path handler:self] && complete_success );
	
	}
	
	// remove the entry from the entries array
	NSMutableArray *tempEntries = [[self entries] mutableCopyWithZone:[self zone]];
	
	[tempEntries removeObjectsInArray:deleteArray];
	[self setEntries:tempEntries];
	
	[tempEntries release];
	
	return complete_success;
	
}
*/

// DEPRECATED
- (JournlerEntry*) unpackageEntryAtPath:(NSString*)filepath 
{
	BOOL entry_encrypted;
	NSData	*readableData;
	JournlerEntry	*unarchivedObject = nil;
	
	NSString *packagePath, *archivePath, *encryptionPath;
	
	packagePath = filepath;
	
	//archivePath = [packagePath stringByAppendingPathComponent:PDEntryPackageEntryContents];
	NSArray *archivePossibilities = [[[NSFileManager defaultManager] directoryContentsAtPath:packagePath] 
			pathsMatchingExtensions:[NSArray arrayWithObject:@"jobj"]];
	if ( [archivePossibilities count] == 1 )
		archivePath = [packagePath stringByAppendingPathComponent:[archivePossibilities objectAtIndex:0]];
	else
	{
		NSLog(@"%@ %s - unable to locate entry contents at package path %@", [self className], _cmd, packagePath);
		return nil;
	}
	
	encryptionPath = [packagePath stringByAppendingPathComponent:PDEntryPackageEncrypted];
	
	NSData *objectData = [[NSData alloc] initWithContentsOfFile:archivePath];
	if ( !objectData ) 
	{
		NSLog(@"Unable to read object data at %@", packagePath);
		return nil;
	}
	
	// check for existence of hidden encrypted file
	/*
	if ( [[NSFileManager defaultManager] fileExistsAtPath:encryptionPath] ) 
	{
		CSSM_RETURN			crtn;
		CSSM_KEY			cdsaKey;
		
		CSSM_DATA			inData;					// data to encrypt/decrypt, 
		CSSM_DATA			outData = {0, NULL};	// result data, written to outFile

		// make sure our handle is valid
		if ( !_cspHandle ) {
			// error, need to do something drastic here
			NSLog(@"Critical encryption error, Entry reports encrypted but journal does not have cspHandle");
			return nil;
		}
		
		cdsaKey = [self generatedKey];
				
		// set our inData properties
		inData.Data = (uint8 *)[objectData bytes];
		inData.Length = [objectData length];
		
		//  decrypt
		crtn = cdsaDecrypt(_cspHandle, &cdsaKey, &inData, &outData);
		if ( crtn ) {
			NSLog(@"Decryption error, unable to decrypt entry at path %@", packagePath);
			return nil;
		}
		
		// set the readable data which the coder will use
		readableData = [NSData dataWithBytes:outData.Data length:outData.Length];
		
		entry_encrypted = YES;
		
		// clean up
		free(outData.Data);
		
	}
	else 
	{
		readableData = objectData;
		entry_encrypted = NO;
	}
	*/
	
	readableData = objectData;
	entry_encrypted = NO;
	
	@try
	{
		unarchivedObject = [NSKeyedUnarchiver unarchiveObjectWithData:readableData];
		
		// mark the entry's encryption flag
		[unarchivedObject setValue:[NSNumber numberWithBool:entry_encrypted] forKey:@"encrypted"];
	}
	@catch (NSException *localException)
	{
		unarchivedObject = nil;
		NSLog(@"%@ %s - unable to unarchive entry at path %@, exception %@", [self className], _cmd, filepath, localException);
		[initErrors addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt:0], @"objectType",
				filepath, @"errorString",
				localException, @"localException", nil]];
	}
	@finally
	{
		[objectData release];
		return unarchivedObject;
	}
	
	// set the perivious path title to the currently saved path title
	//[unarchivedObject setPreviouslySavedTitle:[unarchivedObject pathSafeTitle]];
}

// DEPRECATED
/*
- (BOOL) packageEntry:(JournlerEntry*)entry 
{	
	BOOL dir, isEncrypted;
	NSString *packagePath, *archivePath, *previous_package_path, *encryptionPath;
	
	NSData	*writableData;
	NSData	*encodedData = [NSKeyedArchiver archivedDataWithRootObject:entry];
	
	// derive the package path, archive path and encryption path
	packagePath = [entry pathToPackage];
	
	archivePath = [packagePath stringByAppendingPathComponent:PDEntryPackageEntryContents];
	encryptionPath = [packagePath stringByAppendingPathComponent:PDEntryPackageEncrypted];
	
	// check to see if this entry was saved under a previous name, if so initialize package from that
	if ( [entry previouslySavedTitle] != nil && ![[entry previouslySavedTitle] isEqualToString:[entry pathSafeTitle]] )
		previous_package_path = [[self entriesPath] stringByAppendingPathComponent:
				[NSString stringWithFormat:@"%@ - %@.jentry", [entry tagID], [entry previouslySavedTitle]]];
	else
		previous_package_path = nil;
	
	// create a file wrapper for the package, taking various action depending on the prior state of the entry's package
	NSFileWrapper *entryWrapper;
	if ( previous_package_path != nil && 
			[[NSFileManager defaultManager] fileExistsAtPath:previous_package_path isDirectory:&dir] && dir ) 
	{
		entryWrapper = [[NSFileWrapper alloc] initWithPath:previous_package_path];
	}
	
	else if ( ![[NSFileManager defaultManager] fileExistsAtPath:packagePath isDirectory:&dir] || !dir ) 
	{
		entryWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
	}
	else 
	{
		entryWrapper = [[NSFileWrapper alloc] initWithPath:packagePath];
	}
	
	if ( !entryWrapper ) 
	{
		// critical error
		NSLog(@"Unable to create entry wrapper for entry %@", [entry tagID]);
	}
	
	// remove the old entry contents
	NSFileWrapper *entry_data_wrapper = [[entryWrapper fileWrappers] objectForKey:PDEntryPackageEntryContents];
	if ( entry_data_wrapper ) 
		[entryWrapper removeFileWrapper:entry_data_wrapper];
	
	// remove the encryption wrapper as well
	NSFileWrapper *entry_encryption_wrapper = [[entryWrapper fileWrappers] objectForKey:PDEntryPackageEncrypted];
	if ( entry_encryption_wrapper ) 
		[entryWrapper removeFileWrapper:entry_encryption_wrapper];
	
	if ( [[self valueForKey:@"encrypted"] boolValue] ) 
	{
		CSSM_RETURN			crtn;
		CSSM_KEY			cdsaKey;
		
		CSSM_DATA			inData;					// data to encrypt/decrypt, 
		CSSM_DATA			outData = {0, NULL};	// result data, written to outFile
				
		isEncrypted = YES;	
		
		// make sure our handle is valid
		if ( !_cspHandle ) {
			NSLog(@"Invalid cspHandle, unable to encrypt entry");
			isEncrypted = NO;
			writableData = encodedData;
			goto bail;
		}
		
		cdsaKey = [self generatedKey];
						
		// prepare the entry for encryption
		inData.Data = (uint8 *)[encodedData bytes];
		inData.Length = [encodedData length];
		
		// preform the encryption
		crtn = cdsaEncrypt(_cspHandle, &cdsaKey, &inData, &outData);
		if ( crtn ) {
			NSLog(@"encryption error, unable to encrypt entry to path %@", packagePath);
			isEncrypted = NO;
			writableData = encodedData;
			goto bail;
		}
		
		// add our output data to an NSData object
		writableData = [NSData dataWithBytes:outData.Data length:outData.Length];

		// free the created output data
		free(outData.Data);
	}
	
	else 
	{
		isEncrypted = NO;
		writableData = encodedData;
	}

bail:
// bail in case of error attempting to encrypt	
	
	// prepare the entry data for writing
	if ( !writableData ) {
		NSLog(@"JournlerJournal packageEntry: - unable to produce object data from object dictionary during save!");
		return NO;
	}
	
	// add the object data to the package wrapper and attempt to write it
	[entryWrapper addRegularFileWithContents:writableData preferredFilename:PDEntryPackageEntryContents];
	
	// add the encryption data to the package wrapper if encryption was successful
	if ( isEncrypted )
		[entryWrapper addRegularFileWithContents:[NSData data] preferredFilename:PDEntryPackageEncrypted];
		
	// add the RTFD content to the wrapper
	NSAttributedString *attributedContent = [entry valueForKey:@"attributedContent"];
	NSFileWrapper *rtfdWrapper = [attributedContent RTFDFileWrapperFromRange:NSMakeRange(0,[attributedContent length]) 
			documentAttributes:nil];
			
	if ( rtfdWrapper != nil )
	{
		[rtfdWrapper setPreferredFilename:PDEntryPackageRTFDContent];
		[entryWrapper addFileWrapper:rtfdWrapper];
	}
	else 
	{
		NSLog(@"%@ %s - unable to create file wrapper for entry content %@", 
				[self className], _cmd, [entry valueForKey:@"tagID"]);
	}
	
	BOOL success;
	if ( [entryWrapper writeToFile:packagePath atomically:YES updateFilenames:YES] ) 
	{
		// delete the old entry wrapper if one existed
		if ( previous_package_path != nil && 
				[[NSFileManager defaultManager] fileExistsAtPath:previous_package_path isDirectory:&dir] && dir ) 
		{
			[[NSFileManager defaultManager] removeFileAtPath:previous_package_path handler:self];
		}
		
		// update the previously saved title
		[entry setPreviouslySavedTitle:[entry pathSafeTitle]];
		
		//spotlight any of the entry's resources
		NSString *resourcePath = [entry pathToResourcesCreatingIfNecessary:NO];
		if ( resourcePath != nil ) 
		{
			static NSString *launchPath = @"/usr/bin/mdimport";
			static NSString *taskOptions = @"-f";
			NSArray *args = [NSArray arrayWithObjects: taskOptions, resourcePath, nil];
		
			NSTask *aTask = [NSTask launchedTaskWithLaunchPath:launchPath arguments:args];
			[aTask waitUntilExit];
		}
		
		success = YES;
	}
	else 
	{
		NSLog(@"JournlerJournal packageEntry: - unable to write file package to path %@", packagePath);
		NSLog([entry description]);
		success = NO;
	}
	
	[entryWrapper release];
	return success;
}
*/

#pragma mark -

// DEPRECATED
- (BOOL) writeJournalCollection:(id)collection {
	
	int i;
	BOOL success = YES;
	NSArray *writeArray;
	
	if ( collection == nil )
		return NO;
	
	
	
	if ( [collection isKindOfClass:[JournlerCollection class]] )
		writeArray = [NSArray arrayWithObject:collection];
	else if ( [collection isKindOfClass:[NSArray class]] )
		writeArray = collection;
	
	for ( i = 0; i < [writeArray count]; i++ ) {
		
		// do not write the root collection
		if ( [writeArray objectAtIndex:i] == _rootCollection )
			continue;
		
		NSString *path = [[self collectionsPath] stringByAppendingPathComponent:
				[NSString stringWithFormat:@"%@.jcol", [[writeArray objectAtIndex:i] tagID]]];
		
		// update the collection's journal identifier
		[[writeArray objectAtIndex:i] setJournalID:[self identifier]];
		
		if ( ![self archiveCollection:[writeArray objectAtIndex:i] location:path] ) {
			NSLog( @"Unable to save collection %@ to disk", [[writeArray objectAtIndex:i] tagID] );
			success = NO;
		}
		
	}
	
	
	return success;
	
}

// DEPRECATED
- (BOOL) archiveCollection:(JournlerCollection*)object location:(NSString*)path {
	return [NSKeyedArchiver archiveRootObject:object toFile:path];
}

- (JournlerCollection*) unarchiveCollectionAtPath:(NSString*)path 
{
	JournlerCollection *aCollection = nil;
	
	@try
	{
		aCollection = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
	}
	@catch (NSException *localException)
	{
		aCollection = nil;
		NSLog(@"%@ %s - unable to unarchive folder at path %@, exception %@", [self className], _cmd, path, localException);
		[initErrors addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt:1], @"objectType",
				path, @"errorString",
				localException, @"localException", nil]];
	}
	@finally
	{
		return aCollection;
	}
}

// DEPRECATED
- (BOOL) archiveBlog:(BlogPref*)object location:(NSString*)path {
	return [NSKeyedArchiver archiveRootObject:object toFile:path];
}

- (BlogPref*) unarchiveBlogAtPath:(NSString*)path {
	
	BlogPref *blogPref = nil;
	
	@try
	{
		blogPref = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
	}
	@catch (NSException *localException)
	{
		blogPref = nil;
		NSLog(@"%@ %s - unable to unarchive blog at path %@, exception %@", [self className], _cmd, path, localException);
		[initErrors addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt:2], @"objectType",
				path, @"errorString",
				localException, @"localException", nil]];
	}
	@finally
	{
		return blogPref;
	}
}

- (JournlerResource*) unarchiveResourceAtPath:(NSString*)path
{
	JournlerResource *aResource = nil;
	
	@try
	{
		aResource = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
	}
	@catch (NSException *localException)
	{
		aResource = nil;
		NSLog(@"%@ %s - unable to unarchive resource at path %@, exception %@", [self className], _cmd, path, localException);
		[initErrors addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt:3], @"objectType",
				path, @"errorString",
				localException, @"localException", nil]];
	}
	@finally
	{
		return aResource;
	}
}

#pragma mark -

// DEPRECATED
/*
- (CSSM_KEY) generatedKey {
	
	if ( !_keySchonGenerated ) {
	
		//
		// generate the key only if necessary
		// remember to reset this value when loading other journals (how to handle encryption w/ multiple journals)
		//
		int passLength;
		const char *passphraseChar;
	
		static int keySizeInBits = 256;
		
		CSSM_RETURN			crtn;
		CSSM_ALGORITHMS		encrAlg = CSSM_ALGID_AES;
		CSSM_HANDLE			cssmHandle;
		
		// prepare the decryption mechanism
		// -----------------------------------------------------------------
		
		// use the password sent to our journal
		passphraseChar = [[self password] UTF8String];
		passLength = [[[self password] dataUsingEncoding:NSUTF8StringEncoding] length];
		
		cssmHandle = [self cspHandle];
		
		// make sure our handle is valid
		if ( ![self cspHandle] ) {
			NSLog(@"No cspHandle, cannot decrypt journal");
			_generatedKey.KeyData.Data = nil;
		}
		
		// derive a key from the passphrase
		crtn = cdsaDeriveKey([self cspHandle], passphraseChar, passLength, encrAlg, keySizeInBits, &_generatedKey);
		if ( crtn ) {
			NSLog(@"Critical encryption error, unable to derive key from password");
			_generatedKey.KeyData.Data = nil;
			// and again, what to do here?
		}
		
		_keySchonGenerated = YES;
	
	}
	
	return _generatedKey;
	
}

- (CSSM_CSP_HANDLE) cspHandle 
{ 
	return _cspHandle; 
}
*/

#pragma mark -

- (JournlerCollection*) rootCollection 
{ 
	return _rootCollection; 
}

- (void) setRootCollection:(JournlerCollection*)root 
{
	// dummy for key value coding
	return;
}

- (NSArray*) rootFolders
{
	return [_rootCollection children];
}

- (void) setRootFolders:(NSArray*)anArray
{
	// dummy for key value coding
	return;
}

#pragma mark -

- (JournlerCollection*) collectionForID:(NSNumber*)idTag 
{
	if ( [idTag intValue] == -1 )
		return _rootCollection;
	else
		return [_collectionsDic objectForKey:idTag];
}

#pragma mark -

- (NSArray*) collectionsForIDs:(NSArray*)tagIDs 
{
	//
	// utility for turning an array of collection ids into the collections themselves
	
	int i;
	NSMutableArray *collections = [[NSMutableArray alloc] initWithCapacity:[tagIDs count]];
	for ( i = 0; i < [tagIDs count]; i++ ) {
		id aCollection = [_collectionsDic objectForKey:[tagIDs objectAtIndex:i]];
		if ( aCollection )
			[collections addObject:aCollection];
	}
	
	return [collections autorelease];
}

#pragma mark -

- (NSString*) collectionsPath 
{ 
	return [[self journalPath] stringByAppendingPathComponent:PDCollectionsLoc]; 
}

- (NSString*) entriesPath 
{ 
	return [[self journalPath] stringByAppendingPathComponent:PDEntriesLoc]; 
}

- (NSString*) blogsPath 
{ 
	return [[self journalPath] stringByAppendingPathComponent:PDJournalBlogsLoc]; 
}

- (NSString*) resourcesPath
{
	return [[self journalPath] stringByAppendingPathComponent:PDJournalResourcesLocation];
}

- (NSString*) propertiesPath 
{ 
	return [[self journalPath] stringByAppendingPathComponent:PDJournalPropertiesLoc]; 
}

- (NSString*) storePath
{
	return [[self journalPath] stringByAppendingPathComponent:PDJournalStoreLoc]; 
}

- (NSString*) dropBoxPath
{
	return [[self journalPath] stringByAppendingPathComponent:PDJournalDropBoxLocation];
}

#pragma mark -

- (NSDictionary*) entriesDictionary 
{ 
	return _entriesDic; 
}

- (NSDictionary*) collectionsDictionary 
{ 
	return _collectionsDic; 
}

- (NSDictionary*) blogsDictionary { 
	return _blogsDic; 
}

- (NSDictionary*) resourcesDictionary
{
	return resourcesDic;
}

- (NSDictionary*) entryWikisDictionary
{
	return entryWikis;
}

- (NSSet*) entryTags
{
	return entryTags;
}

#pragma mark -

- (BOOL) performOneTwoMaintenance {
	[_properties removeObjectForKey:@"Blogs"];
	[_properties removeObjectForKey:@"WikiLinks"];
	return YES;
} 

#pragma mark -

- (BOOL) journalIsDirty
{
	// if the journal object is dirty
	if ( [[self valueForKey:@"dirty"] boolValue] )
		return YES;
	
	int i;
	
	// or if any of the managed objects are dirty
	for ( i = 0; i < CFArrayGetCount((CFArrayRef)_entries); i++ )
	{
		if ( [[(id)CFArrayGetValueAtIndex((CFArrayRef)_entries,i) valueForKey:@"dirty"] boolValue] )
			return YES;
	}
	
	for ( i = 0; i < CFArrayGetCount((CFArrayRef)_collections); i++ )
	{
		if ( [[(id)CFArrayGetValueAtIndex((CFArrayRef)_collections,i) valueForKey:@"dirty"] boolValue] )
			return YES;
	}
	
	for ( i = 0; i < CFArrayGetCount((CFArrayRef)resources); i++ )
	{
		if ( [[(id)CFArrayGetValueAtIndex((CFArrayRef)resources,i) valueForKey:@"dirty"] boolValue] )
			return YES;
	}
	
	return NO;
}

- (BOOL) save:(NSError**)error
{
	// write the blogs, collections and entries to a single file
	
	int i;
	BOOL success;
	NSDictionary *store;
	NSMutableArray *theBlogs, *theEntries, *theCollections, *theResources;
	
	theBlogs = [[[NSMutableArray alloc] initWithCapacity:[_blogs count]] autorelease];
	theEntries = [[[NSMutableArray alloc] initWithCapacity:[_entries count]] autorelease];
	theCollections = [[[NSMutableArray alloc] initWithCapacity:[_collections count]] autorelease];
	theResources = [[[NSMutableArray alloc] initWithCapacity:[resources count]] autorelease];
	
	for ( i = 0; i < CFArrayGetCount((CFArrayRef)_blogs); i++ )
	{
		NSData *encodedBlog = [NSKeyedArchiver archivedDataWithRootObject:(id)CFArrayGetValueAtIndex((CFArrayRef)_blogs,i)];
		[theBlogs addObject:encodedBlog];
	}
	
	for ( i = 0; i < CFArrayGetCount((CFArrayRef)_entries); i++ )
	{
		NSDictionary *dictionary;
		NSData *encodedEntry = [NSKeyedArchiver archivedDataWithRootObject:(id)CFArrayGetValueAtIndex((CFArrayRef)_entries,i)];
		
		dictionary = [NSDictionary dictionaryWithObjectsAndKeys: encodedEntry, @"Data", nil];
		[theEntries addObject:dictionary];
	}
	
	for ( i = 0; i < CFArrayGetCount((CFArrayRef)_collections); i++ )
	{
		NSData *encodedCollection = [NSKeyedArchiver archivedDataWithRootObject:(id)CFArrayGetValueAtIndex((CFArrayRef)_collections,i)];
		[theCollections addObject:encodedCollection];
	}
	
	for ( i = 0; i < CFArrayGetCount((CFArrayRef)resources); i++ )
	{
		NSData *encodedResource = [NSKeyedArchiver archivedDataWithRootObject:(id)CFArrayGetValueAtIndex((CFArrayRef)resources,i)];
		[theResources addObject:encodedResource];
	}
	
	
	if ( [[self version] intValue] == 210 )
	{
		store = [NSDictionary dictionaryWithObjectsAndKeys:
		theBlogs, @"Blogs",
		theEntries, @"Entries",
		theCollections, @"Collections", nil];
	}
	else
	{
		store = [NSDictionary dictionaryWithObjectsAndKeys:
		theBlogs, @"Blogs",
		theEntries, @"Entries",
		theCollections, @"Collections",
		theResources, @"Resources", nil];
	}
	
	success = [store writeToFile:[self storePath] atomically:YES];
	if ( !success )
	{
		NSLog(@"%@ %s - unable to write store to path %@", [self className], _cmd, [self storePath]);
	}
	
	// save the individual entries, collections and resources that are marked as dirty
	for ( i = 0; i < CFArrayGetCount((CFArrayRef)_entries); i++ )
	{
		JournlerEntry *anEntry = (id)CFArrayGetValueAtIndex((CFArrayRef)_entries,i);
		if ( [[anEntry valueForKey:@"dirty"] boolValue] )
		{
			[self saveEntry:anEntry];
		}
	}
	
	for ( i = 0; i < CFArrayGetCount((CFArrayRef)_collections); i++ )
	{
		JournlerCollection *aCollection = (id)CFArrayGetValueAtIndex((CFArrayRef)_collections,i);
		if ( [[aCollection valueForKey:@"dirty"] boolValue] )
		{
			[self saveCollection:aCollection];
		}
	}
	
	for ( i = 0; i < CFArrayGetCount((CFArrayRef)resources); i++ )
	{
		JournlerResource *aResource = (id)CFArrayGetValueAtIndex((CFArrayRef)resources,i);
		if ( [[aResource valueForKey:@"dirty"] boolValue] )
		{
			[self saveResource:aResource];
		}
	}
	
	for ( i = 0; i < CFArrayGetCount((CFArrayRef)_blogs); i++ )
	{
		BlogPref *aBlog = (id)CFArrayGetValueAtIndex((CFArrayRef)_blogs,i);
		if ( [[aBlog valueForKey:@"dirty"] boolValue] )
		{
			[self saveBlog:aBlog];
		}
	}

	
	// write the plist to disk
	[self saveProperties];
	// write the search indexes to disk
	[searchManager writeIndexToDisk];
	// the journal is no longer dirty
	[self setValue:BooleanNumber(NO) forKey:@"dirty"];
	
	return success;
}

- (BOOL) saveEntry:(JournlerEntry*)entry
{	
	if ( entry == nil || [[entry valueForKey:@"deleted"] boolValue] )
		return NO;
	
	#ifdef __DEBUG__
	NSLog(@"%@ %s - %@ %@", [self className], _cmd, [entry valueForKey:@"tagID"], [entry valueForKey:@"title"]);
	#endif
	
	BOOL dir;
	NSError *writeError;
	NSString *packagePath, *propertiesPath, *RTFDPath, *RTFDContainer;
	
	NSData	*encodedProperties = [NSKeyedArchiver archivedDataWithRootObject:entry];
	NSAttributedString *attributedContent = [entry attributedContentIfLoaded];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	
	// derive the required paths
	packagePath = [entry packagePath];
	
	// #warning what if the contents aren't there because of an error or something?
	NSArray *propertiesPossibilities = [[fm directoryContentsAtPath:packagePath] pathsMatchingExtensions:[NSArray arrayWithObject:@"jobj"]];
	if ( [propertiesPossibilities count] == 1 )
		propertiesPath = [packagePath stringByAppendingPathComponent:[propertiesPossibilities objectAtIndex:0]];
	else
		propertiesPath = [packagePath stringByAppendingPathComponent:PDEntryPackageEntryContents];
	
	RTFDContainer = [packagePath stringByAppendingPathComponent:PDEntryPackageRTFDContainer];
	RTFDPath = [RTFDContainer stringByAppendingPathComponent:PDEntryPackageRTFDContent];
	
	// ensure that a file exists at the package path
	if ( (![fm fileExistsAtPath:packagePath isDirectory:&dir] || !dir) && ![fm createDirectoryAtPath:packagePath attributes:nil] )
	{
		// critical error - unable to save entry
		NSLog(@"%@ %s - unable to create package for entry at path %@", [self className], _cmd, packagePath);
		return NO;
	}
	
	// create a file wrapper for the attributed content
	NSFileWrapper *rtfdWrapper = ( attributedContent == nil 
			? nil 
			: [attributedContent RTFDFileWrapperFromRange:NSMakeRange(0,[attributedContent length]) documentAttributes:nil] );
	
	if ( rtfdWrapper == nil && attributedContent != nil )
	{
		NSLog(@"%@ %s - unable to create file wrapper for entry content %@", 
				[self className], _cmd, [entry valueForKey:@"tagID"]);
	}
	
	// write the encoded properties
	if ( ![encodedProperties writeToFile:propertiesPath options:NSAtomicWrite error:&writeError] )
	{
		NSLog(@"%@ %s - unable to write encoded properties to file %@, error %@", [self className], _cmd, propertiesPath, writeError);
		return NO;
	}
	else
	{
		// rename the encoded properties
		#warning file manager ignores case?
		NSString *renamedPropertiesFilename = [NSString stringWithFormat:@"%@.jobj", [entry pathSafeTitle]];
		if ( ![[propertiesPath lastPathComponent] isEqualToString:renamedPropertiesFilename] )
			[fm movePath:propertiesPath toPath:[packagePath stringByAppendingPathComponent:renamedPropertiesFilename] handler:self];
	}
	
	// ensure that a directory exists for the entry text
	if ( ![fm fileExistsAtPath:RTFDContainer] && ![fm createDirectoryAtPath:RTFDContainer attributes:nil] )
	{
		NSLog(@"%@ %s - unable to create text container at path %@", [self className], _cmd, RTFDContainer);
		return NO;
	}
	
	// write the rich text
	if ( rtfdWrapper != nil && ![rtfdWrapper writeToFile:RTFDPath atomically:YES updateFilenames:YES] )
	{
		NSLog(@"%@ %s - unable to write rtfd to file %@", [self className], _cmd, RTFDPath);
		return NO;
	}
	
	// at this point the entry is ready for indexing and collection
	if ( !([self saveEntryOptions] & kEntrySaveDoNotIndex ) )
		[self _updateIndex:entry];
	
	if ( !([self saveEntryOptions] & kEntrySaveDoNotCollect) )
		[self _updateCollections:entry];
	
	// the entry is no longer dirty
	[entry setValue:BooleanNumber(NO) forKey:@"dirty"];
	// but the entry's resources are
	
	// go ahead and save the associated resoures as well?
	
	//[[entry valueForKey:@"resources"] setValue:BooleanNumber(NO) forKey:@"dirty"];

	return YES;
}

- (BOOL) saveResource:(JournlerResource*)aResource
{
	if ( aResource == nil || [[aResource valueForKey:@"deleted"] boolValue] || [[aResource valueForKey:@"tagID"] intValue] < 0 )
		return NO;

	if ( [[self version] intValue] >= 250 )
	{
		// derive a path to the colletion
		NSString *path = [[self resourcesPath] stringByAppendingPathComponent:
				[NSString stringWithFormat:@"%@.jresource", [aResource tagID]]];
		
		// update the collection's journal identifier
		[aResource setJournalID:[self identifier]];
		
		// archive the collection
		BOOL success = [NSKeyedArchiver archiveRootObject:aResource toFile:path];
		if ( !success )
		{
			NSLog(@"%@ %s - unable to archive resource %@ to path %@", 
					[self className], _cmd, [aResource valueForKey:@"tagID"], path);
			return NO;
		}
	}

	// resources are saved with an entry, so at this point the only thing to do is index it
	if ( !([self saveEntryOptions] & kEntrySaveDoNotIndex ) )
		[searchManager indexResource:aResource owner:[aResource valueForKey:@"entry"]];
		
	[aResource setValue:BooleanNumber(NO) forKey:@"dirty"];
	
	return YES;
}

- (BOOL) saveCollection:(JournlerCollection*)aCollection
{
	if ( aCollection == nil || [[aCollection valueForKey:@"deleted"] boolValue] || aCollection == _rootCollection )
		return NO;
	
	// derive a path to the colletion
	NSString *path = [[self collectionsPath] stringByAppendingPathComponent:
			[NSString stringWithFormat:@"%@.jcol", [aCollection tagID]]];
	
	// update the collection's journal identifier
	[aCollection setJournalID:[self identifier]];
	
	// archive the collection
	BOOL success = [NSKeyedArchiver archiveRootObject:aCollection toFile:path];
	if ( !success )
	{
		NSLog(@"%@ %s - unable to archive collection %@ to path %@", 
				[self className], _cmd, [aCollection valueForKey:@"tagID"], path);
		return NO;
	}
	
	// the collection is no longer dirty
	[aCollection setValue:BooleanNumber(NO) forKey:@"dirty"];
	
	return YES;
}

- (BOOL) saveCollection:(JournlerCollection*)aCollection saveChildren:(BOOL)recursive 
{
	BOOL completeSuccess = YES;
	completeSuccess = [self saveCollection:aCollection];
	
	if ( recursive ) 
	{
		int i;
		NSArray *kids = [aCollection children];
		
		if ( kids != nil && [kids count] > 0 ) 
		{
			for ( i = 0; i < [kids count]; i++ )
				completeSuccess = ( [self saveCollection:[kids objectAtIndex:i] saveChildren:YES] && completeSuccess );
		}
	}
	
	return completeSuccess;
}

- (BOOL) saveBlog:(BlogPref*)aBlog
{
	if ( aBlog == nil || [[aBlog valueForKey:@"deleted"] boolValue] )
		return NO;
		
	// get the keychain data
	NSString *keychainUserName = [NSString stringWithFormat:@"%@-%@-%@", [aBlog blogType], [aBlog name], [aBlog login]];
	
	// remove the old keychain item
	if ( [AGKeychain checkForExistanceOfKeychainItem:@"NameJournlerKey" 
			withItemKind:@"BlogPassword" forUsername:keychainUserName] ) 
	{
		[AGKeychain deleteKeychainItem:@"NameJournlerKey" withItemKind:@"BlogPassword" forUsername:keychainUserName];
	}

	// add the blog's password to the keychain
	[AGKeychain addKeychainItem:@"NameJournlerKey" withItemKind:@"BlogPassword" 
			forUsername:keychainUserName withPassword:[aBlog password]];
	
	//prepare the path to the blog
	NSString *path = [[self blogsPath] stringByAppendingPathComponent:
			[NSString stringWithFormat:@"%@.jblog", [aBlog valueForKey:@"tagID"]]];
	
	// archive the blog
	BOOL success = [NSKeyedArchiver archiveRootObject:aBlog toFile:path];
	if ( !success)
	{
		NSLog(@"%@ %s - unable to archive blog %@ to path %@", 
				[self className], _cmd, [aBlog valueForKey:@"tagID"], path);
		return NO;
	}
	
	// the blog is no longer dirty
	[aBlog setValue:BooleanNumber(NO) forKey:@"dirty"];
		
	return YES;
}

#pragma mark -

- (void) addEntry:(JournlerEntry*)anEntry 
{	
	// ensure the entry has an appropriate id
	if ( [[anEntry valueForKey:@"tagID"] intValue] == 0 )
		[anEntry setValue:[NSNumber numberWithInt:[self newEntryTag]] forKey:@"tagID"];
	
	// journal relationship and scriptability
	[anEntry setValue:self forKey:@"journal"];
	[anEntry setScriptContainer:[self owner]];
	
	// add the entry to the library
	[[self libraryCollection] addEntry:anEntry];
	
	// add the entry to the dictionary
	if ( [_entriesDic objectForKey:[anEntry tagID]] == nil )
		[_entriesDic setObject:anEntry forKey:[anEntry tagID]];
	
	// add the entry to the entries array if its not there
	if ( [_entries indexOfObjectIdenticalTo:anEntry] == NSNotFound ) 
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:JournalWillAddEntryNotification 
			object:self userInfo:[NSDictionary dictionaryWithObject:anEntry forKey:@"entry"]];
		
		NSMutableArray *tempEntries = [[[self valueForKey:@"entries"] mutableCopyWithZone:[self zone]] autorelease];
		
		[tempEntries addObject:anEntry];
		[self setEntries:tempEntries];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:JournalDidAddEntryNotification 
			object:self userInfo:[NSDictionary dictionaryWithObject:anEntry forKey:@"entry"]];
	}
}

- (void) addCollection:(JournlerCollection*)aCollection 
{	
	// ensure an appropriate id
	if ( [[aCollection valueForKey:@"tagID"] intValue] == 0 )
		[aCollection setValue:[NSNumber numberWithInt:[self newFolderTag]] forKey:@"tagID"];
	
	// ensure a default sort
	if ( [[aCollection valueForKey:@"sortDescriptors"] count] == 0 )
	{
		NSSortDescriptor *titleSort = [[[NSSortDescriptor alloc] 
				initWithKey:@"title" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] autorelease];
		[aCollection setValue:[NSArray arrayWithObject:titleSort] forKey:@"sortDescriptors"];
	}
	
	// establish a relationship to the journal
	[aCollection setValue:self forKey:@"journal"];
	[aCollection setScriptContainer:[self owner]];
	
	// add the collection to the dictionary and array
	[_collectionsDic setObject:aCollection forKey:[aCollection tagID]];
	
	// add the collection to the collections array if its not there
	if ( [_collections indexOfObjectIdenticalTo:aCollection] == NSNotFound ) 
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:JournalWillAddFolderNotification
			object:self userInfo:[NSDictionary dictionaryWithObject:aCollection forKey:@"folder"]];
		
		NSMutableArray *tempFolders = [[[self valueForKey:@"collections"] mutableCopyWithZone:[self zone]] autorelease];
		[tempFolders addObject:aCollection];
		[self setValue:tempFolders forKey:@"collections"];	
		
		[[NSNotificationCenter defaultCenter] postNotificationName:JournalDidAddFolderNotification 
			object:self userInfo:[NSDictionary dictionaryWithObject:aCollection forKey:@"folder"]];
	}
	
	// save the collection
	[self saveCollection:aCollection];
}

- (JournlerResource*) addResource:(JournlerResource*)aResource
{
	if ( aResource == nil )
		return nil;
	
	unsigned resourceIndex;
	JournlerResource *returnResource = nil;
	
	resourceIndex = [[self valueForKey:@"resources"] indexOfObject:aResource];
	
	// add the resource to the journal's array
	if ( resourceIndex == NSNotFound )
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:JournalWillAddResourceNotificiation
			object:self userInfo:[NSDictionary dictionaryWithObject:aResource forKey:@"resource"]];
		
		// establish the relationship to the journal and scripitability
		[aResource setValue:self forKey:@"journal"];
		[aResource setScriptContainer:[self owner]];
		
		// add the resource to the dictionary
		[resourcesDic setObject:aResource forKey:[aResource tagID]];
		
		NSMutableArray *theResources = [[[self valueForKey:@"resources"] mutableCopyWithZone:[self zone]] autorelease];
		[theResources addObject:aResource];
		[self setValue:theResources forKey:@"resources"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:JournalDidAddResourceNotification
			object:self userInfo:[NSDictionary dictionaryWithObject:aResource forKey:@"resource"]];
		
		// save the resource
		[self saveResource:aResource];
		
		returnResource = aResource;
		
		//return YES;
	}
	else
	{
		returnResource = [[self valueForKey:@"resources"] objectAtIndex:resourceIndex];
		//return NO;
	}
	
	return returnResource;
}

#pragma mark -

- (BOOL) deleteEntry:(JournlerEntry*)anEntry
{	
	if ( anEntry == nil )
		return NO;
	
	BOOL success;
	[anEntry retain];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JournalWillDeleteEntryNotification 
			object:self userInfo:[NSDictionary dictionaryWithObject:anEntry forKey:@"entry"]];

	// remove the entries from this resource, relocating them if necessary
	NSArray *errors;
	if ( ![self removeResources:[anEntry resources] fromEntries:[NSArray arrayWithObject:anEntry] errors:&errors] )
	{
		// need a way of getting these entries to the user
		NSLog(@"%@ %s - there were problems removing the resource from entry %@", [self className], _cmd, [anEntry tagID]);
	}

	// path info for the physical delete
	NSString *full_path = [anEntry packagePath];
	
	// remove the file from searching
	[searchManager removeEntry:anEntry];
	
	// remove the file from any collections	-- recursively
	[_rootCollection removeEntry:anEntry considerChildren:YES];
	
	// physically delete the file
	success = ( [[NSFileManager defaultManager] removeFileAtPath:full_path handler:self] );

	// mark the entry as deleted in case its being held elsewhere
	[anEntry setValue:BooleanNumber(YES) forKey:@"deleted"];
	
	// mark the entries resources as being deleted
	//[[anEntry valueForKey:@"resources"] setValue:[NSNumber numberWithBool:YES] forKey:@"deleted"];
	
	// remove the entry from the dictionary
	[_entriesDic removeObjectForKey:[anEntry valueForKey:@"tagID"]];
	
	// remove the entry from the entries array
	NSMutableArray *tempEntries = [[[self entries] mutableCopyWithZone:[self zone]] autorelease];
	[tempEntries removeObjectIdenticalTo:anEntry];
	[self setEntries:tempEntries];
	
	// remove any tags that are not longer being used
	if ( [[anEntry valueForKey:@"tags"] count] != 0 )
	{
		NSSet *thisEntrysTags = [NSSet setWithArray:[anEntry valueForKey:@"tags"]];
				
		NSString *aTag;
		NSEnumerator *enumerator = [thisEntrysTags objectEnumerator];
		
		while ( aTag = [[enumerator nextObject] lowercaseString] )
		{
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%@ in tags.lowercaseString AND markedForTrash == NO",aTag];
			if ( [[[self entries] filteredArrayUsingPredicate:predicate] count] == 0 )
				[entryTags removeObject:aTag];
		}
		
		//NSLog([entryTags description]);
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JournalDidDeleteEntryNotification 
			object:self userInfo:[NSDictionary dictionaryWithObject:anEntry forKey:@"entry"]];
	
	// release the entry now that we're finished
	[anEntry release];
	
	return success;
}

- (BOOL) deleteResource:(JournlerResource*)aResource
{
	if ( aResource == nil )
		return NO;
	
	BOOL success = YES;
	[aResource retain];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JournalWillDeleteResourceNotificiation 
			object:self userInfo:[NSDictionary dictionaryWithObject:aResource forKey:@"resource"]];
	
	// remove the resource from the search index
	[[self searchManager] removeResource:aResource owner:[aResource valueForKey:@"entry"]];
	
	// remove the resource from the entry
	[[aResource valueForKey:@"entry"] removeResource:aResource];
	
	if ( [aResource representsFile] )
	{
		// if the resource is file based, delete it
		if ( [[NSFileManager defaultManager] fileExistsAtPath:[aResource path]] 
			&& ![[NSFileManager defaultManager] removeFileAtPath:[aResource path] handler:self] )
		{
			success = NO;
			NSLog(@"%@ %s - problem removing file based resource at path %@", [self className], _cmd, [aResource path]);
		}
		
		if ( [[NSFileManager defaultManager] fileExistsAtPath:[aResource _pathForFileThumbnail]] 
				&& ![[NSFileManager defaultManager] removeFileAtPath:[aResource _pathForFileThumbnail] handler:self] )
		{
			NSLog(@"%@ %s - problem removing icon for file based resource at path %@", [self className], _cmd, [aResource path]);
		}
	}
	else if ( [aResource representsJournlerObject] )
	{
		#warning if the resource is a link to another entry, delete the reverse link?
		NSURL *uri = [NSURL URLWithString:[aResource valueForKey:@"uriString"]];
		if ( [uri isJournlerEntry] )
		{
			JournlerEntry *theReverseEntry = [self objectForURIRepresentation:uri];
			if ( theReverseEntry == nil )
			{
				NSLog(@"%@ %s - error deriving entry for reverse link delete", [self className], _cmd);
			}
			else
			{
				NSString *myEntryURIString = [[[aResource valueForKey:@"entry"] URIRepresentation] absoluteString];
				
				JournlerResource *aReverseResource;
				NSEnumerator *reverseEntryResourceEnumerator = [[theReverseEntry valueForKey:@"resources"] objectEnumerator];
				
				while ( aReverseResource = [reverseEntryResourceEnumerator nextObject] )
				{
					if ( [aReverseResource representsJournlerObject] && 
							[myEntryURIString isEqualToString:[aReverseResource valueForKey:@"uriString"]] )
					{
						
						[aReverseResource retain];
						
						// remove the reverse resource from the journal
						[resources removeObject:aReverseResource];
						[resourcesDic removeObjectForKey:[aReverseResource valueForKey:@"tagID"]];
						
						// remove the reverse resource from the entry
						[theReverseEntry removeResource:aReverseResource];
						
						[aReverseResource release];
						break;
					}
				}
			}
		}
	}
	
	// and actually delete the resoure file in the resources directory
	NSString *journalResourcePath = [[self resourcesPath] stringByAppendingPathComponent:
	[NSString stringWithFormat:@"%@.jresource", [aResource tagID]]];
	
	if ( [[NSFileManager defaultManager] fileExistsAtPath:journalResourcePath] 
			&& ![[NSFileManager defaultManager] removeFileAtPath:journalResourcePath handler:self] )
		NSLog(@"%@ %s - problem deleting the physical representation of the resource at %@", [self className], _cmd, journalResourcePath);
	
	// mark the entry as deleted
	[aResource setValue:BooleanNumber(YES) forKey:@"deleted"];
	
	// remove the resource from the dictionary
	[resourcesDic removeObjectForKey:[aResource valueForKey:@"tagID"]];
	
	// remove the resource from the array
	NSMutableArray *tempResources = [[[self resources] mutableCopyWithZone:[self zone]] autorelease];
	[tempResources removeObjectIdenticalTo:aResource];
	[self setResources:tempResources];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JournalDidDeleteResourceNotification 
			object:self userInfo:[NSDictionary dictionaryWithObject:aResource forKey:@"resource"]];
	
	[aResource release];
	return success;
}

- (BOOL) deleteCollection:(JournlerCollection*)collection deleteChildren:(BOOL)children 
{
	if ( collection == nil )
		return NO;
	
	BOOL success = YES;
	[collection retain];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JournalWillDeleteFolderNotification 
			object:self userInfo:[NSDictionary dictionaryWithObject:collection forKey:@"folder"]];
	
	// first the children
	if ( children ) 
	{
		int i;
		NSArray *kids = [[[collection children] copyWithZone:[self zone]] autorelease];
		for ( i = 0; i < [kids count]; i++ )
			[self deleteCollection:[kids objectAtIndex:i] deleteChildren:YES];
	}
	
	// get the collections path
	NSString *fullPath = [[self collectionsPath] 
			stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jcol", [collection valueForKey:@"tagID"]]];
		
	// remove the collection from its parent
	JournlerCollection *parentNode = [(JournlerCollection*)collection parent];
	if ( parentNode != nil )
		[(JournlerCollection*)parentNode removeChild:collection recursively:NO];
	
	// remove the collection each of its entries - should this be performed in the collections dealloc?
	int i;
	NSArray *entries = [collection valueForKey:@"entries"];
	for ( i = 0; i < [entries count]; i++ )
	{
		NSMutableArray *collections = [[[[entries objectAtIndex:i] valueForKey:@"collections"] 
				mutableCopyWithZone:[self zone]] autorelease];
		[collections removeObject:collection];
		[[entries objectAtIndex:i] setValue:collections forKey:@"collections"];
	}
	
	// remove the collection from the computer
	if ( fullPath )
		success = [[NSFileManager defaultManager] removeFileAtPath:fullPath handler:self];
	else
		success = NO;
	
	// mark the collection as deleted in case anyone is still holding on to it
	[collection setValue:BooleanNumber(YES) forKey:@"deleted"];
	
	// remove the collection from the dictionary and the array
	[_collectionsDic removeObjectForKey:[collection tagID]];
	
	// remove the collections from the array
	NSMutableArray *tempCollections = [[[self collections] mutableCopyWithZone:[self zone]] autorelease];
	[tempCollections removeObjectIdenticalTo:collection];
	[self setCollections:tempCollections];
	
	// reset the root folders
	[self setRootFolders:tempCollections];
	
	//[_collections removeObjectIdenticalTo:collection];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JournalDidDeleteFolderNotification 
			object:self userInfo:[NSDictionary dictionaryWithObject:collection forKey:@"folder"]];
	
	// an release it
	[collection release];
	
	return success;
}

- (BOOL) deleteBlog:(BlogPref*)aBlog
{
	if ( aBlog == nil )
		return NO;
	
	[aBlog retain];
	
	// make sure the blog exists to be removed
	if ( [_blogs indexOfObjectIdenticalTo:aBlog] == NSNotFound ) 
		return NO;
		
	[[NSNotificationCenter defaultCenter] postNotificationName:JournalWillDeleteBlogNotification
			object:self userInfo:[NSDictionary dictionaryWithObject:aBlog forKey:@"blog"]];
	
	// remove the keychain information
	NSString *keychainUserName = [NSString stringWithFormat:@"%@-%@-%@", [aBlog blogType], [aBlog name], [aBlog login]];

	if ( [AGKeychain checkForExistanceOfKeychainItem:@"NameJournlerKey" 
			withItemKind:@"BlogPassword" forUsername:keychainUserName] ) {
		
		[AGKeychain deleteKeychainItem:@"NameJournlerKey" withItemKind:@"BlogPassword" forUsername:keychainUserName];
	
	}

	// physically delete the blog
	NSString *path = [[self blogsPath] stringByAppendingPathComponent:
			[NSString stringWithFormat:@"%@.jblog", [aBlog valueForKey:@"tagID"]]];

	if ( [[NSFileManager defaultManager] fileExistsAtPath:path] ) {
		if ( ![[NSFileManager defaultManager] removeFileAtPath:path handler:self] )
			NSLog(@"%@ %s - trouble removing blog at path %@", [self className], _cmd, path);
	}
	
	// update the dictionary
	[_blogsDic removeObjectForKey:[aBlog tagID]];

	// remove the blog from the array
	NSMutableArray *temp = [[[self blogs] mutableCopyWithZone:[self zone]] autorelease];
	[temp removeObject:aBlog];
	[self setBlogs:temp];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JournalDidDeleteBlogNotification
			object:self userInfo:[NSDictionary dictionaryWithObject:aBlog forKey:@"blog"]];
	
	[aBlog release];
	
	return YES;
}

#pragma mark -
#pragma mark Resource <-> Entry Utilities

- (JournlerEntry*) bestOwnerForResource:(JournlerResource*)aResource
{
	// finds the best possible entry owner for the resource in question
	// returns nil if none is available
	
	JournlerEntry *bestOwner = nil;
	
	if ( [aResource entry] != nil )
		bestOwner = [aResource entry];
		// ideally the resource already has an owning entry - that would be the best one
	
	else
	{
		if ( [aResource representsFile] )
		{
			// take one course of action if the resource represents a file - associate it with the entry where that file actually is
			
			// first have a look at any entries still registed with the resource
			NSArray *allOwners = [aResource entries];
			
			JournlerEntry *anEntry;
			NSEnumerator *entryEnumerator = [allOwners objectEnumerator];
			
			while ( anEntry = [entryEnumerator nextObject] )
			{
				if ( [anEntry resourcesIncludeFile:[aResource filename]] )
				{
					bestOwner = anEntry;
					// the file represented by this resource is contained in this entry, re-attach it
					break;
				}
			}
			
			// at this point, bestOwner could still be nil, so go through the entire journal looking for an entry
			
			entryEnumerator = [[self entries] objectEnumerator];
			
			while ( anEntry = [entryEnumerator nextObject] )
			{
				if ( [anEntry resourcesIncludeFile:[aResource filename]] )
				{
					bestOwner = anEntry;
					// the file represented by this resource is contained in this entry, re-attach it
					break;
				}
			}
			
			// the bestOwner could still be nil, in which case the resource is lost
			// recovery options include a spotlight search, narrowed to the uti type and filename
		}
		
		else
		{
			// simpler, take the first available entry
			NSArray *allOwners = [aResource entries];
			
			if ( [allOwners count] > 0 )
				bestOwner = [allOwners objectAtIndex:0];
				// just take the first available owner
				
			else
			{
				// the resource isn't seeing any other owners, so comb the entries looking for one that might contain this resource
				
				JournlerEntry *anEntry;
				NSEnumerator *entryEnumerator = [[self entries] objectEnumerator];
				
				while ( anEntry = [entryEnumerator nextObject] )
				{
					if ( [[anEntry resources] containsObject:aResource] )
					{
						bestOwner = anEntry;
						// the entry has not lost the resource relationship - re-attach the resource to the entry
						break;
					}
				}
				
				// its possible best owner could still be nil at this point, in which case the resource really is lost
			}
		}
	}
	
	return bestOwner;
}

- (JournlerResource*) alreadyExistingResourceWithType:(JournlerResourceType)type data:(id)anObject operation:(NewResourceCommand)command
{
	// looks at the data and attempts to find an already existing resource that matches it.
	// uses predicate filtering
	
	NSString *typeString = nil;
	NSArray *potentialMatches = nil;
	JournlerResource *matchingResource = nil;
	
	NSPredicate *dataPredicate = nil;
	NSPredicate *typePredicate = [NSPredicate predicateWithFormat:@"type == %i", type];
	NSPredicate *combinedPredicate = nil;
	
	// build the predicates
	switch ( type )
	{
	case kResourceTypeABRecord:
		if ( [anObject isKindOfClass:[NSString class]] )
		{
			typeString = @"AB Contact";
			//dataPredicate = [NSPredicate predicateWithFormat:@"uniqueId MATCHES %@", anObject];
			dataPredicate = [NSPredicate predicateWithFormat:@"uniqueId == %@", anObject];
		}
		break;
	
	case kResourceTypeURL:
		if ( [anObject isKindOfClass:[NSString class]] )
		{
			typeString = @"URL";
			//dataPredicate = [NSPredicate predicateWithFormat:@"urlString MATCHES %@", anObject];
			dataPredicate = [NSPredicate predicateWithFormat:@"urlString == %@", anObject];
		}
		break;
	
	case kResourceTypeJournlerObject:
		if ( [anObject isKindOfClass:[NSString class]] )
		{
			typeString = @"Internal Link";
			//dataPredicate = [NSPredicate predicateWithFormat:@"uriString MATCHES %@", anObject];
			dataPredicate = [NSPredicate predicateWithFormat:@"uriString == %@", anObject];
		}
		break;
	
	case kResourceTypeFile:
		if ( [anObject isKindOfClass:[NSString class]] )
		{
			typeString = @"File";
			//dataPredicate = [NSPredicate predicateWithFormat:@"filename MATCHES %@", [anObject lastPathComponent]];
			//dataPredicate = [NSPredicate predicateWithFormat:@"originalPath MATCHES %@", anObject];
			dataPredicate = [NSPredicate predicateWithFormat:@"originalPath == %@", anObject];
		}
		break;
	}
	
	// bail if either of the predicates could not be established
	if ( dataPredicate == nil || typePredicate == nil )
		goto bail;
	
	// for contacts, urls and journler objects a simple match is enough
	// for files a path match is also required, so check the original path on any returns
	
	combinedPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:typePredicate, dataPredicate, nil]];
	potentialMatches = [[self resources] filteredArrayUsingPredicate:combinedPredicate];
	
	if ( [potentialMatches count] == 0 )
		goto bail;
	
	if ( type == kResourceTypeABRecord || type == kResourceTypeURL || type == kResourceTypeJournlerObject )
		matchingResource = [potentialMatches objectAtIndex:0];
	
	else if ( type == kResourceTypeFile )
	{
		JournlerResource *aResource;
		NSEnumerator *enumerator = [potentialMatches objectEnumerator];
		
		while ( aResource = [enumerator nextObject] )
		{
			if ( [[aResource originalPath] isEqualToString:anObject] 
					&& ( ( [aResource isAlias] && command == kNewResourceForceLink ) || ( ![aResource isAlias] && command == kNewResourceForceCopy ) ) )
			{
				// unlike the other resource queries, make sure the alias vs copy matches
				matchingResource = aResource;
				break;
			}
		}
	}
	
	// and finally, note that a resources matching the conditions was found
	// also note if there was a potential file match but none used - it would be cool if the user could request that one be used
	
bail:
	
	if ( matchingResource == nil )
	{
		[activity appendFormat:@"No matching resource found for new media, creating new resource.\n\t-- Media Type: %@\n\t-- Information: %@\n", typeString, anObject];
		if ( type == kResourceTypeFile && [potentialMatches count] > 0 )
		{
			[activity appendFormat:@"There were potential matches for the new resources.\n"];
			
			JournlerResource *aResource;
			NSEnumerator *enumerator = [potentialMatches objectEnumerator];
			
			while ( aResource = [enumerator nextObject] )
				[activity appendFormat:@"\t-- Name: %@\n\t-- ID: %@\n\t-- Path: %@\n", [aResource title], [aResource tagID], [aResource originalPath]];
		}
	}
	else
	{
		[activity appendFormat:@"Matching resource found for new media, using previously created resource.\n\t-- Media Type: %@\n\t-- Information: %@\n\t --Resource Name: %@\n\t-- Resource ID: %@\n", typeString, anObject, [matchingResource valueForKey:@"title"], [matchingResource valueForKey:@"tagID"]];
	}
	
	[self setActivity:activity];
	
	return matchingResource;
}

- (BOOL) removeResources:(NSArray*)resourceArray fromEntries:(NSArray*)entriesArray errors:(NSArray**)errorsArray
{
	// resources are removed from the listed entries
	// if the entry is the resources owner, the resource is moved to a different owner
	// note that when an entry is deleted, resources must also be moved around
	
	BOOL success = YES;
	
	#ifdef __DEBUG__
	NSLog(@"%@ %s", [self className], _cmd);
	#endif
	
	JournlerResource *aResource;
	NSEnumerator *resourceEnumerator = [resourceArray objectEnumerator];
	
	while ( aResource = [resourceEnumerator nextObject] )
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		if ( [[aResource entries] containsAnObjectInArray:entriesArray] )
		{
			NSMutableArray *resourcesEntries = [[[aResource entries] mutableCopyWithZone:[self zone]] autorelease];
			
			// remove the entries from the resource - the resource -> entry relationship must change first
			[resourcesEntries removeObjectsInArray:entriesArray];
			[aResource setEntries:resourcesEntries];
			
			// remove the resource from each entry in the array
			[entriesArray makeObjectsPerformSelector:@selector(removeResource:) withObject:aResource];
			
			// check to make sure the resource's parent is still in the entries list
			if ( ![resourcesEntries containsObject:[aResource entry]] )
			{
				[activity appendFormat:@"Resource no longer belongs to parent, taking action...\n\t-- Name: %@\n\t-- ID: %@\n", [aResource title], [aResource tagID]];
				
				// if the resources has no more entries, delete it
				if ( [resourcesEntries count] == 0 )
				{
					[activity appendString:@"Resource no longer belongs to any entries, deleting it\n"];
					
					#ifdef __DEBUG__
					NSLog(@"%@ %s - resource %@ no longer belongs to any entries, deleting it", [self className], _cmd, [aResource tagID]);
					#endif
				
					[self deleteResource:aResource];
				}
				else
				{
					// move the resource to the first other entry
					JournlerEntry *oldParent = [aResource entry];
					JournlerEntry *newParent = [resourcesEntries objectAtIndex:0];
					
					if ( [aResource representsFile] )
					{
						// the resource must be moved - here is the possibility for errors
						NSString *oldPath = [aResource path];
						NSString *oldFilename = [aResource filename];
						
						NSString *newPathDirectory = [newParent resourcesPathCreating:YES];
						if ( newPathDirectory == nil )
						{
							success = NO;
							[activity appendFormat:@"** Moving resource to new entry, but there was a problem creating the new destination directory...\n\t-- Destination Entry: %@\n\t-- Destination ID: %@\n", [newParent title], [newParent tagID]];
							
							NSLog(@"%@ %s - problem creating resource directory for entry %@ to move entry %@",
							[self className], _cmd, [newParent tagID], [aResource tagID]);
						}
						else
						{
							// derive a new target for the file
							NSString *newPath = [[newPathDirectory stringByAppendingPathComponent:oldFilename] pathWithoutOverwritingSelf];
							NSString *newFilename = [newPath lastPathComponent];
							
							#ifdef __DEBUG__
							NSLog(@"%@ %s - moving resource %@ from %@ to %@", [self className], _cmd, [aResource tagID], oldPath, newPath);
							#endif
							
							if ( [[NSFileManager defaultManager] movePath:oldPath toPath:newPath handler:self] )
							{
								// remove the icon representation
								if ( [[NSFileManager defaultManager] fileExistsAtPath:[aResource _pathForFileThumbnail]] )
									[[NSFileManager defaultManager] removeFileAtPath:[aResource _pathForFileThumbnail] handler:self];
								
								// re-parent the resource
								[aResource setEntry:newParent];
								
								// the resource takes on the filename available at its new location (could have changed)
								[aResource setFilename:newFilename];
								
								// log the changes
								[activity appendFormat:@"Successfully moved resource to new parent...\n\t-- Destination Entry: %@\n\t-- Destination ID: %@\n", [newParent title], [newParent tagID]];
							}
							else
							{
								// problem making the move
								success = NO;
								
								[activity appendFormat:@"** There was a problem moving the entry to a new parent...\n\t-- Old Parent: %@\n\t-- Old Parent ID: %@\n\t-- Destination Entry: %@\n\t-- Destination ID: %@\n", [oldParent title], [oldParent tagID], [newParent title], [newParent tagID]];
								
								NSLog(@"%@ %s - problem moving resource %@ from %@ to %@", [self className], _cmd, [aResource tagID], oldPath, newPath);
								
								// set the resource back in the entry
								[[aResource entry] addResource:aResource];
							}
						}
					}
					
					else
					{
						// easy - just re-parent the resource
						[aResource setEntry:newParent];
						
						// log the changes
						[activity appendFormat:@"Successfully moved resource to new parent...\n\t-- Destination Entry: %@\n\t-- Destination ID: %@\n", [newParent title], [newParent tagID]];
					}
					
					#ifdef __DEBUG__
					NSLog(@"%@ %s - moved resource %@ from entry %@ to entry %@", [self className], _cmd, [aResource tagID], [oldParent tagID], [newParent tagID]);
					#endif
					
					// save the resource
					if ( ![self saveResource:aResource] )
					{
						success = NO;
						NSLog(@"%@ %s - problem saving resource %@ after changing its parent to entry %@",
						[self className], _cmd, [aResource tagID], [newParent tagID]);
					}
					
				}
			}
		}
				
		[pool release];
	}
	
	// save all of the entries
	JournlerEntry *anEntry;
	NSEnumerator *entrySaveEnumerator = [entriesArray objectEnumerator];
	
	while ( anEntry = [entrySaveEnumerator nextObject] )
	{
		if ( ![self saveEntry:anEntry] )
		{
			success = NO;
			NSLog(@"%@ %s - problem saving entry %@", [self className], _cmd, [anEntry tagID]);
		}
	}
	
	// note the activity
	[self setActivity:activity];
	
	return success;
}

#pragma mark -

- (EntrySaveOptions) saveEntryOptions
{
	return saveEntryOptions;
}

- (void) setSaveEntryOptions:(EntrySaveOptions)options
{
	saveEntryOptions = options;
}

#pragma mark -
#pragma mark File Manager Delegation

- (BOOL)fileManager:(NSFileManager *)manager shouldProceedAfterError:(NSDictionary *)errorInfo 
{
	NSLog(@"\n%@ %s - Encountered file manager error: source = %@, error = %@, destination = %@\n", [self className], _cmd,
			[errorInfo objectForKey:@"Path"], [errorInfo objectForKey:@"Error"], [errorInfo objectForKey:@"ToPath"]);
	
	return NO;
	
}

- (void)fileManager:(NSFileManager *)manager willProcessPath:(NSString *)path 
{
	// for consistency. method does nothing
}

#pragma mark -
#pragma mark memory management

- (void) checkMemoryUse:(id)anObject
{
	#ifdef __DEBUG__
	NSLog(@"%@ %s",[self className],_cmd);
	#endif
	
	// run this in the background
	[NSThread detachNewThreadSelector:@selector(_checkMemoryUse:) toTarget:self withObject:anObject];
}

- (void) _checkMemoryUse:(id)anObject
{
	// the deal:
	// every ten minutes check every object for its last content access
	// if that last access occurred longer than ten minutes ago, and there is no interface lock, release the content
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	int i;
	NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
	
	// do not index or collect entries, which should already be indexed and collected
	int lastSaveOptions = [self saveEntryOptions];
	[self setSaveEntryOptions:(kEntrySaveDoNotIndex|kEntrySaveDoNotCollect)];
	
	// or if any of the managed objects are dirty
	for ( i = 0; i < CFArrayGetCount((CFArrayRef)_entries); i++ )
	{
		JournlerEntry *anEntry = (JournlerEntry*)CFArrayGetValueAtIndex((CFArrayRef)_entries,i);
		NSTimeInterval lastContentAccess = [anEntry lastContentAccess];
		
		if ( lastContentAccess != 0 && (currentTime - lastContentAccess) > (10*60) && [anEntry contentRetainCount] <= 0 
		&& [anEntry attributedContentIfLoaded] != nil )
		{
			#ifdef __DEBUG__
			NSLog(@"%@ %s - releasing the content for entry %@-%@", [self className], _cmd, [anEntry tagID], [anEntry title]);
			#endif
			
			// save the entry if it is dirty
			if ( [[anEntry dirty] boolValue] )
				[self saveEntry:anEntry];
			
			// unload the content from memory
			[anEntry unloadAttributedContent];
		}
	}

	for ( i = 0; i < CFArrayGetCount((CFArrayRef)resources); i++ )
	{
		JournlerResource *aResource = (JournlerResource*)CFArrayGetValueAtIndex((CFArrayRef)resources,i);
		NSTimeInterval lastPreviewAccess = [aResource lastPreviewAccess];
		
		if ( lastPreviewAccess != 0 && (currentTime - lastPreviewAccess) > (10*60) && [aResource previewRetainCount] <= 0 
		&& [aResource previewIfLoaded] != nil )
		{
			#ifdef __DEBUG__
			NSLog(@"%@ %s - releasing the content for entry %@-%@", [self className], _cmd, [aResource tagID], [aResource title]);
			#endif
			
			// save the resource if it is dirty - not necessary
			//if ( [[aResource dirty] boolValue] )
			//	[self saveResource:anEntry];
			
			[aResource unloadPreview];
		}
	}
	
	// reset the save entry options
	[self setSaveEntryOptions:lastSaveOptions];
	
	[pool release];
}

- (void) checkForModifiedResources:(id)anObject
{
	[NSThread detachNewThreadSelector:@selector(_checkForModifiedResources:) toTarget:self withObject:nil];
}

- (void) _checkForModifiedResources:(id)anObject
{
	// check the date modified for the file resources against what I have
	// if different, reload icon and re-index.
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSFileManager *fm = [NSFileManager defaultManager];
	
	JournlerResource *aResource;
	NSEnumerator *enumerator = [[self resources] objectEnumerator];
	
	#ifdef __DEBUG__
	NSLog(@"%@ %s - beginning at %@",[self className],_cmd,[NSDate date]);
	#endif
	
	while ( aResource = [enumerator nextObject] )
	{
		if ( [aResource representsFile] )
		{
			NSString *path = [aResource originalPath];
			if ( path != nil )
			{
				NSDictionary *fileAttributes = [fm fileAttributesAtPath:path traverseLink:YES];
				
				NSDate *savedDateModified = [aResource valueForKey:@"underlyingModificationDate"];
				NSDate *actualDateModified = [fileAttributes objectForKey:NSFileModificationDate];
				
				if ( savedDateModified != nil && actualDateModified != nil 
				&& [savedDateModified compare:actualDateModified] == NSOrderedAscending )
				{
					#ifdef __DEBUG__
					NSLog(@"%@ %s - resource has been modified, path %@", [self className], _cmd, path);
					#endif
					
					[aResource reloadIcon];
					[aResource setValue:actualDateModified forKey:@"underlyingModificationDate"];
					//[aResource setValue:nil forKey:@"icon"];
					
					[[self searchManager] indexResource:aResource owner:[aResource valueForKey:@"entry"]];
				}
			}
		}
	}
	
	#ifdef __DEBUG__
	NSLog(@"%@ %s - ending at %@",[self className],_cmd,[NSDate date]);
	#endif
	
	[pool release];
}

@end

#pragma mark -

@implementation JournlerJournal (JournlerScripting)


- (id) owner 
{ 
	return owner; 
}

- (void) setOwner:(id)owningObject 
{
	owner = owningObject;
}

@end
