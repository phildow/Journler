//
//  WordDocumentController.m
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

#import "WordDocumentController.h"

#import "NSAlert+JournlerAdditions.h"
#import "IndexServerTextView.h"

#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>

#import "NSString+JournlerUtilities.h"

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
	
	CGFloat width = [modifiedInfo paperSize].width - ( [modifiedInfo rightMargin] + [modifiedInfo leftMargin] );
	CGFloat height = [modifiedInfo paperSize].height - ( [modifiedInfo topMargin] + [modifiedInfo bottomMargin] );
	
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
	
    NSMutableArray *allRanges = [NSMutableArray array];
    NSArray *components = [aString componentsSeparatedByString:@" "];
   
    for ( NSString *aComponent in components )
	{
		// get the range of the string and highlight it
		NSArray *ranges = [[textView string] jn_rangesOfString:aComponent options:NSCaseInsensitiveSearch range:NSMakeRange(0,[[textView string] length])];
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
	
	NSInteger i;
	NSInteger theTag = [sender tag];
	float scaleValue = -1;
	NSInteger theLastScale = (NSInteger)[self lastScale];
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
