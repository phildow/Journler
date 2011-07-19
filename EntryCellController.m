//
//  EntryCellController.m
//  Journler
//
//  Created by Philip Dow on 10/25/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.EntryTextAutoCorrectSpelling
//

#import "EntryCellController.h"
#import "JournlerApplicationDelegate.h"

#import "JournlerJournal.h"
#import "JournlerEntry.h"
#import "JournlerCollection.h"
#import "JournlerResource.h"

//#import "JUtility.h"
#import "Definitions.h"
#import "PDStylesBar.h"
#import "NSURL+JournlerAdditions.h"
#import "NSAlert+JournlerAdditions.h"

#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>

#import "LinksOnlyNSTextView.h"
#import "NSString+JournlerAdditions.h"


#import "WebViewController.h"

@implementation EntryCellController

/*
static NSDictionary * StatusAttributes()
{
	static NSDictionary *statusAttributes = nil;
	if ( statusAttributes == nil )
	{
		NSShadow *textShadow = [[[NSShadow alloc] init] autorelease];
		[textShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.96 alpha:0.8]];
		[textShadow setShadowOffset:NSMakeSize(0,-1)];
		
		NSColor *black = [NSColor blackColor];
		NSFont *font = [NSFont controlContentFontOfSize:11];
		NSParagraphStyle *paragraphStyle = [NSParagraphStyle defaultParagraphStyleWithLineBreakMode:NSLineBreakByTruncatingTail];
		
		statusAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
				textShadow, NSShadowAttributeName,
				paragraphStyle, NSParagraphStyleAttributeName,
				font, NSFontAttributeName,
				black, NSForegroundColorAttributeName, nil];
	}
	
	return statusAttributes;
}
*/

- (id) init 
{
	if ( self = [super init] ) 
	{
		// initialization
		headerHidden = YES;
		footerHidden = YES;
		selectedEntries = [[NSArray alloc] init];
		
		// smart quotes
		openQuote = YES;
		static unichar kOpenSmartQuote = 0x201C; // 0x201C; //0x0093;
		static unichar kCloseSmartQuote = 0x201D; // 0x201D; // 0x0094;
		openSmartQuote = [[NSString alloc] initWithCharacters:(const unichar[]){kOpenSmartQuote} length:1];
		closeSmartQuote = [[NSString alloc] initWithCharacters:(const unichar[]){kCloseSmartQuote} length:1];
		
		textBackgroundColor = [[NSColor whiteColor] retain];
		headerBackgroundColor = [[NSColor whiteColor] retain];
		headerLabelColor = [[NSColor colorWithCalibratedWhite:0.75 alpha:1.0] retain];
		headerTextColor = [[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] retain];
		
		// the interface
		[NSBundle loadNibNamed:@"EntryCell" owner:self];
	}
	return self;
}

- (void) awakeFromNib 
{
	// create the text view by hand
	[self installTextSystem];
	
	NSInteger statusBorders[4] = {1,0,0,0};
	[statusBar setBordered:YES];
	[statusBar setBorders:statusBorders];
	
	[self setHeaderIsWhite:YES];
	[headerView setBorders:(int[]){1,0,0,0}];
	[headerView setGradientStartColor:[NSColor whiteColor]];
	[headerView setGradientEndColor:[NSColor whiteColor]];
	
	NSInteger contentBorders[4] = {0,0,0,0};
	[contentView setBorders:contentBorders];
	
	[self setHeaderHidden:NO];
	[self setFooterHidden:NO];
		
	[textView setDelegate:self];
	[[textView textStorage] setDelegate:self];
	//[textView setContinuouslyPostsSelectionNotification:YES];
	
	[[scalePop cell] setArrowPosition:NSPopUpNoArrow];
	[[marginPop cell] setArrowPosition:NSPopUpNoArrow];
	
	// set the scale on the text view - depends on fullscreen status
	NSInteger scale = ( [self respondsToSelector:@selector(textViewIsInFullscreenMode:)] && [self textViewIsInFullscreenMode:textView]
			? [[NSUserDefaults standardUserDefaults] integerForKey:@"EntryTextFullscreenZoom"]
			: [[NSUserDefaults standardUserDefaults] integerForKey:@"EntryTextDefaultZoom"] );
	
	NSMenuItem *scaleItem = [[scalePop menu] itemWithTag:scale];
	if ( scaleItem != nil )
	{
		[scalePop selectItem:scaleItem];
		[[scaleItem target] performSelector:[scaleItem action] withObject:scaleItem];
	}
	
	// set the margin on the text view - depends on fullscreen status
	NSInteger margin = ( [self respondsToSelector:@selector(textViewIsInFullscreenMode:)] && [self textViewIsInFullscreenMode:textView] 
			? [[NSUserDefaults standardUserDefaults] integerForKey:@"EntryTextHorizontalInsetFullscreen"]
			: [[NSUserDefaults standardUserDefaults] integerForKey:@"EntryTextHorizontalInset"] );
		
	NSMenuItem *marginItem = [[marginPop menu] itemWithTag:margin];
	if ( marginItem != nil )
	{
		[marginPop selectItem:marginItem];
		[[marginItem target] performSelector:[marginItem action] withObject:marginItem];
	}
		
	
	// the styles bar
	stylesBar = [[PDStylesBar allocWithZone:[self zone]] initWithTextView:textView];
	
	// the header
	NSInteger borders[4] = {1,0,0,0};
	[headerView setBorders:borders];
	[headerView setBordered:YES];
	
	// and make sure none of my headers fields draw a focus ring
	[[titleField cell] setFocusRingType:NSFocusRingTypeNone];
	[[tagsField cell] setFocusRingType:NSFocusRingTypeNone];
	[[categoryField cell] setFocusRingType:NSFocusRingTypeNone];
	[[dateField cell] setFocusRingType:NSFocusRingTypeNone];
	[tagsField setDrawsBackground:NO];
	
	// tags cell
	[tagsField setBezeled:NO];
	[tagsField setBordered:NO];
	[tagsField setEditable:NO];
	
	// set the formatter on the date cell
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateStyle:NSDateFormatterLongStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	
	[dateField setFormatter:dateFormatter];
	
	// header background color
	[self bind:@"headerBackgroundColor" 
			toObject:[NSUserDefaultsController sharedUserDefaultsController] 
			withKeyPath:@"values.HeaderBackgroundColor" 
			options:[NSDictionary dictionaryWithObjectsAndKeys:
					@"NSUnarchiveFromData", NSValueTransformerNameBindingOption,
					[NSColor whiteColor], NSNullPlaceholderBindingOption, nil]];
	
	// content background color
	[self bind:@"textBackgroundColor" 
			toObject:[NSUserDefaultsController sharedUserDefaultsController] 
			withKeyPath:@"values.EntryBackgroundColor" 
			options:[NSDictionary dictionaryWithObjectsAndKeys:
					@"NSUnarchiveFromData", NSValueTransformerNameBindingOption,
					[NSColor whiteColor], NSNullPlaceholderBindingOption, nil]];
	
	// header label color
	[self bind:@"headerLabelColor" 
			toObject:[NSUserDefaultsController sharedUserDefaultsController] 
			withKeyPath:@"values.HeaderLabelColor" 
			options:[NSDictionary dictionaryWithObjectsAndKeys:
					@"NSUnarchiveFromData", NSValueTransformerNameBindingOption,
					[NSColor darkGrayColor], NSNullPlaceholderBindingOption, nil]];
	
	// header text color
	[self bind:@"headerTextColor" 
			toObject:[NSUserDefaultsController sharedUserDefaultsController] 
			withKeyPath:@"values.HeaderTextColor" 
			options:[NSDictionary dictionaryWithObjectsAndKeys:
					@"NSUnarchiveFromData", NSValueTransformerNameBindingOption,
					[NSColor blackColor], NSNullPlaceholderBindingOption, nil]];
	
	// smart quotes bound to user defaults on leopard
	if ( [textView respondsToSelector:@selector(isAutomaticQuoteSubstitutionEnabled)] )
		[textView bind:@"automaticQuoteSubstitutionEnabled" 
				toObject:[NSUserDefaultsController sharedUserDefaultsController] 
				withKeyPath:@"values.EntryTextUseSmartQuotes" 
				options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:NSNullPlaceholderBindingOption]];
	
	if ( [textView respondsToSelector:@selector(isAutomaticLinkDetectionEnabled)] )
		[textView bind:@"automaticLinkDetectionEnabled" 
				toObject:[NSUserDefaultsController sharedUserDefaultsController] 
				withKeyPath:@"values.EntryTextRecognizeURLs" 
				options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:NSNullPlaceholderBindingOption]];
}

- (void) dealloc
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	// no more notifications
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	// release the nib objects
	[contentView release];
	[headerView release];
	[statusBar release];
	
	// release the local objects
	[stylesBar release];
	[selectedEntry release];
	[selectedEntries release];
	
	[openSmartQuote release];
	[closeSmartQuote release];
	
	[objectController release];
	[draggedResource release];
	
	[super dealloc];
}

