//
//  IndexBrowser.h
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

@class IndexNode;
@class IndexColumn;

@interface IndexBrowser : NSView {
	
	NSArray *columns;
	IndexColumn *focusedColumn;
	id delegate;
}

- (NSArray*) columns;
- (void) setColumns:(NSArray*)anArray;

- (id) delegate;
- (void) setDelegate:(id)anObject;

- (void) setInitialContent:(NSArray*)anArray;
- (void) setContentAtIndex:(NSDictionary*)aDictionary;
- (BOOL) setContent:(NSArray*)anArray forColumnAtIndex:(NSUInteger)index;

- (float) minWidth;

- (IBAction) addColumn:(id)sender;
- (IBAction) removeColumn:(id)sender;

- (IndexColumn*) focusedColumn;
- (NSArray*) focusedNodes;

- (void) columnFrameDidChange:(NSNotification*)aNotification;
- (void) columnWillResize:(NSNotification*)aNotification;
- (void) columnDidResize:(NSNotification*)aNotification;

@end

@interface NSObject (IndexBrowserDelegate)

// the represented object or selection in this methods is the selection in the column anIndex + 1
// both the represented object and the column index indicate items previous to those about to be displayed

// the selection will be nil and the represented object -1 if the browser is asking for information for the first column

- (NSArray*) browser:(IndexBrowser*)aBrowser contentForNodes:(NSArray*)selectedNodes atColumnIndex:(NSUInteger)anIndex;
- (void) browser:(IndexBrowser*)aBrowser column:(IndexColumn*)aColumn didChangeSelection:(NSArray*)selectedNode lastSelection:(IndexNode*)aNode;

- (NSString*) browser:(IndexBrowser*)aBrowser titleForNode:(IndexNode*)selectedNode atColumnIndex:(NSUInteger)anIndex;
- (NSString*) browser:(IndexBrowser*)aBrowser headerTitleForNode:(IndexNode*)selectedNode atColumnIndex:(NSUInteger)anIndex;

- (NSString*) browser:(IndexBrowser*)aBrowser countSuffixForNode:(IndexNode*)selectedNode atColumnIndex:(NSUInteger)anIndex;
- (NSArray*) browser:(IndexBrowser*)aBrowser sortDescriptorsForNode:(IndexNode*)selectedNode atColumnIndex:(NSUInteger)anIndex;

- (NSMenu*) browser:(IndexBrowser*)aBrowser contextMenuForNode:(IndexNode*)selectedNode atColumnIndex:(NSUInteger)anIndex;
- (float) browser:(IndexBrowser*)aBrowser rowHeightForNode:(IndexNode*)selectedNode atColumnIndex:(NSUInteger)anIndex;

- (BOOL) browser:(IndexBrowser*)aBrowser columnForNodeDrawsIcon:(IndexNode*)selectedNode atColumnIndex:(NSUInteger)anIndex;
- (BOOL) browser:(IndexBrowser*)aBrowser columnForNodeShowsCount:(IndexNode*)selectedNode atColumnIndex:(NSUInteger)anIndex;
- (BOOL) browser:(IndexBrowser*)aBrowser columnForNodeShowsFrequency:(IndexNode*)selectedNode atColumnIndex:(NSUInteger)anIndex;

- (BOOL) browser:(IndexBrowser*)aBrowser columnForNodeAllowsMultipleSelection:(IndexNode*)selectedNode atColumnIndex:(NSUInteger)anIndex;
- (BOOL) browser:(IndexBrowser*)aBrowser columnForNodeCanDeleteContent:(IndexNode*)selectedNode atColumnIndex:(NSUInteger)anIndex;

- (BOOL) browser:(IndexBrowser*)aBrowser columnForNodeFiltersCount:(IndexNode*)selectedNode atColumnIndex:(NSUInteger)anIndex;
- (BOOL) browser:(IndexBrowser*)aBrowser columnForNodeFiltersTitle:(IndexNode*)selectedNode atColumnIndex:(NSUInteger)anIndex;

/*
- (NSString*) browser:(IndexBrowser*)aBrowser titleForSelection:(id)anObject atColumnIndex:(NSUInteger)anIndex;
- (NSString*) browser:(IndexBrowser*)aBrowser countSuffixForSelection:(id)anObject atColumnIndex:(NSUInteger)anIndex;
- (NSArray*) browser:(IndexBrowser*)aBrowser sortDescriptorsForSelection:(id)anObject atColumnIndex:(NSUInteger)anIndex;

- (BOOL) browser:(IndexBrowser*)aBrowser columnForRepresentedObjectDrawsIcon:(id)anObject atColumnIndex:(NSUInteger)anIndex;
- (BOOL) browser:(IndexBrowser*)aBrowser columnForRepresentedObjectShowsCount:(id)anObject atColumnIndex:(NSUInteger)anIndex;
- (BOOL) browser:(IndexBrowser*)aBrowser columnForRepresentedObjectShowsFrequency:(id)anObject atColumnIndex:(NSUInteger)anIndex;
*/

@end