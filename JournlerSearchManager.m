//
//  SearchManager.m
//  Journler XD Lite
//
//  Created by Philip Dow on 9/12/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import "JournlerSearchManager.h"

#import "JournlerJournal.h"
#import "JournlerEntry.h"
#import "JournlerResource.h"

#import <SproutedUtilities/SproutedUtilities.h>

static NSString *stopWordsString = @"a all am an and any are as at be but by can could did do does etc for from goes got had has have he her him his how if in is it let me more much must my nor not now of off on or our own see set shall she should so some than that the them then there these this those though to too us was way we what when where which who why will would yes yet you";
static int kMinTermLength = 1;

#define kSearchMax 1000

static NSString *entryIndexFile = @"Index Entries";
static NSString *referenceIndexFile = @"Index References";

// #warning adding a file document does not include the document's title in the searchable text

@implementation JournlerSearchManager

- (id) initWithJournal:(JournlerJournal*)aJournal 
{
	if ( self = [super init] ) 
	{
		owningJournal = [aJournal retain];
		indexLock = [[NSLock alloc] init];
		
		indexesOnSeparateThread = YES;
		
		// default stop set
		[self setStopWords:[NSSet setWithArray:[stopWordsString componentsSeparatedByString:@" "]]];
	}
	return self;
}

- (void) dealloc 
{
	SKIndexClose(entryIndex);
	entryIndex = NULL;
	
	SKIndexClose(referenceIndex);
	referenceIndex = NULL;
	
	[owningJournal release];
	[indexLock release];
	[stopWords release];
	
	[super dealloc];
}

#pragma mark -

- (NSSet*) stopWords
{
	return stopWords;
}

- (void) setStopWords:(NSSet*)aSet
{
	if ( stopWords != aSet )
	{
		[stopWords release];
		stopWords = [aSet copyWithZone:[self zone]];
	}
}

- (BOOL) indexesOnSeparateThread
{
	return indexesOnSeparateThread;
}

- (void) setIndexesOnSeparateThread:(BOOL)threaded
{
	indexesOnSeparateThread = threaded;
}

#pragma mark -

- (BOOL) loadIndexAtPath:(NSString*)path 
{
	NSString *entryIndexPath = [path stringByAppendingPathComponent:entryIndexFile];
	NSString *referenceIndexPath = [path stringByAppendingPathComponent:referenceIndexFile];
	
	if ( ![[NSFileManager defaultManager] fileExistsAtPath:path] || ![[NSFileManager defaultManager] fileExistsAtPath:referenceIndexPath] ) 
	{
		NSLog(@"%s - no search index at path %@", __PRETTY_FUNCTION__, path);
		return NO;
	}
	
	NSURL *entryIndexURL = [NSURL fileURLWithPath:entryIndexPath];
	NSURL *referenceIndexURL = [NSURL fileURLWithPath:referenceIndexPath];
	
	if ( entryIndexURL == nil || referenceIndexURL == nil ) 
	{
		NSLog(@"%s - unable to create entries index, invalid index path for url %@", __PRETTY_FUNCTION__, path);
		return NO;
	}
	
	// open the index
	entryIndex = SKIndexOpenWithURL((CFURLRef)entryIndexURL, (CFStringRef)@"Entry Index",YES);
	referenceIndex = SKIndexOpenWithURL((CFURLRef)referenceIndexURL,(CFStringRef)@"Reference Index",YES);
	
	if ( entryIndex != NULL && referenceIndex != NULL )
		return YES;
	else 
	{
		NSLog(@"%s - unable to load index, nil index", __PRETTY_FUNCTION__);
		return NO;
	}
}

- (BOOL) createIndexAtPath:(NSString*)path 
{
	BOOL success = YES;
	NSDictionary *analysisDict;
	
	NSString *entryIndexPath = [path stringByAppendingPathComponent:entryIndexFile];
	NSString *referenceIndexPath = [path stringByAppendingPathComponent:referenceIndexFile];
	
	NSURL *entryIndexURL = [NSURL fileURLWithPath:entryIndexPath];
	NSURL *referenceIndexURL = [NSURL fileURLWithPath:referenceIndexPath];
	
	if ( entryIndexURL == nil || referenceIndexURL == nil ) 
	{
		NSLog(@"%s - unable to create entries index, invalid index at path %@", __PRETTY_FUNCTION__, path);
		return NO;
	}
	
	if ( [[NSFileManager defaultManager] fileExistsAtPath:entryIndexPath] ) 
	{
		NSLog(@"%s - index already exists at path, overwriting %@", __PRETTY_FUNCTION__, entryIndexPath);
		[[NSFileManager defaultManager] removeFileAtPath:entryIndexPath handler:nil];
	}
	
	if ( [[NSFileManager defaultManager] fileExistsAtPath:referenceIndexPath] ) 
	{
		NSLog(@"%s - index already exists at path, overwriting %@", __PRETTY_FUNCTION__, referenceIndexPath);
		[[NSFileManager defaultManager] removeFileAtPath:referenceIndexPath handler:nil];
	}
	
	// 10.4 dictionary
	analysisDict = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInt:kMinTermLength], (NSString *)kSKMinTermLength, 
			[self stopWords], (NSString*)kSKStopWords,
			[NSNumber numberWithBool:YES], (NSString *)kSKProximityIndexing, 
			/*kCFBooleanTrue, kSKProximityIndexing,*/
			[NSNumber numberWithInt:0], (NSString *)kSKMaximumTerms, nil];
	
	entryIndex = SKIndexCreateWithURL((CFURLRef)entryIndexURL,
			(CFStringRef)@"Entry Index",kSKIndexInvertedVector,(CFDictionaryRef)analysisDict);
	
	referenceIndex = SKIndexCreateWithURL((CFURLRef)referenceIndexURL,
			(CFStringRef)@"Reference Index",kSKIndexInvertedVector,(CFDictionaryRef)analysisDict);
			
	if ( entryIndex == NULL ) 
	{
		NSLog(@"%s - unable to create entry search index at path %@", __PRETTY_FUNCTION__, entryIndexPath);
		success = NO;
	}
	else 
	{
		SKIndexClose(entryIndex);
		entryIndex = NULL;
	}
	
	if ( referenceIndex == NULL )
	{
		NSLog(@"%s - unable to create reference search index at path %@", __PRETTY_FUNCTION__, referenceIndexPath);
		success = NO;
	}
	else
	{
		SKIndexClose(referenceIndex);
		referenceIndex = NULL;
	}
	
	return success;
}

- (BOOL) deleteIndexAtPath:(NSString*)path 
{
	BOOL success = YES;
	NSString *entryIndexPath = [path stringByAppendingPathComponent:entryIndexFile];
	NSString *referenceIndexPath = [path stringByAppendingPathComponent:referenceIndexFile];

	if ( [[NSFileManager defaultManager] fileExistsAtPath:entryIndexPath] )
		success = ( [[NSFileManager defaultManager] removeFileAtPath:entryIndexPath handler:self] && success );
	else
		success = ( success && NO );
	
	if ( [[NSFileManager defaultManager] fileExistsAtPath:referenceIndexPath] )
		success = ( [[NSFileManager defaultManager] removeFileAtPath:referenceIndexPath handler:self] && success );
	else
		success = ( success && NO );
		
	return success;
}

#pragma mark -

