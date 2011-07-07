//
//  JournlerObject.h
//  Journler
//
//  Created by Philip Dow on 1/26/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

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