#pragma mark -

- (void) installTextSystem
{
	// scroll view bounds: 1,1,480,509
	// container bounds: 0,0,482,511 (contentView)
	
	// everything enabled except hidden and allows document background color change
	
	// attributedString is bound to ownerController selection selectedEntry.attributedContent w/ continuously updates value
	// editable is bound to ownerController selection selectedEntry NSIsNotNil transformer 
	
	KBWordCountingTextStorage *textStorage = [[KBWordCountingTextStorage alloc] init];
	NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
	
	//[[NSNotificationCenter defaultCenter] addObserver:self 
	//		selector:@selector(wordCountDidChange:) 
	//		name:KBTextStorageStatisticsDidChangeNotification 
	//		object:textStorage];
	
	[textStorage addLayoutManager:layoutManager];
	[layoutManager release];
	
	NSRect theFrame = [contentView frame];
	theFrame.origin.x = 1;
	theFrame.origin.y = 1;
	theFrame.size.width -= 2;
	theFrame.size.height -= 2;
	
	NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:theFrame];
	
	[scrollView setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
	[scrollView setHasVerticalScroller:YES];
    [scrollView setHasHorizontalScroller:NO];
    [[scrollView contentView] setAutoresizesSubviews:YES];
    [[scrollView contentView] setBackgroundColor:[NSColor controlColor]];
    if (NSInterfaceStyleForKey(NSInterfaceStyleDefault, scrollView) == NSWindows95InterfaceStyle) {
        [scrollView setBorderType:NSBezelBorder];
    }

	[scrollView setBackgroundColor:[NSColor whiteColor]];
	[scrollView setDrawsBackground:YES];

	NSSize size = [scrollView contentSize];
	
	NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(size.width,FLT_MAX)];
	
	[textContainer setWidthTracksTextView:YES];
	[textContainer setHeightTracksTextView:NO];		/* Not really necessary */
	
	[layoutManager addTextContainer:textContainer];
	[textContainer release];
	
	textView = [[LinksOnlyNSTextView alloc] initWithFrame:NSMakeRect(0.0, 0.0, size.width, size.height) textContainer:textContainer];
	
	[textView setUsesFontPanel:YES];
    [textView setUsesFindPanel:YES];
    [textView setAllowsUndo:YES];
    [textView setAllowsDocumentBackgroundColorChange:NO];
    [textView setContinuousSpellCheckingEnabled:YES];
	[textView setImportsGraphics:YES];
	[textView setRichText:YES];
	
	[textView setHorizontallyResizable:NO];			/* Not really necessary */
	[textView setVerticallyResizable:YES];
	[textView setAutoresizingMask:NSViewWidthSizable];
	[textView setMinSize:size];	/* Not really necessary; will be adjusted by the autoresizing... */
	[textView setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];	/* Will be adjusted by the autoresizing... */ 
	
	[textView setBackgroundColor:[NSColor whiteColor]];
	[textView setDrawsBackground:YES];
	
	
	// bindings
	[textView bind:@"attributedString" toObject:objectController withKeyPath:@"selection.selectedEntry.attributedContent" 
	options:[NSDictionary dictionaryWithObjectsAndKeys:
	[NSNumber numberWithBool:YES], NSAllowsEditingMultipleValuesSelectionBindingOption,
	[NSNumber numberWithBool:YES], NSConditionallySetsEditableBindingOption, 
	[NSNumber numberWithBool:YES], NSContinuouslyUpdatesValueBindingOption,
	[NSNumber numberWithBool:YES], NSRaisesForNotApplicableKeysBindingOption, nil]];
	
	[textView bind:@"editable" toObject:objectController withKeyPath:@"selection.selectedEntry" 
	options:[NSDictionary dictionaryWithObjectsAndKeys:@"NSIsNotNil", NSValueTransformerNameBindingOption, nil]];
	
	
	[scrollView setDocumentView:textView];
	[contentView addSubview:scrollView];
	
	[textView doSetup];
	
	[textView release];
	[scrollView release];

}

#pragma mark -

- (NSView*) contentView {
	return contentView;
}

- (NSView*) headerView {
	return headerView;
}

- (LinksOnlyNSTextView*)textView {
	return textView;
}

- (NSTextField*) titleField {
	return titleField;
}

#pragma mark -

- (JournlerEntry*) selectedEntry 
{
	return selectedEntry;
}

- (void) setSelectedEntry:(JournlerEntry*)anEntry 
{
	if ( ![selectedEntry isEqual:anEntry] )
	{
		[selectedEntry release];
		selectedEntry = [anEntry retain];
		
		// pass the entry to the text view
		[textView setSelectedRange:NSMakeRange(0,0)];
		[textView setEntry:anEntry];
		[textView setSelectedRange:NSMakeRange(0,0)];
		[textView scrollRangeToVisible:NSMakeRange(0,0)];
		
		// set the default style if the entry's length is 0
		if ( [[anEntry valueForKey:@"attributedContent"] length] == 0 )
			[textView applyDefaultStyleAndRuler];
		
		[[textView window] invalidateCursorRectsForView:textView];
	}
}

- (NSArray*) selectedEntries 
{
	return selectedEntries;
}

- (void) setSelectedEntries:(NSArray*)anArray 
{
	loadingEntries = YES;
	
	if ( selectedEntries != anArray ) 
	{
		[selectedEntries release];
		selectedEntries = [anArray retain];
		
		// determine the single, selected entry
		if ( [selectedEntries count] == 1 )
			[self setSelectedEntry:[selectedEntries objectAtIndex:0]];
		else
		{
			[self setSelectedEntry:nil];
		}
	}
	
	loadingEntries = NO;
}

- (JournlerJournal*) journal
{
	return journal;
}

