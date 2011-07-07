//
//  JournlerResource.m
//  Journler
//
//  Created by Phil Dow on 10/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "JournlerResource.h"
#import "JournlerEntry.h"
#import "JournlerJournal.h"
#import "JournlerCollection.h"

#import "PDSingletons.h"
#import "NSURL+JournlerAdditions.h"

#import <SproutedUtilities/SproutedUtilities.h>

static NSString *ResourceTagIDKey = @"ResourceTagIDKey";
static NSString *ResourceTypeKey = @"ResourceTypeKey";
static NSString *ResourceIconKey = @"ResourceIconKey";
static NSString *ResourceSearchesKey = @"ResourceSearchesKey";
static NSString *ResourceTitleKey = @"ResourceTitleKey";
static NSString *ResourceUTIKey = @"ResourceUTIKey";
static NSString *ResourceConformingUTIsKey = @"ResourceConformingUTIsKey";
static NSString *ResourceTextRepresentationKey = @"ResourceTextRepresentationKey";

static NSString *ResourceLabelKey = @"ResourceLabelKey";
static NSString *ResourceIsGlobalKey = @"ResourceIsGlobalKey";
static NSString *ResourceUnderlyingModificationDateKey = @"ResourceUnderlyingModificationDateKey";

static NSString *ResourceFilenameKey = @"ResourceFilenameKey";
static NSString *ResourceRelativePathKey = @"ResourceRelativePathKey";
static NSString *ResourceURLStringKey = @"ResourceURLStringKey";
static NSString *ResourceABIDKey = @"ResourceABIDKey";
static NSString *ResourceJournlerObjectURIKey = @"ResourceJournlerObjectURIKey";

static NSImage* AliasBadge()
{
	static NSImage* aliasIcon = nil;
	if ( aliasIcon == nil )
	{
		aliasIcon = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AliasBadgeIcon.icns"];
		[aliasIcon setSize:NSMakeSize(128,128)];
	}
	return aliasIcon;
}

static NSImage* QuestionMarkBadge()
{
	static NSImage* qmIcon = nil;
	if ( qmIcon == nil )
	{
		qmIcon = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericQuestionMarkIcon.icns"];
		[qmIcon setSize:NSMakeSize(128,128)];
	}
	return qmIcon;
}

static NSImage* BlankDocumentIcon()
{
	static NSImage* docIcon = nil;
	if ( docIcon == nil )
	{
		docIcon = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericDocumentIcon.icns"];
		[docIcon setSize:NSMakeSize(128,128)];
	}
	return docIcon;
}

static NSImage* AlertBadge()
{
	static NSImage* alertBadge = nil;
	if ( alertBadge == nil )
	{
		alertBadge = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertCautionBadgeIcon.icns"];
		[alertBadge setSize:NSMakeSize(128,128)];
	}
	return alertBadge;
}

@implementation JournlerResource

- (id) init
{
	return [self initWithProperties:nil];
}

- (id) initWithProperties:(NSDictionary*)aDictionary
{
	if ( self = [super initWithProperties:aDictionary] )
	{
		// the initial relatinoships
		entry = nil;
		entries = [[NSArray alloc] init];
		
		// initialize search relevance
		relevance = 0.0;
		_previewRetainCount = 0;
		
		if ( [[self uti] isEqualToString:ResourceURLUTI] )
			[self setUti:(NSString*)kUTTypeURL];
	}
	
	return self;
}

+ (NSDictionary*) defaultProperties
{
	BOOL searchesByDefault = [[NSUserDefaults standardUserDefaults] boolForKey:@"SearchMediaByDefault"];
	
	NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInt:0], ResourceTagIDKey,
			[NSNumber numberWithBool:searchesByDefault], ResourceSearchesKey,
			[NSNumber numberWithBool:NO], ResourceIsGlobalKey, nil];
	
	return defaults;
}

- (void) dealloc
{
	[entry release], entry = nil;
	[entries release], entries = nil;
	
	[entryIDs release], entryIDs = nil;
	[owningEntryID release], owningEntryID = nil;
	
	[scriptAliased release], scriptAliased = nil;
	
	[super dealloc];
}

#pragma mark -

- (id)copyWithZone:(NSZone *)zone 
{
	JournlerResource *newObject = [[[self class] allocWithZone:zone] init];
	
	[newObject setProperties:[self properties]];
	[newObject setType:[self type]];
	[newObject setJournal:[self journal]];
	[newObject setEntry:[self entry]];
	[newObject setDirty:[self dirty]];
	[newObject setDeleted:[self deleted]];
	
	// tag and journal
	[newObject setTagID:[NSNumber numberWithInt:[[self journal] newResourceTag]]];
	[[self journal] addResource:newObject];
		
	return newObject;
}

