//
//  JournlerCollection.h
//  Cocoa Journler
//
//  Created by Philip Dow on 08.08.05.
//  Copyright 2005 Sprouted, Philip Dow. All rights reserved.
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
- (void) addChild:(JournlerCollection*)n atIndex:(NSInteger)index;
- (void) removeChild:(JournlerCollection *)aFolder recursively:(BOOL)rFlag;
- (void) moveChild:(JournlerCollection *)aFolder toIndex:(NSUInteger)anIndex;

- (NSInteger) childrenCount;
- (JournlerCollection *) childAtIndex:(NSInteger)i;

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
- (BOOL) flatMenuRepresentation:(NSMenu**)aMenu target:(id)object action:(SEL)aSelector smallImages:(BOOL)useSmallImages inset:(NSInteger)level;

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
+ (NSImage*) defaultImageForID:(NSInteger)type;

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
- (BOOL) writeEntriesToFolder:(NSString*)directoryPath format:(NSInteger)fileType considerChildren:(BOOL)recursive includeHeaders:(BOOL)headers;

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

- (NSInteger) indexOfObjectInJSEntries:(JournlerEntry*)anEntry;
- (NSUInteger) countOfJSEntries;
- (JournlerEntry*) objectInJSEntriesAtIndex:(NSUInteger)i;
- (JournlerEntry*) valueInJSEntriesWithUniqueID:(NSNumber*)idNum;

- (NSInteger) indexOfObjectInJSFolders:(JournlerCollection*)aFolder;
- (NSUInteger) countOfJSFolders;
- (JournlerCollection*) objectInJSFoldersAtIndex:(NSUInteger)i;
- (JournlerCollection*) valueInJSFoldersWithUniqueID:(NSNumber*)idNum;

#pragma mark -

- (void) jsExport:(NSScriptCommand *)command;
- (void) jsAddFolderToFolder:(NSScriptCommand *)command;
- (void) jsMoveFolderToFolder:(NSScriptCommand *)command;

@end