- (void) setJournal:(JournlerJournal*) aJournal
{
	if ( journal != aJournal )
	{
		[journal release];
		journal = [aJournal retain];
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

#pragma mark -

- (void) setFullScreen:(BOOL)isFullScreen
{
	// pass the message to the text view to set the inset
	[textView setFullScreen:isFullScreen];
	
	// reset our scale value
	NSInteger scale;
	
	if ( isFullScreen == YES )
		scale = [[NSUserDefaults standardUserDefaults] integerForKey:@"EntryTextFullscreenZoom"];
	else
		scale = [[NSUserDefaults standardUserDefaults] integerForKey:@"EntryTextDefaultZoom"];
	
	NSMenuItem *scaleItem = [[scalePop menu] itemWithTag:scale];
	if ( scaleItem != nil )
	{
		[scalePop selectItem:scaleItem];
		[[scaleItem target] performSelector:[scaleItem action] withObject:scaleItem];
	}
	
	// set the margin on the text view - depends on fullscreen status
	NSInteger margin = ( isFullScreen 
			? [[NSUserDefaults standardUserDefaults] integerForKey:@"EntryTextHorizontalInsetFullscreen"]
			: [[NSUserDefaults standardUserDefaults] integerForKey:@"EntryTextHorizontalInset"] );
		
	NSMenuItem *marginItem = [[marginPop menu] itemWithTag:margin];
	if ( marginItem != nil )
	{
		[marginPop selectItem:marginItem];
		[[marginItem target] performSelector:[marginItem action] withObject:marginItem];
	}
}

#pragma mark -

- (BOOL) headerHidden
{
	return headerHidden;
}

- (void) setHeaderHidden:(BOOL)hidden
{
	static NSInteger kHeaderHeight = 80;
	
	if ( headerHidden != hidden )
	{
		headerHidden = hidden;
		NSRect textFrame = [[textView enclosingScrollView] frame];
		NSRect stylesFrame = [[stylesBar view] frame];

		if ( headerHidden == YES )
		{
			textFrame.size.height += kHeaderHeight;
			stylesFrame.origin.y += kHeaderHeight;
			
			[headerView retain];
			[headerView removeFromSuperview];
			
			NSInteger contentBorders[4] = {1,0,0,0};
			[contentView setBorders:contentBorders];
		}
		else
		{			
			NSRect contentFrame = [contentView frame];
			NSRect headerFrame = NSMakeRect( 1, contentFrame.size.height - kHeaderHeight, contentFrame.size.width - 2, kHeaderHeight);
			
			textFrame.size.height -= kHeaderHeight;
			stylesFrame.origin.y -= kHeaderHeight;
			
			[headerView retain];
			[headerView removeFromSuperview];
			
			[headerView setFrame:headerFrame];
			[contentView addSubview:headerView];
			
			NSInteger contentBorders[4] = {0,0,0,0};
			[contentView setBorders:contentBorders];

		}
		
		[[textView enclosingScrollView] setFrame:textFrame];
		[[stylesBar view] setFrame:stylesFrame];
		
		// adjust the styles bar
		
		/*
		if ( [self stylesBarVisible] ) 
		{
			NSRect scrollFrame = [[textView enclosingScrollView] frame];
			NSRect stylesFrame = [[stylesBar view] frame];

			scrollFrame.size.height -= stylesFrame.size.height;
			stylesFrame.size.width = scrollFrame.size.width;
			stylesFrame.origin.x = scrollFrame.origin.x;
			stylesFrame.origin.y = scrollFrame.origin.y + scrollFrame.size.height;
			
			[[stylesBar view] setFrame:stylesFrame];
			[[textView enclosingScrollView] setFrame:scrollFrame];
		}
		*/
		
		[contentView setNeedsDisplay:YES];
	}
}

- (BOOL) footerHidden
{
	return footerHidden;
}

- (void) setFooterHidden:(BOOL)hidden
{
	if ( footerHidden != hidden )
	{
		footerHidden = hidden;
		
		NSRect footerFrame;
		NSRect textFrame = [[textView enclosingScrollView] frame];
		
		[statusBar retain];
		[statusBar removeFromSuperview];
		
		if ( footerHidden )
		{
			textFrame.origin.y-=20;
			textFrame.size.height+=20;
		}
		else
		{
			textFrame.origin.y+=20;
			textFrame.size.height-=20;
			footerFrame = NSMakeRect(textFrame.origin.x, textFrame.origin.y-21, textFrame.size.width, 20);
			
			[statusBar setFrame:footerFrame];
			[contentView addSubview:statusBar];
			
			// update the live word count to get the latest measurement
			if ( [self selectedEntry] != nil )
				[self updateLiveCount];
		}
		
		[[textView enclosingScrollView] setFrame:textFrame];
		[contentView setNeedsDisplay:YES];
	}
}

- (BOOL) rulerVisible 
{ 
	return [textView isRulerVisible]; 
}

- (void) setRulerVisible:(BOOL)visible 
{
	//store this value in defaults
	[[NSUserDefaults standardUserDefaults] setBool:visible forKey:@"EntryTextShowRuler"];
	
	// assuming the presence of the ruler is bound to the styles bar
	[self setStylesBarVisible:visible];
	
	// determine the header borders
	[self _determineHeaderBorders];
}

- (BOOL) stylesBarVisible 
{ 
	return stylesBarVisible; 
}

- (void) setStylesBarVisible:(BOOL)visible 
{	
	if ( stylesBarVisible != visible )
	{
		stylesBarVisible = visible;
		
		NSRect scrollFrame = [[textView enclosingScrollView] frame];
		NSRect stylesFrame = [[stylesBar view] frame];
		
		if ( stylesBarVisible ) 
		{
			scrollFrame.size.height -= stylesFrame.size.height;
			stylesFrame.size.width = scrollFrame.size.width;
			stylesFrame.origin.x = scrollFrame.origin.x;
			stylesFrame.origin.y = scrollFrame.origin.y + scrollFrame.size.height;
			
			
			[[stylesBar view] setFrame:stylesFrame];
			[contentView addSubview:[stylesBar view]];
		}
		else
		{
			scrollFrame.size.height += stylesFrame.size.height;
			
			[[stylesBar view] removeFromSuperview];
		}
		
		[[textView enclosingScrollView] setFrame:scrollFrame];
		[contentView setNeedsDisplay:YES];
	}
}

#pragma mark -

- (NSColor*) headerBackgroundColor
{
	return headerBackgroundColor;
}

- (void) setHeaderBackgroundColor:(NSColor*)aColor
{
	if ( headerBackgroundColor != aColor )
	{
		[headerBackgroundColor release];
		headerBackgroundColor = [aColor retain];
		
		if ( headerBackgroundColor != nil )
		{
			NSColor *grayscaleColor = [headerBackgroundColor colorUsingColorSpace:[NSColorSpace genericGrayColorSpace]];
			if ( [grayscaleColor isEqual:[NSColor whiteColor]] )
			{
				[self setHeaderIsWhite:YES];
				//[headerView setBorders:(int[]){1,0,0,0}];
				[headerView setGradientStartColor:[NSColor whiteColor]];
				[headerView setGradientEndColor:[NSColor whiteColor]];
				[self _determineHeaderBorders];
			}
			else
			{
				[self setHeaderIsWhite:NO];
				//[headerView setBorders:(int[]){1,0,1,0}];
				[headerView setGradientStartColor:[[headerBackgroundColor highlightWithLevel:0.2] colorWithAlphaComponent:0.6]];
				[headerView setGradientEndColor:[[headerBackgroundColor shadowWithLevel:0.2] colorWithAlphaComponent:0.6]];
				[self _determineHeaderBorders];
			}
			
			[headerView setNeedsDisplay:YES];
		}
	}
}

- (NSColor*) textBackgroundColor
{
	return textBackgroundColor;
}

- (void) setTextBackgroundColor:(NSColor*)aColor
{
	if ( textBackgroundColor != aColor )
	{
		[textBackgroundColor release];
		textBackgroundColor = [aColor retain];
		
		if ( textBackgroundColor != nil )
		{
			[textView setBackgroundColor:textBackgroundColor];
		}
	}
}

- (NSColor*) headerLabelColor
{
	return headerLabelColor;
}

- (void) setHeaderLabelColor:(NSColor*)aColor
{
	if ( headerLabelColor != aColor )
	{
		[headerLabelColor release];
		headerLabelColor = [aColor retain];
		
		if ( headerLabelColor == nil )
			headerLabelColor = [[NSColor colorWithCalibratedWhite:0.75 alpha:1.0] retain];
	}
}

- (NSColor*) headerTextColor
{
	return headerTextColor;
}

- (void) setHeaderTextColor:(NSColor*)aColor
{
	if ( headerTextColor != aColor )
	{
		[headerTextColor release];
		headerTextColor = [aColor retain];
		
		if ( headerTextColor == nil )
			headerTextColor = [[NSColor colorWithCalibratedWhite:0.00 alpha:1.0] retain];
	}
}

- (BOOL) headerIsWhite
{
	return headerIsWhite;
}

- (void) setHeaderIsWhite:(BOOL)isWhite
{
	headerIsWhite = isWhite;
}

#pragma mark -

-(void) _determineHeaderBorders
{
	// depends on a white background and a visible ruler
	
	if ( [self rulerVisible] )
	{
		[headerView setBorders:(int[]){1,0,1,0}];
	}
	else
	{
		if ( [self headerIsWhite] )
			[headerView setBorders:(int[]){1,0,0,0}];
		else
			[headerView setBorders:(int[]){1,0,1,0}];
	}
}

- (BOOL) commitEditing
{
	return [objectController commitEditing];
}

- (IBAction) performFindPanelAction:(id)sender
{
	[[[self contentView] window] makeFirstResponder:textView];
	[textView performFindPanelAction:sender];
}

- (BOOL) highlightString:(NSString*)aString
{
	if ( aString == nil || [aString length] == 0 )
		return NO;
	
    NSArray *components = [aString componentsSeparatedByString:@" "];
    NSMutableArray *allRanges = [NSMutableArray array];
	BOOL schonScrolled = NO;
	
    for ( NSString *aComponent in components )
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

- (void) appropriateFirstResponder:(NSWindow*)window
{
	[window makeFirstResponder:textView];
}

- (void) appropriateFirstResponderForNewEntry:(NSWindow*)window
{
	// fork the first repsonder based on preferece
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"QuickEntryFocusesTitle"] && [self headerHidden] == NO )
		[window makeFirstResponder:titleField];
	else
		[window makeFirstResponder:textView];
}

- (void) establishKeyViews:(NSView*)previous nextKeyView:(NSView*)next
{
	[previous setNextKeyView:textView];
	[textView setNextKeyView:titleField];
	[titleField setNextKeyView:categoryField];
	[categoryField setNextKeyView:tagsField];
	[tagsField setNextKeyView:next];
}

- (void) ownerWillClose
{
	[textView ownerWillClose:nil];
	
	[objectController unbind:@"contentObject"];
	[objectController setContent:nil];
	
	[self unbind:@"headerBackgroundColor"];
	[self unbind:@"textBackgroundColor"];
	[self unbind:@"headerLabelColor"];
	[self unbind:@"headerTextColor"];
}

- (IBAction) printDocument:(id)sender
{
	//#warning implmenet
}

- (IBAction) setMargin:(id)sender
{
	[self _setMargin:[sender tag]];
}

- (void) _setMargin:(NSInteger)margin
{
	[[NSUserDefaults standardUserDefaults] setInteger:margin forKey:([textView inFullScreen] ? @"EntryTextHorizontalInsetFullscreen" : @"EntryTextHorizontalInset" )];
}

- (IBAction) scaleText:(id)sender
{
	NSInteger scale = [sender tag];
	[[NSUserDefaults standardUserDefaults] setInteger:scale forKey:([textView inFullScreen] ? @"EntryTextFullscreenZoom" : @"EntryTextDefaultZoom" )];
	[textView scaleText:sender];
}

- (void) servicesMenuAppendSelection:(NSPasteboard*)pboard desiredType:(NSString*)type
{
	if ( [self selectedEntry] == nil )
	{
		// ensure an entry is available before appending any data to it
		if ( [[self delegate] respondsToSelector:@selector(entryCellController:newDefaultEntry:)] && 
				![[self delegate] entryCellController:self newDefaultEntry:nil] )
			return;
	}
	
	[textView setSelectedRange:NSMakeRange([[textView string] length],0)];
	[textView insertText:@"\n\n"];
	[textView readSelectionFromPasteboard:pboard type:type];
	[textView insertText:@"\n\n"];
}

#pragma mark -
#pragma mark TextView Delegation


- (void)textViewDidChangeSelection:(NSNotification *)aNotification
{
	if ( [aNotification object] == textView && [self footerHidden] == NO 
		&& [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryTextShowWordCount"] )
	{
    #ifdef __DEBUG__
		NSLog(@"%s",__PRETTY_FUNCTION__);
    #endif
		
		[self updateLiveCount];
	}
}

- (void) textView:(LinksOnlyNSTextView*)aTextView rulerToggling:(NSNotification*)aNotification
{
	[self setRulerVisible:[textView isRulerVisible]];
}

- (BOOL) textView:(LinksOnlyNSTextView*)aTextView newDefaultEntry:(NSNotification*)aNotification
{
	if ( [[self delegate] respondsToSelector:@selector(entryCellController:newDefaultEntry:)] )
		return [[self delegate] entryCellController:self newDefaultEntry:aNotification];
	else
		return NO;
}

- (BOOL) textViewIsInFullscreenMode:(LinksOnlyNSTextView*)aTextView
{
	if ( aTextView != textView )
		return NO;
	
	// pass it up the chain if the chain respects it, otherwise definitely not fullscreen
	if ( [[self delegate] respondsToSelector:@selector(textViewIsInFullscreenMode:)] )
		return [[self delegate] textViewIsInFullscreenMode:aTextView];
	else
		return NO;
}

- (void)textView:(NSTextView *)aTextView clickedOnCell:(id <NSTextAttachmentCell>)cell inRect:(NSRect)cellFrame atIndex:(NSUInteger)charIndex 
{
	// checks for a checkbox and reverses the value and picture
	
	if ( aTextView != textView )
		return;
		
	NSString *actualPreferred = [[[cell attachment] fileWrapper] preferredFilename];
	if ( !( [actualPreferred isEqualToString:@"PDCheckboxChecked.png"] || [actualPreferred isEqualToString:@"PDCheckboxUnchecked.png"] ) )
		return;
	
	NSString *preferredName;
	NSImage *tempImage;
	
	if ( [actualPreferred isEqualToString:@"PDCheckboxUnchecked.png"] ) 
	{
		tempImage = [NSImage imageNamed:@"checkboxchecked.tif"];
		preferredName = @"PDCheckboxChecked.png";
	}
	else 
	{
		tempImage = [NSImage imageNamed:@"checkboxunchecked.tif"];
		preferredName = @"PDCheckboxUnchecked.png";
	}
	
	NSBitmapImageRep *bitmapRep = [[[NSBitmapImageRep alloc] initWithData:[tempImage TIFFRepresentation]] autorelease];
	NSFileWrapper *newWrapper = [[[NSFileWrapper alloc]
			initRegularFileWithContents:[bitmapRep representationUsingType:NSPNGFileType properties:nil]] autorelease];
			
	[newWrapper setPreferredFilename:preferredName];
	NSTextAttachment *newAttachment = [[[NSTextAttachment alloc] initWithFileWrapper:newWrapper] autorelease];
	
	if ( ![aTextView shouldChangeTextInRange:NSMakeRange(charIndex,1) 
			replacementString:[NSString stringWithCharacters: (const unichar[]){NSAttachmentCharacter} length:1]] ) 
	{
		NSBeep();
		return;
	}
	
	[[aTextView textStorage] beginEditing];
	[[aTextView textStorage] removeAttribute:NSAttachmentAttributeName range:NSMakeRange(charIndex,1)];
	[[aTextView textStorage] addAttribute:NSAttachmentAttributeName value:newAttachment range:NSMakeRange(charIndex,1)];
	[[aTextView textStorage] endEditing];
	[aTextView didChangeText];
}

- (BOOL)textView:(NSTextView *)aTextView 
		clickedOnLink:(id)link 
		atIndex:(NSUInteger)charIndex 
{
	static NSString *http_scheme = @"http";

	// This is necessary because of the way I insert an iTunes link?
	if ( ![link isKindOfClass:[NSURL class]] ) 
	{
		if ( [link isKindOfClass:[NSString class]] )
			link = [NSURL URLWithString:link];
		else
			return NO;
	}
	
	NSString *scheme = [(NSURL*)link scheme];
	if ( scheme == nil ) 
		return NO;
	
	if ( [link isJournlerURI] ) 
	{
		if ( [link isJournlerHelpURI] )
		{
			NSString *helpAnchor = [[link path] lastPathComponent];
			if ( helpAnchor == nil ) NSBeep();
			else if ( [helpAnchor isEqualToString:@"JournlerHelpIndex"] ) [NSApp showHelp:self];
			else [[NSHelpManager sharedHelpManager] openHelpAnchor:helpAnchor inBook:@"JournlerHelp"];
		}
		
		else if ( [link isJournlerEntry] ) 
		{
			JournlerEntry *theEntry = (JournlerEntry*)[[self valueForKey:@"journal"] objectForURIRepresentation:link];
			if ( theEntry != nil ) 
			{
				if ( [[self delegate] respondsToSelector:@selector(entryCellController:clickedOnEntry:modifierFlags:highlight:)] )
					[[self delegate] entryCellController:self 
							clickedOnEntry:theEntry 
							modifierFlags:[textView modifierFlags] 
							highlight:nil];
				else
					NSBeep();
			}
			else 
			{
				NSLog(@"%s - unable to read entry link: %@", __PRETTY_FUNCTION__, [(NSURL*)link absoluteString]);
				NSBeep();
			}
		}
		
		else if ( [link isJournlerFolder] )
		{
			JournlerCollection *theFolder = (JournlerCollection*)[[self valueForKey:@"journal"] objectForURIRepresentation:link];
			if ( theFolder != nil )
			{
				if ( [[self delegate] respondsToSelector:@selector(entryCellController:clickedOnFolder:modifierFlags:)] )
					[[self delegate] entryCellController:self 
							clickedOnFolder:theFolder 
							modifierFlags:[textView modifierFlags]];
				else
					NSBeep();
			}
			else 
			{
				NSLog(@"%s - unable to read folder link: %@", __PRETTY_FUNCTION__, [(NSURL*)link absoluteString]);
				NSBeep();
			}
			
		}
		
		else if ( [link isJournlerResource] )
		{
			JournlerResource *theResource = (JournlerResource*)[[self valueForKey:@"journal"] objectForURIRepresentation:link];
			if ( theResource != nil )
			{
				if ( [[self delegate] respondsToSelector:@selector(entryCellController:clickedOnResource:modifierFlags:highlight:)] )
					[[self delegate] entryCellController:self 
							clickedOnResource:theResource 
							modifierFlags:[textView modifierFlags] 
							highlight:nil];
				else
					NSBeep();
			}
			else
			{
				NSBeep();
				[[NSAlert resourceNotFound] runModal];
				NSLog(@"%s - unable to read resource link: %@", __PRETTY_FUNCTION__, [(NSURL*)link absoluteString]);
			}
		}
		
		// journler handled the link, successfully or not
		return YES;
	}
	
	else if ( [scheme isEqualToString:http_scheme] ) 
	{
		if ( [[self delegate] respondsToSelector:@selector(entryCellController:clickedOnURL:modifierFlags:)] )
			[[self delegate] entryCellController:self 
					clickedOnURL:link 
					modifierFlags:[textView modifierFlags]];
		
		// viewing a url, journler handled it
		return YES;
	}
	
	else 
	{
		// anything else is handled by the next object
		return NO;
	}
	
}

- (void) textView:(LinksOnlyNSTextView*)aTextView 
		showLexiconSelection:(JournlerObject*)anObject 
		term:(NSString*)aTerm
{
	// simulate a resource or entry selection and then set the term highlight
	
	NSInteger eventModifiers = 0;
	NSInteger modifiers = GetCurrentKeyModifiers();
	
	if ( modifiers & shiftKey ) eventModifiers |= NSShiftKeyMask;
	if ( modifiers & optionKey ) eventModifiers |= NSAlternateKeyMask;
	if ( modifiers & cmdKey ) eventModifiers |= NSCommandKeyMask;
	if ( modifiers & controlKey ) eventModifiers |= NSControlKeyMask;
	
	if ( [anObject isKindOfClass:[JournlerEntry class]] )
	{
		JournlerEntry *theEntry = (JournlerEntry*)anObject;
		if ( theEntry != nil ) 
		{
			if ( [[self delegate] respondsToSelector:@selector(entryCellController:clickedOnEntry:modifierFlags:highlight:)] )
				[[self delegate] entryCellController:self clickedOnEntry:theEntry modifierFlags:eventModifiers highlight:aTerm];
			else
				NSBeep();
		}
		
		//if ( [[self delegate] respondsToSelector:@selector(highlightString:)] )
		//	[[self delegate] highlightString:aTerm];
	}
	
	else if ( [anObject isKindOfClass:[JournlerResource class]] )
	{
		JournlerResource *theResource = (JournlerResource*)anObject;
		if ( theResource != nil )
		{
			if ( [[self delegate] respondsToSelector:@selector(entryCellController:clickedOnResource:modifierFlags:highlight:)] )
				[[self delegate] entryCellController:self clickedOnResource:theResource modifierFlags:eventModifiers highlight:aTerm];
			else
				NSBeep();
		}
		
		//if ( [[self delegate] respondsToSelector:@selector(highlightString:)] )
		//	[[self delegate] highlightString:aTerm];
	}
	
	else
	{
		NSBeep();
	}
}

/*
- (NSString *)textView:(NSTextView *)aTextView 
		willDisplayToolTip:(NSString *)tooltip forCharacterAtIndex:(NSUInteger)characterIndex
{
	if ( aTextView != textView )
		return tooltip;
	
	// if there is no link at this location, return nil
	NSURL *theURL;
	id theLink = [[aTextView textStorage] attribute:NSLinkAttributeName atIndex:characterIndex effectiveRange:NULL];
	if ( theLink == nil )
		return tooltip;
	
	// ensure the url is a link, bailing if unable to affect a conversion
	if ( [theLink isKindOfClass:[NSURL class]] )
		theURL = theLink;
	else if ( [theLink isKindOfClass:[NSString class]] )
		theURL = [NSURL URLWithString:theLink];
	else
		return tooltip;
	
	// convert the url to a resource, bailing if not possible
	JournlerResource *theResource = nil;
	if ( [theURL isJournlerResource] )
		theResource = [[self journal] objectForURIRepresentation:theURL];
	
	if ( theResource == nil )
		return tooltip;
	
	NSString *actualTooltip = nil;
	
	if ( [theResource representsURL] )
		actualTooltip = [theResource valueForKey:@"urlString"];
	else if ( [theResource representsJournlerObject] )
		actualTooltip = [NSString stringWithFormat:@"%@ (Journler)", [theResource valueForKeyPath:@"journlerObject.title"]];
	else if ( [theResource representsFile] )
		actualTooltip = [NSString stringWithFormat:@"%@ (%@)", [theResource valueForKey:@"title"], 
				[(NSString*)UTTypeCopyDescription( (CFStringRef)[theResource valueForKey:@"uti"] ) autorelease]];
	else if ( [theResource representsABRecord] )
		actualTooltip = [theResource valueForKey:@"person.fullname"];
	
	return actualTooltip;
}
*/

#pragma mark -


- (NSImage*) textView:(LinksOnlyNSTextView*)aTextView dragImageForSelectionWithEvent:(NSEvent *)event origin:(NSPointPointer)origin
{
	if ( draggedResource == nil )
		return nil;
	
	NSImage *returnImage = nil;
	
	NSString *title = [draggedResource valueForKey:@"title"];
	if ( title == nil ) title = [[draggedResource URIRepresentation] absoluteString];
	NSImage *icon = [[draggedResource valueForKey:@"icon"] imageWithWidth:32 height:32 inset:0];
	
	NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.96]];
	[shadow setShadowOffset:NSMakeSize(1,-1)];
	
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys: 
	[NSFont systemFontOfSize:11], NSFontAttributeName,
	[NSColor colorWithCalibratedWhite:0.01 alpha:1.0], NSForegroundColorAttributeName, 
	shadow, NSShadowAttributeName, nil];
	
	NSSize iconSize = [icon size];
	NSSize stringSize = [title sizeWithAttributes:attributes];
	
	//float myWidth = 400;
	float proposedWidth = iconSize.width+stringSize.width+20;
	
	returnImage = [[[NSImage alloc] initWithSize:NSMakeSize( proposedWidth , 
		(iconSize.height >= stringSize.height ? iconSize.height : stringSize.height) + 6)] autorelease];

	[returnImage lockFocus];
	
	[[NSColor colorWithCalibratedWhite:0.25 alpha:0.3] set];
	[[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0,6,[returnImage size].width,[returnImage size].height-6) cornerRadius:10.0] fill];
	
	[[NSColor colorWithCalibratedWhite:0.5 alpha:0.3] set];
	[[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0,6,[returnImage size].width,[returnImage size].height-6) cornerRadius:10.0] stroke];	
	[[icon imageWithWidth:26 height:26] compositeToPoint:NSMakePoint(6,8) operation:NSCompositeSourceOver fraction:1.0];
	[title drawAtPoint:NSMakePoint(iconSize.width+7,8) withAttributes:attributes];
	
	[returnImage unlockFocus];
	
	// match up the cursor to the image location
	NSPoint image_location = [aTextView convertPoint:[event locationInWindow] fromView:nil];
	image_location.x -= 12; image_location.y += 12;
	
	origin->x = image_location.x;
	origin->y = image_location.y;
	
	// clear out the retained resource
	[draggedResource release];
	draggedResource = nil;
	
	return returnImage;
}

