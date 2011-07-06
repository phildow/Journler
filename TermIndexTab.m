#import "TermIndexTab.h"

#import "JournlerWindowController.h"

#import "JournlerJournal.h"
#import "JournlerSearchManager.h"
#import "JournlerObject.h"
#import "JournlerEntry.h"
#import "JournlerResource.h"

#import <SproutedUtilities/SproutedUtilities.h>

/*
#import "ImageAndTextCell.h"
#import "NSImage_PDCategories.h"
#import "NSString+PDStringAdditions.h"

#import "RBSplitView.h"
#import "JournlerGradientView.h"
#import "PDFavoritesBar.h"
*/

#import "IndexLetterView.h"
#import "EntryCellController.h"
#import "ResourceCellController.h"

#import "IndexNode.h"
#import "IndexColumn.h"
#import "IndexBrowser.h"
#import "JournlerIndexServer.h"
#import "Definitions.h"
#import "EntryWindowController.h"


static NSArray *DefaultDocumentsSort()
{
	static NSArray *documentSort = nil;
	if ( documentSort == nil )
	{
		NSSortDescriptor *titleSort = [[[NSSortDescriptor alloc] 
				initWithKey:@"title" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] autorelease];
		
		NSSortDescriptor *utiSort = [[[NSSortDescriptor alloc] 
				initWithKey:@"uti" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease];
		
		documentSort = [[NSArray alloc] initWithObjects:titleSort, utiSort, nil];
	}
	
	return documentSort;
}

#pragma mark -

@implementation TermIndexTab

- (id) initWithOwner:(JournlerWindowController*)anObject 
{	
	if ( self = [super initWithOwner:anObject] ) 
	{
		
		// prepare the cell controllers
		entryCellController = [[EntryCellController alloc] init];
		resourceCellController = [[ResourceCellController alloc] init];
		
		[entryCellController setJournal:[self journal]];
		[entryCellController setDelegate:self];
		[resourceCellController setDelegate:self];
		
		selectedDocuments = [[NSArray alloc] init];
		//termToDocumentsDictionary = [[NSMutableDictionary alloc] init];
		documentToTermsDictionary = [[NSMutableDictionary alloc] init];
			
		loadingDocuments = nil;
		indexServer = ( [anObject respondsToSelector:@selector(indexServer)] ? [anObject indexServer] : nil );
		
		[NSBundle loadNibNamed:@"TermIndexTab" owner:self];

	}
	return self;
}

- (void) awakeFromNib
{
	activeContentView = contentPlaceholder;
	
	[mainSplit restoreState:YES];
	[[[self journal] searchManager] writeIndexToDisk];
	
	if ( indexServer != nil )
	{
		// provide a mechanism by which to load the content outside of awake from nib (in case the server hasn't been set yet)
		if ( [indexServer rootTermsLoaded] )
		{
			[indexBrowser setInitialContent:[indexServer rootTermNodes]];
		}
		else
		{
			[indexBrowser setInitialContent:nil];
			[NSThread detachNewThreadSelector:@selector(loadRootTermNodes:) toTarget:self withObject:nil];
		}
	}
	
	// load the help file for the lexicon
	NSString *aPath = [[NSBundle mainBundle] pathForResource:@"lexiconinlexicon" ofType:@"html" inDirectory:@"Journler Help Files/html"];
	if ( aPath != nil )
	{
		NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:aPath]];
		[[contentPlaceholder mainFrame] loadRequest:urlRequest];
	}
	else
	{
		NSLog(@"%@ %s - unable to locate lexiconinlexicon.html in Journler Help Files/html", [self className], _cmd);
	}
	
	//int borders[4] = {1,1,1,1};
	//[contentPlaceholder setBordered:YES];
	//[contentPlaceholder setDrawsGradient:YES];
	//[contentPlaceholder setBorders:borders];
}

- (void) dealloc
{
	#ifdef __DEBUG__
	NSLog(@"%@ %s",[self className],_cmd);
	#endif
	
	[entryCellController release];
	[resourceCellController release];
	
	[selectedDocuments release];
	[documentToTermsDictionary release];
	
	[documentContextMenu release];
	[termContextMenu release];
	
	[super dealloc];
}

- (void) ownerWillClose 
{
	[super ownerWillClose];
		
	[entryCellController ownerWillClose];
	[resourceCellController ownerWillClose];
}

#pragma mark -

- (NSView*) activeContentView 
{
	return activeContentView;
}

#pragma mark -

- (void) setSelectedEntries:(NSArray*)anArray 
{
	recordNavigationEvent = NO;
	[super setSelectedEntries:anArray];
}

- (void) setSelectedResources:(NSArray*)anArray 
{
	recordNavigationEvent = NO;
	[super setSelectedResources:anArray];
}

- (NSArray*) selectedDocuments
{
	return selectedDocuments;
}

- (void) setSelectedDocuments:(NSArray*)anArray
{	
	// #warning not ready for multiple selection
	
	if ( selectedDocuments != anArray )
	{
		[selectedDocuments release];
		selectedDocuments = [anArray retain];
		
		if ( [selectedDocuments count] == 0 )
		{
		
		}
		
		else if ( [selectedDocuments count] == 1 )
		{
			if ( [[selectedDocuments objectAtIndex:0] isKindOfClass:[JournlerEntry class]] )
			{
				[resourceCellController setSelectedResources:nil];
				[self setSelectedResources:nil];
				[self setSelectedEntries:selectedDocuments];
				
				[self setActiveContentView:[entryCellController contentView]];	
				[entryCellController setSelectedEntries:selectedDocuments];
			}
			else if ( [[selectedDocuments objectAtIndex:0] isKindOfClass:[JournlerResource class]] )
			{
				[entryCellController setSelectedEntries:nil];
				[self setSelectedEntries:nil];
				[self setSelectedResources:selectedDocuments];
				
				[self setActiveContentView:[resourceCellController contentView]];
				[resourceCellController setSelectedResources:selectedDocuments];
				
			}
		}
		
		else
		{
			// filter out the entries and display the multiply selected resources
			JournlerObject *anObject;
			NSMutableArray *resourcesOnly = [NSMutableArray array];
			NSEnumerator *enumerator = [selectedDocuments objectEnumerator];
			
			while ( anObject = [enumerator nextObject] )
			{
				if ( [anObject isKindOfClass:[JournlerResource class]] )
					[resourcesOnly addObject:anObject];
			}
			
			[entryCellController setSelectedEntries:nil];
			[self setActiveContentView:[resourceCellController contentView]];
			[resourceCellController setSelectedResources:resourcesOnly];
			
			[self setSelectedEntries:nil];
			[self setSelectedResources:selectedDocuments];
		}
	}
}

