//
//  WordDocumentController.m
//  Journler
//
//  Created by Philip Dow on 2/6/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "WordDocumentController.h"

#import "NSAlert+JournlerAdditions.h"
#import "IndexServerTextView.h"

#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>
/*
#import "NSWorkspace_PDCategories.h"
#import "NSString+PDStringAdditions.h"
#import "JournlerGradientView.h"
#import "PDPrintTextView.h"
#import "PDMediaBar.h"
#import "PDMediabarItem.h"
*/

@implementation WordDocumentController

- (id) init 
{
	if ( self = [super init] )
	{
		lastScale = 100;
		[NSBundle loadNibNamed:@"WordDocumentView" owner:self];
	}
	return self;
}

- (void) awakeFromNib
{
	[textView setInsertsLexiconContextSeparator:YES];
	[textView setTextContainerInset:NSMakeSize(5,5)];
	
	[super awakeFromNib];
}

#pragma mark -

- (BOOL) loadURL:(NSURL*)aURL 
{
	if ( ![aURL isFileURL] )
	{
		NSLog(@"%s - cannot load mail message from remote location %@", __PRETTY_FUNCTION__, aURL);
		NSBeep();
		[[NSAlert mediaError] runModal];
		return NO;
	}
	
	NSString *path = [aURL path];
	if ( ![[NSFileManager defaultManager] fileExistsAtPath:path] )
	{
		NSLog(@"%s - no message appears to exist for the specified file %@", __PRETTY_FUNCTION__, path);
		NSBeep();
		[[NSAlert mediaError] runModal];
		return NO;
	}
	
	// load depends on uti of file: NSDocFormatTextDocumentType ( com.microsoft.word.doc ), NSWordMLTextDocumentType ( ? )
	
	NSString *fileUTI = [[NSWorkspace sharedWorkspace] UTIForFile:path];
	if ( fileUTI == nil )
	{
		NSLog(@"%s - unable to determine uti for file at path %@", __PRETTY_FUNCTION__, path);
		NSBeep();
		[[NSAlert mediaError] runModal];
		return NO;
	}
	
	NSAttributedString *attributedContent = nil;
	
	if ( UTTypeConformsTo( (CFStringRef)fileUTI, (CFStringRef)@"com.microsoft.word.doc") )
	{
		attributedContent = [[[NSAttributedString alloc] initWithDocFormat:[NSData dataWithContentsOfFile:path] documentAttributes:nil] autorelease];
	}
	
	// if we have attributed content then we're good to go
	if ( attributedContent == nil )
	{
		NSLog(@"%s - unable to load content for file at path %@", __PRETTY_FUNCTION__, path);
		NSBeep();
		[[NSAlert mediaError] runModal];
		return NO;
	}
	
	[[textView textStorage] beginEditing];
	[[textView textStorage] setAttributedString:attributedContent];
	[[textView textStorage] endEditing];
	
	[super loadURL:aURL];
	return YES;
}

- (NSResponder*) preferredResponder
{
	return textView;
}

- (void) appropriateFirstResponder:(NSWindow*)window 
{
	[window makeFirstResponder:textView];
}

- (IBAction) printDocument:(id)sender
{
	// get the print info
	NSPrintInfo *modifiedInfo = [[[NSPrintInfo sharedPrintInfo] copyWithZone:[self zone]] autorelease];
	
	[modifiedInfo setHorizontalPagination:NSFitPagination];
	[modifiedInfo setHorizontallyCentered:NO];
	[modifiedInfo setVerticallyCentered:NO];
	[[modifiedInfo dictionary] setValue:[NSNumber numberWithBool:NO] forKey:NSPrintHeaderAndFooter];
	
	int width = [modifiedInfo paperSize].width - ( [modifiedInfo rightMargin] + [modifiedInfo leftMargin] );
	int height = [modifiedInfo paperSize].height - ( [modifiedInfo topMargin] + [modifiedInfo bottomMargin] );
	
	// create a view based on that information
	PDPrintTextView *printView = [[[PDPrintTextView alloc] initWithFrame:NSMakeRect(0,0,width,height)] autorelease];
	
	// set a few properties for the print job
	[printView setPrintTitle:nil];
	[printView setPrintHeader:NO];
	[printView setPrintFooter:NO];
	
	// set the content
	[[printView textStorage] beginEditing];
	[[printView textStorage] setAttributedString:[textView textStorage]];
	[[printView textStorage] endEditing];
	
	//grab the view to print and send it to the printer using the shared printinfo values
	[[NSPrintOperation printOperationWithView:printView printInfo:modifiedInfo] runOperation];
}


