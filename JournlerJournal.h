/* JournlerJournal */

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
#import <Security/Security.h>

#import "JournlerResource.h"

#define PDJournalPropertiesLoc		@"Journler.plist"
#define PDJournalStoreLoc			@"JournlerStore.dict"

#define PDEntriesLoc				@"Journler Entries"
#define PDCollectionsLoc			@"Collections"
#define PDJournalBlogsLoc			@"Blogs"
#define PDJournalResourcesLocation	@"Resources"
#define PDJournalDropBoxLocation	@"Journler Drop Box"

#define PDJournalImagesLoc			@"Images"
#define	PDAudioLoc					@"Audio Recordings"
#define PDVideoLoc					@"Video Recordings"

#define PDJournalBookmarksLoc		@"Bookmarks"
#define PDJournalWebArchivesLoc		@"WebArchives"
#define PDJournalPDFDocsLoc			@"PDFDocuments"

#define	PDJournalPasswordProtectedLoc @".journalProtected"
#define PDJournalWordListLoc		@"Auto-Correct Word List.csv"

//Deprecated
//#define		supportPath				@"/Library/Application Support/Journler/"

#define PDJournalIdentifier			@"JournalID"
#define	PDJournalVersion			@"Version"
#define	PDJournalBlogs				@"Blogs"
#define PDJournalTitle				@"Title"
#define PDJournalCategories			@"Categories"
#define PDJournalCollections		@"Collections"
#define PDJournalEncryptionState	@"PDJournalEncryptionState"
#define PDJournalEncrypted			@"PDJournalEncrypted"
#define PDJournalMainWindowState	@"PDJournalMainWindowState"
#define PDJournalProperShutDown		@"PDJournalProperShutDown"

#define JournalWillAddEntryNotification			@"JournalWillAddEntryNotification"
#define JournalDidAddEntryNotification			@"JournalDidAddEntryNotification"

#define JournalWillDeleteEntryNotification		@"JournalWillDeleteEntryNotification"
#define JournalDidDeleteEntryNotification		@"JournalDidDeleteEntryNotification"


#define JournalWillAddFolderNotification		@"JournalWillAddFolderNotification"
#define JournalDidAddFolderNotification			@"JournalDidAddFolderNotification"

#define JournalWillDeleteFolderNotification		@"JournalWillDeleteFolderNotification"
#define JournalDidDeleteFolderNotification		@"JournalDidDeleteFolderNotification"


#define JournalWillAddResourceNotificiation		@"JournalWillAddResourceNotificiation"
#define JournalDidAddResourceNotification		@"JournalDidAddResourceNotification"

#define JournalWillDeleteResourceNotificiation	@"JournalWillDeleteResourceNotificiation"
#define JournalDidDeleteResourceNotification	@"JournalDidDeleteResourceNotification"


#define JournalWillAddBlogNotification			@"JournalWillAddBlogNotification"
#define JournalDidAddBlogNotification			@"JournalDidAddBlogNotification"

#define JournalWillDeleteBlogNotification		@"JournalWillDeleteBlogNotification"
#define JournalDidDeleteBlogNotification		@"JournalDidDeleteBlogNotification"


#define JournalWillTrashEntryNotification		@"JournalWillTrashEntryNotification"
#define JournalDidTrashEntryNotification		@"JournalDidTrashEntryNotification"

#define JournalWillUntrashEntryNotification		@"JournalWillUntrashEntryNotification"
#define JournalDidUntrashEntryNotification		@"JournalDidUntrashEntryNotification"


typedef enum {
	
	PDEncryptionNone = 0,
	PDEncryptionJournal = 1,
	PDEncryptionEntry = 2
} JournalEncryptionOption;

typedef UInt32 EntrySaveOptions;
enum EntrySaveOperation {
	kEntrySaveIndexAndCollect = 0,
	kEntrySaveDoNotIndex = 1 << 1,
	kEntrySaveDoNotCollect = 1 << 2
};

