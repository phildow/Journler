
#import "PrefWindowController.h"
#import "JournlerApplicationDelegate.h"

#import "JournlerJournal.h"
#import "JournlerEntry.h"

#import "IndividualLabelView.h"

#import "NSAlert+JournlerAdditions.h"
#import "NSString+JournlerAdditions.h"

#import "AutoCorrectWordPair.h"
#import "Calendar.h"

#import "Definitions.h"
#import "JournlerWeblogInterface.h"
#import "JournlerLicenseManager.h"

#import <SproutedUtilities/SproutedUtilities.h>

// http://journler.com/purchase/calculate.php?src=journler&g_name=Evan%20Agee&g_email=evanagee@gmail.com&g_license=xxxx-xxxx-xxxx-xxxx
// replace spaces in the name with characters

#define PDEncryptionDisabled	0
#define PDEncryptionJournal		1
#define PDEncryptionEntry		2

/*
typedef enum {
	kJournlerLicenseInvalid = -1, 
	kJournlerLicensePersonal = 0,
	kJournlerLicenseNonPersonal = 1,
	kJournlerLicenseBeta = 2,
	kJournlerLicenseSpecial = 3,
	kJournlerLicenseFull = 9
} JournlerLicenseIdentifier;
*/

@implementation PrefWindowController
// #warning removing categories causes hang, index beyond bounds

+ (id)sharedController 
{
    static PrefWindowController *sharedPrefWindowController = nil;

    if (!sharedPrefWindowController) 
	{
        sharedPrefWindowController = [[PrefWindowController allocWithZone:NULL] init];
    }

    return sharedPrefWindowController;
}

- (id)init 
{
    if (self = [self initWithWindowNibName:@"Preferences"] ) 
	{
		licenseType = kJournlerLicenseInvalid;
		[[NSNotificationCenter defaultCenter] addObserver:self 
				selector:@selector(cleanup:) 
				name:NSApplicationWillTerminateNotification 
				object:NSApp];
			
		//panelTemporary = [[JournlerGradientView alloc] initWithFrame:NSMakeRect(0,0,100,100)];
		panelTemporary = [[NSView alloc] initWithFrame:NSMakeRect(0,0,100,100)];
		
		/*
		NSInteger borders[4] = { 1,0,0,0 };
		NSColor *borderColor = [NSColor colorWithCalibratedWhite:0.3 alpha:1.0];
		NSColor *fillColor = [NSColor colorWithCalibratedWhite:230.0/255.0 alpha:1.0];
		
		[(JournlerGradientView*)panelTemporary setBordered:YES];
		[(JournlerGradientView*)panelTemporary setBorders:borders];		
		[(JournlerGradientView*)panelTemporary setBorderColor:borderColor];
		[(JournlerGradientView*)panelTemporary setDrawsGradient:NO];
		[(JournlerGradientView*)panelTemporary setBackgroundColor:fillColor];
		*/
		
		[self retain];
    }
    return self;
}


- (void)dealloc 
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	[journal release];
	[panelTemporary release];
	[shortFormJournalLoc release];
	[autoCorrectWordPairs release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

#pragma mark -

- (void)windowDidLoad 
{
	if ( [[self window] respondsToSelector:@selector(contentBorderThicknessForEdge:)] )
		[[self window] setContentBorderThickness:0.0 forEdge:NSMinYEdge];
	//else
	//	[[self window] setBackgroundColor:[NSColor colorWithCalibratedWhite:0.5 alpha:1.0]];
	
	//[blogTable sizeLastColumnToFit];
	
	// alphabetize categories
	[catListController setSortDescriptors:[NSArray arrayWithObject:
	[[[NSSortDescriptor alloc] initWithKey:@"description" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] autorelease]]];
	
	// alphaetize the wordlist
	[wordListController setSortDescriptors:[NSArray arrayWithObject:
	[[[NSSortDescriptor alloc] initWithKey:@"misspelledWord" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] autorelease]]];
	
	//set the preview fonts
	[foldersFontPreview setDefaultsKey:@"FoldersTableFont"];
	[foldersFontPreview setColorHidden:YES];
	
	[browserFontPreview setDefaultsKey:@"BrowserTableFont"];
	[browserFontPreview  setColorHidden:YES];
	
	[referencesFontPreview setDefaultsKey:@"ReferencesTableFont"];
	[referencesFontPreview  setColorHidden:YES];
	
	[entrytextFontPreview setDefaultsKey:@"DefaultEntryFont"];
	[entrytextFontPreview setColorDefaultsKey:@"Entry Text Color"];
	
	// the worktool sends action on mouse down
	[wordListWoorktool sendActionOn:NSLeftMouseDownMask];
	
	// the license
	[self loadLicenseViewer];
	
	// select the appropriate pane
	NSInteger selectedPane = [[NSUserDefaults standardUserDefaults] integerForKey:@"SelectedPreferencesPane"];
	[self selectPanel:[NSNumber numberWithInteger: ( selectedPane == 0 ? ( licenseType != kJournlerLicenseFull && licenseType != kJournlerLicenseSpecial ? kPrefDonations : kPrefGeneral ) : selectedPane )]];
		
	// center the window
	[[self window] center];
	
	[labelView1 setTag:1];
	[labelView2 setTag:2];
	[labelView3 setTag:3];
	[labelView4 setTag:4];
	[labelView5 setTag:5];
	[labelView6 setTag:6];
	[labelView7 setTag:7];
	
	NSString *customTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"LabelName1"];
	if ( customTitle == nil ) [[NSUserDefaults standardUserDefaults] setObject:NSLocalizedString(@"LabelName1",@"") forKey:@"LabelName1"];
	customTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"LabelName2"];
	if ( customTitle == nil ) [[NSUserDefaults standardUserDefaults] setObject:NSLocalizedString(@"LabelName2",@"") forKey:@"LabelName2"];
	customTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"LabelName3"];
	if ( customTitle == nil ) [[NSUserDefaults standardUserDefaults] setObject:NSLocalizedString(@"LabelName3",@"") forKey:@"LabelName3"];
	customTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"LabelName4"];
	if ( customTitle == nil ) [[NSUserDefaults standardUserDefaults] setObject:NSLocalizedString(@"LabelName4",@"") forKey:@"LabelName4"];
	customTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"LabelName5"];
	if ( customTitle == nil ) [[NSUserDefaults standardUserDefaults] setObject:NSLocalizedString(@"LabelName5",@"") forKey:@"LabelName5"];
	customTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"LabelName6"];
	if ( customTitle == nil ) [[NSUserDefaults standardUserDefaults] setObject:NSLocalizedString(@"LabelName6",@"") forKey:@"LabelName6"];
	customTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"LabelName7"];
	if ( customTitle == nil )[[NSUserDefaults standardUserDefaults] setObject:NSLocalizedString(@"LabelName7",@"") forKey:@"LabelName7"];

	[highlightYellow setDefaultsKey:@"highlightYellow"];
	[highlightOrange setDefaultsKey:@"highlightOrange"];
	[highlightRed setDefaultsKey:@"highlightRed"];
	[highlightBlue setDefaultsKey:@"highlightBlue"];
	[highlightGreen setDefaultsKey:@"highlightGreen"];
	
	[colorLink setDefaultsKey:@"EntryTextLinkColor"];
	
	[backgroundColorText setDefaultsKey:@"EntryBackgroundColor"];
	[backgroundColorHeader setDefaultsKey:@"HeaderBackgroundColor"];
	[headerColorLabel setDefaultsKey:@"HeaderLabelColor"];
	[headerColorValue setDefaultsKey:@"HeaderTextColor"];
	
	// 1.1.5 - disable the xml-rpc header
	//[blogTypes setAutoenablesItems:NO];
	//[[blogTypes itemAtIndex:3] setEnabled:NO];
	
	//toolbar
	[self setupToolbar];
	
	// the selected item
	[[[self window] toolbar] setSelectedItemIdentifier:
		[[(PDToolbar*)[[self window] toolbar] itemWithTag:
		( selectedPane == 0 ? ( licenseType != kJournlerLicenseFull && licenseType != kJournlerLicenseSpecial ? kPrefDonations : kPrefGeneral ) : selectedPane )] itemIdentifier]];

	// defaults
	[self loadHandledDefaults];
	
	// preferred blog editor
	NSString *weblogEditor = [[NSUserDefaults standardUserDefaults] stringForKey:@"PreferredWeblogEditor"];
	if ( weblogEditor != nil ) [self setPreferredWeblogEditor:weblogEditor];
}