- (JournlerIndexServer*) indexServer
{
	return indexServer;
}

- (void) setIndexServer:(JournlerIndexServer*)aServer
{
	if ( indexServer != aServer )
	{
		[indexServer release];
		indexServer = [aServer retain];
	}
}

#pragma mark -

- (void) loadRootTermNodes:(id)anObject
{
	NSArray *rootTerms = nil;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if ( ![indexServer loadRootTerms] )
	{
		NSLog(@"%@ %s - unable to load root terms from index server", [self className], _cmd);
		rootTerms = [NSArray array];
	}
	else
	{
		rootTerms = [indexServer rootTermNodes];
	}
	
	[indexBrowser performSelectorOnMainThread:@selector(setInitialContent:) withObject:rootTerms waitUntilDone:YES];
	[pool release];
}

/*
- (void) setSelectedDocumentsOnSeparateThread:(NSArray*)anArray
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSThread setThreadPriority:1.0];
	[self setSelectedDocuments:anArray];
	[pool release];
}
*/

- (void) loadTermsForObjectAtIndex:(NSDictionary*)aDictionary
{
	// may be performed on a separate thread to give document loading priority on the main thread
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	unsigned anIndex = [[aDictionary objectForKey:@"index"] intValue];
	NSArray *documentNodes = [aDictionary objectForKey:@"documents"];
	
	if ( loadingDocuments != nil )
		[loadingDocuments release];
	
	// a global variable to check the local variable against
	loadingDocuments = [documentNodes retain];
	
	[termsForObjectsLock lock];
	
	NSArray *content = [indexServer termNodesForDocumentNodes:documentNodes];
	if ( content == nil )
		content = [NSArray array];
	
	if ( documentNodes == loadingDocuments )
	{
		NSDictionary *contentDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				content, @"content", 
				[NSNumber numberWithUnsignedInt:anIndex], @"index", nil];
				
		[indexBrowser performSelectorOnMainThread:@selector(setContentAtIndex:) withObject:contentDictionary waitUntilDone:YES];
	}
	
	[pool release];
	[termsForObjectsLock unlock];
	
	/*
	BOOL setContent = NO;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSArray *documents = [aDictionary objectForKey:@"documents"];
	if ( documents == nil || [documents count] == 0 )
		goto bail;
	
	JournlerObject *anObject = [documents objectAtIndex:0];
	unsigned anIndex = [[aDictionary objectForKey:@"index"] intValue];
	
	NSMutableArray *content = [NSMutableArray array];
	NSArray *objectTermDictionaries = [documentToTermsDictionary objectForKey:anObject];
	JournlerSearchManager *searchManager = [[self journal] searchManager];
		
	if ( objectTermDictionaries == nil )
	{
		NSString *aTerm;
		NSArray *terms = [searchManager termsForJournlerObject:anObject options:kIgnoreNumericTerms];
		NSEnumerator *enumerator = [terms objectEnumerator];
		
		_breakTermLoadingThread = NO;
		
		while ( aTerm = [enumerator nextObject] )
		{
			if ( _breakTermLoadingThread )
			{
				#ifdef __DEBUG__
				NSLog(@"%@ %s - killing thread", [self className],_cmd);
				#endif
				goto bail;
				//[pool release];
				//[NSThread exit];
			}
			
			unsigned count = [searchManager countOfDocumentsForTerm:aTerm options:kIgnoreNumericTerms];
			unsigned frequency = [searchManager frequenceyOfTerm:aTerm forDocument:anObject options:kIgnoreNumericTerms];
			
			IndexNode *aNode = [[[IndexNode alloc] init] autorelease];
		
			[aNode setTitle:aTerm];
			[aNode setRepresentedObject:aTerm];
			[aNode setCount:count];
			[aNode setFrequency:frequency];
			
			[content addObject:aNode];

		}
		
		setContent = YES;
		[documentToTermsDictionary setObject:content forKey:anObject];
	}
	else
	{
		setContent = YES;
		[content setArray:objectTermDictionaries];
	}
	
bail:

	if ( setContent ) 
	{
		#ifdef __DEBUG__
		NSLog(@"%@ %s - setting content", [self className],_cmd);
		#endif
		NSDictionary *contentDictionary = [NSDictionary dictionaryWithObjectsAndKeys:content, @"content", [NSNumber numberWithUnsignedInt:anIndex], @"index", nil];
		[indexBrowser performSelectorOnMainThread:@selector(setContentAtIndex:) withObject:contentDictionary waitUntilDone:YES];
		//[indexBrowser setContent:content forColumnAtIndex:anIndex];
	}
	
	[pool release];
	*/
}

#pragma mark -

