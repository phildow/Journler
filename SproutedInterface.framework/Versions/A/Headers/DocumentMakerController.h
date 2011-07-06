//
//  DocumentMakerController.h
//  Sprouted Interface
//
//  Created by Philip Dow on 9/28/07.
//  Copyright 2007 Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *kSproutedAppHelperURL;
extern NSString *kSproutedAppHelperFlags;
extern NSString *kSproutedAppHelperMetadata;
extern NSString *kSproutedAppHelperIcon;
extern NSString *kSproutedAppHelperEntityName;

@interface DocumentMakerController : NSObject {
	
	id delegate;
	id representedObject;
	
	NSManagedObjectContext *managedObjectContext;
}

- (id) initWithOwner:(id)anObject managedObjectContext:(NSManagedObjectContext*)moc;

- (int) numberOfViews;
- (NSView*) contentViewAtIndex:(int)index;
- (void) willSelectViewAtIndex:(int)index;
- (void) didSelectViewAtIndex:(int)index;
- (NSString*) titleOfViewAtIndex:(int)index;

- (id) delegate;
- (void) setDelegate:(id)anObject;

- (NSManagedObjectContext*) managedObjectContext;
- (void) setManagedObjectContext:(NSManagedObjectContext*)moc;

- (id) representedObject;
- (void) setRepresentedObject:(id)anObject;

- (NSArray*) documentDictionaries:(NSError**)error;

@end