#pragma mark -

// ============================================================
// NSWindow Delegation
// ============================================================

- (void)windowWillClose:(NSNotification *)aNotification 
{		
	if ( [aNotification object] == [self window] )
	{
		[self cleanup:nil];
		
		[defaultsController commitEditing];
		[prefController commitEditing];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:PDPreferencesDidEndEditingNotification object:self userInfo:nil];
		
		[prefController unbind:@"contentObject"];
		[prefController setContent:nil];
		
		[self autorelease];
	}
}

#pragma mark -

- (JournlerJournal*) journal
{
	return journal;
}

- (void) setJournal:(JournlerJournal*)aJournal
{
	journal = [aJournal retain];
}


- (NSArray*) autoCorrectWordPairs
{
	return autoCorrectWordPairs;
}

- (void) setAutoCorrectWordPairs:(NSArray*)anArray
{
	if ( autoCorrectWordPairs != anArray ) 
	{
		[autoCorrectWordPairs release];
		autoCorrectWordPairs = [anArray retain];
	}
}

- (NSString*) shortFormJournalLoc {
	return shortFormJournalLoc;
}

- (void) setShortFormJournalLoc: (NSString*)jloc {
	if ( shortFormJournalLoc != jloc ) {
		[shortFormJournalLoc release];
		shortFormJournalLoc = [jloc copyWithZone:[self zone]];
	}
}

- (void) setPassed:(NSInteger)newVal {
	passed = newVal;
}

- (NSInteger) passed {
	return passed;
}

#pragma mark -

// ============================================================
// NSToolbar Related Methods
// ============================================================


- (IBAction) tabPanel:(id)sender 
{
	[self selectPanel:[NSNumber numberWithInteger:[sender tag]]];
}


- (void) selectPanel:(NSNumber*)tagNum 
{
	
	NSInteger tag = [tagNum integerValue];
	NSView *newView = nil;
	
	switch (tag) {
		case kPrefDonations:
			newView = panelDonations;
			break;
		//case kPrefBlogging:
		//	newView = panelBlogs;
		//	break;
		case kPrefGeneral:
			newView = panelGeneral;
			break;
		case kPrefMedia:
			newView = panelMedia;
			break;
		case kPrefWindow:
			newView = panelWindow;
			break;
		case kPrefEditing:
			newView = panelEditing;
			break;
		case kPrefAdvanced:
			newView = panelAdvanced;
			break;
		case kPrefLabels:
			newView = panelLabels;
			break;
	}
	
	if ( newView && newView != [[self window] contentView] ) 
	{
		/*
		NSInteger borders[4] = { 1,0,0,0 };
		NSColor *borderColor = [NSColor colorWithCalibratedWhite:0.3 alpha:1.0];
		[(PDGradientView*)newView setBordered:YES];
		[(PDGradientView*)newView setBorders:borders];		
		[(PDGradientView*)newView setBorderColor:borderColor];
		*/
		
		NSRect contentRect, newFrame;
		NSInteger newViewFrameHeight = [newView frame].size.height;
		
		// if the license view is shown, change the target height
		if ( newView == panelDonations )
		{
			if ( licenseType == kJournlerLicenseFull )
				newViewFrameHeight = 200;
			else if ( licenseType == kJournlerLicenseSpecial )
				newViewFrameHeight = 250;
		}
				
		contentRect = [[self window] contentRectForFrameRect:[[self window] frame]];
		contentRect.origin.y = contentRect.origin.y + contentRect.size.height - newViewFrameHeight;
		contentRect.size.height = newViewFrameHeight;
		
		newFrame = [[self window] frameRectForContentRect:contentRect];
		
		//[[self window] setContentView:newView];
		//[[[self window] contentView] setHidden:YES];
		
		[[self window] setContentView:panelTemporary];
		[[self window] setFrame:newFrame display:YES animate:YES];
		[[self window] setContentView:newView];
						
		//[[[self window] contentView] setHidden:NO];
		
		[[NSUserDefaults standardUserDefaults] setInteger:tag forKey:@"SelectedPreferencesPane"];
		
	}
	
	NSString *loc_key = [NSString stringWithFormat:@"preferences panel %i",tag];
	NSString *window_name = NSLocalizedString(loc_key, @"");
	[[self window] setTitle:window_name];
}

#pragma mark -

- (void) loadHandledDefaults {
	//called to handle local defaults
	NSUserDefaults *myDefaults = [[NSUserDefaults standardUserDefaults] retain];
	
	//3. Load Journal Location
	NSString *journalLoc = [myDefaults objectForKey:@"Default Journal Location"];
	NSArray *locComponents = [journalLoc pathComponents];
	[self setShortFormJournalLoc:[locComponents objectAtIndex:[locComponents count] - 3 ]];
	
	//4. Set the state of the password button
	NSString *encryptedFilename = [[[self journal] journalPath] stringByAppendingPathComponent:PDJournalPasswordProtectedLoc];
	[self setPassed:[[NSFileManager defaultManager] fileExistsAtPath:encryptedFilename]];
	
	// email setting
	NSInteger mailPreference = [[NSUserDefaults standardUserDefaults] integerForKey:@"UseMailForEmailing"];
	[useAppleMailCheck setState:( mailPreference == 1 ? NSOnState : NSOffState )];
	
	//clean up
	[myDefaults release];
}

