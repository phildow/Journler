//
//  BlogPref.h
//  Cocoa Journler
//
//  Created by Philip Dow on 4/4/05.
//  Copyright 2005 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	
	kBloggerAccountType = 10,
	kLiveJournalAccountType = 11,
	kBloggerAPIAccountType = 20,
	kBlogger2APIAccountType = 21,
	kMetaWeblogAPIAccountType = 22,
	kMovableTypeAPIAccountType = 23
	
}BlogPrefAccountType;

#define BlogPrefBloggerAccount			@"Blogger"
#define BlogPrefLiveJournalAccount		@"LiveJournal"
#define BlogPrefBloggerAPIAccount		@"Blogger API"
#define BlogPrefBlogger2APIAccount		@"Blogger2 API"
#define BlogPrefMetaWeblogAPIAccount	@"MetaWeblog API"
#define BlogPrefMovableTypeAPIAccount	@"MovableType API"

@class JournlerJournal;

#import "JournlerObject.h"

@interface BlogPref : JournlerObject <NSCopying, NSCoding> {

}

- (NSString*)name;
- (void)setName:(NSString*)newObject;

- (NSString*)blogType;
- (void)setBlogType:(NSString*)newObject;

- (NSString*)httpLocation;
- (void)setHttpLocation:(NSString*)newObject;

- (NSString*)login;
- (void)setLogin:(NSString*)newObject;

- (NSString*)password;
- (void)setPassword:(NSString*)newObject;

- (NSString*)xmlrpcLocation;
- (void)setXmlrpcLocation:(NSString*)newObject;

- (NSString*)blogID;
- (void)setBlogID:(NSString*)newObject;

- (NSString*)blogJournal;
- (void) setBlogJournal:(NSString*)aString;

//
// compatibility with older setups
- (id)objectForKey:(id)aKey;
- (void)setObject:(id)anObject forKey:(id)aKey;

- (id)valueForUndefinedKey:(NSString *)key;
- (void)setValue:(id)value forUndefinedKey:(NSString *)key;

@end
