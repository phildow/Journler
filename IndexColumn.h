//
//  IndexColumn.h
//  Journler
//
//  Created by Philip Dow on 2/6/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
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

#define kIndexColumnSmallRowHeight 14
#define kIndexColumnLargeRowHeight 32
#define kIndexColumnMediumRowHeight 22

@class IndexNode;
@class IndexColumnView;
@class IndexTreeController;

@class PDGradientView;

@interface IndexColumn : NSObject {
	
	IBOutlet IndexColumnView *columnView;
	IBOutlet NSOutlineView *outlineView;
	IBOutlet NSTextField *titleField;
	IBOutlet NSSearchField *searchField;
	IBOutlet NSButton *searchCheck;
	
	IBOutlet NSTextField *minField;
	IBOutlet NSTextField *maxField;
	IBOutlet NSButton *countCheck;
	
	IBOutlet NSObjectController *ownerController;
	IBOutlet IndexTreeController *outlineController;
	IBOutlet NSArrayController *rootController;
	
	IBOutlet NSProgressIndicator *indicator;
	
	IBOutlet PDGradientView *footer;
	IBOutlet PDGradientView *header;
	
	id delegate;
	
	BOOL drawsIcon;
	BOOL showsCount;
	BOOL showsFrequency;
	
	NSString *title;
	NSString *headerTitle;
	NSString *countSuffix;
	NSPredicate *filterPredicate;
	
	NSInteger minCount;
	NSInteger maxCount;
	
	BOOL canDeleteContent;
	BOOL canFilterCount;
	BOOL canFilterTitle;
	
	BOOL countFilterEnabled;
	BOOL titleFilterEnabled;
}

- (IndexColumnView*) columnView;

- (IndexNode*) selectedObject;
- (NSArray*) selectedObjects;

- (NSArray*) content;
- (void) setContent:(NSArray*)content;

- (NSArray*) sortDescriptors;
- (void) setSortDescriptors:(NSArray*)anArray;

- (BOOL) allowsMultipleSelection;
- (void) setAllowsMultipleSelection:(BOOL)flag;

- (float) rowHeight;
- (void) setRowHeight:(float)height;

- (NSMenu*) menu;
- (void) setMenu:(NSMenu*)aMenu;

- (NSString*) title;
- (void) setTitle:(NSString*)aString;

- (NSString*) headerTitle;
- (void) setHeaderTitle:(NSString*)aString;

- (NSString*) countSuffix;
- (void) setCountSuffix:(NSString*)aString;

- (NSPredicate*) filterPredicate;
- (void) setFilterPredicate:(NSPredicate*)aPredicate;

- (BOOL) drawsIcon;
- (void) setDrawsIcon:(BOOL)draw;

- (BOOL) showsCount;
- (void) setShowsCount:(BOOL)show;

- (BOOL) showsFrequency;
- (void) setShowsFrequency:(BOOL)show;

- (id) delegate;
- (void) setDelegate:(id)anObject;

- (NSInteger) minCount;
- (void) setMinCount:(NSInteger)aCount;

- (NSInteger) maxCount;
- (void) setMaxCount:(NSInteger)aCount;

#pragma mark -

- (BOOL) canFilterCount;
- (void) setCanFilterCount:(BOOL)countFilters;

- (BOOL) canFilterTitle;
- (void) setCanFilterTitle:(BOOL)titleFilters;

- (BOOL) canDeleteContent;
- (void) setCanDeleteContent:(BOOL)canDelete;

#pragma mark -

- (BOOL) countFilterEnabled;
- (void) setCountFilterEnabled:(BOOL)enabled;

- (BOOL) titleFilterEnabled;
- (void) setTitleFilterEnabled:(BOOL)enabled;

#pragma mark -

- (void) ownerWillClose:(NSNotification*)aNotification;

- (BOOL) selectNode:(IndexNode*)aNode;
- (BOOL) scrollNodeToVisible:(IndexNode*)aNode;
- (BOOL) focusOutlineWithSelection:(BOOL)selectFirstNode;

- (void) determineCompoundPredicate;
- (IBAction) setCountRestriction:(id)sender;

@end

@interface NSObject (IndexColumnDelegate)

- (void) columnDidChangeSelection:(IndexColumn*)aColumn;
- (void) columnDidComeIntoFocus:(IndexColumn*)aColumn;
- (BOOL) indexColumn:(IndexColumn*)aColumn deleteSelectedRows:(NSIndexSet*)selectedRows nodes:(NSArray*)theNodes;

@end