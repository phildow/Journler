#import "PDPDFViewController.h"
#import "JournlerMediaViewer.h"

#import "IndexServerPDFView.h"
#import "PDFSelectionNode.h"
#import "IndexServerPDFView.h"

#import "NSAlert+JournlerAdditions.h"

#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>

typedef UInt32 JournlerPDFDisplayOptions;
enum JournlerPDFDisplayOption {
	kJournlerPDFDisplayDefaultSetting = 0,
	kJournlerPDFDisplaySinglePage = 1,
	kJournlerPDFDisplaySinglePageContinuous = 1 << 1,
	kJournlerPDFDisplayTwoUp = 1 << 2,
	kJournlerPDFDisplayTwoUpContinuous = 1 << 3,
	kJournlerPDFDisplaysPageBreaks = 1 << 4,
	kJournlerPDFDisplaysAsBook = 1 << 5,
	kJournlerPDFAutoScales = 1 << 6
};

@implementation PDPDFViewController

- (id) init
{
	if ( self = [super init] ) 
	{
		//[NSBundle loadNibNamed:@"PDFContentView" owner:self];
		
		static NSString *kNibName = @"PDFContentView";
		NSString *kNibName105 = [NSString stringWithFormat:@"%@_105",kNibName];
		
		if ( [[NSBundle mainBundle] respondsToSelector:@selector(executableArchitectures)] 
				&& [[NSBundle mainBundle] pathForResource:kNibName105 ofType:@"nib"] != nil )
			[NSBundle loadNibNamed:kNibName105 owner:self];
		else
			[NSBundle loadNibNamed:kNibName owner:self];
		
		outlineState = kPDFMediaNoOutline;
		searchResults = [[NSMutableArray alloc] init];
		
		autoselectSearchResults = NO;
		//searchLock = [[NSLock alloc] init];
	}
	
	return self;	
}

- (void) awakeFromNib {
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
			selector:@selector(pageChanged:)	
			name:PDFViewPageChangedNotification 
			object:pdfView];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
			selector:@selector(pageChanged:)	
			name:PDFViewDocumentChangedNotification 
			object:pdfView];
	
	if ( ![[NSBundle mainBundle] respondsToSelector:@selector(executableArchitectures)] )
	{
		[[NSNotificationCenter defaultCenter] addObserver:self 
				selector:@selector(displayWillPop:)	
				name:NSPopUpButtonWillPopUpNotification 
				object:display];
		
		[[NSNotificationCenter defaultCenter] addObserver:self 
				selector:@selector(displayStoppedTracking:)	
				name:NSMenuDidEndTrackingNotification 
				object:[display menu]];
	}
	
	[super awakeFromNib];

	[[display cell] setArrowPosition:NSPopUpNoArrow];	
	[[splitView subviewAtPosition:1] collapse];
	
	_outlineIndentation = [outline indentationPerLevel];
	
	int borders[4] = { 0,1,0,0 };
	[unlockView setDrawsGradient:NO];
	[unlockView setBackgroundColor:[NSColor whiteColor]];
	[unlockView setBordered:YES];
	[unlockView setBorders:borders];
	
	[pdfView setDelegate:self];
	[pdfView setInsertsLexiconContextSeparator:YES];
	
	// all those images that are stored in SproutedInterface
	if ( ![[NSBundle mainBundle] respondsToSelector:@selector(executableArchitectures)] )
	{
		[[back cell] setImageDimsWhenDisabled:NO];
		[[forward cell] setImageDimsWhenDisabled:NO];
		
		[[zoomIn cell] setImageDimsWhenDisabled:NO];
		[[zoomOut cell] setImageDimsWhenDisabled:NO];
		
		[back setImage:BundledImageWithName(@"Back.tif", @"com.sprouted.interface")];
		[back setAlternateImage:BundledImageWithName(@"BackPressed.tif", @"com.sprouted.interface")];
		
		[forward setImage:BundledImageWithName(@"Forward.tif", @"com.sprouted.interface")];
		[forward setAlternateImage:BundledImageWithName(@"ForwardPressed.tif", @"com.sprouted.interface")];
			
		[zoomIn setImage:BundledImageWithName(@"Bigger.png", @"com.sprouted.interface")];
		[zoomIn setAlternateImage:BundledImageWithName(@"BiggerPressed.png", @"com.sprouted.interface")];
		
		[zoomOut setImage:BundledImageWithName(@"Smaller.png", @"com.sprouted.interface")];
		[zoomOut setAlternateImage:BundledImageWithName(@"SmallerPressed.png", @"com.sprouted.interface")];
		
		[actualSize setImage:BundledImageWithName(@"ActualSize.png", @"com.sprouted.interface")];
		[actualSize setAlternateImage:BundledImageWithName(@"ActualSizePressed.png", @"com.sprouted.interface")];
	}
	
	
	if ( [[NSBundle mainBundle] respondsToSelector:@selector(executableArchitectures)] )
		[[[display menu] itemAtIndex:0] setImage:[NSImage imageNamed:NSImageNameActionTemplate]];
	else
		[[[display menu] itemAtIndex:0] setImage:BundledImageWithName(@"Display.png", @"com.sprouted.interface")];
	
	
	// move the display button down a pixel if we're on tiger
	if ( ![display respondsToSelector:@selector(addTrackingArea:)] )
	{
		NSPoint frameOrigin = [display frame].origin;
		frameOrigin.y--; // flipped view
		[display setFrameOrigin:frameOrigin];
	}
}