- (NSArray *)textView:(NSTextView *)aTextView writablePasteboardTypesForCell:(id <NSTextAttachmentCell>)cell atIndex:(NSUInteger)charIndex
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	if ( aTextView != textView )
		return nil;
	
	// if there is no link at this location, return nil
	NSURL *theURL;
	id theLink = [[aTextView textStorage] attribute:NSLinkAttributeName atIndex:charIndex effectiveRange:NULL];
	if ( theLink == nil )
		return nil;
	
	// ensure the url is a link, bailing if unable to affect a conversion
	if ( [theLink isKindOfClass:[NSURL class]] )
		theURL = theLink;
	else if ( [theLink isKindOfClass:[NSString class]] )
		theURL = [NSURL URLWithString:theLink];
	else
		return nil;
	
	// convert the url to a resource, bailing if not possible
	JournlerResource *theResource = nil;
	if ( [theURL isJournlerResource] )
		theResource = [[self journal] objectForURIRepresentation:theURL];
	
	if ( theResource == nil )
		return nil;
	else
	{
		if ( draggedResource != nil ) [draggedResource release];
		draggedResource = [theResource retain];
	}
	
	NSArray *types = nil;
	
	if ( [theResource representsABRecord] )
	{
		types = [NSArray arrayWithObjects:PDResourceIDPboardType, NSFilenamesPboardType, nil];
	}
	else if ( [theResource representsFile] )
	{
		if ( [NSImage canInitWithFile:[theResource originalPath]] )
			types = [NSArray arrayWithObjects:PDResourceIDPboardType, NSTIFFPboardType, NSFilenamesPboardType, nil];
		else
			types = [NSArray arrayWithObjects:PDResourceIDPboardType, NSFilenamesPboardType, nil];
	}
	else
	{
		types = [NSArray arrayWithObject:PDResourceIDPboardType];
	}
	
	return types;
}

