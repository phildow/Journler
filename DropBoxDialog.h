/* DropBoxDialog */

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
#import <SproutedInterface/SproutedInterface.h>

@class JournlerJournal;
@class JournlerCollection;
@class FoldersController;

@class DropBoxFoldersController;
@class DropBoxSourceList;

@interface DropBoxDialog : NSWindowController
{
	JournlerJournal *journal;
	
	IBOutlet JournlerGradientView *gradientBackground;
	IBOutlet DropBoxFoldersController *sourceController;
	IBOutlet DropBoxSourceList *sourceList;
	
	IBOutlet NSTextField *titleField;
	IBOutlet NSTextField *noteField;
	IBOutlet NSButton *rememberFolderSelectionCheckbox;
	
	IBOutlet NSTokenField *tagsField;
	IBOutlet NSComboBox	*categoryField;
	
	IBOutlet NSButton *returnButton;
	IBOutlet NSButton *cancelButton;
	
	IBOutlet NSArrayController *filesController;
	IBOutlet NSTableView *filesTable;
	
	BOOL multipleFiles;
	BOOL canCancelImport;
	BOOL shouldDeleteOriginal;
	
	id delegate;
	id representedObject;
	NSArray *content;
	NSDictionary *activeApplication;
	
	NSInteger mode;
	SEL didEndSelector;
	
	NSArray *tags;
	NSString *category;
	
	NSArray *tagCompletions;
}

- (id) initWithJournal:(JournlerJournal*)aJournal delegate:(id)aDelegate mode:(NSInteger)dropboxMode didEndSelector:(SEL)aSelector;
- (void) _endWithCode:(NSInteger)code;

+ (NSArray*) contentForFilenames:(NSArray*)filenames;
+ (NSArray*) contentForEntries:(NSArray*)entries;

- (JournlerJournal*) journal;
- (void) setJournal:(JournlerJournal*)aJournal;

- (NSArray*)content;
- (void) setContent:(NSArray*)anArray;

- (id) representedObject;
- (void) setRepresentedObject:(id)anObject;

- (NSDictionary*) activeApplication;
- (void) setActiveApplication:(NSDictionary*)aDictionary;

- (BOOL) multipleFiles;
- (void) setMultipleFiles:(BOOL)multiple;

- (BOOL) canCancelImport;
- (void) setCanCancelImport:(BOOL)canCancel;

- (BOOL) shouldDeleteOriginal;
- (void) setShouldDeleteOriginal:(BOOL)deletesOriginal;

- (NSArray*) tagCompletions;
- (void) setTagCompletions:(NSArray*)anArray;

- (IBAction) runClose:(id)sender;
- (IBAction) doImport:(id)sender;

- (IBAction) changeFolderSelectionMemory:(id)sender;

- (void) fadeWindowOut:(id)sender;
- (void) fadeWindowIn:(id)sender;

- (NSArray*) tags;
- (void) setTags:(NSArray*)anArray;

- (NSString*) category;
- (void) setCategory:(NSString*)aCategory;

- (JournlerCollection*) selectedFolder;
- (NSArray*) selectedFolders;

@end

@interface NSObject (DropBoxDialogDelegate)

- (void) dropBox:(DropBoxDialog*)aDialog didAcceptContent:(NSArray*)content;
- (void) dropBox:(DropBoxDialog*)aDialog didDenyContent:(NSArray*)content;

@end