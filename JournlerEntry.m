#import "JournlerEntry.h"

#import "BlogPref.h"
#import "JournlerResource.h"
#import "JournlerJournal.h"
#import "JournlerCollection.h"

#import <WebKit/WebKit.h>
#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>

#import "PDSingletons.h"
#import "Definitions.h"

#import "NSAttributedString+JournlerAdditions.h"
#import "NSArray_JournlerAdditions.h"
#import "NSURL+JournlerAdditions.h"

static short kFinderLabelForEntryLabel[8] = { 0, 6, 7, 5, 2, 4, 3, 1 };
static short kEntryLabelForFinderLabel[8] = { 0, 7, 4, 6, 5, 3, 1, 2 };

static NSString *kTextClippingExtension = @"textClipping";
static NSString *kWeblocExtension = @"webloc";
static NSString *kPDUTTypeWordDocument = @"com.microsoft.word.doc";


static NSArray *JObjectKeys() 
{
	static NSArray *array = nil;
	if ( array == nil ) 
	{
		array = [[NSArray alloc] initWithObjects:
			PDEntryTitle,
			/*PDEntryCategory, */
			/*PDEntryKeywords, */
			PDEntryTag, 
			/*PDEntryBlogs, */
			/*PDEntryFlagged, */
			/*PDEntryLabelColor, */
			PDEntryCalDate,
			PDEntryCalDateModified,
			PDEntryVersion,
			PDJournalIdentifier,
			/*PDEntryMarkedForTrash, */
			nil];
	}
	return array;
}

static NSArray *JObjectValues() 
{
	static NSArray *array = nil;
	if ( array == nil ) 
	{
		array = [[NSArray alloc] initWithObjects:
			[NSString string],									// title
			/*[NSString string],*/									// category
			/*[NSString string],*/									// keywords
			[NSNumber numberWithInt:0],							// tag
			/*[NSArray array],*/									// blogs
			/*[NSNumber numberWithInt:0],*/							// marked (flagged)
			/*[NSNumber numberWithInt:0],*/							// label color
			[NSCalendarDate calendarDate],						// date as date
			[NSCalendarDate calendarDate],						// date modified as date
			[NSNumber numberWithInt:1],							// entry version format
			[NSNumber numberWithDouble:0],						// journal identifier
			/*[NSNumber numberWithBool:NO],*/						// marked for trash
			nil];		// selected ranges			
				
	}
	return array;
}

#pragma mark -
// #warning include attribute to remember the last selected range

@implementation JournlerEntry


// ============================================================
// Birth and Death
// ============================================================

- (id) init 
{
	return [self initWithProperties:nil];
}

- (id) initWithPath:(NSString*)path 
{		
	NSDictionary *tempDict;
	
	tempDict = [NSDictionary dictionaryWithContentsOfFile:path];
	if ( tempDict == nil )
		return nil;
	
	return [self initWithProperties:tempDict];
}

- (id) initWithProperties:(NSDictionary*)aDictionary
{
	if ( self = [super initWithProperties:aDictionary] )
	{
		// reset the date created and date modified if we're beginning a new entry
		if ( aDictionary == nil )
		{
			NSCalendarDate *rightNow = [NSCalendarDate calendarDate];
			[self setCalDate:rightNow];
			[self setCalDateModified:rightNow];
		}
		
		// regenerate the date int, cached and used extensively
		[self generateDateInt];
		
		// search relevance
		relevance = 0.0;
		_lastContentAccess = 0;
		
		// initialize empty relationships
		collections = [[NSArray alloc] init];
		resources = [[NSArray alloc] init];
	}
	return self;
}

+ (NSDictionary*) defaultProperties
{
	NSDictionary *defaults = [NSDictionary dictionaryWithObjects:JObjectValues() forKeys:JObjectKeys()];
	return defaults;
}

#pragma mark -

- (id)copyWithZone:(NSZone *)zone 
{	
	#if DEBUG
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	JournlerEntry *newObject = [[[self class] allocWithZone:zone] init];
	NSCalendarDate *dateModified = [[[self valueForKey:@"calDateModified"] copyWithZone:[self zone]] autorelease];
	NSAttributedString *content = [[[self attributedContent] copyWithZone:[self zone]] autorelease];
	
	[newObject setProperties:[self properties]];
	
	[newObject setJournal:[self journal]];
	[newObject setCollections:[self collections]];
	[newObject setDeleted:[self deleted]];
	
	newObject->_dateInt = _dateInt;
	newObject->encrypted = encrypted;
	newObject->relevance = relevance;

	[newObject setScriptContainer:[self scriptContainer]];
	
	// tag and journal
	[newObject setTagID:[NSNumber numberWithInt:[[self journal] newEntryTag]]];
	[[self journal] addEntry:newObject];
	
	[newObject setValue:dateModified forKey:@"calDateModified"];
	[newObject setValue:content forKey:@"attributedContent"];
	[newObject setDirty:BooleanNumber(YES)];
	
	return newObject;
}

- (void) dealloc 
{
	[collections release], collections = nil;
	[resources release], resources = nil;
	
	[resourceIDs release], resourceIDs = nil;
	[lastResourceSelectionID release], lastResourceSelectionID = nil;
	
	[scriptContents release], scriptContents = nil;
	
	//_import_path and _importModificationDate are usually released immediately after use
	[_import_path release], _import_path = nil;
	[_importModificationDate release], _importModificationDate = nil;
	
	[super dealloc];
}

#pragma mark -

+ (NSDictionary*) defaultTextAttributes 
{	
	//
	// the default font - archive this!
	NSFont *defaultFont = [NSFont systemFontOfSize:15.0];
	NSData *defaultFontData = [[NSUserDefaults standardUserDefaults] dataForKey:@"DefaultEntryFont"];
	if ( defaultFontData != nil )
		defaultFont = [NSUnarchiver unarchiveObjectWithData:defaultFontData];
		
	if ( defaultFont == nil || ![defaultFont isKindOfClass:[NSFont class]] ) 
	{
		NSString *fontFamName = [[NSUserDefaults standardUserDefaults] objectForKey:@"Journler Default Font"];
		NSString *fontSize = [[NSUserDefaults standardUserDefaults] objectForKey:@"Text Font Size"];
		
		if ( fontFamName && fontSize ) 
		{
			defaultFont = [[NSFontManager sharedFontManager] convertFont:defaultFont toFace:fontFamName];
			defaultFont = [[NSFontManager sharedFontManager] convertFont:defaultFont toSize:[fontSize floatValue]];
		}
	}
	
	//
	// the default color
	NSColor *defaultColor = nil;
	NSData *defaultColorData = [[NSUserDefaults standardUserDefaults] dataForKey:@"Entry Text Color"];
	if ( defaultColorData != nil )
		defaultColor = [NSUnarchiver unarchiveObjectWithData:defaultColorData];
	else
		defaultColor = [NSColor blackColor];
	
	//
	// the default paragraph style
	NSParagraphStyle *defaultParagraph;
	NSData *paragraphData = [[NSUserDefaults standardUserDefaults] dataForKey:@"DefaultEntryParagraphStyle"];
	if ( paragraphData != nil )
		defaultParagraph = [NSUnarchiver unarchiveObjectWithData:paragraphData];
	else
		defaultParagraph = [NSParagraphStyle defaultParagraphStyle]; 
	
	//
	// put it all together
	NSDictionary *attr = [[NSDictionary alloc] initWithObjectsAndKeys:
		defaultFont, NSFontAttributeName, 
		defaultColor, NSForegroundColorAttributeName, 
		defaultParagraph, NSParagraphStyleAttributeName, nil];
		
	return [attr autorelease];	
}

#pragma mark -
#pragma mark NSCoding Protocol (v1.2)

- (id)initWithCoder:(NSCoder *)decoder 
{	
	// decode the properties
	NSDictionary *archivedProperties = [decoder decodeObjectForKey:@"JObjectProperties"];
	if ( archivedProperties == nil ) return nil; // some kind of error
	
	// decode the resources
	NSArray *theResources = [decoder decodeObjectForKey:@"Resources"];
	NSArray *theResourcesIDs = [decoder decodeObjectForKey:@"AllResourceIDs"];
	NSNumber *lastResourceID = [decoder decodeObjectForKey:@"LastResourceID"];
	
	// decode the collection ids: unused
	//NSArray *theCollectionIDs = [decoder decodeObjectForKey:@"CollectionsIDs"];
	
	if ( self = [self initWithProperties:archivedProperties] ) 
	{
		if ( theResources != nil )
		{
			[self setValue:theResources forKey:@"resources"];
			
			// re-establish the relationship between the entry and the resources
			[theResources makeObjectsPerformSelector:@selector(setEntry:) withObject:self];
			// the journal will re-establish the relationship between itself and the resources
			
			if ( [lastResourceID intValue] != NSNotFound )
			{
				NSArray *objectHits = [theResources objectsWithValue:lastResourceID forKey:@"tagID"];
				if ( [objectHits count] == 1 )
					[self setSelectedResource:[objectHits objectAtIndex:0]];
			}
		}
		
		else if ( theResourcesIDs != nil )
		{
			[self setResourceIDs:theResourcesIDs];
			[self setLastResourceSelectionID:lastResourceID];
			// the journal will re-establish the relationships between the entry and its resources
		}
	}
	
	return self;
}


- (void)encodeWithCoder:(NSCoder *)encoder 
{		
	if ( ![encoder allowsKeyedCoding] ) 
	{
		NSLog(@"%s - cannot encode entry without a keyed archiver", __PRETTY_FUNCTION__);
		return;
	}
	
	// prepare the properties without the attributed content or last selected resource
	NSMutableDictionary *encodableProperties = [[[self valueForKey:@"properties"] mutableCopyWithZone:[self zone]] autorelease];
	[encodableProperties removeObjectForKey:PDEntryAtttibutedContent];
	
	NSNumber *lastResourceID;
	JournlerResource *lastResourceSelection = [encodableProperties objectForKey:PDEntryLastSelectedResource];
	if ( lastResourceSelection == nil )
		lastResourceID = [NSNumber numberWithInt:NSNotFound];
	else
		lastResourceID = [lastResourceSelection tagID];
	
	[encodableProperties removeObjectForKey:PDEntryLastSelectedResource];
	
	// resources are encoded as is - would it be better to put this in the store (as well)?
	NSArray *theResources = [self valueForKey:@"resources"];
	NSArray *theResourceIDs = [self valueForKeyPath:@"resources.tagID"];
	
	// collections keep only the ids : unused
	//int i;
	//NSArray *theCollections = [self valueForKey:@"collections"];
	//NSMutableArray *collectionIDs = [NSMutableArray arrayWithCapacity:[theCollections count]];
	
	//for ( i = 0; i < [theCollections count]; i++ )
		//[collectionIDs addObject:[[theCollections objectAtIndex:i] valueForKey:@"tagID"]];
	
	// encode the whole lot of it
	[encoder encodeObject:encodableProperties forKey:@"JObjectProperties"];
	[encoder encodeObject:lastResourceID forKey:@"LastResourceID"];
	
	// encode the resource only if we're version 210
	if ( [(NSNumber*)[[self journal] version] intValue] < 250 )
		[encoder encodeObject:theResources forKey:@"Resources"];
	
	// otherwise encode the ids
	else
		[encoder encodeObject:theResourceIDs forKey:@"AllResourceIDs"];
	
	//[encoder encodeObject:collectionIDs forKey:@"CollectionsIDs"];
}

#pragma mark -

- (NSScriptObjectSpecifier *)objectSpecifier 
{	
	NSScriptClassDescription* appDesc = (NSScriptClassDescription*)[NSApp classDescription];
		
	NSUniqueIDSpecifier *specifier = [[NSUniqueIDSpecifier allocWithZone:[self zone]]
			initWithContainerClassDescription:appDesc containerSpecifier:nil
			key:@"JSEntries" uniqueID:[self tagID]];
		
	return [specifier autorelease];
}

- (NSAppleEventDescriptor *)aeDescriptorValue
{
	return nil;
}

#pragma mark -
#pragma mark Relationships

- (NSArray*) collections
{
	return collections;
}

- (void) setCollections:(NSArray*)anArray
{
	if ( collections != anArray )
	{
		[collections release];
		collections = [anArray copyWithZone:[self zone]];
	}
}

- (NSArray*) resources
{
	return resources;
}

- (void) setResources:(NSArray*)anArray
{
	if ( resources != anArray )
	{
		[resources release];
		resources = [anArray copyWithZone:[self zone]];
		
		[self setValue:BooleanNumber(YES) forKey:@"dirty"];
	}
}

#pragma mark -
#pragma mark Relationships Identifiers Used During Load

- (NSArray*) resourceIDs
{
	return resourceIDs;
}

- (void) setResourceIDs:(NSArray*)anArray
{
	if ( resourceIDs != anArray )
	{
		[resourceIDs release];
		resourceIDs = [anArray copyWithZone:[self zone]];
	}
}

- (NSNumber*) lastResourceSelectionID
{
	return lastResourceSelectionID;
}

- (void) setLastResourceSelectionID:(NSNumber*)aNumber
{
	if ( lastResourceSelectionID != aNumber )
	{
		[lastResourceSelectionID release];
		lastResourceSelectionID = [aNumber copyWithZone:[self zone]];
	}
}

#pragma mark -

- (NSNumber*) encrypted
{
	return encrypted;
}

- (void) setEncrypted:(NSNumber*)encrypt
{
	if ( ![encrypted isEqualToNumber:encrypt] )
	{
		[encrypted release];
		encrypted = [encrypt retain];
		
		[self setValue:BooleanNumber(YES) forKey:@"dirty"];
	}
}

#pragma mark -

// ============================================================
// False Accessors - Ensures Backwards Compatibility
// ============================================================

//
// 1.2 Changes
- (NSString*) date 
{ 
	//NSLog(@"JObject date: this method has been deprecated, please use calDate instead");	
	return [[_properties objectForKey:PDEntryCalDate] descriptionWithCalendarFormat:@"%Y-%m-%d" 
			timeZone:nil 
			locale:nil];		
}

// --------
#pragma mark -

+ (NSString*) tagIDKey
{
	return PDEntryTag;
}

+ (NSString*) titleKey
{
	return PDEntryTitle;
}

#pragma mark -

- (void) setTitle:(NSString*)aString
{
	// override to add support for date modified and wiki linking
	NSString *oldTitle = [[_properties objectForKey:PDEntryTitle] retain];
	
	[super setTitle:aString];
	[[self journal] entry:self didChangeTitle:[oldTitle autorelease]];
	
	if ( ![JournlerEntry modsDateModdedOnlyOnTextualChange] )
		[self setValue:[NSCalendarDate calendarDate] forKey:@"calDateModified"];
}

- (NSString*) pathSafeTitle 
{	
	return [[self title] pathSafeString];		
}

- (NSString*) wikiTitle
{
	NSMutableString *wikiTitle = [[[[self valueForKey:@"title"] capitalizedString] mutableCopyWithZone:[self zone]] autorelease];
	if ( [[wikiTitle componentsSeparatedByString:@" "] count] <= 1 )
		return nil;
	
	[wikiTitle replaceOccurrencesOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] withString:@"" 
			options:0 range:NSMakeRange(0,[wikiTitle length])];
			
	return wikiTitle;
}

- (NSString*) category 
{ 
	NSString *category = [_properties objectForKey:PDEntryCategory];
	if ( category == nil ) category = EmptyString();
	return category;
	
	//return [_properties objectForKey:PDEntryCategory]; 
}

- (void) setCategory:(NSString*)newObject 
{
	[_properties setObject:(newObject?newObject:[NSString string]) forKey:PDEntryCategory];
	
	[self setValue:BooleanNumber(YES) forKey:@"dirty"];
	
	if ( ![JournlerEntry modsDateModdedOnlyOnTextualChange] )
		[self setValue:[NSCalendarDate calendarDate] forKey:@"calDateModified"];
}


- (NSString*) keywords 
{ 
	NSString *keywords = [_properties objectForKey:PDEntryKeywords];
	if ( keywords == nil ) keywords = EmptyString();
	return keywords;
	
	//return [_properties objectForKey:PDEntryKeywords]; 
}

- (void) setKeywords:(NSString*)newObject 
{
	[_properties setObject:(newObject?newObject:[NSString string]) forKey:PDEntryKeywords];
	[self setValue:BooleanNumber(YES) forKey:@"dirty"];
	
	if ( ![JournlerEntry modsDateModdedOnlyOnTextualChange] )
		[self setValue:[NSCalendarDate calendarDate] forKey:@"calDateModified"];
}

- (NSArray*) tags
{
	NSArray *tags = [_properties objectForKey:PDEntryTags];
	if ( tags == nil ) tags = EmptyArray();
	return tags;
}

- (void) setTags:(NSArray*)newObject
{
	NSArray *oldTags = [[_properties objectForKey:PDEntryTags] retain];
	
	//[_properties setObject:( newObject ? [newObject valueForKey:@"lowercaseString"] : [NSArray array] ) forKey:PDEntryTags];
	[_properties setObject:( newObject ? newObject : [NSArray array] ) forKey:PDEntryTags];
	
	[self setValue:BooleanNumber(YES) forKey:@"dirty"];
	[[self journal] entry:self didChangeTags:[oldTags autorelease]];
	
	if ( ![JournlerEntry modsDateModdedOnlyOnTextualChange] )
		[self setValue:[NSCalendarDate calendarDate] forKey:@"calDateModified"];
}

