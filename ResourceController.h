//
//  ResourceController.h
//  Journler
//
//  Created by Philip Dow on 10/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>

#import "JournlerResource.h"

typedef enum
{
	kSortResourcesByKind = 0,
	kSortResourcesByTitle = 1,
	kSortResourcesByRank = 2
} ResourceSortCommand;

typedef enum 
{
	kResourceNodeHidden = 0,	// not available
	kResourceNodeCollapsed = 1,	// visble but closed
	kResourceNodeExpanded = 2	// visble and expanded
} ResourceCategoryNodeState;

@class ResourceTableView;
@class ResourceNode;

@class JournlerEntry;
@class JournlerResource;

@interface ResourceController : NSArrayController {
	
	id delegate;
	NSSet *intersectSet;
	IBOutlet ResourceTableView *resourceTable;
	
	NSArray *folders;
	NSArray *resources;
	NSArray *resourceNodes;
	
	NSArray *selectedResources;
	NSArray *arrangedResources;
	
	ResourceNode *foldersNode, *internalNode;
	ResourceNode *contactsNode, *correspondenceNode, *urlsNode, *documentsNode, *pdfsNode, *archivesNode, *imagesNode, *avNode;
	
	NSMutableDictionary *stateDictionary;
	
	unsigned _dragOperation;
	BOOL showingSearchResults;
	BOOL usesSmallResourceIcons;
	
	int onTheFlyTag;
	BOOL dragProducedEntry;
	
	NSImage *defaultDisclosure;
	NSImage *defaultAltDisclosure;
	
	NSImage *smallDiscloure;
	NSImage *smallAltDisclosure;
}

- (id) delegate;
- (void) setDelegate:(id)anObject;

- (BOOL) showingSearchResults;
- (void) setShowingSearchResults:(BOOL)searching;

- (NSArray*) selectedResources;
- (void) setSelectedResources:(NSArray*)anArray;

- (NSArray*) arrangedResources;
- (void) setArrangedResources:(NSArray*)anArray;

- (NSSet*) intersectSet;
- (void) setIntersectSet:(NSSet*)newSet;

- (NSArray*) resources;
- (void) setResources:(NSArray*)anArray;

- (NSArray*) folders;
- (void) setFolders:(NSArray*)anArray;

- (NSArray*) resourceNodes;
- (void) setResourceNodes:(NSArray*)anArray;

- (NSDictionary*) stateDictionary;
- (BOOL) restoreStateFromDictionary:(NSDictionary*)aDictionary;

- (void) prepareResourceNodes;

- (IBAction) tableDoubleClick:(id)sender;

- (IBAction) showEntryForSelectedResource:(id)sender;
- (IBAction) setSelectionAsDefaultForEntry:(id)sender;

- (IBAction) renameResource:(id)sender;
- (IBAction) editResourceLabel:(id)sender;
- (IBAction) editResourcePropety:(id)sender;
- (IBAction) revealResource:(id)sender;
- (IBAction) launchResource:(id)sender;
- (IBAction) emailResourceSelection:(id)sender;

- (IBAction) openResourceInNewTab:(id)sender;
- (IBAction) openResourceInNewWindow:(id)sender;
- (IBAction) openResourceInNewFloatingWindow:(id)sender;

- (void) openAResourceWithFinder:(JournlerResource*)aResource;
- (void) openAResourceInNewTab:(JournlerResource*)aResource;
- (void) openAResourceInNewWindow:(JournlerResource*)aResource;

- (IBAction) setProperty:(id)sender;
- (IBAction) setDisplayOption:(id)sender;
- (IBAction) deleteSelectedResources:(id)sender;

- (void) sortBy:(int)sortTag;
- (IBAction) sortByCommand:(id)sender;
- (IBAction) exposeAllResources:(id)sender;
- (BOOL) selectResource:(JournlerResource*)aResource byExtendingSelection:(BOOL)extend;

- (IBAction) rescanResourceIcon:(id)sender;
- (IBAction) rescanResourceUTI:(id)sender;

- (BOOL) _addMailMessage:(NSDictionary*)objectDictionary;
- (BOOL) _addMailMessage:(id <NSDraggingInfo>)sender toEntry:(JournlerEntry*)anEntry;

- (BOOL) _addPerson:(ABPerson*)aPerson toEntry:(JournlerEntry*)anEntry;
- (BOOL) _addURL:(NSURL*)aURL title:(NSString*)title toEntry:(JournlerEntry*)anEntry;
- (BOOL) _addJournlerObjectWithURI:(NSURL*)aURL toEntry:(JournlerEntry*)anEntry;
- (BOOL) _addAttributedString:(NSAttributedString*)anAttributedString toEntry:(JournlerEntry*)anEntry;
- (BOOL) _addString:(NSString*)aString toEntry:(JournlerEntry*)anEntry;
- (BOOL) _addWebArchiveFromURL:(NSURL*)aURL title:(NSString*)title toEntry:(JournlerEntry*)anEntry;
- (BOOL) _addImageData:(NSData*)imageData dataType:(NSString*)type title:(NSString*)title toEntry:(JournlerEntry*)anEntry;
- (BOOL) _addFile:(NSString*)filename title:(NSString*)title resourceCommand:(NewResourceCommand)command toEntry:(JournlerEntry*)anEntry;

- (NSString*) _mdTitleFoFileAtPath:(NSString*)fullpath;
- (NSString*) _linkedTextForAudioFile:(NSString*)fullpath;

- (unsigned) _commandForCurrentCommand:(unsigned)dragOperation fileType:(NSString*)type directory:(BOOL)dir package:(BOOL)package;

- (void) _entryDidChangeResourceContent:(NSNotification*)aNotification;
- (ResourceNode*) _nodeForResource:(JournlerResource*)aResource;

@end

@interface NSObject (ResourceControllerDelegate)

- (BOOL) resourceController:(ResourceController*)aController newDefaultEntry:(NSNotification*)aNotification;
- (void) resourceController:(ResourceController*)aController willChangeSelection:(NSArray*)currentSelection;

@end