- (void) loadLicenseViewer
{
	NSError *error = nil;
	NSString *dLicensePath;
	NSString *dLicenseName = [[NSUserDefaults standardUserDefaults] stringForKey:@"LicenseName"];
	NSMutableString *dLicenseCode = [[[[NSUserDefaults standardUserDefaults] stringForKey:@"LicenseCode"] 
			mutableCopyWithZone:[self zone]] autorelease];
	
	static NSString *kCalculateUpgradePath = @"http://journler.com/purchase/calculate.php";
	
	if ( dLicenseName == nil || dLicenseCode == nil )
	{
		dLicensePath = [[NSBundle mainBundle] pathForResource:@"LicenseInformation" ofType:@"html"];
		[[licenseWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:dLicensePath]]];
	}
	else
	{
		// what kind of license is this?
		licenseType = [[JournlerLicenseManager sharedManager] licenseTypeForName:dLicenseName digest:dLicenseCode];
		
		// make the license code a little friendlier to the eye
		[dLicenseCode insertString:@"-" atIndex:12];
		[dLicenseCode insertString:@"-" atIndex:8];
		[dLicenseCode insertString:@"-" atIndex:4];
		
		// enable/disable certain buttons
		[purchaseJournlerButton setHidden:( licenseType != kJournlerLicenseInvalid )];
		
		if ( licenseType == kJournlerLicenseInvalid )
		{
			[enterLicenseButton setHidden:NO];
			[thanksField setHidden:YES];
		}
		else
		{
			[enterLicenseButton setHidden:YES];
			[thanksField setHidden:NO];
		}
		
		if ( licenseType == kJournlerLicensePersonal )
		{
			dLicensePath = [[NSBundle mainBundle] pathForResource:@"LicensePersonalUse" ofType:@"html"];
			//NSString *licenseHTML = [NSString stringWithContentsOfFile:dLicensePath usedEncoding:NULL error:&error];
			NSString *licenseHTML = [NSString stringWithContentsOfFile:dLicensePath encoding:NSUTF8StringEncoding error:&error];
			if ( licenseHTML == nil )
				NSLog(@"%s - there was a problem reading the LicensePersonalUse.html file, error %@", __PRETTY_FUNCTION__, error);
			else
			{
				// make sure name does not have ampersand in it nor any characters beyond the standard english that fit in a url
				
				NSString *upgradeLink = nil;
				NSString *escapedName = [dLicenseName stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
				if ( escapedName == nil )
					upgradeLink = kCalculateUpgradePath;
				else
					upgradeLink = [NSString stringWithFormat:@"%@?src=journler&g_name=%@&g_license=%@",kCalculateUpgradePath,escapedName,dLicenseCode];
					
				NSString *completedLicenseHTML = [NSString stringWithFormat:licenseHTML, dLicenseName, dLicenseCode,upgradeLink,upgradeLink];
				[[licenseWebView mainFrame] loadHTMLString:completedLicenseHTML baseURL:nil];
			}
		}
		else if ( licenseType == kJournlerLicenseNonPersonal )
		{
			dLicensePath = [[NSBundle mainBundle] pathForResource:@"LicenseNonPersonalUse" ofType:@"html"];
			//NSString *licenseHTML = [NSString stringWithContentsOfFile:dLicensePath usedEncoding:NULL error:&error];
			NSString *licenseHTML = [NSString stringWithContentsOfFile:dLicensePath encoding:NSUTF8StringEncoding error:&error];
			if ( licenseHTML == nil )
				NSLog(@"%s - there was a problem reading the LicenseNonPersonalUse.html file, error %@", __PRETTY_FUNCTION__, error);
			else
			{
				NSString *completedLicenseHTML = [NSString stringWithFormat:licenseHTML, dLicenseName, dLicenseCode];
				[[licenseWebView mainFrame] loadHTMLString:completedLicenseHTML baseURL:nil];
			}
		}
		else if ( licenseType == kJournlerLicenseBeta ) 
		{
			dLicensePath = [[NSBundle mainBundle] pathForResource:@"LicenseBetaTesting" ofType:@"html"];
			//NSString *licenseHTML = [NSString stringWithContentsOfFile:dLicensePath usedEncoding:NULL error:&error];
			NSString *licenseHTML = [NSString stringWithContentsOfFile:dLicensePath encoding:NSUTF8StringEncoding error:&error];
			if ( licenseHTML == nil )
				NSLog(@"%s - there was a problem reading the LicenseBetaTesting.html file, error %@", __PRETTY_FUNCTION__, error);
			else
			{
				NSString *completedLicenseHTML = [NSString stringWithFormat:licenseHTML, dLicenseName, dLicenseCode];
				[[licenseWebView mainFrame] loadHTMLString:completedLicenseHTML baseURL:nil];
			}
		}
		else if ( licenseType == kJournlerLicenseSpecial )
		{
			dLicensePath = [[NSBundle mainBundle] pathForResource:@"LicenseJournlerSpecial" ofType:@"html"];
			//NSString *licenseHTML = [NSString stringWithContentsOfFile:dLicensePath usedEncoding:NULL error:&error];
			NSString *licenseHTML = [NSString stringWithContentsOfFile:dLicensePath encoding:NSUTF8StringEncoding error:&error];
			if ( licenseHTML == nil )
				NSLog(@"%s - there was a problem reading the LicenseJournlerSpecial.html file, error %@", __PRETTY_FUNCTION__, error);
			else
			{
				NSString *completedLicenseHTML = [NSString stringWithFormat:licenseHTML, dLicenseName, dLicenseCode];
				[[licenseWebView mainFrame] loadHTMLString:completedLicenseHTML baseURL:nil];
			}
		}
		else if ( licenseType == kJournlerLicenseFull )
		{
			dLicensePath = [[NSBundle mainBundle] pathForResource:@"LicenseFull" ofType:@"html"];
			//NSString *licenseHTML = [NSString stringWithContentsOfFile:dLicensePath usedEncoding:NULL error:&error];
			NSString *licenseHTML = [NSString stringWithContentsOfFile:dLicensePath encoding:NSUTF8StringEncoding error:&error];
			if ( licenseHTML == nil )
				NSLog(@"%s - there was a problem reading the LicenseFull.html file, error %@", __PRETTY_FUNCTION__, error);
			else
			{
				NSString *completedLicenseHTML = [NSString stringWithFormat:licenseHTML, dLicenseName, dLicenseCode];
				[[licenseWebView mainFrame] loadHTMLString:completedLicenseHTML baseURL:nil];
			}
		}
		else
		{
			dLicensePath = [[NSBundle mainBundle] pathForResource:@"LicenseInformation" ofType:@"html"];
			[[licenseWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:dLicensePath]]];
		}
	}
}

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation 
		request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener
{
	if ( [[[request URL] scheme] isEqualToString:@"http"] )
	{
		[listener ignore];
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
	}
	else
	{
		[listener use];
	}
}

#pragma mark -
#pragma mark Auto-Correct Word List