- (BOOL)textView:(NSTextView *)aTextView writeCell:(id <NSTextAttachmentCell>)cell 
		atIndex:(NSUInteger)charIndex toPasteboard:(NSPasteboard *)pboard type:(NSString *)type
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	if ( aTextView != textView )
		return NO;
	
	// if there is no link at this location, return NO
	if ( [[aTextView textStorage] attribute:NSLinkAttributeName atIndex:charIndex effectiveRange:NULL] == nil )
		return NO;
	
	// if there is no link at this location, return nil
	NSURL *theURL;
	id theLink = [[aTextView textStorage] attribute:NSLinkAttributeName atIndex:charIndex effectiveRange:NULL];
	if ( theLink == nil )return NO;
	
	// ensure the url is a link, bailing if unable to affect a conversion
	if ( [theLink isKindOfClass:[NSURL class]] )
		theURL = theLink;
	else if ( [theLink isKindOfClass:[NSString class]] )
		theURL = [NSURL URLWithString:theLink];
	else
		return NO;
	
	// convert the url to a resource, bailing if not possible
	JournlerResource *theResource = nil;
	if ( [theURL isJournlerResource] )
		theResource = [[self journal] objectForURIRepresentation:theURL];
	
	if ( theResource == nil )
		return NO;
	
	BOOL success = NO;
	
	if ( [type isEqualToString:NSFilenamesPboardType] )
	{
		// write the item to the temp directory and put the file's path on the pasteboard
		NSString *actualPath = [theResource createFileAtDestination:TempDirectory()];
		if ( actualPath != nil )
			success = [pboard setPropertyList:[NSArray arrayWithObject:actualPath] forType:type];
	}

	else if ( [type isEqualToString:NSTIFFPboardType] && [NSImage canInitWithFile:[theResource originalPath]] )
	{
		// put a tiff representation of the receiver on the pasteboard
		NSImage *theImage = [[[NSImage alloc] initWithContentsOfFile:[theResource originalPath]] autorelease];
		NSData *tiffData = [theImage TIFFRepresentation];
		
		if ( theImage != nil && tiffData != nil )
			success = [pboard setData:tiffData forType:type];
	}
	
	else if ( [type isEqualToString:PDResourceIDPboardType] )
	{
		NSArray *uris = [NSArray arrayWithObject:[[theResource URIRepresentation] absoluteString]];
		success = [pboard setPropertyList:uris forType:PDResourceIDPboardType];
	}
	
	return success;
}


