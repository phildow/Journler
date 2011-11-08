/* EntryInfoController */

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
@class JournlerEntry;

@interface EntryInfoController : NSWindowController
{
    // Main inteface
	
	IBOutlet NSTableView	*blogsTable;
    IBOutlet NSComboBox		*category;
    
    IBOutlet NSTextField	*location;
    IBOutlet NSTextField	*title;
	
	IBOutlet NSTextView		*comments;
	IBOutlet NSTokenField	*tags;
	
	IBOutlet LabelPicker	*label;
	
	IBOutlet NSObjectController *objectController;
	IBOutlet NSArrayController *blogListController;
	
	// Adding an Blog Record
	
	IBOutlet NSWindow		*addBlogSheet;
	IBOutlet NSPopUpButton	*addBlogType;
	IBOutlet NSComboBox		*addBlogName;
	IBOutlet NSTextField	*addBlogJournal;
	
	// Deleting a Blog Record
	
	IBOutlet NSWindow		*deleteBlogSheet;
	IBOutlet NSTextField	*deleteBlogType;
	IBOutlet NSTextField	*deleteBlogName;
	IBOutlet NSTextField	*deleteBlogJournal;
	
	IBOutlet NSDatePicker	*dateAndTime;
	
	NSString			*entryLocation;
	NSCalendarDate		*entryDate;
	NSCalendarDate		*entryDateDue;
	BOOL clearsDateDue;
	
	// entry is a weak reference while representedEntry is a copy
	// allows me to save or cancel changes made
	
	JournlerJournal *journal;
	JournlerEntry *entry;
	JournlerEntry *representedEntry;
	
	NSMutableArray *blogs;
	NSArray *tagCompletions;

}

- (NSString*) entryLocation;
- (void) setEntryLocation:(NSString*)string;

- (NSCalendarDate*) entryDate;
- (void) setEntryDate:(NSCalendarDate*)date;

- (NSCalendarDate*) entryDateDue;
- (void) setEntryDateDue:(NSCalendarDate*)date;

- (JournlerJournal*) journal;
- (void) setJournal:(JournlerJournal*)aJournal;

- (JournlerEntry*) entry;
- (void) setEntry:(JournlerEntry*)object;

- (JournlerEntry*) representedEntry;
- (void) setRepresentedEntry:(JournlerEntry*)object;

- (NSArray*) blogs;
- (void) setBlogs:(NSArray*)newBlogs;

- (NSArray*) tagCompletions;
- (void) setTagCompletions:(NSArray*)anArray;

- (BOOL) clearsDateDue;
- (void) setClearsDateDue:(BOOL)clears;

- (IBAction)addBlog:(id)sender;
- (IBAction)cancelChanges:(id)sender;
- (IBAction)editBlogList:(id)sender;
- (IBAction)removeBlog:(id)sender;
- (IBAction)saveChanges:(id)sender;
- (IBAction)showHelp:(id)sender;

- (IBAction) cancelBlogAdd:(id)sender;
- (IBAction) confirmBlogAdd:(id)sender;

- (IBAction) cancelBlogDelete:(id)sender;
- (IBAction) confirmBlogDelete:(id)sender;

@end
