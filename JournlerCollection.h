//
//  JournlerCollection.h
//  Cocoa Journler
//
//  Created by Philip Dow on 08.08.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JournlerObject.h"

// collection type defintions
// ----------------------------------------------------------------------------------
#define PDCollectionTypeLibrary		@"01-Library"
#define PDCollectionTypeTrash		@"09-Trash"
#define PDCollectionTypeSmart		@"11-SmartFolder"
#define PDCollectionTypeFolder		@"21-Folder"

#define PDCollectionTypeIDLibrary		1
#define PDCollectionTypeIDTrash			50

#define PDCollectionTypeIDWriting		100
#define PDCollectionTypeIDImage			200
#define PDCollectionTypeIDAudio			300
#define PDCollectionTypeIDVideo			400
#define PDCollectionTypeIDDocuments		1000

#define PDCollectionTypeIDBookmark		500
#define PDCollectionTypeIDWebArchive	600
#define PDCollectionTypeIDPDF			700

#define PDCollectionTypeIDSmart			800
#define PDCollectionTypeIDFolder		900

#define PDCollectionTypeIDSeparator		-1

//
// 1.1 definitions
#define PDCollectionTag				@"tagID"
#define PDCollectionTitle			@"title"
#define PDCollectionType			@"type"
#define PDCollectionPreds			@"predicates"
#define PDCollectionComb			@"combinationStyle"
#define PDCollectionEntries			@"entries"

//
// 1.2 definitions
#define PDCollectionEntryIDs		@"entryIDs"
#define PDCollectionTypeID			@"typeID"

#define PDCollectionParentID		@"parentID"
#define PDCollectionParent			@"parent"

//#define PDCollectionEntryTableState	@"PDCollectionEntryTableState"
#define PDCollectionSortDescriptors	@"PDCollectionSortDescriptors"
#define PDCollectionLabel			@"PDCollectionLabel"

#define PDCollectionChildrenIDs		@"childrenIDs"
#define PDCollectionChildren		@"children"

#define PDCollectionImage			@"image"
#define PDCollectionImageSmall		@"imageSmall"

#define PDCollectionVersion			@"version"

#define PDCollectionIndex			@"index"

#define FolderWillAddEntryNotification			@"FolderWillAddEntryNotification"
#define FolderDidAddEntryNotification			@"FolderDidAddEntryNotification"

#define FolderWillRemoveEntryNotification		@"FolderWillRemoveEntryNotification"
#define FolderDidRemoveEntryNotification		@"FolderDidRemoveEntryNotification"

#define FolderWillBeginEvaluation				@"FolderWillBeginEvaluation"
#define FolderDidCompleteEvaluation				@"FolderDidCompleteEvaluation"



@class JournlerJournal;
@class JournlerEntry;

typedef enum {
	kJournlerFolderMenuDefaultSettings = 0,
	kJournlerFolderMenuIncludesEntries = 1 << 1,
	kJournlerFolderMenuUseLargeImages = 1 << 2
} JournlerFolderMenuRepresentationOptions;

@interface JournlerCollection : JournlerObject <NSCopying, NSCoding>
{
	
	NSArray *entries;
	NSArray *children;
	JournlerCollection *parent; // weak reference
	
	// cached predicate for smart folders
	NSPredicate *_actualPredicate;
	
	// dictionary of dynamically generated date conditions
	NSMutableDictionary *dynamicDatePredicates;
	
	BOOL isEvaluating;
	NSLock *entriesLock;
	
	NSInteger menuRepresentationOptions;
}

+ (JournlerCollection*) separatorFolder;

- (NSArray*) children;
- (void) setChildren: (NSArray*)anArray;

- (JournlerCollection*)parent;
- (void ) setParent:(JournlerCollection*)aCollection;

- (BOOL) isEvaluating;
- (void) setIsEvaluating:(BOOL)evaluating;

- (NSMutableArray*) childrenIDs;
- (void) setChildrenIDs: (NSArray*)theChildren;

- (NSNumber*) parentID;
- (void) setParentID:(NSNumber*)theParent;

- (NSArray*) sortDescriptors;
- (void) setSortDescriptors:(NSArray*)anArray;

//- (NSArray*) entryTableState;
//- (void) setEntryTableState:(NSArray*)anArray;

- (NSNumber*) label;
- (void) setLabel:(NSNumber*)aNumber;

- (void) clearOldProperties;

- (NSArray*) allConditions:(BOOL)grouped;

- (BOOL) autotagsKey:(NSString*)aKey;
- (BOOL) canAutotag:(JournlerEntry*)anEntry;
- (BOOL) autotagEntry:(JournlerEntry*)anEntry add:(BOOL)add;