- (void) restoreLastDisplaySettings
{
	JournlerPDFDisplayOptions pdfOptions =  [[NSUserDefaults standardUserDefaults] integerForKey:@"PDFViewDisplayOptions"];
	
	// basic stuff
	if ( pdfOptions & kJournlerPDFDisplaysPageBreaks )
		[pdfView setDisplaysPageBreaks:YES];
	else
		[pdfView setDisplaysPageBreaks:NO];
		
	if ( pdfOptions & kJournlerPDFDisplaysAsBook )
		[pdfView setDisplaysAsBook:YES];
	else
		[pdfView setDisplaysAsBook:NO];
	
	if ( pdfOptions & kJournlerPDFAutoScales )
		[pdfView setAutoScales:YES];
	else
		[pdfView setAutoScales:NO];
	
	// more advanced display mode
	PDFDisplayMode dp = [pdfView displayMode];
	
	if ( pdfOptions & kJournlerPDFDisplaySinglePage )
		dp = kPDFDisplaySinglePage;
		
	else if ( pdfOptions & kJournlerPDFDisplaySinglePageContinuous )
		dp = kPDFDisplaySinglePageContinuous;
		
	else if ( pdfOptions & kJournlerPDFDisplayTwoUp )
		dp = kPDFDisplayTwoUp;

	else if ( pdfOptions & kJournlerPDFDisplayTwoUpContinuous )
		dp = kPDFDisplayTwoUpContinuous;

	[pdfView setDisplayMode:dp];

}