- (id)initWithCoder:(NSCoder *)decoder 
{	
	if ( self = [self initWithProperties:nil] )
	{
		NSDictionary *archivedProperties = [decoder decodeObjectForKey:@"ResourceProperties"];
		NSNumber *theOwningEntryID = [decoder decodeObjectForKey:@"EntryID"];
		NSArray *theEntryIDs = [decoder decodeObjectForKey:@"AllEntryIDs"];
				
		if ( archivedProperties == nil) 
			return nil;
		
		[_properties addEntriesFromDictionary:archivedProperties];
		
		if ( [[self uti] isEqualToString:ResourceURLUTI] )
			[self setUti:(NSString*)kUTTypeURL];
		
		[self setEntryIDs:theEntryIDs];
		[self setOwningEntryID:theOwningEntryID];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder 
{
	if ( ![encoder allowsKeyedCoding] ) 
	{
		NSLog(@"%s - cannot encode Resource without a keyed archiver", __PRETTY_FUNCTION__);
		return;
	}
	
	NSNumber *journalID;
	NSNumber *entryID;
	NSArray *entriesIDs;
	
	// remove the icon from the properties - it is not stored
	NSMutableDictionary *theProperties = [[[self valueForKey:@"properties"] mutableCopyWithZone:[self zone]] autorelease];
	
	//if ( [self type] != kResourceTypeFile  )
	[theProperties removeObjectForKey:ResourceIconKey];
	
	// convert the journal to an identifier
	journalID = [[self journal] identifier];
	
	// convert the owning entry to an identifier
	entryID = [[self entry] tagID];
	
	// conver all of the associated entries to their identifiers
	entriesIDs = [[self entries] valueForKey:@"tagID"];
	
	// encode our properties and relationships
	[encoder encodeObject:theProperties forKey:@"ResourceProperties"];
	
	// the next three aren't actually used
	[encoder encodeObject:journalID forKey:@"JournalID"];
	[encoder encodeObject:entryID forKey:@"EntryID"];
	[encoder encodeObject:entriesIDs forKey:@"AllEntryIDs"];
	
	//#warning how to handle the journal and entry id?
}

#pragma mark -

+ (NSArray*) definedUTIs
{
	NSArray *definedUTIs = [NSArray arrayWithObjects:
			ResourceUnknownUTI, ResourceABPersonUTI, 
			ResourceJournlerObjectURIUTI, ResourceSnapshotUTI, 
			ResourceAudioRecordingUTI, ResourceVideoRecordingUTI, nil];
	
	return definedUTIs;
}

#pragma mark -

- (unsigned) hash 
{	
	// return the tag id, guaranteed to be unique
	return [[self tagID] unsignedIntValue];
}

- (BOOL)isEqual:(id)anObject 
{	
	if ( ![anObject isMemberOfClass:[self class]] )
		return NO;
	
	// tests for the class and then the int tag id
	if ( [[self tagID] intValue] == -1 ) // -1 for on the fly resource generation
		return ( [[self URIRepresentation] isEqual:[anObject URIRepresentation]] );
	
	else if ( [[self tagID] intValue] < 0 ) // < 0 for on the fly resource generation
		return ( [[self URIRepresentation] isEqual:[anObject URIRepresentation]] );
	
	else
		return ( [[self tagID] intValue] == [[anObject tagID] intValue] );
}

- (BOOL) isEqualToResource:(JournlerResource*)aResource
{
	if ( ![aResource isMemberOfClass:[self class]] )
		return NO;
	
	// obviously if the addresses are the same the objects are the same
	if ( self == aResource )
		return YES;
	
	// tests for the class and then the int tag id
	else if ( [[self tagID] intValue] == -1 ) // -1 for on the fly resource generation
		return ( [[self URIRepresentation] isEqual:[aResource URIRepresentation]] );
	
	// equality depends on object type - could have unintended consequences
	else if ( [self representsURL] && [aResource representsURL]  )
		return ( [[self urlString] isEqualToString:[aResource urlString]] );
		
	else if ( [self representsABRecord] && [aResource representsABRecord])
		return ( [[self uniqueId] isEqualToString:[aResource uniqueId]] );
		
	else if ( [self representsJournlerObject] && [aResource representsJournlerObject] )
		return ( [self journlerObject] == [aResource journlerObject] );
		
	else if ( [self representsFile] && [aResource representsFile] )
		return ( [[self originalPath] isEqual:[aResource originalPath]] || ( [self originalPath] == nil && [aResource originalPath] == nil ) );
		
	else
		return ( [aResource isMemberOfClass:[self class]] && [[self tagID] intValue] == [[aResource tagID] intValue] );
}

#pragma mark -

- (JournlerEntry*) entry
{
	return entry;
}

- (void) setEntry:(JournlerEntry*)anEntry
{
	if ( entry != anEntry )
	{
		[entry release];
		entry = [anEntry retain];
		// retain the one-one attribute
		
		[self setValue:BooleanNumber(YES) forKey:@"dirty"];
		
		// make sure this entry is part of our entries array
		if ( ![[self entries] containsObject:anEntry] )
		{
			NSMutableArray *theEntries = [[[self entries] mutableCopyWithZone:[self zone]] autorelease];
			[theEntries addObject:anEntry];
			[self setEntries:theEntries];
		}
	}
}

- (NSArray*) entries
{
	return entries;
}

- (void) setEntries:(NSArray*)anArray
{
	if ( entries != anArray )
	{
		[entries release];
		entries = [anArray copyWithZone:[self zone]];
		
		[self setValue:BooleanNumber(YES) forKey:@"dirty"];
	}
}

#pragma mark -

- (NSArray *) entryIDs
{
	return entryIDs;
}

- (void) setEntryIDs:(NSArray*)anArray
{
	if ( entryIDs != anArray )
	{
		[entryIDs release];
		entryIDs = [anArray copyWithZone:[self zone]];
	}
}

- (NSNumber *) owningEntryID
{
	return owningEntryID;
}

- (void) setOwningEntryID:(NSNumber*)aNumber
{
	if ( owningEntryID != aNumber )
	{
		[owningEntryID release];
		owningEntryID = [aNumber copyWithZone:[self zone]];
	}
}

#pragma mark -

+ (NSString*) tagIDKey
{
	return ResourceTagIDKey;
}

+ (NSString*) titleKey
{
	return ResourceTitleKey;
}

+ (NSString*) iconKey
{
	return ResourceIconKey;
}

#pragma mark -

- (JournlerResourceType) type
{
	return [[_properties valueForKey:ResourceTypeKey] intValue];
}

- (void) setType:(JournlerResourceType)aResourceType
{
	[_properties setValue:[NSNumber numberWithInt:aResourceType] forKey:ResourceTypeKey];	
	[self setValue:BooleanNumber(YES) forKey:@"dirty"];
}

- (NSImage*) icon
{
	// override to support the lazy loading of images
	NSImage *icon = [super icon];
	if ( icon == nil )
	{
		// icons are loaded lazily
		[self loadIcon];
		icon = [_properties objectForKey:ResourceIconKey];
	}
	
	_lastPreviewAccess = [NSDate timeIntervalSinceReferenceDate];
	return icon;
}

- (void) setIcon:(NSImage*)anImage
{
	// override to note the access time and unmark dirty
	[super setIcon:anImage];
	[self setValue:BooleanNumber(NO) forKey:@"dirty"];
	
	_lastPreviewAccess = [NSDate timeIntervalSinceReferenceDate];
	
	// no dirty to prevent an unneeded indexing from taking place
	// and because the icon is not stored with the metadata
	// caching immediately writes it to disk
}

#pragma mark -

- (NSNumber*) searches
{
	return [_properties valueForKey:ResourceSearchesKey];
}

- (void) setSearches:(NSNumber*)search
{
	[_properties setValue:( search ? search : [NSNumber numberWithBool:NO] ) forKey:ResourceSearchesKey];
	[self setValue:BooleanNumber(YES) forKey:@"dirty"];
}

- (NSNumber*) label 
{ 
	NSNumber *theLabel = [_properties objectForKey:ResourceLabelKey];
	if ( theLabel == nil ) theLabel = ZeroNumber();
	return theLabel;
}

- (void) setLabel:(NSNumber*)aNumber
{
	[_properties setValue:( aNumber ? aNumber : [NSNumber numberWithInt:0] ) forKey:ResourceLabelKey];	
	[self setValue:BooleanNumber(YES) forKey:@"dirty"];
	
	// post a notification that this attribute has changed
	[[NSNotificationCenter defaultCenter] postNotificationName:JournlerObjectDidChangeValueForKeyNotification 
			object:self 
			userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
					JournlerObjectAttributeLabelKey, JournlerObjectAttributeKey, nil]];
}

- (NSString*) uti
{
	return [_properties valueForKey:ResourceUTIKey];
}

- (void) setUti:(NSString*)aString
{
	[_properties setValue:( aString ? aString : ResourceUnknownUTI ) forKey:ResourceUTIKey];
	[self setValue:BooleanNumber(YES) forKey:@"dirty"];
	
	// anytime the uti changes, update the parents with utis
	if ( aString != nil && ![[JournlerResource definedUTIs] containsObject:aString] )
		[self setUtisConforming:[[NSWorkspace sharedWorkspace] allParentsAsArrayForUTI:aString]];
	else if ( aString == nil )
		[_properties setValue:[NSArray array] forKey:ResourceConformingUTIsKey];
	
	// invalide the utis on the owning entries
	[[self entries] makeObjectsPerformSelector:@selector(invalidateResourceTypes)];
}

- (NSArray*) utisConforming
{
	return [_properties valueForKey:ResourceConformingUTIsKey];
}

- (void) setUtisConforming:(NSArray*)anArray
{
	[_properties setValue:( anArray ? anArray : [NSArray array] ) forKey:ResourceConformingUTIsKey];
	[self setValue:BooleanNumber(YES) forKey:@"dirty"];
}

- (NSNumber*) globalResource
{
	return [_properties valueForKey:ResourceIsGlobalKey];
}

- (void) setGlobalResource:(NSNumber*)global
{
	[_properties setValue:( global ? global : [NSNumber numberWithBool:NO] ) forKey:ResourceIsGlobalKey];
	[self setValue:BooleanNumber(YES) forKey:@"dirty"];
}

- (NSString*) textRepresentation
{
	return [_properties valueForKey:ResourceTextRepresentationKey];
}

- (void) setTextRepresentation:(NSString*)aString
{
	if ( aString == nil ) [_properties removeObjectForKey:ResourceTextRepresentationKey];
	else [_properties setValue:aString forKey:ResourceTextRepresentationKey];
	
	[self setValue:BooleanNumber(YES) forKey:@"dirty"];
}

- (NSDate*) underlyingModificationDate
{
	return [_properties objectForKey:ResourceUnderlyingModificationDateKey];
}

- (void) setUnderlyingModificationDate:(NSDate*)aDate
{
	if ( aDate == nil ) [_properties removeObjectForKey:ResourceUnderlyingModificationDateKey];
	else [_properties setObject:aDate forKey:ResourceUnderlyingModificationDateKey];
	
	[self setValue:BooleanNumber(YES) forKey:@"dirty"];
}

#pragma mark -

- (float) relevance
{
	return relevance;
}

- (void) setRelevance:(float)aValue
{
	relevance = aValue;
}

#pragma mark -

- (BOOL) representsFile
{
	return ( [self type] == kResourceTypeFile );
}

- (BOOL) representsURL
{
	return ( [self type] == kResourceTypeURL );
}

- (BOOL) representsABRecord
{
	return ( [self type] == kResourceTypeABRecord );
}

- (BOOL) representsJournlerObject
{
	return ( [self type] == kResourceTypeJournlerObject );
}

#pragma mark -

- (NSURL*) URIRepresentation
{	
	NSString *urlString = [NSString stringWithFormat:@"journler://reference/%@", [self valueForKey:@"tagID"]];
	if ( urlString == nil )
	{
		NSLog(@"%s - unable to create string representation of resource #%@", __PRETTY_FUNCTION__, [self valueForKey:@"tagID"]);
		return nil;
	}
	
	NSURL *url = [NSURL URLWithString:urlString];
	if ( url == nil )
	{
		NSLog(@"%s - unable to create url representation of resource #%@", __PRETTY_FUNCTION__, [self valueForKey:@"tagID"]);
		return nil;
	}
	
	return url;
}

- (NSString*) _pathForFileThumbnail
{
	// prefer the png path, but go with the tif path as well
	NSString *path = [[self path] stringByAppendingString:@"_t.png"];
	if ( ![[NSFileManager defaultManager] fileExistsAtPath:path] )
		path = [[self path] stringByAppendingString:@"_t.tif"];
	
	return path;
}

- (NSImage*) _iconForFileResource
{
	NSImage *icon = nil;
	NSString *thumbnailPath = [self _pathForFileThumbnail];
		
	// first check to see if the file exists, if not -- question mark document
	if ( ![[NSFileManager defaultManager] fileExistsAtPath:[self path]] )
	{
		icon = BlankDocumentIcon();
		[icon lockFocus];
		
		[QuestionMarkBadge() drawInRect:NSMakeRect(16,16,96,96) 
				fromRect:NSMakeRect(0,0,[QuestionMarkBadge() size].width, [QuestionMarkBadge() size].height) 
				operation:NSCompositeSourceOver 
				fraction:1.0];
				
		[icon unlockFocus];
		
		return icon;
	}
	
	// next check to see if a thumbnail version of the file exists
	else if ( [[NSFileManager defaultManager] fileExistsAtPath:thumbnailPath] 
			&& ( (icon = [[[NSImage alloc] initWithContentsOfFile:thumbnailPath] autorelease]) != nil ) )
	{
		return icon;
	}
	
	// finally, the icon must be generated
	else
	{
		// pdf icons are generated from the first page of the pdf document
		if ( UTTypeConformsTo((CFStringRef)[self uti],(CFStringRef)kUTTypePDF) )
		{
			// this takes a *really* long time
			
			/*
			PDFDocument *pdfDoc = [[[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:[self originalPath]]] autorelease];
			if ( pdfDoc == nil || [pdfDoc pageCount] == 0 )
				goto bail;
				
			icon = [pdfDoc thumbnailForPage:0 size:128];
			
			if ( ![[self path] isEqualToString:[self originalPath]] )
			{
				[icon lockFocus];
				
				[AliasBadge() drawInRect:NSMakeRect(0,0,128,128) 
						fromRect:NSMakeRect(0,0,[AliasBadge() size].width, [AliasBadge() size].height) 
						operation:NSCompositeSourceOver 
						fraction:1.0];
						
				[icon unlockFocus];
			}
			*/
		}
		
		// images use a preview
		else if ( [NSImage canInitWithFile:[self originalPath]] )
		{
			icon = [NSImage iconWithContentsOfFile:[self originalPath] edgeSize:128 inset:9];
			if ( icon != nil && ![[self path] isEqualToString:[self originalPath]] )
			{
				[icon lockFocus];
				
				[AliasBadge() drawInRect:NSMakeRect(0,0,128,128) 
						fromRect:NSMakeRect(0,0,[AliasBadge() size].width, [AliasBadge() size].height) 
						operation:NSCompositeSourceOver 
						fraction:1.0];
						
				[icon unlockFocus];
			}
		}
	
	}
	
bail:
	
	// if the icon is still new, ask the workspace for the file's icon
	if ( icon == nil )
	{
		icon = [[NSWorkspace sharedWorkspace] iconForFile:[self path]];
		[icon setSize:NSMakeSize(128,128)];
	}
	
	// if the original path is nil, the resources represents an alias that no longer points to anything - caution badge
	if ( [self originalPath] == nil )
	{
		NSImage *newImage = [[[NSImage alloc] initWithSize:NSMakeSize(128,128)] autorelease];
		
		[newImage lockFocus];
		
		[icon drawInRect:NSMakeRect(0,0,128,128) 
				fromRect:NSMakeRect(0,0,[icon size].width,[icon size].height) 
				operation:NSCompositeSourceOver 
				fraction:1.0];
				
		[AlertBadge() drawInRect:NSMakeRect(0,0,128,128) 
				fromRect:NSMakeRect(0,0,[AlertBadge() size].width, [AlertBadge() size].height) 
				operation:NSCompositeSourceOver 
				fraction:1.0];
				
		[newImage unlockFocus];
		
		icon = newImage;
	}
	
	// #warning properly invalidate the thumb whenever necessary -- difficult, added option to reload thumb
	// write the icon to the thumb file
	NSError *error = nil;
	//if ( ![[icon TIFFRepresentation] writeToFile:[[self path] stringByAppendingString:@"_t.tif"] options:0 error:nil] )
	if ( ![[icon pngData] writeToFile:[[self path] stringByAppendingString:@"_t.png"] options:0 error:&error] )
		NSLog(@"%s - unable to write resource thumbnail to %@, error: %@", __PRETTY_FUNCTION__, [[self path] stringByAppendingString:@"_t.png"], error);
	
	return icon;
	
}

- (void) loadIcon
{
	NSImage *icon = nil;
	
	switch ( [self type] )
	{
	case kResourceTypeURL:
		icon = [NSImage imageNamed:@"safari.tif"];
		break;
	
	case kResourceTypeABRecord:
		icon = [[self person] image];
		if ( icon == nil ) icon = [[[NSImage imageNamed:@"vCard.tiff"] copyWithZone:[self zone]] autorelease];
		//if ( icon == nil ) icon = [NSImage imageNamed:@"vCard.tiff"];
		else icon = [icon imageWithWidth:128 height:128 inset:9];
		break;
	
	case kResourceTypeFile:
		
		icon = [self _iconForFileResource];
		break;
	
	case kResourceTypeJournlerObject:
		
		if ( [[NSURL URLWithString:[self valueForKey:@"uriString"]] isJournlerEntry] )
		{
			icon = [[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Entry" ofType:@"icns"]] autorelease];
			[icon setSize:NSMakeSize(128,128)];
		}
		else if ( [[NSURL URLWithString:[self valueForKey:@"uriString"]] isJournlerFolder] )
		{
			icon = [[[self valueForKey:@"journal"] objectForURIRepresentation:
					[NSURL URLWithString:[self valueForKey:@"uriString"]]] valueForKey:@"icon"];
		}
		break;
	}
	
	// set the icon directly in the dictionary not to dirty the object
	[_properties setValue:icon forKey:ResourceIconKey];
	_lastPreviewAccess = [NSDate timeIntervalSinceReferenceDate];
}

- (void) reloadIcon
{
	// delete the thumbnail
	NSString *thumbnailPath = [self _pathForFileThumbnail];
	if ( [[NSFileManager defaultManager] fileExistsAtPath:thumbnailPath] && ![[NSFileManager defaultManager] removeFileAtPath:thumbnailPath handler:self] )
		NSLog(@"%s - unable to remove thumbnail at path %@", __PRETTY_FUNCTION__, thumbnailPath);
	
	// reload the icon
	[self loadIcon];
}

- (void) cacheIconToDisk
{
	NSImage *theIcon = [self icon];
	
	if ( theIcon == nil )
		return;
	
	//else if ( ![[theIcon TIFFRepresentation] writeToFile:[[self path] stringByAppendingString:@"_t.tif"] options:0 error:nil] )
	//	NSLog(@"%s - unable to write resource thumbnail to %@", __PRETTY_FUNCTION__, [[self path] stringByAppendingString:@"_t.tif"]);
	
	NSError *error = nil;
	if ( ![[theIcon pngData] writeToFile:[[self path] stringByAppendingString:@"_t.png"] options:0 error:&error] )
		NSLog(@"%s - unable to write resource thumbnail to %@, error: %@", __PRETTY_FUNCTION__, [[self path] stringByAppendingString:@"_t.png"], error);
}

- (void) addMissingFileBadge
{
	NSImage *theIcon = [self icon];
	
	[theIcon lockFocus];
	
	[AlertBadge() drawInRect:NSMakeRect(0,0,128,128) 
			fromRect:NSMakeRect(0,0,[AlertBadge() size].width, [AlertBadge() size].height) 
			operation:NSCompositeSourceOver 
			fraction:1.0];
	
	[theIcon unlockFocus];
	
	[self setIcon:theIcon];
}

- (void) _deriveTextRepresentation:(NSString*)filename
{
	// the point of this method was to derive the plain text representation myself
	// for files that the search manager had trouble with
	// but I'm not otherwise currently using this file, and that text could potentially
	// take up a huge amount of space in the database
	
	[self setTextRepresentation:nil];
	
	/*
	if ( ![self representsFile] ) return;
	
	NSString *textRepresentation = nil;
	NSString *originalFilename = [[filename copyWithZone:[self zone]] autorelease];
	
	// if nil is passed, try our own original path
	if ( filename == nil )
		filename = [self originalPath];
	// otherwise resolve the filename for aliases
	else
		filename = [[NSWorkspace sharedWorkspace] resolveForAliases:filename];
	
	if ( filename == nil )
	{
		// bail if we're still nil
		NSLog(@"%s - unable to derive original path from alias %@, resource %@", __PRETTY_FUNCTION__, originalFilename, [self tagID]);
	}
	else
	{
		
	}
	
	// depending on the file type, derive some string goodness
	if ( UTTypeConformsTo((CFStringRef)[self uti],(CFStringRef)ResourceMailUTI) )
	{
		MailMessageParser *mailParser = [[[MailMessageParser alloc] initWithFile:filename] autorelease];
		if ( mailParser == nil )
		{
			NSLog(@"%s - unable to load mail message parser for mail message at path %@", __PRETTY_FUNCTION__, filename);
			return;
		}
		
		NSString *plainContent = nil;
		NSString *sender = [[[mailParser message] from] stringValue];
		
		if ( [mailParser hasHTMLBody] )
		{
			// convert to plain text
			NSString *htmlContent = [mailParser body:YES];
			
			@try
			{
				NSData *htmlData = [htmlContent dataUsingEncoding:NSUnicodeStringEncoding];
				NSAttributedString *attributedHTML = [[[NSAttributedString alloc] initWithHTML:htmlData documentAttributes:nil] autorelease];
				if ( attributedHTML == nil ) 
				{	
					NSLog(@"%s - unable to convert mail message to attributed string %@", __PRETTY_FUNCTION__, filename);
					return;
				}
				
				plainContent = [attributedHTML string];
			}
			@catch (NSException *localException)
			{
				NSLog(@"%s - exception encountered while parsing mail message, file: %@, exception: %@",
				 __PRETTY_FUNCTION__, filename, [localException description]);
				return;
			}
			@catch (id undefinedException)
			{
				NSLog(@"%s - undefined exception encountered while parsing mail message, file: %@, exception: %@",
				 __PRETTY_FUNCTION__, filename, [undefinedException description]);
				return;
			}
			@finally
			{
			
			}
		}
		else if ( [mailParser hasPlainTextBody] )
		{
			plainContent = [mailParser body:NO];
		}
		
		// build the searchable string
		if ( plainContent == nil )
		{
			NSLog(@"%s - unable to derive plain content for mail message at path %@", __PRETTY_FUNCTION__, filename);
			return;
		}
		
		
		if ( sender != nil )
			textRepresentation = [NSString stringWithFormat:@"%@ %@", sender, plainContent];
		else
			textRepresentation = plainContent;
	}
	
	else if ( UTTypeConformsTo((CFStringRef)[self uti], kUTTypeWebArchive) )
	{
		@try
		{
			NSData *data = [NSData dataWithContentsOfFile:filename];
			if ( data != nil )
			{
				WebArchive *archive = [[[WebArchive alloc] initWithData:data] autorelease];
				if ( archive != nil )
					textRepresentation = [PDWebArchiveMiner plaintextRepresentationForWebArchive:archive];
			}
		}
		@catch (NSException *localException)
		{
			NSLog(@"%s - exception encountered while parsing mail message, file: %@, exception: %@",
			 __PRETTY_FUNCTION__, filename, [localException description]);
			return;
		}
		@catch (id undefinedException)
		{
			NSLog(@"%s - undefined exception encountered while parsing mail message, file: %@, exception: %@",
			 __PRETTY_FUNCTION__, filename, [undefinedException description]);
			return;
		}
		@finally
		{
		
		}
	}
	
	#ifdef __DEBUG__
	NSLog(@"%s - textRepresentation: %@", __PRETTY_FUNCTION__, textRepresentation);
	#endif
	
	// set the textRepresentation
	if ( textRepresentation != nil )
		[self setTextRepresentation:textRepresentation];
	*/
	
}

#pragma mark -

- (NSString*) htmlRepresentationWithCache:(NSString*)cachePath
{
	// generates an html representation of the receiver
	if ( [self representsABRecord] ) 
		return [[self person] htmlRepresentationWithCache:cachePath];
	else if ( [self representsJournlerObject] )
		return [[self journlerObject] htmlRepresentationWithCache:cachePath];
	else if ( [self representsURL] )
		return [self htmlRepresentationForURLWithCache:cachePath];
	else
		return [NSString string];
}

- (NSString*) allUTIs
{
	NSString *allUTIs = nil;
	
	if ( [self representsFile] )
	{
		NSString *allParentUTIs = [[NSWorkspace sharedWorkspace] allParentsForUTI:[self uti]];
		if ( allParentUTIs == nil )
			allUTIs = [self uti];
		else
			allUTIs = [NSString stringWithFormat:@"%@,%@",[self uti],allParentUTIs];
	}
	else
	{
		allUTIs = [self uti];
	}
	
	return allUTIs;
}

- (NSArray*) allUTIsArray
{
	NSMutableArray *allUTIsArray = [NSMutableArray arrayWithArray:[self utisConforming]];
	[allUTIsArray addObject:[self uti]];
	return allUTIsArray;
}

- (NSString*) createFileAtDestination:(NSString*)path 
{	
	// path should be a directory which will contain the newly created file
	// returns the actual path of the written file or nil if the file could not be written
	
	NSString *actualPath = nil;
	
	if ( [self representsFile] ) 
	{
		NSString *original = [self originalPath];
		NSString *filename = [original lastPathComponent];
		NSString *destination = [[path stringByAppendingPathComponent:filename] pathWithoutOverwritingSelf];
		
		if ( filename == nil || destination == nil )
		{
			NSLog(@"%s - unable to prepare paths for copy, source: %@, destination: %@", __PRETTY_FUNCTION__, original, destination);
			actualPath = nil;
		}
		else
		{
			if ( [[NSFileManager defaultManager] copyPath:original toPath:destination handler:self] )
				actualPath = destination;
			else
				actualPath = nil;
		}
	}
	
	else if ( [self representsABRecord] ) 
	{
		NSString *uniqueID = [self valueForKey:@"uniqueId"];
		ABPerson *person = (ABPerson*)[[ABAddressBook sharedAddressBook] recordForUniqueId:uniqueID];
		if ( person == nil ) 
		{
			NSLog(@"%s - unable to derive person from id %@", __PRETTY_FUNCTION__, uniqueID);
		}
		else 
		{
			NSData *data = [person vCardRepresentation];
			if ( data == nil ) 
			{
				NSLog(@"%s - unable to derive data from person %@", __PRETTY_FUNCTION__, [person description]);
			}
			else 
			{
				static NSString *vCardExtension = @"vcf";
				NSString *destination = [[path stringByAppendingPathComponent:
						[NSString stringWithFormat:@"%@.%@", [[person fullname] pathSafeString], vCardExtension]] pathWithoutOverwritingSelf];
				
				if ( [data writeToFile:destination options:NSAtomicWrite error:nil] )
					actualPath = destination;
			}
		}
	}
	
	else if ( [self representsURL] ) 
	{
		NSString *filename = [[self valueForKey:@"title"] pathSafeString];
		NSString *destination = [[path stringByAppendingPathComponent:filename] pathWithoutOverwritingSelf];
		PDWeblocFile *weblocFile = [PDWeblocFile weblocWithURL:[NSURL URLWithString:[self valueForKey:@"urlString"]]];
		
		if ( [weblocFile writeToFile:destination] )
			actualPath = destination;
	}
	
	else if ( [self representsJournlerObject] )
	{
		id anObject = [[self journal] objectForURIRepresentation:[NSURL URLWithString:[self uriString]]];
		if ( [anObject isKindOfClass:[JournlerEntry class]] )
		{
			NSString *destination = [[path stringByAppendingPathComponent:
					[(JournlerEntry*)anObject pathSafeTitle]] pathWithoutOverwritingSelf];
			
			int flags = kEntrySetLabelColor;
			if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryExportIncludeHeader"] )
				flags |= kEntryIncludeHeader;
			if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryExportSetCreationDate"] )
				flags |= kEntrySetFileCreationDate;
			if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryExportSetModificationDate"] )
				flags |= kEntrySetFileModificationDate;
			
			if ( [(JournlerEntry*)anObject writeToFile:destination as:kEntrySaveAsRTFD flags:flags] )
				actualPath = destination;
		}
		else if ( [anObject isKindOfClass:[JournlerCollection class]] )
		{
			if ( [(JournlerCollection*)anObject writeEntriesToFolder:path format:kEntrySaveAsRTFD considerChildren:YES includeHeaders:YES] )
				actualPath = path;
		}
	}
	
	return actualPath;
}

#pragma mark -

- (void) revealInFinder
{
	if ( [self representsFile] )
	{
		NSString *path = [self originalPath];	
		if ( [self originalPath] == nil )
			path = [self path];
		
		// folders should be opened, everything else revealed
		//NSString *uti = [[NSWorkspace sharedWorkspace] UTIForFile:path];
		
		//if ( UTTypeConformsTo((CFStringRef)uti, kUTTypeFolder) )
		//	[[NSWorkspace sharedWorkspace] openFile:path];
		//else
			[[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:[path stringByDeletingLastPathComponent]];
	}
	else if ( [self representsJournlerObject] )
	{
		NSString *aPath = nil;
		JournlerObject *theObject = [self journlerObject];
		
		if ( [theObject isKindOfClass:[JournlerEntry class]] )
			aPath = [(JournlerEntry*)theObject packagePath];
		
		else if ( [theObject isKindOfClass:[JournlerCollection class]] )
			aPath = [(JournlerCollection*)theObject packagePath];
		
		if ( aPath != nil && [[NSFileManager defaultManager] fileExistsAtPath:aPath] )
			[[NSWorkspace sharedWorkspace] selectFile:aPath inFileViewerRootedAtPath:[aPath stringByDeletingLastPathComponent]];
		else
			[self openWithFinder];
	}
	else
	{
		[self openWithFinder];
	}
}

- (void) openWithFinder
{
	if ( [self representsFile] )
	{
		NSString *path = [self originalPath];	
		if ( path == nil )
			path = [self path];
		[[NSWorkspace sharedWorkspace] openFile:path];
	}
	else if ( [self representsURL] )
	{
		NSURL *url = [NSURL URLWithString:[self urlString]];
		[[NSWorkspace sharedWorkspace] openURL:url];
	}
	else if ( [self representsABRecord] )
	{
		ABRecord *person = [self person];
		ABPeoplePickerView *peoplePicker = [[[ABPeoplePickerView alloc] initWithFrame:NSMakeRect(0,0,100,100)] autorelease];
		[peoplePicker selectRecord:person byExtendingSelection:NO];
		[peoplePicker selectInAddressBook:self];
	}
	else if ( [self representsJournlerObject] )
	{
		// simulate a url event
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[self uriString]]];
	}
}

#pragma mark -

// increments the retain count on the attributed content
- (void) retainPreview
{
	_previewRetainCount++;
}

- (void) releasePreview
{
	_previewRetainCount--;
}

- (int) previewRetainCount
{
	return _previewRetainCount;
}

- (NSTimeInterval) lastPreviewAccess
{
	return _lastPreviewAccess;
}

- (void) unloadPreview
{
	// unload my icon from memory without marking for dirty
	[_properties removeObjectForKey:ResourceIconKey];
}

- (NSImage*) previewIfLoaded
{
	// returns the icon without actually loading it
	return [_properties objectForKey:ResourceIconKey];
}

#pragma mark -

- (void) perform253Maintenance
{
	// remove unused labels
	if ( [[_properties objectForKey:ResourceLabelKey] intValue] == 0 )
		[_properties removeObjectForKey:ResourceLabelKey];
	
	// note the date modified and relative path of the underlying data
	if ( [self representsFile] )
	{
		NSString *path = [self originalPath];
		if ( path != nil )
		{
			NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES];
			
			[self setValue:[fileAttributes objectForKey:NSFileModificationDate] forKey:@"underlyingModificationDate"];
			[self setValue:[path stringByAbbreviatingWithTildeInPath] forKey:@"relativePath"];
		}
		else
		{
			NSLog(@"%s - original file missing for resource %@-%@ %@", __PRETTY_FUNCTION__, [[self entry] tagID], [self tagID], [self title]);
		}
	}
}

#pragma mark -

- (NSScriptObjectSpecifier *)objectSpecifier 
{	
	NSScriptClassDescription* appDesc = (NSScriptClassDescription*)[NSApp classDescription];
		
	NSUniqueIDSpecifier *specifier = [[NSUniqueIDSpecifier allocWithZone:[self zone]]
			initWithContainerClassDescription:appDesc containerSpecifier:nil
			key:@"JSReferences" uniqueID:[self tagID]];
		
	return [specifier autorelease];
}

@end

#pragma mark -

@implementation JournlerResource (FileResource)

- (id) initFileResource:(NSString*)path
{
	if ( self = [self initWithProperties:nil] )
	{
		[self setType:kResourceTypeFile];
		
		// note the title and filename
		[self setValue:[[path lastPathComponent] stringByDeletingPathExtension] forKey:@"title"];
		[self setValue:[path lastPathComponent] forKey:@"filename"];
		
		// note the relative path and the uti
		[self setValue:[[[NSWorkspace sharedWorkspace] resolveForAliases:path] stringByAbbreviatingWithTildeInPath] forKey:@"relativePath"];
		[self setValue:[[NSWorkspace sharedWorkspace] UTIForFile:[[NSWorkspace sharedWorkspace] resolveForAliases:path]] forKey:@"uti"];
	
		// note the date modified of the underlying data
		NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:[[NSWorkspace sharedWorkspace] resolveForAliases:path] traverseLink:YES];
		[self setValue:[fileAttributes objectForKey:NSFileModificationDate] forKey:@"underlyingModificationDate"];
	
		// prepare the text representation for the resources
		[self _deriveTextRepresentation:path];
	}
	return self;
}