- (NSString*) comments
{
	return [self keywords];
}

- (void) setComments:(NSString*)newObject
{
	[self setKeywords:newObject];
}

#pragma mark -

- (NSAttributedString*) attributedContent { 
	
	// lazily load the attributed content
	NSAttributedString *attributedContent = [_properties objectForKey:PDEntryAtttibutedContent];
	if ( attributedContent == nil )
	{
		[self loadAttributedContent];
		attributedContent = [_properties objectForKey:PDEntryAtttibutedContent];
	}
	
	_lastContentAccess = [NSDate timeIntervalSinceReferenceDate];
	
	return attributedContent;
}

- (void) setAttributedContent:(NSAttributedString*)content 
{
	[_properties setObject:(content?content:[[[NSAttributedString alloc] init] autorelease]) forKey:PDEntryAtttibutedContent];
	
	[self setValue:BooleanNumber(YES) forKey:@"dirty"];
	[self setValue:[NSCalendarDate calendarDate] forKey:@"calDateModified"];
	
	_lastContentAccess = [NSDate timeIntervalSinceReferenceDate];
}

- (NSAttributedString*) attributedContentIfLoaded
{
	// access the attributed content directly, avoiding an unnecessary load
	return [_properties objectForKey:PDEntryAtttibutedContent];
}

- (BOOL) loadAttributedContent
{
	NSString *path = [self attributedContentPath];
	
	if ( ![[NSFileManager defaultManager] fileExistsAtPath:path] )
	{
		NSLog(@"%s - no rich text content at path %@", __PRETTY_FUNCTION__, path);
		return NO;
	}
	
	NSAttributedString *attrString = [[[NSAttributedString alloc] initWithPath:path documentAttributes:nil] autorelease];
	if ( attrString == nil )
	{
		NSLog(@"%s - unable to initialize attributed string from content at path %@", __PRETTY_FUNCTION__, path);
		return NO;
	}
	
	// set this directly in the properties dictionary so as not to dirty the entry
	[_properties setObject:attrString forKey:PDEntryAtttibutedContent];
	return YES;
}

- (void) unloadAttributedContent
{
	[_properties removeObjectForKey:PDEntryAtttibutedContent];
}

- (NSString*) attributedContentPath
{
	NSString *path = [[[self packagePath] stringByAppendingPathComponent:PDEntryPackageRTFDContainer] 
			stringByAppendingPathComponent:PDEntryPackageRTFDContent];
	return path;
}

- (NSData*) attributedData
{
	NSAttributedString *content = [self attributedContent];
	return [content RTFDFromRange:NSMakeRange(0,[content length]) documentAttributes:nil];
}

- (void) setAttributedData:(NSData*)aData
{
	[self setAttributedContent:[[[NSAttributedString alloc] initWithRTFD:aData documentAttributes:nil] autorelease]];
}

// increments the retain count on the attributed content
- (void) retainContent
{
	_contentRetainCount++;
}

- (void) releaseContent
{
	_contentRetainCount--;
}

- (int) contentRetainCount
{
	return _contentRetainCount;
}

- (NSTimeInterval) lastContentAccess
{
	return _lastContentAccess;
}

#pragma mark -

- (JournlerResource*) selectedResource
{
	return [_properties objectForKey:PDEntryLastSelectedResource];
}

- (void) setSelectedResource:(JournlerResource*)aResource
{	
	if ( aResource == nil )
		[_properties removeObjectForKey:PDEntryLastSelectedResource];
	else
		[_properties setObject:aResource forKey:PDEntryLastSelectedResource];
	
	[self setValue:BooleanNumber(YES) forKey:@"dirty"];
}

- (NSNumber*)version 
{ 
	return [_properties objectForKey:PDEntryVersion]; 
}

- (void) setVersion:(NSNumber*)verNum 
{
	[_properties setObject:(verNum?verNum:[NSNumber numberWithInt:1]) forKey:PDEntryVersion];
}

#pragma mark -

// -----------------------

- (NSNumber*) markedForTrash 
{ 
	NSNumber *markedForTrash = [_properties objectForKey:PDEntryMarkedForTrash];
	if ( markedForTrash == nil ) markedForTrash = BooleanNumber(NO);
	return markedForTrash;
}

- (void) setMarkedForTrash:(NSNumber*)mark 
{
	[_properties setObject:(mark?mark:[NSNumber numberWithBool:NO]) forKey:PDEntryMarkedForTrash];
	[self setValue:BooleanNumber(YES) forKey:@"dirty"];
}

// ------------------------

- (NSCalendarDate*) calDate 
{ 
	return [_properties objectForKey:PDEntryCalDate]; 
}

- (void) setCalDate:(NSCalendarDate*)date 
{
	[_properties setObject:(date?date:[NSCalendarDate calendarDate]) forKey:PDEntryCalDate];
	[self generateDateInt];
	
	[self setValue:BooleanNumber(YES) forKey:@"dirty"];
	
	if ( ![JournlerEntry modsDateModdedOnlyOnTextualChange] )
		[self setValue:[NSCalendarDate calendarDate] forKey:@"calDateModified"];
}

- (NSCalendarDate*) calDateModified 
{ 
	return [_properties objectForKey:PDEntryCalDateModified]; 
}

- (void) setCalDateModified:(NSCalendarDate*)date 
{	
	[_properties setObject:(date?date:[NSCalendarDate calendarDate]) forKey:PDEntryCalDateModified];
	[self setValue:BooleanNumber(YES) forKey:@"dirty"];
}

- (NSCalendarDate*) calDateDue
{
	return [_properties objectForKey:PDEntryCalDateDue]; 
}

- (void) setCalDateDue:(NSCalendarDate*)date
{
	// unlike the other date options, the due-date may be cleared
	
	if ( date == nil ) [_properties removeObjectForKey:PDEntryCalDateDue];
	else [_properties setObject:date forKey:PDEntryCalDateDue];
		
	[self setValue:BooleanNumber(YES) forKey:@"dirty"];
}

- (NSArray*) blogs 
{
	NSArray *blogs = [_properties objectForKey:PDEntryBlogs];
	if ( blogs == nil ) blogs = EmptyArray();
	return blogs;
}

- (void) setBlogs:(NSArray*)newObject 
{
	[_properties setObject:(newObject?newObject:[NSArray array]) forKey:PDEntryBlogs];
	
	[self setBlogged:[newObject count]];
	[self setValue:BooleanNumber(YES) forKey:@"dirty"];
}

#pragma mark -

- (NSNumber*) label 
{ 
	NSNumber *theLabel = [_properties objectForKey:PDEntryLabelColor];
	if ( theLabel == nil ) theLabel = ZeroNumber();
	return theLabel;
	
	//return [_properties objectForKey:PDEntryLabelColor]; 
}

- (void) setLabel:(NSNumber*)val 
{
	[_properties setObject:(val?val:[NSNumber numberWithInt:0]) forKey:PDEntryLabelColor];	
	[self setValue:BooleanNumber(YES) forKey:@"dirty"];
	
	if ( ![JournlerEntry modsDateModdedOnlyOnTextualChange] )
		[self setValue:[NSCalendarDate calendarDate] forKey:@"calDateModified"];
	
	// post a notification that this attribute has changed
	[[NSNotificationCenter defaultCenter] postNotificationName:JournlerObjectDidChangeValueForKeyNotification 
			object:self 
			userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
					JournlerObjectAttributeLabelKey, JournlerObjectAttributeKey, nil]];
}

#pragma mark -

- (NSNumber*) marked 
{
	NSNumber *marked = [_properties objectForKey:PDEntryFlagged];
	if ( marked == nil ) marked = ZeroNumber();
	return marked;
}

- (void) setMarked:(NSNumber*)aValue 
{
	[_properties setObject:(aValue?aValue:ZeroNumber()) forKey:PDEntryFlagged];	
	[self setValue:BooleanNumber(YES) forKey:@"dirty"];
	
	if ( ![JournlerEntry modsDateModdedOnlyOnTextualChange] )
		[self setValue:[NSCalendarDate calendarDate] forKey:@"calDateModified"];
}

- (NSNumber*) flagged 
{
	return [self marked];
}

- (void) setFlagged:(NSNumber*)flagValue 
{
	[self setMarked:flagValue];
}

#pragma mark -

- (float) relevance 
{
	return relevance;
}

- (void) setRelevance:(float)nr 
{
	relevance = nr;
}

- (NSNumber*) relevanceNumber 
{
	//return [NSNumber numberWithInt:(int)(relevance*100)];
	return [NSNumber numberWithFloat:relevance];
}

#pragma mark -

- (int) dateModifiedInt 
{
	// a simple cheat to enable smart folders with date conditions
	int returnValue;
	returnValue = [[[self calDateModified] descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil] intValue];
	return returnValue;
}

- (int) dateDueInt
{
	int returnValue;
	returnValue = [[[self calDateDue] descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil] intValue];
	return returnValue;
}

- (int) dateInt
{
	// a simple cheat to enable smart folders with date conditions
	return _dateInt;	// -- _dateInt is generated and cached at the appropriate moments
}

- (int) dateCreatedInt
{
	return [self dateInt];
}

- (int) labelInt 
{
	// a simple cheat to enable smart folders with label condition : probably unnecessary
	return [[self label] intValue];
}

- (int) markedInt 
{
	return [[self marked] intValue];
}

- (void) setMarkedInt:(int)aValue 
{
	[self setMarked:[NSNumber numberWithInt:aValue]];
}

- (BOOL) blogged 
{
	// a simple cheat to enable smart folders with the blogged condition
	return ( [[self blogs] count] > 0 ? YES : NO );
}

- (void) setBlogged:(BOOL)isBlogged 
{
	// doesn't do anything, cheat for key-value coding 
	return;
}

- (BOOL) flaggedBool 
{
	return ( [[self marked] intValue] == 1 );
}

- (void) setFlaggedBool:(BOOL)flagValue 
{
	[self setMarked:[NSNumber numberWithBool:( flagValue ? 1 : 0 )]];
}

- (BOOL) checkedBool 
{
	return ( [[self marked] intValue] == 2 );
}

- (void) setCheckedBool:(BOOL)aValue 
{
	[self setMarked:[NSNumber numberWithBool:( aValue ? 2 : 0 )]];
}

- (NSString*) content 
{		
	NSString *contentAsString;
	
	// a cheat to enable smart folders to check an entry's plain text content 
	NSAttributedString *attr = [self attributedContent];
	if ( attr == nil )
		contentAsString = [NSString string];
	else
	{
		// strip on non-linguistically significant characters (seems aweful heavyweight)
		NSMutableString *mutableContent = [[[attr string] mutableCopyWithZone:[self zone]] autorelease];
		[mutableContent replaceOccurrencesOfString:[NSString stringWithCharacters: (const unichar[]){NSAttachmentCharacter} length:1] 
				withString:@"" options:NSLiteralSearch range:NSMakeRange(0,[mutableContent length])];
		
		contentAsString = mutableContent;
	}
	
	return contentAsString;
}

- (NSString*) entireEntry 
{
	// a cheat to enable smart folders to check an entry's entire text content 
	NSMutableString *entireString = [[[NSMutableString allocWithZone:[self zone]] init] autorelease];
	
	[entireString appendString:[self title]];
	[entireString appendString:@" "];
	[entireString appendString:[self category]];
	[entireString appendString:@" "];
	[entireString appendString:[self keywords]];
	[entireString appendString:@" "];
	[entireString appendString:[self content]];
	
	return entireString;
}

#pragma mark -

- (NSURL*) URIRepresentation
{	
	NSString *urlString = [NSString stringWithFormat:@"journler://entry/%@", [self valueForKey:@"tagID"]];
	if ( urlString == nil )
	{
		NSLog(@"%s - unable to create string representation of entry #%@", __PRETTY_FUNCTION__, [self valueForKey:@"tagID"]);
		return nil;
	}
	
	NSURL *url = [NSURL URLWithString:urlString];
	if ( url == nil )
	{
		NSLog(@"%s - unable to create url representation of entry #%@", __PRETTY_FUNCTION__, [self valueForKey:@"tagID"]);
		return nil;
	}
	
	return url;
}

- (NSString*) searchableContent 
{	
	NSString *title = [self valueForKey:@"title"];
	NSString *keywords = [self valueForKey:@"keywords"];
	NSString *category = [self valueForKey:@"category"];
	NSString *plainContent = [[self valueForKey:@"attributedContent"] string];
	NSString *tags = [[self valueForKey:@"tags"] componentsJoinedByString:@" "];
	
	NSMutableString *searchableContent = [NSMutableString string];
	
	if ( title != nil )
		[searchableContent appendString:[NSString stringWithFormat:@"%@ %@ %@ ", title, title, title]];
	
	if ( keywords != nil )
		[searchableContent appendString:[NSString stringWithFormat:@"%@ %@ %@ ", keywords, keywords, keywords]];
	
	if ( tags != nil )
		[searchableContent appendString:[NSString stringWithFormat:@"%@ %@ %@ ", tags, tags, tags]];
	
	if ( category != nil )
	{
		[searchableContent appendString:category];
		[searchableContent appendString:@" "];
	}
	
	if ( plainContent != nil )
		[searchableContent appendString:plainContent];
	
	return searchableContent;
	
	/*
	NSString *searchable = [NSString stringWithFormat:@"%@ %@ %@ %@ %@",
		( title ? [NSString stringWithFormat:@"%@ %@ %@",title,title,title] : [NSString string] ),
		( keywords ? [NSString stringWithFormat:@"%@ %@ %@",keywords,keywords,keywords] : [NSString string] ),
		( tags ? [NSString stringWithFormat:@"%@ %@ %@",tags,tags,tags] : [NSString string] ),
		( category ? category : [NSString string] ),
		( plainContent ? plainContent : [NSString string] )];
	
	return searchable;
	*/
}

- (NSDictionary*) metadata
{
	// generate a metadata dictionary that can be written to file anywhere
	NSString *keywords = [self valueForKey:@"keywords"];
	NSString *category = [self valueForKey:@"category"];
	NSString *plainContent = [[self valueForKey:@"attributedContent"] string];
	
	NSString *mdKeywords = [NSString stringWithFormat:@"%@ %@", 
			(category?category:[NSString string]), (keywords?keywords:[NSString string])];
	
	NSDictionary *metadata = [NSDictionary dictionaryWithObjectsAndKeys:
			[self valueForKey:@"title"], kMDItemTitle, [self valueForKey:@"title"], kMDItemDisplayName,
			[self valueForKey:@"dateCreated"], kMDItemContentCreationDate,
			[self valueForKey:@"dateModified"], kMDItemContentModificationDate,
			mdKeywords, kMDItemKeywords, 
			(plainContent?plainContent:[NSString string]), kMDItemTextContent, nil];
	
	return metadata;
}

- (NSString*) allResourceTypes
{
	if ( _resourceTypesCached == nil )
	{
		//NSArray *allTypesArray = [[self resources] valueForKey:@"allUTIs"];
		NSArray *allTypesArray = [self valueForKeyPath:@"resources.@distinctUnionOfArrays.allUTIsArray"];
		NSString *allTypesString = [allTypesArray componentsJoinedByString:@","];
		
		//if ( _resourceTypesCached ) NSLog(_resourceTypesCached);
		_resourceTypesCached = ( allTypesString ? [allTypesString retain] : [[NSString alloc] init] );
	}
	
	return _resourceTypesCached;
}

- (void) setAllResourceType:(NSString*)aString
{
	// dummy method for key-value observers
	return;
}

- (void) invalidateResourceTypes
{
	[_resourceTypesCached release];
	_resourceTypesCached = nil;
}

#pragma mark -
#pragma Move these to the JournlerObject method - all objects must support

- (NSImage*) icon
{
	// override to return a standard icon
	return [NSImage imageNamed:@"Entry.icns"];
}

- (void) setIcon:(NSImage*)anImage
{
	// override to do nothing
	return;
}

- (NSString*) uti
{
	return @"com.phildow.journler.jentry";
}

#pragma mark -
#pragma mark Set Requirements

- (unsigned)hash 
{
	// returns the entry's ID number, guaranteed to be unique to the entry
	return [[self tagID] unsignedIntValue];
}

- (BOOL)isEqual:(id)anObject 
{
	// tests for the class and then the int tag id
	return ( [anObject isMemberOfClass:[self class]] && [[self tagID] intValue] == [[anObject tagID] intValue] );	
}

#pragma mark -

- (void) addBlog:(id)whichBlog 
{	
	NSMutableArray *myBlogs = [[NSMutableArray alloc] initWithArray:[self blogs]];
	
	if ( [myBlogs indexOfObjectIdenticalTo:whichBlog] == NSNotFound )
		[myBlogs addObject:whichBlog];
	
	[self setBlogs:[NSArray arrayWithArray:myBlogs]];
	
	[myBlogs release];
}

- (BOOL) hasBlog:(id)whichBlog 
{
	return ( [[self blogs] indexOfObjectIdenticalTo:whichBlog] != NSNotFound );
}

- (int) numberOfResources
{
	return [[self resources] count];
}

- (void) setNumberOfResources:(int)numResources
{
	// stand-in for key-value observing
	return;
}

// ----------

#pragma mark -
#pragma mark 1.2 changes
// 1.2 Changes