- (BOOL) indexEntry:(JournlerEntry*)anEntry 
{	
	// adds an entry as well as it's references to the search manager
	if ( indexesOnSeparateThread == YES )
		[NSThread detachNewThreadSelector:@selector(indexEntryOnThread:) toTarget:self withObject:anEntry];
	else
		[self indexEntryOnThread:anEntry];
	
	return YES;
}

- (BOOL) indexResource:(JournlerResource*)aResource
{
	// adds just a resource ot the search manager
	if ( indexesOnSeparateThread == YES )
		[NSThread detachNewThreadSelector:@selector(indexResourceOnThread:) toTarget:self withObject:aResource];
	else
		[self indexResourceOnThread:aResource];
	
	return YES;
}

- (void) indexResourceOnThread:(JournlerResource*)aResource
{
	[indexLock lock];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// determine the owner and call into the main resource indexing function
	
	JournlerEntry *owner = [aResource valueForKey:@"entry"];
	if ( owner == nil )
	{
		NSArray *entries = [aResource valueForKey:@"entries"];
		owner = ( [entries count] > 0 ? [entries objectAtIndex:0] : nil );
	}
	
	// is the owner still nil?
	if ( owner == nil )
	{
		NSLog(@"%s - the resource %@ : %@ does not seem to have an owner, not indexing", 
				__PRETTY_FUNCTION__, [aResource valueForKey:@"tagID"], [aResource valueForKey:@"title"]);
	}
	else
	{
		[self indexResource:aResource owner:owner];
	}
			
	[pool release];
	[indexLock unlock];
}

- (void) indexEntryOnThread:(id)anEntry
{	
	[indexLock lock];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if ( entryIndex == NULL ) 
	{
		NSLog(@"%s - unable to index entry, no search index available", __PRETTY_FUNCTION__);
		[pool release];
		[indexLock unlock];
		return;
	}
	
	NSString *entryText = [anEntry searchableContent];
	NSURL *entryIdentifier = [anEntry URIRepresentation];
	
	SKDocumentRef entryDocumentRef = SKDocumentCreateWithURL((CFURLRef)entryIdentifier);
	
	if ( entryDocumentRef == NULL ) 
	{
		NSLog(@"%s - problem preparing entry for indexing: %@", __PRETTY_FUNCTION__, [anEntry valueForKey:@"tagID"]);
		[pool release];
		[indexLock unlock];
		return;
	}
	
	if ( !SKIndexAddDocumentWithText(entryIndex,entryDocumentRef,(CFStringRef)entryText,YES) ) 
	{
		NSLog(@"%s - unable to add entry to index: %@", __PRETTY_FUNCTION__, [anEntry valueForKey:@"tagID"]);
		
		SKIndexRemoveDocument(entryIndex,entryDocumentRef);
		CFRelease(entryDocumentRef);
		[pool release];
		[indexLock unlock];
		return;
	}
	
	// iterate through the entry's references, adding them to the index in an appropriate manner

    for ( JournlerResource *aResource in [anEntry valueForKey:@"resources"] )
		[self indexResource:aResource owner:anEntry];
	
	// I am unlocking before indexing the resource because the thread is crashing when an exception is not caught
	// and the lock isn't being unlocked. It seems to keep a reference to its thread, though, which results in a message
	// being sent to an invalid object.
	
	CFRelease(entryDocumentRef);
	[pool release];
	
	[indexLock unlock];
	return;
}

