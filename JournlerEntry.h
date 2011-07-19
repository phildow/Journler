/* JournlerEntry */

#import <Cocoa/Cocoa.h>
#import <Security/Security.h>
#import <AddressBook/AddressBook.h>

#import "JournlerObject.h"
#import "JournlerResource.h"

#define PDEntryTitle				@"Entry Title"
#define PDEntryCategory				@"Entry Category"
#define PDEntryKeywords				@"Entry Keywords"
#define PDEntryTag					@"Entry Tag"
#define PDEntryBlogs				@"Entry Blogs"
#define PDEntryFlagged				@"Entry Flagged"
#define PDEntryLabelColor			@"Entry Label Color"
#define PDEntryAtttibutedContent	@"Entry Attributed Content"
#define PDEntryCalDate				@"Entry Cal Date"
#define PDEntryCalDateModified		@"Entry Cal Date Modified"
#define PDEntryCalDateDue			@"Entry Cal Date Due"
#define PDEntryVersion				@"Entry Version Number"
#define PDEntryMarkedForTrash		@"Entry Marked For Trash"

#define PDEntryResourceIDs			@"PDEntryResourceIDs"

//2.5.4
#define PDEntryComments				PDEntryKeywords
#define PDEntryTags					@"Entry Tags"

//
// deprecated
#define PDEntryDateModified			@"Entry Date Modified"
#define PDEntryDate					@"Entry Date"
#define PDEntryTimestamp			@"Entry Timestamp"
#define PDEntryRTFD					@"Entry RTFD"
#define PDEntryViewMode				@"Entry View Mode"
#define PDEntrySelectedMediaURL		@"EntryMediaURL"
#define PDEntryStringValue			@"EntryStringValue"
#define PDEntrySearchMedia			@"PDEntrySearchMedia"
#define PDEntryLastSelectedResource	@"EntryLastSelectedResource"

//
// for storing an entrys data in the file package
#define PDEntryPackageEncrypted					@".encrypted"
#define	PDEntryPackageEntryContents				@"Contents.jobj"
#define PDEntryPackageRTFDContent				@"Entry.rtfd"
#define PDEntryPackageRTFDContainer				@"_Text.jrtfd"
#define PDEntryPackageResources					@"Resources"


#define EntryWillAddResourceNotification		@"EntryWillAddResourceNotification"
#define EntryDidAddResourceNotification			@"EntryDidAddResourceNotification"

#define EntryWillRemoveResourceNotification		@"EntryWillRemoveResourceNotification"
#define EntryDidRemoveResourceNotification		@"EntryDidRemoveResourceNotification"

typedef enum {

	kEntrySaveAsRTF = 0,
	kEntrySaveAsWord = 1,
	kEntrySaveAsRTFD = 2,
	kEntrySaveAsPDF = 3,
	kEntrySaveAsHTML = 4,
	kEntrySaveAsText = 5,
	kEntrySaveAsiPodNote = 6,
	kEntrySaveAsPackage = 7,
	kEntrySaveAsWebArchive = 8
	
} EntrySaveFileTypes;

enum {
	kEntrySetFileCreationDate = 1 << 1,
	kEntrySetFileModificationDate = 1 << 2,
	kEntryIncludeHeader = 1 << 3,
	kEntrySetLabelColor = 1 << 4,
	kEntryHideExtension = 1 << 5,
	kEntryDoNotOverwrite = 1 << 6
} EntrySaveFlags;

enum {
	kEntryImportIncludeIcon = 1 << 1,
	kEntryImportSetDefaultResource = 1 << 2,
	kEntryImportPreserveDateModified = 1 << 3
} EntryImportOptions;

@class BlogPref;
@class JournlerJournal;
@class JournlerResource;

@interface JournlerEntry : JournlerObject <NSCopying, NSCoding>
{
	
	//
	// The JournlerEntry instance variables.
	//
	//		// Do not modify these variables directly
	//		// Use the appropriate accessors to alter the entry's contents
	//
	
	// relationships
	NSArray *collections;
	NSArray *resources;
	
