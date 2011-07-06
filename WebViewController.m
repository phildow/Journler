#import "WebViewController.h"
#import "Definitions.h"

#import "JournlerMediaViewer.h"
#import "NSAlert+JournlerAdditions.h"

#import <SproutedUtilities/SproutedUtilities.h>

#warning progress indicator: statusIndicator

@implementation WebViewController

- (id) init 
{
	if ( self = [super init] )
	{
		closing = NO;
		blockPopup = YES;
		//[NSBundle loadNibNamed:@"WebArchiveView" owner:self];
		
		static NSString *kNibName = @"WebArchiveView";
		NSString *kNibName105 = [NSString stringWithFormat:@"%@_105",kNibName];
		
		if ( [[NSBundle mainBundle] respondsToSelector:@selector(executableArchitectures)] 
				&& [[NSBundle mainBundle] pathForResource:kNibName105 ofType:@"nib"] != nil )
			[NSBundle loadNibNamed:kNibName105 owner:self];
		else
			[NSBundle loadNibNamed:kNibName owner:self];

	}
	return self;
}

- (void) awakeFromNib 
{
	[super awakeFromNib];
	
	int statusBarBorders[4] = {1,0,0,0};
	[statusBar setBordered:YES];
	[statusBar setBorders:statusBarBorders];
	
	[[back cell] setImageDimsWhenDisabled:[[NSBundle mainBundle] respondsToSelector:@selector(executableArchitectures)]];
	[[forward cell] setImageDimsWhenDisabled:[[NSBundle mainBundle] respondsToSelector:@selector(executableArchitectures)]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
			selector:@selector(progressEstimateChanged:) 
			name:WebViewProgressEstimateChangedNotification 
			object:webView];
			
	[[NSNotificationCenter defaultCenter] addObserver:self 
			selector:@selector(progressFinished:) 
			name:WebViewProgressFinishedNotification 
			object:webView];
	
	// interface stuff that depends on images located in a bundle not our own
	// com.sprouted.interface has what we want
	
	if ( [[NSBundle mainBundle] respondsToSelector:@selector(executableArchitectures)] )
	{
		[backForward setEnabled:[webView canGoBack] forSegment:0];
		[backForward setEnabled:[webView canGoForward] forSegment:1];
	}
	else
	{
		[homeButton setImage:BundledImageWithName(@"Home.tif", @"com.sprouted.interface")];
		[homeButton setAlternateImage:BundledImageWithName(@"HomePressed.tif", @"com.sprouted.interface")];
	
		[back setImage:BundledImageWithName(@"BackDisabled.tif", @"com.sprouted.interface")];
		[back setAlternateImage:BundledImageWithName(@"BackPressed.tif", @"com.sprouted.interface")];
	
		[forward setImage:BundledImageWithName(@"ForwardDisabled.tif", @"com.sprouted.interface")];
		[forward setAlternateImage:BundledImageWithName(@"ForwardPressed.tif", @"com.sprouted.interface")];
		
		[stopRestart setImage:BundledImageWithName(@"Stop.tif", @"com.sprouted.interface")];
		[stopRestart setAlternateImage:BundledImageWithName(@"StopPressed.tif", @"com.sprouted.interface")];
	}

	//[statusIndicator setUsesThreadedAnimation:YES];
}

- (void) dealloc 
{	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_contextual_menu release];
	[webviewFindPanel release];
	
	[super dealloc];
}

#pragma mark -

- (WebView*) webView
{
	return webView;
}

- (NSURL*) webBrowsedURL
{
	if ( [[[webView mainFrame] dataSource] isLoading] )
		[[[[webView mainFrame] dataSource] request] URL];
	return 
		[[[[webView mainFrame] dataSource] response] URL];
}

- (NSString*) browserTitle
{
	NSString *theTitle = [[[webView mainFrame] dataSource] pageTitle];
	if ( theTitle == nil )
		theTitle = [[self webBrowsedURL] absoluteString];
	
	return theTitle;
}

#pragma mark -

- (BOOL) loadURL:(NSURL*)aURL 
{
	// create a url request from the url
	NSURLRequest *request = [NSURLRequest requestWithURL:aURL];
	if ( !request ) {
		NSLog(@"%@ %s - unable to derive url request from url %@", [self className], _cmd, aURL);
		NSBeep();
		[[NSAlert mediaError] runModal];
		return NO;
	}
	
	// actually load the url in the web view
	[[webView mainFrame] loadRequest:request];
	
	[super loadURL:aURL];
	return YES;
}

- (void) stopContent 
{
	[webView stopLoading:self];
	[webviewFindPanel orderOut:self];
}