- (BOOL) indexResource:(JournlerResource*)aResource owner:(JournlerEntry*)anEntry
{
	// only include references the user would like to search through
	if ( ![[aResource valueForKey:@"searches"] boolValue] || [[aResource valueForKeyPath:@"entry.markedForTrash"] boolValue] )
		return NO;
	
	// make sure the index is available
	if ( referenceIndex == NULL ) 
	{
		NSLog(@"%s - unable to index reference, no search index available", __PRETTY_FUNCTION__);
		return NO;
	}
	
	// support is only included for files and contacts - no urls yet although that would be very cool
	if ( !( [aResource representsFile] || [aResource representsABRecord] ) || 
			( [aResource representsFile] && [[aResource valueForKey:@"uti"] isEqualToString:ResourceUnknownUTI] ) )
		return NO;
	
	// the entry asscoiated with this resource
	NSURL *entryIdentifier = [anEntry URIRepresentation];
	
	// all the entries associated with this resource
	NSArray *allEntryIdentifiers = [aResource valueForKeyPath:@"entries.URIRepresentation.absoluteString"];
	if ( allEntryIdentifiers == nil ) allEntryIdentifiers = [NSArray arrayWithObject:entryIdentifier];
	
	// a dictionary which links the resource to its entry and entries
	NSDictionary *referenceProperties = [NSDictionary dictionaryWithObjectsAndKeys:
			[entryIdentifier absoluteString], @"entry", 
			allEntryIdentifiers, @"entries",
			[[aResource URIRepresentation] absoluteString], @"reference", nil]; 
	
	// determine how the resource will be identified in the search index
	NSString *textRepresentation = nil;
	NSURL *referenceIdentifier = nil;
	
	if ( [aResource representsFile] )
	{
		// prefer an already determined text representation if one is available, otherwise let spotlight index the file
		textRepresentation = [aResource textRepresentation];
	
		if ( textRepresentation == nil )
		{
			// try deriving the text representation myself
			NSString *originalPath = [aResource originalPath];
			
			if ( originalPath == nil )
				NSLog(@"%s - unable to determine original path for resource %@", __PRETTY_FUNCTION__, [aResource valueForKey:@"tagID"]);
			else
			{
				NSString *uti = [[NSWorkspace sharedWorkspace] UTIForFile:originalPath];
				
				// note the path and uti for the file if search debug is abled
				if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"JournlerSearchDebug"] )
					NSLog(@"%s - indexing file %@, uti: %@", __PRETTY_FUNCTION__, originalPath, uti); 
				
				if ( UTTypeConformsTo((CFStringRef)uti, (CFStringRef)kPDUTTypeMailEmail) )
				{
					// a bug in SpotlightTextContentRetriever crashes when extracting mail files if mail tags is installed
					MailMessageParser *parser = [[[MailMessageParser alloc] initWithFile:originalPath] autorelease];
					if ( parser == nil )
						NSLog(@"%s - unable to parse message at path %@", __PRETTY_FUNCTION__, originalPath);
					else
						textRepresentation = [parser body:NO];
				}
				else
				{
					// grab the text representation over spotlight
					// surround in exception code
					@try {
						textRepresentation = [SpotlightTextContentRetriever textContentOfFileAtPath:originalPath];
					}
					@catch (NSException *localException) {
						NSLog(@"%s - exception encountered while trying to index file based resource, file: %@, exception: %@",
						__PRETTY_FUNCTION__, [aResource originalPath], [localException description]);
					}
					@finally {
						
					}
				}
				
				if ( textRepresentation == nil )
					referenceIdentifier = [NSURL fileURLWithPath:originalPath];
				else
					referenceIdentifier = [aResource URIRepresentation];
			}
		}
		else
		{
			referenceIdentifier = [aResource URIRepresentation];
		}
	}
	else if ( [aResource representsABRecord] || [aResource representsURL] )
		referenceIdentifier = [aResource URIRepresentation];
	
	if ( referenceIdentifier == nil )
	{
		// this is not the kind of resources that's indexed. No worries.
		return NO;
		
		//NSLog(@"%s - problem preparing reference identifier for indexing %@-%@", __PRETTY_FUNCTION__, 
		//		[anEntry valueForKey:@"tagID"], [aResource valueForKey:@"tagID"]);
	}
	
	// create and check the SKDocumentRef
	SKDocumentRef referenceDocumentRef = SKDocumentCreateWithURL((CFURLRef)referenceIdentifier);
	if ( referenceDocumentRef == NULL ) 
	{
		NSLog(@"%s - problem preparing reference for indexing %@-%@", __PRETTY_FUNCTION__, 
		[anEntry valueForKey:@"tagID"], [aResource valueForKey:@"tagID"]);
		return NO;
	}
	
	if ( [aResource representsFile] )
	{
		// prefer the textRepresentation but if it is not available let spotlight index the file
		
		if ( textRepresentation == nil )
		{
			BOOL indexed = NO;
			
			@try {
				// add the document as a file to the index, letting the search manager determine the textual contents
				indexed = SKIndexAddDocument(referenceIndex,referenceDocumentRef,NULL,YES);
			 }
			@catch (NSException *localException) {
				NSLog(@"%s - exception encountered while trying to index file based resource, file: %@, exception: %@",
				__PRETTY_FUNCTION__, [aResource originalPath], [localException description]);
				//CFRelease(referenceDocumentRef);
				return NO;
			}
			@catch (id undefinedException)
			{
				NSLog(@"%s - undefined exception encountered while trying to index file based resource, file: %@, exception: %@",
				__PRETTY_FUNCTION__, [aResource originalPath], [undefinedException description]);
				//CFRelease(referenceDocumentRef);
				return NO;
			}
			@finally {
				if ( !indexed ) 
				{
					NSLog(@"%s - SKIndexAddDocument() problem adding reference to index %@-%@ %@, SKDocumentRef: %@",
					 __PRETTY_FUNCTION__,
					 [anEntry valueForKey:@"tagID"], 
					 [aResource valueForKey:@"tagID"], [aResource valueForKey:@"title"], referenceIdentifier);
					 
					SKIndexRemoveDocument(referenceIndex,referenceDocumentRef);
					CFRelease(referenceDocumentRef);
					return NO;
				}
			}
		} // if ( textRepresentation == nil )
		else
		{
			#ifdef __DEBUG__
			NSLog(@"%s - using text representation",__PRETTY_FUNCTION__);
			#endif
			
			// add the resource's filename to the searchable contents
			NSMutableString *enhancedRepresentation = [NSMutableString stringWithString:textRepresentation];
			NSString *resourceTitle = [aResource valueForKey:@"title"];
			if ( resourceTitle != nil ) [enhancedRepresentation appendFormat:@" %@ %@", resourceTitle, resourceTitle];
			
			// index the enhanced text
			//if ( !SKIndexAddDocumentWithText(referenceIndex,referenceDocumentRef,(CFStringRef)textRepresentation,YES) ) 
			if ( !SKIndexAddDocumentWithText(referenceIndex,referenceDocumentRef,(CFStringRef)enhancedRepresentation,YES) ) 
			{
				NSLog(@"%s - unable to add ABResource to index: %@-%@", __PRETTY_FUNCTION__, 
				 [anEntry valueForKey:@"tagID"], [aResource valueForKey:@"tagID"]);
				
				SKIndexRemoveDocument(referenceIndex,referenceDocumentRef);
				CFRelease(referenceDocumentRef);
				return NO;
			}
		}
	}
	else if ( [aResource representsABRecord] )
	{
		// add the textual contents of the ab record to the index
		NSString *referenceText = [aResource searchContentForABRecord];
		if ( referenceText == nil )
		{
			NSLog(@"%s - unable to derive searchable text for ABRecord resource %@-%@", __PRETTY_FUNCTION__,
			[anEntry valueForKey:@"tagID"], [aResource valueForKey:@"tagID"]);
			CFRelease(referenceDocumentRef);
			return NO;
		}
		
		if ( !SKIndexAddDocumentWithText(referenceIndex,referenceDocumentRef,(CFStringRef)referenceText,YES) ) 
		{
			NSLog(@"%s - unable to add ABResource to index: %@-%@", __PRETTY_FUNCTION__, 
			 [anEntry valueForKey:@"tagID"], [aResource valueForKey:@"tagID"]);
			
			SKIndexRemoveDocument(referenceIndex,referenceDocumentRef);
			CFRelease(referenceDocumentRef);
			return NO;
		}
	}
	else if ( [aResource representsURL] )
	{
		// add the textual contents of the ab record to the index
		NSString *referenceText = [aResource searchContentForURL];
		if ( referenceText == nil )
		{
			NSLog(@"%s - unable to derive searchable text for ABRecord resource %@-%@", __PRETTY_FUNCTION__,
			 [anEntry valueForKey:@"tagID"], [aResource valueForKey:@"tagID"]);
			CFRelease(referenceDocumentRef);
			return NO;
		}
		
		if ( !SKIndexAddDocumentWithText(referenceIndex,referenceDocumentRef,(CFStringRef)referenceText,YES) ) 
		{
			NSLog(@"%s - unable to add ABResource to index: %@-%@", __PRETTY_FUNCTION__, 
			 [anEntry valueForKey:@"tagID"], [aResource valueForKey:@"tagID"]);
			
			SKIndexRemoveDocument(referenceIndex,referenceDocumentRef);
			CFRelease(referenceDocumentRef);
			return NO;
		}
	}
	
	// link the resource to its entry in the search index file
	SKIndexSetDocumentProperties(referenceIndex,referenceDocumentRef,(CFDictionaryRef)referenceProperties);
	
	CFRelease(referenceDocumentRef);
	return YES;
}

#pragma mark -

- (BOOL) removeEntry:(JournlerEntry*)anEntry 
{
	NSURL *entryIdentifier = [anEntry URIRepresentation];
	SKDocumentRef entryDocumentRef = SKDocumentCreateWithURL((CFURLRef)entryIdentifier);
	
	if ( entryDocumentRef == NULL ) 
	{
		NSLog(@"%s - problem preparing entry for indexing: %@", __PRETTY_FUNCTION__, [anEntry valueForKey:@"tagID"]);
		return NO;
	}
	
	if ( entryIndex == NULL )
	{
		NSLog(@"%s - no entry index available, entry was not removed from index: %@", __PRETTY_FUNCTION__, [anEntry valueForKey:@"tagID"]);
		return NO;
	}
	
	if ( !SKIndexRemoveDocument(entryIndex,entryDocumentRef) ) 
	{
		NSLog(@"%s - unable to remove entry from search index", __PRETTY_FUNCTION__);
		return NO;
	}
	
	
	
	// iterate through the entry's references, adding them to the index in an appropriate manner
	
    for ( JournlerResource *aResource in [anEntry valueForKey:@"resources"] )
		[self removeResource:aResource owner:anEntry];
	
	CFRelease(entryDocumentRef);
	return YES;
}