	// used when re-establishing the entry-resource relationships during load
	NSArray *resourceIDs;
	NSNumber *lastResourceSelectionID;
	
	// container for AppleScript support
	NSTextStorage *scriptContents;
	
	// relevance is used during searching
	float relevance;
	
	// the date integer is an integer representation of an entry's date,
	// cached to speed up the calendar and smart folders. It is regenerated
	// whenever the date changes
	NSInteger _dateInt;
	
	// used internally during file imports, necessary in Journler 2.0 due to
	// the way Journler packages entries
	NSString *_import_path;
	NSDate *_importModificationDate;
	
	//
	NSString *_resourceTypesCached;
	
	
	NSInteger _contentRetainCount;
	NSTimeInterval _lastContentAccess;
	
	// indicates whether an entry is encrypted or not. 
	// DEPCREATED
	NSNumber *encrypted;
}

//
// The Journler initializers
//
//		// Your plugin should not need to call these methods
//

- (id) initWithPath:(NSString*)path;

//
// The NSDictionary properties contains all of an entry's persistent data
//
//		// Normally you should use the other accessors to acquire and modify the entry's contents
//		// Directly access the properties dictionary only when you need to work with your own properties
//		// If you add new properties to the dictionary they will be persistent, 
//		   but Journler will not know how to access and use them. Not yet anyway
//

//
//
// relationships

- (NSArray*) collections;
- (void) setCollections:(NSArray*)anArray;

// resources describes references to other files, contacts, urls, etc
- (NSArray*) resources;
- (void) setResources:(NSArray*)anArray;

#pragma mark -

- (NSArray*) resourceIDs;
- (void) setResourceIDs:(NSArray*)anArray;

- (NSNumber*) lastResourceSelectionID;
- (void) setLastResourceSelectionID:(NSNumber*)aNumber;

#pragma mark -

//
// The NSString date indicates the date to which the entry belongs
//
//		// Deprecated. Do not use this method any more
//		// Use calDate instead, which returns an NSCalendarDate object
//

- (NSString*) date;

//
// The NSString title is the entry's title
//
//		// The title is often the most important means of entry identification
//		// If the user is running Tiger, smart folders can identify an entry by its timestamp
//		// The title can be any string and can include unicode characters
//		// Entries are not stored by title, so more than one entry can have the same title
//
//		// The pathSafeTitle filters an entry's title for against reserved characters
//		// You could use it when exporting the entry content's to a separate file
//
//		// previouslySavedTitle is a utility method used by the journal when saving
//		// a renamed entry. You do not need to use it, and do not change it.
//

- (NSString*) pathSafeTitle;
- (NSString*) wikiTitle;

//
// The calDate and calDateModified properties place an entry at a dated location
// ( New in Journle 2.0 - they replace the date and dateModified properties )
//
//		// calDate and calDateModified use NSCalendarDate objects
//		// The date and dateModified methods are deprecated. Do not use them.
//	
//		// Be careful NOT to use NSDate objects. NSCalendarDate objects are expected
//		// To convert an NSDate to an NSCalendarDate, use NSDate's
//		//		dateWithCalendarFormat:timeZone - you may pass nil for both parameters
//

- (NSCalendarDate*) calDate;
- (void) setCalDate:(NSCalendarDate*)date;

- (NSCalendarDate*) calDateModified;
- (void) setCalDateModified:(NSCalendarDate*)date;

- (NSCalendarDate*) calDateDue;
- (void) setCalDateDue:(NSCalendarDate*)date;

//
// The NSString category is the entry's abstract category
//
//		// The category is an abstract way of grouping the entry with other entries
//		// Standard categories include Personal, Dreams, and Work, etc
//		// If the user is running Tiger, smart folders can identify an entry by its category
//		// The category can be any string and can include unicode characters
//

- (NSString*) category;
- (void) setCategory:(NSString*)newObject;

//
// The NSString keywords is a further means of abstractly handling an entry
//
//		// The keywords property quickly identifies an entry by key concepts it deals with
//		// The user can format the string in any way, ie a comma separated list or a complete sentence
//		// If the user is running Tiger, smart folders can identify an entry by its keywords
//		// The keywords string can be any string and can include unicode characters
//