#pragma mark -

- (NSString*) filename
{
	return [_properties valueForKey:ResourceFilenameKey];
}

- (void) setFilename:(NSString*)aString
{
	[_properties setValue:( aString ? aString : [NSString string] ) forKey:ResourceFilenameKey];
	[self setValue:BooleanNumber(YES) forKey:@"dirty"];
}

- (NSString*) relativePath
{
	return [_properties objectForKey:ResourceRelativePathKey];
}

- (void) setRelativePath:(NSString*)aString
{
	#ifdef __DEBUG__
	NSLog(@"%s - %@", __PRETTY_FUNCTION__, aString);
	#endif
	
	[_properties setValue:( aString ? aString : [NSString string] ) forKey:ResourceRelativePathKey];
	[self setValue:BooleanNumber(YES) forKey:@"dirty"];
}

#pragma mark -

// be able to reset the root folder
// so for example the data is stored on an external hard drive, root is no longer the same / 
// make it possible to change path information with applescript? what about creating new aliases?
// search the mounted volumes replacing /Volumes/VolumeName/ or even / with the various mounted volume paths

- (NSString*) path
{
	NSString *path = [[[self entry] resourcesPathCreating:NO] stringByAppendingPathComponent:[self valueForKey:@"filename"]];
	return path;
}