- (BOOL) performOneTwoMaintenance:(NSMutableString**)log {
	
	//
	// called to handle the 1.0/1 to 1.2 changeover
	// - convert the rtfd to an attributed string
	// - convert date and time strings to a date object
	// - convert date modified string to a date object
	//
	
	BOOL success = YES;
	NSMutableString *upgradeLog = *log;
	
	//
	// convert a few objects to the appropriate format - leftover from very early days
	
	if ( [_properties objectForKey:PDEntryFlagged] && [[_properties objectForKey:PDEntryFlagged] isKindOfClass:[NSString class]] ) {
		// convert flag as string to flag as number
		[_properties setObject:[NSNumber numberWithInt:[[_properties objectForKey:PDEntryFlagged] intValue]] forKey:PDEntryFlagged];
	}
	if ( [_properties objectForKey:PDEntryFlagged] && [[_properties objectForKey:PDEntryLabelColor] isKindOfClass:[NSString class]] ) {
		// convert flag as string to flag as number
		[_properties setObject:[NSNumber numberWithInt:[[_properties objectForKey:PDEntryLabelColor] intValue]] forKey:PDEntryLabelColor];
	}
	if ( [_properties objectForKey:PDEntryTag] && [[_properties objectForKey:PDEntryTag] isKindOfClass:[NSString class]] ) {
		// convert tagID as string to tagID as number
		[_properties setObject:[NSNumber numberWithInt:[[_properties objectForKey:PDEntryTag] intValue]] forKey:PDEntryTag];
	}
	
	//
	// then try for the date created and timestamp
	NSCalendarDate *myCalDateCreated = nil;
	
	if ( [_properties objectForKey:PDEntryDate] && 
			[[_properties objectForKey:PDEntryDate] isKindOfClass:[NSString class]] &&
			[[_properties objectForKey:PDEntryDate] length] != 0 ) {
	
		// format : %Y-%m-%d %H:%M %p
		
		NSMutableString *dateString = [[_properties objectForKey:PDEntryDate] mutableCopyWithZone:[self zone]];
		NSString *timeString = [_properties objectForKey:PDEntryTimestamp];
		
		NSString *dateFormat;
		NSCalendarDate *dateCreatedAsDate;
		
		// add the timestamp if possible
		if ( timeString ) {
			
			dateFormat = @"%Y-%m-%d %H:%M %p";
			[dateString appendString:[NSString stringWithFormat:@" %@", timeString]];
			
		}
		else {
			
			dateFormat = @"%Y-%m-%d";
			
		}
		
		// prepare and add the date
		dateCreatedAsDate = [[[NSCalendarDate alloc] initWithString:dateString calendarFormat:dateFormat] autorelease];
		if ( !dateCreatedAsDate ) {
			
			//
			// log an error but set the date to today's date
			[upgradeLog appendFormat:@"Entry %@: unable to convert date and time string to date object\n", [self tagID]];
			myCalDateCreated = [NSCalendarDate calendarDate];
			//[self setCalDate:[NSCalendarDate calendarDate]];
			
		}
		else {
			// set the new property
			//[self setCalDate:dateCreatedAsDate];
			myCalDateCreated = dateCreatedAsDate;
			// clean up
			//[dateCreatedAsDate release];
		}
		
		// clean up
		[dateString release];
		
	}
	else {
		
		//
		// if not able to get a date, set the date of the entry to today's date
		[upgradeLog appendFormat:@"Entry %@: no date created, using today's date\n", [self tagID]];
		myCalDateCreated = [NSCalendarDate calendarDate];
		//[self setCalDate:[NSCalendarDate calendarDate]];
		
	}
	
	// remove the old date properties
	[_properties removeObjectForKey:PDEntryDate];
	[_properties removeObjectForKey:PDEntryTimestamp];
	
	//
	// convert the date modified string to a date object - date modified first because it must be preserved

	if ( [_properties objectForKey:PDEntryDateModified] && 
			[[_properties objectForKey:PDEntryDateModified] isKindOfClass:[NSString class]] && 
			[[_properties objectForKey:PDEntryDateModified] length] != 0 ) {
	
		// format : %Y-%m-%d
		
		NSString *dateString = [_properties objectForKey:PDEntryDateModified];
		
		NSString *dateFormat = @"%Y-%m-%d";
		NSCalendarDate *dateModifiedAsDate;
		
		// prepare and add the date
		dateModifiedAsDate = [[NSCalendarDate alloc] initWithString:dateString calendarFormat:dateFormat];
		if ( !dateModifiedAsDate ) {
			
			//
			// log an error but set the date to the date created date
			[upgradeLog appendFormat:@"Entry %@: unable to convert date modified string to date object\n", [self tagID]];
			//[self setCalDateModified:[self calDate]];
			[self setCalDateModified:myCalDateCreated];
		}
		else {
			// set the new property
			[self setCalDateModified:dateModifiedAsDate];
			// clean up
			[dateModifiedAsDate release];
		}
		
	}
	else {
		
		[upgradeLog appendFormat:@"Entry %@: no date modified, using the entry's creation date\n", [self tagID]];
		//[self setCalDateModified:[self calDate]];
		[self setCalDateModified:myCalDateCreated];
	}
	
	//
	// remove the old date modified property
	[_properties removeObjectForKey:PDEntryDateModified];


	// preseve the date modified
	NSCalendarDate *preservedDateModified = [[[self calDateModified] retain] autorelease];
	
	// actually set the cal date
	[self setCalDate:myCalDateCreated];
	
	//
	// convert the rtfd data to an attributed string object - most critical conversion
	
	NSData *data = [_properties objectForKey:PDEntryRTFD];
	if ( !data ) {

		[upgradeLog appendFormat:@"Entry %@: no rich text data for the entry's content\n", [self tagID]];		
		[self setAttributedContent:[[[NSAttributedString alloc] init] autorelease]];

	}
	else {
	
		NSAttributedString *attributedString = [[NSAttributedString alloc] initWithRTFD:data documentAttributes:nil];
		if ( !attributedString ) {
			
			//
			// critical error
			
			[upgradeLog appendFormat:@"Entry %@: unable to convert rich text content to attributed string\n", [self tagID]];
			[self setAttributedContent:[[[NSAttributedString alloc] init] autorelease]];
			success = NO;
			
		}
		else {
			
			// set the new data
			[self setAttributedContent:attributedString];
			// remove the old data
			[_properties removeObjectForKey:PDEntryRTFD];
			// clean up
			[attributedString release];
			
		}
	
	}
	
	//
	// upgrade the old blog info
	if ( [self blogged] ) {
		
		//
		// convert them to type BlogPref
		
		int b;
		NSArray *blogs = [self blogs];
		NSMutableArray *converted_blogs = [[NSMutableArray alloc] initWithCapacity:[blogs count]];
		for ( b = 0; b < [blogs count]; b++ ) {
			
			if ( ![[blogs objectAtIndex:b] isKindOfClass:[NSDictionary class]] )
				continue;
			
			BlogPref *aBlog = [[BlogPref alloc] initWithProperties:[blogs objectAtIndex:b]];
			[converted_blogs addObject:aBlog];
			[aBlog release];
			
		}
		
		[self setBlogs:converted_blogs];
		[converted_blogs release];
		
	}
	
	//
	// upgrade the version number
	[self setValue:[NSNumber numberWithInt:120] forKey:@"version"];
	
	// restore the date modified
	[self setCalDateModified:preservedDateModified];
	
	//
	// return the success value
	return success;
}

- (void) perform210Maintenance
{
	NSMutableDictionary *theProperties = [[[self valueForKey:@"properties"] mutableCopyWithZone:[self zone]] autorelease];
	NSArray *removeKeys = [NSArray arrayWithObjects:
			PDEntryDateModified, PDEntryDate, PDEntryTimestamp, PDEntrySearchMedia, 
			PDEntryRTFD, PDEntryViewMode, PDEntrySelectedMediaURL, PDEntryStringValue, nil];
	
	[theProperties removeObjectsForKeys:removeKeys];
	[self setValue:theProperties forKey:@"properties"];
}

- (void) perform253Maintenance
{
	if ( [[_properties objectForKey:PDEntryLabelColor] intValue] == 0 )
		[_properties removeObjectForKey:PDEntryLabelColor];
		
	if ( [[_properties objectForKey:PDEntryFlagged] intValue] == 0 )
		[_properties removeObjectForKey:PDEntryFlagged];
		
	if ( [[_properties objectForKey:PDEntryCategory] length] == 0 )
		[_properties removeObjectForKey:PDEntryCategory];
		
	if ( [[_properties objectForKey:PDEntryKeywords] length] == 0 )
		[_properties removeObjectForKey:PDEntryKeywords];
		
	if ( [[_properties objectForKey:PDEntryBlogs] count] == 0 )
		[_properties removeObjectForKey:PDEntryBlogs];
		
	if ( [[_properties objectForKey:PDEntryMarkedForTrash] boolValue] == NO )
		[_properties removeObjectForKey:PDEntryMarkedForTrash];

}

- (void) generateDateInt 
{
	// a simple cheat to enable smart folders with date conditions

	int returnValue;
	returnValue = [[[self calDate] descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil] intValue];
	_dateInt = returnValue;
}

#pragma mark -
#pragma mark Deprecated

- (NSNumber*) labelValue
{
	return [self valueForKey:@"label"];
}

- (void) setLabelValue:(NSNumber*)aNumber
{
	[self setValue:aNumber forKey:@"label"];
}

/*
- (NSString*) previouslySavedTitle 
{ 
	return _previously_saved_title; 
}

- (void) setPreviouslySavedTitle:(NSString*)previousTitle 
{
	if ( _previously_saved_title != previousTitle ) 
	{
		[_previously_saved_title release];
		_previously_saved_title = [previousTitle retain];
	}
}
*/

@end

#pragma mark -

@implementation JournlerEntry (ResourceAndMediaManagement)

// DEPRECATED
- (NSURL*) fileURLForResourceFilename:(NSString*)filename 
{
	// just returned the standardized path which takes into account symbolic links
	
	NSString *resourcePath = [[[self pathToResourcesCreatingIfNecessary:YES] stringByAppendingPathComponent:filename] 
			stringByStandardizingPath];
	if ( !resourcePath ) {
		NSLog(@"%s -  no resource for entry %@ and filename %@", __PRETTY_FUNCTION__, [self tagID], filename);
		return nil;
	}
	
	NSURL *resourceURL;
	
	NSString *symbolicContents = [[NSWorkspace sharedWorkspace] resolveForAliases:resourcePath];
	
	resourceURL = [NSURL fileURLWithPath:(symbolicContents?symbolicContents:resourcePath)];
	if ( !resourceURL ) {
		NSLog(@"%s - unable to convert resource string to resource url: %@", __PRETTY_FUNCTION__, resourcePath);
		return nil;
	}
	
	return resourceURL;
	
}

// DEPRECATED
- (NSURL*) fileURLForResourceURL:(NSURL*)url 
{
	// url in the form of journler://resource/id/name
	return [self fileURLForResourceFilename:[[url path] lastPathComponent]];
}

#pragma mark -

- (JournlerResource*) resourceForFile:(NSString*)path operation:(NewResourceCommand)operation
{
	NSFileManager *fm = [NSFileManager defaultManager];
	
	// initial error checking
	if ( path == nil ) 
	{
		NSLog(@"%s - nil path", __PRETTY_FUNCTION__);
		return nil;
	}
	
	if ( ![fm fileExistsAtPath:path] ) 
	{
		NSLog(@"%s - no file at path %@", __PRETTY_FUNCTION__, path);
		return nil;
	}

	JournlerResource *returnResource = nil;
	
	// first query the journal for a resource that already encapsulates this information,
	returnResource = [[self journal] alreadyExistingResourceWithType:kResourceTypeFile data:path operation:operation];
	
	if ( returnResource == nil )
	{
		// the file exist and everything is valid. sym link it from this entry's reference directory
		NSString *filename = [path lastPathComponent];
		if ( !filename ) filename = NSLocalizedString(@"untitled title", @"");
		
		NSString *resourcePath = [self resourcesPathCreating:YES];
		if ( !resourcePath ) 
		{
			NSLog(@"%s - unable to create reference directory for entry, bailing on copy", __PRETTY_FUNCTION__);
			return nil;
		}
		
		NSString *filepath = [resourcePath stringByAppendingPathComponent:filename];
		NSString *fullLocalPath = [filepath pathWithoutOverwritingSelf];
			
		if ( operation == kNewResourceForceCopy ) 
		{
			// actually copy the file
			if ( ![fm copyPath:path toPath:fullLocalPath handler:self] )
			 {
				NSLog(@"%s - unable to copy %@ to %@", __PRETTY_FUNCTION__, path, fullLocalPath);
				return nil;
			}
			
			// set the creation date on the copied file
			NSDate *creation_date = [[fm fileAttributesAtPath:path traverseLink:NO] objectForKey:NSFileCreationDate];
			if ( creation_date == nil ) creation_date = [NSDate date];
			NSDictionary *file_attrs = [NSDictionary dictionaryWithObject:creation_date forKey:NSFileCreationDate];
			[fm changeFileAttributes:file_attrs atPath:fullLocalPath];
		}
		
		else if ( operation == kNewResourceForceMove )
		{
			// actually move the file
			if ( ![fm movePath:path toPath:fullLocalPath handler:self] )
			 {
				NSLog(@"%s - unable to move %@ to %@", __PRETTY_FUNCTION__, path, fullLocalPath);
				return nil;
			}
			
			// set the creation date on the copied file
			NSDate *creation_date = [[fm fileAttributesAtPath:path traverseLink:NO] objectForKey:NSFileCreationDate];
			if ( creation_date == nil ) creation_date = [NSDate date];
			NSDictionary *file_attrs = [NSDictionary dictionaryWithObject:creation_date forKey:NSFileCreationDate];
			[fm changeFileAttributes:file_attrs atPath:fullLocalPath];
		}
		
		else if ( operation == kNewResourceForceLink )
		{
			// actually create the link
			NDAlias *alias = [[NDAlias alloc] initWithPath:path];
			if ( ![alias writeToFile:fullLocalPath] ) 
			{
				NSLog(@"%s - unable to link %@ to %@", __PRETTY_FUNCTION__, fullLocalPath, path);
				return nil;
			}
		}
		
		else
		{
			// no default operation ?
			NSLog(@"%s - no operation specified for new file resource", __PRETTY_FUNCTION__);
		}
		
		// create a resource that encapsulates this information
		JournlerResource *resource = [[[JournlerResource alloc] initFileResource:fullLocalPath] autorelease];
		[resource setValue:[NSNumber numberWithInt:[[self journal] newResourceTag]] forKey:@"tagID"];
		
		// add the resource to myself
		returnResource = [self addResource:resource];
		
		// add the resource to the journal
		if ( returnResource == resource )
			[[self journal] addResource:resource];
	}
	
	else
	{
		returnResource = [self addResource:returnResource];
	}

	return returnResource;
}

- (JournlerResource*) resourceForABPerson:(ABPerson*)aPerson
{
	if ( aPerson == nil )
		return nil;
	
	JournlerResource *returnResource = nil;
	
	// first query the journal for a resource that already encapsulates this information
	returnResource = [[self journal] alreadyExistingResourceWithType:kResourceTypeABRecord data:[aPerson uniqueId] operation:kNewResourceForceLink];
	
	if ( returnResource == nil )
	{
		// create a resource that encapsulates this information
		JournlerResource *resource = [[[JournlerResource alloc] initABPersonResource:aPerson] autorelease];
		[resource setValue:[NSNumber numberWithInt:[[self journal] newResourceTag]] forKey:@"tagID"];
		
		// add the resource to myself
		returnResource = [self addResource:resource];
		
		// add the resource to the journal
		if ( returnResource == resource )
			[[self journal] addResource:resource];
	}
	
	else
	{
		returnResource = [self addResource:returnResource];
	}

	return returnResource;
}

- (JournlerResource*) resourceForURL:(NSString*)urlString title:(NSString*)title
{
	if ( urlString == nil )
		return nil;
	
	JournlerResource *returnResource = nil;
	
	// first query the journal for a resource that already encapsulates this information
	returnResource = [[self journal] alreadyExistingResourceWithType:kResourceTypeURL data:urlString  operation:kNewResourceForceLink];
	
	if ( returnResource == nil )
	{
		// create a resource that encapsulates this information
		JournlerResource *resource = [[[JournlerResource alloc] initURLResource:[NSURL URLWithString:urlString]] autorelease];
		[resource setValue:[NSNumber numberWithInt:[[self journal] newResourceTag]] forKey:@"tagID"];
		[resource setValue:( title ? title : urlString ) forKey:@"title"];
		
		// add the resource to myself
		returnResource = [self addResource:resource];
		
		// add the resource to the journal
		if ( returnResource == resource )
			[[self journal] addResource:resource];
	}
	
	else
	{
		returnResource = [self addResource:returnResource];
	}
	
	return returnResource;
}