- (NSString*) keywords;
- (void) setKeywords:(NSString*)newObject;

// as of 2.5.4, keywords then referred to as tags become comments
- (NSString*) comments;
- (void) setComments:(NSString*)newObject;

//
// as of 2.5.3, tags as an array takes over from keywords/tags as a string

- (NSArray*) tags;
- (void) setTags:(NSArray*)newObject;

//
// The attributedContent is the entry's main content as an attributed string object
// ( New in Journler 2.0 - the 1.x format used rich text data )
//
//		// ************
//		// Your plugin subclass will most likely need to focus on this property
//		// ************
//

- (NSAttributedString*) attributedContent;
- (void) setAttributedContent:(NSAttributedString*)content;

// returns the attributed content if it's loaded, nil otherwise
- (NSAttributedString*) attributedContentIfLoaded;

- (BOOL) loadAttributedContent;
- (NSString*) attributedContentPath;

// increments the retain count on the attributed content
// if you're using the attributed content you should call this method to prevent journler from emptying the cache
// at an unspecified interval
- (void) retainContent;
- (void) releaseContent;
- (NSInteger) contentRetainCount;
- (NSTimeInterval) lastContentAccess;
- (void) unloadAttributedContent;

//
//
//

- (JournlerResource*) selectedResource;
- (void) setSelectedResource:(JournlerResource*)aResource;

//
// The version identifies an entry's formatting as an integer value
// ( New in Journler 2.0 )
//
//		// The current version number is 120.
//		// A more appropriate value would be 200, but Journler 2.0 was originally 1.2
//

- (NSNumber*)version;
- (void) setVersion:(NSNumber*)verNum;

//
// markedForTrash indicates an entry's "trashed" status
//
//		// When an entry is deleted from a date or the journal collection, 
//		// it is placed in the trash
//		// Entries are only permanently removed when they are deleted from the trash 
//		// or when the trash is emptied
//

- (NSNumber*) markedForTrash;
- (void) setMarkedForTrash:(NSNumber*)mark;

//
// The NSArray blogs property contains a list of blogs to which this entry has been posted
//
//		// The blogs array contains BlogPref objects
//
//		// You should not modify this property yet. I need to make further changes
//		// to blog tracking first
//

- (NSArray*) blogs;
- (void) setBlogs:(NSArray*)newObject;

//
// flagged provides an  way of marking an entry.
//
//		// The user can flag an entry for any reason, a personal way of assigning significance 
//		// Smart folders can filter entries based on the flag property
//

- (NSNumber*) marked;
- (void) setMarked:(NSNumber*)aValue;

- (NSInteger) markedInt;
- (void) setMarkedInt:(NSInteger)aValue;

- (NSNumber*) flagged;
- (void) setFlagged:(NSNumber*)flagValue;

- (BOOL) flaggedBool;
- (void) setFlaggedBool:(BOOL)flagValue;

- (BOOL) checkedBool;
- (void) setCheckedBool:(BOOL)aValue;

//
// The label provides yet another way of marking an entry.
//
//		// The user can label an entry for any reason, a personal way of assigning significance 
//		// Smart folders can filter entries based on the label property
//		// A label's value runs from 0 to 6, 0 is none while 1 through 6 indicate color
//

- (NSNumber*) label;
- (void) setLabel:(NSNumber*)val;

//
// The float relevance is an entry's relevance during toolbar searching
//
//		// Your plugin should not modify this value
//		// Relevance comes and goes as the search query changes
//		// The relevance value is not cleared after a search, do not rely on its value
//

- (float) relevance;
- (void) setRelevance:(float)nr;

//
// The NSString relevanceString and NSNumber relevanceNumber are an entry's relevance as cocoa objects
//
//		// Your plugin should not need to operate on these value
//		// Relevance comes and goes as the search query changes
//		// The relevance value is not cleared after a search, do not rely on its value
//		// Utility methods to convert the actual relevance into a useful cocoa object
//

- (NSNumber*) relevanceNumber;