- (void) setActiveContentView:(NSView*)aView 
{
	if ( activeContentView == aView || aView == nil )
		return;
	
	// if the current active view is the resource view, we're switch out, so stop whatever it's doing
	if ( activeContentView == [resourceCellController contentView] )
		[resourceCellController stopContent];
	
	// if switching to text view, disable custom find panel action, otherwise, update
	if ( aView == [entryCellController contentView] )
	{
		//[[NSApp delegate] performSelector:@selector(setFindPanelPerformsCustomAction:) withObject:[NSNumber numberWithBool:NO]];
		//[[NSApp delegate] performSelector:@selector(setTextSizePerformsCustomAction:) withObject:[NSNumber numberWithBool:NO]];
	}
	else
	{
		//[resourceCellController checkCustomFindPanelAction];
		//[resourceCellController checkCustomTextSizeAction];
	}
	
	//[activeContentView retain];
	[aView setFrame:[activeContentView frame]];
	[[activeContentView superview] replaceSubview:activeContentView with:aView];
	
	activeContentView = aView;
}

- (IBAction) printDocument:(id)sender
{
	// dispatch the print request to the appropriate view controller
	if ( [resourceCellController trumpsPrint] )
	{
		// print whatever the resource view shows (is browsing)
		[resourceCellController printDocument:sender];
	}
	else if ( [[self selectedDocuments] count] == 0 )
	{
		NSBeep(); return;
	}
	
	// #warning multiple selection - this is not set up for multiple selection
	else if ( [[[self selectedDocuments] objectAtIndex:0] isKindOfClass:[JournlerResource class]] )
	{
		// print whatever the resource view shows
		[resourceCellController printDocument:sender];
	}
	else if ( [[[self selectedDocuments] objectAtIndex:0] isKindOfClass:[JournlerEntry class]] )
	{	
		// print the selected entries
		NSArray *printArray = [[[NSArray alloc] initWithArray:[self selectedDocuments]] autorelease];
		NSDictionary *printDict = [NSDictionary dictionaryWithObjectsAndKeys: printArray, @"entries", nil];
	
		[self printEntries:printDict];
	}
	else
	{
		// nothing to print
		NSBeep(); return;
	}
}

#pragma mark -

- (BOOL) canPerformNavigation:(int)direction 
{
	// overridden because subclass does not support navigation
	return NO;
}

- (IBAction) navigateBack:(id)sender
{
	NSBeep(); return;
}

- (IBAction) navigateForward:(id)sender 
{
	NSBeep(); return;
}

#pragma mark -
#pragma mark Custom Find/Text Support

- (BOOL) handlesFindCommand
{
	return ( [self activeContentView] == [resourceCellController contentView] && [resourceCellController handlesFindCommand] );
}

- (void)performCustomFindPanelAction:(id)sender
{
	if ( [self activeContentView] == [resourceCellController contentView] && [resourceCellController handlesFindCommand] )
		[resourceCellController performSelector:@selector(performCustomFindPanelAction:) withObject:sender];
}

- (BOOL) handlesTextSizeCommand
{
	return ( [self activeContentView] == [resourceCellController contentView] && [resourceCellController handlesTextSizeCommand] );
}

- (void) performCustomTextSizeAction:(id)sender
{
	if ( [self activeContentView] == [resourceCellController contentView] && [resourceCellController handlesTextSizeCommand] )
		[resourceCellController performSelector:@selector(performCustomTextSizeAction:) withObject:sender];
}

- (IBAction) performFindPanelAction:(id)sender
{
	if ( [self activeContentView] == [entryCellController contentView] )
		[entryCellController performFindPanelAction:sender];
	else
		NSBeep();
}

#pragma mark -
#pragma mark Validation

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	BOOL enabled = YES;
	//int tag = [menuItem tag];
	SEL action = [menuItem action];
	
	if ( action == @selector(performCustomFindPanelAction:) )
	{
		if ( [self activeContentView] == [entryCellController contentView] )
			enabled = NO;
		else if ( [resourceCellController handlesFindCommand] )
			enabled = [resourceCellController validateMenuItem:menuItem];
	}
	
	else if ( action == @selector(performFindPanelAction:) )
	{
		if ( [self activeContentView] == [entryCellController contentView] )
			enabled = YES;
		else
			enabled = NO;
	}

	else
	{
		enabled = [super validateMenuItem:menuItem];
	}
	
	return enabled;
}

#pragma mark -

- (IBAction) gotoLetter:(id)sender
{
	NSString *letter = [sender selectedLetter];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title beginswith[cd] %@", letter];
	
	IndexColumn *targetColumn = [indexBrowser focusedColumn];
	NSArray *nodes = [targetColumn content];
	
	NSArray *filteredNodes = [nodes filteredArrayUsingPredicate:predicate];
	if ( [filteredNodes count] > 0 )
		[targetColumn scrollNodeToVisible:[filteredNodes objectAtIndex:0]];
	else
	{
		// while loop to get next letter that fits
	}
	
	//NSLog([predicate description]);
}

#pragma mark -

/*
- (IBAction) openDocumentInNewTab:(id)sender
{
	IndexNode *aNode;
	NSEnumerator *enumerator;
	NSArray *focusedNodes = [indexBrowser focusedNodes];
	
	if ( focusedNodes == nil || [focusedNodes count] == 0 )
	{
		NSBeep(); return;
	}
	
	enumerator = [focusedNodes objectEnumerator];
	while ( aNode = [ enumerator nextObject] )
	{
		JournlerObject *representedObject = [aNode representedObject];
		
		if ( [representedObject isKindOfClass:[JournlerResource class]] )
		{
			[[self valueForKey:@"owner"] newTab:sender];
			TabController *theTab =[[self valueForKeyPath:@"owner.tabControllers"] lastObject];
			[theTab selectDate:[anEntry valueForKey:@"calDate"] folders:nil entries:[NSArray arrayWithObject:anEntry] resources:nil];
		}
		
		else if ( [representedObject isKindOfClass:[JournlerEntry class]] )
		{
			[[self valueForKey:@"owner"] newTab:sender];
			TabController *theTab =[[self valueForKeyPath:@"owner.tabControllers"] lastObject];
			[theTab selectDate:[anEntry valueForKey:@"calDate"] folders:nil entries:[NSArray arrayWithObject:anEntry] resources:nil];
		}
	}
}
*/