- (NSString*) originalPath
{
	// 1. try the alias
	// 2. try the relative path
	// 3. try the mounted volumes
	
	// if the file is found on a mounted volume, reset the relative path
	// might be a good ideal to also re-establish the alias
	
	// #warning check for nil!
	NSString *originalPath = [[NSWorkspace sharedWorkspace] resolveForAliases:[self path]];
	
	if ( originalPath == nil )
	{
		// try the relative path
		originalPath = [[self valueForKey:@"relativePath"] stringByExpandingTildeInPath];
		
		if ( ![[NSFileManager defaultManager] fileExistsAtPath:originalPath] )
		{
			// go through the volumes and see if the file is on one of them
			
			// /Users/philipdow/Documents/file.pdf -> /Volumes/AVolume/Documents/file.pdf
			// /Volumes/AVolume/Documents/file.pdf -> /Volumes/BVolume/Documents/file.pdf
			// /Volumes/AVolume/Documents/file.pdf -> /Users/philipdow/Documents/file.pdf

			NSString *strippedPath = nil;
			NSString *homeDirectory = NSHomeDirectory();
			NSArray *pathComponents = [originalPath pathComponents];
			NSArray *localVolumes = [[NSWorkspace sharedWorkspace] mountedLocalVolumePaths];
			static NSString *volumesRoot = @"/Volumes";
			
			// remove the volume specific path information from the original path
			
			if ( [originalPath rangeOfString:homeDirectory].location == 0 )
			{
				// remove the home directory path
				strippedPath = [originalPath substringFromIndex:[homeDirectory length]];
			}
			
			else if ( [originalPath rangeOfString:volumesRoot].location == 0 )
			{
				// remove the volume path
				//#warning exception being thrown here
				@try
				{
					NSArray *strippedPathComponents = [pathComponents subarrayWithRange:NSMakeRange( 3, [pathComponents count] - 3 )];
					strippedPath = [NSString pathWithComponents:strippedPathComponents];
				}
				@catch (NSException *localException)
				{
					strippedPath = nil;
					NSLog(@"%s exception: %@, entry: %@ resource path: %@", __PRETTY_FUNCTION__, localException, [self valueForKeyPath:@"entry.title"], originalPath);
				}
			}
			
			// move forward with the stripped down path unless we weren't able to derive it
			
			if ( strippedPath == nil )
				originalPath = nil;
			else
			{
				NSString *mountPoint;
				NSEnumerator *enumerator = [localVolumes objectEnumerator];
				
				// nil the path assuming we cannot find it
				originalPath = nil;
				
				// try each volume
				while ( mountPoint = [enumerator nextObject] )
				{
					NSString *aPath = [[mountPoint stringByAppendingPathComponent:strippedPath] stringByStandardizingPath];
					if ( [[NSFileManager defaultManager] fileExistsAtPath:aPath] )
					{
						originalPath = aPath;
						break;
					}
				}
				
				// try the home directory
				if ( originalPath == nil )
				{
					NSString *aPath = [[homeDirectory stringByAppendingPathComponent:strippedPath] stringByStandardizingPath];
					if ( [[NSFileManager defaultManager] fileExistsAtPath:aPath] )
						originalPath = aPath;
				}
				
				// reset the relative path if the file was found
				if ( originalPath != nil )
					[self setValue:[originalPath stringByAbbreviatingWithTildeInPath] forKey:@"relativePath"];
			}
		}
	}
	
	return originalPath;
}