typedef UInt32 JournalLoadFlag;
enum JournalLoadNotes {
	kJournalLoadedNormally = 0,
	kJournalUpgraded = 1 << 1,
	kJournalCrashed = 1 << 2,
	kJournalCouldNotLoad = 1 << 3,
	kJournalNoSearchIndex = 1 << 4,
	kJournalPathInitErrors = 1 << 5,
	kJournalWantsUpgrade = 1 << 6
};

typedef enum {
	PDJournalNoError = 0,
	PDNoJournalAtPath = 1 << 1,
	PDJournalFormatTooOld = 1 << 2,
	PDEncryptedAtUgrade = 1 << 3,
	PDUnreadableProperties = 1 << 4,
	PDJournalNoSearchIndexError = 1 << 5,
	PDJournalStoreAndPathFailure = 1 << 6,
	
	kJournalWants250Upgrade = 1 << 7,
	
} JournalLoadNotesDetails;

@class JournlerEntry;
@class JournlerResource;
@class JournlerCollection;
@class BlogPref;

@class JournlerIndexServer;
@class JournlerSearchManager;

@interface JournlerJournal : NSObject
{
		
	//version 1.0.2 changes
	NSMutableDictionary	*_properties;
	
	// arrays stored the objects for the controllers
	NSMutableArray *_entries;
	NSMutableArray	*_collections;
	NSMutableArray *_blogs;
	NSMutableArray *resources;
	
	// dictionaries store the objects for a quick lookup
	NSMutableDictionary	*_entriesDic;
	NSMutableDictionary	*_collectionsDic;
	NSMutableDictionary *_blogsDic;
	NSMutableDictionary *resourcesDic;
	
	NSMutableDictionary *entryWikis;
	NSMutableSet		*entryTags;
	
	NSNumber *dirty;
	
	//
	// version 1.2 addition
	JournlerCollection	*_rootCollection;
	JournlerCollection	*_libraryCollection;
	JournlerCollection	*_trashCollection;
	
	// version 1.0.3 additions (collections and internal searching)
	JournlerSearchManager	*searchManager;
	JournlerIndexServer		*indexServer;
	
	//to keep track of our entries in the simplest way possible
	NSInteger lastTag;
	NSInteger lastFolderTag;
	NSInteger lastBlogTag;
	NSInteger lastResourceTag;
	
	//internal usage
	BOOL	_loaded;
	NSInteger error;
	
	// encyrption (v1.0.3)
	NSString			*password;
	//CSSM_CSP_HANDLE	_cspHandle;
	
	BOOL				_keySchonGenerated;
	//CSSM_KEY			_generatedKey;
	
	//
	// SCRIPTABILITY changes
	id owner;
	
	BOOL _do_not_index_and_collect;
	EntrySaveOptions saveEntryOptions;
	
	NSString *_journalPath;
	
	NSMutableArray *initErrors;
	NSMutableString *activity;
	
	// checks the entry content last accessed and releases attributed content that hasn't been used for a while
	NSTimer *contentMemoryManagerTimer;
}

+ (JournlerJournal*) sharedJournal;
+ (JournlerJournal*) defaultJournal:(NSError**)error;
+ (NSString*) defaultJournalPath;

//loading entries and topics into the model
- (JournalLoadFlag) loadFromPath:(NSString*)path error:(NSInteger*)err;
- (JournalLoadFlag) loadFromStore:(NSInteger*)err;
- (JournalLoadFlag) loadFromDirectoryIgnoringEntryFolders:(BOOL)ignore210Entries error:(NSInteger*)err;

#pragma mark -


//bindings implementation --------------------

- (NSNumber*) version;
- (void) setVersion:(NSNumber*)newVersion;

- (NSNumber*) identifier;
- (void) setIdentifier:(NSNumber*)jid;

- (NSNumber*) shutDownProperly;
- (void) setShutDownProperly:(NSNumber*)aNumber;

