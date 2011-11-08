//
//  FoldersController.m
//  Journler
//
//  Created by Philip Dow on 10/24/06.
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

#import "FoldersController.h"
#import "CollectionsSourceList.h"

#import "Definitions.h"

#import "JournlerCollection.h"
#import "JournlerEntry.h"
#import "JournlerJournal.h"

#import "NSAlert+JournlerAdditions.h"
#import "JournlerApplicationDelegate.h"
#import "EntriesTableView.h"

#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>

#define kSourceListFullHeight		28.0
#define kSourceListSmallHeight		20.0

@implementation FoldersController

- (id)initWithContent:(id)content
{	
	if ( self = [super initWithContent:content] )
	{
		smallRowHeight = kSourceListSmallHeight;
		fullRowHeight = kSourceListFullHeight;
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	if ( self = [super initWithCoder:decoder] )
	{
		smallRowHeight = kSourceListSmallHeight;
		fullRowHeight = kSourceListFullHeight;
	}
	return self;
}

- (void) awakeFromNib
{
	draggingEntries = NO;
	_draggedNodes = [[NSMutableArray alloc] init];
	
	[self bind:@"usesSmallFolderIcons" 
			toObject:[NSUserDefaultsController sharedUserDefaultsController]
			withKeyPath:@"values.SourceListUseSmallIcons" 
			options:[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithBool:NO], NSNullPlaceholderBindingOption, nil]];
			
	[self bind:@"showsEntryCount" 
			toObject:[NSUserDefaultsController sharedUserDefaultsController]
			withKeyPath:@"values.SourceListShowsEntryCount" 
			options:[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithBool:YES], NSNullPlaceholderBindingOption, nil]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
			selector:@selector(_folderDidChangeEntryContent:) 
			name:FolderDidAddEntryNotification 
			object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
			selector:@selector(_folderDidChangeEntryContent:) 
			name:FolderDidRemoveEntryNotification 
			object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
			selector:@selector(_folderDidChangeEntryContent:) 
			name:FolderDidCompleteEvaluation 
			object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
			selector:@selector(_entriesDidBeginDrag:) 
			name:EntriesTableViewDidBeginDragNotification 
			object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
			selector:@selector(_entriesDidEndDrag:) 
			name:EntriesTableViewDidEndDragNotification 
			object:nil];
	 
	[[NSNotificationCenter defaultCenter] addObserver:self 
			selector:@selector(journlerObjectValueDidChange:) 
			name:JournlerObjectDidChangeValueForKeyNotification 
			object:nil];

}

- (void) dealloc
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_draggedNodes release];
	[rootCollection release];
	
	#ifdef __DEBUG__
	NSLog(@"%s - ending",__PRETTY_FUNCTION__);
	#endif
	
	[super dealloc];
}

#pragma mark -

- (JournlerCollection*) rootCollection
{
	return rootCollection;
}

- (void) setRootCollection:(JournlerCollection*)aCollection
{
	if ( rootCollection != aCollection )
	{
		[rootCollection release];
		rootCollection = [aCollection retain];
	}
}

- (id) delegate
{
	return delegate;
}

- (void) setDelegate:(id)anObject
{
	delegate = anObject;
}

- (float) smallRowHeight
{
	return smallRowHeight;
}

- (void) setSmallRowHeight:(float)aValue
{
	if ( aValue > kSourceListSmallHeight )
		smallRowHeight = aValue + floor(aValue/4);
}

- (float) fullRowHeight
{
	return fullRowHeight;
}

- (void) setFullRowHeight:(float)aValue
{
	if ( aValue > kSourceListFullHeight )
		fullRowHeight = aValue + floor(aValue/4);
}

- (BOOL) usesSmallFolderIcons
{
	return usesSmallFolderIcons;
}

- (void) setUsesSmallFolderIcons:(BOOL)smallIcons
{
	usesSmallFolderIcons = smallIcons;
	[self rearrangeObjects];
}

- (BOOL) showsEntryCount
{
	return showsEntryCount;
}

- (void) setShowsEntryCount:(BOOL)entryCount
{
	showsEntryCount = entryCount;
	[self rearrangeObjects];
}

#pragma mark -

- (NSArray*)allObjects 
{
	// returns all of the objects available in the controller
	return [[self rootCollection] allChildren];
}

- (void) adjustRowHeightsFromFontSize:(float)aValue
{
	[self setSmallRowHeight:aValue];
	[self setFullRowHeight:aValue];
	[sourceList reloadData];
}

#pragma mark -
#pragma mark NSOutlineView Delegation