#pragma mark -
#pragma mark TextStorage Delegation

- (void) wordCountDidChange:(NSNotification*)aNotification
{
	//NSLog(@"Word count: %i",[[aNotification object] wordCount]);
	
	if ( [aNotification object] == [textView textStorage] && [self footerHidden] == NO && [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryTextShowWordCount"] )
	{
		#ifdef __DEBUG__
		NSLog(@"%s",__PRETTY_FUNCTION__);
		#endif
		
		[self updateLiveCount];
	}
}

- (void)textStorageWillProcessEditing:(NSNotification *)aNotification
{
	// surround the whole thing in a try blog
	//@try
	//{
		
		static unichar kRegularQuote = 0x0022;
		
		NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
		
		// return immediately if an entry is being loaded or if there is no text
		if ( loadingEntries || [(NSTextStorage*)[aNotification object] length] == 0 )
			return;
		
		NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
		
		// check for curly quotes if we're running Tiger
		if ( [aNotification object] == [textView textStorage] && [ud boolForKey:@"EntryTextUseSmartQuotes"] 
				&& ![textView respondsToSelector:@selector(isAutomaticQuoteSubstitutionEnabled)] )
		{
			NSTextStorage *textStorage = [aNotification object];
			NSRange editedRange = [textStorage editedRange];
			NSString *string = [textStorage string];
			NSString *editedString = [string substringWithRange:editedRange];
			
			if ( [editedString length] != 0 && [string length] != 0 )
			{
				CFStringInlineBuffer buffer; // dip into CF calls for faster string manipulation
				CFStringInitInlineBuffer((CFStringRef)editedString,&buffer,CFRangeMake(0,[editedString length]));
				
				NSMutableAttributedString *editedStringReplacement = nil;
				NSCharacterSet *whiteSpaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
				
				NSInteger i;
				for ( i = 0; i < [editedString length]; i++ )
				{
					UniChar aCharacter = CFStringGetCharacterFromInlineBuffer(&buffer,i);
					if ( aCharacter == kRegularQuote ) {
						
						if ( editedStringReplacement == nil )
							editedStringReplacement = [[[textStorage attributedSubstringFromRange:editedRange] 
							mutableCopyWithZone:[self zone]] autorelease];
						
						// determine if an open or closed quote is to be used
						if ( i == 0 && editedRange.location != 0 && ![whiteSpaceSet characterIsMember:[string characterAtIndex:editedRange.location-1]] )
							[editedStringReplacement replaceCharactersInRange:NSMakeRange(i,1) withString:closeSmartQuote];
						else
							[editedStringReplacement replaceCharactersInRange:NSMakeRange(i,1) withString:openSmartQuote];
						
						// make the replacment
						[textStorage beginEditing];
						[textStorage replaceCharactersInRange:editedRange withAttributedString:editedStringReplacement];
						[textStorage endEditing];
					}
				}
			}
		}	
		
		// check for urls, links and autocorrect only after a space, and satisying othe conditions
		if ( [aNotification object] == [textView textStorage] && ( [ud boolForKey:@"EntryTextRecognizeWikiLinks"] || 
				[ud boolForKey:@"EntryTextRecognizeURLs"] || [ud boolForKey:@"EntryTextAutoCorrectSpelling"] ) )
		{
			NSTextStorage *textStorage = [aNotification object];
			NSRange editedRange = [textStorage editedRange];
			NSString *string = [textStorage string];
			NSString *editedString = [string substringWithRange:editedRange];
			NSCharacterSet *whiteSpaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
			
			if ( [editedString length] != 0 && [string length] != 0 && [editedString length] != [[textView string] length] &&
					[whiteSpaceSet characterIsMember:[editedString characterAtIndex:0]] ) 
			{
				[self processTextForLinksAndMisspelledWords:textStorage range:editedRange];
			}
		}
		
	/*
	}
	@catch (NSException *localException)
	{
		NSLog(@"%s - exception processing entry text %@", __PRETTY_FUNCTION__, localException);
	}
	@finally
	{
	
	}
	*/
	
	[thePool release];
}


- (BOOL) processTextForLinksAndMisspelledWords:(NSTextStorage*)aTextStorage range:(NSRange)aRange
{	
	// returns YES if what? Looks to be unused.
	
	static NSString *fileUrlIdentifier = @"file://";
	static NSString *urlIdentifier = @"://";
	static NSString *httpScheme = @"http";
	
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

	NSTextStorage *textStorage = aTextStorage;
	NSRange editedRange = aRange;
	
    NSString *string = [textStorage string];
	
    NSRange area = editedRange;
    NSUInteger length = [string length];
    NSRange start, end;
    NSCharacterSet *whiteSpaceSet;
    NSUInteger areamax = NSMaxRange(area);
	NSRange found;
	NSString *word;
	
	BOOL edited = NO;
	
    // extend our range along word boundaries.
    whiteSpaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    start = [string rangeOfCharacterFromSet:whiteSpaceSet options:NSBackwardsSearch range:NSMakeRange(0, area.location)];
	
    if (start.location == NSNotFound) 
	{
        start.location = 0;
    }  
	else 
	{
        start.location = NSMaxRange(start);
    }
	
    end = [string rangeOfCharacterFromSet:whiteSpaceSet options:0 range:NSMakeRange(areamax, length - areamax)];
    if (end.location == NSNotFound)
        end.location = length;
	
    area = NSMakeRange(start.location, end.location - start.location);
    if (area.length == 0) return NO; // bail early
	
	while (area.length) 
	{
		// find the next word
		end = [string rangeOfCharacterFromSet:whiteSpaceSet options:0 range:area];
		if (end.location == NSNotFound) 
		{
			end = found = area;
		} 
		else 
		{
			found.length = end.location - area.location;
			found.location = area.location;
		}
		
		if ( found.location != NSNotFound && found.length != 0 )
		{
			NSURL *entryURI;
			word = [string substringWithRange:found];
			
			// do not do anything with this word if it begins with an @ character
			if ( [word length] > 0 && [word characterAtIndex:0] == '@' )
			{
				;
			}
			else
			{
				// check for urls
				if ( [ud boolForKey:@"EntryTextRecognizeURLs"] )
				{
					if ( [[self textView] respondsToSelector:@selector(isAutomaticLinkDetectionEnabled)] )
					{
						// leopard
						// the url will already been in place for the range and word, 
						// so grab the url without editing the text and create either a file or url resource
							
						// grab the attribute and convert it to a url if necessary
						
						NSURL *url = nil;
						NSRange urlRange = NSMakeRange(NSNotFound, 0);
						//id urlAttribute = [[[self textView] textStorage] attribute:NSLinkAttributeName atIndex:found.location effectiveRange:NULL];
						id urlAttribute = [[[self textView] textStorage] attribute:NSLinkAttributeName 
								atIndex:found.location 
								longestEffectiveRange:&urlRange 
								inRange:NSMakeRange(0, [[[self textView] textStorage] length])];
						
						if ( [urlAttribute isKindOfClass:[NSURL class]] )
							url = urlAttribute;
						else if ( [urlAttribute isKindOfClass:[NSString class]] )
							url = [NSURL URLWithString:urlAttribute];
						else if ( url == nil && [word isWellformedURL] )
						{
							// a special case that does not rely on the link attribute; in fact there is none
							// -- the url is the word and the url range is the word's range
							urlRange = found;
							url = [NSURL URLWithString:word];
						}
						else
							url = nil;
							//NSLog(@"%s - unable to convert link attribute of class %@ to url, expected string or url", __PRETTY_FUNCTION__, [urlAttribute className]);
						
						if ( url != nil )
						{
							if ( [url isFileURL] )
							{
								if ( [[NSFileManager defaultManager] fileExistsAtPath:[url path]] && [textView shouldChangeTextInRange:found replacementString:nil] )
								{
									edited = YES;
									[[self selectedEntry] resourceForFile:[url path] operation:kNewResourceUseDefaults];
								}
							}
							
							else if ( [[[url scheme] lowercaseString] isEqualToString:httpScheme] )
							{
								edited = YES;
								NSString *urledText = [[[[self textView] textStorage] string] substringWithRange:urlRange];
								
								// when the urled text has more content than the single word over which the url was originally found
								// the url attribute is more encompassing (eg it came from a url drop)
								//
								// when the word is longer than the urled text, it is because the url hasn't yet been extended
								// over the entire range, which occurs as the user types with link recognition enabled on Leopard
								// use the word instead, which will reflect the desired url
								//
								// I don't like any of this, but it seems necessary 
								// because of the way the text view handles drags from OmniWeb
								
								if ( [urledText length] >= [word length] )
									[[self selectedEntry] resourceForURL:[url absoluteString] title:urledText];
								else
									[[self selectedEntry] resourceForURL:word title:word];
							}
						}
					}
					else
					{
						// tiger - need to build the url myself
						
						if ( [word rangeOfString:fileUrlIdentifier options:0 range:NSMakeRange(0,[word length])].location != NSNotFound )
						{
							// file url
							NSURL *fileURL = [NSURL URLWithString:word];
							//#warning buggy
							
							if ( [[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]] && [textView shouldChangeTextInRange:found replacementString:nil] )
							{
								// include the url with the entry - no undo
								[[self selectedEntry] resourceForFile:[fileURL path] operation:kNewResourceUseDefaults];
								
								// add the url attribute 
								[textStorage beginEditing];
								[textStorage addAttribute:NSLinkAttributeName value:fileURL range:found];
								[textStorage endEditing];
								
								[textView didChangeText];
								[[textView undoManager] setActionName:NSLocalizedString(@"undo autourl",@"")];
								
								edited = YES;
							}
						}
						
						else if ( [word rangeOfString:urlIdentifier options:0 range:NSMakeRange(0,[word length])].location != NSNotFound )
						{
							// web url
							if ( [textView shouldChangeTextInRange:found replacementString:nil] )
							{
								// include the url with the entry - no undo
								[[self selectedEntry] resourceForURL:word title:word];
								
								// add the url attribute 
								[textStorage beginEditing];
								[textStorage addAttribute:NSLinkAttributeName value:[NSURL URLWithString:word] range:found];
								[textStorage endEditing];
								
								[textView didChangeText];
								[[textView undoManager] setActionName:NSLocalizedString(@"undo autourl",@"")];
								
								edited = YES;
							}
						}
					}
				}
				
								
				// check for an entry wikilink
				if ( [ud boolForKey:@"EntryTextRecognizeWikiLinks"] && ( entryURI = [self valueForKeyPath:[NSString stringWithFormat:@"journal.entryWikisDictionary.%@", word]] ) )
				{
					if ( [textView shouldChangeTextInRange:found replacementString:nil] )
					{
						// link the entry to the object
						[[self selectedEntry] resourceForJournlerObject:[[self valueForKeyPath:@"selectedEntry.journal"] objectForURIRepresentation:entryURI]];
						
						// add the url attribute 
						[textStorage beginEditing];
						[textStorage addAttribute:NSLinkAttributeName value:entryURI range:found];
						[textStorage endEditing];
						
						[textView didChangeText];
						[[textView undoManager] setActionName:NSLocalizedString(@"undo autowiki",@"")];
						
						edited = YES;
					}
				}
				
				
				// spell checking
				if ( [ud boolForKey:@"EntryTextAutoCorrectSpelling"] )
				{
					BOOL corrected = NO;
					NSRange correctedRange;
					
					// word list spell checking - faster but not always a guaranteed hit
					if ( [ud boolForKey:@"EntryTextAutoCorrectSpellingUseWordList"] )
					{
						NSString *correctedWord = [[[NSApp delegate] autoCorrectWordList] objectForKey:word];
						if ( correctedWord != nil )
						{
							[textStorage beginEditing];
							[textStorage replaceCharactersInRange:found withString:correctedWord];
							[textStorage endEditing];
							
							[textView didChangeText];
							[[textView undoManager] setActionName:NSLocalizedString(@"undo autospelling",@"")];
							
							edited = YES;
							corrected = YES;
							correctedRange = NSMakeRange(found.location, [correctedWord length]);
						}
					}
					
					// built in educated guess spelling - slower but a correction more often
					if ( !corrected && [ud boolForKey:@"EntryTextAutoCorrectSpellingUseBuiltIn"] )
					{
						NSSpellChecker *sp = [NSSpellChecker sharedSpellChecker];
						NSRange misspelledRange = [sp checkSpellingOfString:word startingAt:0 language:nil 
						wrap:NO inSpellDocumentWithTag:[[NSApp delegate] spellDocumentTag] wordCount:NULL];
						
						if ( misspelledRange.location == 0 )
						{
							NSArray *spellingGuesses = [sp guessesForWord:word];
							if ( [spellingGuesses count] > 0 ) 
							{
								if ( [textView shouldChangeTextInRange:found replacementString:[spellingGuesses objectAtIndex:0]] )
								{
									[textStorage beginEditing];
									[textStorage replaceCharactersInRange:found withString:[spellingGuesses objectAtIndex:0]];
									[textStorage endEditing];
									
									[textView didChangeText];
									[[textView undoManager] setActionName:NSLocalizedString(@"undo autospelling",@"")];
									
									edited = YES;
									corrected = YES;
									correctedRange = NSMakeRange(found.location, [[spellingGuesses objectAtIndex:0] length]);
								}
							}
						}
						
					} // end built-in spell checking
					
					// note the correction with nifty visual effect
					if ( corrected == YES && [[self textView] respondsToSelector:@selector(showFindIndicatorForRange:)] )
						[self performSelector:@selector(showMyFindIndicatorForRange:) withObject:[NSValue valueWithRange:correctedRange] afterDelay:0.1];
					
				} // end spell checking
			} // end word processing
		} // while (area.length) 
		
		// adjust our area
		areamax = NSMaxRange(end);
		area.length -= areamax - area.location;
		area.location = areamax;
    }
	
	return edited;
}

- (void) showMyFindIndicatorForRange:(NSValue*)rangeValue
{
	// must be called after a delay, that is once the text is finished editing or else the lozenge is cleared
	[[self textView] showFindIndicatorForRange:[rangeValue rangeValue]];
}

#pragma mark -
#pragma mark Audio/Video Delegation

- (void) sproutedVideoRecorder:(SproutedRecorder*)recorder insertRecording:(NSString*)path title:(NSString*)title
{
	if ( [self valueForKey:@"selectedEntry"] == nil )
	{
		NSBeep(); return;
	}
	
	if ( title == nil )
		title = [NSString stringWithFormat:@"%@ %@", [self valueForKeyPath:@"selectedEntry.title"], NSLocalizedString(@"video recording",@"")];
	
	[textView addFileToText:path fileName:title forceTitle:YES resourceCommand:kNewResourceForceCopy];
}

- (void) sproutedAudioRecorder:(SproutedRecorder*)recorder insertRecording:(NSString*)path title:(NSString*)title
{
	if ( [self valueForKey:@"selectedEntry"] == nil )
	{
		NSBeep(); return;
	}

	if ( title == nil )
		title = [NSString stringWithFormat:@"%@ %@", [self valueForKeyPath:@"selectedEntry.title"], NSLocalizedString(@"audio recording",@"")];
	
	//kSproutedAudioSavedToiTunes
	//kSproutedAudioSavedToTemporaryLocation
	
	NSInteger saveAction = [(SproutedAudioRecorder*)recorder saveAction];
	NSInteger resourceCommand = ( saveAction == kSproutedAudioSavedToiTunes ? kNewResourceForceLink : kNewResourceForceCopy );
	
	[textView addFileToText:path fileName:title forceTitle:NO resourceCommand:resourceCommand];
}

- (void) sproutedSnapshot:(SproutedRecorder*)recorder insertRecording:(NSString*)path title:(NSString*)title
{
	if ( [self valueForKey:@"selectedEntry"] == nil )
	{
		NSBeep(); return;
	}
	
	if ( title == nil )
		title = [NSString stringWithFormat:@"%@ %@", [self valueForKeyPath:@"selectedEntry.title"], NSLocalizedString(@"snapshot recording",@"")];
	
	[textView addFileToText:path fileName:title forceTitle:YES resourceCommand:kNewResourceForceCopy];
}

#pragma mark -
#pragma mark ResourceCell Delegation

- (void) webViewController:(WebViewController*)aController appendPasteboardLink:(NSPasteboard*)pboard 
{
	NSDictionary *attributes = [[self textView] typingAttributes];
	
	[[self textView] setSelectedRange:NSMakeRange([[[self textView] textStorage] length],0)];
	NSInteger loc = [[self textView] selectedRange].location;
	
	if ( [[self textView] readSelectionFromPasteboard:pboard] )
	{
		[[self textView] setSelectedRange:NSMakeRange(loc,0)];
		[[self textView] insertText:[[[NSAttributedString alloc] initWithString:@"\n" attributes:attributes] autorelease]];
		[[self textView] setSelectedRange:NSMakeRange([[[self textView] textStorage] length],0)];
		[[self textView] insertText:[[[NSAttributedString alloc] initWithString:@" \n" attributes:attributes] autorelease]];
	}
	
	[[self textView] setTypingAttributes:attributes];
}

- (void) webViewController:(WebViewController*)aController appendPasteboardContents:(NSPasteboard*)pboard 
{
	NSDictionary *attributes = [[self textView] typingAttributes];
	
	[[self textView] setSelectedRange:NSMakeRange([[[self textView] textStorage] length],0)];
	NSInteger loc = [[self textView] selectedRange].location;
	
	if ( [[self textView] readSelectionFromPasteboard:pboard] )
	{
		[[self textView] setSelectedRange:NSMakeRange(loc,0)];
		[[self textView] insertText:[[[NSAttributedString alloc] initWithString:@"\n" attributes:attributes] autorelease]];
		[[self textView] setSelectedRange:NSMakeRange([[[self textView] textStorage] length],0)];
		[[self textView] insertText:[[[NSAttributedString alloc] initWithString:@" \n" attributes:attributes] autorelease]];
	}
	
	[[self textView] setTypingAttributes:attributes];
}

- (void) webViewController:(WebViewController*)aController appendPasetboardWebArchive:(NSPasteboard*)pboard
{
	// download the archive and append it to the entry - actually, the text view handles this quite well
	NSDictionary *attributes = [[self textView] typingAttributes];
	
	// iterate through each of the items, forcing a link
	NSArray *webURLs = [pboard propertyListForType:WebURLsWithTitlesPboardType];
	NSArray *urls = [webURLs objectAtIndex:0];
	NSArray *titles = [webURLs objectAtIndex:1];
	
	NSInteger i;
	for ( i = 0; i < [urls count]; i++ )
	{
		[[self textView] setSelectedRange:NSMakeRange([[[self textView] textStorage] length],0)];
		[[self textView] addWebArchiveToTextFromURL:[NSURL URLWithString:[urls objectAtIndex:i]] title:[titles objectAtIndex:i]];
		[[self textView] setTypingAttributes:attributes];
	}
}

#pragma mark -
#pragma mark NSTokenFieldCell Delegation

- (BOOL)tokenField:(NSTokenField *)tokenField hasMenuForRepresentedObject:(id)representedObject
{
	//NSLog(@"%s",__PRETTY_FUNCTION__);
	return YES;
}

- (NSMenu *)tokenField:(NSTokenField *)tokenField menuForRepresentedObject:(id)representedObject
{
	//NSLog(@"%s",__PRETTY_FUNCTION__);
	
	NSMenu *theMenu = nil;
	
	NSArray *results;
	representedObject = ( [representedObject isKindOfClass:[NSString class]] ? [representedObject lowercaseString] : representedObject );
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%@ in tags.lowercaseString AND markedForTrash == NO", representedObject];
		
	NSSortDescriptor *titleSort = [[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES 
	selector:@selector(localizedCaseInsensitiveCompare:)] autorelease];
	
	results = [[[journal entries] filteredArrayUsingPredicate:predicate] sortedArrayUsingDescriptors:[NSArray arrayWithObject:titleSort]];
	
	if ( [results count] > 0 )
	{
		theMenu = [[[NSMenu alloc] initWithTitle:[NSString string]] autorelease];
        NSSize size = NSMakeSize(0,0);
		
        for ( JournlerEntry *anEntry in results )
		{
			NSMenuItem *anItem = [anEntry menuItemRepresentation:size];
			if ( anItem != nil )
			{
				[anItem setTarget:[self delegate]];
				[anItem setAction:@selector(selectEntryFromTokenMenu:)];
				
				[theMenu addItem:anItem];
			}
		}
	}
	else
	{
		NSLog(@"%s - filter returned no objects", __PRETTY_FUNCTION__);
	}
	
	return theMenu;
}

- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring 
	indexOfToken:(NSInteger )tokenIndex indexOfSelectedItem:(NSInteger *)selectedIndex
{
	//NSLog(@"%s",__PRETTY_FUNCTION__);
	
	NSArray *tagsArray = [[[self journal] entryTags] allObjects];
	//NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self beginswith[cd] %@", substring];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self beginswith %@", substring];
	NSArray *completions = [tagsArray filteredArrayUsingPredicate:predicate];
	return completions;
}

- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(NSUInteger)index
{
	//NSLog(@"%s - %@",__PRETTY_FUNCTION__,tokens);
	
	NSMutableArray *modifiedArray = [NSMutableArray array];
	
    for ( NSString *aString in tokens )
	{
		if ( ![aString isOnlyWhitespace] )
			//[modifiedArray addObject:[aString lowercaseString]];
			[modifiedArray addObject:aString];
	}
	
	return modifiedArray;
}

- (void)tokenField:(PDTokenField *)tokenField didReadTokens:(NSArray*)theTokens fromPasteboard:(NSPasteboard *)pboard
{
	//NSLog(@"%s - %@",__PRETTY_FUNCTION__,theTokens);
	[[self selectedEntry] setValue:theTokens forKey:@"tags"];
}

#pragma mark -

- (BOOL) hasSelectedText
{
	NSArray *selectedRanges = [textView selectedRanges];
	
	if ( selectedRanges == nil || [selectedRanges count] == 0 
			|| ( [selectedRanges count] == 1 && [[selectedRanges objectAtIndex:0] rangeValue].length == 0 ) )
		return NO;
	else
		return YES;
}

- (NSAttributedString*) selectedText
{
	NSAttributedString *selectedText;
	NSArray *selectedRanges = [textView selectedRanges];
	
	if ( selectedRanges == nil || [selectedRanges count] == 0 || 
			( [selectedRanges count] == 1 && [[selectedRanges objectAtIndex:0] rangeValue].length == 0 ) )
	{
		selectedText = [textView attributedSubstringFromRange:NSMakeRange(0,[[textView string] length])];
	}
	else
	{
		selectedText = [[[NSMutableAttributedString alloc] init] autorelease];
	
        for ( NSValue *aRangeValue in selectedRanges )
		{
			NSRange aRange = [aRangeValue rangeValue];
			NSAttributedString *aSelection = [textView attributedSubstringFromRange:aRange];
			[(NSMutableAttributedString*)selectedText appendAttributedString:aSelection];
			[(NSMutableAttributedString*)selectedText appendAttributedString:
					[[[NSAttributedString alloc] initWithString:@"\n" attributes:nil] autorelease]];
		}
	}
	
	return selectedText;
}

- (void) updateLiveCount
{
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSInteger totalParagraphCount = 0, totalWordCount = 0, totalCharacterCount = 0;
	
	NSString *selectedText = [[textView string] substringWithRange:[textView selectedRange]];
	
	// if there is a single selection without any length (no selection)
	if ( selectedText == nil || [selectedText length] == 0 )
	{
		//NSLog(@"%s - new word counting method",__PRETTY_FUNCTION__);
		
		NSString *selected_text;
		NSMutableString *paragraph_text;
		
		selected_text = [textView string];
		paragraph_text = [selected_text mutableCopyWithZone:[self zone]];
	
		[paragraph_text replaceOccurrencesOfString:@"\r" withString:@"\n" 
		options:NSLiteralSearch range:NSMakeRange(0,[paragraph_text length])];
		[paragraph_text replaceOccurrencesOfString:@"\n\n" withString:@"\n" 
		options:NSLiteralSearch range:NSMakeRange(0,[paragraph_text length])];
		
		totalParagraphCount = [[paragraph_text componentsSeparatedByString:@"\n"] count];
		//totalWordCount = [[NSSpellChecker sharedSpellChecker] countWordsInString:selected_text language:nil];
		totalWordCount = [(KBWordCountingTextStorage*)[[self textView] textStorage] wordCount];
		totalCharacterCount = [selected_text length];
		
		// clean up baby!
		[paragraph_text release];
	}
	
	else 
	{
		NSInteger i;
		NSArray *selections = [textView selectedRanges];
		
		for ( i = 0; i < [selections count]; i++ )
		{
			NSInteger paragraphCount, wordCount, characterCount;
			NSString *selected_text;
			NSMutableString *paragraph_text;
			
			NSRange aSelection = [[selections objectAtIndex:i] rangeValue];
			
			selected_text = [[textView string] substringWithRange:aSelection];
			paragraph_text = [selected_text mutableCopyWithZone:[self zone]];
	
			[paragraph_text replaceOccurrencesOfString:@"\r" withString:@"\n" options:NSLiteralSearch range:NSMakeRange(0,[paragraph_text length])];
			[paragraph_text replaceOccurrencesOfString:@"\n\n" withString:@"\n" options:NSLiteralSearch range:NSMakeRange(0,[paragraph_text length])];
			
			paragraphCount = [[paragraph_text componentsSeparatedByString:@"\n"] count];
			wordCount = [[NSSpellChecker sharedSpellChecker] countWordsInString:selected_text language:nil];
			characterCount = [selected_text length];
			
			totalParagraphCount+=paragraphCount;
			totalWordCount+=wordCount;
			totalCharacterCount+=characterCount;
			
			// clean up baby!
			[paragraph_text release];
		}
	}
		
	NSString *status = [NSString stringWithFormat:NSLocalizedString(@"live count", @""), 
			totalParagraphCount, totalWordCount, totalCharacterCount];
	
	[statusText setStringValue:status];
	
	//[pool release];
}

@end