- (BOOL) isAlias
{
	return ( ![[self path] isEqualToString:[self originalPath]] );
}

- (BOOL) isDirectory
{
	BOOL isDir;
	NSString *originalPath = [self originalPath];
	if ( originalPath == nil ) return NO;
	else return ( [[NSFileManager defaultManager] fileExistsAtPath:originalPath isDirectory:&isDir] && isDir );
}

- (BOOL) isFilePackage
{
	NSString *originalPath = [self originalPath];
	if ( originalPath == nil ) return NO;
	else return ( [[NSWorkspace sharedWorkspace] isFilePackageAtPath:originalPath] );
}

- (BOOL) isAppleScript
{	
	NSString *originalPath = [self originalPath];
	
	NSArray *exectuableUTIs = [NSArray arrayWithObjects: @"com.apple.applescript.text", @"com.apple.applescript.script", nil];
	NSArray *executableExtensions = [NSArray arrayWithObjects:@"scpt", @"scptd", nil];
	
	return ( [[NSWorkspace sharedWorkspace] file:originalPath confromsToUTIInArray:exectuableUTIs] 
			|| [executableExtensions containsObject:[originalPath pathExtension]] );
}

- (BOOL) isApplication
{
	return ( UTTypeConformsTo( (CFStringRef)[self uti], kUTTypeApplication ) );
}