- (IBAction) openDocumentInNewWindow:(id)sender
{
	IndexNode *aNode;
	NSEnumerator *enumerator;
	NSArray *focusedNodes = [indexBrowser focusedNodes];
	
	if ( focusedNodes == nil || [focusedNodes count] == 0 )
	{
		NSBeep(); return;
	}
	
	enumerator = [focusedNodes objectEnumerator];
	while ( aNode = [ enumerator nextObject] )
	{
		JournlerObject *representedObject = [aNode representedObject];
		
		if ( [representedObject isKindOfClass:[JournlerResource class]] )
			[self openAResourceInNewWindow:(JournlerResource*)representedObject];
		
		else if ( [representedObject isKindOfClass:[JournlerEntry class]] )
			[self openAnEntryInNewWindow:(JournlerEntry*)representedObject];
	}
}

- (IBAction) revealDocumentInFinder:(id)sender
{
	IndexNode *aNode;
	NSEnumerator *enumerator;
	NSArray *focusedNodes = [indexBrowser focusedNodes];
	
	if ( focusedNodes == nil || [focusedNodes count] == 0 )
	{
		NSBeep(); return;
	}
	
	enumerator = [focusedNodes objectEnumerator];
	while ( aNode = [ enumerator nextObject] )
	{
		JournlerObject *representedObject = [aNode representedObject];
		
		if ( [representedObject isKindOfClass:[JournlerResource class]] )
		{
			[(JournlerResource*)representedObject revealInFinder];
		}
		
		else if ( [representedObject isKindOfClass:[JournlerEntry class]] )
		{
			NSString *path = [(JournlerEntry*)representedObject packagePath];
			[[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:[path stringByDeletingLastPathComponent]];
		}
	}
}

- (IBAction) openDocumentInFinder:(id)sender
{
	IndexNode *aNode;
	NSEnumerator *enumerator;
	NSArray *focusedNodes = [indexBrowser focusedNodes];
	
	if ( focusedNodes == nil || [focusedNodes count] == 0 )
	{
		NSBeep(); return;
	}
	
	enumerator = [focusedNodes objectEnumerator];
	while ( aNode = [ enumerator nextObject] )
	{
		JournlerObject *representedObject = [aNode representedObject];
		
		if ( [representedObject isKindOfClass:[JournlerResource class]] )
			[(JournlerResource*)representedObject openWithFinder];
		
		else if ( [representedObject isKindOfClass:[JournlerEntry class]] )
			[self openAnEntryInNewWindow:(JournlerEntry*)representedObject];
	}
}

#pragma mark -

- (IBAction) addTermsToStopList:(id)sender
{

}

#pragma mark -
#pragma mark RBSplitView Delegation

/*
- (void)splitView:(RBSplitView*)sender willDrawSubview:(RBSplitSubview*)subview inRect:(NSRect)rect
{
	[[NSColor darkGrayColor] set];
	NSFrameRect(rect);
}
*/

- (void)splitView:(RBSplitView*)sender wasResizedFrom:(float)oldDimension to:(float)newDimension 
{
	if ( [sender tag] == 0 )
		[sender adjustSubviewsExcepting:[sender subviewAtPosition:0]];
}


- (NSRect)splitView:(RBSplitView*)sender willDrawDividerInRect:(NSRect)dividerRect 
		betweenView:(RBSplitSubview*)leading andView:(RBSplitSubview*)trailing withProposedRect:(NSRect)imageRect
{
	
	NSBezierPath *framePath = [NSBezierPath bezierPathWithRect:dividerRect];
	
	[[NSColor windowBackgroundColor] set];
	[framePath fill];
	
	/*
	NSGraphicsContext *context = [NSGraphicsContext currentContext];
	[context saveGraphicsState];
	[context setShouldAntialias:NO];
	
	[framePath setLineWidth:1];
	
	[[NSColor colorWithCalibratedWhite:0.4 alpha:1.0] set];
	[framePath stroke];

	[context restoreGraphicsState];
	*/
	
	/*
	[context setShouldAntialias:NO];
	
	NSRect frameRect = dividerRect;
	frameRect.origin.x--; frameRect.size.width++;
	
	framePath = [NSBezierPath bezierPathWithRect:frameRect];
	[framePath setLineWidth:1];
	
	[[NSColor colorWithCalibratedWhite:0.4 alpha:1.0] set];
	[framePath stroke];
	
	[context restoreGraphicsState];
	*/
	return imageRect;
}

- (void)splitView:(RBSplitView*)sender willDrawSubview:(RBSplitSubview*)subview inRect:(NSRect)rect
{
	[[NSColor colorWithCalibratedWhite:0.5 alpha:1.0] set];
	NSFrameRect(rect);
}

#pragma mark -
#pragma mark Resource Cell Delegation

- (void) resourceCellController:(ResourceCellController*)aController didChangeTitle:(NSString*)newTitle
{
	if ( [[self owner] respondsToSelector:@selector(tabController:didChangeTitle:)] )
		[[self owner] tabController:self didChangeTitle:newTitle];
}

#pragma mark -
#pragma mark Browser Delegation and Selection

- (NSArray*) browser:(IndexBrowser*)aBrowser contentForNodes:(NSArray*)selectedNodes atColumnIndex:(unsigned)anIndex
{
	NSArray *content = nil;
	//NSMutableArray *content = [[[NSMutableArray alloc] init] autorelease];
	//JournlerSearchManager *searchManager = [[self journal] searchManager];
	
	// bail if we don't have anything to work with
	if ( selectedNodes == nil || [selectedNodes count] == 0 )
		return nil;
	
	// get the nodes represented object
	IndexNode *selectedNode = [selectedNodes objectAtIndex:0];
	id anObject = [selectedNode representedObject];
	
	if ( [anObject isKindOfClass:[NSString class]] )
	{
		content = (NSArray*)[indexServer documentNodesForTermNodes:selectedNodes];
		
		/*
		NSMutableArray *multiArray = [NSMutableArray array];
		NSEnumerator *nodesEnumerator = [selectedNodes objectEnumerator];
		
		while ( selectedNode = [nodesEnumerator nextObject] )
		{
			
			anObject = [selectedNode representedObject];
			if ( ![anObject isKindOfClass:[NSString class]] )
				continue;
			
			NSString *theTerm = anObject;
			
			// get an array of journler objects that have been prepared for this selection (no duplicates allowed)
			NSArray *alreadyRepresented = [multiArray valueForKey:@"representedObject"];
			
			// try the cache
			NSArray *journlerObjects = [termToDocumentsDictionary objectForKey:theTerm];
			if ( journlerObjects == nil ) 
			{
				NSMutableArray *thisTermsObjects = [NSMutableArray array];
				
				// grab the objects and set the cache
				journlerObjects = [[searchManager journlerObjectsForTerm:theTerm options:kIgnoreNumericTerms]
						sortedArrayUsingDescriptors:DefaultDocumentsSort()];
				
				JournlerObject *aJournlerObject;
				NSEnumerator *enumerator = [journlerObjects objectEnumerator];
				
				while ( aJournlerObject = [enumerator nextObject] )
				{
					IndexNode *aNode = [[[IndexNode alloc] init] autorelease];
					
					[aNode setTitle:[aJournlerObject title]];
					[aNode setRepresentedObject:aJournlerObject];
					//[aNode setCount:0];
					
					// produce children for the journler object
					NSArray *children = nil;
					NSMutableArray *childNodes = [NSMutableArray array];
					
					if ( [aJournlerObject isKindOfClass:[JournlerResource class]] )
						children = [NSArray arrayWithObject:[(JournlerResource*)aJournlerObject entry]];
					else if ( [aJournlerObject isKindOfClass:[JournlerEntry class]] )
						children = [(JournlerEntry*)aJournlerObject resources];
					
					JournlerObject *aChildObject;
					NSEnumerator *childEnumerator = [children objectEnumerator];
					
					while ( aChildObject = [childEnumerator nextObject] )
					{
						IndexNode *aChildNode = [[[IndexNode alloc] init] autorelease];
					
						[aChildNode setTitle:[aChildObject title]];
						[aChildNode setRepresentedObject:aChildObject];
						[aChildNode setParent:aNode];
						
						[childNodes addObject:aChildNode];
					}
					
					// actually set the child nodes - could do the same for user defined term synonyms
					[aNode setChildren:childNodes];
					
					[content addObject:aNode];
					[thisTermsObjects addObject:aNode];
					
					if ( ![alreadyRepresented containsObject:aJournlerObject] )
						[multiArray addObject:aNode];
				}
				
				[termToDocumentsDictionary setObject:thisTermsObjects forKey:theTerm];
			}
			else
			{
				//[content setArray:journlerObjects];
				
				// only add objects that have not been added already
				IndexNode *aCachedNode;
				NSEnumerator *journlerObjectsEnumerator = [journlerObjects objectEnumerator];
				
				while ( aCachedNode = [journlerObjectsEnumerator nextObject] )
				{
					if ( ![alreadyRepresented containsObject:[aCachedNode representedObject]] )
						[multiArray addObject:aCachedNode];
				}
			}
			
		}
		
		// reset the count on this node
		[selectedNode setCount:[content count]];
		
		// set the returned content to our parsed-for-duplicates multi array
		[content setArray:multiArray];
		*/
	}
	
	else if ( [anObject isKindOfClass:[JournlerObject class]] )
	{
		// get the objects, reset the represented object, return the count
		
		// if this is a resource that represents the entry, we want the entry
		if ( [anObject isKindOfClass:[JournlerResource class]] 
				&& [(JournlerResource*)anObject representsJournlerObject] 
				&& [[(JournlerResource*)anObject journlerObject] isKindOfClass:[JournlerEntry class]] )
		{
			anObject = [(JournlerResource*)anObject journlerObject];
		}
		
		// thread priority
		double currentPriority = [NSThread threadPriority];
		
		// break any load thread that might be taking place right now
		_breakTermLoadingThread = YES;
				
		// and pause for a moment
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		
		// fork the term loading to another thread
		NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:anObject,nil], @"documents", [NSNumber numberWithInt:anIndex+1], @"index", nil];
		[NSThread detachNewThreadSelector:@selector(loadTermsForObjectAtIndex:) toTarget:self withObject:dictionary];
		
		// give this thread priority
		[NSThread setThreadPriority:0.8];
		
		// load and display the document on this thread
		[self setSelectedDocuments:[NSArray arrayWithObject:anObject]];
		
		// reset the priority
		[NSThread setThreadPriority:currentPriority];
		
		// return empty content
		content = nil;
	}

	return content;
}