- (BOOL) removeResource:(JournlerResource*)aResource owner:(JournlerEntry*)anEntry 
{
	// only include references the user was searching through
	if ( ![[aResource valueForKey:@"searches"] boolValue] )
		return NO;
	
	// support is only included for files and contacts - no urls yet although that would be very cool
	if ( !( [aResource representsFile] || [aResource representsABRecord] ) || 
			( [aResource representsFile] && [[aResource valueForKey:@"uti"] isEqualToString:ResourceUnknownUTI] ) )
		return NO;
	
	
	// determine the reference identifier
	// prefer the uri representation
	NSURL *referenceIdentifier = [aResource URIRepresentation];
	
	// derive the SKDocumentRef
	SKDocumentRef referenceDocumentRef = SKDocumentCreateWithURL((CFURLRef)referenceIdentifier);
	if ( referenceDocumentRef == NULL ) 
	{
		NSLog(@"%s - problem preparing reference for indexing %@-%@", __PRETTY_FUNCTION__, 
		[anEntry valueForKey:@"tagID"], [aResource valueForKey:@"tagID"]);
		return NO;
	}
	
	if ( referenceIndex == NULL )
	{
		NSLog(@"%s - no entry index available, resource was not removed from index:  %@-%@", __PRETTY_FUNCTION__, 
		[anEntry valueForKey:@"tagID"], [aResource valueForKey:@"tagID"]);
		return NO;
	}
	
	if ( !SKIndexRemoveDocument(referenceIndex, referenceDocumentRef) ) 
	{
		NSLog(@"%s - unable to remove resource with identifier %@ from search index", __PRETTY_FUNCTION__, [referenceIdentifier absoluteString]);
		
		if ( [aResource representsFile] )
		{
			BOOL fileSuccess = NO;
			NSLog(@"%s - resource is a file, trying a file based reference identifier", __PRETTY_FUNCTION__);
			
			// derive the reference identifier for a file
			NSString *originalPath = [aResource originalPath];
			if ( originalPath != nil )
			{
				referenceIdentifier = [NSURL fileURLWithPath:[aResource originalPath]];
				if ( referenceIdentifier != nil )
				{
					// clear ou the current SKDocumentRef
					CFRelease(referenceDocumentRef);
					referenceDocumentRef = nil;
					
					// create a new one
					referenceDocumentRef = SKDocumentCreateWithURL((CFURLRef)referenceIdentifier);
					if ( referenceDocumentRef == NULL ) 
					{
						// same error checking
						NSLog(@"%s - problem preparing file based reference for indexing %@-%@", __PRETTY_FUNCTION__, 
						[anEntry valueForKey:@"tagID"], [aResource valueForKey:@"tagID"]);
						return NO;
					}
					else
					{
						fileSuccess = SKIndexRemoveDocument(referenceIndex, referenceDocumentRef);
					}
				}
			}
			
			if ( fileSuccess == NO )
				NSLog(@"%s - still unable to remove file based resource from index, file identifier: %@", __PRETTY_FUNCTION__, referenceIdentifier);
		}
	}
	
	CFRelease(referenceDocumentRef);
	return YES;
}

#pragma mark -

- (BOOL) performSearch:(NSString*)query options:(SKSearchOptions)options 
		journlerSearchOptions:(JournlerSearchOptions)journlerOptions
		maximumTime:(CFTimeInterval)maxTime maximumHits:(CFIndex)maxCount 
		entries:(NSSet**)entryMatches resources:(NSSet**)resourceMatches 
		entryHits:(int*)entryHits referenceHits:(int*)referenceHits 
{

	*entryHits = (int) 0;
	*referenceHits = (int) 0;
	
	NSMutableSet *entriesSet = [NSMutableSet set];
	NSMutableSet *referencesSet = [NSMutableSet set];
	
	if ( entryIndex == nil || referenceIndex == nil ) 
	{
		NSLog(@"%s - unable to perform search, search index is nil", __PRETTY_FUNCTION__);
		goto bail;
	}
	
	// flush the index
	if ( !SKIndexFlush(entryIndex) || !SKIndexFlush(referenceIndex) ) 
	{
		NSLog(@"%s - could not flush one of the indexes", __PRETTY_FUNCTION__);
		goto bail;
	}
	
	// perform the entry index search if the caller wants it
	if ( entryMatches != nil && ( journlerOptions & kSearchEntries ) ) 
	{
		SKSearchRef			searchQuery;
	
		BOOL				exhausted;
		CFIndex				numberOfHits;
		
		//SKDocumentID entryDocumentIDs[kSearchMax];
		//SKDocumentRef entryDocumentRefs[kSearchMax];
		//float entryScores[kSearchMax];
		
		float *entryScores = calloc(maxCount,sizeof(float));;
		SKDocumentID *entryDocumentIDs = calloc(maxCount,sizeof(SKDocumentID));
		SKDocumentRef *entryDocumentRefs;
	
		// create a search query
		searchQuery = SKSearchCreate(entryIndex,(CFStringRef)query,options);
		if ( searchQuery == nil ) 
		{
			NSLog(@"%s - unable to perform search, SKSearchRef is not valid", __PRETTY_FUNCTION__);
			free(entryDocumentIDs);
			free(entryScores);
			goto bail;
		}

		// run the search
		exhausted = SKSearchFindMatches(searchQuery,maxCount,entryDocumentIDs,entryScores,maxTime,&numberOfHits);
		*entryHits = (int) numberOfHits;
		
		entryDocumentRefs = calloc(numberOfHits,sizeof(SKDocumentRef));
		
		// convert the document ids to document refs
		//#warning memory leak
		// "When finished with the document URL objects array, dispose of it by calling CFRelease on each array element."
		SKIndexCopyDocumentRefsForDocumentIDs(entryIndex,numberOfHits,entryDocumentIDs,entryDocumentRefs);
		
		// get the max score for relevance ranked display
		int i;
		float maxScore = 0.0;
		for ( i = 0; i < numberOfHits; i++ ) 
		{
			if ( entryScores[i] > maxScore ) maxScore = entryScores[i];
		}
		if ( maxScore == 0.0 ) // to avoid division by zero to be safe
			maxScore = 0.000001;
		
		// convert the document references to entries
		for ( i = 0; i < numberOfHits; i++ ) 
		{
			NSURL *documentURI = (NSURL*)SKDocumentCopyURL(entryDocumentRefs[i]);
			if ( documentURI == nil )
			{
				NSLog(@"%s - nil document uri for a document ref", __PRETTY_FUNCTION__);
				continue;
			}
			
			JournlerEntry *theEntry = [owningJournal objectForURIRepresentation:documentURI];
			
			CFRelease(entryDocumentRefs[i]);
			
			if ( theEntry == nil ) 
			{
				NSLog(@"%s - entry object id returned nil entry: %@", __PRETTY_FUNCTION__, documentURI);
				continue;
			}
			
			[theEntry setRelevance:entryScores[i]/maxScore];
			[entriesSet addObject:theEntry];
			
			// clean up
			[documentURI release];
		}
		
		// stop the search and clean up
		SKSearchCancel(searchQuery);
		CFRelease(searchQuery);
		
		free(entryScores);
		free(entryDocumentIDs);
		free(entryDocumentRefs);
	}
	
	// perform the reference search if the caller wants it
	if ( resourceMatches != nil && ( journlerOptions & kSearchResources ) ) 
	{
		SKSearchRef			searchQuery;
	
		BOOL				exhausted;
		CFIndex				numberOfHits;
		
		//SKDocumentID referenceDocumentIDs[kSearchMax];
		//SKDocumentRef referenceDocumentRefs[kSearchMax];
		//float referenceScores[kSearchMax];
		
		float *referenceScores = calloc(maxCount, sizeof(float));
		SKDocumentID *referenceDocumentIDs = calloc(maxCount,sizeof(SKDocumentID));
		SKDocumentRef *referenceDocumentRefs;
		
		// create a search query
		searchQuery = SKSearchCreate(referenceIndex,(CFStringRef)query,options);
		if ( searchQuery == nil ) 
		{
			NSLog(@"%s - unable to perform search, SKSearchRef is not valid", __PRETTY_FUNCTION__);
			free(referenceScores);
			free(referenceDocumentIDs);
			goto bail;
		}

		// run the search
		exhausted = SKSearchFindMatches(searchQuery,maxCount,referenceDocumentIDs,referenceScores,maxTime,&numberOfHits);
		*referenceHits = (int) numberOfHits;
		
		referenceDocumentRefs = calloc(numberOfHits,sizeof(SKDocumentRef));
		
		// convert the document ids to document refs
		//#warning memory leak! 
		// "When finished with the document URL objects array, dispose of it by calling CFRelease on each array element."
		SKIndexCopyDocumentRefsForDocumentIDs(referenceIndex,numberOfHits,referenceDocumentIDs,referenceDocumentRefs);
		
		// get the max score for relevance ranked display
		int i;
		float maxScore = 0.0;
		for ( i = 0; i < numberOfHits; i++ ) 
		{
			if ( referenceScores[i] > maxScore ) maxScore = referenceScores[i];
		}
		if ( maxScore == 0.0 ) // to avoid division by zero to be safe
			maxScore = 0.000001;
		
		// convert the document references to entries and references
		for ( i = 0; i < numberOfHits; i++ ) 
		{
		
			NSURL *documentURI = (NSURL*)SKDocumentCopyURL(referenceDocumentRefs[i]);
			if ( documentURI == nil )
			{
				NSLog(@"%s - nil document uri for a reference document ref", __PRETTY_FUNCTION__);
				continue;
			}
			
			NSDictionary *documentProperties = (NSDictionary*)SKIndexCopyDocumentProperties(referenceIndex,referenceDocumentRefs[i]);
			if ( documentProperties == nil )
			{
				NSLog(@"%s - nil document properties for a document ref with uri %@", __PRETTY_FUNCTION__, documentURI);
				continue;
			}
			
			CFRelease(referenceDocumentRefs[i]);
			
			// dealing with a file reference - convert it to the reference object
			NSURL *referenceURI = [NSURL URLWithString:[documentProperties objectForKey:@"reference"]];
			NSURL *entryURI = [NSURL URLWithString:[documentProperties objectForKey:@"entry"]];
			
			JournlerResource *theReference = [owningJournal objectForURIRepresentation:referenceURI];
			JournlerEntry *theEntry = [owningJournal objectForURIRepresentation:entryURI];
			
			if ( theReference == nil ) 
			{
				NSLog(@"%s - reference managed object id returned nil reference: %@", __PRETTY_FUNCTION__, referenceURI);
				[documentProperties release];
				continue;
			}
			
			if ( theEntry == nil ) 
			{
				NSLog(@"%s - entry managed object id for reference returned nil reference: %@", __PRETTY_FUNCTION__, entryURI);
				[documentProperties release];
				continue;
			}
			
			float entryRelevance = [theEntry relevance];
			float referenceRelevance = referenceScores[i]/maxScore;
			
			//#warning find a good way to represent multiple hits on an entry via references
			[theReference setRelevance:referenceRelevance];
			[theEntry setRelevance:( referenceRelevance > entryRelevance ? referenceRelevance : entryRelevance )];
			
			// set the relevance on all of the associated entries
            
            for ( NSString *anEntryURI in [documentProperties objectForKey:@"entries"] )
			{
				JournlerEntry *anOwningEntry = [owningJournal objectForURIRepresentation:[NSURL URLWithString:anEntryURI]];
				if ( anOwningEntry == nil )
					continue;
				
				entryRelevance = [anOwningEntry relevance];
				[anOwningEntry setRelevance:( referenceRelevance > entryRelevance ? referenceRelevance : entryRelevance )];
				
				[entriesSet addObject:anOwningEntry];
			}
			
			[referencesSet addObject:theReference];
			[entriesSet addObject:theEntry];
			
			// clean up
			[documentURI release];
			[documentProperties release];
		
		}
		
		// stop the search and clean up
		SKSearchCancel(searchQuery);
		CFRelease(searchQuery);
		
		free(referenceScores);
		free(referenceDocumentIDs);
		free(referenceDocumentRefs);
	}

bail:
	
	// set the... sets
	*entryMatches = entriesSet;
	*resourceMatches = referencesSet;
	
	return YES;
}