#pragma mark -

+ (NSImage*) iconBadgeForType:(NSInteger)type
{
	NSImage *returnImage = nil;
	switch ( type )
	{
	case kJournlerResourceAliasBadge:
		returnImage = AliasBadge();
		break;
		
	case kJournlerResourceQuestionMarkBadge:
		returnImage = QuestionMarkBadge();
		break;
		
	case kJournlerResourceBlankDocumentIcon:
		returnImage = BlankDocumentIcon();
		break;
		
	case kJournlerResourceAlertBadge:
		returnImage = AlertBadge();
		break;
	}
	
	return returnImage;
}

@end

#pragma mark -

@implementation JournlerResource (URLResource)

- (id) initURLResource:(NSURL*)aURL
{
	if ( self = [self initWithProperties:nil] )
	{
		[self setType:kResourceTypeURL];
		
		[self setValue:[aURL absoluteString] forKey:@"title"];
		[self setValue:[aURL absoluteString] forKey:@"urlString"];
		
		//NSImage *icon = [NSImage imageNamed:@"safari.tif"];
		//[self setValue:icon forKey:@"icon"];
		
		[self setValue:(NSString*)kUTTypeURL forKey:@"uti"];
		[self setValue:[NSNumber numberWithBool:NO] forKey:@"searches"];
	}	
	return self;
}

