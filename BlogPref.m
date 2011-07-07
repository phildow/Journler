//
//  BlogPref.m
//  Cocoa Journler
//
//  Created by Philip Dow on 4/4/05.
//  Copyright 2005 Sprouted, Philip Dow. All rights reserved.
//

#import "BlogPref.h"

// #warning "journal" is a key-value used by the entry info and blog center

@implementation BlogPref

- (id) init 
{
	return [self initWithProperties:nil];
}

- (id) initWithProperties:(NSDictionary*)aDictionary
{
	if ( self = [super initWithProperties:aDictionary] )
	{
	
	}
	return self;
}


+ (NSDictionary*) defaultProperties
{
	NSArray *keys = [[[NSArray alloc] initWithObjects: 
			@"name", @"location", 
			@"type", @"login", 
			@"password", @"xmlrpcLocation", 
			@"blogID", @"tagID", 
			@"blog", @"journal", nil] autorelease]; /* for backwards compatbility */
			
	NSArray *objects = [[[NSArray alloc] initWithObjects: 
			@"New Blog", @"http://", 
			@"Blogger", [NSString string], 
			[NSString string], [NSString string], 
			[NSString stringWithString:@"1"], [NSNumber numberWithInt:-1], 
			[NSString string], [NSString string], nil] autorelease];  /* for backwards compatbility */
			
	NSDictionary *defaults = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	return defaults;
}

#pragma mark -

- (id)initWithCoder:(NSCoder *)decoder 
{
	// decode the archive
	NSDictionary *archivedProperties = [decoder decodeObjectForKey:@"BlogProperties"];
	if ( !archivedProperties ) 
		return nil;
	
	return [self initWithProperties:archivedProperties];
}


- (void)encodeWithCoder:(NSCoder *)encoder {
	
	if ( ![encoder allowsKeyedCoding] ) 
	{
		NSLog(@"Cannot encode BlogPef without a keyed archiver");
		return;
	}
	
	// encode the properties dictionary but without the password
	NSMutableDictionary *encodableProperties = [[[self valueForKey:@"properties"] mutableCopyWithZone:[self zone]] autorelease];
	[encodableProperties removeObjectForKey:@"password"];
	
	[encoder encodeObject:encodableProperties forKey:@"BlogProperties"];
}

#pragma mark -

- (id)copyWithZone:(NSZone *)zone 
{
	BlogPref *newObject = [[[self class] allocWithZone:zone] init];
	
	[newObject setProperties:[self properties]];
	[newObject setJournal:[self journal]];
	[newObject setDirty:[self dirty]];
	[newObject setDeleted:[self deleted]];
	
	return newObject;
}


#pragma mark -

- (unsigned) hash 
{	
	// return the tag id, guaranteed to be unique
	return [[self tagID] unsignedIntValue];
}

- (BOOL)isEqual:(id)anObject 
{	
	// tests for the class and then the int tag id
	return ( [anObject isMemberOfClass:[self class]] && [[self tagID] intValue] == [[anObject tagID] intValue] );
}

#pragma mark -

+ (NSString*) tagIDKey
{
	return @"tagID";
}

+ (NSString*) titleKey
{
	return @"name";
}

- (NSString*)name 
{
	return [_properties objectForKey:@"name"];
}

- (void)setName:(NSString*)newObject 
{	
	[_properties setObject:( newObject ? newObject : [NSString string] ) forKey:@"name"];
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"dirty"];
}

- (NSString*)blogType 
{
	return [_properties objectForKey:@"type"];
}

- (void)setBlogType:(NSString*)newObject 
{
	[_properties setObject:( newObject ? newObject : [NSString string] ) forKey:@"type"];
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"dirty"];
}

- (NSString*)httpLocation 
{
	return [_properties objectForKey:@"location"];
}

- (void)setHttpLocation:(NSString*)newObject 
{
	[_properties setObject:( newObject ? newObject : [NSString string] ) forKey:@"location"];
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"dirty"];
}

- (NSString*)login 
{
	return [_properties objectForKey:@"login"];
}

- (void)setLogin:(NSString*)newObject 
{
	[_properties setObject:( newObject ? newObject : [NSString string] ) forKey:@"login"];	
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"dirty"];
}

- (NSString*)password 
{
	return [_properties objectForKey:@"password"];
}

- (void)setPassword:(NSString*)newObject 
{
	[_properties setObject:( newObject ? newObject : [NSString string] ) forKey:@"password"];	
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"dirty"];
}

- (NSString*)xmlrpcLocation 
{
	return [_properties objectForKey:@"xmlrpcLocation"];
}

- (void)setXmlrpcLocation:(NSString*)newObject 
{	
	[_properties setObject:( newObject ? newObject : [NSString string] ) forKey:@"xmlrpcLocation"];	
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"dirty"];	
}

- (NSString*)blogID 
{
	return [_properties objectForKey:@"blogID"];
}

- (void)setBlogID:(NSString*)newObject
{	
	[_properties setObject:( newObject ? newObject : [NSString string] ) forKey:@"blogID"];
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"dirty"];
}

// backwards compatibility with old blog data that used the "journal" property as an attribute
- (NSString*)blogJournal
{
	NSString *blogJournal = [_properties objectForKey:@"journal"];
	if ( blogJournal == nil ) blogJournal = [_properties objectForKey:@"blogJournal"];
	
	return blogJournal;
}

- (void) setBlogJournal:(NSString*)aString
{
	[_properties setObject:( aString ? aString : [NSString string] ) forKey:@"journal"];
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"dirty"];
}

#pragma mark -

- (NSURL*) URIRepresentation
{	
	NSString *urlString = [NSString stringWithFormat:@"journler://blog/%@", [self valueForKey:@"tagID"]];
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

#pragma mark -

- (id)objectForKey:(id)aKey 
{ 	
	return [_properties objectForKey:aKey]; 
}

- (void)setObject:(id)anObject forKey:(id)aKey 
{
	if ( anObject == nil || aKey == nil ) 
	{
		[NSException raise:NSInvalidArgumentException format:@""];
		return;
	}
	
	[_properties setObject:anObject forKey:aKey];
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"dirty"];
}

- (id)valueForUndefinedKey:(NSString *)key 
{ 
	return [self objectForKey:key]; 
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key 
{
	[self willChangeValueForKey:key];
	[self setObject:value forKey:key];
	[self didChangeValueForKey:key];
}

#pragma mark -

- (NSScriptObjectSpecifier *)objectSpecifier 
{
	
	NSScriptClassDescription* appDesc = (NSScriptClassDescription*)[NSApp classDescription];
		
	NSUniqueIDSpecifier *specifier = [[NSUniqueIDSpecifier allocWithZone:[self zone]]
			initWithContainerClassDescription:appDesc containerSpecifier:nil
			key:@"JSBlogs" uniqueID:[self tagID]];
		
	return [specifier autorelease];
}

@end