- (void) browser:(IndexBrowser*)aBrowser column:(IndexColumn*)aColumn didChangeSelection:(NSArray*)selectedNode lastSelection:(IndexNode*)aNode
{
	// used to highlight the current document
	id anObject = [aNode representedObject];
	
	if ( [anObject isKindOfClass:[NSString class]] )
	{
		if ( [self activeContentView] == [entryCellController contentView] )
			[entryCellController highlightString:anObject];
		
		else if ( [self activeContentView] == [resourceCellController contentView] )
			[resourceCellController highlightString:anObject];
	}
	else if ( [anObject isKindOfClass:[JournlerObject class]] )
	{
		unsigned indexOfColumn = [[aBrowser columns] indexOfObjectIdenticalTo:aColumn];
		if ( indexOfColumn > 0 )
		{
			id selectedTerm = [[[[aBrowser columns] objectAtIndex:indexOfColumn-1] selectedObject] representedObject];
			if ( [selectedTerm isKindOfClass:[NSString class]] )
			{
				#ifdef __DEBUG__
				NSLog(@"%@ %s - selected term: %@", [self className], _cmd, selectedTerm);
				#endif
				
				if ( [self activeContentView] == [entryCellController contentView] )
					[entryCellController highlightString:selectedTerm];
				
				else if ( [self activeContentView] == [resourceCellController contentView] )
					[resourceCellController highlightString:selectedTerm];
			}
		}

	}
}