- (IBAction) toggleUseWordList:(id)sender
{
	// if the wordlist hasn't been loaded, try to load it
	if ( [sender state] != NSOnState )
		return;
	
	NSString *wordlistPath = [[[self journal] journalPath] stringByAppendingPathComponent:PDJournalWordListLoc];
	if ( [[NSFileManager defaultManager] fileExistsAtPath:wordlistPath] )
	{
		NSDictionary *wordlist = [[NSApp delegate] autoCorrectDictionaryForFileAtPath:wordlistPath];
		if ( wordlist == nil )
		{
			NSBeep();
			[[NSAlert wordlistCreationError] runModal];
			NSLog(@"%s - unable to load wordlist from path %@", __PRETTY_FUNCTION__, wordlistPath);
		}
		else
		{
			[[NSApp delegate] setAutoCorrectWordList:wordlist];
		}
	}
	else
	{
		NSLog(@"%s - no wordlist for auto-correct spelling", __PRETTY_FUNCTION__);
	}

}

- (IBAction) editWordList:(id)sender
{
	// prepare the word list if necessary
	if ( autoCorrectWordPairs == nil || [autoCorrectWordPairs count] == 0 )
	{
		NSDictionary *wordlist = [[NSApp delegate] autoCorrectWordList];
		if ( wordlist == nil )
		{
			NSLog(@"%s - nil word list, building from scratch", __PRETTY_FUNCTION__);
			[self setAutoCorrectWordPairs:[NSArray array]];
		}
		else
		{
			NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:[wordlist count]];
			
            for ( NSString *aKey in [wordlist keyEnumerator] )
			{
				AutoCorrectWordPair *aPair = [[[AutoCorrectWordPair alloc] 
						initWithMisspelledWord:aKey correctWord:[wordlist objectForKey:aKey]] autorelease];
				[tempArray addObject:aPair];
			}
			
			[self setAutoCorrectWordPairs:tempArray];
		}
	}
	
	// put the sheet on the screen
	[NSApp beginSheet: wordListSheet
			modalForWindow: [self window]
			modalDelegate: self
			didEndSelector: @selector(wordListSheet:returnCode:contextInfo:)
			contextInfo: nil];

}

- (void) wordListSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void  *)contextInfo
{
	if ( returnCode == NSRunStoppedResponse )
	{
		// save the changes to the word list
		NSArray *misspellings = [autoCorrectWordPairs valueForKey:@"misspelledWord"];
		NSArray *properspellings = [autoCorrectWordPairs valueForKey:@"correctWord"];
		
		NSDictionary *newAutoCorrectDictionary = [NSDictionary dictionaryWithObjects:properspellings forKeys:misspellings];
		[[NSApp delegate] setAutoCorrectWordList:newAutoCorrectDictionary];
		
		NSArray *sortedMisspellings = [misspellings sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
				
		NSInteger i;
		NSMutableString *csvRep = [NSMutableString string];
		for ( i = 0; i < CFArrayGetCount((CFArrayRef)sortedMisspellings); i++ )
		{
			NSString *aMisspelling = (NSString*)CFArrayGetValueAtIndex((CFArrayRef)sortedMisspellings,i);
			[csvRep appendString:aMisspelling];
			[csvRep appendString:@","];
			[csvRep appendString:[newAutoCorrectDictionary objectForKey:aMisspelling]];
			[csvRep appendString:@"\r"];
		}
		
		// remove the last carriage return if it exists
		if ( [csvRep length] != 0 && ( [csvRep characterAtIndex:[csvRep length]-1] == NSEnterCharacter || 
				[csvRep characterAtIndex:[csvRep length]-1] == NSCarriageReturnCharacter ) )
			[csvRep deleteCharactersInRange:NSMakeRange([csvRep length]-1,1)];
		
		NSString *autocorrectPath = [[[self journal] journalPath] stringByAppendingPathComponent:PDJournalWordListLoc];
		if ( ![csvRep writeToFile:autocorrectPath atomically:YES encoding:NSUnicodeStringEncoding error:nil] )
		{
			NSBeep();
			[[NSAlert wordlistSaveError] runModal];
			NSLog(@"%s - unable to write new autocorrect dictionary to path %@", __PRETTY_FUNCTION__, autocorrectPath);
		}
	}
	
	[wordListSheet orderOut:self];
}

- (IBAction) cancelWordListChanges:(id)sender
{
	[NSApp endSheet:wordListSheet returnCode:NSRunAbortedResponse];
}

- (IBAction) okayWordListChanges:(id)sender
{
	[NSApp endSheet:wordListSheet returnCode:NSRunStoppedResponse];
}

- (IBAction) showWordListWorktool:(id)sender
{
	[NSMenu popUpContextMenu:wordListMenu withEvent:[NSApp currentEvent] forView:wordListWoorktool];
}

#pragma mark -

- (IBAction) clearWordList:(id)sender
{
	[self setAutoCorrectWordPairs:[NSArray array]];
}

- (IBAction) restoreDefaultWordList:(id)sender
{
	NSString *wordlistSource = [[NSBundle mainBundle] pathForResource:@"AutoCorrectWordPairs" ofType:@"csv"];
	if ( wordlistSource == nil )
	{
		NSBeep();
		[[NSAlert wordlistCreationError] runModal];
		NSLog(@"%s - unable to load wordlist from path %@", __PRETTY_FUNCTION__, wordlistSource);
		return;
	}
	
	NSDictionary *wordlist = [[NSApp delegate] autoCorrectDictionaryForFileAtPath:wordlistSource];
	if ( wordlist == nil )
	{
		NSBeep();
		[[NSAlert wordlistCreationError] runModal];
		NSLog(@"%s - unable to derive dictionary from wordlist at path %@", __PRETTY_FUNCTION__, wordlistSource);
		return;
	}
	
	NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:[wordlist count]];
	
    for ( NSString *aKey in [wordlist keyEnumerator] )
	{
		AutoCorrectWordPair *aPair = [[[AutoCorrectWordPair alloc] 
				initWithMisspelledWord:aKey correctWord:[wordlist objectForKey:aKey]] autorelease];
		[tempArray addObject:aPair];
	}
	
	[self setAutoCorrectWordPairs:tempArray];
}

- (IBAction) loadWordListFromFile:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	NSArray *types = [NSArray arrayWithObjects:@"txt", @"text", @"csv", 
			NSFileTypeForHFSTypeCode( 'TEXT' ), NSFileTypeForHFSTypeCode( 'CSV ' ), (NSString*)kUTTypeText, nil];
	
	[openPanel setTitle:NSLocalizedString(@"csv select title", @"")];
	[openPanel setPrompt:NSLocalizedString(@"csv select prompt", @"")];
    [openPanel setMessage:NSLocalizedString(@"csv select message", @"")];
	
	if ( [openPanel runModalForDirectory:nil file:nil types:types] == NSOKButton )
	{
		NSString *wordlistSource = [openPanel filename];
		NSDictionary *wordlist = [[NSApp delegate] autoCorrectDictionaryForFileAtPath:wordlistSource];
		if ( wordlist == nil )
		{
			NSBeep();
			[[NSAlert wordlistCreationError] runModal];
			NSLog(@"%s - unable to derive dictionary from wordlist at path %@", __PRETTY_FUNCTION__, wordlistSource);
			return;
		}
		
		NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:[wordlist count]];
        for ( NSString *aKey in [wordlist keyEnumerator] )
		{
			AutoCorrectWordPair *aPair = [[[AutoCorrectWordPair alloc] 
					initWithMisspelledWord:aKey correctWord:[wordlist objectForKey:aKey]] autorelease];
			[tempArray addObject:aPair];
		}
		
		[self setAutoCorrectWordPairs:tempArray];
	}
}