- (JournlerResource*) resourceForJournlerObject:(id)anObject
{
	// different than the above three
	// resources all have id of -1, are not kept with the rest of the resources
	// these resources describe other journler objects only - a way of encapsulating a relationship
	
	if ( anObject == nil || !( [anObject isKindOfClass:[JournlerEntry class]] || [anObject isKindOfClass:[JournlerCollection class]] ) )
		return nil;
	
	JournlerResource *returnResource = nil;
	
	// first query the journal for a resource that already encapsulates this information
	returnResource = [[self journal] alreadyExistingResourceWithType:kResourceTypeJournlerObject data:[anObject URIRepresentationAsString] operation:kNewResourceForceLink];

	if ( returnResource == nil )	
	{
		// create a resource that encapsulates this information
		JournlerResource *resource = [[[JournlerResource alloc] initJournalObjectResource:[anObject URIRepresentation]] autorelease];
		
		[resource setValue:[NSNumber numberWithInt:[[self journal] newResourceTag]] forKey:@"tagID"];
		[resource setValue:[anObject valueForKey:@"title"] forKey:@"title"];
		[resource setValue:[NSNumber numberWithBool:NO] forKey:@"searches"];
		
		// set the icon
		if ( [anObject isKindOfClass:[JournlerCollection class]] )
		{
			[resource setValue:[anObject valueForKey:@"icon"] forKey:@"icon"];
		}
		else if ( [anObject isKindOfClass:[JournlerEntry class]] )
		{
			[resource setValue:[self icon] forKey:@"icon"];
		}
		
		// add the resource to myself
		returnResource = [self addResource:resource];
		
		// add the resource to the journal
		if ( returnResource == resource )
		{
			[[self journal] addResource:resource];
			
			// establish a reverse link if this is an entry
			if ( [anObject isKindOfClass:[JournlerEntry class]] )
			{
				JournlerResource *selfAsResource = [[[JournlerResource alloc] initJournalObjectResource:[self URIRepresentation]] autorelease];
				[selfAsResource setValue:[NSNumber numberWithInt:[[self journal] newResourceTag]] forKey:@"tagID"];
				[selfAsResource setValue:[self valueForKey:@"title"] forKey:@"title"];
				[selfAsResource setValue:[self icon] forKey:@"icon"];
				[selfAsResource setValue:[NSNumber numberWithBool:NO] forKey:@"searches"];
				
				// add myself as resource to the entry and to the journal
				[(JournlerEntry*)anObject addResource:selfAsResource];
				[[self journal] addResource:selfAsResource];
			}
		}
	}
	
	else
	{
		JournlerResource *previousResource = returnResource;
		returnResource = [self addResource:returnResource];
		
		if ( returnResource == previousResource )
		{
			// establish a reverse link if this is an entry
			if ( [anObject isKindOfClass:[JournlerEntry class]] )
			{
				JournlerResource *selfAsResource = [[[JournlerResource alloc] initJournalObjectResource:[self URIRepresentation]] autorelease];
				[selfAsResource setValue:[NSNumber numberWithInt:[[self journal] newResourceTag]] forKey:@"tagID"];
				[selfAsResource setValue:[self valueForKey:@"title"] forKey:@"title"];
				[selfAsResource setValue:[self icon] forKey:@"icon"];
				[selfAsResource setValue:[NSNumber numberWithBool:NO] forKey:@"searches"];
				
				// add myself as resource to the entry and to the journal
				[(JournlerEntry*)anObject addResource:selfAsResource];
				[[self journal] addResource:selfAsResource];
			}
		}
	}

	return returnResource;
}

#pragma mark -

- (JournlerResource*) addResource:(JournlerResource*)aResource
{
	// checks to see if an identifical version is already in the entry
	// if one is, returns that resource instead, otherwise returns the resource passed to it
	
	if ( aResource == nil )
		return nil;
	
	JournlerResource *returnResource = nil;
	unsigned resourceIndex = [[self valueForKey:@"resources"] indexOfObjectIdenticalToResource:aResource];

	if ( resourceIndex == NSNotFound )
	{
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:EntryWillAddResourceNotification 
				object:self userInfo:[NSDictionary dictionaryWithObject:aResource forKey:@"resource"] waitUntilDone:NO];
		
		NSMutableArray *entryResources = [[[self valueForKey:@"resources"] mutableCopyWithZone:[self zone]] autorelease];
		
		// establish the resource's relationship to myself, the resource -> entry relationship must be altered first
		
		// a. as owner if the resource does not have one
		if ( [aResource valueForKey:@"entry"] == nil )
			[aResource setValue:self forKey:@"entry"];
		
		// b. always as part of the to-many relationship
		if ( ![[aResource valueForKey:@"entries"] containsObject:self] ) 
		{
			NSMutableArray *resourcesEntries = [[[aResource valueForKey:@"entries"] mutableCopyWithZone:[self zone]] autorelease];
			[resourcesEntries addObject:self];
			[aResource setValue:resourcesEntries forKey:@"entries"];
		}
		
		// establish my relationship to the resource second 
		// (observers depend on the resource->entry relationships already established when i set the "resources" value )
		[entryResources addObject:aResource];
		[self setValue:entryResources forKey:@"resources"];
		
		// invalidate the resource cache
		[self invalidateResourceTypes];
		
		// dummy number method
		[self setNumberOfResources:[entryResources count]];
		
		[self setDirty:BooleanNumber(YES)];
		[aResource setDirty:BooleanNumber(YES)];
		
		returnResource = aResource;
		
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:EntryDidAddResourceNotification 
				object:self 
				userInfo:[NSDictionary dictionaryWithObject:aResource forKey:@"resource"] 
				waitUntilDone:NO];
	}
	else
	{
		returnResource = [[self valueForKey:@"resources"] objectAtIndex:resourceIndex];
	}
	
	return returnResource;
}

- (BOOL) removeResource:(JournlerResource*)aResource
{
	if ( aResource == nil )
		return NO;
	
	unsigned resourceIndex = [[self valueForKey:@"resources"] indexOfObjectIdenticalToResource:aResource];
	
	//if ( [entryResources indexOfObject:aResource] != NSNotFound )
	if ( resourceIndex != NSNotFound )
	{
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:EntryWillRemoveResourceNotification 
				object:self userInfo:[NSDictionary dictionaryWithObject:aResource forKey:@"resource"] waitUntilDone:NO];
		
		NSMutableArray *entryResources = [[[self valueForKey:@"resources"] mutableCopyWithZone:[self zone]] autorelease];
		
		[entryResources removeObject:aResource];
		[self setValue:entryResources forKey:@"resources"];
		
		// invalidate the cache
		[self invalidateResourceTypes];
		
		// dummy number method
		[self setNumberOfResources:[entryResources count]];
		
		[self setDirty:BooleanNumber(YES)];
		[aResource setDirty:BooleanNumber(YES)];
		
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:EntryDidRemoveResourceNotification 
				object:self 
				userInfo:[NSDictionary dictionaryWithObject:aResource forKey:@"resource"] 
				waitUntilDone:NO];
		
		return YES;
	}
	else
	{
		return NO;
	}
}

#pragma mark -

//
// - pathToPackage and - pathToResourcesCreatingIfNecessary: are deprecated methods, used in version 2.0

// DEPRECATED
- (NSString*) pathToPackage 
{
	NSString *entryPath;
	NSString *completePath;
	
	entryPath = [NSString stringWithFormat:@"%@ - %@.jentry", [self tagID], [self pathSafeTitle]];
	completePath = [[[self journal] entriesPath] stringByAppendingPathComponent:entryPath];
	
	return completePath;
}

// DEPRECATED
- (NSString*) pathToResourcesCreatingIfNecessary:(BOOL)create 
{
	BOOL dir;
	NSString *resourcePath = [[self pathToPackage] stringByAppendingPathComponent:PDEntryPackageResources];
	
	if ( create && ( ![[NSFileManager defaultManager] fileExistsAtPath:resourcePath isDirectory:&dir] || !dir ) ) 
	{
		if ( ![[NSFileManager defaultManager] createDirectoryAtPath:resourcePath attributes:nil] ) 
		{
			NSLog(@"%s - unable to create resource directory at %@",  __PRETTY_FUNCTION__, resourcePath);
			resourcePath = nil;
		}
	}
	
	return resourcePath;
}

#pragma mark -

- (NSString*) packagePath
{
	NSString *entryPath;
	NSString *completePath;
	
	entryPath = [NSString stringWithFormat:@"Entry %@", [self tagID]];
	completePath = [[[self journal] entriesPath] stringByAppendingPathComponent:entryPath];
	
	return completePath;
}

- (NSString*) resourcesPathCreating:(BOOL)create
{
	BOOL dir;
	NSString *resourcePath = [[self packagePath] stringByAppendingPathComponent:PDEntryPackageResources];
	
	if ( create && ( ![[NSFileManager defaultManager] fileExistsAtPath:resourcePath isDirectory:&dir] || !dir ) ) 
	{
		if ( ![[NSFileManager defaultManager] createDirectoryAtPath:resourcePath attributes:nil] ) 
		{
			NSLog(@"%s - unable to create resource directory at %@", __PRETTY_FUNCTION__, resourcePath);
			resourcePath = nil;
		}
	}
	
	return resourcePath;
}

- (BOOL) resourcesIncludeFile:(NSString*)filename
{
	// answer yes if the entry includes the filename in its resources directory
	NSString *resourcesPath = [self resourcesPathCreating:NO];
	NSString *completeResourcePath = [resourcesPath stringByAppendingPathComponent:filename];
	
	return ( [[NSFileManager defaultManager] fileExistsAtPath:completeResourcePath] );
}

#pragma mark -

- (NSArray*) textualLinks 
{
	// returns the links contained within an entry
	
	NSMutableArray *links = [[NSMutableArray allocWithZone:[self zone]] init];
	NSMutableArray *linksRange = [[NSMutableArray allocWithZone:[self zone]] init];
	NSMutableArray *linksText = [[NSMutableArray allocWithZone:[self zone]] init];
	
	NSAttributedString *attrStr = [self attributedContent];
	if ( !attrStr )
		return [links autorelease];	// no links
	
	int i;
	unsigned int length;
	NSRange effectiveRange;
	id attributeValue;
	 
	length = [attrStr length];
	effectiveRange = NSMakeRange(0, 0);
	
	//
	// parse the attributed string for links
	while (NSMaxRange(effectiveRange) < length) {
		attributeValue = [attrStr attribute:NSLinkAttributeName atIndex:NSMaxRange(effectiveRange) effectiveRange:&effectiveRange];
		if ( [attributeValue isKindOfClass:[NSURL class]] ) {
			[links addObject:attributeValue];
			[linksRange addObject:[NSValue valueWithRange:effectiveRange]];
		}
	}
	
	//
	// look for duplicate links
	for ( i = 0; i < [links count]; i++ ) 
	{
		if ( i != [links count] - 1 && [[[links objectAtIndex:i] absoluteString] isEqualToString:[[links objectAtIndex:i+1] absoluteString]] )
			i++;
		
		[linksText addObject:[links objectAtIndex:i]];
		[linksText addObject:[[attrStr string] substringWithRange:[[linksRange objectAtIndex:i] rangeValue]]];

	}
	
	[links release];
	[linksRange release];
	
	return [linksText autorelease];
}

