//
//  QuickLinkArrayController.m
//  Journler
//
//  Created by Philip Dow on 2/15/06.
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

#import "QuickLinkArrayController.h"

#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>

/*
#import "NSString+PDStringAdditions.h"
#import "PDFavoritesBar.h"
*/

@implementation QuickLinkArrayController

#pragma mark -
#pragma mark Dragging Source

- (id) selectedObject {
	
	//
	// a simple utility method to return the selected object 
	// when the array controller can only have one selection anyway
	// - returns nil when no item is selected
	// - returns the object when it is selected
	//
	
	if ( [self selectionIndex] == NSNotFound )
		return nil;
	
	return [[self selectedObjects] objectAtIndex:0];
	
}

/*
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if ( [[aTableColumn identifier] isEqualToString:@"tags"] && [aCell respondsToSelector:@selector(_allTokenFieldAttachments)] )
	{
		NSArray *attachments = [aCell _allTokenFieldAttachments];
		if ( [attachments count] > 0 )
		{
			//[[[attachments objectAtIndex:0] attachmentCell] setDrawingStyle:2];
			NSLog( @"%i",[[[attachments objectAtIndex:0] attachmentCell] drawingStyle] );
		}
	}
}
*/

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard 
{
	
	NSArray *entries = [[self arrangedObjects] objectsAtIndexes:rowIndexes];
	
	NSInteger i;
	NSMutableArray *entryURIs = [NSMutableArray array];
	NSMutableArray *entryTitles = [NSMutableArray array];
	NSMutableArray *entryPromises = [NSMutableArray array];
	
	for ( i = 0; i < [entries count]; i++ ) 
	{
		JournlerEntry *anEntry = [entries objectAtIndex:i];
		
		[entryURIs addObject:[[anEntry URIRepresentation] absoluteString]];
		[entryTitles addObject:[anEntry valueForKey:@"title"]];
		[entryPromises addObject:(NSString*)kUTTypeFolder];
	}
	
	// prepare the favorites data
	NSDictionary *favoritesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
			[[entries objectAtIndex:0] valueForKey:@"title"], PDFavoriteName, 
			[[[entries objectAtIndex:0] URIRepresentation] absoluteString], PDFavoriteID, nil];
	
	// prepare the web urls
	NSArray *web_urls_array = [NSArray arrayWithObjects:entryURIs,entryTitles,nil];
	
	// declare the types
	NSArray *pboardTypes = 	[NSArray arrayWithObjects: PDEntryIDPboardType, NSFilesPromisePboardType, 
			PDFavoritePboardType, WebURLsWithTitlesPboardType, NSURLPboardType, nil];
	[pboard declareTypes:pboardTypes owner:self];
	
	[pboard setPropertyList:entryURIs forType:PDEntryIDPboardType];
	[pboard setPropertyList:entryPromises forType:NSFilesPromisePboardType];
	[pboard setPropertyList:favoritesDictionary forType:PDFavoritePboardType];
	[pboard setPropertyList:web_urls_array forType:WebURLsWithTitlesPboardType];
	
	// write the url for the first item to the pasteboard
	[[[entries objectAtIndex:0] URIRepresentation] writeToPasteboard:pboard];
	
	return YES;
}

- (NSArray *)tableView:(NSTableView *)aTableView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination 
		forDraggedRowsWithIndexes:(NSIndexSet *)indexSet 
{
	
	if ( ![dropDestination isFileURL] ) 
		return nil;
	
	NSInteger i;
	NSMutableArray *titles = [[NSMutableArray alloc] init];
	NSArray *entries = [[self arrangedObjects] objectsAtIndexes:indexSet];
	NSString *destinationPath = [dropDestination path];
	
	NSInteger flags = kEntrySetLabelColor;
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryExportIncludeHeader"] )
		flags |= kEntryIncludeHeader;
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryExportSetCreationDate"] )
		flags |= kEntrySetFileCreationDate;
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryExportSetModificationDate"] )
		flags |= kEntrySetFileModificationDate;

	for ( i = 0; i < [entries count]; i++ )
	{
		JournlerEntry *anEntry = [entries objectAtIndex:i];
		//NSString *filePath = [NSString stringWithFormat:@"%@ %@", [anEntry tagID], [anEntry pathSafeTitle]];
		//[anEntry writeToFile:[destinationPath stringByAppendingPathComponent:filePath] as:kEntrySaveAsRTFD flags:flags];
		//[titles addObject:filePath];
		NSString *completePath = [[destinationPath stringByAppendingPathComponent:[anEntry pathSafeTitle]] pathWithoutOverwritingSelf];
		[anEntry writeToFile:completePath as:kEntrySaveAsRTFD flags:flags];
		[titles addObject:completePath];
	}
	
	[titles release];
	return [NSArray array];
}



@end