#pragma mark -
#pragma mark Categories

- (IBAction)removeCategory:(id)sender {
	
	//set up some of the sheets properties
	//NSMenu *catMenu = [[defaultCatPop menu] copyWithZone:[self zone]];
	//[deleteCatPop setMenu:catMenu];
	[deleteCatPop selectItemAtIndex:0];
	
	[NSApp beginSheet: deleteCatSheet
            modalForWindow: [self window]
            modalDelegate: nil
            didEndSelector: nil
            contextInfo: nil];
    [NSApp runModalForWindow: deleteCatSheet];
    // Sheet is up here.
    [NSApp endSheet: deleteCatSheet];
    [deleteCatSheet orderOut: self];
	
	// clean up 
	//[catMenu release];

}

- (IBAction) proceedRemoveCategory:(id)sender {
	
	// must have at least one item in the list
	if ( [deleteCatPop numberOfItems] == 1 ) {
		NSBeep();
		return;
	}
	
	[NSApp stopModal];
	
	//grab the item and remove it from the user defaults array
	NSString *toRemove = [deleteCatPop titleOfSelectedItem];
	//NSInteger iR= [deleteCatPop indexOfSelectedItem];
	
	//if ( [toRemove isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:@"Journler Default Category"]] )
		//[[NSUserDefaults standardUserDefaults] setObject:[[deleteCatPop itemAtIndex:( iR > 0 ? 0 : 1 )] title]
		//		forKey:@"Journler Default Category"];
	
	//[catListController removeObjectAtArrangedObjectIndex:iR];
	[catListController removeObject:toRemove];
	[catListController rearrangeObjects];
	
	if ( [toRemove isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:@"Journler Default Category"]] )
	{
		NSString *newDefaultCategory = [[catListController arrangedObjects] objectAtIndex:0];
		[[NSUserDefaults standardUserDefaults] setObject:newDefaultCategory forKey:@"Journler Default Category"];
	}
}

- (IBAction) closeRemoveCategory:(id)sender {
	[NSApp abortModal];
}

- (IBAction)addCategory:(id)sender {
	
	// clear ou the category field
	[newCatName setStringValue:[NSString string]];
	
	//set up some of the sheets properties
	[NSApp beginSheet: newCatSheet
            modalForWindow: [self window]
            modalDelegate: nil
            didEndSelector: nil
            contextInfo: nil];
    [NSApp runModalForWindow: newCatSheet];
    // Sheet is up here.
    [NSApp endSheet: newCatSheet];
    [newCatSheet orderOut: self];
}

- (IBAction)createCategory:(id)sender {
	//add this guy to the category list
	NSString *catString = [newCatName stringValue];
	[catListController addObject:catString];
	[catListController rearrangeObjects];
	//check for category default
	if ( [makeDefaultCategory state] == NSOnState ) {
		[defaultCatPop selectItemWithTitle:catString];
		[[NSUserDefaults standardUserDefaults] setObject:catString forKey:@"Journler Default Category"];
	}
		
	[NSApp stopModal];
}


- (IBAction)closeCreateCategory:(id)sender {
	[NSApp abortModal];
}

#pragma mark -

- (IBAction) makeDonation:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://journler.com/purchase/"]];
}

- (IBAction) showSecurityHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"JournlerSecurity" inBook:@"JournlerHelp"];
}

- (IBAction) showTunesHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"JournlerTunesPreferences" inBook:@"JournlerHelp"];
}

- (IBAction) showMediaHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"MediaPreferences" inBook:@"JournlerHelp"];
}

#pragma mark -

- (IBAction) changeCalendarStartDay:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:CalendarStartDayChangedNotification object:self userInfo:nil];
}


#pragma mark -
#pragma mark Password Protection

- (IBAction) changePassword:(id)sender 
{
	[passwordWindow makeFirstResponder:passA];
	[passA setStringValue:@""];
	[passB setStringValue:@""];
	[NSApp beginSheet: passwordWindow
			modalForWindow: [self window]
			modalDelegate: nil
			didEndSelector: nil
			contextInfo: nil];
	[NSApp runModalForWindow: passwordWindow];
	// Sheet is up here.
	[NSApp endSheet: passwordWindow];
	[passwordWindow orderOut: self];
}

- (IBAction) okayPassword:(id)sender 
{
	if ( [[passA stringValue] isEqualToString:[passB stringValue]] ) 
	{
		// derive an md5 digest for the given password
		NSString *md5Digest = [[passA stringValue] journlerMD5Digest];
		
		NSLog([md5Digest className]);
		
		//check the state of the enable button
		if ( [enablePassword state] == NSOnState ) 
		{
			if ( md5Digest == nil )
			{
				NSBeep();
				[[NSAlert digestCreationError] runModal];
				
				NSLog(@"%s - unable to create digest for password", __PRETTY_FUNCTION__);
				[self setPassed:NO];
			}
			else
			{
				NSError *error = nil;
				NSString *encryptedFilename = [[[self journal] journalPath] stringByAppendingPathComponent:PDJournalPasswordProtectedLoc];
				if ( ![md5Digest writeToFile:encryptedFilename atomically:YES encoding:NSUnicodeStringEncoding error:&error] )
				{
					NSBeep();
					[[NSAlert passfileCreationError] runModal];
					
					[self setPassed:NO];
					NSLog(@"%s - unable to write encrypted password to file %@, error %@", __PRETTY_FUNCTION__, encryptedFilename, error);
				}
				else
				{
					// everything is set up properly
					[self setPassed:YES];
				}
			}
		}
		else 
		{
			// remove the password protected marker from the journal's directory
			NSError *error = nil;
			NSString *encryptedFilename = [[[self journal] journalPath] stringByAppendingPathComponent:PDJournalPasswordProtectedLoc];
			NSString *availableDigest = [NSString stringWithContentsOfFile:encryptedFilename encoding:NSUnicodeStringEncoding error:&error];
			
			if ( availableDigest == nil )
			{
				// problem reading the file
				NSLog(@"%s - there was a problem reading the digest file at path %@, error %@", __PRETTY_FUNCTION__, encryptedFilename, error);
				NSBeep();
				return;
			}
			
			if ( ![md5Digest isEqualToString:availableDigest] )
			{
				// password doesn't match password on file
				NSBeep();
				return;
			}
			
			if ( ![[NSFileManager defaultManager] removeFileAtPath:encryptedFilename handler:self] )
			{
				NSBeep();
				[[NSAlert passfileDeletionError] runModal];
				
				NSBeep();
				[self setPassed:YES];
			}
			else
			{
				[self setPassed:NO];
			}
		}
		
		[NSApp stopModal];
	}
	else
	{
		NSBeep();
	}
}

