//
//  JournlerIndexServer.h
//  Journler
//
//  Created by Philip Dow on 2/13/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//
//	The Index Server provides a centralized location for index processing
//	All index-related queries are directed to it
//	The Server is thus a bridge between the interface controllers and the data model
//

#import <Cocoa/Cocoa.h>

#define kLexiconMenuItemTag 10746

@class JournlerObject;
@class JournlerSearchManager;

@interface JournlerIndexServer : NSObject {
	
	JournlerSearchManager *searchManager;
	
	NSMutableDictionary *termToDocumentsDictionary;
	NSMutableDictionary *documentToTermsDictionary;
	
	BOOL rootTermsLoaded;
	NSArray *rootTermNodes;
	
	NSMenuItem *embeddedLexiconMenuItem;
	NSString *embeddedLexiconMenuItemTerm;
}

- (id) initWithSearchManager:(JournlerSearchManager*)aSearchManager;
- (JournlerSearchManager*)searchManager;

#pragma mark -

- (BOOL) loadRootTerms;
- (BOOL) rootTermsLoaded;

- (NSArray*) rootTermNodes;
- (void ) setRootTermNodes:(NSArray*)anArray;

#pragma mark -

// both methods take an array of index nodes and return an array of index nodes
- (NSArray*) termNodesForDocumentNodes:(NSArray*)anArray;
- (NSArray*) documentNodesForTermNodes:(NSArray*)anArray;

// clean out the lexicon dictionary - call when you no longer need the data
- (void) releaseTermAndDocumentDictionaries;

#pragma mark -

// these methods may be used to build a menu item - they must be run on the main thread
//	1. set the menu's delegate to the index server and set the tag on the menu's super menuitem to kLexiconMenuItemTag
//	2. you should also set the target and action on the super menuitem, the lexicon uses it for each constructed item in the menu
//	3. set the term you want the lexicon entries for to the super menuitem's represented object - but do not rely on it for anything else

- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(int)index shouldCancel:(BOOL)shouldCancel;
- (int)numberOfItemsInMenu:(NSMenu *)menu;

// returns the term being represented by the lexicon menu - you should have set it earlier (#3 above)
- (NSString*) lexiconMenuRepresentedTerm;

@end

@interface JournlerIndexServer (InterfaceSupport)

- (NSImage*) image:(NSImage*)anImage withWidth:(float)width height:(float)height;

@end

#pragma mark -