- (NSArray*) allResourcePaths 
{
	// The function parses the resource directory and returns urls for the resources in pairs
	// The first item is the textual link, the second item is the full path url
	
	int i;
	BOOL dir;
	
	NSArray *contents;
	NSMutableArray *pathURLs;
	
	NSString *resourcesPath = [self pathToResourcesCreatingIfNecessary:NO];
	if ( ![[NSFileManager defaultManager] fileExistsAtPath:resourcesPath isDirectory:&dir] || !dir )
		return nil;	// no resources
	
	//
	// grab an array of the contents
	contents = [[NSFileManager defaultManager] directoryContentsAtPath:resourcesPath];
	pathURLs = [[NSMutableArray alloc] initWithCapacity:[contents count]];
	
	//
	// build an array of local path urls from this information: journler://resource/xxentnumxx/filename
	for ( i = 0; i < [contents count]; i++ ) {
		
		NSString *resourcePath;
		NSURL *resourceURL, *fullURL;
		
		//
		// skip invisible files
		if ( [[[contents objectAtIndex:i] lastPathComponent] characterAtIndex:0] == '.' )
			continue;
		
		//
		// build the path
		resourcePath = [NSString stringWithFormat:@"journler://resource/%@/%@",
				[self valueForKey:@"tagID"], [[contents objectAtIndex:i] lastPathComponent]];
				
		if ( !resourcePath ) {
			NSLog(@"allResourcePaths unable to create resource path for fullpath %@", 
					[resourcePath stringByAppendingPathComponent:[contents objectAtIndex:i]]);
			continue;
		}
		
		//
		// create a url from the path
		resourceURL = [NSURL URLWithString:[resourcePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		if ( !resourceURL ) {
			NSLog(@"allResourcePaths unable to create resource url for resource path %@", resourcePath);
			continue;
		}
		
		//
		// create the full path url for the resource
		fullURL = [NSURL fileURLWithPath:[resourcesPath stringByAppendingPathComponent:[contents objectAtIndex:i]]];
		if ( !fullURL ) {
			NSLog(@"allResourcePaths unable to create fullpath url for resource path %@", resourcePath);
			continue;
		}
		
		//
		// add the urls to the array
		[pathURLs addObject:resourceURL];
		[pathURLs addObject:fullURL];
		
	}
	
	//
	// return the results
	return [pathURLs autorelease];
	
}

#pragma mark -

// DEPRECATED
- (NSURL*) selectedMedia 
{ 
	return [_properties objectForKey:PDEntrySelectedMediaURL]; 
}

- (void) setSelectedMedia:(NSURL*)url 
{	
	[_properties setObject:(url?url:[NSURL URLWithString:@""]) forKey:PDEntrySelectedMediaURL];
}

- (NSNumber*) searchesMedia 
{ 
	return [_properties objectForKey:PDEntrySearchMedia]; 
}

- (void) setSearchesMedia:(NSNumber*)includeMedia 
{
	[_properties setObject:(includeMedia?includeMedia:[NSNumber numberWithBool:NO]) forKey:PDEntrySearchMedia];
}

@end

#pragma mark -

/*
@implementation JournlerEntry (EncryptionSupport)

- (id) initWithEncryptedPath:(NSString*)path CSSMHandle:(CSSM_CSP_HANDLE*)handle CSSMKey:(CSSM_KEY*)key {
	
	//
	// indicates that the file at path may or may not be encrypted
	// - check the loaded dictionary for the "encrypted" and "data" keys
	// - anytime we run into errors, return nil
	//
	
	NSDictionary		*inputDict;
	
	// grab the contents of the file
	inputDict = [NSDictionary dictionaryWithContentsOfFile:path];
	if ( !inputDict ) {
		NSLog(@"Unable to read entry at path %@", path);
		return nil;
	}
	
	// if everything is okay, immediately fork
	if ( [inputDict objectForKey:@"encrypted"] ) {
		
		CSSM_RETURN			crtn;
		CSSM_DATA			inData;					// data to encrypt/decrypt, 
		CSSM_DATA			outData = {0, NULL};	// result data, written to outFile

		// grab the encrypted data
		NSData *encryptedData = [inputDict objectForKey:@"data"];
		
		// set our inData properties
		inData.Data = (uint8 *)[encryptedData bytes];
		inData.Length = [encryptedData length];
		
		// go ahead and decrypt if we can
		if ( !handle || !key ) {
			NSLog(@"Bad handle or key, unable to decrypt entry at path %@", path);
			return nil;
		}
		
		// okay to decrypt
		crtn = cdsaDecrypt(*handle, key, &inData, &outData);
		if ( crtn ) {
			
			//error
			NSLog(@"Decryption error, unable to decrypt entry at path %@", path);
			return nil;
			
		}
		
		// no error, create a string from this data
		NSMutableString *entryPList = [[NSString stringWithCString:(const char*)outData.Data length:outData.Length]
				mutableCopy];
		
		if ( !entryPList ) {
			
			//error
			NSLog(@"Unable to convert decrypted data to string at path %@", path);
			return nil;
			
		}
		
		// ------------------------------------------------------------------
		// HUGE ERROR - NO DATES ALLOWED IN PROPERTY LIST
		
		NSRange range = [entryPList rangeOfString:@"Entry Date Modified"];
		if ( range.location != NSNotFound ) {
			NSRange lineRange = [entryPList lineRangeForRange:range];
			if ( lineRange.location != NSNotFound )
				[entryPList deleteCharactersInRange:lineRange];
		}
		
		
		// ------------------------------------------------------------------
		
		// no error, parse this string as a properties list
		id tempEntryProperties = [entryPList propertyList];
		if ( !tempEntryProperties || ![tempEntryProperties isKindOfClass:[NSDictionary class]] ) {
			
			//error
			NSLog(@"Unable to read pList from encrypted data at path %@", path);
			return nil;
			
		}
		
		// success - actually initiliaze ourselves!
		self = [self initWithProperties:tempEntryProperties];
		[self setValue:[NSNumber numberWithBool:YES] forKey:@"encrypted"];
	
		// clean up
		free(outData.Data);
		
	}
	else {
		
		// standard input
		self = [self initWithProperties:inputDict];
		
	}
	
	return self;
}

@end
*/

#pragma mark -

@implementation JournlerEntry (InterfaceSupport)

+ (BOOL) canImportFile:(NSString*)fullpath {
	
	static NSString *kPDUTTypeExecutable = @"public.executable";
	static NSString *kPDUTTypeWordDocument = @"com.microsoft.word.doc";
	
	BOOL can_import = YES;
	NSString *import_uti = [[NSWorkspace sharedWorkspace] UTIForFile:[[NSWorkspace sharedWorkspace] resolveForAliases:fullpath]];
	
	if ( fullpath == nil || ( [fullpath length] > 0 && [fullpath characterAtIndex:0] == '.' ) )
		can_import = NO;
	
	else if ( UTTypeConformsTo((CFStringRef)import_uti,kUTTypeWebArchive) )
		can_import = YES;
	
	else if ( UTTypeConformsTo((CFStringRef)import_uti,(CFStringRef)ResourceMailUTI) )
		can_import = YES;
	
	else if ( UTTypeConformsTo((CFStringRef)import_uti,(CFStringRef)ResourceMailStandardEmailUTI) )
		can_import = YES;
	
	else if ( UTTypeConformsTo((CFStringRef)import_uti,kUTTypePDF) )
		can_import = YES;	
		
	else if ( [NSImage canInitWithFile:fullpath] )
		can_import = YES;
			
	else if ( [[NSWorkspace sharedWorkspace] canWatchFile:fullpath] )
		can_import = YES;
			
	else if ( [[NSWorkspace sharedWorkspace] canPlayFile:fullpath] )
		can_import = YES;
			
	else if ( UTTypeConformsTo((CFStringRef)import_uti,kUTTypeRTF) )
		can_import = YES;
			
	else if ( UTTypeConformsTo((CFStringRef)import_uti,kUTTypeRTFD) )
		can_import = YES;
			
	else if ( UTTypeConformsTo((CFStringRef)import_uti,(CFStringRef)kPDUTTypeWordDocument) )
		can_import = YES;
			
	else if ( UTTypeConformsTo((CFStringRef)import_uti, kUTTypePlainText) )
		can_import = YES;
			
	else 
	{
		// no executables and no directories
		if ( UTTypeConformsTo((CFStringRef)import_uti,(CFStringRef)kPDUTTypeExecutable) )
			can_import = NO;
		else if ( UTTypeConformsTo((CFStringRef)import_uti,kUTTypePackage) )
			can_import = YES;
		else if ( UTTypeConformsTo((CFStringRef)import_uti,kUTTypeDirectory) )
			can_import = NO;
		else
			can_import = YES;
	}

	return can_import;
}

- (id) initWithImportAtPath:(NSString*)fullpath options:(int)importOptions maxPreviewSize:(NSSize)maxSize {
	
	//#warning - don't convert mail messages to actual entries - display them instead?
	
	//
	// determine four things:
	// 1) title 2) attributed content 3) view mode 4) import file path
	
	if ( fullpath == nil || ![[NSFileManager defaultManager] fileExistsAtPath:fullpath] )
		return nil;
	if ( ![JournlerEntry canImportFile:fullpath] )
		return nil;
	
	//NSString *import_extension = [fullpath pathExtension];
	NSString *mime_type = nil;
	NSString *import_title = [[fullpath lastPathComponent] stringByDeletingPathExtension];
	NSString *import_uti = [[NSWorkspace sharedWorkspace] UTIForFile:[[NSWorkspace sharedWorkspace] resolveForAliases:fullpath]];
	
	NSAttributedString *import_content = nil;
	NSDictionary *docAttributes = nil;
	
	// check the uti
	if ( import_uti == nil ) 
	{
		NSLog(@"%s - unable to determine uti for file at path %@", __PRETTY_FUNCTION__, fullpath);
		return nil;
	}
	else
	{
		// given a uti, grab the mime type
		mime_type = (NSString*)UTTypeCopyPreferredTagWithClass((CFStringRef)import_uti,kUTTagClassMIMEType);
	}
	
	// ensure the title
	if ( !import_title ) 
		import_title = NSLocalizedString(@"untitled title",@"");
	
	
	// take action depending on the uti and/or mime
	if ( UTTypeConformsTo((CFStringRef)import_uti,kUTTypeWebArchive) ) 
	{
		// web archives
		_import_path = [fullpath retain];
		
		import_content = [[[NSAttributedString allocWithZone:[self zone]]
		initWithString:[NSString string] attributes:[JournlerEntry defaultTextAttributes]] autorelease];
	}
	
	else if ( UTTypeConformsTo((CFStringRef)import_uti, (CFStringRef)@"com.apple.mail.emlx") )
	{
		_import_path = nil;
		// use spotlight to get the title
		MDItemRef mdItem = MDItemCreate(NULL,(CFStringRef)fullpath);
		if ( mdItem != NULL )
		{
			import_title = [(NSString*)MDItemCopyAttribute(mdItem,kMDItemTitle) autorelease];
			if ( [import_title length] == 0 )
			{
				import_title = [(NSString*)MDItemCopyAttribute(mdItem,kMDItemDisplayName) autorelease];
				if ( [import_title length] == 0 )
					import_title = NSLocalizedString(@"untitled title", @"");
			}
		}
		
		_import_path = [fullpath retain];
		
		import_content = [[[NSAttributedString allocWithZone:[self zone]]
		initWithString:[NSString string] attributes:[JournlerEntry defaultTextAttributes]] autorelease];
	}
	
	else if ( UTTypeConformsTo((CFStringRef)import_uti,kUTTypePDF) ) 
	{
		// pdf documents
		_import_path = [fullpath retain];
		
		import_content = [[[NSAttributedString allocWithZone:[self zone]]
		initWithString:[NSString string] attributes:[JournlerEntry defaultTextAttributes]] autorelease];
	}
	
	else if ( [NSImage canInitWithFile:fullpath] )
	{
		// images
		_import_path = [fullpath retain];
		
		import_content = [[[NSAttributedString allocWithZone:[self zone]]
		initWithString:[NSString string] attributes:[JournlerEntry defaultTextAttributes]] autorelease];
	}
	
	else if ( [[NSWorkspace sharedWorkspace] canWatchFile:fullpath] ) 
	{
		// videos
		_import_path = [fullpath retain];
		
		import_content = [[[NSAttributedString allocWithZone:[self zone]]
		initWithString:[NSString string] attributes:[JournlerEntry defaultTextAttributes]] autorelease];
	}
	
	else if ( [[NSWorkspace sharedWorkspace] canPlayFile:fullpath] ) 
	{
		// audio
		_import_path = [fullpath retain];
		
		import_content = [[[NSAttributedString allocWithZone:[self zone]]
		initWithString:[NSString string] attributes:[JournlerEntry defaultTextAttributes]] autorelease];
	}
	
	else if ( UTTypeConformsTo((CFStringRef)import_uti,kUTTypeRTF) ) 
	{
		// rtf - import content
		NSData *rtfData = nil;
		NSError *error = nil;
		
		_import_path = nil;
		
		rtfData = [NSData dataWithContentsOfFile:fullpath options:NSUncachedRead error:&error];
		if ( rtfData == nil )
		{
			import_content = nil;
			NSLog(@"%s - problem reading rtf data for file at path %@, error: %@", __PRETTY_FUNCTION__, fullpath, error);
		}
		else
		{
			import_content = [[[NSAttributedString allocWithZone:[self zone]]
			initWithRTF:rtfData documentAttributes:&docAttributes] autorelease];
		}
	}
	
	else if ( UTTypeConformsTo((CFStringRef)import_uti,kUTTypeRTFD) )
	{
		// rtfd - import content
		_import_path = nil;
		
		NSFileWrapper *import_wrapper = [[[NSFileWrapper allocWithZone:[self zone]] initWithPath:fullpath] autorelease];
		if ( import_wrapper != nil ) 
		{
			import_content = [[[NSAttributedString allocWithZone:[self zone]]
			initWithRTFDFileWrapper:import_wrapper documentAttributes:&docAttributes] autorelease];
		}
		else
		{
			NSLog(@"%s - problem reading rtfd wrapper for file at path %@", __PRETTY_FUNCTION__, fullpath);
		}
	}
	
	else if ( UTTypeConformsTo((CFStringRef)import_uti,(CFStringRef)kPDUTTypeWordDocument) ) 
	{
		// word document - import content
		NSData *wordData = nil;
		NSError *error = nil;
		
		_import_path = nil;
		
		wordData = [NSData dataWithContentsOfFile:fullpath options:NSUncachedRead error:&error];
		if ( wordData == nil )
		{
			import_content = nil;
			NSLog(@"%s - problem reading rtf data for file at path %@, error: %@", __PRETTY_FUNCTION__, fullpath, error);
		}
		else
		{
			import_content = [[[NSAttributedString allocWithZone:[self zone]]
			initWithDocFormat:wordData documentAttributes:&docAttributes] autorelease];
		}		
	}
	
	else if ( UTTypeConformsTo((CFStringRef)import_uti, kUTTypePlainText) ) 
	{
		// plain text - go ahead and import this stuff
		NSString *plainText = nil;
		NSError *error = nil;
		NSStringEncoding encoding;
		
		_import_path = nil;
		
		plainText = [NSString stringWithContentsOfFile:fullpath usedEncoding:&encoding error:&error];
		if ( plainText == nil )
		{
			// let's try with a couple different encodings
			int i;
			NSStringEncoding encodings[2] = { NSMacOSRomanStringEncoding, NSUnicodeStringEncoding };
			
			for ( i = 0; i < 2; i++ )
			{
				plainText = [NSString stringWithContentsOfFile:fullpath encoding:encodings[i] error:&error];
				if ( plainText != nil )
					break;
			}
			
			if ( plainText == nil )
			{
				import_content = nil;
				NSLog(@"%s - problem reading plain text file at path %@, error: %@", __PRETTY_FUNCTION__, fullpath, error);
			}
			else
			{
				import_content = [[[NSAttributedString allocWithZone:[self zone]]
				initWithString:plainText attributes:[JournlerEntry defaultTextAttributes]] autorelease];
			}
		}
		else
		{
			import_content = [[[NSAttributedString allocWithZone:[self zone]]
			initWithString:plainText attributes:[JournlerEntry defaultTextAttributes]] autorelease];
		}
	}
	
	else if ( mime_type != nil && [WebView canShowMIMEType:mime_type] ) 
	{
		// anything a web view can display
		_import_path = [fullpath retain];
		
		import_content = [[[NSAttributedString allocWithZone:[self zone]]
		initWithString:[NSString string] attributes:[JournlerEntry defaultTextAttributes]] autorelease];
	}
	
	else if ( [[fullpath pathExtension] isEqualToString:kTextClippingExtension] ) 
	{
		_import_path = nil;
		PDTextClipping *textClipping = [[[PDTextClipping alloc] initWithContentsOfFile:fullpath] autorelease];
		
		if ( textClipping == nil )
			import_content = nil;
		else
		{
			if ( [textClipping isRichText] )
				import_content = [textClipping richTextRepresentation];
			else
				import_content = [[[NSAttributedString alloc] initWithString:[textClipping plainTextRepresentation] 
				 attributes:[JournlerEntry defaultTextAttributes]] autorelease];
		}
	}
	
	else if ( [[fullpath pathExtension] isEqualToString:kWeblocExtension] )
	{
		_import_path = [fullpath retain];
		
		import_content = [[[NSAttributedString allocWithZone:[self zone]]
		initWithString:[NSString string] attributes:[JournlerEntry defaultTextAttributes]] autorelease];
	}
	
	else 
	{
		// anything else will be referenced (but copied to the journal)
		_import_path = [fullpath retain];
		
		import_content = [[[NSAttributedString allocWithZone:[self zone]]
		initWithString:[NSString string] attributes:[JournlerEntry defaultTextAttributes]] autorelease];
	}
	
	// at this point the import content will content something or have failed to make the import
	if ( mime_type != nil ) 
		[mime_type release];
	if ( import_content == nil ) 
	{
		NSLog(@"%s unable to prepare import content for file at path %@", __PRETTY_FUNCTION__, fullpath);
		return nil;
	}
	
	// finder label
	short importedLabel = kEntryLabelForFinderLabel[ [[NSWorkspace sharedWorkspace] finderLabelColorForFile:fullpath] ];
	
	NSDictionary *import_attributes = [[[NSDictionary alloc] initWithObjectsAndKeys:
			import_title, PDEntryTitle,
			import_content, PDEntryAtttibutedContent, 
			[NSNumber numberWithShort:importedLabel], PDEntryLabelColor, nil] autorelease];
	
	if ( self = [self initWithProperties:import_attributes] ) 
	{
		if ( docAttributes != nil )
		{
			NSArray *someTags = [docAttributes objectForKey:NSKeywordsDocumentAttribute];
			// make the tags lowercase?
			
			NSString *someComments = [docAttributes objectForKey:NSCommentDocumentAttribute];
			NSString *someCategories = [docAttributes objectForKey:NSSubjectDocumentAttribute];
			
			[self setTags:someTags];
			[self setComments:someComments];
			[self setCategory:someCategories];
		}
	}
	
	// note the modification date on the file in case the user want's this preserved
	_importModificationDate = [[[[NSFileManager defaultManager] fileAttributesAtPath:fullpath traverseLink:YES] objectForKey:NSFileModificationDate] retain];
	
	return self;			
}

- (BOOL) completeImport:(int)importOptions operation:(NewResourceCommand)operation maxPreviewSize:(NSSize)maxSize
{	
	BOOL success = YES;
	BOOL includeIcon = ( importOptions & kEntryImportIncludeIcon );
	BOOL setDefaultResource = ( importOptions & kEntryImportSetDefaultResource );
	BOOL preserveModificationDate = ( importOptions & kEntryImportPreserveDateModified );
	
	// copy the import path if available to our resource directory
	if ( _import_path != nil ) 
	{
		// get the resource
		JournlerResource *importedResource = nil;
		
		// special treatment for webloc files
		if ( [[_import_path pathExtension] isEqualToString:kWeblocExtension] )
		{
			PDWeblocFile *webloc = [[[PDWeblocFile alloc] initWithContentsOfFile:_import_path] autorelease];
			if ( webloc == nil )
			{
				NSLog(@"%s - unable to get location information for webloc at path %@", __PRETTY_FUNCTION__, _import_path);
				return NO;
			}
			
			importedResource = [self resourceForURL:[[webloc url] absoluteString] title:[webloc displayName]];
			if ( importedResource == nil )
			{
				NSLog(@"%s - unable to get resource for webloc at path %@", __PRETTY_FUNCTION__, _import_path);
				return NO;
			}
		}
		else
		{
			importedResource = [self resourceForFile:_import_path operation:operation];
			if ( importedResource == nil )
			{
				NSLog(@"%s - unable to get resource for file at path %@", __PRETTY_FUNCTION__, _import_path );
				return NO;
			}
		}
		
		// set resource as default if requested
		if ( setDefaultResource )
			[self setSelectedResource:importedResource];
		
		// preapre the entry content
		NSURL *full_local_url = [importedResource URIRepresentation];
		NSString *importedFilePath = [importedResource originalPath];
		
		// set a title on this resource and entry that's a little more useful than the default
		if ( [[NSWorkspace sharedWorkspace] canWatchFile:_import_path] || [[NSWorkspace sharedWorkspace] canPlayFile:_import_path]
				|| [[NSWorkspace sharedWorkspace] canViewFile:_import_path] 
				|| [[NSWorkspace sharedWorkspace] file:_import_path conformsToUTI:ResourceMailUTI] 
				|| [[NSWorkspace sharedWorkspace] file:_import_path conformsToUTI:ResourceMailStandardEmailUTI] )
		{
			NSString *importTitle = [[NSWorkspace sharedWorkspace] mdTitleForFile:_import_path];
			if ( importTitle != nil )
			{
				[importedResource setValue:importTitle forKey:@"title"];
				[self setValue:importTitle forKey:@"title"];
			}
		}
		
		// set our content to a link to this media and an image if applicable
		NSMutableAttributedString *attributed_content;
		NSString *link_string;
		
		if ( [NSImage canInitWithFile:importedFilePath] )
		{
			
			// if dealing with an image file
			// use the journler_local_url plus an image of the file for the link
			
			NSImage *img = [[[NSImage alloc] initWithContentsOfFile:importedFilePath] autorelease];
			if ( !img ) 
			{
				NSLog(@"%s - unable to create img from %@", __PRETTY_FUNCTION__, importedFilePath);
				return NO;
			}
			
			//NSAttributedString *attributed_img = [JUtility attributedStringForImage:img quality:10 maxWidth:maxSize.width];
			NSAttributedString *attributed_img = [img attributedString:10 maxWidth:maxSize.width];
			
			if ( attributed_img == nil )
			{ 
				[img release];
				NSLog(@"%s - unable to derive attributed string from img %@", __PRETTY_FUNCTION__, importedFilePath);
				return NO;
			}
			
			link_string = [NSString stringWithFormat:@"  \n\n"];
			attributed_content = [[[NSMutableAttributedString allocWithZone:[self zone]] initWithString:link_string attributes:[JournlerEntry defaultTextAttributes]] autorelease];
			[attributed_content insertAttributedString:attributed_img atIndex:1];
			[attributed_content addAttribute:NSLinkAttributeName value:full_local_url range:NSMakeRange(1,1)];
		}
		
		else 
		{
			// if dealing with a text based file,
			// use the journler_local_url and the title of the entry for the link, as well as a preview icon
			
			// the base content string
			NSMutableAttributedString *insertString = [[[NSMutableAttributedString alloc] 
			initWithString:[NSString string] attributes:[JournlerEntry defaultTextAttributes]] autorelease];
			
			// the linked text
			NSString *linkedText = [self title];
			
			// ----
			
			if ( includeIcon ) 
			{
				// the preview icon
				//NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:importedFilePath];
				NSImage *theIcon = [importedResource icon];
				//[icon setSize:NSMakeSize(128,128)];
				NSImage *resizedImage = [theIcon imageWithWidth:32 height:32 inset:0];
			
				// prepare the image if one is available
				if ( resizedImage != nil ) 
				{
					NSBitmapImageRep *bitmapRep = [[[NSBitmapImageRep alloc] initWithData:[resizedImage TIFFRepresentation]] autorelease];
					if ( bitmapRep == nil )
					{
						NSLog(@"%s - unable to create bitmap rep from image", __PRETTY_FUNCTION__);
					}
					else 
					{
						NSFileWrapper *iconWrapper = [[[NSFileWrapper alloc] 
								initRegularFileWithContents:[bitmapRep representationUsingType:NSPNGFileType 
								properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] 
								forKey:NSImageCompressionFactor]]] autorelease];
								
						if ( iconWrapper == nil )
						{
							NSLog(@"%s - unable to create icon file wrapper from bitmap", __PRETTY_FUNCTION__);
						}
						else 
						{
							if ( linkedText )
								[iconWrapper setPreferredFilename:[linkedText stringByAppendingPathExtension:@"png"]];
							else
								[iconWrapper setPreferredFilename:@"iconimage.png"];
							
							NSTextAttachment *iconAttachment = [[[NSTextAttachment alloc] initWithFileWrapper:iconWrapper] autorelease];
							if ( iconAttachment == nil )
							{
								NSLog(@"%s - unable to create icon text attachment from file wrapper", __PRETTY_FUNCTION__);
							}
							else 
							{
								NSMutableAttributedString *imgStr = [[[NSAttributedString 
								attributedStringWithAttachment:iconAttachment] mutableCopyWithZone:[self zone]] autorelease];
								
								[imgStr addAttributes:[JournlerEntry defaultTextAttributes] range:NSMakeRange(0,[imgStr length])];
								[imgStr addAttribute:NSLinkAttributeName value:full_local_url range:NSMakeRange(0,[imgStr length])];
							
								// actually add the image to our final string
								[insertString appendAttributedString:imgStr];
							}
						}
					}
				}
			}
			
			// add a space!
			[insertString appendAttributedString:[[[NSAttributedString alloc] initWithString:@" "] autorelease]];
		
			// prepare the text if text is available
			if ( linkedText != nil )
			{
				NSMutableAttributedString *textStr = [[[NSMutableAttributedString alloc] initWithString:linkedText 
				attributes:[JournlerEntry defaultTextAttributes]] autorelease];
				
				[textStr addAttribute:NSLinkAttributeName value:full_local_url range:NSMakeRange(0,[textStr length])];
						
				// add the text to the final string
				[insertString appendAttributedString:textStr];
			}
			
			// final newlines
			[insertString appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n\n"] autorelease]];
			
			// final attributes
			[insertString addAttributes:[JournlerEntry defaultTextAttributes] range:NSMakeRange(0, [insertString length])];
			
			attributed_content = insertString;
			
			// ---
			
			//link_string = [NSString stringWithFormat:@" %@ \n\n", [self title]];
			//attributed_content = [[[NSMutableAttributedString allocWithZone:[self zone]] initWithString:link_string attributes:[JournlerEntry defaultTextAttributes]] autorelease];
			//[attributed_content addAttribute:NSLinkAttributeName value:full_local_url range:NSMakeRange(1,[[self title] length])];
		}
		
		// use spotlight to get some possible metadata for the entry
		// kMDItemKeywords -> keywords
		// kMDItemComment, kMDItemFinderComment -> comments
		// kMDItemProjects, kMDItemAlbum -> category
		// kMDItemDueDate
		// kMDItemDescription
		
		static NSString *kPDMDItemMailTagsDueDate = @"mailTagsItemDueDate";
		
		MDItemRef mdItem = MDItemCreate(NULL,(CFStringRef)_import_path);
		if ( mdItem != nil )
		{
			NSMutableSet *importTagsSet = [NSMutableSet setWithArray:[self tags]];
			NSMutableString *importComments = [[[self comments] mutableCopyWithZone:[self zone]] autorelease];
			NSMutableString *importCategory = [[[self category] mutableCopyWithZone:[self zone]] autorelease];
			
			NSDate *mdDateDue = nil;
			NSArray *mdTags = nil, *mdProjects = nil;
			NSString *mdComment = nil, *mdFinderComment, *mdAlbum = nil;
			
			mdTags = [(NSArray*)MDItemCopyAttribute(mdItem,kMDItemKeywords) autorelease];
			// make the tags lowercase?
			
			mdComment = [(NSString*)MDItemCopyAttribute(mdItem,kMDItemComment) autorelease];
			mdFinderComment = [(NSString*)MDItemCopyAttribute(mdItem,kMDItemFinderComment) autorelease];
			
			mdProjects = [(NSArray*)MDItemCopyAttribute(mdItem,kMDItemProjects) autorelease];
			mdAlbum = [(NSString*)MDItemCopyAttribute(mdItem,kMDItemAlbum) autorelease];
			
			mdDateDue = [(NSDate*)MDItemCopyAttribute(mdItem, kMDItemDueDate) autorelease];
			if ( mdDateDue == nil ) mdDateDue = [(NSDate*)MDItemCopyAttribute(mdItem, (CFStringRef)kPDMDItemMailTagsDueDate) autorelease];
			
			if ( mdTags != nil ) [importTagsSet addObjectsFromArray:mdTags];
			
			if ( mdComment != nil ) [importComments appendFormat:@" %@", mdComment];
			if ( mdFinderComment != nil && ![mdComment isEqualToString:mdFinderComment] ) [importComments appendFormat:@" %@", mdFinderComment];
			
			if ( mdProjects != nil ) [importCategory appendFormat:@" %@", [mdProjects componentsJoinedByString:@", "]];
			if ( mdAlbum != nil ) [importCategory appendFormat:@" %@", mdAlbum];
			
			[self setTags:[importTagsSet allObjects]];
			[self setComments:importComments];
			[self setCategory:importCategory];
			[self setDateDue:mdDateDue];
			
			// clean up
			CFRelease(mdItem);
		}
		
		// set and clean up
		[self setAttributedContent:attributed_content];
		
		[_import_path release], _import_path = nil;
	}
	
	if ( preserveModificationDate )
	{
		[self setCalDateModified:[_importModificationDate dateWithCalendarFormat:nil timeZone:nil]];
		[_importModificationDate release], _importModificationDate = nil;
	}
	
	return success;
}

#pragma mark -
#pragma mark Saving an entry to file

- (BOOL)writeToFile:(NSString*)path as:(int)saveType flags:(int)saveFlags
{	
	//this guy takes an entry, preps a text with all the releveant information, then saves it to filepath
	//with either rtf or rtfd, perhaps doc, html, or pdf later
	
	BOOL modCreation = ( saveFlags & kEntrySetFileCreationDate );
	BOOL modModified = ( saveFlags & kEntrySetFileModificationDate );
	BOOL withHeader = ( saveFlags & kEntryIncludeHeader );
	BOOL setLabel = ( saveFlags & kEntrySetLabelColor );
	BOOL hideExtension = ( saveFlags & kEntryHideExtension );
	BOOL overwrite = !( saveFlags & kEntryDoNotOverwrite );
	
	NSError *error;
	NSFileWrapper *rtfWrapper;
	NSMutableDictionary *fileAttributes;
	NSMutableString *textString;
	//a temp text make saving rtf and rtfd much easier
	NSAttributedString *tempText = [[self prepWithTitle:withHeader category:withHeader smallDate:withHeader] attributedStringWithoutJournlerLinks];
	
	NSString *filename = path;
	NSString *saveWithExtension = path;
	
	// none of the values here should ever be nil
	NSDictionary *doc_attributes = [NSDictionary dictionaryWithObjectsAndKeys:
			[self calDate],	NSCreationTimeDocumentAttribute,
			[self calDateModified], NSModificationTimeDocumentAttribute,
			[self tags], NSKeywordsDocumentAttribute,
			[self comments], NSCommentDocumentAttribute,
			[self title], NSTitleDocumentAttribute,
			[self category], NSSubjectDocumentAttribute, nil];
	
	switch ( saveType ) {

	case kEntrySaveAsRTF:
		
		if ( ![[filename pathExtension] isEqualToString:@"rtf"] )
		{
			if ( overwrite ) 
				saveWithExtension = [filename stringByAppendingPathExtension:@"rtf"];
			else
				saveWithExtension = [[filename stringByAppendingPathExtension:@"rtf"] pathWithoutOverwritingSelf];
		}
		
		rtfWrapper = [[NSFileWrapper alloc] initRegularFileWithContents: 
			[tempText RTFFromRange:NSMakeRange(0, [tempText length]) documentAttributes:doc_attributes]];
		
		[rtfWrapper setPreferredFilename:saveWithExtension];

		if ( ![rtfWrapper writeToFile:saveWithExtension atomically:YES updateFilenames:YES] ) {
			//NSBeep();
			[rtfWrapper release];
			NSLog(@"Unable to write entry '%@' to location '%@'", [self title], saveWithExtension);
			return NO;
		}
		[rtfWrapper release];
		
		break;
		
	case kEntrySaveAsWord:
		
		if ( ![[filename pathExtension] isEqualToString:@"doc"] )
		{
			if ( overwrite ) 
				saveWithExtension = [filename stringByAppendingPathExtension:@"doc"];
			else
				saveWithExtension = [[filename stringByAppendingPathExtension:@"doc"] pathWithoutOverwritingSelf];
		}
		
		//attributed strings are cool	
		NSData *docData = [tempText docFormatFromRange:NSMakeRange(0, [tempText length]) documentAttributes:doc_attributes];
		
		if ( ![docData writeToFile:saveWithExtension atomically:YES] ) {
			//NSBeep();
			NSLog(@"Unable to write entry '%@' to location '%@'", [self title], saveWithExtension);
			return NO;
		}
				
		break;
		
	case kEntrySaveAsRTFD:
		
		if ( ![[filename pathExtension] isEqualToString:@"rtfd"] )
		{
			if ( overwrite ) 
				saveWithExtension = [filename stringByAppendingPathExtension:@"rtfd"];
			else
				saveWithExtension = [[filename stringByAppendingPathExtension:@"rtfd"] pathWithoutOverwritingSelf];
		}
		
		NSFileWrapper *rtfdWrapper = [tempText RTFDFileWrapperFromRange:NSMakeRange(0, [tempText length])
			documentAttributes:doc_attributes];

		if ( ![rtfdWrapper writeToFile:saveWithExtension atomically:YES updateFilenames:YES] ) {
			//NSBeep();
			NSLog(@"Unable to write entry '%@' to location '%@'", [self title], saveWithExtension);
			return NO;
		}
				
		break;
		
	case kEntrySaveAsPDF:
		
		if ( ![[filename pathExtension] isEqualToString:@"pdf"] )
		{
			if ( overwrite ) 
				saveWithExtension = [filename stringByAppendingPathExtension:@"pdf"];
			else
				saveWithExtension = [[filename stringByAppendingPathExtension:@"pdf"] pathWithoutOverwritingSelf];
		}
		
		//format the page using current printer settings
		NSPrintInfo *printInfo;
		NSPrintOperation *printOp;

		printInfo = [[[NSPrintInfo sharedPrintInfo] copyWithZone:[self zone]] autorelease];
		[printInfo setJobDisposition:NSPrintSaveJob];
		[[printInfo dictionary]  setObject:saveWithExtension forKey:NSPrintSavePath];
			
		[printInfo setHorizontalPagination: NSAutoPagination];
		[printInfo setVerticalPagination: NSAutoPagination];
		[printInfo setVerticallyCentered:NO];
		[[printInfo dictionary] setValue:[NSNumber numberWithBool:NO] forKey:NSPrintHeaderAndFooter];
		
		//should give me the width and height
		int width = [printInfo paperSize].width - ( [printInfo rightMargin] + [printInfo leftMargin] );
		int height = [printInfo paperSize].height - ( [printInfo topMargin] + [printInfo bottomMargin] );
		
		// prepare a text view that overrides the header and footer that is now on by default
		PDPrintTextView *pdfView = [[PDPrintTextView alloc] initWithFrame:NSMakeRect(0,0,width,height)];
		
		[pdfView setPrintHeader:NO];
		[pdfView setPrintFooter:NO];
		
		[[pdfView textStorage] beginEditing];
		[[pdfView textStorage] replaceCharactersInRange:NSMakeRange(0,0) withAttributedString:tempText];
		[[pdfView textStorage] endEditing];
		[pdfView sizeToFit];
		
		printOp = [NSPrintOperation printOperationWithView:pdfView printInfo:printInfo];
		[printOp setShowPanels:NO];
		
		if ( ![printOp runOperation] )
		{
			[pdfView release];
			NSLog(@"Unable to write entry '%@' to location '%@'", [self title], saveWithExtension);
			return NO;
		}
		
		//[printInfo release];
		[pdfView release];
		
		break;
		
	case kEntrySaveAsHTML:
		
		if ( ![[filename pathExtension] isEqualToString:@"html"] )
		{
			if ( overwrite ) 
				saveWithExtension = [filename stringByAppendingPathExtension:@"html"];
			else
				saveWithExtension = [[filename stringByAppendingPathExtension:@"html"] pathWithoutOverwritingSelf];
		}
		
		NSString *html_to_export;
		
		if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"ExportsUseAdvancedHTMLGeneration"] )
			html_to_export = [[tempText attributedStringWithoutJournlerLinks]
					attributedStringAsHTML:kUseSystemHTMLConversion|kConvertSmartQuotesToRegularQuotes
					documentAttributes:[NSDictionary dictionaryWithObject:[self title] forKey:NSTitleDocumentAttribute]
					avoidStyleAttributes:[[NSUserDefaults standardUserDefaults] stringForKey:@"ExportsNoAttributeList"]];
					
		else
			html_to_export = [[[tempText attributedStringWithoutJournlerLinks] attributedStringAsHTML:kUseJournlerHTMLConversion|kConvertSmartQuotesToRegularQuotes
					documentAttributes:nil avoidStyleAttributes:nil] stringAsHTMLDocument:[self title]];
					
				
		if ( ![html_to_export writeToFile:saveWithExtension atomically:YES encoding:NSUTF8StringEncoding error:&error] )
		{
			NSLog(@"Unable to write entry '%@' to location '%@', error: %@", [self title], saveWithExtension, error);
			return NO;
		}
		break;
	
	case kEntrySaveAsText:
	
		if ( ![[filename pathExtension] isEqualToString:@"txt"] )
		{
			if ( overwrite ) 
				saveWithExtension = [filename stringByAppendingPathExtension:@"txt"];
			else
				saveWithExtension = [[filename stringByAppendingPathExtension:@"txt"] pathWithoutOverwritingSelf];
		}
		
		textString = [[tempText string] mutableCopyWithZone:[self zone]];
		[textString replaceOccurrencesOfString:[NSString stringWithCharacters:(const unichar[]) {NSAttachmentCharacter} length:1] 
				withString:[NSString string] options:NSLiteralSearch range:NSMakeRange(0, [textString length])];
		
		//if ( ![textString writeToFile:saveWithExtension atomically:YES] ) 
		if ( ![textString writeToFile:saveWithExtension atomically:YES encoding:NSUnicodeStringEncoding error:&error] )
		{
			[textString release];
			NSLog(@"Unable to write entry %@ as text to location %@, error: %@", [self title], saveWithExtension, error);
			return NO;
		}
		
		[textString release];
		break;
	
	case kEntrySaveAsiPodNote:
		
		// break my text into chunks of 4000 characters or less, titled and linked
		return [self _writeiPodNote:[[self prepWithTitle:YES category:YES smallDate:YES] iPodLinkedNote:[self journal]] iPod:path];
		break;
	
	case kEntrySaveAsWebArchive:
		
		if ( ![[filename pathExtension] isEqualToString:@"webarchive"] )
		{
			if ( overwrite ) 
				saveWithExtension = [filename stringByAppendingPathExtension:@"webarchive"];
			else
				saveWithExtension = [[filename stringByAppendingPathExtension:@"webarchive"] pathWithoutOverwritingSelf];
		}
		
		NSMutableDictionary *archiveAttributes = [[doc_attributes mutableCopyWithZone:[self zone]] autorelease];
		
		[archiveAttributes setObject:NSWebArchiveTextDocumentType forKey:NSDocumentTypeDocumentAttribute];
		NSFileWrapper *archiveWrapper = [tempText fileWrapperFromRange:NSMakeRange(0,[tempText length])
				documentAttributes:archiveAttributes error:nil];
		
		if ( ![archiveWrapper writeToFile:saveWithExtension atomically:YES updateFilenames:YES] )
		{
			NSLog(@"%s - unable to write entry as webarchive '%@' to location '%@'", __PRETTY_FUNCTION__, [self title], saveWithExtension);
			return NO;
		}
		
		break;
	
	}
	
	// hide or the extension - this overrides the user preference?
	fileAttributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
			[NSNumber numberWithBool:hideExtension], NSFileExtensionHidden, nil] autorelease];

	// set the files creation date to that of the entry
	if ( modCreation )
		[fileAttributes setObject:[self calDate] forKey:NSFileCreationDate];
	if ( modModified )
		[fileAttributes setObject:[self calDateModified] forKey:NSFileModificationDate];
		
	if ( setLabel )
		[[NSWorkspace sharedWorkspace] setLabel:kFinderLabelForEntryLabel[ [[self label] intValue] ] forFile:saveWithExtension];
		
	[[NSFileManager defaultManager] changeFileAttributes:fileAttributes atPath:saveWithExtension];

	return YES;
}

