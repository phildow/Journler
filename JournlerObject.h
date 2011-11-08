//
//  JournlerObject.h
//  Journler
//
//  Created by Philip Dow on 1/26/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
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

#define JournlerObjectAttributeKey @"JournlerObjectAttributeKey"

#define JournlerObjectAttributeLabelKey @"label"

#define JournlerObjectDidChangeValueForKeyNotification @"JournlerObjectDidChangeAttributeNotification"

@class JournlerJournal;

@interface JournlerObject : NSObject <NSCopying, NSCoding> {
	
	NSMutableDictionary	 *_properties;
	
	JournlerJournal *_journal;
	
	NSNumber *_dirty;
	NSNumber *_deleted;
	
	id _scriptContainer;
}

// initialization

- (id) initWithProperties:(NSDictionary*)aDictionary;

// properties (attributes)

- (NSDictionary*) properties;
- (void) setProperties:(NSDictionary*)aDictionary;

+ (NSDictionary*) defaultProperties;

// every object maintains a relationship to a journal

- (JournlerJournal*) journal;
- (void) setJournal:(JournlerJournal*)aJournal;

- (NSNumber*) journalID;
- (void) setJournalID:(NSNumber*)jID;

// state information

- (NSNumber*) dirty;
- (void) setDirty:(NSNumber*)aNumber;

- (NSNumber*) deleted;
- (void) setDeleted:(NSNumber*)aNumber;

// applescript support

- (id) scriptContainer;
- (void) setScriptContainer:(id)anObject;

- (NSScriptObjectSpecifier *)objectSpecifier;

// uri representation allows the object to be accessed from any application

- (NSURL*) URIRepresentation;
- (NSMenuItem*) menuItemRepresentation:(NSSize)imageSize;

// keys used for the tag and title, subclasses may override

+ (NSString*) tagIDKey;
+ (NSString*) titleKey;
+ (NSString*) iconKey;

// standard attributes which every journler object supports

- (NSNumber*) tagID;
- (void) setTagID:(NSNumber*)aNumber;

- (NSString*) title;
- (void) setTitle:(NSString*)aString;

- (NSImage*) icon;
- (void) setIcon:(NSImage*)anImage;

@end