#pragma mark -

- (BOOL) writeIndexToDisk 
{
	BOOL completeSuccess = YES;
	
	[indexLock lock];
	
	if ( entryIndex != NULL )
	{
		BOOL result = SKIndexFlush(entryIndex);
		if ( !result ) 
			NSLog(@"%s - Could not flush the entry index", __PRETTY_FUNCTION__);
		
		completeSuccess = ( completeSuccess && result );
	}
	
	if ( referenceIndex != NULL )
	{
		BOOL result = SKIndexFlush(referenceIndex);
		if ( !result ) 
			NSLog(@"%s - Could not flush the resource index", __PRETTY_FUNCTION__);

		completeSuccess = ( completeSuccess && result );
	}
	
	[indexLock unlock];
	
	return completeSuccess;
}

- (BOOL) compactIndex 
{
	//will make a decision about compacting our search indexes.  Not done all the time, only every once in a while.
	if ( entryIndex == NULL || referenceIndex == NULL ) 
	{
		return NO;
	}
	
	[indexLock lock];
	NSLog(@"%s - beginning at %@", __PRETTY_FUNCTION__, [NSDate date]);
	
	if ( !SKIndexCompact(entryIndex) || !SKIndexCompact(referenceIndex)) 
	{
		NSLog(@"%s - Unable to compact index or compacting not necessary", __PRETTY_FUNCTION__);
		[indexLock unlock];	
		return NO;
	}
	
	NSLog(@"%s - finished at %@", __PRETTY_FUNCTION__, [NSDate date]);
	[indexLock unlock];

	return YES;
}

- (BOOL) rebuildIndex 
{
	BOOL threadedIndex = [self indexesOnSeparateThread];
	[self setIndexesOnSeparateThread:NO];
	NSLog(@"%s - beginning at %@", __PRETTY_FUNCTION__, [NSDate date]);
	
    for ( JournlerEntry *anEntry in [owningJournal valueForKey:@"entries"] )
		[self indexEntry:anEntry];
	
	NSLog(@"%s - finished at %@", __PRETTY_FUNCTION__, [NSDate date]);
	[self setIndexesOnSeparateThread:threadedIndex];
	
	return [self writeIndexToDisk];
}

- (BOOL) closeIndex
{
	// ensure we aren't in the process of indexing any entries (ie especially during setup)
	[indexLock lock];
	
	if ( entryIndex != NULL )
	{
		SKIndexFlush(entryIndex);
		SKIndexClose(entryIndex);
		entryIndex = NULL;
	}
	
	if ( referenceIndex != NULL )
	{
		SKIndexFlush(referenceIndex);
		SKIndexClose(referenceIndex);
		referenceIndex = NULL;
	}
	
	[indexLock unlock];
	
	return YES;
}