- (void) dealloc 
{	
	// nib objects
	[unlockView release];
	
	// local objects
	[pdfView setDocument:nil];
	[selectedDocument release];
	[searchResults release];
	[rootNode release];
	
	// notification center
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

#pragma mark -

- (BOOL) loadURL:(NSURL*)aURL 
{
	PDFDocument *pdfDoc = [[[PDFDocument alloc] initWithURL:aURL] autorelease];
	if ( pdfDoc == nil ) 
	{
		NSBeep();
		NSLog(@"%s - unable to derive url from url %@", __PRETTY_FUNCTION__, aURL);
		[[NSAlert mediaError] runModal];
		return NO;
	}
	
	// check to see if the pdf document is locked, and if it is, display the locked view
	if ( ( [pdfDoc isLocked] || [pdfDoc isEncrypted] ) && ![pdfDoc unlockWithPassword:[NSString string]] )
	{
		[pdfView retain];
		[unlockView setFrame:[pdfView frame]];
		[[pdfView superview] replaceSubview:pdfView with:unlockView];
		[[[self contentView] window] makeFirstResponder:passwordField];
		[unlockView setNeedsDisplay:YES];
	}
	
	else
	{
		[pdfDoc setDelegate:self];
		[pdfView goToFirstPage:self];
		[pdfView setDocument:pdfDoc];
		
		rootNode = [[[pdfView document] outlineRoot] retain];
		if ( rootNode != nil ) 
		{
			[showOutline setEnabled:YES];
			[outline reloadData];
		}
		else 
		{
			[showOutline setEnabled:NO];
			rootNode = nil;
			[outline reloadData];
		}
		
		// re-establish the saved pdf display options - like this better in awakeFromNib, but causes problems
		[self restoreLastDisplaySettings];
	}
	
	selectedDocument = [pdfDoc retain];
	[super loadURL:aURL];
	
	return YES;
}

- (NSResponder*) preferredResponder
{
	if ( [pdfView superview] != nil )
		return pdfView;
		
	else if ( [unlockView superview] != nil )
		return passwordField;
	
	else
		return nil;
}

- (void) appropriateFirstResponder:(NSWindow*)window 
{
	if ( [pdfView superview] != nil )
		[window makeFirstResponder:pdfView];
		
	else if ( [unlockView superview] != nil )
		[window makeFirstResponder:passwordField];
}

- (IBAction) printDocument:(id)sender 
{
	//NSPrintInfo *modifiedInfo = [[[NSPrintInfo sharedPrintInfo] copyWithZone:[self zone]] autorelease];
	//[[modifiedInfo dictionary] setValue:[NSNumber numberWithBool:NO] forKey:NSPrintHeaderAndFooter];
	
	[pdfView printWithInfo:[NSPrintInfo sharedPrintInfo] autoRotate:NO];
}

#pragma mark -

- (PDFDocument*) pdfDocument
{
	return selectedDocument;
}

#pragma mark -

- (BOOL) handlesFindCommand
{
	// retargets the find panel action so that we can handle it
	return YES;
}

- (void) performCustomFindPanelAction:(id)sender
{
	switch ( [sender tag] )
	{
	case 1: // bring front panel
		[[[self contentView] window] makeFirstResponder:searchField];
		break;
	case 2: // find next (select next item in outline )
		if ( [self outlineState] != kPDFMediaSearchOutline || [outline numberOfRows] == 0 )
			NSBeep();
		else
		{
			if ( [outline selectedRow] == [outline numberOfRows] - 1 )
				[outline selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
			else
				[outline selectRowIndexes:[NSIndexSet indexSetWithIndex:[outline selectedRow]+1] byExtendingSelection:NO];
			
			[outline scrollRowToVisible:[outline selectedRow]];
		}
		break;
	case 3: // find previous (select previous item in outline )
		if ( [self outlineState] != kPDFMediaSearchOutline || [outline numberOfRows] == 0 )
			NSBeep();
		else
		{
			if ( [outline selectedRow] == 0 )
				[outline selectRowIndexes:[NSIndexSet indexSetWithIndex:[outline numberOfRows]-1] byExtendingSelection:NO];
			else
				[outline selectRowIndexes:[NSIndexSet indexSetWithIndex:[outline selectedRow]-1] byExtendingSelection:NO];
			
			[outline scrollRowToVisible:[outline selectedRow]];
		}
		break;
	default:
		NSBeep();
		break;
	}
}

- (BOOL) highlightString:(NSString*)aString
{
	if ( aString == nil || [aString length] == 0 )
		return NO;
	
	autoselectSearchResults = YES;
	
	//BOOL schonMatched = NO;
	NSString *aComponent;
	NSEnumerator *enumerator = [[aString componentsSeparatedByString:@" "] objectEnumerator];
	
	// run a search but without showing the panel
	[searchResults removeAllObjects];
	[outline reloadData];
	
	if ([[pdfView document] isFinding])
        [[pdfView document] cancelFindString];
	
	[self setOutlineState:kPDFMediaSearchOutline];
	
	while ( aComponent = [enumerator nextObject] )
	{
		// lock and search
		//[searchLock lock];
		[[pdfView document] beginFindString: aComponent withOptions: NSCaseInsensitiveSearch];
		
		while ( [[pdfView document] isFinding] )
			[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		
		// wait until the search is finished
		//[searchLock lock];
		
		if ( [searchResults count] != 0 )
		{
			// put the string on the find pasteboard
			NSPasteboard *findBoard = [NSPasteboard pasteboardWithName:NSFindPboard];
			[findBoard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
			[findBoard setString:aComponent forType:NSStringPboardType];
			
			// open the lock
			//[searchLock unlock];
			
			// get out - we're finished
			break;
		}
		
		//[searchLock unlock];
	}
	
	return YES;
	
	/*
	
	NSString *firstTerm;
	NSArray *allTerms = [aString componentsSeparatedByString:@" "];
	if ( [allTerms count] > 0 )
		firstTerm = [allTerms objectAtIndex:0];
	else
		firstTerm = aString;
	
	// put the string on the find pasteboard
	NSPasteboard *findBoard = [NSPasteboard pasteboardWithName:NSFindPboard];
	[findBoard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
	[findBoard setString:firstTerm forType:NSStringPboardType];

	// run a search but without showing the panel
	[searchResults removeAllObjects];
	[outline reloadData];
	
	if ([[pdfView document] isFinding])
        [[pdfView document] cancelFindString];
	
	[self setOutlineState:kPDFMediaSearchOutline];
	
	[searchLock lock];
	[[pdfView document] beginFindString: firstTerm withOptions: NSCaseInsensitiveSearch];
	
	return YES;
	
	*/
}

- (IBAction) barSearch:(id)sender
{
	autoselectSearchResults = NO;
	NSString *theSearchString = [sender stringValue];
	
	if ( [theSearchString length] == 0 && ![[splitView subviewAtPosition:1] isCollapsed] )
		[[splitView subviewAtPosition:1] collapse];
		//[[splitView subviewAtPosition:1] collapseWithAnimation];
	else if ( [[splitView subviewAtPosition:1] isCollapsed] )
		[[splitView subviewAtPosition:1] expand];
		//[[splitView subviewAtPosition:1] expandWithAnimation];
	
	[searchResults removeAllObjects];
	
	if ([[pdfView document] isFinding])
        [[pdfView document] cancelFindString];
	
	[self setOutlineState:kPDFMediaSearchOutline];
	[outline reloadData];
	
	//[searchLock lock];
	[[pdfView document] beginFindString: theSearchString withOptions: NSCaseInsensitiveSearch];

}

- (void) didMatchString: (PDFSelection *) instance {
    
	PDFSelectionNode *node = [[[PDFSelectionNode alloc] initWithSelection:instance] autorelease];
	
	[searchResults addObject:node];
	//[searchResults sortUsingDescriptors:SearchSortDescriptors()];
	
    // Force a reload.
    [outline reloadData];
	
	if ( autoselectSearchResults && [searchResults count] == 1 )
	{
		[outline deselectAll:self];
		[outline selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        //[outline selectRow:0 byExtendingSelection:NO]; DEPRECATED
	}
}

- (void)documentDidBeginDocumentFind:(NSNotification *)notification
{
	//[searchLock lock];
}

- (void)documentDidEndDocumentFind:(NSNotification *)notification
{
	//[searchLock unlock];
}


#pragma mark -

- (BOOL) handlesTextSizeCommand
{
	return YES;
}

- (void) performCustomTextSizeAction:(id)sender
{
	if ( [sender tag] == 3 )
		[pdfView zoomIn:sender];
	else if ( [sender tag] == 4 )
		[pdfView zoomOut:sender];
	else if ( [sender tag] == 99 )
		[self scaleToActual:sender];
}


#pragma mark -

- (PDFMediaOutlineState) outlineState 
{
	return outlineState;
}

- (void) setOutlineState:(PDFMediaOutlineState)state 
{
	outlineState = state;
	[outline setIndentationPerLevel:( state == kPDFMediaSearchOutline ? 0 : _outlineIndentation )];
}

#pragma mark -

- (IBAction) goToNextPage:(id)sender 
{
	[pdfView goToNextPage:sender];
}

- (IBAction) goToPreviousPage:(id)sender 
{
	[pdfView goToPreviousPage:sender];
}

- (IBAction) goToNextOrPreviousPage:(id)sender
{
	int clickedSegment = [sender selectedSegment];
    int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
	
	if ( clickedSegmentTag == 0 ) [pdfView goToPreviousPage:sender];
	else if ( clickedSegmentTag == 1 ) [pdfView goToNextPage:sender];
	else NSBeep();
}

- (IBAction) gotoPage:(id)sender 
{
	unsigned int index = [sender intValue] - 1;
	if ( index >= [[pdfView document] pageCount] ) 
	{
		index = [[pdfView document] pageCount] - 1;
	}
	
	PDFPage *page = [[pdfView document] pageAtIndex:index];
	if ( !page ) 
	{
		return;
	}
	
	[pdfView goToPage:page];
	
}

- (void) pageChanged:(NSNotification*)aNotification 
{
	
    int             numRows;
    int             i;
    int             newlySelectedRow;
	
	unsigned int index = [(PDFDocument*)[(PDFView*)[aNotification object] document] 
			indexForPage:[(PDFView*)[aNotification object] currentPage]];
	
	[pageNum setIntValue:++index];
	[self updateNavButtons];
	
	//
	// update the outline view if possible
    if ( [[pdfView document] outlineRoot] == NULL || _outlineChange || [self outlineState] != kPDFMediaDocumentOutline )
        return;
		
    newlySelectedRow = -1;
    numRows = [outline numberOfRows];
    for (i = 0; i < numRows; i++)// 3
    {
        PDFOutline  *outlineItem;
 
        // Get the destination of the given row....
        outlineItem = (PDFOutline *)[outline itemAtRow: i];
 
        if ( [[outlineItem destination] page] != nil && 
				[[pdfView document] indexForPage: [[outlineItem destination] page]] == index) 
		{
            newlySelectedRow = i;
            [outline selectRowIndexes:[NSIndexSet indexSetWithIndex:newlySelectedRow] byExtendingSelection:NO];
            //[outline selectRow: newlySelectedRow byExtendingSelection: NO]; DEPRECATED
            break;
        }
        else if ( [[outlineItem destination] page] != nil && 
				[[pdfView document] indexForPage: [[outlineItem destination] page]] > index) 
		{
            newlySelectedRow = i - 1;
            [outline selectRowIndexes:[NSIndexSet indexSetWithIndex:newlySelectedRow] byExtendingSelection:NO];
            //[outline selectRow: newlySelectedRow byExtendingSelection: NO]; DEPRECATED
            break;
        }
    }
 
    if (newlySelectedRow != -1)
        [outline scrollRowToVisible: newlySelectedRow];
}


- (void) displayWillPop:(NSNotification*)aNotification 
{
	// change the icon!
	if ( ![[NSBundle mainBundle] respondsToSelector:@selector(executableArchitectures)] )
	{
		NSImage *theImage = BundledImageWithName(@"DisplayPressed.png", @"com.sprouted.interface");
		[[[display menu] itemAtIndex:0] setImage:theImage];
	}
}

- (void) displayStoppedTracking:(NSNotification*)aNotification 
{
	// change the icon!
	if ( ![[NSBundle mainBundle] respondsToSelector:@selector(executableArchitectures)] )
	{
		NSImage *theImage = BundledImageWithName(@"Display.png", @"com.sprouted.interface");
		[[[display menu] itemAtIndex:0] setImage:theImage];
	}
}

- (IBAction) scaleToActual:(id)sender 
{
	[pdfView setScaleFactor:1.0];
	
	if ( [[NSBundle mainBundle] respondsToSelector:@selector(executableArchitectures)] )
	{
	
	}
	else
	{
		NSImage *zoomInImage = BundledImageWithName( ( [pdfView canZoomIn] ? @"Bigger.png" : @"BiggerDisabled.png" ), @"com.sprouted.interface");
		NSImage *zoomOutImage = BundledImageWithName( ( [pdfView canZoomOut] ? @"Smaller.png" : @"SmallerDisabled.png" ), @"com.sprouted.interface");
		
		[zoomIn setImage:zoomInImage];
		[zoomOut setImage:zoomOutImage];
	}
	
	[zoomIn setEnabled:[pdfView canZoomIn]];
	[zoomOut setEnabled:[pdfView canZoomOut]];
	
	// reset the auto-scale if it's enabled
	JournlerPDFDisplayOptions pdfOptions =  [[NSUserDefaults standardUserDefaults] integerForKey:@"PDFViewDisplayOptions"];
	pdfOptions ^= kJournlerPDFAutoScales;
	[[NSUserDefaults standardUserDefaults] setInteger:pdfOptions forKey:@"PDFViewDisplayOptions"];
}

#pragma mark -

- (IBAction) toggleOutline:(id)sender 
{
	if ( [self outlineState] == kPDFMediaSearchOutline )
	{
		// clear the search
		if ([[pdfView document] isFinding])
			[[pdfView document] cancelFindString];
		
		[searchField setStringValue:[NSString string]];
		
		// deselect the search term
		[outline deselectAll:sender];
		
		// set the state
		[self setOutlineState:kPDFMediaDocumentOutline];
		
		// show the outline
		if ( [[splitView subviewAtPosition:1] isCollapsed] )
			[[splitView subviewAtPosition:1] expand];
	}
	else
	{
		// show or hide the outline
		
		// set the state
		[self setOutlineState:kPDFMediaDocumentOutline];
		
		if ( [[splitView subviewAtPosition:1] isCollapsed] )
			[[splitView subviewAtPosition:1] expand];
			//[[splitView subviewAtPosition:1] expandWithAnimation];
		else
			[[splitView subviewAtPosition:1] collapse];
			//[[splitView subviewAtPosition:1] collapseWithAnimation];
	}
	
	// reload the outline
	[outline reloadData];
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem 
{
	BOOL enabled = YES;
	int theTag = [menuItem tag];
	SEL action = [menuItem action];
	PDFDisplayMode dp = [pdfView displayMode];
	
	if ( action == @selector(changeDisplayMode:) )
	{
	
		switch ( theTag ) 
		{
		case 1:	// single pages
			if ( dp == kPDFDisplaySinglePage || dp == kPDFDisplaySinglePageContinuous )
				[menuItem setState:NSOnState];
			else
				[menuItem setState:NSOffState];
			break;
		
		case 2: // facing pages
			if ( dp == kPDFDisplayTwoUp || dp == kPDFDisplayTwoUpContinuous )
				[menuItem setState:NSOnState];
			else
				[menuItem setState:NSOffState];
			break;
		
		case 3: // continuous
			if ( dp == kPDFDisplaySinglePageContinuous || dp == kPDFDisplayTwoUpContinuous )
				[menuItem setState:NSOnState];
			else
				[menuItem setState:NSOffState];
			break;
		
		case 4: // page breaks
			[menuItem setState:([pdfView displaysPageBreaks]?NSOnState:NSOffState)];
			break;
		
		case 5: // book mode
			
			[menuItem setState:([pdfView displaysAsBook]?NSOnState:NSOffState)];
			enabled = ( [pdfView displayMode] == kPDFDisplayTwoUp || [pdfView displayMode] == kPDFDisplayTwoUpContinuous );
			break;
		
		case 6: // auto-resizes
			[menuItem setState:([pdfView autoScales]?NSOnState:NSOffState)];
			break;
		}
	}
	
	else if ( action == @selector(performCustomFindPanelAction:) )
	{
		switch ( theTag )
		{
		case 1:
			enabled = YES;
			break;
		case 2:
			enabled = ( [outline numberOfRows] != 0 );
			break;
		case 3:
			enabled = ( [outline numberOfRows] != 0 );
			break;
		default:
			enabled = NO;
			break;
		}
	}
	
	else if ( action == @selector(performCustomTextSizeAction:) )
	{
		if ( theTag == 3 )
			enabled = [pdfView canZoomIn];
		else if ( theTag == 4 )
			enabled = [pdfView canZoomOut];
		else if ( theTag == 99 )
			enabled = YES;
	}
	
	return enabled;
}

- (IBAction) scaleView:(id)sender 
{
	if ( [sender tag] == 0 ) [pdfView zoomOut:self];
	else if ( [sender tag] == 1 ) [pdfView zoomIn:self];
	
	[self _updateScaleOptions];
}

- (IBAction) zoomInOrOut:(id)sender
{
	int clickedSegment = [sender selectedSegment];
    int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
	
	if ( clickedSegmentTag == 0 ) [pdfView zoomOut:self];
	else if ( clickedSegmentTag == 1 ) [pdfView zoomIn:self];
	else if ( clickedSegmentTag == 2 ) [self scaleToActual:self];
	else NSBeep();
	
	[self _updateScaleOptions];
}

- (void) _updateScaleOptions
{
	if ( [[NSBundle mainBundle] respondsToSelector:@selector(executableArchitectures)] )
	{
		[zoomInOut setEnabled:[pdfView canZoomOut] forSegment:0];
		[zoomInOut setEnabled:[pdfView canZoomIn] forSegment:1];
	}
	else
	{
		NSImage *zoomInImage = BundledImageWithName( ( [pdfView canZoomIn] ? @"Bigger.png" : @"BiggerDisabled.png" ), @"com.sprouted.interface");
		NSImage *zoomOutImage = BundledImageWithName( ( [pdfView canZoomOut] ? @"Smaller.png" : @"SmallerDisabled.png" ), @"com.sprouted.interface");
		
		[zoomIn setImage:zoomInImage];
		[zoomOut setImage:zoomOutImage];
		
		[zoomIn setEnabled:[pdfView canZoomIn]];
		[zoomOut setEnabled:[pdfView canZoomOut]];
	}
	
	// reset the autoscales if it's enabled
	JournlerPDFDisplayOptions pdfOptions =  [[NSUserDefaults standardUserDefaults] integerForKey:@"PDFViewDisplayOptions"];
	pdfOptions ^= kJournlerPDFAutoScales;
	[[NSUserDefaults standardUserDefaults] setInteger:pdfOptions forKey:@"PDFViewDisplayOptions"];
}

- (IBAction) changeDisplayMode:(id)sender 
{
	JournlerPDFDisplayOptions pdfOptions = 0;
	PDFDisplayMode dp = [pdfView displayMode];
	
	switch ( [sender tag] ) {
		
		case 1: //single pages
			if ( dp == kPDFDisplaySinglePage || dp == kPDFDisplayTwoUp )
				[pdfView setDisplayMode:kPDFDisplaySinglePage];
			else if ( dp == kPDFDisplaySinglePageContinuous || dp == kPDFDisplayTwoUpContinuous )
				[pdfView setDisplayMode:kPDFDisplaySinglePageContinuous];
			break;
		
		case 2: // facing pages
			if ( dp == kPDFDisplaySinglePage || dp == kPDFDisplayTwoUp )
				[pdfView setDisplayMode:kPDFDisplayTwoUp];
			else if ( dp == kPDFDisplaySinglePageContinuous || dp == kPDFDisplayTwoUpContinuous )
				[pdfView setDisplayMode:kPDFDisplayTwoUpContinuous];
			break;
		
		case 3: // continuous
			if ( dp == kPDFDisplaySinglePage || dp == kPDFDisplaySinglePageContinuous )
				[pdfView setDisplayMode: ( [sender state] == NSOnState ? kPDFDisplaySinglePageContinuous : kPDFDisplaySinglePage )];
			else if ( dp == kPDFDisplayTwoUp || dp == kPDFDisplayTwoUpContinuous )
				[pdfView setDisplayMode: ( [sender state] == NSOnState ? kPDFDisplayTwoUpContinuous : kPDFDisplaySinglePage )];
			break;
		
		case 4: // page breaks
			[pdfView setDisplaysPageBreaks:![pdfView displaysPageBreaks]];
			break;
		
		case 5: // book mode
			[pdfView setDisplaysAsBook:![pdfView displaysAsBook]];
			break;
		
		case 6:
			[pdfView setAutoScales:![pdfView autoScales]];
			break;
		
	}
	
	// save the changes to defaults - basic stuff
	if ( [pdfView displaysPageBreaks] )
		pdfOptions |= kJournlerPDFDisplaysPageBreaks;
	if ( [pdfView displaysAsBook] )
		pdfOptions |= kJournlerPDFDisplaysAsBook;
	if ( [pdfView autoScales] )
		pdfOptions |= kJournlerPDFAutoScales;
	
	// more advanced display mode
	dp = [pdfView displayMode];
	
	if ( dp == kPDFDisplaySinglePage )
		pdfOptions |= kJournlerPDFDisplaySinglePage;
	else if ( dp == kPDFDisplaySinglePageContinuous )
		pdfOptions |= kJournlerPDFDisplaySinglePageContinuous;
	else if ( dp == kPDFDisplayTwoUp )
		pdfOptions |= kJournlerPDFDisplayTwoUp;
	else if ( dp == kPDFDisplayTwoUpContinuous )
		pdfOptions |= kJournlerPDFDisplayTwoUpContinuous;
		
	[[NSUserDefaults standardUserDefaults] setInteger:pdfOptions forKey:@"PDFViewDisplayOptions"];
}

#pragma mark -

- (IBAction) previousPage:(id)sender 
{
	[pdfView goToNextPage:sender];
	[self updateNavButtons];
}

- (IBAction) nextPage:(id)sender 
{
	[pdfView goToPreviousPage:sender];
	[self updateNavButtons];
}

- (void) updateNavButtons 
{		 
	if ( [[NSBundle mainBundle] respondsToSelector:@selector(executableArchitectures)] )
	{
		[backForward setEnabled:[pdfView canGoToPreviousPage] forSegment:0];
		[backForward setEnabled:[pdfView canGoToNextPage] forSegment:1];
	}
	else
	{
		NSImage *backImage = BundledImageWithName( ( [pdfView canGoToPreviousPage] ? @"Back.tif" : @"BackDisabled.tif" ), @"com.sprouted.interface");
		NSImage *forwardImage = BundledImageWithName( ( [pdfView canGoToNextPage] ? @"Forward.tif" : @"ForwardDisabled.tif" ), @"com.sprouted.interface");
		
		[back setEnabled:[pdfView canGoToPreviousPage]];
		[forward setEnabled:[pdfView canGoToNextPage]];
		
		[back setImage:backImage];
		[forward setImage:forwardImage];
	}
}

#pragma mark -

- (IBAction) unlockDocument:(id)sender
{
	NSString *password = [passwordField stringValue];
	
	if ( [selectedDocument unlockWithPassword:password] )
	{
		[unlockView retain];
		[pdfView setFrame:[unlockView frame]];
		[[unlockView superview] replaceSubview:unlockView with:pdfView];
		[[[self contentView] window] makeFirstResponder:pdfView];
		
		[selectedDocument setDelegate:self];
		[pdfView goToFirstPage:self];
		[pdfView setDocument:selectedDocument];
		
		rootNode = [[[pdfView document] outlineRoot] retain];
		if ( rootNode != nil ) 
		{
			[showOutline setEnabled:YES];
			[outline reloadData];
		}
		else 
		{
			[showOutline setEnabled:NO];
			rootNode = nil;
			[outline reloadData];
		}
		
		// re-establish the saved pdf display options - like this better in awakeFromNib, but causes problems
		[self restoreLastDisplaySettings];
		
		// set an icon on the represented object if it supports that
		if ( [[self representedObject] respondsToSelector:@selector(setIcon:)] )
		{
			NSImage *icon = [selectedDocument efficientThumbnailForPage:0 size:128];
			[representedObject setValue:icon forKey:@"icon"];
			
			if ( [[self representedObject] respondsToSelector:@selector(cacheIconToDisk)] )
				[representedObject performSelector:@selector(cacheIconToDisk)];
		}
	}
	else
	{
		NSBeep();
		[unlockNoticeField setHidden:NO];
		[[[self contentView] window] makeFirstResponder:passwordField];
	}
}

#pragma mark -
#pragma mark IndexServerPDFView Delegation

- (void) indexServerPDFView:(IndexServerPDFView*)aPDFView showLexiconSelection:(id)anObject term:(NSString*)aTerm
{
	if ( ![[self delegate] respondsToSelector:@selector(contentController:showLexiconSelection:term:)] )
	{
		NSBeep(); return;
	}
	else [[self delegate] contentController:self showLexiconSelection:anObject term:aTerm];
}

#pragma mark -
#pragma mark Outline View Data Source

// This method is called repeatedly when the table view is displaying it self. 
- (id)outlineView:(NSOutlineView *)ov child:(int)index ofItem:(id)item
{	
	if ( [self outlineState] == kPDFMediaDocumentOutline ) 
	{
		if (item == nil) 
		{
			if ( rootNode )
				return [[rootNode childAtIndex:index] retain];
			else
				return nil;
		}
		else
			return [[item childAtIndex:index] retain];
	}
	
	else if ( [self outlineState] == kPDFMediaSearchOutline ) 
	{
		if ( item == nil )
			return [searchResults objectAtIndex:index];
		else
			return nil;
	}
	
	else 
	{
		return nil;
	}
}

// Called repeatedly to find out if there should be an "expand triangle" next to the label
- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item
{
    if ( [self outlineState] == kPDFMediaDocumentOutline ) 
	{
		if ( item == nil ) 
		{
			if ( rootNode )
				return ( [rootNode numberOfChildren] > 0);
			else
				return NO;
		}
		else
			return ( [item numberOfChildren] > 0 );
	}
	
	else if ( [self outlineState] == kPDFMediaSearchOutline ) 
	{
		return NO;
	}
	
	else 
	{
		return NO;
	}

}

// Called repeatedly when the table view is displaying itself
- (int)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item
{
    if ( [self outlineState] == kPDFMediaDocumentOutline ) 
	{
		if (item == nil) 
		{
			if ( rootNode )
				return [rootNode numberOfChildren];
			else
				return 0;
		}
		else
			return [item numberOfChildren];
		
	}
	
	else if ( [self outlineState] == kPDFMediaSearchOutline ) 
	{
		if ( item == nil )
			return [searchResults count];
		else
			return 0;
	}
	
	else 
	{
		return 0;
	}

}

// This method gets called repeatedly when the outline view is trying
- (id)outlineView:(NSOutlineView *)olv objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item 
{   
	if ( [self outlineState] == kPDFMediaDocumentOutline ) 
	{
		id objectValue = nil;
		
		if([[tableColumn identifier] isEqualToString: @"label"])
			objectValue = [(PDFOutline*)item label];
			
		else if([[tableColumn identifier] isEqualToString: @"page"])
			objectValue = [[[(PDFOutline*)item destination] page] label];
		
		return objectValue;
	}
	
	else if ( [self outlineState] == kPDFMediaSearchOutline ) 
	{
		id objectValue = nil;
			
		if([[tableColumn identifier] isEqualToString: @"label"])
			objectValue = [(PDFSelectionNode*)item attributedPreview];
			
		else if([[tableColumn identifier] isEqualToString: @"page"])
			objectValue = [[(PDFSelectionNode*)item page] label];
			
		return objectValue;
	}
	
	else
	{
		return nil;
	}

}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification 
{
	_outlineChange = YES;
	
	int selectedRow = [outline selectedRow];
	id selection = [outline itemAtRow:selectedRow];
	
	if ( [self outlineState] == kPDFMediaSearchOutline ) 
	{
		[pdfView setCurrentSelection:[(PDFSelectionNode*)selection selection]];
		[pdfView scrollSelectionToVisible:self];
	}
	
	else if ( [self outlineState] == kPDFMediaDocumentOutline ) 
	{
		if ( [selection isKindOfClass:[PDFOutline class]] ) 
		{
			[pdfView goToDestination:[selection destination]];
		}
	}
	
	_outlineChange = NO;
}

#pragma mark -
#pragma RBSplitView Delegation

// this prevents a subview from resizing while the others around it do
- (void)splitView:(RBSplitView*)sender wasResizedFrom:(float)oldDimension to:(float)newDimension 
{
	if ( [sender tag] == 0 )
		[sender adjustSubviewsExcepting:[sender subviewAtPosition:1]];
}

- (NSRect)splitView:(RBSplitView*)sender willDrawDividerInRect:(NSRect)dividerRect 
		betweenView:(RBSplitSubview*)leading andView:(RBSplitSubview*)trailing withProposedRect:(NSRect)imageRect
{
	NSBezierPath *framePath = [NSBezierPath bezierPathWithRect:dividerRect];
	[framePath setLineWidth:1];
	
	NSGraphicsContext *context = [NSGraphicsContext currentContext];
	[context saveGraphicsState];
	
	[[NSColor colorWithCalibratedWhite:0.96 alpha:1.0] set];
	[framePath fill];
	
	[context setShouldAntialias:NO];
	
	/*
	NSRect frameRect = dividerRect;
	frameRect.origin.x--; frameRect.size.width++;
	
	framePath = [NSBezierPath bezierPathWithRect:frameRect];
	[framePath setLineWidth:1];
	
	[[NSColor colorWithCalibratedWhite:0.2 alpha:1.0] set];
	[framePath stroke];
	*/
	[context restoreGraphicsState];
	
	return imageRect;
}


#pragma mark -

- (IBAction) openInNewWindow:(id)sender 
{
	JournlerMediaViewer *mediaViewer = [[[JournlerMediaViewer alloc] initWithURL:[self URL] uti:(NSString*)kUTTypePDF] autorelease];
	if ( mediaViewer == nil )
	{
		NSLog(@"%s - problem allocating media viewer for url %@", __PRETTY_FUNCTION__, [self URL]);
		[[NSWorkspace sharedWorkspace] openURL:[self URL]];
	}
	else
	{
		[mediaViewer setRepresentedObject:[self representedObject]];
		[mediaViewer showWindow:self];
	}
}

#pragma mark -
#pragma mark The Media Bar

- (BOOL) canCustomizeMediabar:(PDMediaBar*)aMediabar
{
	return YES;
}

- (NSImage*) defaultOpenWithFinderImage:(PDMediaBar*)aMediabar
{
	NSImage *theImage = BundledImageWithName(@"PreviewBarSmall.png", @"com.sprouted.interface");
	return theImage;

}

- (float) mediabarMinimumWidthForUnmanagedControls:(PDMediaBar*)aMediabar
{
	// leave room for the pdf controls
	return 490;
}

- (NSArray*) mediabarDefaultItemIdentifiers:(PDMediaBar *)mediabar
{
	return [NSArray arrayWithObjects:PDMediaBarItemGetInfo, PDMediabarItemShowInFinder, PDMediabarItemOpenWithFinder, nil];
}


@end
