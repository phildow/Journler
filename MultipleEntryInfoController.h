/* MultipleEntryController */

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

@class LabelPicker;

@class BlogPref;
@class JournlerEntry;
@class JournlerJournal;

@interface MultipleEntryInfoController : NSWindowController
{
	//
	// properties will be filled with initial values and handled by the controller

	NSArray				*entries;
	JournlerJournal		*journal;
	
	NSString			*category;
	NSString			*keywords;
	NSDate				*calDate;
	NSDate				*eventDate;
	NSDate				*dateDue;
	NSDate				*calDateModified;
	NSArray				*tags;
	
	NSMutableArray		*blogs;
	
	int				marked;
	
	IBOutlet NSObjectController *objectController;
	IBOutlet NSArrayController	*blogListController;
	IBOutlet NSComboBox			*categoryCombo;
	
	IBOutlet LabelPicker		*label;
	IBOutlet NSTextField		*numField;
	
	// dates
	IBOutlet NSDatePicker 		*dateCreatedPicker;
	IBOutlet NSDatePicker		*dateDuePicker;
	IBOutlet NSDatePicker		*eventDatePicker;
	
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
	
	// keeping track of what to change
	BOOL	modifiedCat;
	BOOL	modifiedCalDate;
	BOOL	modifiedCalDateModified;
	BOOL	modifiedLabel;
	BOOL	modifiedMarked;
	BOOL	modifiedBlogs;
	BOOL	modifiedDateDue;
	BOOL	modifiedEventDate;
	
	BOOL	modifiedKeywords;
	BOOL	modifiedTags;
	
	BOOL clearsDateDue;
	NSArray *tagCompletions;
}

- (id) initWithEntries:(NSArray*)initialEntries;

- (NSArray*) entries;
- (void) setEntries:(NSArray*) newEntries;

- (JournlerJournal*)journal;
- (void) setJournal:(JournlerJournal*)aJournal;

- (NSArray*) tagCompletions;
- (void) setTagCompletions:(NSArray*)anArray;

- (void) updateViewValues;

//
// editing values

- (NSString*) category;
- (void) setCategory:(NSString*) newCategory;

- (NSString*) keywords;
- (void) setKeywords:(NSString*) newKeywords;

- (NSArray*) tags;
- (void) setTags:(NSArray*)anArray;

- (NSDate*) calDate;
- (void) setCalDate:(NSDate*)newCalDate;

- (NSDate*) dateDue;
- (void) setDateDue:(NSDate*)newCalDate;

- (NSDate*) eventDate;
- (void) setEventDate:(NSDate*)newCalDate;

- (NSDate*) calDateModified;
- (void) setCalDateModified:(NSDate*)newCalDateModified;

- (NSArray*) blogs;
- (void) setBlogs:(NSArray*)theBlogs;

- (NSInteger) marked;
- (void) setMarked:(NSInteger)newMark;

- (BOOL) clearsDateDue;
- (void) setClearsDateDue:(BOOL)clears;

#pragma mark -

- (BOOL) modifiedCat;
- (void) setModifiedCat:(BOOL)modified;

- (BOOL) modifiedKeywords;
- (void) setModifiedKeywords:(BOOL)modified;

- (BOOL) modifiedTags;
- (void) setModifiedTags:(BOOL)modified;

- (BOOL) modifiedCalDate;
- (void) setModifiedCalDate:(BOOL)modified;

- (BOOL) modifiedCalDateModified;
- (void) setModifiedCalDateModified:(BOOL)modified;

- (BOOL) modifiedLabel;
- (void) setModifiedLabel:(BOOL)modified;

- (BOOL) modifiedMarked;
- (void) setModifiedMarked:(BOOL)modified;

- (BOOL) modifiedBlogs;
- (void) setModifiedBlogs:(BOOL)modified;

- (BOOL) modifiedDateDue;
- (void) setModifiedDateDue:(BOOL)modified;

- (BOOL) modifiedEventDate;
- (void) setModifiedEventDate:(BOOL)modified;

- (IBAction)activateProperty:(id)sender;

- (IBAction)addBlog:(id)sender;
- (IBAction)editBlogList:(id)sender;
- (IBAction)removeBlog:(id)sender;

- (IBAction) cancelBlogAdd:(id)sender;
- (IBAction) confirmBlogAdd:(id)sender;

- (IBAction) cancelBlogDelete:(id)sender;
- (IBAction) confirmBlogDelete:(id)sender;

- (IBAction)cancelChanges:(id)sender;
- (IBAction)saveChanges:(id)sender;

@end