- (IBAction) cancelPassword:(id)sender {
	
	// and make sure the pass enable button is in its old state
	[self setPassed:( [self passed] == NSOnState ? NSOffState : NSOnState )];
	[NSApp abortModal];
}

#pragma mark -

- (void) cleanup:(NSNotification*)aNotification {
	
	//
	// rewrites our handled preferences to user defaults
	//
	
	//commit all of my bound changes - just to be safe
	[catListController commitEditing];
	[defaultsController commitEditing];
	[prefController commitEditing];
	
}

/*

#pragma mark -
#pragma mark Blogging


- (IBAction) blogTypeChange:(id)sender {
	//changes certain text fields depending on the type
	
	BOOL enable = NO;
	NSInteger tag = [[sender selectedItem] tag];
	
	if ( tag >= 10 && tag < 20 )
		enable = NO;
	else if ( tag >= 20 && tag <= 30 )
		enable = YES;
	
	[xmlrpcLoc setEnabled:enable];
	[blogID setEnabled:enable];
	
	[blogTable setNeedsDisplay:YES];
	
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	[self blogTypeChange:blogTypes];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	[(BlogAccountCell*)aCell setImageSize:NSMakeSize(28,28)];
	[(BlogAccountCell*)aCell setImage:[NSImage imageNamed:@"ToolbarItemLink.tif"]];
	[(BlogAccountCell*)aCell setBlogType:[[[blogPrefsController arrangedObjects] objectAtIndex:rowIndex] valueForKey:@"blogType"]];
	[(BlogAccountCell*)aCell setSelected:( [[aTableView selectedRowIndexes] containsIndex:rowIndex] )];
}


- (IBAction) showBlogHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"BlogPreferences" inBook:@"JournlerHelp"];
}

- (IBAction) addBlog:(id)sender 
{			
	//[self blogAccountWizard:sender];
	
	BlogPref *newAccount = [[[BlogPref alloc] init] autorelease];
	[newAccount setValue:NSLocalizedString(@"untitled title",@"") forKey:@"name"];
	[[self journal] addBlog:newAccount];
	[blogPrefsController setSelectedObjects:[NSArray arrayWithObject:newAccount]];
}

- (IBAction) removeBlog:(id)sender 
{
	if ( [[blogPrefsController selectedObjects] count] == 0 )
	{
		NSBeep(); return;
	}
	
	BlogPref *selected_blog = [[blogPrefsController selectedObjects] objectAtIndex:0];
	[[self journal] deleteBlog:selected_blog];
}

- (void) selectBlog:(BlogPref*)aBlog
{
	if ( [[self window] contentView] != panelBlogs )
		[self selectPanel:[NSNumber numberWithInteger:kPrefBlogging]];
	
	[blogPrefsController setSelectedObjects:[NSArray arrayWithObject:aBlog]];
}

- (IBAction) blogAccountWizard:(id)sender 
{
	NSBeep();
	NSLog(@"%s - this method is deprecated", __PRETTY_FUNCTION__);
	
	NSInteger result;
	BlogAccountWizardController *account_creator = [[BlogAccountWizardController alloc] init];
	
	result = [account_creator runAsSheetForWindow:[self window] attached:YES];
	if ( result != NSRunStoppedResponse ) return;
	
	BlogPref *new_account = [account_creator blogPref];
	
	[[self journal] addBlog:new_account];
	[blogPrefsController setSelectedObjects:[NSArray arrayWithObject:new_account]];
	
	[account_creator release];
	
}

*/

- (IBAction) changeEmailSetting:(id)sender
{
	NSInteger mailPreference = ( [sender state] == NSOnState ? 1 : 2 );
	[[NSUserDefaults standardUserDefaults] setInteger:mailPreference forKey:@"UseMailForEmailing"];
}

- (IBAction) chooseWeblogEditor:(id)sender
{
	JournlerWeblogInterface *webInterface = [[JournlerWeblogInterface alloc] init];
	[webInterface choosePreferredEditor:self didEndSelector:@selector(didChoosePreferredEditor:returnCode:editor:) modalForWindow:[self window]];
}

- (void) didChoosePreferredEditor:(JournlerWeblogInterface*)weblogInterface returnCode:(NSInteger)returnCode editor:(NSString*)filename
{
	if ( returnCode == NSOKButton )
	{
		[[NSUserDefaults standardUserDefaults] setObject:filename forKey:@"PreferredWeblogEditor"];
		[self setPreferredWeblogEditor:filename];
	}
	else
	{
		// select the zero index item either way
		[weblogEditorPopUp selectItemAtIndex:0];
	}
	
	// release now that we're finished with it
	[weblogInterface release];
}

- (void) setPreferredWeblogEditor:(NSString*)filename
{
	if ( filename != nil )
	{
		if ( [[weblogEditorPopUp itemAtIndex:0] representedObject] != nil )
			[weblogEditorPopUp removeItemAtIndex:0];
		
		NSString *appName = [[[NSFileManager defaultManager] displayNameAtPath:filename] stringByDeletingPathExtension];
		
		[weblogEditorPopUp insertItemWithTitle:appName atIndex:0];
		[[weblogEditorPopUp itemAtIndex:0] setRepresentedObject:filename];
		
		// select the zero index item either way
		[weblogEditorPopUp selectItemAtIndex:0];
	}
}

#pragma mark -
#pragma mark License

- (IBAction) enterLicense:(id)sender
{
	if ( licenseType == kJournlerLicenseInvalid )
	{
		// request license confirmation
		[NSApp beginSheet: licenseSheet
				modalForWindow: [self window]
				modalDelegate: self
				didEndSelector: @selector(licenseSheetDidEnd:returnCode:contextInfo:)
				contextInfo: nil];
	}
	else
	{
		// invalidate the current license
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LicenseName"];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LicenseCode"];
		
		// retitle the button
		[enterLicenseButton setTitle:NSLocalizedString(@"enter license",@"")];
		
		// redisplay the license information
		NSString *dLicensePath = [[NSBundle mainBundle] pathForResource:@"LicenseInformation" ofType:@"html"];
		[[licenseWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:dLicensePath]]];
		
		// adjust the size of the license panel
		NSRect contentRect, newFrame;
		NSInteger newViewFrameHeight = 422;
		
		contentRect = [[self window] contentRectForFrameRect:[[self window] frame]];
		contentRect.origin.y = contentRect.origin.y + contentRect.size.height - newViewFrameHeight;
		contentRect.size.height = newViewFrameHeight;
		
		newFrame = [[self window] frameRectForContentRect:contentRect];
		
		[[self window] setContentView:panelTemporary];
		[[self window] setFrame:newFrame display:YES animate:YES];
		[[self window] setContentView:panelDonations];
		
		// reset the internal cache
		licenseType = kJournlerLicenseInvalid;
	}
}

