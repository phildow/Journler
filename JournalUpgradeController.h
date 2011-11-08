/* JournalUpgradeController */

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
#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>
#import <SproutedAVI/SproutedAVI.h>

@class BlogPref;
@class JournlerEntry;
@class JournlerJournal;
@class JournlerCollection;

@interface JournalUpgradeController : NSWindowController
{
	IBOutlet PDGradientView			*container210;
	IBOutlet NSProgressIndicator	*progressIndicator210;
	IBOutlet NSBox					*box210;
	
	IBOutlet NSTextField			*headerText210;
	IBOutlet NSTextField			*progressText210;
	
	IBOutlet NSButton				*relaunch210;
	
	IBOutlet NSWindow				*licenseChanged210;
	
	NSModalSession session210;
	NSModalSession session253;
	NSMutableString *log210;
	NSMutableString	*log117;
	
	NSInteger  upgradeMode;
	JournlerJournal		*_journal;
	
	NSMutableDictionary *entriesDictionary;
	NSMutableDictionary *foldersDictionary;
}

- (void) run117To210Upgrade:(JournlerJournal*)journal;
- (BOOL) processResourcesLinksForEntry117To210:(JournlerEntry*)anEntry;
- (void) installLameComponents;
- (id) objectForURIRepresentation:(NSURL*)aURL;
- (NSArray*) entriesForTagIDs:(NSArray*)tagIDs;

#pragma mark -

- (NSInteger) run200To210Upgrade:(JournlerJournal*)journal;
- (BOOL) processResourcesForEntry:(JournlerEntry*)anEntry;
- (BOOL) processResourcesLinksForEntry:(JournlerEntry*)anEntry;
- (BOOL) processFileLinksForEntry:(JournlerEntry*)anEntry;

- (IBAction) relaunchJournler:(id)sender;
- (IBAction) quit210Upgrade:(id)sender;

#pragma mark -

- (void) run210To250Upgrade:(JournlerJournal*)aJournal;

#pragma mark -

- (BOOL) perform250To253Upgrade:(JournlerJournal*)aJournal;

#pragma mark -

- (BOOL) moveJournalOutOfApplicationSupport:(JournlerJournal*)aJournal;

- (NSAlert*) alertForMovingJournalOutOfApplicationSupport;
- (NSAlert*) alertWhenFolderNamedJournalAlreadyExistsInLibrary;
- (NSAlert*) alertWhenDataStoreMoveSucceeds;
- (NSAlert*) alertWhenDataStoreMoveFails;

- (NSString *) applicationSupportFolder;
- (NSString*) documentsFolder;
- (NSString*) libraryFolder;

@end