#pragma mark -

- (BOOL) browser:(IndexBrowser*)aBrowser columnForNodeDrawsIcon:(IndexNode*)selectedNode atColumnIndex:(unsigned)anIndex
{
	// the represented object is the selection whose contents are going to be displayed
	id representedObject = [selectedNode representedObject];
	
	if ( [representedObject isKindOfClass:[NSString class]] )
		return YES;
	else
		return NO;
}

- (BOOL) browser:(IndexBrowser*)aBrowser columnForNodeShowsCount:(IndexNode*)selectedNode atColumnIndex:(unsigned)anIndex
{
	// the represented object is the selection whose contents are going to be displayed
	id representedObject = [selectedNode representedObject];
	
	if ( [representedObject isKindOfClass:[NSString class]] )
		return NO;
	else
		return YES;
}

- (BOOL) browser:(IndexBrowser*)aBrowser columnForNodeShowsFrequency:(IndexNode*)selectedNode atColumnIndex:(unsigned)anIndex
{
	// the represented object is the selection whose contents are going to be displayed
	
	if ( selectedNode == nil )
		return NO;
	
	id representedObject = [selectedNode representedObject];
	
	if ( [representedObject isKindOfClass:[NSString class]] )
		return NO;
	else
		return YES;
}

- (BOOL) browser:(IndexBrowser*)aBrowser columnForNodeAllowsMultipleSelection:(IndexNode*)selectedNode atColumnIndex:(unsigned)anIndex
{
	if ( selectedNode == nil )
		return YES;
	
	id representedObject = [selectedNode representedObject];
	
	if ( [representedObject isKindOfClass:[NSString class]] )
		return NO;
	else
		return YES;
}

- (BOOL) browser:(IndexBrowser*)aBrowser columnForNodeCanDeleteContent:(IndexNode*)selectedNode atColumnIndex:(unsigned)anIndex
{
	if ( selectedNode == nil )
		return YES;
	
	id representedObject = [selectedNode representedObject];
	
	if ( [representedObject isKindOfClass:[NSString class]] )
		return NO;
	else
		return YES;
}

#pragma mark -

- (NSString*) browser:(IndexBrowser*)aBrowser titleForNode:(IndexNode*)selectedNode atColumnIndex:(unsigned)anIndex
{
	// the represented object is the Node whose contents are going to be displayed
	if ( selectedNode == nil ) // first column
		return nil;
	
	id representedObject = [selectedNode representedObject];
	
	if ( [representedObject isKindOfClass:[NSString class]] )
		return representedObject;
	else if ( [representedObject isKindOfClass:[JournlerObject class]] )
		return [representedObject valueForKey:@"title"];
	else
		return nil;
}

- (NSString*) browser:(IndexBrowser*)aBrowser headerTitleForNode:(IndexNode*)selectedNode atColumnIndex:(unsigned)anIndex
{
	// the represented object is the Node whose contents are going to be displayed
	if ( selectedNode == nil ) // first column
		return NSLocalizedString(@"term header title",@"");
	
	id representedObject = [selectedNode representedObject];
	
	if ( [representedObject isKindOfClass:[NSString class]] )
		return NSLocalizedString(@"document header title",@"");
	else if ( [representedObject isKindOfClass:[JournlerObject class]] )
		return NSLocalizedString(@"term header title",@"");
	else
		return NSLocalizedString(@"term header title",@"");
}

- (NSString*) browser:(IndexBrowser*)aBrowser countSuffixForNode:(IndexNode*)selectedNode atColumnIndex:(unsigned)anIndex
{
	// the represented object is the Node whose contents are going to be displayed
	if ( selectedNode == nil ) // first column
		return NSLocalizedString(@"terms label",@"");
	
	id representedObject = [selectedNode representedObject];
	
	if ( [representedObject isKindOfClass:[NSString class]] )
		return NSLocalizedString(@"documents label",@"");
	else if ( [representedObject isKindOfClass:[JournlerObject class]] )
		return NSLocalizedString(@"terms label",@"");
	else
		return nil;
}

- (NSArray*) browser:(IndexBrowser*)aBrowser sortDescriptorsForNode:(IndexNode*)selectedNode atColumnIndex:(unsigned)anIndex
{
	if ( anIndex == 0 ) // use the saved sort descriptors
		return nil;
	
	// otherwise allow the browser to determine the sort
	else return nil;
}

- (BOOL) browser:(IndexBrowser*)aBrowser columnForNodeFiltersCount:(IndexNode*)selectedNode atColumnIndex:(unsigned)anIndex
{
	if ( selectedNode == nil)
		return YES;
	
	id representedObject = [selectedNode representedObject];
	
	if ( [representedObject isKindOfClass:[NSString class]] )
		return NO;
	else if ( [representedObject isKindOfClass:[JournlerObject class]] )
		return YES;
	else
		return NO;
}