- (IBAction) confirmLicense:(id)sender
{
	// verify the license
	NSString *enteredName = [licenseNameField stringValue];
	NSMutableString *enteredDigest = [NSMutableString string];
	
	[enteredDigest appendString:[licenseSequence1 stringValue]];
	[enteredDigest appendString:[licenseSequence2 stringValue]];
	[enteredDigest appendString:[licenseSequence3 stringValue]];
	[enteredDigest appendString:[licenseSequence4 stringValue]];
	
	[self checkLicenseName:enteredName code:enteredDigest];
	[self loadLicenseViewer];
}

- (void) checkLicenseName:(NSString*)name code:(NSString*)code
{
	// name, code = xxxxxxxxxxxxxx (no dashes)
	
	licenseType = [[JournlerLicenseManager sharedManager] licenseTypeForName:name digest:code];
	
	if ( licenseType == kJournlerLicensePersonal )
	{
		NSRunAlertPanel(NSLocalizedString(@"alert valid license title",@""),NSLocalizedString(@"alert valid personal use",@""),nil,nil,nil);
		[[NSUserDefaults standardUserDefaults] setObject:name forKey:@"LicenseName"];
		[[NSUserDefaults standardUserDefaults] setObject:code forKey:@"LicenseCode"];
		[NSApp endSheet:licenseSheet returnCode:NSRunStoppedResponse];
	}
	else if ( licenseType == kJournlerLicenseNonPersonal )
	{
		NSRunAlertPanel(NSLocalizedString(@"alert valid license title",@""),NSLocalizedString(@"alert valid nonpersonal use",@""),nil,nil,nil);
		[[NSUserDefaults standardUserDefaults] setObject:name forKey:@"LicenseName"];
		[[NSUserDefaults standardUserDefaults] setObject:code forKey:@"LicenseCode"];
		[NSApp endSheet:licenseSheet returnCode:NSRunStoppedResponse];
	}
	else if ( licenseType == kJournlerLicenseBeta )
	{
		NSRunAlertPanel(NSLocalizedString(@"alert valid license title",@""),NSLocalizedString(@"alert valid beta",@""),nil,nil,nil);
		[[NSUserDefaults standardUserDefaults] setObject:name forKey:@"LicenseName"];
		[[NSUserDefaults standardUserDefaults] setObject:code forKey:@"LicenseCode"];
		[NSApp endSheet:licenseSheet returnCode:NSRunStoppedResponse];
	}
	else if ( licenseType == kJournlerLicenseSpecial )
	{
		NSRunAlertPanel(NSLocalizedString(@"alert valid license title",@""),NSLocalizedString(@"alert valid journler",@""),nil,nil,nil);
		[[NSUserDefaults standardUserDefaults] setObject:name forKey:@"LicenseName"];
		[[NSUserDefaults standardUserDefaults] setObject:code forKey:@"LicenseCode"];
		[NSApp endSheet:licenseSheet returnCode:NSRunStoppedResponse];
	}
	else if ( licenseType == kJournlerLicenseFull )
	{
		NSRunAlertPanel(NSLocalizedString(@"alert valid license title",@""),NSLocalizedString(@"alert valid full",@""),nil,nil,nil);
		[[NSUserDefaults standardUserDefaults] setObject:name forKey:@"LicenseName"];
		[[NSUserDefaults standardUserDefaults] setObject:code forKey:@"LicenseCode"];
		[NSApp endSheet:licenseSheet returnCode:NSRunStoppedResponse];
	}
	else
	{
		NSBeep();
		NSRunAlertPanel(NSLocalizedString(@"alert invalid license title",@""),NSLocalizedString(@"alert invalid msg",@""),nil,nil,nil);
	}

}

- (IBAction) cancelLicense:(id)sender
{
	// simply quit the sheet
	[NSApp endSheet:licenseSheet returnCode:NSRunAbortedResponse];
}

- (void) licenseSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void  *)contextInfo
{	
	// close the window
	[licenseSheet orderOut:self];
	
	if ( returnCode == NSRunStoppedResponse )
	{
		// adjust the size of the license panel
		if ( licenseType == kJournlerLicenseFull || licenseType == kJournlerLicenseSpecial )
		{
			NSRect contentRect, newFrame;
			NSInteger newViewFrameHeight = ( licenseType == kJournlerLicenseFull ? 200 : 250 );
			
			contentRect = [[self window] contentRectForFrameRect:[[self window] frame]];
			contentRect.origin.y = contentRect.origin.y + contentRect.size.height - newViewFrameHeight;
			contentRect.size.height = newViewFrameHeight;
			
			newFrame = [[self window] frameRectForContentRect:contentRect];
			
			[[self window] setContentView:panelTemporary];
			[[self window] setFrame:newFrame display:YES animate:YES];
			[[self window] setContentView:panelDonations];
			
			[[[self window] contentView] setHidden:YES];
			[[self window] setFrame:newFrame display:YES animate:YES];
			[[[self window] contentView] setHidden:NO];
		}
	}
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
	id anObject = [aNotification object];
	
	if ( [anObject tag] >= 776 && [anObject tag] <= 779 )
	{
		NSString *stringValue = [[anObject stringValue] uppercaseString];
		[anObject setStringValue:stringValue];
		
		if ( anObject == licenseSequence1 && [stringValue length] == 19 )
		{
			NSArray *sections = [stringValue componentsSeparatedByString:@"-"];
			if ( [sections count] == 4 )
			{
				[licenseSequence1 setStringValue:[sections objectAtIndex:0]];
				[licenseSequence2 setStringValue:[sections objectAtIndex:1]];
				[licenseSequence3 setStringValue:[sections objectAtIndex:2]];
				[licenseSequence4 setStringValue:[sections objectAtIndex:3]];
			}
		}
		else
		{
			if ( [stringValue length] >= 4 )
			{
				if ( anObject == licenseSequence1 )
					[licenseSheet makeFirstResponder:licenseSequence2];
				else if ( anObject == licenseSequence2 )
					[licenseSheet makeFirstResponder:licenseSequence3];
				else if ( anObject == licenseSequence3 )
					[licenseSheet makeFirstResponder:licenseSequence4];
			}
		}
	}
	
	else if ( anObject == imageWidthField )
	{
		if ( [anObject integerValue] == 0 && [[anObject stringValue] length] != 0 )
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"EmbeddedImageUseFullSize"];
	}
}

#pragma mark -
#pragma mark setting colors

- (IBAction) selectColor:(id) sender 
{
	[[self window] makeFirstResponder:sender];
	[[NSColorPanel sharedColorPanel] setColor:[sender color]];
	[NSApp orderFrontColorPanel:sender];
}

- (void) changeColor:(id) sender 
{
	//send it off to our display via user defaults
	if ( ![[[self window] firstResponder] isKindOfClass:[PDButtonColorWell class]] )
		NSBeep();
	else
	{
		
		NSString *defaultsKey = [(PDButtonColorWell*)[[self window] firstResponder] defaultsKey];
		if ( defaultsKey == nil )
			[(PDButtonColorWell*)[[self window] firstResponder] setColor:[sender color]];
		else
			[[NSUserDefaults standardUserDefaults] setColor:[sender color] forKey:defaultsKey];
	}
}