#pragma mark -

- (NSString*) urlString
{
	return [_properties valueForKey:ResourceURLStringKey];
}

- (void) setUrlString:(NSString*)aString
{
	[_properties setValue:( aString ? aString : @"http://journler.com" ) forKey:ResourceURLStringKey];
	[self setValue:BooleanNumber(YES) forKey:@"dirty"];
}

#pragma mark -

- (NSString*) searchContentForURL
{
	NSMutableString *searchable = [NSMutableString string];
	
	NSString *theTitle = [self valueForKey:@"theTitle"];
	NSString *theAddress = [self valueForKey:@"urlString"];
	
	if ( theTitle != nil )
		[searchable appendString:theTitle];
	if ( theAddress != nil && ![theAddress isEqualToString:theTitle] )
	{
		[searchable appendString:@" "];
		[searchable appendString:theAddress];
	}
	
	return searchable;
}

- (NSString*) htmlRepresentationForURLWithCache:(NSString*)cachePath
{
	return nil;
}

@end

#pragma mark -

@implementation JournlerResource (ABPersonResource)

- (id) initABPersonResource:(ABPerson*)aPerson
{
	if ( self = [self initWithProperties:nil] )
	{
		[self setType:kResourceTypeABRecord];
		
		[self setValue:[aPerson fullname] forKey:@"title"];
		[self setValue:[aPerson uniqueId] forKey:@"uniqueId"];
		
		/*
		NSImage *icon = [aPerson image];
		if ( icon == nil )
			icon = [NSImage imageNamed:@"vCard.tiff"];
		else
			icon = [icon imageWithWidth:128 height:128 inset:9];
		
		[self setValue:icon forKey:@"icon"];
		*/
		
		[self setValue:ResourceABPersonUTI forKey:@"uti"];
	}
	return self;
}

#pragma mark -

- (NSString*) uniqueId
{
	return [_properties valueForKey:ResourceABIDKey];
}

- (void) setUniqueId:(NSString*)aString
{
	[_properties setValue:( aString ? aString : [NSString string] ) forKey:ResourceABIDKey];
	[self setValue:BooleanNumber(YES) forKey:@"dirty"];
}

#pragma mark -

- (ABPerson*) person
{
	return (ABPerson*)[[ABAddressBook sharedAddressBook] recordForUniqueId:[self valueForKey:@"uniqueId"]];
}

