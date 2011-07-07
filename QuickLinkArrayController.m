//
//  QuickLinkArrayController.m
//  Journler
//
//  Created by Philip Dow on 2/15/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

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
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
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
	
	int i;
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
	
	int i;
	NSMutableArray *titles = [[NSMutableArray alloc] init];
	NSArray *entries = [[self arrangedObjects] objectsAtIndexes:indexSet];
	NSString *destinationPath = [dropDestination path];
	
	int flags = kEntrySetLabelColor;
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
