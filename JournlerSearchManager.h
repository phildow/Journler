//
//  SearchManager.h
//  Journler XD Lite
//
//  Created by Philip Dow on 9/12/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JournlerObject;
@class JournlerJournal;
@class JournlerEntry;
@class JournlerResource;

typedef UInt32 JournlerSearchOptions;
enum JournlerSearchOption {
	kSearchEntries = 1 << 1,
	kSearchResources = 1 << 2
};

typedef UInt32 JournlerTermIndexOptions;
enum JournlerTermIndexOption {
	kGetAllTerms = 0,
	kIgnoreNumericTerms = 1 << 1,
	kIgnoreStopWords = 1 << 2
};


@interface JournlerSearchManager : NSObject {
	
	SKIndexRef entryIndex;
	SKIndexRef referenceIndex;
	
	NSLock *indexLock;
	JournlerJournal *owningJournal;
	NSSet *stopWords;
	
	BOOL indexesOnSeparateThread;
}

- (id) initWithJournal:(JournlerJournal*)aJournal;

- (NSSet*) stopWords;
- (void) setStopWords:(NSSet*)aSet;

- (BOOL) indexesOnSeparateThread;
- (void) setIndexesOnSeparateThread:(BOOL)threaded;

- (BOOL) loadIndexAtPath:(NSString*)path;
- (BOOL) createIndexAtPath:(NSString*)path;
- (BOOL) deleteIndexAtPath:(NSString*)path;

- (BOOL) indexEntry:(JournlerEntry*)anEntry;
- (void) indexEntryOnThread:(id)anEntry;

- (BOOL) indexResource:(JournlerResource*)aResource;
- (void) indexResourceOnThread:(JournlerResource*)aResource;

- (BOOL) indexResource:(JournlerResource*)aResource owner:(JournlerEntry*)anEntry;

- (BOOL) removeEntry:(JournlerEntry*)anEntry;
- (BOOL) removeResource:(JournlerResource*)aResource owner:(JournlerEntry*)anEntry;

- (BOOL) performSearch:(NSString*)query options:(SKSearchOptions)options 
		journlerSearchOptions:(JournlerSearchOptions)journlerOptions
		maximumTime:(CFTimeInterval)maxTime maximumHits:(CFIndex)maxCount 
		entries:(NSSet**)entryMatches resources:(NSSet**)resourceMatches 
		entryHits:(NSInteger*)entryHits referenceHits:(NSInteger*)referenceHits;

- (BOOL) writeIndexToDisk;
- (BOOL) compactIndex;
- (BOOL) rebuildIndex;
- (BOOL) closeIndex;

@end

@interface JournlerSearchManager (TermIndexSupport)

- (NSArray*) allTerms:(NSUInteger)options;
- (NSArray*) entryTerms:(NSUInteger)options;
- (NSArray*) resourceTerms:(NSUInteger)options;

- (NSInteger) countOfDocumentsForTerm:(NSString*)aTerm options:(NSUInteger)options;
- (NSInteger) countOfEntriesForTerm:(NSString*)aTerm options:(NSUInteger)options;
- (NSInteger) countOfResourcesForTerm:(NSString*)aTerm options:(NSUInteger)options;

// returns the number of occurrence of a term within a specified document
- (NSInteger) frequenceyOfTerm:(NSString*)aTerm forDocument:(JournlerObject*)anObject options:(NSUInteger)options;

// returns an array of dictionaries with keys "term" and "journlerObjects" the one a string, the other an array of journler objects
- (NSArray*) termsAndDocumentsArray:(NSUInteger)options;

// these methods should also accept arrays
- (NSArray*) journlerObjectsForTerm:(NSString*)aTerm options:(NSUInteger)options;
- (NSArray*) termsForJournlerObject:(JournlerObject*)anObject options:(NSUInteger)options;

- (NSArray*) termsForTermIDRefs:(CFArrayRef)termIDs index:(SKIndexRef)anIndex options:(NSUInteger)options;

// do the same for the document reference
- (SKDocumentID) documentIDForJournlerObject:(JournlerObject*)anObject options:(NSUInteger)options;

@end

/*
@interface NSString (StringAsDelegateForWebarchiveIndexingCrash)

- (id) delegate;

@end
*/
