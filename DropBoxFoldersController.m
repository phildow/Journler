//
//  DropBoxFoldersController.m
//  Journler
//
//  Created by Philip Dow on 3/15/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import "DropBoxFoldersController.h"
#import "JournlerCollection.h"

#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>

#define kSourceListFullHeight		28.0
#define kSourceListSmallHeight		20.0

@implementation DropBoxFoldersController

- (void) awakeFromNib
{
	draggingEntries = NO;
	_draggedNodes = [[NSMutableArray alloc] init];
	
	[self bind:@"usesSmallFolderIcons" toObject:[NSUserDefaultsController sharedUserDefaultsController]
			withKeyPath:@"values.SourceListUseSmallIcons" options:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithBool:NO], NSNullPlaceholderBindingOption, nil]];
			
	//[self bind:@"showsEntryCount" toObject:[NSUserDefaultsController sharedUserDefaultsController]
	//		withKeyPath:@"values.SourceListShowsEntryCount" options:[NSDictionary dictionaryWithObjectsAndKeys:
	//		[NSNumber numberWithBool:YES], NSNullPlaceholderBindingOption, nil]];
	
	[self setShowsEntryCount:NO];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	JournlerCollection *actualItem; 
	// necessary hack to get around NSTreeController proxy object, 10.5 compatible
	if ( [item respondsToSelector:@selector(representedObject)] )
		actualItem = [item representedObject];
	else if ( [item respondsToSelector:@selector(observedObject)] )
		actualItem = [item observedObject];
	else
		actualItem = item;
	
	if ( [actualItem isTrash] || [actualItem isLibrary] || ( [actualItem isSmartFolder] && ![actualItem canAutotag:nil] ) )
	{
		[outlineView performSelector:@selector(deselectAll:) withObject:self afterDelay:0.2];
		return NO;
	}
	else
		return YES;
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
		if ( [actualItem isTrash] || [actualItem isLibrary] || ( [actualItem isSmartFolder] && ![actualItem canAutotag:nil] ) )
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


@end