//
// The boolean encrypted indicates an entry's encryption status
//
//		// A true value indicates the entry will be encrypted when it is written to disk
//		// An entry's contents are no encrypted when in memory
//		// Do not modify this value, your modifications will be ignored
//

- (NSNumber*) encrypted;
- (void) setEncrypted:(NSNumber*)encrypt;

//
// The integers dateInt, timeInt and dateModifiedInt indicate the date and time in integer format
//
//		// Smart folders use this information to quickly assess one entry's date or time
//		   relationship to another, ie before, after, or on
//		// An entry whose date is January 12th 2005 will have a dateInt value of 20050112
//		// the dateInt value is cached because it is used so often
//

- (NSInteger) dateInt;
- (NSInteger) dateModifiedInt;
- (NSInteger) dateCreatedInt;
- (NSInteger) dateDueInt;

- (void) generateDateInt;

- (NSInteger) labelInt;

//
// The boolean blogged quickly indicates whether an entry has been blogged or not
//
//		// The method simply looks at the blogs array and returns true if the count is greater than zero
//		// Smart folders use this information to determine an entry's blogged status
//		// setBlogged: does nothing but provides a cheat for key-value observing
//

- (BOOL) blogged;
- (void) setBlogged:(BOOL)isBlogged;

//
// The addBlog: and hasBlog: methods are utiltiy methods related to blog tracking
//
//		// Utility methods used by Journler's blog center to keep track of blog postings
//		// If you would like to check whether an entry has been posted to a certain blog,
//		   use the hasBlog: method passing in an appropriate dictionary
//
//		// Do no use these methods until I have had a chance 
//		// to improve Journler's blog tracking functionality
//

- (BOOL) hasBlog:(id)whichBlog;
- (void) addBlog:(id)whichBlog;

//
// The number numberOfResources quickly indicates whether an entry has resources or not
//
//		// The method simply looks at the resources array and returns the count
//		// Tables use this information to indicate an entry's resource status
//		// setNumberOfResources: does nothing but provides a cheat for key-value observing
//

- (NSInteger) numberOfResources;
- (void) setNumberOfResources:(NSInteger)numResources;

//
// The content value is the same as returned by stringValue
// entireEntry returns a string representation of the entry's title, category, keywords and content
//
//		// These methods are utility methods used during searching.
//		// Use them if you need a string representation of an entry
//

- (NSString*) content;
- (NSString*) entireEntry;

//
// The defaultTextAttributes is a starting point for an entry's textual attributes
//
//		// defaultTextAttributes provides the user defined font, color and paragraph attributes
//		// for new entries. Use these values if you are adding plain text content to an entry
//
//		// Better yet, examine the attributes at the point where you are inserting the text
//		// and use those.
//

+ (NSDictionary*) defaultTextAttributes;

//
// The performOneTwoMaintenance method is a utility used during the 1.1 -> 2.0 conversion
//
//		// Do not call this method.
//		// It may have no effect or it may produce unexpected results
//

- (BOOL) performOneTwoMaintenance:(NSMutableString**)log;
- (void) perform210Maintenance;
- (void) perform253Maintenance;


//- (NSURL*) URIRepresentation;
- (NSString*) searchableContent;
- (NSDictionary*) metadata;

//
// for including entries with specific resources in smart folders

- (NSString*) allResourceTypes;
- (void) setAllResourceType:(NSString*)aString;

- (void) invalidateResourceTypes;

// DEPRECATED
- (NSNumber*) labelValue;
- (void) setLabelValue:(NSNumber*)aNumber;

// END --------------------------------------------------------

@end

@interface JournlerEntry (ResourceAndMediaManagement)

- (JournlerResource*) resourceForABPerson:(ABPerson*)aPerson;
- (JournlerResource*) resourceForURL:(NSString*)urlString title:(NSString*)title;
- (JournlerResource*) resourceForFile:(NSString*)path operation:(NewResourceCommand)operation;
- (JournlerResource*) resourceForJournlerObject:(id)anObject;

- (JournlerResource*) addResource:(JournlerResource*)aResource;
- (BOOL) removeResource:(JournlerResource*)aResource;

- (BOOL) resourcesIncludeFile:(NSString*)filename;