/*
- (BOOL) createFolderAtDestination:(NSString*)path
{
	// exports the entry's contents as well as all of its resources
	#warning implement createFolderAtDestination
	return NO;
}
*/

#pragma mark -

- (NSAttributedString*) prepWithTitle:(BOOL)wTitle category:(BOOL)wCategory smallDate:(BOOL)wDate {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSMutableDictionary *tempAttributes = [NSMutableDictionary dictionary];
	NSMutableAttributedString *tempText = [[NSMutableAttributedString alloc] init];
	
	if ( wTitle || wCategory || wDate )
	{
		if ( wTitle )
		{
			// the title lable
			[tempAttributes setObject:[NSColor colorWithCalibratedWhite:0.5 alpha:1.0] forKey:NSForegroundColorAttributeName];
			[tempAttributes setObject:[NSFont systemFontOfSize:11] forKey:NSFontAttributeName];
			
			NSString *titleLabel = [NSString stringWithFormat:@"%@:  ", NSLocalizedString(@"title label",@"")];
			NSAttributedString *attributedTitleLabel = [[[NSAttributedString alloc] initWithString:titleLabel attributes:tempAttributes] autorelease];
			
			// the title content
			[tempAttributes setObject:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] forKey:NSForegroundColorAttributeName];
			[tempAttributes setObject:[NSFont systemFontOfSize:11] forKey:NSFontAttributeName];
			
			NSString *titleContent = [self valueForKey:@"title"];
			if ( titleContent == nil ) titleContent = [NSString string];
			NSAttributedString *attributedTitleContent = [[[NSAttributedString alloc] initWithString:titleContent attributes:tempAttributes] autorelease];
			
			[tempText appendAttributedString:attributedTitleLabel];
			[tempText appendAttributedString:attributedTitleContent];
			[tempText replaceCharactersInRange:NSMakeRange([tempText length],0) withString:@"\n"];
		}
		
		if ( wDate ) 
		{
			NSDateFormatter *date_formatter = [[[NSDateFormatter alloc] init] autorelease];
			[date_formatter setDateStyle:NSDateFormatterLongStyle];
			[date_formatter setTimeStyle:NSDateFormatterShortStyle];
			
			// the date label
			[tempAttributes setObject:[NSColor colorWithCalibratedWhite:0.5 alpha:1.0] forKey:NSForegroundColorAttributeName];
			[tempAttributes setObject:[NSFont systemFontOfSize:11] forKey:NSFontAttributeName];
			
			NSString *dateLabel = [NSString stringWithFormat:@"%@:  ", NSLocalizedString(@"date label",@"")];
			NSAttributedString *attributedDateLabel = [[[NSAttributedString alloc] initWithString:dateLabel attributes:tempAttributes] autorelease];
			
			// the date content
			[tempAttributes setObject:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] forKey:NSForegroundColorAttributeName];
			[tempAttributes setObject:[NSFont systemFontOfSize:11] forKey:NSFontAttributeName];
			
			NSString *dateContent = [date_formatter stringFromDate:[self valueForKey:@"calDate"]];
			if ( dateContent == nil ) dateContent = [NSString string];
			NSAttributedString *attributedDateContent = [[[NSAttributedString alloc] initWithString:dateContent attributes:tempAttributes] autorelease];
			
			[tempText appendAttributedString:attributedDateLabel];
			[tempText appendAttributedString:attributedDateContent];
			[tempText replaceCharactersInRange:NSMakeRange([tempText length],0) withString:@"\n"];		
		}

		if ( wCategory ) 
		{
			// the category label
			[tempAttributes setObject:[NSColor colorWithCalibratedWhite:0.5 alpha:1.0] forKey:NSForegroundColorAttributeName];
			[tempAttributes setObject:[NSFont systemFontOfSize:11] forKey:NSFontAttributeName];
			
			NSString *categoryLabel = [NSString stringWithFormat:@"%@:  ", NSLocalizedString(@"category label",@"")];
			NSAttributedString *categoryAttributedLabel = [[[NSAttributedString alloc] initWithString:categoryLabel attributes:tempAttributes] autorelease];
			
			// the date content
			[tempAttributes setObject:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] forKey:NSForegroundColorAttributeName];
			[tempAttributes setObject:[NSFont systemFontOfSize:11] forKey:NSFontAttributeName];
			
			NSString *categoryContent = [self valueForKey:@"category"];
			if ( categoryContent == nil ) categoryContent = [NSString string];
			NSAttributedString *attributedCategoryContent = [[[NSAttributedString alloc] initWithString:categoryContent attributes:tempAttributes] autorelease];
			
			[tempText appendAttributedString:categoryAttributedLabel];
			[tempText appendAttributedString:attributedCategoryContent];
			[tempText replaceCharactersInRange:NSMakeRange([tempText length],0) withString:@"\n"];		
			
			
			// the tags label [prev: keywords]
			[tempAttributes setObject:[NSColor colorWithCalibratedWhite:0.5 alpha:1.0] forKey:NSForegroundColorAttributeName];
			[tempAttributes setObject:[NSFont systemFontOfSize:11] forKey:NSFontAttributeName];
			
			NSString *tagsLabel = [NSString stringWithFormat:@"%@:  ", NSLocalizedString(@"tags label",@"")];
			NSAttributedString *attributedTagsLabel = [[[NSAttributedString alloc] initWithString:tagsLabel attributes:tempAttributes] autorelease];
			
			// the keywords content
			[tempAttributes setObject:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] forKey:NSForegroundColorAttributeName];
			[tempAttributes setObject:[NSFont systemFontOfSize:11] forKey:NSFontAttributeName];
			
			NSArray *allTags = [self valueForKey:@"tags"];
			NSString *tagsContent = [allTags componentsJoinedByString:@", "];
			if ( tagsContent == nil ) tagsContent = [NSString string];
			NSAttributedString *attributedTagsContent = [[[NSAttributedString alloc] initWithString:tagsContent attributes:tempAttributes] autorelease];
			
			[tempText appendAttributedString:attributedTagsLabel];
			[tempText appendAttributedString:attributedTagsContent];
			[tempText replaceCharactersInRange:NSMakeRange([tempText length],0) withString:@"\n"];	
		}
	}
	
	// add the actual content  ---------
	NSAttributedString *textualContent = [self attributedContent];
	if ( textualContent ) 
	{
		// append a space between the header and content 
		// if there is a header
		if ( wTitle || wCategory || wDate )
			[tempText replaceCharactersInRange:NSMakeRange([tempText length],0) withString:@"\n"];	
		
		[tempText appendAttributedString:textualContent];
	}
	
	// clean up
	[pool release];
	
	return [tempText autorelease];
}

