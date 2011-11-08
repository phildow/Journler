//
//  BlogPref.m
//  Cocoa Journler
//
//  Created by Philip Dow on 4/4/05.
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
			[NSString stringWithString:@"1"], [NSNumber numberWithInteger:-1], 
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

- (NSUInteger) hash 
{	
	// return the tag id, guaranteed to be unique
	return [[self tagID] unsignedIntegerValue];
}

- (BOOL)isEqual:(id)anObject 
{	
	// tests for the class and then the int tag id
	return ( [anObject isMemberOfClass:[self class]] && [[self tagID] integerValue] == [[anObject tagID] integerValue] );
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