- (NSArray*) textualLinks;

// replacement methods used in 2.1
- (NSString*) packagePath;
- (NSString*) resourcesPathCreating:(BOOL)create;

// DEPRECATED (from 2.0)
- (NSString*) pathToPackage;
- (NSString*) pathToResourcesCreatingIfNecessary:(BOOL)create;
- (NSArray*) allResourcePaths;

// DEPRECATED
- (NSURL*) selectedMedia;
- (void) setSelectedMedia:(NSURL*)url;

// DEPRECATED
- (NSNumber*) searchesMedia;
- (void) setSearchesMedia:(NSNumber*)includeMedia;

// DEPRECATED
- (NSURL*) fileURLForResourceURL:(NSURL*)url;
- (NSURL*) fileURLForResourceFilename:(NSString*)filename;

@end

// DEPRECATED
/*
@interface JournlerEntry (EncryptionSupport)

- (id) initWithEncryptedPath:(NSString*)path CSSMHandle:(CSSM_CSP_HANDLE*)handle CSSMKey:(CSSM_KEY*)key;

@end
*/

@interface JournlerEntry (InterfaceSupport)

+ (BOOL) canImportFile:(NSString*)fullpath;
- (id) initWithImportAtPath:(NSString*)fullpath options:(NSInteger)importOptions maxPreviewSize:(NSSize)maxSize;
- (BOOL) completeImport:(NSInteger)importOptions operation:(NewResourceCommand)operation maxPreviewSize:(NSSize)maxSize;

- (BOOL) writeToFile:(NSString*)path as:(NSInteger)saveType flags:(NSInteger)saveFlags;
//- (BOOL) createFolderAtDestination:(NSString*)path;

- (NSAttributedString*) prepWithTitle:(BOOL)wTitle category:(BOOL)wCategory smallDate:(BOOL)wDate;

- (BOOL) _writeiPodNote:(NSString*)contents iPod:(NSString*)path;

- (NSString*) htmlRepresentationWithCache:(NSString*)cachePath;

@end

@interface JournlerEntry (PreferencesSupport)

+ (BOOL) modsDateModdedOnlyOnTextualChange;
+ (NSString*) defaultCategory;
+ (NSString*) dropBoxCategory;

@end

@interface JournlerEntry (JournlerScriptability)

//- (id) scriptContainer;
//- (void) setScriptContainer:(id)anObject;

- (NSTextStorage*) contents;
- (void) setContents:(id)anObject;

- (NSAttributedString*) processScriptSetContentsForLinks:(NSAttributedString*)anAttributedString;

- (OSType) scriptLabel;
- (void) setScriptLabel:(OSType)osType;

- (OSType) scriptMark;
- (void) setScriptMark:(OSType)osType;

- (NSDate*) dateCreated;
- (void) setDateCreated:(NSDate*)aDate;

- (NSDate*) dateModified;
- (void) setDateModified:(NSDate*)aDate;

- (NSDate*) dateDue;
- (void) setDateDue:(NSDate*)aDate;

- (NSString*) htmlString;

- (JournlerResource*) scriptSelectedResource;
- (void) setScriptSelectedResource:(id)anObject;

//
// The NSString stringValue is the entry's RTFD content as a string
//
//		// The method converts only the attributed content into string object
//		// Use this method to quickly access an entry's string content when you do not
//		   need all the information containted in an attributed string
//

- (NSString*) stringValue;
- (void) setStringValue:(id)sv;

- (NSString*) URIRepresentationAsString;

#pragma mark -

- (NSInteger) indexOfObjectInJSReferences:(JournlerResource*)aReference;
- (NSUInteger) countOfJSReferences;
- (JournlerResource*) objectInJSReferencesAtIndex:(NSUInteger)i;
- (JournlerResource*) valueInJSReferencesWithUniqueID:(NSNumber*)idNum;

#pragma mark -

- (void) jsExport:(NSScriptCommand *)command;
- (void) jsAddEntryToFolder:(NSScriptCommand *)command;
- (void) jsRemoveEntryFromFolder:(NSScriptCommand *)command;

@end