- (BOOL) _writeiPodNote:(NSString*)contents iPod:(NSString*)path {
	
	//
	// content should already be parsed for entry links
	
	NSMutableString *mutable_string = [[contents mutableCopyWithZone:[self zone]] autorelease];
	[mutable_string replaceOccurrencesOfString:[NSString stringWithCharacters:(const unichar[]) {NSAttachmentCharacter} length:1] 
			withString:[NSString string] options:NSLiteralSearch range:NSMakeRange(0, [mutable_string length])];

	
	static int kMaxChars = 2000;
	NSString *baseTitle = [NSString stringWithFormat:@"%@ %@", [self pathSafeTitle], [self tagID]];
	static NSString *pathExtension = @"txt";
	
	if ( [mutable_string length] <= kMaxChars ) 
	{
		NSError *error;
		NSString *actualPath = [NSString stringWithFormat:@"%@ %i.%@", baseTitle, 1, pathExtension];
		//BOOL wroteWorked = [mutable_string writeToFile:[path stringByAppendingPathComponent:actualPath] atomically:YES];
		BOOL wroteWorked = [mutable_string writeToFile:[path stringByAppendingPathComponent:actualPath] atomically:YES encoding:NSUnicodeStringEncoding error:&error];
		if ( !wroteWorked )
		{
			NSLog(@"%s - unable to write the note to %@, error: %@", __PRETTY_FUNCTION__, [path stringByAppendingPathComponent:actualPath], error);
		}
		
		return wroteWorked;
	}
	else 
	{
		@try
		{

			// the entry must be broken up into pieces and they must be connected
			int additionalFiles = 1;
			unsigned int startIndex, endIndex;
			NSRange lineRange;
			NSRange currentRange = NSMakeRange(0, kMaxChars);
			NSMutableString *workingContents = mutable_string;
			
			while ( [workingContents length] > 0 ) {
			
				//
				// get the max length for this portion, first try for a line
				startIndex = 0; endIndex = 0;
				
				[workingContents getLineStart:&startIndex end:&endIndex contentsEnd:NULL forRange:NSMakeRange(currentRange.length-1,1)];
				lineRange.location = startIndex; lineRange.length = endIndex - startIndex;
				
				if ( lineRange.location == NSNotFound ) {
				
					// if that doesn't work, try for a space
					lineRange = [workingContents rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet] 
							options:NSBackwardsSearch range:NSMakeRange(currentRange.length-1,1)];
							
					if ( lineRange.location == NSNotFound ) {
					
						//if that doesnt work, take what we already have
						lineRange = currentRange;
					}
				}
				
				//
				// cut the string
				NSRange thisFilesRange = NSMakeRange(currentRange.location, lineRange.location + lineRange.length );
				NSString *thisFilesContents = [workingContents substringWithRange:thisFilesRange];
				
				//
				// remove the cut contents from the string
				[workingContents deleteCharactersInRange:thisFilesRange];
				
				NSString *nextFilesTitle = nil, *thisFilesTitle;
				thisFilesTitle = [NSString stringWithFormat:@"%@ %i.%@", baseTitle, additionalFiles, pathExtension];
				
				if ( [workingContents length] != 0 ) 
				{
					// append a link to the next file, prepend a link to this file
					nextFilesTitle = [NSString stringWithFormat:@"%@ %i.%@", baseTitle, ++additionalFiles, pathExtension];
					
					NSString *nextLink = [NSString stringWithFormat:@"\n<a href=\"%@\">next</a>", nextFilesTitle];
					NSString *previousLink = [NSString stringWithFormat:@"<a href=\"%@\">previous</a>\n", thisFilesTitle];
					
					[workingContents insertString:previousLink atIndex:0];
					thisFilesContents = [thisFilesContents stringByAppendingString:nextLink];
				}
				
				// write out this files contents
				NSError *error;
				//if ( ![thisFilesContents writeToFile:[path stringByAppendingPathComponent:thisFilesTitle] atomically:YES] ) {
				if ( ![thisFilesContents writeToFile:[path stringByAppendingPathComponent:thisFilesTitle] atomically:YES encoding:NSUnicodeStringEncoding error:&error] )
				{
					NSLog(@"Unable to export entry %@ to path %@, error: %@", [self tagID], [path stringByAppendingPathComponent:thisFilesTitle], error );
					return NO;
				}
				
				// reset the current range
				currentRange = NSMakeRange(0, [workingContents length]);
				if ( currentRange.length > kMaxChars ) currentRange.length = kMaxChars;
			
			}
		}
		@catch (NSException *localException)
		{
			NSLog(@"%s - encountered exception: %@", __PRETTY_FUNCTION__, [localException description]);
			return NO;
		}
		@finally
		{
			return YES;
		}
	}
}

- (NSString*) htmlRepresentationWithCache:(NSString*)cachePath
{
	// prodcue an html representation of the entry, storing images at cachePath

	NSString *fullname = [self valueForKey:@"title"];
	NSImage *icon = [[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Entry" ofType:@"icns"]] autorelease];
	
	[icon setSize:NSMakeSize(128,128)];
	
	
	static NSString *img = @"<img align=\"left\" src=\"%@\" />\n";
	static NSString *imgLink = @"<a href=\"%@\">%@</a>";
	static NSString *header = @"<h3>%@</h3>\n";
	static NSString *openTable = @"<table class=\"infotable\" cellspacing=\"2\" cellpadding=\"0\" border=\"0\" cols=\"2\">\n"; 
	static NSString *closeTable = @"</table>\n";
	static NSString *row = @"<tr style=\"inforow\" valign=\"top\"><td align=\"right\" class=\"label\">%@</td><td align=\"left\" class=\"labelvalue\">%@</td></tr>\n";
	
	NSMutableString *htmlBody = [NSMutableString string];
		
	NSString *largeIconFilename = @"EntryIcon-128";
	NSString *iconPath = [[cachePath stringByAppendingPathComponent:largeIconFilename] stringByAppendingPathExtension:@"tiff"];
	
	if ( ![[NSFileManager defaultManager] fileExistsAtPath:iconPath] ) 
	{
		[[icon TIFFRepresentation] writeToFile:iconPath atomically:NO];
	}
	
	// draw the header
	[htmlBody appendString:@"<div style=\"clear:both;\">"];
	//[htmlBody appendString:@"<br style=\"clear:both;\" />"];
	
	
	// draw the icon
	NSURL *imgURL = [NSURL fileURLWithPath:iconPath];
	NSString *thisImg = [NSString stringWithFormat:img, [imgURL absoluteString]];
	NSString *thisImgLink = [NSString stringWithFormat:imgLink, [self URIRepresentation], thisImg];
	
	//[htmlBody appendString:@"<div style=\"clear:both;\">"];
	//[htmlBody appendString:thisImg];
	[htmlBody appendString:thisImgLink];
	
	NSString *theHeader = [NSString stringWithFormat:header,fullname];
	[htmlBody appendString:theHeader];
	
	
	// open the table
	[htmlBody appendString:openTable];
	
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateStyle:NSDateFormatterLongStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];

	// build the table - date created, category, tags, summary
	NSString *createdRow = [NSString stringWithFormat:row,NSLocalizedString(@"date label",@""),[dateFormatter stringFromDate:[self valueForKey:@"calDate"]]];
	[htmlBody appendString:createdRow];
	
	if ( [[self valueForKey:@"category"] length] != 0 )
	{
		NSString *categoryRow = [NSString stringWithFormat:row,NSLocalizedString(@"category label",@""),[self valueForKey:@"category"]];
		[htmlBody appendString:categoryRow];
	}
	
	if ( [[self valueForKey:@"keywords"] length] != 0 )
	{
		NSString *tagsRow = [NSString stringWithFormat:row,NSLocalizedString(@"tags label",@""),[self valueForKey:@"keywords"]];
		[htmlBody appendString:tagsRow];
	}
	
	// close the table and the div
	//[htmlBody appendString:closeTable];
	//[htmlBody appendString:@"</div>"];
	
	// begin another div for the summary
	//[htmlBody appendString:@"<div class=\"labelvalue\">"];
	//[htmlBody appendString:@"<p class=\"labelvalue\">"];
	
	NSString *summary;
	NSString *plainContent = [[self valueForKey:@"attributedContent"] string];
	if ( plainContent == nil )
		 summary = [self valueForKey:@"title"];
	
	SKSummaryRef summaryRef = SKSummaryCreateWithString((CFStringRef)plainContent);
	if ( summaryRef == NULL )
		 summary = [self valueForKey:@"title"];
	
	summary = [(NSString*)SKSummaryCopySentenceSummaryString(summaryRef,1) autorelease];
	if ( summary == nil )
		summary = [self valueForKey:@"title"];
	
	if ( [summary isEqualToString:[self valueForKey:@"title"]] )
	{
		NSString *summaryRow = [NSString stringWithFormat:row,NSLocalizedString(@"summary label",@""),summary];
		[htmlBody appendString:summaryRow];
		[htmlBody appendString:closeTable];
	}
	else
	{
		[htmlBody appendString:closeTable];
		[htmlBody appendString:@"<div class=\"labelvalue\">"];
		[htmlBody appendString:[NSString stringWithFormat:@"<strong class=\"label\">%@</strong><br \\>", NSLocalizedString(@"summary label",@"")]];
		[htmlBody appendString:summary];
		[htmlBody appendString:@"</div>"];
	}
	
	//NSString *summaryRow = [NSString stringWithFormat:row,@"Summary",summary];
	//[htmlBody appendString:summaryRow];
	
	// close the table
	//[htmlBody appendString:closeTable];
	// close the div
	//[htmlBody appendString:@"</p>"];
	//[htmlBody appendString:@"</div>"];
	
	[htmlBody appendString:@"</div>"];
	
	return htmlBody;

}

@end

#pragma mark -

@implementation JournlerEntry (PreferencesSupport)

+ (BOOL) modsDateModdedOnlyOnTextualChange
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"UpdateDateModifiedOnlyAfterTextChange"];
}

+ (NSString*) defaultCategory
{
	NSString *defaultCategory = [[NSUserDefaults standardUserDefaults] stringForKey:@"Journler Default Category"];
	if ( [defaultCategory isEqualToString:@"-"] ) return nil;
	else return defaultCategory;
}

+ (NSString*) dropBoxCategory
{
	NSString *defaultCategory = [[NSUserDefaults standardUserDefaults] stringForKey:@"Drop Box Category"];
	if ( [defaultCategory isEqualToString:@"-"] ) return nil;
	else return defaultCategory;
}

@end

#pragma mark -

@implementation JournlerEntry (JournlerScriptability)

/*
- (id) scriptContainer
{
	return scriptContainer;
}

- (void) setScriptContainer:(id)anObject
{
	scriptContainer = anObject;
}
*/

- (NSTextStorage*) contents
{
	if ( scriptContents == nil )
	{
		scriptContents = [[NSTextStorage alloc] initWithAttributedString:[self attributedContent]];
		[scriptContents setDelegate:self];
	}
	else
	{
		[scriptContents setAttributedString:[self attributedContent]];
	}
	
	return scriptContents;
}

