//
//  PDMediabarItem.h
//  Journler
//
//  Created by Phil Dow on 2/20/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	kMenubarItemDefault = 0,
	kMenubarItemURI = 1,
	kMenubarItemAppleScript = 2,
} MenubarItemType;

@class PDMediaBar;

@interface PDMediabarItem : NSButton {
	
	NSString *identifier;
	NSNumber *typeIdentifier;
	
	NSURL *targetURI;
	NSAttributedString *targetScript;
	
	PDMediaBar *mediabar;
}

- (id) initWithItemIdentifier:(NSString*)aString;
- (id) initWithDictionaryRepresentation:(NSDictionary*)aDictionary;

- (NSDictionary*) dictionaryRepresentation;
- (void) setAttributesFromDictionaryRepresentation:(NSDictionary*)aDictionary;

- (NSString*)identifier;
- (void) setIdentifier:(NSString*)aString;

- (NSSize) size;
- (void) setSize:(NSSize)aSize;

- (PDMediaBar*) mediabar;
- (void) setMediabar:(PDMediaBar*)aMediabar;

// a custom button should target the media controller itself
// a special function that grabs the target information and takes the appropriate action
// a default method will handle this, but it may be overridden

- (NSNumber*) typeIdentifier;
- (void) setTypeIdentifier:(NSNumber*)aNumber;

- (NSURL*) targetURI;
- (void) setTargetURI:(NSURL*)aURL;

- (NSAttributedString*) targetScript;
- (void) setTargetScript:(NSAttributedString*)aString;


@end