#pragma mark -
#pragma mark NSFileManager Delegation

- (BOOL)fileManager:(NSFileManager *)manager shouldProceedAfterError:(NSDictionary *)errorInfo 
{
	NSLog(@"\n%s - file manager error: %@\n", __PRETTY_FUNCTION__, [errorInfo description]);
	return NO;
}

- (void)fileManager:(NSFileManager *)manager willProcessPath:(NSString *)path 
{

}

@end

#pragma mark -

@implementation JournlerSearchManager (TermIndexSupport)

- (NSArray*) allTerms:(unsigned)options
{
	// flush the index before calling - (BOOL) writeIndexToDisk
	NSMutableSet *allTermsSet = [NSMutableSet set];
	
	[allTermsSet addObjectsFromArray:[self entryTerms:options]];
	[allTermsSet addObjectsFromArray:[self resourceTerms:options]];
	
	// remove the terms that *aren't* supposed to be indexed (stop words)
	[allTermsSet minusSet:[self stopWords]];
	
	return [[allTermsSet allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	//return [allTermsSet allObjects];
}

- (NSArray*) entryTerms:(unsigned)options
{
	// flush the index before calling - (BOOL) writeIndexToDisk
	NSMutableArray *entryTerms = [NSMutableArray array];
	
	if ( entryIndex == NULL )
	{
		NSLog(@"%s - entry index is null", __PRETTY_FUNCTION__);
		return nil;
	}
	
	CFIndex aTermID;
	CFIndex maxTermID = SKIndexGetMaximumTermID(entryIndex);
	
	// why did I have <= herE?
	for ( aTermID = 0; aTermID < maxTermID; aTermID++ )
	{
		CFIndex documentCount = SKIndexGetTermDocumentCount( entryIndex, aTermID );
		if ( documentCount == 0 )
			continue;
		
		CFStringRef aTerm = SKIndexCopyTermStringForTermID( entryIndex, aTermID );
		if ( aTerm == NULL )
		{
			NSLog(@"%s - unable to get term for term index %ld", __PRETTY_FUNCTION__, aTermID);
			continue;
		}
		
		if ( !( (options & kIgnoreNumericTerms) && CFStringGetCharacterAtIndex(aTerm,0) < 0x0041 ) )
			[entryTerms addObject:(NSString*)aTerm];

		CFRelease(aTerm);
	}
	
	return entryTerms;
}

- (NSArray*) resourceTerms:(unsigned)options
{
	// flush the index before calling - (BOOL) writeIndexToDisk
	NSMutableArray *resourceTerms = [NSMutableArray array];
	
	if ( referenceIndex == NULL )
	{
		NSLog(@"%s - resource index is null", __PRETTY_FUNCTION__);
		return nil;
	}
	
	CFIndex aTermID;
	CFIndex maxTermID = SKIndexGetMaximumTermID(referenceIndex);
	
	// why did I have <= here?
	for ( aTermID = 0; aTermID < maxTermID; aTermID++ )
	{
		CFIndex documentCount = SKIndexGetTermDocumentCount( referenceIndex, aTermID );
		if ( documentCount == 0 )
			continue;
		
		CFStringRef aTerm = SKIndexCopyTermStringForTermID( referenceIndex, aTermID );
		if ( aTerm == NULL )
		{
			NSLog(@"%s - unable to get term for term index %ld", __PRETTY_FUNCTION__, aTermID);
			continue;
		}
		
		if ( !( (options & kIgnoreNumericTerms) && CFStringGetCharacterAtIndex(aTerm,0) < 0x0041 ) )
			[resourceTerms addObject:(NSString*)aTerm];
			
		CFRelease(aTerm);
	}
	
	return resourceTerms;
}

#pragma mark -

- (int) countOfDocumentsForTerm:(NSString*)aTerm options:(unsigned)options
{
	//aTerm = [aTerm lowercaseString];
	
	if ( aTerm == nil || [aTerm length] == 0 )
		return 0;
	
	// flush the index before calling - (BOOL) writeIndexToDisk
	return ( [self countOfEntriesForTerm:aTerm options:options] + [self countOfResourcesForTerm:aTerm options:options] );
}

- (int) countOfEntriesForTerm:(NSString*)aTerm options:(unsigned)options
{
	//aTerm = [aTerm lowercaseString];
	
	if ( aTerm == nil || [aTerm length] == 0 )
		return 0;
	
	// flush the index before calling - (BOOL) writeIndexToDisk
	CFIndex aTermID = SKIndexGetTermIDForTermString( entryIndex, (CFStringRef)aTerm );
	if ( aTermID == kCFNotFound )
		return 0;
	
	CFIndex documentCount = SKIndexGetTermDocumentCount( entryIndex, aTermID );
	return documentCount;
}

- (int) countOfResourcesForTerm:(NSString*)aTerm options:(unsigned)options
{
	//aTerm = [aTerm lowercaseString];
	
	if ( aTerm == nil || [aTerm length] == 0 )
		return 0;
	
	// flush the index before calling - (BOOL) writeIndexToDisk
	CFIndex aTermID = SKIndexGetTermIDForTermString( referenceIndex, (CFStringRef)aTerm );
	if ( aTermID == kCFNotFound )
		return 0;

	CFIndex documentCount = SKIndexGetTermDocumentCount( referenceIndex, aTermID );
	return documentCount;
}

#pragma mark -

- (int) frequenceyOfTerm:(NSString*)aTerm forDocument:(JournlerObject*)anObject options:(unsigned)options
{
	//aTerm = [aTerm lowercaseString];
	
	CFIndex frequency = 0;
	SKIndexRef targetIndex = NULL;
	
	CFIndex termID = kCFNotFound;
	SKDocumentID documentID = kCFNotFound;
	
	if ( [anObject isKindOfClass:[JournlerEntry class]] )
		targetIndex = entryIndex;
	else if ( [anObject isKindOfClass:[JournlerResource class]] )
		targetIndex = referenceIndex;
	
	if ( targetIndex == NULL )
		return 0;
		
	if ( aTerm == nil || [aTerm length] == 0 )
		return 0;

	// get the document id from the document ref: documentIDForJournlerObject:options:
	documentID = [self documentIDForJournlerObject:anObject options:options];
	if ( documentID == kCFNotFound )
		return 0;
	
	// get the term id for the term: SKIndexGetTermIDForTermString
	termID = SKIndexGetTermIDForTermString( targetIndex, (CFStringRef)aTerm );
	if ( termID == kCFNotFound )
		return 0;
	
	// get the frequency of the term in the document: SKIndexGetDocumentTermFrequency
	frequency = SKIndexGetDocumentTermFrequency( targetIndex, documentID, termID);
	return frequency;
}

#pragma mark -

- (NSArray*) termsAndDocumentsArray:(unsigned)options
{
	// "term" and "journlerObjects"
	
	if ( entryIndex == NULL || referenceIndex == NULL )
	{
		NSLog(@"%s - entry index or resources index is null", __PRETTY_FUNCTION__);
		return nil;
	}
	
	if ( ![self writeIndexToDisk] )
	{
		NSLog(@"%s - unable to flush the indexes to disk", __PRETTY_FUNCTION__);
	}
	
	NSArray *allTerms = [self allTerms:options];
	NSMutableArray *termsAndDocumentsArray = [NSMutableArray arrayWithCapacity:[allTerms count]];
	
	//CFIndex maxEntryIndex = SKIndexGetMaximumTermID(entryIndex);
	//CFIndex maxResourceIndex = SKIndexGetMaximumTermID(referenceIndex);
	
    for ( NSString *aTerm in allTerms )
	{
		NSString *theTerm = aTerm;
		NSArray *journlerObjects = [self journlerObjectsForTerm:aTerm options:options];
		
		if ( [journlerObjects count] == 0 )
			NSLog(@"%@",theTerm);
		else
		{
			// once done, prepare the dictionary
			NSDictionary *aTermDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
					theTerm, @"term", 
					[NSNumber numberWithInt:[journlerObjects count]], @"objectCount",
					journlerObjects, @"journlerObjects", nil];
			
			// and add it to the main array
			[termsAndDocumentsArray addObject:aTermDictionary];
		}
	}
	
	return termsAndDocumentsArray;
}

#pragma mark -

- (NSArray*) journlerObjectsForTerm:(NSString*)aTerm options:(unsigned)options
{	
	//aTerm = [aTerm lowercaseString];
	NSMutableArray *journlerObjects = [NSMutableArray array];
	
	// bail if something is wrong with the term
	if ( aTerm == nil || [aTerm length] == 0 )
		return journlerObjects;
	
	if ( entryIndex == NULL || referenceIndex == NULL )
	{
		NSLog(@"%s - indexes unavailable", __PRETTY_FUNCTION__);
		return journlerObjects;
	}
	
	// query the indexes
	CFIndex entryTermID = SKIndexGetTermIDForTermString( entryIndex, (CFStringRef)aTerm );
	CFIndex resourceTermID = SKIndexGetTermIDForTermString( referenceIndex, (CFStringRef)aTerm );
	
	// get the entrys with these terms
	if ( entryTermID != kCFNotFound )
	{
		CFIndex documentCount = SKIndexGetTermDocumentCount( entryIndex, entryTermID );
		if ( documentCount != 0 )
		{
		
			CFArrayRef entryDocumentNumbers = SKIndexCopyDocumentIDArrayForTermID( entryIndex, entryTermID );
			
			if ( entryDocumentNumbers == NULL )
			{
				NSLog(@"%s - unable to get entry document ids for term %@ term id %ld", __PRETTY_FUNCTION__, aTerm, entryTermID);
			}
			else
			{
				//SKDocumentID  entryDocumentIDs[ kSearchMax ];
				//SKDocumentRef entryDocumentRefs[ kSearchMax ];
				
				SKDocumentID *entryDocumentIDs = calloc(documentCount,sizeof(SKDocumentID));
				SKDocumentRef *entryDocumentRefs = calloc(documentCount,sizeof(SKDocumentRef));
				
				int y, x = -1;
				// convert the array of numbers to actual documet ids
				for ( y = 0; y < CFArrayGetCount(entryDocumentNumbers); y++ ) 
				{
					SKDocumentID aDocumentID;
					if ( !CFNumberGetValue( (CFNumberRef)CFArrayGetValueAtIndex(entryDocumentNumbers,y), kCFNumberSInt32Type, &aDocumentID ) )
					{
						NSLog(@"%s - unable to get document id for document number", __PRETTY_FUNCTION__);
					}
					else
					{
						entryDocumentIDs[++x] = aDocumentID;
					}
				}
				
				//#warning memory leak! 
				// "When finished with the document URL objects array, dispose of it by calling CFRelease on each array element."
				SKIndexCopyDocumentRefsForDocumentIDs( entryIndex, CFArrayGetCount(entryDocumentNumbers), entryDocumentIDs, entryDocumentRefs );
			
				// convert the document references to entries
				for ( y = 0; y <= x; y++ ) 
				{
					NSURL *documentURI = (NSURL*)SKDocumentCopyURL(entryDocumentRefs[y]);
					
					if ( documentURI == nil )
					{
						NSLog(@"%s - unable to get url for document ref", __PRETTY_FUNCTION__);
					}
					else
					{
						JournlerEntry *theEntry = [owningJournal objectForURIRepresentation:documentURI];
						
						CFRelease(entryDocumentRefs[y]);
						
						if ( theEntry == nil ) 
						{
							//there are potentially many of these if the index is not compacted
							//NSLog(@"%s - entry object id returned nil entry: %@", __PRETTY_FUNCTION__, documentURI);
							[documentURI release];
						}
						else
						{
							// add it to the array
							[journlerObjects addObject:theEntry];
							
							// clean up
							[documentURI release];
						}
					}
				}
				
				free(entryDocumentIDs);
				free(entryDocumentRefs);
				
			} // if ( entryDocumentIDs == NULL ) : else
			
			CFRelease(entryDocumentNumbers);
			
		} // if ( SKIndexGetTermDocumentCount( entryIndex, entryTermID ) != 0 )
		
	} // if ( entryTermID != kCFNotFound )
	
	
	
	// get the resources with these terms
	if ( resourceTermID != kCFNotFound )
	{
		CFIndex documentCount = SKIndexGetTermDocumentCount( referenceIndex, resourceTermID );
		if ( documentCount != 0 )
		{
		
			CFArrayRef resourceDocumentNumbers = SKIndexCopyDocumentIDArrayForTermID( referenceIndex, resourceTermID );
			
			if ( resourceDocumentNumbers == NULL )
			{
				NSLog(@"%s - unable to get resource document ids for term %@ term id %ld", __PRETTY_FUNCTION__, aTerm, resourceTermID);
			}
			else
			{
				//SKDocumentID  entryDocumentIDs[ kSearchMax ];
				//SKDocumentRef entryDocumentRefs[ kSearchMax ];
				
				SKDocumentID *resourceDocumentIDs = calloc(documentCount,sizeof(SKDocumentID));
				SKDocumentRef *resourceDocumentRefs = calloc(documentCount,sizeof(SKDocumentRef));
				
				int y, x = -1;
				// convert the array of numbers to actual documet ids
				for ( y = 0; y < CFArrayGetCount(resourceDocumentNumbers); y++ ) 
				{
					SKDocumentID aDocumentID;
					if ( !CFNumberGetValue( (CFNumberRef)CFArrayGetValueAtIndex(resourceDocumentNumbers,y), kCFNumberSInt32Type, &aDocumentID ) )
					{
						NSLog(@"%s - unable to get document id for document number", __PRETTY_FUNCTION__);
					}
					else
					{
						resourceDocumentIDs[++x] = aDocumentID;
					}
				}
				
				//#warning memory leak! 
				// "When finished with the document URL objects array, dispose of it by calling CFRelease on each array element."
				SKIndexCopyDocumentRefsForDocumentIDs( referenceIndex, CFArrayGetCount(resourceDocumentNumbers), resourceDocumentIDs, resourceDocumentRefs );
			
				// convert the document references to entries
				for ( y = 0; y <= x; y++ ) // - why less than x here while less than equal x there
				{
					NSDictionary *documentProperties = (NSDictionary*)SKIndexCopyDocumentProperties(referenceIndex,resourceDocumentRefs[y]);
					
					if ( documentProperties == nil )
					{
						NSLog(@"%s - unable to get properties for resource document ref", __PRETTY_FUNCTION__);
					}
					else
					{
						// dealing with a file reference - convert it to the reference object
						NSURL *referenceURI = [NSURL URLWithString:[documentProperties objectForKey:@"reference"]];
						JournlerResource *theResource = [owningJournal objectForURIRepresentation:referenceURI];
						
						CFRelease(resourceDocumentRefs[y]);
						
						if ( theResource == nil ) 
						{
							//there are potentially many of these if the index is not compacted
							//NSLog(@"%s - entry object id returned nil entry: %@", __PRETTY_FUNCTION__, documentURI);
							[documentProperties release];
						}
						else
						{
							// add it to the array
							[journlerObjects addObject:theResource];
							
							// clean up
							[documentProperties release];
						}
					}
				}
				
				free(resourceDocumentIDs);
				free(resourceDocumentRefs);
				
			} // if ( entryDocumentIDs == NULL ) : else
			
			CFRelease(resourceDocumentNumbers);
			
		} // if ( SKIndexGetTermDocumentCount( entryIndex, entryTermID ) != 0 )
		
	} // if ( entryTermID != kCFNotFound )
	
	return journlerObjects;
}

- (NSArray*) termsForJournlerObject:(JournlerObject*)anObject options:(unsigned)options
{
	SKIndexRef targetIndex = NULL;
	
	if ( [anObject isKindOfClass:[JournlerEntry class]] )
		targetIndex = entryIndex;
	else if ( [anObject isKindOfClass:[JournlerResource class]] )
		targetIndex = referenceIndex;
	
	if ( targetIndex == NULL )
		return nil;
	
	// get the document id
	SKDocumentID documentID = [self documentIDForJournlerObject:anObject options:options];
	if ( documentID == kCFNotFound )
		return nil;
	
	// get the terms id array
	CFArrayRef termIDRefs = SKIndexCopyTermIDArrayForDocumentID( targetIndex, documentID );
	if ( termIDRefs == NULL )
		return nil;
	
	NSArray *actualTerms = [self termsForTermIDRefs:termIDRefs index:targetIndex options:options];
	
	// clean up
	CFRelease (termIDRefs);
	
	return actualTerms;
}

#pragma mark -

- (NSArray*) termsForTermIDRefs:(CFArrayRef)termIDs index:(SKIndexRef)anIndex options:(unsigned)options
{
	if ( termIDs == NULL )
		return nil;
	
	NSMutableArray *actualTerms = [NSMutableArray array];
	
	CFIndex i;
	CFIndex maxCount = CFArrayGetCount(termIDs);
	
	for ( i = 0; i < maxCount; i++ )
	{
		CFNumberRef aNumberRef = CFArrayGetValueAtIndex(termIDs,i);
		CFIndex aTermID;
		
		if ( !CFNumberGetValue(aNumberRef,kCFNumberSInt32Type,&aTermID) )
		{
			NSLog(@"%s - problem getting term id from number ref", __PRETTY_FUNCTION__);
			continue;
		}
		
		CFIndex documentCount = SKIndexGetTermDocumentCount( anIndex, aTermID );
		if ( documentCount == 0 )
			continue;
		
		CFStringRef aTerm = SKIndexCopyTermStringForTermID( anIndex, aTermID );
		if ( aTerm == NULL )
		{
			NSLog(@"%s - unable to get term for term index %ld", __PRETTY_FUNCTION__, aTermID);
			continue;
		}
		
		else if ( (options & kIgnoreNumericTerms) && CFStringGetCharacterAtIndex(aTerm,0) < 0x0041 )
			;
		else
			[actualTerms addObject:(NSString*)aTerm];
			
		CFRelease(aTerm);
	}
	
	NSMutableSet *allSet = [NSMutableSet setWithArray:actualTerms];
	[allSet minusSet:[self stopWords]];
	return [[allSet allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	
	//return actualTerms;
}

- (SKDocumentID) documentIDForJournlerObject:(JournlerObject*)anObject options:(unsigned)options
{
	if ( anObject == nil )
		return kCFNotFound;
	
	else if ( [anObject isKindOfClass:[JournlerEntry class]] )
	{
	
		NSURL *entryIdentifier = [anObject URIRepresentation];
		SKDocumentRef entryDocumentRef = SKDocumentCreateWithURL((CFURLRef)entryIdentifier);
		if ( entryDocumentRef == NULL ) 
		{
			NSLog(@"%s - problem getting document ref for entry object: %@", __PRETTY_FUNCTION__, [anObject valueForKey:@"tagID"]);
			return kCFNotFound;
		}
		
		if ( entryIndex == NULL ) 
		{
			NSLog(@"%s - unable to get document id for entry, no search index available", __PRETTY_FUNCTION__);
			return kCFNotFound;
		}
		
		SKDocumentID documentID = SKIndexGetDocumentID(entryIndex,entryDocumentRef);
		return documentID;
	
	}
	
	else if ( [anObject isKindOfClass:[JournlerResource class]] )
	{
		// only include references the user would like to search through
		if ( ![[anObject valueForKey:@"searches"] boolValue] || [[anObject valueForKeyPath:@"entry.markedForTrash"] boolValue] )
			return kCFNotFound;
	
		// make sure the index is available
		if ( referenceIndex == NULL ) 
		{
			NSLog(@"%s - unable to get document id reference, no search index available", __PRETTY_FUNCTION__);
			return kCFNotFound;
		}
		
		// support is only included for files and contacts - no urls yet although that would be very cool
		if ( !([(JournlerResource*)anObject representsFile] || [(JournlerResource*)anObject representsABRecord]) || 
				( [(JournlerResource*)anObject representsFile] && [[(JournlerResource*)anObject valueForKey:@"uti"] isEqualToString:ResourceUnknownUTI] ) )
		{
			return kCFNotFound;
		}
		
		// determine how the resource will be identified in the search index
		NSURL *referenceIdentifier = nil;
		JournlerResource *anEntry = [anObject valueForKey:@"entry"];
		
		if ( [(JournlerResource*)anObject representsFile] )
		{
			NSString *originalPath = [(JournlerResource*)anObject originalPath];
			if ( originalPath != nil )
				referenceIdentifier = [NSURL fileURLWithPath:[(JournlerResource*)anObject originalPath]];
		}
		
		else if ( [(JournlerResource*)anObject representsABRecord] || [(JournlerResource*)anObject representsURL] )
			referenceIdentifier = [anObject URIRepresentation];
		
		if ( referenceIdentifier == nil )
		{
			NSLog(@"%s - problem getting url identifier for reference %@-%@", __PRETTY_FUNCTION__, 
					[anEntry valueForKey:@"tagID"], [anObject valueForKey:@"tagID"]);
			return kCFNotFound;
		}
		
		// create and check the SKDocumentRef
		SKDocumentRef referenceDocumentRef = SKDocumentCreateWithURL((CFURLRef)referenceIdentifier);
		if ( referenceDocumentRef == NULL ) 
		{
			NSLog(@"%s - problem getting document reference for reference %@-%@", __PRETTY_FUNCTION__, 
					[anEntry valueForKey:@"tagID"], [anObject valueForKey:@"tagID"]);
			return kCFNotFound;
		}
		
		SKDocumentID documentID = SKIndexGetDocumentID(referenceIndex,referenceDocumentRef);
		return documentID;
	
	}
	
	else
	{
		return kCFNotFound;
	}

}

@end

/*
@implementation NSString (StringAsDelegateForWebarchiveIndexingCrash)

- (id) delegate
{
	return nil;
	// what the hell is going on here?
}

@end
*/