- (void) ownerWillClose:(NSNotification*)aNotification
{
	closing = YES;
	
	// invalidate the timer and release it
	if ( statusFader != nil )
	{
		[statusFader invalidate];
		[statusFader release];
		statusFader = nil;
	}
	
	// subclasses should override to unhook bindings, etc. aNotification is currently nil
	[webView stopLoading:self];
	[webviewFindPanel orderOut:self];
	
	// nil the delegates
	[webView setFrameLoadDelegate:nil];
	[webView setUIDelegate:nil];
	[webView setDownloadDelegate:nil];
	[webView setPolicyDelegate:nil];
	[webView setResourceLoadDelegate:nil];
}

- (BOOL) handlesFindCommand
{
	// retargets the find panel action because WebKit's WebView doesn't support it
	return YES;
}

#pragma mark -

- (void) performCustomFindPanelAction:(id)sender
{
	[self performWebViewFindPanelAction:sender];
}

- (IBAction)performWebViewFindPanelAction:(id)sender
{	
	if ( [sender tag] == 1 )
		[webviewFindPanel makeKeyAndOrderFront:sender];
	else if ( [sender tag] == 2 || [sender tag] == 3 )
	{
		BOOL next = ( [sender tag] == 2 ? YES : NO );
		NSString *query = [webviewFindQueryField stringValue];
		
		if ( ![webView searchFor:query direction:next 
				caseSensitive:![[NSUserDefaults standardUserDefaults] boolForKey:@"WebViewFindIgnoreCase"] wrap:YES] )
			NSBeep();
	}
	else
		NSBeep();
}

- (BOOL) highlightString:(NSString*)aString
{
	if ( aString == nil || [aString length] == 0 )
		return NO;
	
	// put the string on the find pasteboard
	NSPasteboard *findBoard = [NSPasteboard pasteboardWithName:NSFindPboard];
	[findBoard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
	[findBoard setString:aString forType:NSStringPboardType];
	
	[self setSearchString:aString];
	
	NSString *aComponent;
	NSEnumerator *enumerator = [[aString componentsSeparatedByString:@" "] objectEnumerator];
	
	while ( aComponent = [enumerator nextObject] )
	{
		// find the occurrence of this string and break if it's available - thus iterating through all the strings
		if ( [webView searchFor:aComponent direction:YES caseSensitive:NO wrap:YES] )
		{
			[webviewFindQueryField setStringValue:aString];
			break;
		}
	}
	
	if ( [[webviewFindQueryField stringValue] length] == 0 )
		[webviewFindQueryField setStringValue:aString];
		
	return YES;
}

#pragma mark -

- (BOOL) handlesTextSizeCommand
{
	return YES;
}

- (void) performCustomTextSizeAction:(id)sender
{
	if ( [sender tag] == 3 )
		[webView makeTextLarger:sender];
	else if ( [sender tag] == 4 )
		[webView makeTextSmaller:sender];
	else if ( [sender tag] == 99 )
		[webView setTextSizeMultiplier:1.0];
}


#pragma mark -

- (void) setStatusText:(NSString*)aString
{	
	[statusField setStringValue:aString];
	[statusField setHidden:NO];
	
	if ( statusFader != nil ) 
	{
		[statusFader invalidate];
		[statusFader release];
		statusFader = nil;
	}
	
	if ( closing == NO )
		statusFader = [[NSTimer scheduledTimerWithTimeInterval:5.0 target:self 
				selector:@selector(fadeStatusText:) 
				userInfo:nil 
				repeats:NO] retain];
		
	[statusBar setNeedsDisplay:YES];
}

- (void) fadeStatusText:(NSTimer*)aTimer 
{
	// invalidate the timer and release it
	if ( statusFader != nil )
	{
		[statusFader invalidate];
		[statusFader release];
		statusFader = nil;
	}
	
	// fade out
	NSDictionary *theDict = [[[NSDictionary alloc] initWithObjectsAndKeys:
			statusField, NSViewAnimationTargetKey, 
			NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey, nil] autorelease];
			
	NSViewAnimation *notificationFadeout = [[NSViewAnimation alloc] 
		initWithViewAnimations:[NSArray arrayWithObject:theDict]];

	[notificationFadeout startAnimation];
}

- (void) setStatusProgressHidden:(NSNumber*)aNumber
{
	/*
	BOOL hidden = [aNumber boolValue];
	if ( [statusIndicator isHidden] == hidden )
		return;
	
	if ( hidden )
	{
		[statusIndicator stopAnimation:self];
		[statusIndicator setHidden:YES];
	}
	else
	{
		[statusIndicator setHidden:NO];
		[statusIndicator startAnimation:self];
	}
	
	NSRect statusFieldFrame = [statusField frame];
	int delta = ( hidden ? 24 : -24 );
	
	statusFieldFrame.origin.x-=delta; 
	statusFieldFrame.size.width+=delta;
	
	[statusField setFrame:statusFieldFrame];
	[statusBar setNeedsDisplay:YES];
	*/
}

#pragma mark -

- (IBAction)goBackOrForward:(id)sender
{
	int clickedSegment = [sender selectedSegment];
    int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
	
	if ( clickedSegmentTag == 0 ) [webView goBack:self];
	else if ( clickedSegmentTag == 1 ) [webView goForward:self];
	else NSBeep();
}

- (IBAction)addURLAsArchive:(id)sender
{
}

- (IBAction)goHome:(id)sender
{
	[self loadURL:[self URL]];
}

- (IBAction)search:(id)sender
{
	static NSString *format = @"http://www.google.com/search?rls=en&q=%@&ie=UTF-8&oe=UTF-8";
	
	NSMutableString *theSearchString = [[sender stringValue] mutableCopyWithZone:[self zone]];
	//[theSearchString replaceOccurrencesOfString:@" " withString:@"+" options:NSLiteralSearch range:NSMakeRange(0,[searchString length])];
	[theSearchString replaceOccurrencesOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet] withString:@"+" 
	options:NSLiteralSearch range:NSMakeRange(0,[theSearchString length])];
	
	NSString *urlString = [NSString stringWithFormat:format, theSearchString];
	if ( !urlString ) 
	{
		NSLog(@"WebViewController search: - unable to create url string from search request %@", theSearchString );
		NSBeep(); 
		[[NSAlert googleSearchError] runModal];
		return;
	}
	
	NSURL *url = [NSURL URLWithString:urlString];
	if ( !url ) 
	{
		NSLog(@"WebViewController search: - unable to create url from url string", urlString );
		NSBeep(); 
		[[NSAlert googleSearchError] runModal];
		return;
	}
	
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	if ( !request ) 
	{
		NSLog(@"WebViewController search: - unable to create url request from url %@", [url absoluteString] );
		NSBeep(); 
		[[NSAlert googleSearchError] runModal];
		return;
	}
	
	[[webView mainFrame] loadRequest:request];
	[theSearchString release];
}