- (void) setContents:(id)anObject
{
	NSAttributedString *incomingAttributedContent = nil;
	NSAttributedString *processedAttributedContent = nil;
	
	// fork depending on the incoming object's class
	if ( [anObject respondsToSelector:@selector(attributedSubstringFromRange:)] )
		incomingAttributedContent = [anObject attributedSubstringFromRange:NSMakeRange(0,[anObject length])];
	else if ( [anObject respondsToSelector:@selector(substringWithRange:)] )
		incomingAttributedContent = [[[NSAttributedString alloc] initWithString:[anObject substringWithRange:NSMakeRange(0,[anObject length])] 
		attributes:[JournlerEntry defaultTextAttributes]] autorelease];
	else
		NSLog(@"%s - unable to dervie textual contents from object of class %@", __PRETTY_FUNCTION__, [anObject className]);
	
	// process the attributed content for links, leopard only
	if ( [incomingAttributedContent respondsToSelector:@selector(URLAtIndex:effectiveRange:)] && [self journal] != nil 
				&& ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryTextRecognizeURLs"] || [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryTextRecognizeWikiLinks"] ) )
		processedAttributedContent = [self processScriptSetContentsForLinks:incomingAttributedContent];
	else
		processedAttributedContent = incomingAttributedContent;
	
	// actually set the attributed content
	[self setValue:processedAttributedContent forKey:@"attributedContent"];
}

- (void)textStorageDidProcessEditing:(NSNotification *)aNotification
{
	NSTextStorage *aTextStorage = [aNotification object];
	if ( aTextStorage == scriptContents )
		[self setValue:[aTextStorage attributedSubstringFromRange:NSMakeRange(0,[aTextStorage length])] forKey:@"attributedContent"];
}

- (NSAttributedString*) processScriptSetContentsForLinks:(NSAttributedString*)anAttributedString
{
	// process the provided text for wiki, journler and url links
	// leopard only, as it uses the CFStringTokenizer API
	//
	// - (NSURL *)URLAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)effectiveRange
	// EntryTextRecognizeURLs
	// EntryTextRecognizeWikiLinks
	//
	// note that this only works when the entry has a journal
	
	//static NSString *fileUrlIdentifier = @"file://";
	//static NSString *urlIdentifier = @"://";
	
	BOOL checkForURLLinks = [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryTextRecognizeURLs"];
	BOOL checkForWikiLinks = [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryTextRecognizeWikiLinks"];
	
	NSMutableAttributedString *workingAttributedString = nil;
	
	if ( anAttributedString != nil )
	{
		workingAttributedString = [[anAttributedString mutableCopyWithZone:[self zone]] autorelease];
		
		// check for urls
		if ( checkForURLLinks )
		{
			// file urls, journler urls, web urls
			
			unsigned int length;
			NSRange effectiveRange;
			NSURL *aURL;
			 
			length = [workingAttributedString length];
			effectiveRange = NSMakeRange(0, 0);
			 
			while ( NSMaxRange(effectiveRange) < length ) 
			{
				aURL = [workingAttributedString URLAtIndex:NSMaxRange(effectiveRange) effectiveRange:&effectiveRange];
				if ( aURL != nil )
				{
					// what kind of url are we dealing with
					if ( [aURL isFileURL] )
					{
						//NSLog(@"file url: %@", aURL);
						if ( [[NSFileManager defaultManager] fileExistsAtPath:[aURL path]] )
						{
							JournlerResource *aResource = [self resourceForFile:[aURL path] operation:kNewResourceUseDefaults];
							if ( aResource != nil )
							{
								NSURL *resourceURI = [aResource URIRepresentation];
								[workingAttributedString addAttribute:NSLinkAttributeName value:resourceURI range:effectiveRange];
							}
						}
					}
					else if ( [aURL isJournlerURI] )
					{
						//NSLog(@"journler url: %@", aURL);
						JournlerResource *aResource = [self resourceForJournlerObject:[[self journal] objectForURIRepresentation:aURL]];
						if ( aResource != nil )
						{
							NSURL *resourceURI = [aResource URIRepresentation];
							[workingAttributedString addAttribute:NSLinkAttributeName value:resourceURI range:effectiveRange];
						}
					}
					else
					{
						//NSLog(@"regular url: %@", aURL);
						JournlerResource *aResource = [self resourceForURL:[aURL absoluteString] title:[aURL absoluteString]];
						if ( aResource != nil )
						{
							// actually use the url and let journler find the resource for it on the fly
							[workingAttributedString addAttribute:NSLinkAttributeName value:aURL range:effectiveRange];
						}
					}
				}
			}
		}
		
		// check for wikilinks
		if ( checkForWikiLinks ) 
		{
			// wikilink checking uses the tokenizer
			NSString *string = [workingAttributedString string];
			CFRange range = CFRangeMake(0, [string length]);
			
			CFStringTokenizerRef tokenizer;
			CFStringTokenizerTokenType tokenType;
			CFLocaleRef locale = CFLocaleCopyCurrent();
			
			// create the tokenizer
			tokenizer = CFStringTokenizerCreate(NULL, (CFStringRef)string, range, kCFStringTokenizerUnitWord, locale);
			
			if ( tokenizer != NULL )
			{
				// advance through the tokens
				while ( ( tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer) ) != kCFStringTokenizerTokenNone )
				{
					// get the range of the current token
					CFRange tokenRange = CFStringTokenizerGetCurrentTokenRange(tokenizer);
					NSRange nsTokenRange = NSMakeRange(tokenRange.location, tokenRange.length);
					
					// get the corresponding word
					NSString *aWord = [string substringWithRange:nsTokenRange];
					//NSLog(aWord);
					
					// actually quite easy
					NSURL *entryURI = [self valueForKeyPath:[NSString stringWithFormat:@"journal.entryWikisDictionary.%@", aWord]];
					if ( entryURI != nil )
					{
						JournlerResource *aResource = [self resourceForJournlerObject:[[self journal] objectForURIRepresentation:entryURI]];
						if ( aResource != nil )
						{
							[workingAttributedString addAttribute:NSLinkAttributeName value:entryURI range:nsTokenRange];
						}
					}
				}
				
				CFRelease(tokenizer);
			}
			else
				NSLog(@"%s - unable to create string tokenizer, bypassing link processing", __PRETTY_FUNCTION__);
			
			CFRelease(locale);
		}
	}
	
	return workingAttributedString;
}

- (OSType) scriptLabel
{
	OSType scriptLabel = 'lcCE';
	
	switch ( [[self valueForKey:@"label"] intValue] )
	{
	case 0:
		scriptLabel = 'lcCE';
		break;
	case 1:
		scriptLabel = 'lcRE';
		break;
	case 2:
		scriptLabel = 'lcOR';
		break;
	case 3:
		scriptLabel = 'lcYE';
		break;
	case 4:
		scriptLabel = 'lcGN';
		break;
	case 5:
		scriptLabel = 'lcBL';
		break;
	case 6:
		scriptLabel = 'lcPU';
		break;
	case 7:
		scriptLabel = 'lcGY';
		break;
	default:
		scriptLabel = 'lcCE';
		break;
	}
	
	return scriptLabel;
}

- (void) setScriptLabel:(OSType)osType
{
	int label = 0;
	
	switch ( osType )
	{
	case 'lcCE':
		label = 0;
		break;
	case 'lcRE':
		label = 1;
		break;
	case 'lcOR':
		label = 2;
		break;
	case 'lcYE':
		label = 3;
		break;
	case 'lcGN':
		label = 4;
		break;
	case 'lcBL':
		label = 5;
		break;
	case 'lcPU':
		label = 6;
		break;
	case 'lcGY':
		label = 7;
		break;
	default:
		label = 0;
		break;

	}
	
	[self setValue:[NSNumber numberWithInt:label] forKey:@"label"];
}

- (OSType) scriptMark
{
	OSType scriptMark = 'emUM';
	
	switch ( [[self marked] intValue] )
	{
	case 0:
		scriptMark = 'emUM';
		break;
	case 1:
		scriptMark = 'emFL';
		break;
	case 2:
		scriptMark = 'emCH';
		break;
	
	default:
		scriptMark = 'emUM';
		break;
	}
	
	return scriptMark;
}

- (void) setScriptMark:(OSType)osType
{
	int mark = 0;
	
	switch ( osType )
	{
	case 'emUM':
		mark = 0;
		break;
	case 'emFL':
		mark = 1;
		break;
	case 'emCH':
		mark = 2;
		break;
	
	default:
		mark = 0;
		break;
	}
	
	[self setMarked:[NSNumber numberWithInt:mark]];
}

- (NSDate*) dateCreated
{
	return [self calDate];
}

- (void) setDateCreated:(NSDate*)aDate
{
	[self setCalDate:[aDate dateWithCalendarFormat:nil timeZone:nil]];
}

- (NSDate*) dateModified
{
	return [self calDateModified];
}

- (void) setDateModified:(NSDate*)aDate
{
	[self setCalDateModified:[aDate dateWithCalendarFormat:nil timeZone:nil]];
}

- (NSDate*) dateDue
{
	return [self calDateDue];
}

- (void) setDateDue:(NSDate*)aDate
{
	[self setCalDateDue:[aDate dateWithCalendarFormat:nil timeZone:nil]];
}

- (NSString*) htmlString
{
	// what about curly quotes?
	NSString *strippedHTML = nil;
	NSAttributedString *strippedContent = [[self attributedContent] attributedStringWithoutTextAttachments];
	
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"ExportsUseAdvancedHTMLGeneration"] )
		strippedHTML = [strippedContent
			attributedStringAsHTML:kUseSystemHTMLConversion|kUseInlineStyleDefinitions|kConvertSmartQuotesToRegularQuotes 
			documentAttributes:nil avoidStyleAttributes:[[NSUserDefaults standardUserDefaults] stringForKey:@"ExportsNoAttributeList"]];
	else
		strippedHTML = [strippedContent attributedStringAsHTML:kUseJournlerHTMLConversion|kConvertSmartQuotesToRegularQuotes documentAttributes:nil avoidStyleAttributes:nil];
	
	return strippedHTML;
}

- (JournlerResource*) scriptSelectedResource
{
	return [self selectedResource];
}

- (void) setScriptSelectedResource:(id)anObject
{
	if ( [anObject isKindOfClass:[NSArray class]] )
	{
		[self setSelectedResource:( [anObject count] > 0 ? [anObject objectAtIndex:0] : nil )];
	}
	else if ( [anObject isKindOfClass:[JournlerResource class]] )
	{
		[self setSelectedResource:anObject];
	}
}

- (NSString*) stringValue 
{
	// returns the rtfd content as a plain string
	return [self content];
}

- (void) setStringValue:(id)sv 
{	
	if ( [sv isKindOfClass:[NSString class]] )
		[self setAttributedContent:[[[NSAttributedString alloc] initWithString:sv attributes:[JournlerEntry defaultTextAttributes]] autorelease]]; 
	else if ( [sv isKindOfClass:[NSAttributedString class]] )
		[self setAttributedContent:sv];
}

- (NSString*) URIRepresentationAsString
{
	return [[self URIRepresentation] absoluteString];
}

- (NSString*) scriptWikiName
{
	return [self wikiTitle];
}

#pragma mark -
#pragma mark Handling References

- (int) indexOfObjectInJSReferences:(JournlerResource*)aReference
{
	return [[self valueForKey:@"resources"] indexOfObject:aReference];
}

- (unsigned int) countOfJSReferences
{ 
	return [[self valueForKey:@"resources"] count];
}

- (JournlerResource*) objectInJSReferencesAtIndex:(unsigned int)i
{
	if ( i >= [[self valueForKey:@"resources"] count] ) 
	{
		[self returnError:OSAIllegalIndex string:nil];
		return nil;
	}
	else
	{
		return [[self valueForKey:@"resources"] objectAtIndex:i];
	}
}

- (JournlerResource*) valueInJSReferencesWithUniqueID:(NSNumber*)idNum
{
	return [[self valueForKeyPath:@"journal.resourcesDictionary"] objectForKey:idNum];
}

#pragma mark -
#pragma mark Handling Folders

- (int) indexOfObjectInJSFolders:(JournlerCollection*)aFolder 
{
	return [[self valueForKey:@"collections"] indexOfObject:aFolder];
}

- (unsigned int) countOfJSFolders
{ 
	return [[self valueForKey:@"collections"] count];
}

- (JournlerCollection*) objectInJSFoldersAtIndex:(unsigned int)i 
{
	if ( i >= [[self valueForKey:@"collections"] count] ) 
	{
		[self returnError:OSAIllegalIndex string:nil];
		return nil;
	}
	else
	{
		return [[self valueForKey:@"collections"] objectAtIndex:i];
	}
}

- (JournlerCollection*) valueInJSFoldersWithUniqueID:(NSNumber*)idNum
{
	return [[self valueForKeyPath:@"journal.collectionsDictionary"] objectForKey:idNum];
}

#pragma mark -
#pragma mark Scripting Commands

- (void) jsTrash:(NSScriptCommand *)command 
{
	JournlerJournal *theJournal = [self journal];
	[theJournal markEntryForTrash:self];
}

- (void) jsExport:(NSScriptCommand *)command
{
	
	NSDictionary *args = [command evaluatedArguments];
	
	BOOL dir, includeHeader = YES;
	unsigned int fileType;
	OSType formatKeyCode = 'etRT';
	
	NSString *path;
	id pathURL = [args objectForKey:@"exportLocation"];
	id formatArg = [args objectForKey:@"exportFormat"];
	id headerArg = [args objectForKey:@"includeHeader"];
	
	if ( pathURL == nil || ![pathURL isKindOfClass:[NSURL class]] ) 
	{
		// raise an error
		NSLog(@"%s - nil path or path other than url, but path is required", __PRETTY_FUNCTION__);
		[self returnError:errOSACantAssign string:nil];
		return;
	}
	
	path = [pathURL path];
	if ( [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&dir] && dir )
		path = [[pathURL path] stringByAppendingPathComponent:[self pathSafeTitle]];
	
	// default to rtfd if no format is specified
	if ( formatArg != nil )
		formatKeyCode = (OSType)[formatArg unsignedIntValue];
	
	// include the headers? default is yes
	if ( headerArg != nil && [headerArg isKindOfClass:[NSNumber class]] )
		includeHeader = [headerArg boolValue];
	
	switch ( formatKeyCode )
	{
	case 'etRT': // rich text
		fileType = kEntrySaveAsRTF;
		break;
	case 'etRD': // rich text directory
		fileType = kEntrySaveAsRTFD;
		break;
	case 'etPD': // portable document format
		fileType = kEntrySaveAsPDF;
		break;
	case 'etDO': // word document
		fileType = kEntrySaveAsWord;
		break;
	case 'etTX': // plain text
		fileType = kEntrySaveAsText;
		break;
	case 'etXH': // xhtml
		fileType = kEntrySaveAsHTML;
		break;
	case 'etWA': // web archive
		fileType = kEntrySaveAsWebArchive;
		break;
	default:
		fileType = kEntrySaveAsRTF;
		break;
	}
	
	// write the file, error checking on the way
	int flags = (kEntrySetLabelColor|kEntrySetFileCreationDate|kEntrySetFileModificationDate);
	if ( includeHeader )
		flags |= kEntryIncludeHeader;
	
	if ( ![self writeToFile:path as:fileType flags:flags] )
	{
		NSLog(@"%s - unable to export entry to path %@ as type %i", __PRETTY_FUNCTION__, path, fileType);
		[self returnError:OSAParameterMismatch string:@"File path is not valid or an error occurred creating the file."];
	}
	
}

- (void) jsAddEntryToFolder:(NSScriptCommand *)command 
{

	NSDictionary *args = [command evaluatedArguments];
    
	id targetCollection = [args objectForKey:@"targetCollection"];
	
	if ( targetCollection == nil || ![targetCollection isKindOfClass:[JournlerCollection class]]) 
	{
		// raise an error
		[self returnError:errOSACantAssign string:nil];
		return;
	}

	// make sure the collection is a valid one
	if ( !( [(JournlerCollection*)targetCollection isRegularFolder] || ( [(JournlerCollection*)targetCollection isSmartFolder] && [(JournlerCollection*)targetCollection canAutotag:self] ) ) ) 
	{
		// raise an error
		[self returnError:errOSACantAssign string:nil];
		return;
	}
	
	// add the entry to the requested collection
	if ( [(JournlerCollection*)targetCollection isRegularFolder] )
		[(JournlerCollection*)targetCollection addEntry:self];
	
	else if ( [(JournlerCollection*)targetCollection isSmartFolder] && [(JournlerCollection*)targetCollection canAutotag:self] )
		[(JournlerCollection*)targetCollection autotagEntry:self add:YES];

}

- (void) jsRemoveEntryFromFolder:(NSScriptCommand *)command 
{
	
	NSDictionary *args = [command evaluatedArguments];
	id targetCollection = [args objectForKey:@"targetCollection"];
	
	if ( targetCollection == nil || ![targetCollection isKindOfClass:[JournlerCollection class]]) 
	{
		// raise an error
		[self returnError:errOSACantAssign string:nil];
		return;
	}

	// make sure the collection is a valid one
	if ( ![(JournlerCollection*)targetCollection isRegularFolder] ) 
	{
		// raise an error
		[self returnError:errOSACantAssign string:@"Collection must be of type \"21-Folder\""];
		return;
	}
	
	// remove the entry from the collection
	[(JournlerCollection*)targetCollection removeEntry:self];
}


@end