- (BOOL) browser:(IndexBrowser*)aBrowser columnForNodeFiltersTitle:(IndexNode*)selectedNode atColumnIndex:(unsigned)anIndex
{
	return YES;
}

#pragma mark -

- (float) browser:(IndexBrowser*)aBrowser rowHeightForNode:(IndexNode*)selectedNode atColumnIndex:(unsigned)anIndex
{	
	if ( selectedNode == nil )
		return kIndexColumnSmallRowHeight;
	
	id representedObject = [selectedNode representedObject];
	
	if ( [representedObject isKindOfClass:[NSString class]] )
		return kIndexColumnLargeRowHeight;
	
	else if ( [representedObject isKindOfClass:[JournlerObject class]] )
		return kIndexColumnSmallRowHeight;
	
	// go with the big one to be safe
	else return kIndexColumnLargeRowHeight;
}

- (NSMenu*) browser:(IndexBrowser*)aBrowser contextMenuForNode:(IndexNode*)selectedNode atColumnIndex:(unsigned)anIndex
{
	if ( selectedNode == nil )
		return nil;
	
	id representedObject = [selectedNode representedObject];
	
	if ( [representedObject isKindOfClass:[NSString class]] )
		return documentContextMenu;
	
	else if ( [representedObject isKindOfClass:[JournlerObject class]] )
		return termContextMenu;
	
	else return nil;
}

#pragma mark -

- (BOOL) indexColumn:(IndexColumn*)aColumn deleteSelectedRows:(NSIndexSet*)selectedRows nodes:(NSArray*)theNodes
{
	// enumerator through the nodes, grab represented objects, add to stop list, return yes
	
	#ifdef __DEBUG__
	NSLog([selectedRows description]);
	#endif
	
	if ( ![aColumn canDeleteContent] )
		return NO;
	
	IndexNode *aNode;
	NSEnumerator *enumerator = [theNodes objectEnumerator];
	NSMutableSet *stopWords = [NSMutableSet setWithCapacity:[selectedRows count]];
	
	while ( aNode = [enumerator nextObject] )
	{
		id anObject = [aNode representedObject];
		if ( ![anObject isKindOfClass:[NSString class]] )
			continue;
		
		[stopWords addObject:[(NSString*)anObject lowercaseString]];
	}
	
	#ifdef __DEBUG__
	NSLog([stopWords description]);
	#endif
	
	NSSet *currentStopWords = [self valueForKeyPath:@"journal.searchManager.stopWords"];
	[stopWords unionSet:currentStopWords];
	
	#ifdef __DEBUG__
	NSLog([stopWords description]);
	#endif
	
	[self setValue:stopWords forKeyPath:@"journal.searchManager.stopWords"];
	[[NSUserDefaults standardUserDefaults] setObject:[[stopWords allObjects] componentsJoinedByString:@" "] forKey:@"SearchStopWords"];
	
	return YES;
}

/*

- (BOOL) browser:(IndexBrowser*)aBrowser columnForRepresentedObjectDrawsIcon:(id)anObject atColumnIndex:(unsigned)anIndex
{
	// the represented object is the selection whose contents are going to be displayed
	if ( [anObject isKindOfClass:[NSString class]] )
		return YES;
	else
		return NO;
}

- (BOOL) browser:(IndexBrowser*)aBrowser columnForRepresentedObjectShowsCount:(id)anObject atColumnIndex:(unsigned)anIndex
{
	// the represented object is the selection whose contents are going to be displayed
	if ( [anObject isKindOfClass:[NSString class]] )
		return NO;
	else
		return YES;
}

- (BOOL) browser:(IndexBrowser*)aBrowser columnForRepresentedObjectShowsFrequency:(id)anObject atColumnIndex:(unsigned)anIndex
{
	// the represented object is the selection whose contents are going to be displayed
	if ( anObject == nil )
		return NO;
	else if ( [anObject isKindOfClass:[NSString class]] )
		return NO;
	else
		return YES;
}

#pragma mark -

- (NSString*) browser:(IndexBrowser*)aBrowser titleForSelection:(id)anObject atColumnIndex:(unsigned)anIndex
{
	// the represented object is the selection whose contents are going to be displayed
	if ( anObject == nil ) // first column
		return nil;
	else if ( [anObject isKindOfClass:[NSString class]] )
		return anObject;
	else if ( [anObject isKindOfClass:[JournlerObject class]] )
		return [anObject valueForKey:@"title"];
	else
		return nil;
}

- (NSString*) browser:(IndexBrowser*)aBrowser countSuffixForSelection:(id)anObject atColumnIndex:(unsigned)anIndex
{
	// the represented object is the selection whose contents are going to be displayed
	if ( anObject == nil ) // first column
		return NSLocalizedString(@"terms label",@"");
	else if ( [anObject isKindOfClass:[NSString class]] )
		return NSLocalizedString(@"documents label",@"");
	else if ( [anObject isKindOfClass:[JournlerObject class]] )
		return NSLocalizedString(@"terms label",@"");
	else
		return nil;
}

- (NSArray*) browser:(IndexBrowser*)aBrowser sortDescriptorsForSelection:(id)anObject atColumnIndex:(unsigned)anIndex
{
	if ( anIndex == nil ) // use the saved sort descriptors
		return nil;
	
	// otherwise allow the browser to determine the sort
	else return nil;
}

*/

#pragma mark -
#pragma mark Drag and Drop Support