- (NSNumber*) dirty;
- (void) setDirty:(NSNumber*)aNumber;

- (NSInteger) error;
- (void) setError:(NSInteger)err;

- (NSArray*) entries;
- (void) setEntries:(NSArray*)newEntries;

- (NSArray*) resources;
- (void) setResources:(NSArray*)newResources;

- (NSArray*) collections;
- (void) setCollections:(NSArray*)newCollections;

- (NSDictionary*) entriesDictionary;
- (NSDictionary*) collectionsDictionary;
- (NSDictionary*) blogsDictionary;
- (NSDictionary*) resourcesDictionary;
- (NSDictionary*) entryWikisDictionary;

- (NSSet*) entryTags;

- (NSString*) title;
- (void) setTitle:(NSString*)newObject;

- (NSArray*) categories;
- (void) setCategories:(NSArray*)newObject;

- (NSArray*) blogs;
- (void) setBlogs:(NSArray*)newObject;

- (NSData*) tabState;
- (void) setTabState:(NSData*)data;

- (NSDictionary*) properties;
- (void) setProperties:(NSDictionary*)newObject;

- (NSString*) journalPath;
- (void) setJournalPath:(NSString*)newObject;

- (NSString*) activity;
- (void) setActivity:(NSString*)aString;

- (NSArray*) initErrors;

- (BOOL) isLoaded;
- (void) setLoaded:(BOOL)loaded;

- (JournlerSearchManager*) searchManager;
- (JournlerIndexServer*) indexServer;

#pragma mark -

- (id) objectForURIRepresentation:(NSURL*)aURL;

- (void) entry:(JournlerEntry*)anEntry didChangeTitle:(NSString*)oldTitle;
- (void) entry:(JournlerEntry*)anEntry didChangeTags:(NSArray*)oldTags;

- (JournlerEntry*) entryForTagString:(NSString*)tagString;
- (JournlerEntry*) entryForTagID:(NSNumber*)tagNumber;

- (NSArray*) entriesForTagIDs:(NSArray*)tagIDs;
- (NSArray*) resourcesForTagIDs:(NSArray*)tagIDs;

- (JournlerEntry*) objectForTagString:(NSString*)tagString;

- (BlogPref*) blogForTagID:(NSNumber*)tagNumber;

//return a new entry or topic tag number
- (NSInteger) newEntryTag;
- (NSInteger) newFolderTag;
- (NSInteger) newBlogTag;
- (NSInteger) newResourceTag;

//for constructing the table of entries at a given date
- (BOOL) calIntHasEntries:(NSInteger)dayAsInt;

- (BOOL) writeJournalCollection:(id)collection;

- (void) saveProperties;
- (void) saveCollections;
- (void) saveBlogs;

// collections (v1.0.3)
- (void) updateIndexAndCollections:(id)object;

- (void) _updateIndex:(JournlerEntry*)entry;
- (void) _updateCollections:(JournlerEntry*)entry;

- (NSArray*) collectionsForTypeID:(NSInteger)type;

- (JournlerCollection*) libraryCollection;
- (JournlerCollection*) trashCollection;

// for entry editing, redating
- (void) addBlog:(BlogPref*)aBlog;
- (void) addEntry:(JournlerEntry*)entry;
- (void) addCollection:(JournlerCollection*)collection;
- (JournlerResource*) addResource:(JournlerResource*)aResource;

- (JournlerEntry*) bestOwnerForResource:(JournlerResource*)aResource;
- (JournlerResource*) alreadyExistingResourceWithType:(JournlerResourceType)type data:(id)anObject operation:(NewResourceCommand)command;
- (BOOL) removeResources:(NSArray*)resourceArray fromEntries:(NSArray*)entriesArray errors:(NSArray**)errorsArray;

// console utilities
- (BOOL) resetSearchManager;
- (BOOL) resetEntryDateModified;
- (BOOL) resetSmartFolders;
- (BOOL) createResourcesForLinkedFiles;
- (BOOL) updateJournlerResourceTitles;
- (BOOL) resetResourceText;
- (BOOL) resetRelativePaths;