#pragma mark -

- (void)splitView:(RBSplitView*)sender wasResizedFrom:(float)oldDimension to:(float)newDimension {
	if ( sender == urlSplit ) 
	{
		[sender adjustSubviewsExcepting:[sender subviewAtPosition:1]];
	}
}

#pragma mark -

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
    // Only report feedback for the main frame.
    if ( frame != [sender mainFrame] || closing == YES )
		return;
	
	NSString *not_string = NSLocalizedStringFromTable(@"web loading", @"JNotifications", @"");
	[self performSelectorOnMainThread:@selector(setStatusText:) withObject:not_string waitUntilDone:NO];
	[self performSelectorOnMainThread:@selector(setStatusProgressHidden:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:NO];
	
	NSString *url = [[[[frame provisionalDataSource] request] URL] absoluteString];
	[urlField setStringValue:url];
	
	[self _updateButtonsReloads:NO];
    
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame 
{
	if ( frame != [sender mainFrame] || closing == YES )
		return;
	
	[self performSelectorOnMainThread:@selector(setStatusText:) withObject:[NSString string] waitUntilDone:NO];
	[self performSelectorOnMainThread:@selector(setStatusProgressHidden:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];
	
	[urlField setEstimatedProgress:2.0];
	[self _updateButtonsReloads:YES];
	
	if ( [self searchString] != nil )
		[self highlightString:[self searchString]];
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame 
{	
	if ( frame != [sender mainFrame] || closing == YES )
		return;
	
	NSString *not_string = [NSString stringWithFormat:NSLocalizedStringFromTable(@"web error", @"JNotifications", @""),
			[error localizedDescription]];
	[self performSelectorOnMainThread:@selector(setStatusText:) withObject:not_string waitUntilDone:NO];
	[self performSelectorOnMainThread:@selector(setStatusProgressHidden:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];
	
	[urlField setEstimatedProgress:2.0];
	[self _updateButtonsReloads:YES];
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame 
{
	if ( frame != [sender mainFrame] || closing == YES )
		return;
	
	NSString *not_string = [NSString stringWithFormat:NSLocalizedStringFromTable(@"web error", @"JNotifications", @""),
			[error localizedDescription]];
	[self performSelectorOnMainThread:@selector(setStatusText:) withObject:not_string waitUntilDone:NO];
	[self performSelectorOnMainThread:@selector(setStatusProgressHidden:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];

	[urlField setEstimatedProgress:2.0];
	[self _updateButtonsReloads:YES];
}

#pragma mark -

- (void)webView:(WebView *)sender unableToImplementPolicyWithError:(NSError *)error frame:(WebFrame *)frame 
{
	if ( frame != [sender mainFrame] || closing == YES )
		return;
	
	NSString *not_string = [NSString stringWithFormat:NSLocalizedStringFromTable(@"web error", @"JNotifications", @""),
			[error localizedDescription]];
	[self performSelectorOnMainThread:@selector(setStatusText:) withObject:not_string waitUntilDone:NO];
	[self performSelectorOnMainThread:@selector(setStatusProgressHidden:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];
}

/*
- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation 
 request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener
{
	if ( [actionInformation objectForKey:WebActionNavigationTypeKey] == nil )
		NSLog(@"%@ %s - no WebActionNavigationTypeKey",[self className],_cmd);
	
	switch ( [[actionInformation objectForKey:WebActionNavigationTypeKey] intValue] )
	{
	case WebNavigationTypeLinkClicked:
		NSLog(@"%@ %s - WebNavigationTypeLinkClicked",[self className],_cmd);
		break;
		
    case WebNavigationTypeFormSubmitted:
		NSLog(@"%@ %s - WebNavigationTypeFormSubmitted",[self className],_cmd);
		break;

    case WebNavigationTypeBackForward:
		NSLog(@"%@ %s - WebNavigationTypeBackForward",[self className],_cmd);
		break;

    case WebNavigationTypeReload:
		NSLog(@"%@ %s - WebNavigationTypeReload",[self className],_cmd);
		break;

    case WebNavigationTypeFormResubmitted:
		NSLog(@"%@ %s - WebNavigationTypeFormResubmitted",[self className],_cmd);
		break;

    case WebNavigationTypeOther:
		NSLog(@"%@ %s - WebNavigationTypeOther",[self className],_cmd);
		break;
	
	default:
		NSLog(@"%@ %s - default",[self className],_cmd);
		break;

	}
	
	if ( [[actionInformation objectForKey:WebActionNavigationTypeKey] intValue] == WebNavigationTypeOther )
		[listener use];
	else
		[listener use];

}
*/

- (void)webView:(WebView *)sender decidePolicyForNewWindowAction:(NSDictionary *)actionInformation 
request:(NSURLRequest *)request newFrameName:(NSString *)frameName decisionListener:(id<WebPolicyDecisionListener>)listener
{	
	#ifdef __DEBUG__
	if ( [actionInformation objectForKey:WebActionNavigationTypeKey] == nil )
		NSLog(@"%@ %s - no WebActionNavigationTypeKey",[self className],_cmd);
	
	switch ( [[actionInformation objectForKey:WebActionNavigationTypeKey] intValue] )
	{
	case WebNavigationTypeLinkClicked:
		NSLog(@"%@ %s - WebNavigationTypeLinkClicked",[self className],_cmd);
		break;
		
    case WebNavigationTypeFormSubmitted:
		NSLog(@"%@ %s - WebNavigationTypeFormSubmitted",[self className],_cmd);
		break;

    case WebNavigationTypeBackForward:
		NSLog(@"%@ %s - WebNavigationTypeBackForward",[self className],_cmd);
		break;

    case WebNavigationTypeReload:
		NSLog(@"%@ %s - WebNavigationTypeReload",[self className],_cmd);
		break;

    case WebNavigationTypeFormResubmitted:
		NSLog(@"%@ %s - WebNavigationTypeFormResubmitted",[self className],_cmd);
		break;

    case WebNavigationTypeOther:
		NSLog(@"%@ %s - WebNavigationTypeOther",[self className],_cmd);
		break;
	
	default:
		NSLog(@"%@ %s - default",[self className],_cmd);
		break;
	}
	#endif
	
	//if ( [[actionInformation objectForKey:WebActionNavigationTypeKey] intValue] == WebNavigationTypeOther )
	//	[listener ignore];
	//else
	blockPopup = NO;
	[listener use];
}

- (WebView *)webView:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request 
{
	WebView *theWebView = nil;
	NSURL *mediaURL = [request URL];
	
	if ( blockPopup == YES )
		goto bail;
		
	JournlerMediaViewer *mediaViewer = [[[JournlerMediaViewer alloc] initWithURL:mediaURL uti:(NSString*)kUTTypeURL] autorelease];
	if ( mediaViewer == nil )
	{
		NSLog(@"%@ %s - problem allocating media viewer for url %@", [self className], _cmd, mediaURL);
		[[NSWorkspace sharedWorkspace] openURL:mediaURL];
	}
	else
	{
		[mediaViewer setRepresentedObject:[self representedObject]];
		[mediaViewer showWindow:self];
		theWebView = [(WebViewController*)[mediaViewer contentController] webView];
	}

bail:
	
	blockPopup = YES;
	return theWebView;
	//return nil;
}

- (NSWindow *)downloadWindowForAuthenticationSheet:(WebDownload *)sender 
{
	return [webView window];
}

#pragma mark -


- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame {
	
	if (frame != [sender mainFrame]) return;
	
	[urlField setURLTitle:title];
	
	if ( delegate && [delegate respondsToSelector:@selector(contentController:changedTitle:)] )
		[delegate contentController:self changedTitle:title];
}

- (void)webView:(WebView *)sender didReceiveIcon:(NSImage *)image forFrame:(WebFrame *)frame {
	
	if (frame != [sender mainFrame]) return;
	
	[urlField setImage:image];
	[urlField setNeedsDisplay:YES];
}

#pragma mark -

- (NSArray *)webView:(WebView *)sender 
		contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems {

	// copy our additional items to the default items
	NSMutableArray *items = [[defaultMenuItems mutableCopyWithZone:[self zone]] autorelease];
	NSArray *contextual_items = [[[NSArray alloc] initWithArray:[_contextual_menu itemArray] copyItems:YES] autorelease];
	[items addObjectsFromArray:contextual_items];
	
	// a few special items
	NSMenuItem *appendImageItem = [[[NSMenuItem alloc] 
			initWithTitle:NSLocalizedString(@"menuitem append image",@"") 
			action:@selector(appendImageToEntry:) 
			keyEquivalent:@""] autorelease];
			
	[appendImageItem setTag:92];
	[appendImageItem setTarget:self];
	
	if ( [[element objectForKey:WebElementIsSelectedKey] boolValue] 
		&& [[[self representedObject] className] isEqualToString:@"JournlerResource"]
		&& [[self delegate] respondsToSelector:@selector(contentController:showLexiconSelection:term:)] )
	{
		// we have a text selection
		NSString *selection = [[sender selectedDOMRange] toString];
		
		if ( [selection rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location == NSNotFound )
		{
			NSMenu *lexiconMenu = [[[NSMenu alloc] initWithTitle:NSLocalizedString(@"menuitem lexicon", @"")] autorelease];
			[lexiconMenu setDelegate:[self valueForKeyPath:@"representedObject.journal.indexServer"]];
			
			NSMenuItem *lexiconMenuItem = [[[NSMenuItem alloc] 
					initWithTitle:NSLocalizedString(@"menuitem lexicon", @"") 
					action:nil 
					keyEquivalent:@""] autorelease];
			
			[lexiconMenuItem setTag:10746];
			[lexiconMenuItem setTarget:self];
			[lexiconMenuItem setAction:@selector(_showObjectFromLexicon:)];
			[lexiconMenuItem setRepresentedObject:selection];
			
			[lexiconMenuItem setSubmenu:lexiconMenu];
			[items addObject:lexiconMenuItem];
		}
	}
	
	//  downloadLinkToDisk: downloadImageToDisk:
	
	// remove a few default items that I don't implement
	int i;
	for ( i = [items count] - 1; i >= 0; i-- ) 
	{
		NSMenuItem *item = [items objectAtIndex:i];
		
		if ( [item action] == @selector(copyImageToClipboard:) ) 
		{
			NSImage *theImage = [element objectForKey:WebElementImageKey];
			NSData *tiffData = [theImage TIFFRepresentation];
			
			if ( theImage != nil && tiffData != nil )
			{
				[appendImageItem setRepresentedObject:tiffData];
				[items insertObject:appendImageItem atIndex:i];
			}
		}
		
		if ( [item action] == @selector(downloadLinkToDisk:) || [item action] == @selector(downloadImageToDisk:) )
			[items removeObjectAtIndex:i];
	}
	
	return items;
}

- (void)webView:(WebView *)sender mouseDidMoveOverElement:(NSDictionary *)elementInformation 
		modifierFlags:(unsigned int)modifierFlags
{
	if ( elementInformation != nil && closing == NO )
	{
		NSURL *linkURL = [elementInformation objectForKey:WebElementLinkURLKey];
		if ( linkURL != nil )
		{
			[self performSelectorOnMainThread:@selector(setStatusText:) withObject:[linkURL absoluteString] waitUntilDone:NO];
			return;
		}
	}
}

/*
- (void)webView:(WebView *)sender setStatusText:(NSString *)text
{
	// The delegate receives this message when a JavaScript function 
	// in the WebView explicitly sets the status text.
	[self performSelectorOnMainThread:@selector(setStatusText:) withObject:text waitUntilDone:NO];
}
*/

#pragma mark -


- (void) _updateButtonsReloads:(BOOL)reloads 
{
	if ( reloads ) 
	{
		[stopRestart setAction:@selector(reload:)];
		
		if ( [[NSBundle mainBundle] respondsToSelector:@selector(executableArchitectures)] )
		{
			[stopRestart setImage:[NSImage imageNamed:NSImageNameRefreshTemplate]];
		}
		else
		{
			[stopRestart setImage:BundledImageWithName(@"Reload.tif",@"com.sprouted.interface")];
			[stopRestart setAlternateImage:BundledImageWithName(@"ReloadPressed.tif",@"com.sprouted.interface")];
		}
	}
	else 
	{
		[stopRestart setAction:@selector(stopLoading:)];
		
		if ( [[NSBundle mainBundle] respondsToSelector:@selector(executableArchitectures)] )
		{
			[stopRestart setImage:[NSImage imageNamed:NSImageNameStopProgressTemplate]];
		}
		else
		{
			[stopRestart setImage:BundledImageWithName(@"Stop.tif",@"com.sprouted.interface")];
			[stopRestart setAlternateImage:BundledImageWithName(@"StopPressed.tif",@"com.sprouted.interface")];
		}
	}
	
	if ( [[NSBundle mainBundle] respondsToSelector:@selector(executableArchitectures)] )
	{
		[back setEnabled:[webView canGoBack]];
		[forward setEnabled:[webView canGoForward]];
		
		[backForward setEnabled:[webView canGoBack] forSegment:0];
		[backForward setEnabled:[webView canGoForward] forSegment:1];
	}
	else
	{
		[back setImage:BundledImageWithName(([webView canGoBack] ? @"Back.tif" : @"BackDisabled.tif" ),@"com.sprouted.interface")];
		[forward setImage:BundledImageWithName(([webView canGoForward] ? @"Forward.tif" : @"ForwardDisabled.tif" ),@"com.sprouted.interface")];
	}
}

- (NSResponder*) preferredResponder
{
	return webView;
}

- (void) appropriateFirstResponder:(NSWindow*)aWindow 
{
	[aWindow makeFirstResponder:webView];
}

- (void) appropriateAlternateResponder:(NSWindow*)aWindow
{
	[aWindow makeFirstResponder:urlField];
}

- (IBAction) printDocument:(id)sender {
	
	NSPrintInfo *modifiedInfo = [[[NSPrintInfo sharedPrintInfo] copyWithZone:[self zone]] autorelease];
	
	[modifiedInfo setHorizontalPagination:NSFitPagination];
    [modifiedInfo setHorizontallyCentered:NO];
    [modifiedInfo setVerticallyCentered:NO];
	[[modifiedInfo dictionary] setValue:[NSNumber numberWithBool:NO] forKey:NSPrintHeaderAndFooter];

    NSRect imageableBounds = [modifiedInfo imageablePageBounds];
    NSSize paperSize = [modifiedInfo paperSize];
    if (NSWidth(imageableBounds) > paperSize.width) {
        imageableBounds.origin.x = 0;
        imageableBounds.size.width = paperSize.width;
    }
    if (NSHeight(imageableBounds) > paperSize.height) {
        imageableBounds.origin.y = 0;
        imageableBounds.size.height = paperSize.height;
    }

	[modifiedInfo setBottomMargin:NSMinY(imageableBounds)];
	[modifiedInfo setTopMargin:paperSize.height - NSMinY(imageableBounds) - NSHeight(imageableBounds)];
	[modifiedInfo setLeftMargin:NSMinX(imageableBounds)];
	[modifiedInfo setRightMargin:paperSize.width - NSMinX(imageableBounds) - NSWidth(imageableBounds)];
	
	[[NSPrintOperation printOperationWithView:[[[webView mainFrame] frameView] documentView] printInfo:modifiedInfo] runOperation];
	
	//[NSPrintInfo setSharedPrintInfo:modifiedInfo];
	//[[[[webView mainFrame] frameView] documentView] print:sender];
	//[NSPrintInfo setSharedPrintInfo:currentInfo];
}

- (IBAction) exportSelection:(id)sender
{
	// convert the current url to a web archive and save it
	NSURL *theURL = [[[[webView mainFrame] dataSource] request] URL];
	WebArchive *theArchive = [[[webView mainFrame] dataSource] webArchive];
	
	if ( theArchive == nil )
	{
		NSBeep();
		NSLog(@"%@ %s - unable to get archive for url", [self className], _cmd, [theURL absoluteString]);
		return;
	}
	
	NSData *archiveData = [theArchive data];
	if ( archiveData == nil )
	{
		NSBeep();
		NSLog(@"%@ %s - unable to get archive data for url", [self className], _cmd, [theURL absoluteString]);
		return;
	}
	
	NSString *pageTitle = [[[webView mainFrame] dataSource] pageTitle];
	
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setRequiredFileType:@"webarchive"];
	[savePanel setCanSelectHiddenExtension:YES];

	if ( [savePanel runModalForDirectory:nil file:( pageTitle ? pageTitle : @"Website" )] == NSOKButton )
	{
		NSError *writeError;
		NSString *filename = [savePanel filename];
		
		if ( ![archiveData writeToFile:filename options:NSAtomicWrite error:&writeError] )
		{
			NSBeep();
			[NSApp presentError:writeError];
			//[[NSAlert alertWithError:writeError] beginSheetModalForWindow:[[self contentView] window] 
			//		modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
		}
		else
		{
			NSDictionary *fileAttributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:[savePanel isExtensionHidden]] forKey:NSFileExtensionHidden];
			[[NSFileManager defaultManager] changeFileAttributes:fileAttributes atPath:[savePanel filename]];
		}
	}

}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[[alert window] orderOut:self];
}

#pragma mark -

- (void) progressEstimateChanged:(NSNotification*)aNotification {
	[urlField setEstimatedProgress:[webView estimatedProgress]];
	[urlField setNeedsDisplay:YES];
}

- (void) progressFinished:(NSNotification*)aNotification {
	[urlField setEstimatedProgress:2.0];
	[urlField setNeedsDisplay:YES];
}

#pragma mark -


- (IBAction) appendLinkToEntry:(id)sender 
{
	if ( !delegate || ![delegate respondsToSelector:@selector(webViewController:appendPasteboardLink:)] ) 
	{
		NSLog(@"WebViewController appendLinkToEntry: invalid delegate");
		NSBeep(); return;
	}
	
	if ( [[[webView mainFrame] dataSource] isLoading] ) 
	{
		NSLog(@"WebViewController appendLinkToEntry: datasource still loading");
		NSBeep(); return;
	}
	
	NSPasteboard *pboard = [NSPasteboard generalPasteboard];
	
	NSString *title = [urlField URLTitle];
	NSString *url = [urlField stringValue];
	if ( !url ) 
	{
		NSLog(@"WebViewController appendLinkToEntry: no url for pasteboard");
		NSBeep(); return;
	}
	
	NSArray *url_array = [NSArray arrayWithObjects:url, nil];
	NSArray *title_array = [NSArray arrayWithObjects:( title ? title : url ), nil];
	NSArray *web_urls_array = [NSArray arrayWithObjects:url_array,title_array, nil];
	
    [pboard declareTypes:[NSArray arrayWithObjects:@"WebURLsWithTitlesPboardType", NSURLPboardType, nil] owner:nil];
	[pboard setPropertyList:web_urls_array forType:@"WebURLsWithTitlesPboardType"];
	[[NSURL URLWithString:url] writeToPasteboard:pboard];
	
	[delegate webViewController:self appendPasteboardLink:pboard];
}

- (IBAction) appendSelectionToEntry:(id)sender 
{
	if ( !delegate || ![delegate respondsToSelector:@selector(webViewController:appendPasteboardContents:)] ) 
	{
		NSLog(@"WebViewController appendSelectionToEntry: invalid delegate");
		NSBeep(); return;
	}
	
	if ( [[[webView mainFrame] dataSource] isLoading] ) 
	{
		NSLog(@"WebViewController appendSelectionToEntry: datasource still loading");
		NSBeep(); return;
	}
	
	[webView copy:self];
	[delegate webViewController:self appendPasteboardContents:[NSPasteboard generalPasteboard]];
}

- (IBAction) appendSiteArchiveToEntry:(id)sender
{
	if ( !delegate || ![delegate respondsToSelector:@selector(webViewController:appendPasetboardWebArchive:)] ) 
	{
		NSLog(@"WebViewController appendLinkToEntry: invalid delegate");
		NSBeep(); return;
	}
	
	if ( [[[webView mainFrame] dataSource] isLoading] ) 
	{
		NSLog(@"WebViewController appendLinkToEntry: datasource still loading");
		NSBeep(); return;
	}
	
	NSPasteboard *pboard = [NSPasteboard generalPasteboard];
	
	NSString *title = [urlField URLTitle];
	NSString *url = [urlField stringValue];
	if ( !url ) 
	{
		NSLog(@"WebViewController appendLinkToEntry: no url for pasteboard");
		NSBeep(); return;
	}
	
	NSArray *url_array = [NSArray arrayWithObjects:url, nil];
	NSArray *title_array = [NSArray arrayWithObjects:( title ? title : url ), nil];
	NSArray *web_urls_array = [NSArray arrayWithObjects:url_array,title_array, nil];
	
    [pboard declareTypes:[NSArray arrayWithObjects:@"WebURLsWithTitlesPboardType", NSURLPboardType, nil] owner:nil];
	[pboard setPropertyList:web_urls_array forType:@"WebURLsWithTitlesPboardType"];
	[[NSURL URLWithString:url] writeToPasteboard:pboard];
	
	[delegate webViewController:self appendPasetboardWebArchive:pboard];
}

- (IBAction) appendImageToEntry:(id)sender 
{
	NSData *tiffData;
	
	if ( !delegate || ![delegate respondsToSelector:@selector(webViewController:appendPasteboardContents:)] ) {
		NSLog(@"WebViewController appendImageToEntry: invalid delegate");
		NSBeep(); return;
	}
	
	if ( [[[webView mainFrame] dataSource] isLoading] ) 
	{
		NSLog(@"WebViewController appendImageToEntry: datasource still loading");
		NSBeep(); return;
	}
	
	tiffData = [sender representedObject];
	if ( tiffData == nil )
	{
		NSLog(@"%@ %s - no tiff data associated with the menu item", [self className], _cmd);
		NSBeep(); return;
	}
	
	NSPasteboard *pboard = [NSPasteboard generalPasteboard];
	
	[pboard declareTypes:[NSArray arrayWithObject:NSTIFFPboardType] owner:nil];
	[pboard setData:tiffData forType:NSTIFFPboardType];
	
	[delegate webViewController:self appendPasteboardContents:[NSPasteboard generalPasteboard]];
}

#pragma mark -

- (IBAction) newEntryWithArchive:(id)sender 
{	
	if ( [[webView mainFrame] dataSource] == nil ) 
	{ 
		NSBeep(); return; 
	}
	
	// write the web archive to a temporary directory
	WebArchive *web_archive = [[[webView mainFrame] dataSource] webArchive];
	if ( web_archive == nil ) 
	{ 
		NSBeep(); return; 
	}
	
	NSString *archive_name = [[urlField URLTitle] pathSafeString];
	NSString *archive_path = [TempDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.webarchive", archive_name]];
	
	if ( ![[web_archive data] writeToFile:archive_path atomically:YES] ) 
	{
		NSBeep();
		NSLog(@"WebViewController newEntryWithArchive: - unable to write webarchive to %@", archive_path);
		return;
	}
	
	// import a new entry with this information
	if ( [[NSApp delegate] respondsToSelector:@selector(importFile:)] )
	{
		[[NSApp delegate] performSelector:@selector(importFile:) withObject:archive_path];
	}
	else
	{
		NSBeep();
		NSLog(@"%@ %s - application does not respond to importFile method, cannot import archive", [self className], _cmd);
	}
}

- (IBAction) _showObjectFromLexicon:(id)sender
{
	id anObject = [sender representedObject];
	
	// modifiers should support opening the item in windows, tabs, etc
	// the item should be opened and the terms highlighted and located
	
	if ( anObject == nil || ![[self delegate] respondsToSelector:@selector(contentController:showLexiconSelection:term:)] )
	{
		NSBeep();
	}
	else
	{
		[[self delegate] contentController:self showLexiconSelection:anObject 
		term:[self valueForKeyPath:@"representedObject.journal.indexServer.lexiconMenuRepresentedTerm"]];
	}
}


#pragma mark -

- (IBAction) openInNewWindow:(id)sender 
{
	NSURL *mediaURL = [self URL];
		
	JournlerMediaViewer *mediaViewer = [[[JournlerMediaViewer alloc] initWithURL:mediaURL uti:(NSString*)kUTTypeURL] autorelease];
	if ( mediaViewer == nil )
	{
		NSLog(@"%@ %s - problem allocating media viewer for url %@", [self className], _cmd, mediaURL);
		[[NSWorkspace sharedWorkspace] openURL:[self URL]];
	}
	else
	{
		[mediaViewer setRepresentedObject:[self representedObject]];
		[mediaViewer showWindow:self];
	}
}

- (IBAction) openInBrowser:(id)sender 
{
	NSString *url_location = [urlField stringValue];
	if ( url_location == nil || [url_location length] == 0 ) 
	{ 
		NSBeep(); return; 
	}
	
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url_location]];
}

- (IBAction) loadWebAddress:(id)sender 
{
	static NSString *delimeter = @".";
	static NSString *http_scheme = @"http";
	static NSString *file_scheme = @"file";
	
	NSString *address = [sender stringValue];
	
	if ( [address rangeOfString:http_scheme options:NSCaseInsensitiveSearch].location != 0 &&
			[address rangeOfString:file_scheme options:NSCaseInsensitiveSearch].location != 0 ) {
		
		if ( [address rangeOfString:delimeter options:NSCaseInsensitiveSearch].location == NSNotFound )
			address = [NSString stringWithFormat:@"http://www.%@.com", address];
		else
			address = [NSString stringWithFormat:@"http://%@", address];
		
	}
	
	NSURL *url = [NSURL URLWithString:address];
	NSURLRequest *url_request = [NSURLRequest requestWithURL:url];
	
	[[webView mainFrame] loadRequest:url_request];
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem 
{	
	BOOL enabled = YES;
	int theTag = [menuItem tag];
	SEL action = [menuItem action];
	
	if ( action == @selector(appendLinkToEntry:) )
		enabled = ( [delegate respondsToSelector:@selector(webViewController:appendPasteboardLink:)] );
		
	else if ( action == @selector(appendSelectionToEntry:) )
		enabled = ( [webView selectedDOMRange] != nil && [delegate respondsToSelector:@selector(webViewController:appendPasteboardContents:)] );
	
	else if ( action == @selector(appendImageToEntry:) )
		enabled = ( [delegate respondsToSelector:@selector(webViewController:appendPasteboardContents:)] );
	
	else if ( action == @selector(appendSiteArchiveToEntry: ) )
		enabled = ![[[webView mainFrame] dataSource] isLoading];
	
	else if ( action == @selector(performCustomFindPanelAction:) )
	{
		switch ( theTag )
		{
		case 1:
			enabled = YES;
			break;
		case 2:
			enabled = ( [[webviewFindQueryField stringValue] length] != 0 );
			break;
		case 3:
			enabled = ( [[webviewFindQueryField stringValue] length] != 0 );
			break;
		default:
			enabled = NO;
			break;
		}
	}
	
	else if ( action == @selector(performCustomTextSizeAction:) )
	{
		if ( theTag == 3 )
			enabled = [webView canMakeTextLarger];
		else if ( theTag == 4 )
			enabled = [webView canMakeTextSmaller];
		else if ( theTag == 99 )
			enabled = YES;
	}
	
	return enabled;
}

@end