// Accessors for the children
- (void) addChild:(JournlerCollection *)n;
- (void) addChild:(JournlerCollection*)n atIndex:(int)index;
- (void) removeChild:(JournlerCollection *)aFolder recursively:(BOOL)rFlag;
- (void) moveChild:(JournlerCollection *)aFolder toIndex:(unsigned int)anIndex;

- (int) childrenCount;
- (JournlerCollection *) childAtIndex:(int)i;

- (NSArray*) allChildren;

// Other properties
- (BOOL)expandable;

- (NSString*) pureType;

- (void) sortChildrenByIndex;

- (BOOL) generateDynamicDatePredicates:(BOOL)recursive;
- (void) invalidatePredicate:(BOOL)recursive;

- (NSString*) predicateString;
- (NSPredicate*) predicate;
- (NSPredicate*) effectivePredicate;

- (BOOL) evaluateAndAct:(id)object considerChildren:(BOOL)recursive;
- (void) _threadedEvaluateAndAct:(NSDictionary*)evalDict;

- (void) removeEntry:(JournlerEntry*)entry considerChildren:(BOOL)recursive;

- (NSMenu*) menuRepresentation:(id)target action:(SEL)aSelector smallImages:(BOOL)useSmallImages includeEntries:(BOOL)wEntries;
- (NSMenu*) undelegatedMenuRepresentation:(id)target action:(SEL)aSelector smallImages:(BOOL)useSmallImages includeEntries:(BOOL)wEntries;
- (BOOL) flatMenuRepresentation:(NSMenu**)aMenu target:(id)object action:(SEL)aSelector smallImages:(BOOL)useSmallImages inset:(int)level;

- (void) updateForTwoZero;

- (NSURL*) URIRepresentation;

// 1.2 changes -------------------
- (NSNumber*) typeID;
- (void) setTypeID:(NSNumber*)newType;

- (NSNumber*) version;
- (void) setVersion:(NSNumber*)newVersion;

// --------------------------------------

- (NSArray*) conditions;
- (void) setConditions:(NSArray*)newPredicates;

- (NSNumber*) combinationStyle;
- (void) setCombinationStyle:(NSNumber*)newStyle;

- (NSArray*) entries;
- (void) setEntries:(NSArray*)anArray;

// 1.2 changes -------------------
- (NSArray*) entryIDs;
- (void) setEntryIDs:(NSArray*)entries;

// utilities

- (NSImage*) determineIcon;
- (void) validateIcon;
+ (NSImage*) defaultImageForID:(int)type;

- (void) addEntry:(JournlerEntry*)entry;
- (void) removeEntry:(JournlerEntry*)entry;
- (BOOL) containsEntry:(JournlerEntry*)anEntry;

- (BOOL) isRegularFolder;
- (BOOL) isSmartFolder;
- (BOOL) isTrash;
- (BOOL) isLibrary;
- (BOOL) isSeparatorFolder;

- (BOOL) isDescendantOfFolder:(JournlerCollection*)node;
- (BOOL) isDescendantOfFolderInArray:(NSArray*)nodes;
- (BOOL) isMemberOfSmartFamilyConsideringSelf:(BOOL)includeSelf;

- (void) deepCopyChildrenToFolder:(JournlerCollection*)aFolder;

- (NSNumber*) index;
- (void) setIndex:(NSNumber*)index;

- (NSString*) packagePath;
- (NSString*) pathSafeTitle;
- (BOOL) writeEntriesToFolder:(NSString*)directoryPath format:(int)fileType considerChildren:(BOOL)recursive includeHeaders:(BOOL)headers;

- (NSString*) htmlRepresentationWithCache:(NSString*)cachePath;

- (void) perform253Maintenance;

@end

@interface JournlerCollection (JournlerScriptability)

- (OSType) scriptType;
- (void) setScriptType:(OSType)osType;

- (OSType) scriptLabel;
- (void) setScriptLabel:(OSType)osType;

- (NSNumber*)scriptCanAutotag;
- (NSString*) URIRepresentationAsString;

#pragma mark -

- (int) indexOfObjectInJSEntries:(JournlerEntry*)anEntry;
- (unsigned int) countOfJSEntries;
- (JournlerEntry*) objectInJSEntriesAtIndex:(unsigned int)i;
- (JournlerEntry*) valueInJSEntriesWithUniqueID:(NSNumber*)idNum;

- (int) indexOfObjectInJSFolders:(JournlerCollection*)aFolder;
- (unsigned int) countOfJSFolders;
- (JournlerCollection*) objectInJSFoldersAtIndex:(unsigned int)i;
- (JournlerCollection*) valueInJSFoldersWithUniqueID:(NSNumber*)idNum;

#pragma mark -

- (void) jsExport:(NSScriptCommand *)command;
- (void) jsAddFolderToFolder:(NSScriptCommand *)command;
- (void) jsMoveFolderToFolder:(NSScriptCommand *)command;

@end
