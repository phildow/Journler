//
//  ResourceController.h
//  Journler
//
//  Created by Philip Dow on 10/26/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
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
	
	NSUInteger _dragOperation;
	BOOL showingSearchResults;
	BOOL usesSmallResourceIcons;
	
	NSInteger onTheFlyTag;
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

- (void) sortBy:(NSInteger)sortTag;
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

- (NSUInteger) _commandForCurrentCommand:(NSUInteger)dragOperation fileType:(NSString*)type directory:(BOOL)dir package:(BOOL)package;

- (void) _entryDidChangeResourceContent:(NSNotification*)aNotification;
- (ResourceNode*) _nodeForResource:(JournlerResource*)aResource;

@end

@interface NSObject (ResourceControllerDelegate)

- (BOOL) resourceController:(ResourceController*)aController newDefaultEntry:(NSNotification*)aNotification;
- (void) resourceController:(ResourceController*)aController willChangeSelection:(NSArray*)currentSelection;

@end