#pragma mark -

- (BOOL) handlesFindCommand
{
	// retargets the find panel action
	return YES;
}

- (void) performCustomFindPanelAction:(id)sender
{
	[[[self contentView] window] makeFirstResponder:textView];
	[textView performFindPanelAction:sender];
}

- (BOOL) highlightString:(NSString*)aString
{
	if ( aString == nil || [aString length] == 0 )
		return NO;
	
	BOOL schonScrolled = NO;
	NSString *aComponent;
	NSEnumerator *enumerator = [[aString componentsSeparatedByString:@" "] objectEnumerator];
	NSMutableArray *allRanges = [NSMutableArray array];
	
	while ( aComponent = [enumerator nextObject] )
	{
		// get the range of the string and highlight it
		NSArray *ranges = [[textView string] rangesOfString:aComponent options:NSCaseInsensitiveSearch range:NSMakeRange(0,[[textView string] length])];
		if ( ranges != nil && [ranges count] != 0 )
		{
			// put the term on the find clipboard, then highlight everywhere
			if ( !schonScrolled )
			{
				if ( [aComponent length] != 0 )
				{
					NSPasteboard *findBoard = [NSPasteboard pasteboardWithName:NSFindPboard];
					[findBoard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
					[findBoard setString:aComponent forType:NSStringPboardType];
				}
				schonScrolled = YES;
			}
			
			// store the ranges
			[allRanges addObjectsFromArray:ranges];
		}
	}
	
	if ( [allRanges count] > 0 )
	{
		// select the ranges
		[textView setSelectedRanges:allRanges];
		// scroll the first range to visible
		[textView scrollRangeToVisible:[[allRanges objectAtIndex:0] rangeValue]];
		return YES;
	}
	else
	{
		return NO;
	}
}

#pragma mark -

- (BOOL) handlesTextSizeCommand
{
	return YES;
}

- (void) performCustomTextSizeAction:(id)sender
{
	// zoom the text but taking into account last text size
	// 3 = larger, 4 = smaller, 5 = equal
	
	int i;
	int theTag = [sender tag];
	float scaleValue = -1;
	int theLastScale = (int)[self lastScale];
	static float scale[10] = { 10, 25, 50, 75, 100, 125, 150, 200, 400, 800 };
	
	if ( theTag == 99 )
		scaleValue = 100;
	
	else
	{
	
		for ( i = 0; i < 10; i++ )
		{
			if ( scale[i] == theLastScale )
			{
				if ( theTag == 3 && i != 9 )
					scaleValue = scale[i+1];
				else if ( theTag == 4 && i != 0 )
					scaleValue = scale[i-1];
				
				break;
			}
		}
	
	}
	
	if ( scaleValue < 0 )
	{
		// invalid scale request - too small, too big
		NSBeep(); return;
	}
	
	// make a correction based on the new and previous values
	float correctedScale = scaleValue / [self lastScale];
	
	// perform the scale
	[textView scaleUnitSquareToSize:NSMakeSize(correctedScale,correctedScale)];
	[[NSNotificationCenter defaultCenter] postNotificationName:NSViewFrameDidChangeNotification object:textView];
	[[textView enclosingScrollView] setNeedsDisplay:YES];
	
	// save the new scale
	[self setLastScale:scaleValue];
}

#pragma mark -

- (float) lastScale 
{ 
	return lastScale; 
}

- (void) setLastScale:(float)scaleValue 
{
	lastScale = scaleValue;
}

#pragma mark -
#pragma mark TextView Delegation

- (void) indexServerTextView:(IndexServerTextView*)aTextView showLexiconSelection:(id)anObject term:(NSString*)aTerm
{
	if ( ![[self delegate] respondsToSelector:@selector(contentController:showLexiconSelection:term:)] )
	{
		NSBeep(); return;
	}
	else [[self delegate] contentController:self showLexiconSelection:anObject term:aTerm];
}

#pragma mark -
#pragma mark The Media Bar

- (BOOL) canCustomizeMediabar:(PDMediaBar*)aMediabar
{
	return YES;
}

- (NSImage*) defaultOpenWithFinderImage:(PDMediaBar*)aMediabar
{
	return BundledImageWithName(@"WordBarSmall.png", @"com.sprouted.interface");
}

- (NSArray*) mediabarDefaultItemIdentifiers:(PDMediaBar *)mediabar
{
	return [NSArray arrayWithObjects:PDMediaBarItemGetInfo, PDMediabarItemShowInFinder, PDMediabarItemOpenWithFinder, nil];
}


@end