#pragma mark -

- (BOOL)fileManager:(NSFileManager *)manager shouldProceedAfterError:(NSDictionary *)errorInfo 
{
	NSLog(@"\n%s - file manager error working with path: %@\n", __PRETTY_FUNCTION__, [errorInfo description]);
	return NO;
}

- (void)fileManager:(NSFileManager *)manager willProcessPath:(NSString *)path 
{
	return;
}

@end

#pragma mark -

@implementation PrefWindowController (Toolbars)

	static NSString *PrefToolbarIdentifier = @"Preferences Toolbar";	
	
	static NSString *ToolbarItemDonations = @"ToolbarItemDonations";
	static NSString *ToolbarItemGeneral = @"ToolbarItemGeneral";
	static NSString *ToolbarItemEditing = @"ToolbarItemEditing";
	//static NSString *ToolbarItemBlogging = @"ToolbarItemBlogging";
	static NSString *ToolbarItemAppearance = @"ToolbarItemAppearance";
	static NSString *ToolbarItemMedia = @"ToolbarItemMedia";
	static NSString *ToolbarItemAdvanced = @"ToolbarItemAdvanced";
	static NSString *ToolbarItemLabels = @"ToolbarItemLabels";

- (void) setupToolbar 
{
	PDToolbar *toolbar = [[[PDToolbar alloc] initWithIdentifier: PrefToolbarIdentifier] autorelease];
	
	[toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
    [toolbar setDelegate: self];
	
    [[self window] setToolbar: toolbar];
	[[[self window] toolbar] setSelectedItemIdentifier:( licenseType != kJournlerLicenseFull && licenseType != kJournlerLicenseSpecial ? ToolbarItemDonations : ToolbarItemGeneral )];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted 
{
	NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
    
	[toolbarItem setTarget:self];
	[toolbarItem setAction:@selector(tabPanel:)];
	
	if ( [itemIdent isEqualToString:ToolbarItemDonations] )
	{
		[toolbarItem setTag:kPrefDonations];
		[toolbarItem setImage:[NSImage imageNamed:@"ToolbarItemDonations.tif"]];
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"donpref label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedStringFromTable(@"donpref label", @"Toolbar", @"")];
		//[toolbarItem setToolTip: NSLocalizedStringFromTable(@"donpref tip", @"Toolbar", @"")];
	}
	else if ( [itemIdent isEqualToString:ToolbarItemGeneral] )
	{
		[toolbarItem setTag:kPrefGeneral];
		[toolbarItem setImage:[NSImage imageNamed:@"ToolbarItemGeneralPreferences.png"]];
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"genpref label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedStringFromTable(@"genpref label", @"Toolbar", @"")];
		//[toolbarItem setToolTip: NSLocalizedStringFromTable(@"genpref tip", @"Toolbar", @"")];
	}
	else if ( [itemIdent isEqualToString:ToolbarItemEditing] )
	{
		[toolbarItem setTag:kPrefEditing];
		[toolbarItem setImage:[NSImage imageNamed:@"ToolbarItemEditing.tiff"]];
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"pref editing label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedStringFromTable(@"pref editing label", @"Toolbar", @"")];
		//[toolbarItem setToolTip: NSLocalizedStringFromTable(@"pref editing tip", @"Toolbar", @"")];
	}
	/*
	else if ( [itemIdent isEqualToString:ToolbarItemBlogging] )
	{
		[toolbarItem setTag:kPrefBlogging];
		[toolbarItem setImage:[NSImage imageNamed:@"ToolbarItemBlog.tiff"]];
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"blogpref label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedStringFromTable(@"blogpref label", @"Toolbar", @"")];
		//[toolbarItem setToolTip: NSLocalizedStringFromTable(@"blogpref tip", @"Toolbar", @"")];
	}
	*/
	else if ( [itemIdent isEqualToString:ToolbarItemAppearance] )
	{
		[toolbarItem setTag:kPrefWindow];
		[toolbarItem setImage:[NSImage imageNamed:@"ToolbarItemAppearance.tif"]];
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"appearpref label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedStringFromTable(@"appearpref label", @"Toolbar", @"")];
		//[toolbarItem setToolTip: NSLocalizedStringFromTable(@"appearpref tip", @"Toolbar", @"")];
	}
	else if ( [itemIdent isEqualToString:ToolbarItemMedia] )
	{
		[toolbarItem setTag:kPrefMedia];
		[toolbarItem setImage:[NSImage imageNamed:@"ToolbarItemMediaPrefs.png"]];
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"pref media label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedStringFromTable(@"pref media label", @"Toolbar", @"")];
		//[toolbarItem setToolTip: NSLocalizedStringFromTable(@"pref media tip", @"Toolbar", @"")];
	}
	else if ( [itemIdent isEqualToString:ToolbarItemAdvanced] )
	{
		[toolbarItem setTag:kPrefAdvanced];
		[toolbarItem setImage:[NSImage imageNamed:@"ToolbarItemAdvanced.tiff"]];
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"pref advanced label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedStringFromTable(@"pref advanced label", @"Toolbar", @"")];
		//[toolbarItem setToolTip: NSLocalizedStringFromTable(@"pref advanced tip", @"Toolbar", @"")];
	}
	
	else if ( [itemIdent isEqualToString:ToolbarItemLabels] )
	{
		[toolbarItem setTag:kPrefLabels];
		[toolbarItem setImage:[NSImage imageNamed:@"ToolbarItemLabels.icns"]];
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"pref labels label", @"Toolbar", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedStringFromTable(@"pref labels label", @"Toolbar", @"")];
		//[toolbarItem setToolTip: NSLocalizedStringFromTable(@"pref labels tip", @"Toolbar", @"")];
	}

	else 
	{
		toolbarItem = nil;
    }
	
    return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar 
{
	return [NSArray arrayWithObjects: ToolbarItemDonations, NSToolbarSeparatorItemIdentifier, 
			ToolbarItemGeneral, ToolbarItemAppearance, ToolbarItemLabels, ToolbarItemEditing, 
			ToolbarItemMedia, /*ToolbarItemBlogging,*/ ToolbarItemAdvanced, nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar 
{
	return [NSArray arrayWithObjects: ToolbarItemDonations, ToolbarItemGeneral, ToolbarItemAppearance,
			ToolbarItemLabels, ToolbarItemEditing, ToolbarItemMedia, /*ToolbarItemBlogging,*/ 
			NSToolbarSeparatorItemIdentifier, ToolbarItemAdvanced, nil];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects: ToolbarItemDonations, NSToolbarSeparatorItemIdentifier, 
			ToolbarItemGeneral, ToolbarItemAppearance, ToolbarItemLabels, ToolbarItemEditing, 
			ToolbarItemMedia, /*ToolbarItemBlogging,*/ ToolbarItemAdvanced, nil];
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem 
{
   return YES;
}

@end

