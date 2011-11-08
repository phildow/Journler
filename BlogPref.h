//
//  BlogPref.h
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