- (NSString*) searchContentForABRecord
{
	ABPerson *myPerson = [self person];
	if ( myPerson == nil )
		return nil;
	
	int i;
	NSString *note;
	ABMultiValue *phoneRecords, *emailRecords, *urlRecords, *addressRecords;
	NSMutableString *searchContent = [NSMutableString string];
	
	// build the search content - full name first
	[searchContent appendString:[myPerson fullname]];
	
	// phone records
	phoneRecords = [myPerson valueForProperty:kABPhoneProperty];
	for ( i = 0; i < [phoneRecords count]; i++ )
	{
		[searchContent appendString:[phoneRecords valueAtIndex:i]];
		[searchContent appendString:@" "];
	}
	
	// email records
	emailRecords = [myPerson valueForProperty:kABEmailProperty];
	for ( i = 0; i < [emailRecords count]; i++ ) 
	{
		[searchContent appendString:[emailRecords valueAtIndex:i]];
		[searchContent appendString:@" "];
	}
	
	// url records
	urlRecords = [myPerson valueForProperty:kABURLsProperty];
	for ( i = 0; i < [urlRecords count]; i++ ) 
	{
		[searchContent appendString:[urlRecords valueAtIndex:i]];
		[searchContent appendString:@" "];
	}
	
	// address records
	addressRecords = [myPerson valueForProperty:kABAddressProperty];
	for ( i = 0; i < [addressRecords count]; i++ ) 
	{
		NSAttributedString *formattedAddress = [[ABAddressBook sharedAddressBook] formattedAddressFromDictionary:[addressRecords valueAtIndex:i]];
		if ( formattedAddress != nil )
			[searchContent appendString:[formattedAddress string]];
		[searchContent appendString:@" "];
	}
	
	// the note
	note = [myPerson valueForProperty:kABNoteProperty];
	if ( note != nil )
	{
		[searchContent appendString:note];
		[searchContent appendString:@" "];
	}
	
	return searchContent;
}

@end

#pragma mark -

@implementation JournlerResource (JournlerObjectResource)

- (id) initJournalObjectResource:(NSURL*)aURI
{
	if ( self = [self initWithProperties:nil] )
	{
		[self setType:kResourceTypeJournlerObject];
		
		[self setValue:[aURI absoluteString] forKey:@"title"];
		[self setValue:[aURI absoluteString] forKey:@"uriString"];
		
		// icon is handled only after the journal relationship has been estalished
		
		[self setValue:ResourceJournlerObjectURIUTI forKey:@"uti"];
	}
	return self;
}

#pragma mark -

- (NSString*) uriString
{
	return [_properties valueForKey:ResourceJournlerObjectURIKey];
}

- (void) setUriString:(NSString*)aString
{
	[_properties setValue:( aString ? aString : [NSString string] ) forKey:ResourceJournlerObjectURIKey];
	[self setValue:BooleanNumber(YES) forKey:@"dirty"];
}

#pragma mark -

- (id) journlerObject
{
	if ( [self representsJournlerObject] )
		return [[self valueForKey:@"journal"] objectForURIRepresentation:[NSURL URLWithString:[self valueForKey:@"uriString"]]];
	else
		return nil;
}

@end

#pragma mark -

/*
@implementation JournlerResource (AudioVideoSnapshotSupport)

- (id) initSnapshotResource
{
	if ( self = [self initWithProperties:nil] )
	{
		[self setType:kResourceTypeRecording];
		[self setValue:ResourceSnapshotUTI forKey:@"uti"];
		[self setValue:NSLocalizedString(@"Snapshot",@"title of snapshot resource") forKey:@"title"];
	
		// entry handled afterwards
		// icon is handled only after the journal relationship has been estalished
		
	}
	return self;
}

- (id) initAudioRecordingResource
{
	return nil;
}

- (id) initVideoRecordingResource
{
	return nil;
}

#pragma mark -

- (BOOL) representsRecording
{
	return ( [self type] == kResourceTypeRecording ); 
}

@end

#pragma mark -
*/

@implementation JournlerResource (PasteboardSupport)

- (id) initWithPasteboard:(NSPasteboard*)pboard operation:(NewResourceCommand)command 
		entry:(JournlerEntry*)anEntry journal:(JournlerJournal*)aJournal
{
	// initializes a resource from pasteboard data, global if no entry is provided (in which case the journal must be)
	
	return nil;
}

@end

#pragma mark -

@implementation JournlerResource (JournlerScriptability)

- (OSType) scriptType
{
	OSType scriptType = 'rtME';
	
	switch ( [self type] )
	{
	case kResourceTypeFile:
		scriptType = 'rtME';
		break;
	case kResourceTypeABRecord:
		scriptType = 'rtCO';
		break;
	case kResourceTypeURL:
		scriptType = 'rtWE';
		break;
	case kResourceTypeJournlerObject:
		scriptType = 'rtIN';
		break;
	}
	
	return scriptType;
}

- (void) setScriptType:(OSType)osType
{
	
	JournlerResourceType aType = kResourceTypeFile;
	
	switch ( osType )
	{
	case 'rtME':
		aType = kResourceTypeFile;
		break;
	case 'rtCO':
		aType = kResourceTypeABRecord;
		break;
	case 'rtWE':
		aType = kResourceTypeURL;
		break;
	case 'rtIN':
		aType = kResourceTypeJournlerObject;
		break;
	}
	
	[self setType:aType];
	
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


- (NSNumber*) scriptAliased
{
	if ( scriptAliased != nil )
		return scriptAliased;
	else
		return [NSNumber numberWithBool:![[self path] isEqualToString:[self originalPath]]];
}

- (void) setScriptAliased:(NSNumber*)aNumber
{
	scriptAliased = [aNumber retain];
}

- (NSString*) URIRepresentationAsString
{
	return [[self URIRepresentation] absoluteString];
}

#pragma mark -
#pragma mark Entries

- (int) indexOfObjectInJSEntries:(JournlerEntry*)anEntry 
{
	return [[self valueForKeyPath:@"entries"] indexOfObject:anEntry];
}

- (unsigned int) countOfJSEntries 
{
	return [[self valueForKeyPath:@"entries"] count];
}

- (JournlerEntry*) objectInJSEntriesAtIndex:(unsigned int)i 
{
	if ( i >= [[self valueForKeyPath:@"entries"] count] ) 
	{
		[self returnError:OSAIllegalIndex string:nil];
		return nil;
	}
	else
	{
		return [[self valueForKeyPath:@"entries"] objectAtIndex:i];
	}
}

- (JournlerEntry*) valueInJSEntriesWithUniqueID:(NSNumber*)idNum 
{
	return [[self valueForKeyPath:@"journal.entriesDictionary"] objectForKey:idNum];
}

#pragma mark -
#pragma mark Scripting Commands

- (void) jsExport:(NSScriptCommand *)command
{
	
	NSDictionary *args = [command evaluatedArguments];
	
	BOOL dir;
	
	NSString *path;
	id pathURL = [args objectForKey:@"exportLocation"];
	
	if ( pathURL == nil || ![pathURL isKindOfClass:[NSURL class]] ) 
	{
		// raise an error
		NSLog(@"%s - nil path or path other than url, but path is required", __PRETTY_FUNCTION__);
		[self returnError:errOSACantAssign string:nil];
		return;
	}
	
	path = [pathURL path];
	if ( [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&dir] && dir )
		path = path;
	else
		path = [path stringByDeletingLastPathComponent];
		
	// write the file, error checking on the way
	if ( [self createFileAtDestination:path] == nil )
	{
		NSLog(@"%s - unable to export resource to path %@", __PRETTY_FUNCTION__, path);
		[self returnError:OSAParameterMismatch string:@"File path is not valid or an error was encountered writing the file."];
	}
	
}



@end