- (NSArray*) orphanedResources;
- (BOOL) deleteOrphanedResources:(NSArray*)theResources;

// a 1.15 addition - trashing
- (void) markEntryForTrash:(JournlerEntry*)entry;
- (void) unmarkEntryForTrash:(JournlerEntry*)entry;

#pragma mark 1.2 Changes
// 1.2 changes

- (JournlerEntry*) unpackageEntryAtPath:(NSString*)filepath;
//- (BOOL) packageEntry:(JournlerEntry*)entry;

- (BOOL) archiveCollection:(JournlerCollection*)object location:(NSString*)path;
- (BOOL) archiveBlog:(BlogPref*)object location:(NSString*)path;

- (JournlerCollection*) unarchiveCollectionAtPath:(NSString*)path;
- (BlogPref*) unarchiveBlogAtPath:(NSString*)path;
- (JournlerResource*) unarchiveResourceAtPath:(NSString*)path;

- (JournlerCollection*) rootCollection;
- (void) setRootCollection:(JournlerCollection*)root;

// compatibility with XD implementation
- (NSArray*) rootFolders;
- (void) setRootFolders:(NSArray*)anArray;

- (JournlerCollection*) collectionForID:(NSNumber*)idTag;
- (NSArray*) collectionsForIDs:(NSArray*)tagIDs;

- (EntrySaveOptions) saveEntryOptions;
- (void) setSaveEntryOptions:(EntrySaveOptions)options;

- (NSString*) collectionsPath;
- (NSString*) entriesPath;
- (NSString*) blogsPath;
- (NSString*) resourcesPath;
- (NSString*) propertiesPath;
- (NSString*) storePath;
- (NSString*) dropBoxPath;

- (void) saveScriptChanges;
- (BOOL) performOneTwoMaintenance;

- (BOOL) journalIsDirty;

- (BOOL) save:(NSError**)error;
- (BOOL) saveEntry:(JournlerEntry*)entry;
- (BOOL) saveResource:(JournlerResource*)aResource;
- (BOOL) saveCollection:(JournlerCollection*)aCollection;
- (BOOL) saveCollection:(JournlerCollection*)aCollection saveChildren:(BOOL)recursive;
- (BOOL) saveBlog:(BlogPref*)aBlog;

- (BOOL) deleteEntry:(JournlerEntry*)anEntry;
- (BOOL) deleteResource:(JournlerResource*)aResource;
- (BOOL) deleteCollection:(JournlerCollection*)collection deleteChildren:(BOOL)children;
- (BOOL) deleteBlog:(BlogPref*)aBlog;

- (void) checkMemoryUse:(id)anObject;
- (void) _checkMemoryUse:(id)anObject;

- (void) checkForModifiedResources:(id)anObject;
- (void) _checkForModifiedResources:(id)anObject;

// DEPRECATED
- (NSNumber*) encrypted;
- (void) setEncrypted:(NSNumber*)aNumber;
// DEPRECATED
//- (CSSM_KEY) generatedKey;
//- (CSSM_CSP_HANDLE) cspHandle;
// DEPRECATED
- (void) addEntry:(JournlerEntry*)entry threaded:(BOOL)thread;
// DEPRECATED
- (NSNumber*) encryptionState;
- (void) setEncryptionState:(NSNumber*)state;
// DEPRECATED
- (NSString*) password;
- (void) setPassword:(NSString*)encryptionPassword;

//- (BOOL) deleteObject:(id)entry;

// DEPRECATED
- (NSURL*) urlForResourcePath:(NSString*)path entryID:(NSString*)entryTag;

@end

@interface JournlerJournal (JournlerScripting)

- (id) owner;
- (void) setOwner:(id)owningObject;

@end

@interface NSObject (JournalSpellChecking)

- (NSInteger) spellDocumentTag;

@end