- (BOOL)outlineView:(NSOutlineView *)anOutlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard 
{
	BOOL wroteAnItem = NO;
	BOOL dealingWithStrings = NO;
	
	id aNode;
	NSEnumerator *enumerator = [items objectEnumerator];
	
	NSMutableArray *URIs = [NSMutableArray array];
	NSMutableArray *titles = [NSMutableArray array];
	NSMutableArray *promises = [NSMutableArray array];
	
	while ( aNode = [enumerator nextObject] )
	{
		if ( ![aNode respondsToSelector:@selector(representedObject)] )
			continue;
			
		id anItem = [aNode representedObject];
		
		if ( [anItem isKindOfClass:[JournlerEntry class]] )
		{
			// write an entry to the pasteboard
			wroteAnItem = YES;
			
			[URIs addObject:[[(JournlerEntry*)anItem URIRepresentation] absoluteString]];
			[titles addObject:[(JournlerEntry*)anItem valueForKey:@"title"]];
			[promises addObject:(NSString*)kUTTypeFolder];
		}
		
		else if ( [anItem isKindOfClass:[JournlerResource class]] )
		{
			// write a resource to the pasteboard
			wroteAnItem = YES;
			
			[URIs addObject:[[(JournlerResource*)anItem URIRepresentation] absoluteString]];
			[titles addObject:[(JournlerResource*)anItem valueForKey:@"title"]];
			[promises addObject:[(JournlerResource*)anItem valueForKey:@"uti"]];
		}
		
		else if ( [anItem isKindOfClass:[NSString class]] )
		{
			wroteAnItem = YES;
			dealingWithStrings = YES;
			[titles addObject:anItem];
		}
	}
	
	if ( dealingWithStrings )
	{
		[pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
		[pboard setString:[titles componentsJoinedByString:@" "] forType:NSStringPboardType];
	}
	else
	{
		NSArray *pboardTypes;
		
		// prepare the web urls
		NSArray *web_urls_array = [NSArray arrayWithObjects:URIs,titles,nil];
		
		// prepare the favorites data
		NSDictionary *favoritesDictionary = nil;
		if ( [[items objectAtIndex:0] isKindOfClass:[JournlerObject class]] )
		{
			favoritesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
					[(JournlerObject*)[items objectAtIndex:0] valueForKey:@"title"], PDFavoriteName, 
					[[(JournlerObject*)[items objectAtIndex:0] URIRepresentation] absoluteString], PDFavoriteID, nil];
			
			// declare the types
			pboardTypes = [NSArray arrayWithObjects: PDEntryIDPboardType, NSFilesPromisePboardType, 
					PDFavoritePboardType, WebURLsWithTitlesPboardType, NSURLPboardType, NSStringPboardType, nil];
		}
		else if ( wroteAnItem )
		{
			// declare the types
			pboardTypes = [NSArray arrayWithObjects: PDEntryIDPboardType, NSFilesPromisePboardType, 
					WebURLsWithTitlesPboardType, NSURLPboardType, NSStringPboardType, nil];
		}
		
		if ( wroteAnItem )
		{
		
			[pboard declareTypes:pboardTypes owner:self];
			
			[pboard setPropertyList:URIs forType:PDEntryIDPboardType];
			[pboard setPropertyList:promises forType:NSFilesPromisePboardType];
			
			if ( [[items objectAtIndex:0] isKindOfClass:[JournlerObject class]] )
				[pboard setPropertyList:favoritesDictionary forType:PDFavoritePboardType];
			
			[pboard setPropertyList:web_urls_array forType:WebURLsWithTitlesPboardType];
		
		}
		
		// write the url for the first item to the pasteboard, as a url and as a string
		if ( [[items objectAtIndex:0] isKindOfClass:[JournlerObject class]] )
		{
			[[[items objectAtIndex:0] URIRepresentation] writeToPasteboard:pboard];
			[pboard setString:[[items objectAtIndex:0] URIRepresentationAsString] forType:NSStringPboardType];
		}
	}
	
	return wroteAnItem;
}

- (NSArray *)outlineView:(NSOutlineView *)anOutlineView 
		namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedItems:(NSArray *)items
{
	
	if ( ![dropDestination isFileURL] ) 
		return nil;
	
	NSMutableArray *titles = [NSMutableArray array];
	NSString *destinationPath = [dropDestination path];
	
	id anItem;
	JournlerObject *anObject;
	NSEnumerator *enumerator = [items objectEnumerator];
	
	int flags = kEntrySetLabelColor;
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryExportIncludeHeader"] )
		flags |= kEntryIncludeHeader;
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryExportSetCreationDate"] )
		flags |= kEntrySetFileCreationDate;
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryExportSetModificationDate"] )
		flags |= kEntrySetFileModificationDate;
	
	while ( anItem = [enumerator nextObject] )
	{
		if ( [anItem isKindOfClass:[JournlerObject class]] )
			anObject = anItem;
		else if ( [anItem isKindOfClass:[IndexNode class]] )
		{
			anObject = [anItem representedObject];
			if ( ![anObject isKindOfClass:[JournlerObject class]] )
				continue;
		}
		else
			continue;
		
		if ( [anObject isKindOfClass:[JournlerEntry class]] )
		{
			//NSString *filePath = [NSString stringWithFormat:@"%@ %@", [(JournlerEntry*)anObject tagID], [(JournlerEntry*)anObject pathSafeTitle]];
			//[(JournlerEntry*)anObject writeToFile:[destinationPath stringByAppendingPathComponent:filePath] as:kEntrySaveAsRTFD flags:flags];
			NSString *completePath = [[destinationPath stringByAppendingPathComponent:[(JournlerEntry*)anObject pathSafeTitle]] pathWithoutOverwritingSelf];
			[(JournlerEntry*)anObject writeToFile:completePath as:kEntrySaveAsRTFD flags:flags];
			[titles addObject:completePath];
		}
		else if ( [anObject isKindOfClass:[JournlerResource class]] )
		{
			[(JournlerResource*)anObject createFileAtDestination:destinationPath];
			[titles addObject:[(JournlerResource*)anObject valueForKey:@"title"]];
		}
	}
	
	return [NSArray array];
}

@end