- (BOOL)selectionShouldChangeInOutlineView:(NSOutlineView *)outlineView 
{
	if ( delegate != nil && [delegate respondsToSelector:@selector(foldersController:willChangeSelection:)] )
		[delegate foldersController:self willChangeSelection:[self selectedObjects]];

	return YES;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification 
{
	if ( delegate != nil && [delegate respondsToSelector:@selector(foldersController:didChangeSelection:)] )
		[delegate foldersController:self didChangeSelection:[self selectedObjects]];
}


- (float)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item 
{
	// to support variable row heights in the outline view, available in 10.4 and later
	if ( [self usesSmallFolderIcons] )
		return [self smallRowHeight];
	else {
		
		JournlerCollection *actualItem; 
		// necessary hack to get around NSTreeController proxy object, 10.5 compatible
		if ( [item respondsToSelector:@selector(representedObject)] )
			actualItem = [item representedObject];
		else if ( [item respondsToSelector:@selector(observedObject)] )
			actualItem = [item observedObject];
		else
			actualItem = item;
		
		if ( [actualItem valueForKey:@"parent"] == [self rootCollection] )
			return [self fullRowHeight];
		else
			return [self smallRowHeight];
	}
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item 
{
	
	if ([[tableColumn identifier] isEqualToString: @"title"]) 
	{
		// Set the image here since the value returned from 
		// outlineView:objectValueForTableColumn:... didn't specify the image part...
		
		JournlerCollection *actualItem; 
		// necessary hack to get around NSTreeController proxy object, 10.5 compatible
		if ( [item respondsToSelector:@selector(representedObject)] )
			actualItem = [item representedObject];
		else if ( [item respondsToSelector:@selector(observedObject)] )
			actualItem = [item observedObject];
		else
			actualItem = item;
		
		// set the image
		[(ImageAndTextCell*)cell setImage:[actualItem valueForKey:@"icon"]];
		// evaluating
		[(ImageAndTextCell*)cell setUpdating:[actualItem isEvaluating]];
		
		// count - if requested by preference
		if ( [self showsEntryCount] )
			[(ImageAndTextCell*)cell setContentCount:[[actualItem entries] count]];
		else
			[(ImageAndTextCell*)cell setContentCount:-1];
		
		// selection (so color can determine colors, font, etc)
		[(ImageAndTextCell*)cell setSelected:( [[outlineView selectedRowIndexes] containsIndex:[outlineView rowForItem:item]] )];
		
		// dim (indicates accepts drag)
		if ( draggingEntries == YES && [actualItem isSmartFolder] && ![actualItem canAutotag:nil] )
			[(ImageAndTextCell*)cell setDim:YES];
		else
			[(ImageAndTextCell*)cell setDim:NO];
		
		// let the cell know what size of image to use
		if ( [self usesSmallFolderIcons] )
			[(ImageAndTextCell*)cell setImageSize:NSMakeSize(kSourceListSmallHeight,kSourceListSmallHeight)];
		else
			[(ImageAndTextCell*)cell setImageSize:( [actualItem valueForKey:@"parent"] == [self rootCollection] ? 
					NSMakeSize(kSourceListFullHeight,kSourceListFullHeight) : 
					NSMakeSize(kSourceListSmallHeight,kSourceListSmallHeight) )];
		
		// shrink the font on the cell by floor (4/5) if this is a subfolder
		/*
		[(ImageAndTextCell*)cell setFont: ( [actualItem valueForKey:@"parent"] == [self rootCollection] ? 
				[outlineView font] : 
				[[NSFontManager sharedFontManager] convertFont:[outlineView font] 
				toSize:[[outlineView font] pointSize] - ( floor([[outlineView font] pointSize] / 5 ))] ) ];
		*/
				
	}
}

- (NSString *)outlineView:(NSOutlineView *)ov toolTipForCell:(NSCell *)cell 
		rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tc item:(id)item mouseLocation:(NSPoint)mouseLocation
{
	return [cell stringValue];	
}

#pragma mark -
#pragma mark Navigation Events

- (void) outlineView:(NSOutlineView*)anOutlineView leftNavigationEvent:(NSEvent*)anEvent
{
	if ( [[self delegate] respondsToSelector:@selector(outlineView:leftNavigationEvent:)] )
		[[self delegate] outlineView:anOutlineView leftNavigationEvent:anEvent];
}

- (void) outlineView:(NSOutlineView*)anOutlineView rightNavigationEvent:(NSEvent*)anEvent
{
	if ( [[self delegate] respondsToSelector:@selector(outlineView:rightNavigationEvent:)] )
		[[self delegate] outlineView:anOutlineView rightNavigationEvent:anEvent];
}

#pragma mark -

- (BOOL) sourceList:(CollectionsSourceList*)aSourceList didSelectRowAlreadySelected:(NSInteger)aRow event:(NSEvent*)mouseEvent
{
	if ( [[self delegate] respondsToSelector:@selector(sourceList:didSelectRowAlreadySelected:event:)] )
		return [[self delegate] sourceList:aSourceList didSelectRowAlreadySelected:aRow event:mouseEvent];
	else
		return NO;
}

#pragma mark -
#pragma mark Dummy NSOutlineView Data Source


- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item 
{
	return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item 
{
	return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item 
{
	return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView 
		objectValueForTableColumn:(NSTableColumn *)tableColumn 
		byItem:(id)item 
{
	return nil;
}

#pragma mark -
#pragma mark OutlineView Drag and Drop

- (BOOL)outlineView:(NSOutlineView *)outlineView 
		writeItems:(NSArray *)items 
		toPasteboard:(NSPasteboard *)pboard 
{	
	NSInteger i;
	BOOL canWrite = YES;
	NSMutableArray *folderURIs = [NSMutableArray array];
	NSMutableArray *folderTitles = [NSMutableArray array];
	NSMutableArray *folderPromises = [NSMutableArray array];
	
	// references to the actual items are stored during the drag
	[_draggedNodes removeAllObjects];
	
	for ( i = 0; i < [items count]; i++ ) 
	{
		id item = [items objectAtIndex:i];
		JournlerCollection *actualItem;
		
		if ( [item respondsToSelector:@selector(representedObject)] )
			actualItem = [item representedObject];
		else if ( [item respondsToSelector:@selector(observedObject)] )
			actualItem = [item observedObject];
		else
			actualItem = item;
		
		if ( !([actualItem isRegularFolder] || [actualItem isSmartFolder]) ) 
		{
			canWrite = NO;
			break;
		}
		
		[folderURIs addObject:[[actualItem URIRepresentation] absoluteString]];
		[folderTitles addObject:[actualItem valueForKey:@"title"]];
		[folderPromises addObject:(NSString*)kUTTypeFolder];
		
		[_draggedNodes addObject:actualItem];
	}
	
	if ( !canWrite )
	{
		return NO;
	}
	else 
	{
		id firstItem = [items objectAtIndex:0];
		JournlerCollection *actualFirstItem;
		
		if ( [firstItem respondsToSelector:@selector(representedObject)] )
			actualFirstItem = [firstItem representedObject];
		else if ( [firstItem respondsToSelector:@selector(observedObject)] )
			actualFirstItem = [firstItem observedObject];
		else
			actualFirstItem = firstItem;
		
		// prepare the favorites dictionary
		NSDictionary *favoritesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				[actualFirstItem valueForKey:@"title"], PDFavoriteName, 
				[[actualFirstItem URIRepresentation] absoluteString], PDFavoriteID, nil];
		
		// prepare the web urls
		NSArray *webURLs = [NSArray arrayWithObjects:folderURIs, folderTitles, nil];
		
		// declare the types
		NSArray *pboardTypes = [NSArray arrayWithObjects: 
				PDFolderIDPboardType, NSFilesPromisePboardType,
				PDFavoritePboardType, WebURLsWithTitlesPboardType, 
				NSURLPboardType, NSStringPboardType, nil];
				
		[pboard declareTypes:pboardTypes owner:self];
		
		// write the data to the pasteboard
		[pboard setPropertyList:folderURIs forType:PDFolderIDPboardType];
		[pboard setPropertyList:folderPromises forType:NSFilesPromisePboardType];
		[pboard setPropertyList:favoritesDictionary forType:PDFavoritePboardType];
		[pboard setPropertyList:webURLs forType:WebURLsWithTitlesPboardType];
		
		[[actualFirstItem URIRepresentation] writeToPasteboard:pboard];
		[pboard setString:[actualFirstItem URIRepresentationAsString] forType:NSStringPboardType];
		
		return YES;
	}
}

- (NSArray *)outlineView:(NSOutlineView *)outlineView 
		namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination 
		forDraggedItems:(NSArray *)items
{
	if ( ![dropDestination isFileURL] ) 
		return nil;
	
	NSInteger i;
	NSMutableArray *titles = [[NSMutableArray alloc] init];
	NSString *destinationPath = [dropDestination path];
	
	for ( i = 0; i < [items count]; i++ ) 
	{
		JournlerCollection *actualItem;
		id anItem = [items objectAtIndex:i];
		
		if ( [anItem respondsToSelector:@selector(representedObject)] )
			actualItem = [anItem representedObject];
		else if ( [anItem respondsToSelector:@selector(observedObject)] )
			actualItem = [anItem observedObject];
		else
			actualItem = anItem;

		[actualItem writeEntriesToFolder:destinationPath 
				format:kEntrySaveAsRTFD 
				considerChildren:YES 
				includeHeaders:YES];
		
		[titles addObject:[actualItem valueForKey:@"title"]];
	}
	
	[titles release];
	return [NSArray array];

}

#pragma mark -

- (BOOL)outlineView:(NSOutlineView *)outlineView 
		acceptDrop:(id <NSDraggingInfo>)info 
		item:(id)item 
		childIndex:(NSInteger)index 
{
	BOOL accepted = YES;
	JournlerCollection *actualItem;
	JournlerJournal *myJournal = [self valueForKeyPath:@"delegate.journal"];
	NSPasteboard *pboard = [info draggingPasteboard];
	NSArray *types = [[info draggingPasteboard] types];
	
	if ( item == nil )
		actualItem = [self valueForKey:@"rootCollection"];
	else if ( [item respondsToSelector:@selector(representedObject)] )
		actualItem = [item representedObject];
	else if ( [item respondsToSelector:@selector(observedObject)] )
		actualItem = [item observedObject];
	else
		actualItem = item;
	
	// moving folders around
	if ( [types containsObject:PDFolderIDPboardType] || [info draggingSource] == sourceList ) 
	{
		// grab the folders from the pasteboard and make them children of the targeted folder
		NSInteger i;
		NSArray *folderURIs = [pboard propertyListForType:PDFolderIDPboardType];
		NSArray *selectedFolders = [NSArray arrayWithArray:[self selectedObjects]];
		
		// adjust the index value so that we're adding after the last add 
		//	1. when the parents are not the same
		//	2. when we're moving folders up in the list rather than down
		NSInteger indexAdjust = 0;
		BOOL adjustingIndex = NO;
		
		NSDragOperation op = [info draggingSourceOperationMask];
		
		// deselect the current selection
		[sourceList deselectAll:self];
		
		for ( i = 0; i < [folderURIs count]; i++ ) 
		//for ( i = [folderURIs count] - 1; i >= 0; i-- ) 
		{
			
			NSString *absoluteString = [folderURIs objectAtIndex:i];
			NSURL *uri = [NSURL URLWithString:absoluteString];
			
			JournlerCollection *aFolder = [myJournal objectForURIRepresentation:uri];
			
			if ( aFolder != nil ) 
			{
				if ( op == NSDragOperationCopy )
				{
					// copy folder operation - duplicate, new tag, add to parent, re-evaluate if smart
					
					// note if the folder belonged to a smart family
					BOOL wasMemberOfSmartFamily = [aFolder isMemberOfSmartFamilyConsideringSelf:YES];
					
					// get the new folder
					JournlerCollection *newFolder = [[aFolder copyWithZone:[self zone]] autorelease];
					
					// add to new parent
					[actualItem addChild:newFolder atIndex:index];
					
					// if the folder did belong or now does belong to a smart family, re-evaluate contents
					if ( wasMemberOfSmartFamily || [newFolder isMemberOfSmartFamilyConsideringSelf:YES] )
					{
						[newFolder invalidatePredicate:YES];
						[newFolder evaluateAndAct:[myJournal valueForKey:@"entries"] considerChildren:YES];
						
						// save the affected folder's children
                        for ( JournlerCollection *aChildFolder in [newFolder allChildren] )
							[[aChildFolder journal] saveCollection:aChildFolder];
					}
						
					// save the affected folder and its children
					[[newFolder journal] addCollection:newFolder];
					[[newFolder journal] saveCollection:newFolder];
					
					// reset the root folders after each pass
					[myJournal setRootFolders:[myJournal rootFolders]];
				}
				else
				{
					// move the folder
					
					// retain the folder while it's being moved in and out of things
					[aFolder retain];
					
					// determine the folders parent
					JournlerCollection *aFoldersParent = [aFolder valueForKey:@"parent"];
					
					// if the drop target and the previous parent are the same, all we need to do is change the index
					if ( aFoldersParent == actualItem )
					{
						// reverse the order if we're moving this folder up and it's our first one
						if ( i == 0 && [[aFolder index] integerValue] > index )	// whoops! don't use integerValue unless Leopard only
							adjustingIndex = YES;
						
						// move the folder
						[aFoldersParent moveChild:aFolder toIndex:index+indexAdjust];
						// adjust the adjust
						if ( adjustingIndex ) indexAdjust++;
						
						// save the parents folders children, which includes the affected folder
                        for ( JournlerCollection *aChildFolder in [aFoldersParent allChildren] )
							[[aChildFolder journal] saveCollection:aChildFolder];
					}
					
					// if the drop and parent are not the same, remove, add and adjust smart families
					else
					{					
						// note if the folder belonged to a smart family
						BOOL wasMemberOfSmartFamily = [aFolder isMemberOfSmartFamilyConsideringSelf:YES];
						
						// remove the folder from its parent
						[aFoldersParent removeChild:aFolder recursively:NO];
						// add the folder to the new target item
						[actualItem addChild:aFolder atIndex:index+indexAdjust];
						// adjust the adjust
						indexAdjust++;
														
						// if the folder did belong or now does belong to a smart family, re-evaluate contents
						if ( wasMemberOfSmartFamily || [aFolder isMemberOfSmartFamilyConsideringSelf:YES] )
						{
							[aFolder invalidatePredicate:YES];
							[aFolder evaluateAndAct:[myJournal valueForKey:@"entries"] considerChildren:YES];
							
							// save the affected folder's children
							for ( JournlerCollection *aChildFolder in [aFolder allChildren] )
								[[aChildFolder journal] saveCollection:aChildFolder];
						}
						
						// save the affected folder and its children
						[[aFolder journal] saveCollection:aFolder];

					}
					
					// reset the root folders after each pass
					[myJournal setRootFolders:[myJournal rootFolders]];
					
					// release the folder now that the work is finished
					[aFolder release];
					
				}
			}
		}
		
		// save the affected folder and its children
		[[actualItem journal] saveCollection:actualItem];
		
        for ( JournlerCollection *aChildFolder in [actualItem allChildren] )
			[[aChildFolder journal] saveCollection:aChildFolder];
		
		// reselect the previously selected folder
		for ( i = 0; i < [selectedFolders count]; i++ )
			[self selectCollection:[selectedFolders objectAtIndex:i] byExtendingSelection:YES];
		
	}
	
	// moving entries into the folder 
	else if ( [types containsObject:PDEntryIDPboardType] ) 
	{
		// the entry ids as strings from the pboard
		NSArray *entryURIs = [pboard propertyListForType:PDEntryIDPboardType];
		
		NSInteger i;
		for ( i = 0; i < [entryURIs count]; i++ ) 
		{
			// conver the ids to actual entries
			NSString *absoluteString = [entryURIs objectAtIndex:i];
			NSURL *theURI = [NSURL URLWithString:absoluteString];
			
			JournlerEntry *anEntry = (JournlerEntry*)[myJournal objectForURIRepresentation:theURI];
			if ( anEntry != nil ) 
			{
				// add or remove the entry from the trash
				if ( ![actualItem isTrash] && [[anEntry valueForKey:@"markedForTrash"] boolValue] )
					[myJournal unmarkEntryForTrash:anEntry];
				else if ( [actualItem isTrash] && ![[anEntry valueForKey:@"markedForTrash"] boolValue] )
					[myJournal markEntryForTrash:anEntry];
				
				// add the entry to the folder
				if ( [actualItem isRegularFolder] )
					[actualItem addEntry:anEntry];
				else if ( [actualItem isSmartFolder] )
					[actualItem autotagEntry:anEntry add:YES];
					
				// save the entry
				[[anEntry journal] saveEntry:anEntry];
			}
		}
		
		// save the affected folder
		[[actualItem journal] saveCollection:actualItem];
	}
	
	else if ( [types containsObject:kMailMessagePboardType] )
	{
		accepted = YES;
		// run this after a delay as it screws up the drop loop when not
		NSDictionary *objectDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				pboard, @"pasteboard", 
				actualItem, @"folder", nil];
		
		[self performSelector:@selector(importPasteboardFromDictionary:) withObject:objectDictionary afterDelay:0.1];
	}
	
	// movings files - want to run an import
	else if ( [types containsObject:NSFilenamesPboardType] )
	{
		JournlerCollection *importFolder = ( [actualItem isRegularFolder] || [actualItem isSmartFolder] ? actualItem : nil );
		[[NSApp delegate] importFilesWithImporter:[pboard propertyListForType:NSFilenamesPboardType] folder:importFolder userInteraction:NO];
		
		// save the affected folder
		[[actualItem journal] saveCollection:actualItem];
	}
	
	else
	{
		[self importPasteboardData:pboard target:actualItem];
		// moving any other kind of data to the folder - import it
		
		// save the affected folder
		[[actualItem journal] saveCollection:actualItem];
	}
	
	return accepted;
}


- (NSDragOperation)outlineView:(NSOutlineView *)outlineView 
	validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index 
{
	NSDragOperation operation;
	JournlerCollection *actualItem;
	
	if ( [item respondsToSelector:@selector(representedObject)] )
		actualItem = [item representedObject];
	else if ( [item respondsToSelector:@selector(observedObject)] )
		actualItem = [item observedObject];
	else
		actualItem = item;
	
	if ( [info draggingSource] == sourceList ) 
	{
		// the drag is originating from our managed object
		
		// do not allow th drag to occur if the folder is being dragged inside itself
		if ( [actualItem isDescendantOfFolderInArray:_draggedNodes] )
			operation = NSDragOperationNone;
			
		// do not allow the drag to occur if the location is other than a regular or smart folder
		else if ( actualItem != nil && !( [actualItem isRegularFolder] || [actualItem isSmartFolder] ) )
			operation = NSDragOperationNone;
			
		else 
		{
			// permit the operation, retargeting as necessary
			if ( [info draggingSourceOperationMask] && ( GetCurrentKeyModifiers() & optionKey ) )
				operation = NSDragOperationCopy;
			else
				operation = NSDragOperationMove;
			
			if ( index == -1 ) 
			{
				// drop wants to occur on folder, retarget so that it is in the folder or after library & trash
				if ( actualItem == nil ) 
					[sourceList setDropItem:item dropChildIndex:2];
				else 
					[sourceList setDropItem:item dropChildIndex:0];
			}
			else 
			{
				// drop is already occuring inside the folder, retarget so after library and trash
				if ( actualItem == nil && index < 2 )
					[sourceList setDropItem:item dropChildIndex:2];
			}
		}
	}
	
	else 
	{
		// the drag is an entry or coming from elsewhere
		if ( index == -1 ) 
		{
			// a -1 childIndex means the drop is occuring on the proposedItem item
			NSPasteboard *pboard = [info draggingPasteboard];
			NSArray *types = [pboard types];
			BOOL hasEntries = [types containsObject:PDEntryIDPboardType];
			
			// #warning prevent drags to trash unless its an entry?
			
			if ( actualItem == nil )
				operation = NSDragOperationNone;
			else if ( [actualItem isSmartFolder] )
			{
				// could be made more sophisticated to take into account dragged uti and uti conditions
				operation = ( [actualItem canAutotag:nil] ? NSDragOperationCopy : NSDragOperationNone );
			}
			else if ( [actualItem isTrash] && !hasEntries )
				operation = NSDragOperationNone;
			else
				operation = NSDragOperationCopy;
		}
		else 
		{
			operation = NSDragOperationNone;		
		}
	}
	
	return operation;
}

#pragma mark -

- (void) importPasteboardFromDictionary:(NSDictionary*)aDictionary
{
	// just pass it on to the appropriate handler
	[self importPasteboardData:[aDictionary objectForKey:@"pasteboard"] target:[aDictionary objectForKey:@"folder"]];
}

- (void) importPasteboardData:(NSPasteboard*)pboard target:(JournlerCollection*)aCollection
{
	NSArray *pasteboardEntries = [[NSApp delegate] entriesForPasteboardData:pboard visual:NO preferredTypes:nil];
	
	if ( pasteboardEntries == nil )
	{
		NSBeep();
		[[NSAlert pasteboardImportFailure] runModal];
	}
	else
	{
		if ( [aCollection isRegularFolder] )
		{
			for ( JournlerEntry *pasteboardEntry in pasteboardEntries )
				[aCollection addEntry:pasteboardEntry];
		}
		else if ( [aCollection isSmartFolder] )
		{
			for ( JournlerEntry *pasteboardEntry in pasteboardEntries )
				[aCollection autotagEntry:pasteboardEntry add:YES];
		}
		else
		{
			NSLog(@"%s - attempting to add import to something other than a regular folder", __PRETTY_FUNCTION__);
		}
	}

}

#pragma mark -

- (IBAction) exposeAllFolders:(id)sender
{
    for ( JournlerCollection *aFolder in [[self rootCollection] children] )
		[sourceList expandItem:[sourceList itemAtRow:[sourceList rowForOriginalItem:aFolder]] expandChildren:NO];
}


- (BOOL) selectCollection:(JournlerCollection*)aCollection byExtendingSelection:(BOOL)extend
{
	if ( aCollection != nil && [aCollection isKindOfClass:[JournlerCollection class]] ) 
	{
		// expand the columns so that this guy is visible
		JournlerCollection *nodeWantsVisibility = aCollection;
		NSMutableArray *nodesToExpand = [[[NSMutableArray alloc] init] autorelease];
		
		while ( nodeWantsVisibility = [nodeWantsVisibility parent] ) 
		{
			if ( nodeWantsVisibility == [self rootCollection] )
				break;
			
			[nodesToExpand addObject:nodeWantsVisibility];
			
			if ( [sourceList rowForOriginalItem:nodeWantsVisibility] != -1 )
				break;
		}
		
		NSInteger i;
		for ( i = [nodesToExpand count] - 1; i >= 0; i-- )
		{
			NSUInteger aRow = [sourceList rowForOriginalItem:[nodesToExpand objectAtIndex:i]];
			id treeNode = [sourceList itemAtRow:aRow];
			[sourceList expandItem:treeNode expandChildren:NO];
			
			//[sourceList expandItem:[nodesToExpand objectAtIndex:i] expandChildren:NO];
		}
		
		[sourceList selectRowIndexes:[NSIndexSet indexSetWithIndex:
		[sourceList rowForOriginalItem:aCollection]] byExtendingSelection:extend];
	}
	else 
	{
		[sourceList selectItems:nil byExtendingSelection:NO];
	}
	return YES;
}

#pragma mark -

- (IBAction) deleteSelectedFolder:(id)sender
{
	if ( [delegate respondsToSelector:@selector(deleteSelectedFolder:)] )
		[delegate performSelector:@selector(deleteSelectedFolder:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (IBAction) renameFolder:(id)sender
{
	if ( [[self delegate] respondsToSelector:@selector(renameFolder:)] )
		[delegate performSelector:@selector(renameFolder:) withObject:sender];
	else
		NSBeep();
}
- (IBAction) editSmartFolder:(id)sender
{
	if ( [[self delegate] respondsToSelector:@selector(editSmartFolder:)] )
		[delegate performSelector:@selector(editSmartFolder:) withObject:sender];
	else
		NSBeep();
}

- (IBAction) getFolderInfo:(id)sender
{
	if ( [[self delegate] respondsToSelector:@selector(getFolderInfo:)] )
		[delegate performSelector:@selector(getFolderInfo:) withObject:sender];
	else
		NSBeep();
}

- (IBAction) emptyTrash:(id)sender
{
	if ( [[self delegate] respondsToSelector:@selector(emptyTrash:)] )
		[delegate performSelector:@selector(emptyTrash:) withObject:sender];
	else
		NSBeep();
}

- (IBAction) editFolderLabel:(id)sender
{
	if ( [[self delegate] respondsToSelector:@selector(editFolderLabel:)] )
		[delegate performSelector:@selector(editFolderLabel:) withObject:sender];
	else
		NSBeep();
}

- (IBAction) editFolderProperty:(id)sender
{
	if ( [[self delegate] respondsToSelector:@selector(editFolderProperty:)] )
		[delegate performSelector:@selector(editFolderProperty:) withObject:sender];
	else
		NSBeep();
}

- (IBAction) selectFolderFromMenu:(id)sender
{
	if ( [[self delegate] respondsToSelector:@selector(selectFolderFromMenu:)] )
		[delegate performSelector:@selector(selectFolderFromMenu:) withObject:sender];
	else
		NSBeep();
}

#pragma mark -

- (IBAction) showColorPickerToChangeFolderColor:(id)sender
{
	[[sourceList window] makeFirstResponder:sourceList];
	[[NSColorPanel sharedColorPanel] setColor:[sourceList backgroundColor]];
	[NSApp orderFrontColorPanel:sender];
}

- (void) journlerObjectValueDidChange:(NSNotification*)aNotification
{
	JournlerObject *theObject = [aNotification object];
	if ( [theObject isKindOfClass:[JournlerCollection class]] 
		&& [[[aNotification userInfo] objectForKey:JournlerObjectAttributeKey] isEqualToString:JournlerObjectAttributeLabelKey] )
	{
		NSInteger theRow = [sourceList rowForOriginalItem:theObject];
		if ( theRow != -1 )
			[sourceList setNeedsDisplayInRect:[sourceList rectOfRow:theRow]];
	}
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	BOOL enabled = YES;
	NSInteger tag = [menuItem tag];
	SEL action = [menuItem action];
	NSUInteger selectionCount;
	
    NSMutableArray *actualFolders = [NSMutableArray arrayWithCapacity:[[self selectedObjects] count]];
   
    for ( id anObject in [self selectedObjects] )
	{
		if ( [anObject respondsToSelector:@selector(representedObject)] )
			[actualFolders addObject:[anObject representedObject]];
		if ( [anObject respondsToSelector:@selector(observedObject)] )
			[actualFolders addObject:[anObject observedObject]];
		else
			[actualFolders addObject:anObject];
	}
	
	selectionCount = [actualFolders count];
	
	if ( action == @selector( renameFolder: ) )
		enabled = ( selectionCount != 0 );
	
	else if ( action == @selector( getFolderInfo: ) )
		enabled = ( selectionCount != 0 );
	
	else if ( action == @selector( emptyTrash: ) )
		enabled = ( [[[(JournlerJournal*)[[self delegate] journal] trashCollection] entries] count] != 0 );
	
	else if ( action == @selector(selectFolderFromMenu:) && tag == 241 ) 
	{
		if ( actualFolders == nil || [actualFolders count] != 1 || [[actualFolders objectAtIndex:0] childrenCount] == 0 )
			enabled = NO;
		else
		{
			[menuItem setSubmenu:[[actualFolders objectAtIndex:0] 
			menuRepresentation:self action:@selector(selectFolderFromMenu:) smallImages:NO includeEntries:NO]];
		}
	}
	
	else if ( action == @selector(deleteSelectedFolder:) )
	{
		if ( selectionCount == 0 )
			enabled = NO;
		else
		{
			for ( JournlerCollection *aFolder in actualFolders )
			{
				if ( [aFolder isTrash] || [aFolder isLibrary] )
				{
					enabled = NO;
					break;
				}
			}
		}
	}
	
	else if ( action == @selector(editSmartFolder:) )
	{
		enabled = ( [actualFolders count] == 1 && [[actualFolders objectAtIndex:0] isSmartFolder] );
	}
	
	else if ( action == @selector(editFolderLabel:) )
	{
		NSUInteger entryCount = [[self selectedObjects] count];
		enabled = ( entryCount > 0 );
		
		if ( tag == 0 )
			[menuItem setState:NSOffState];
		else
		{
			// set the state
			[menuItem setState: [[[self selectedObjects] valueForKey:@"label"] stateForInteger:tag] ];
			
			// set the title -- would bind but does not work in Leopard 10.5.2 at the very least
			NSString *defaultsKey = [NSString stringWithFormat:@"LabelName%i",tag];
			NSString *itemTitle = [[NSUserDefaults standardUserDefaults] stringForKey:defaultsKey];
			if ( itemTitle != nil ) [menuItem setTitle:itemTitle];
		}
	}
	
	return enabled;
}

#pragma mark -

- (void) _smartFolderBeganEvaluation:(NSNotification*)aNotification
{
	JournlerCollection *theFolder = [aNotification object];
	NSInteger theRow = [sourceList rowForOriginalItem:theFolder];
	
	if ( theRow != -1 )
	{
		// check for visibility
		//NSRect rowFrame = [sourceList rectOfRow:theRow];
		[sourceList setNeedsDisplayInRect:[sourceList frameOfCellAtColumn:0 row:theRow]];
				
	}
}

- (void) _smartFolderCompletedEvalutation:(NSNotification*)aNotification
{
	JournlerCollection *theFolder = [aNotification object];
	NSInteger theRow = [sourceList rowForOriginalItem:theFolder];
	
	if ( theRow != -1 )
	{
		// check for visibility
		//NSRect rowFrame = [sourceList rectOfRow:theRow];
		[sourceList setNeedsDisplayInRect:[sourceList frameOfCellAtColumn:0 row:theRow]];
				
	}
}

- (void) _folderDidChangeEntryContent:(NSNotification*)aNotification
{
	JournlerCollection *theFolder = [aNotification object];
	NSInteger theRow = [sourceList rowForOriginalItem:theFolder];
	
	if ( theRow != -1 )
	{
		// check for visibility
		//NSRect rowFrame = [sourceList rectOfRow:theRow];
		[sourceList setNeedsDisplayInRect:[sourceList frameOfCellAtColumn:0 row:theRow]];
				
	}
}

- (void) _entriesDidBeginDrag:(NSNotification*)aNotification
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	if ( [sourceList window] != nil )
	{
		draggingEntries = YES;
		[sourceList setNeedsDisplay:YES];
	}
}

- (void) _entriesDidEndDrag:(NSNotification*)aNotification
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	if ( [sourceList window] != nil )
	{
		draggingEntries = NO;
		[sourceList setNeedsDisplay:YES];
	}
}

@end
