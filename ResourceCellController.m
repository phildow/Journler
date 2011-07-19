//
//  ResourceCellController.m
//  Journler
//
//  Created by Philip Dow on 10/28/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import "ResourceCellController.h"
#import "Definitions.h"

#import "JournlerResource.h"
#import "JournlerJournal.h"
#import "JournlerEntry.h"

#import "TabController.h"

#import <Quartz/Quartz.h>
#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>

#import "JournlerMediaViewer.h"
#import "JournlerMediaContentController.h"

#import "AddressRecordController.h"
#import "AudioViewController.h"
#import "ImageViewController.h"
#import "MovieViewController.h"
#import "PDPDFViewController.h"
#import "WebViewController.h"
#import "MailMessageController.h"
#import "WordDocumentController.h"
#import "TextDocumentController.h"
#import "GenericMediaController.h"
#import "JournlerResourceMediaController.h"


#import "ResourceInfoController.h"
#import "ResourceInfoView.h"

#import "JournlerLicenseManager.h"
#import "MissingFileController.h"

@implementation ResourceCellController

- (id) init 
{
	if ( self = [super init] ) 
	{
		[NSBundle loadNibNamed:@"ResourceCell" owner:self];
	}
	return self;
}

- (void) awakeFromNib 
{
	activeContentView = contentPlaceholder;
	[self setActiveContentView:defaultContent];
	
	static NSInteger borders[4] = {0,0,0,0};
	[contentView setBorderColor:[NSColor blackColor]];
	[contentView setBorders:borders];
	
	static NSInteger gBorders[4] = {1,0,0,0};
	[defaultGradient setBordered:YES];
	[defaultGradient setBorders:gBorders];
	
	[photoView setPhotoSize:96];
	[photoView setUseOutlineBorder:NO];
	[photoView setUseBorderSelection:YES];
	[photoView setUseShadowBorder:NO];
	[photoView setUseShadowSelection:NO];
	
	//[photoView setPermitsSelection:YES];
	[photoView setUseHighQualityResize:YES];
	[photoView setHoverCursor:[NSCursor pointingHandCursor]];
	[photoView setBackgroundColor:[NSColor whiteColor]];
	//[[photoView enclosingScrollView] setBackgroundColor:[NSColor whiteColor]];
	
	[photoView bind:@"photoSize" toObject:[NSUserDefaultsController sharedUserDefaultsController] 
			withKeyPath:@"values.PhotoViewPhotoSize" options:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithBool:YES], NSContinuouslyUpdatesValueBindingOption,
			[NSNumber numberWithFloat:80], NSNullPlaceholderBindingOption, 
			[NSNumber numberWithFloat:80], NSNotApplicablePlaceholderBindingOption, nil]];
	
	// the media bar -- no need to set these up until they are called for (should be separate resource cells)
	//[self setupMediabar:defaultContentMediabar url:nil];
	//[self setupMediabar:photoContainerMediabar url:nil];
	
	NSInteger whichBorders[4] = {1,0,1,0};
	[defaultContentMediabar setBordered:YES];
	[defaultContentMediabar setBorderColor:[NSColor colorWithCalibratedRed:155.0/255.0 green:155.0/255.0 blue:155.0/255.0 alpha:1.0]];
	[defaultContentMediabar setBorders:whichBorders];
	
	[photoContainerMediabar setBordered:YES];
	[photoContainerMediabar setBorderColor:[NSColor colorWithCalibratedRed:155.0/255.0 green:155.0/255.0 blue:155.0/255.0 alpha:1.0]];
	[photoContainerMediabar setBorders:whichBorders];
}

- (void) dealloc
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	[fileErrorController release];
	[mediaController release];
	[selectedResources release];
	[selectedResource release];
	
	// release top level nib objects
	[contentView release];
	[defaultContent release];
	[photoContainer release];
	[photoMenu release];
	
	[super dealloc];
}

#pragma mark -

- (NSView*) contentView 
{
	return contentView;
}

- (id) delegate
{
	return delegate;
}

- (void) setDelegate:(id)anObject
{
	delegate = anObject;
}

- (NSView*) activeContentView 
{
	return activeContentView;
}

- (void) setActiveContentView:(NSView*)aView 
{	
	if ( activeContentView != aView ) 
	{
		// keep the old view - somebody else will release it
		[activeContentView retain];
		
		[aView setFrame:[activeContentView frame]];
		[[activeContentView superview] replaceSubview:activeContentView with:aView];
		
		activeContentView = aView;
	}
}

- (MediaContentController*) mediaController 
{
	return mediaController;
}

- (void) setMediaController:(MediaContentController*)aController 
{
	// ACTIVE CONTENT VIEW MUST BE SET BEFORE THE MEDIA CONTROLLER IS
	
	if ( mediaController != aController ) 
	{
		[mediaController ownerWillClose:nil];
		[mediaController release];
		mediaController = [aController retain];
		
		// check to see if the find menu must be updated
		//[self checkCustomFindPanelAction];
		[self checkCustomTextSizeAction];
	}
}

- (NSURL*) mediaURL
{
	return mediaURL;
}

- (void) setMediaURL:(NSURL*)aURL
{
	if ( mediaURL != aURL )
	{
		[mediaURL release];
		mediaURL = [aURL copyWithZone:[self zone]];
	}
}

#pragma mark -

- (JournlerResource*) selectedResource 
{
	return selectedResource;
}

- (void) setSelectedResource:(JournlerResource*)aResource 
{
	if ( selectedResource != aResource ) 
	{
		[selectedResource release];
		selectedResource = [aResource retain];
		
		// call another method which determines how to display this resource
		[self loadMediaViewerForResource:selectedResource];
	}
}

- (NSArray*) selectedResources 
{
	return selectedResources;
}

- (void) setSelectedResources:(NSArray*)anArray 
{
	if ( selectedResources != anArray ) 
	{
		[selectedResources release];
		selectedResources = [anArray copyWithZone:[self zone]];
		
		if ( selectedResources == nil || [selectedResources count] == 0 )
			[self setSelectedResource:nil];
			
		else if ( [selectedResources count] == 1 )
			[self setSelectedResource:[selectedResources objectAtIndex:0]];
			
		else 
		{
			[self setSelectedResource:nil];
			if ( [selectedResources count] > 1 )
				[self showInfoForMultipleResources:anArray];
		}
		
		if ( [photoContainer superview] != nil )
			[photoView setPhotosArray:[selectedResources valueForKey:@"icon"]];;
	}
}

#pragma mark -

- (BOOL) openURL:(NSURL*)aURL
{
	Class controllerClass = nil;
	controllerClass = [WebViewController class];
	
	MediaContentController *aController = [[[controllerClass alloc] init] autorelease];
	NSView *localContentView = [aController contentView];
		
	[aController setDelegate:self];
	[aController setRepresentedObject:nil];
		
	[self setActiveContentView:localContentView];
	[self setMediaController:aController];
		
	if ( aURL == nil )
		[aController appropriateAlternateResponder:[[self contentView] window]];
	else
		[self appropriateFirstResponder:[[self contentView] window]];
	
	if ( aURL != nil ) [aController loadURL:aURL];
	
	return YES;
}

- (NSURL*) webBrowsedURL
{
	if ( [[self mediaController] isKindOfClass:[WebViewController class]] )
		return [(WebViewController*)[self mediaController] webBrowsedURL];
	else
		return nil;
}

- (BOOL) isWebBrowsing
{
	return ( [self webBrowsedURL] != nil );
}

- (NSString*) documentTitle
{
	if ( [self isWebBrowsing] )
		return [(WebViewController*)[self mediaController] browserTitle];
	else
		return nil;
}

- (void) showInfoForMultipleResources:(NSArray*)anArray
{
	NSURL *aURL = nil;
	JournlerResource *aResource = nil;
	if ( [anArray count] > 0 && ( aResource = [anArray objectAtIndex:0] ) && [aResource representsFile] )
	if ( aResource != nil && [aResource representsFile] )
	{
		NSString *aPath = [aResource originalPath];
		if ( aPath != nil ) aURL = [NSURL fileURLWithPath:aPath];
	}
	
	[self setMediaURL:aURL];
	[self setActiveContentView:photoContainer];
	[self setupMediabar:photoContainerMediabar url:[self mediaURL]];

}

- (void) loadMediaViewerForResource:(JournlerResource*)aResource
{
	//
	// based on the resource uti, determine the plugin used to display the resource
	
	if ( aResource == nil ) 
	{
		// clear out the views and get out of here
		[self setActiveContentView:defaultContent];
		[self setMediaController:nil];
		return;
	}
	
	Class controllerClass = nil;
	
	if ( [aResource representsURL] )
		controllerClass = [WebViewController class];
		
	else if ( [aResource representsABRecord] )
		controllerClass = [AddressRecordController class];
	
	else if ( [aResource representsJournlerObject] )
		controllerClass = [JournlerResourceMediaController class];
	
	else if ( [aResource representsFile] )
	{
		// determine the controller according to UTI
		NSString *uti = [aResource valueForKey:@"uti"];
		
		if ( UTTypeConformsTo( (CFStringRef)uti, kUTTypePDF ) )
			controllerClass = [PDPDFViewController class];
		
		else if ( UTTypeConformsTo( (CFStringRef)uti, kUTTypeAudio ) )
			controllerClass = [AudioViewController class];
			
		else if ( UTTypeConformsTo( (CFStringRef)uti, (CFStringRef)@"public.movie" ) )
			controllerClass = [MovieViewController class];
		
		else if ( UTTypeConformsTo( (CFStringRef)uti, kUTTypeImage ) )
			controllerClass = [ImageViewController class];
		
		else if ( UTTypeConformsTo( (CFStringRef)uti, kUTTypeWebArchive ) || UTTypeConformsTo( (CFStringRef)uti, kUTTypeHTML) )
			controllerClass = [WebViewController class];
		
		else if ( UTTypeConformsTo( (CFStringRef)uti,(CFStringRef)ResourceMailUTI) )
			controllerClass = [MailMessageController class];
		
		else if ( UTTypeConformsTo( (CFStringRef)uti,(CFStringRef)ResourceMailStandardEmailUTI) )
			controllerClass = [MailMessageController class];
		
		else if ( UTTypeConformsTo( (CFStringRef)uti, (CFStringRef)@"com.microsoft.word.doc") )
			controllerClass = [WordDocumentController class];
		
		else if ( UTTypeConformsTo( (CFStringRef)uti, kUTTypeRTF ) || UTTypeConformsTo( (CFStringRef)uti, kUTTypeRTFD ) || UTTypeConformsTo( (CFStringRef)uti, kUTTypePlainText ) )
			controllerClass = [TextDocumentController class];
		
		else if ( uti != nil )
		{
			// check the mime type
			NSString *mime_type = (NSString*)UTTypeCopyPreferredTagWithClass((CFStringRef)uti,kUTTagClassMIMEType);
			if ( mime_type != nil && [WebView canShowMIMEType:mime_type] )
				controllerClass = [WebViewController class];
			else //2.5.3 change - unknown files gte the generic controller
				controllerClass = [GenericMediaController class];
			
		}
		
		else //2.5.3 change - unknown files gte the generic controller
			controllerClass = [GenericMediaController class];
	}
	
	
	if ( controllerClass != nil ) 
	{
				
		MediaContentController *aController = [[[controllerClass alloc] init] autorelease];
		NSView *localContentView = [aController contentView];
		
		[aController setDelegate:self];
		[aController setRepresentedObject:aResource];
		
		[self setActiveContentView:localContentView];
		[self setMediaController:aController];
		
		// determine if the generic view uses quicklook
		if ( [aController isKindOfClass:[GenericMediaController class]] )
		{
			NSInteger licenseType = [[JournlerLicenseManager sharedManager] licenseType];
			BOOL usesQLDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"QuickLookPreviewsDisabled"];
			BOOL usesQL = ( ( licenseType == kJournlerLicenseNonPersonal || licenseType == kJournlerLicenseSpecial || licenseType == kJournlerLicenseFull) && !usesQLDisabled );
			[(GenericMediaController*)aController setUsesQuickLook:usesQL];
		}
		
		if ( [aResource representsURL] )
			[aController loadURL:[NSURL URLWithString:[aResource valueForKey:@"urlString"]]];
		else if ( [aResource representsABRecord] )
			[aController loadURL:[NSURL URLWithString:[aResource valueForKey:@"uniqueId"]]];
		else if ( [aResource representsJournlerObject] )
			[aController loadURL:[aResource URIRepresentation]];
		else if ( [aResource representsFile] )
		{
			if ( [aResource originalPath] != nil )
				[aController loadURL:[NSURL fileURLWithPath:[aResource originalPath]]];
			else
			{
				// let the user know the file could not be found
				
				// reset the resource icon to include a caution badge or question mark
				[aResource addMissingFileBadge];

				// prepare the error view
				if ( fileErrorController == nil )
					fileErrorController = [[MissingFileController alloc] initWithResource:aResource];
				else
					[fileErrorController setResource:aResource];
				
				// show the error view
				[fileErrorController setDelegate:self];
				[self setActiveContentView:[fileErrorController contentView]];
				
				NSBeep();
				NSLog(@"%s - no resource at original path for path %@", __PRETTY_FUNCTION__, [aResource path]);
			}
		}	
	}
	
	else 
	{
		// if no suitable plugin has been found, go the default route
		//[self showInfoForResource:aResource];
		NSLog(@"%s - wants to call showInfoForResource -- definitely shouldn't be here", __PRETTY_FUNCTION__);
	}
}

- (void) appropriateFirstResponder:(NSWindow*)aWindow
{
	[[self mediaController] appropriateFirstResponder:aWindow];
}

- (void) establishKeyViews:(NSView*)previous nextKeyView:(NSView*)next
{

}

- (BOOL) highlightString:(NSString*)aString
{	
	if ( [[self mediaController] respondsToSelector:@selector(highlightString:)] )
	{
		[[self mediaController] performSelector:@selector(highlightString:) withObject:aString];
		return YES;
	}
	else
	{
		return NO;
	}
}


#pragma mark -

- (void) ownerWillClose
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	[photoView unbind:@"photoSize"];
	[photoView ownerWillClose:nil];
	[[self mediaController] ownerWillClose:nil];
}

- (void) stopContent
{
	[[self mediaController] stopContent];
}

- (IBAction) exportResource:(id)sender
{
	// pass to active media controller unless displaying entry info, which we must export self as webarchive
	if ( [self mediaController] != nil )
		[[self mediaController] exportSelection:sender];
	else
	{
		// export a webarchive of the default view
		WebArchive *theArchive = [[[defaultWebView mainFrame] dataSource] webArchive];
		
		if ( theArchive == nil )
		{
			NSBeep();
			NSLog(@"%s - unable to get archive for default web view", __PRETTY_FUNCTION__);
			return;
		}
		
		NSData *archiveData = [theArchive data];
		if ( archiveData == nil )
		{
			NSBeep();
			NSLog(@"%s - unable to get archive data for default web view", __PRETTY_FUNCTION__);
			return;
		}
		
		NSString *pageTitle = [[[defaultWebView mainFrame] dataSource] pageTitle];
		
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
}
	
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[[alert window] orderOut:self];
}

- (IBAction) printDocument:(id)sender
{
	if ( [self mediaController] != nil && [self activeContentView] == [[self mediaController] contentView] )
	{
		if ( [[self mediaController] respondsToSelector:@selector(printDocument:)] )
			[[self mediaController] performSelector:@selector(printDocument:) withObject:sender];
		else
		{
			NSBeep();
		}
	}
	else if ( [self activeContentView] == photoContainer && [[self selectedResources] count] > 1 )
	{
		[self printMultipleSelection:sender];
	}	
	else
	{
		NSBeep();
		NSLog(@"%s - nothing selected that Journler knows how to print", __PRETTY_FUNCTION__);
	}
}

- (BOOL) trumpsPrint
{
	return ( [self webBrowsedURL] != nil );
}

- (IBAction) printFileViewerContent:(id)sender {
	
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
	
	[[NSPrintOperation printOperationWithView:[[[defaultWebView mainFrame] frameView] documentView] printInfo:modifiedInfo] runOperation];
	
	//[NSPrintInfo setSharedPrintInfo:modifiedInfo];
	//[[[[defaultWebView mainFrame] frameView] documentView] print:sender];
	//[NSPrintInfo setSharedPrintInfo:currentInfo];
	
	//[modifiedInfo release];
}

- (IBAction) printMultipleSelection:(id)sender
{
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
	
	[[NSPrintOperation printOperationWithView:photoView printInfo:modifiedInfo] runOperation];
	
	//[NSPrintInfo setSharedPrintInfo:modifiedInfo];
	//[photoView print:sender];
	//[NSPrintInfo setSharedPrintInfo:currentInfo];
	
	//[modifiedInfo release];
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	BOOL enabled = YES;
	SEL action = [menuItem action];
	
	if ( action == @selector(performCustomFindPanelAction:) )
		enabled = ( [mediaController handlesFindCommand] && [mediaController validateMenuItem:menuItem] );
	
	else if ( action == @selector(performCustomTextSizeAction:) )
		enabled = ( [mediaController handlesTextSizeCommand] && [mediaController validateMenuItem:menuItem] );
	
	else if ( action == @selector(jumpToEntryFromPhotoView:) || action == @selector(openInFinderFromPhotoView:)
		|| action == @selector(revealInFinderFromPhotoView:) || action == @selector(openInNewTabFromPhotoView:)
		|| action == @selector(openInNewWindowFromPhotoView:) )
	{
		NSUInteger theIndex = [photoView indexForMenuEvent];
		if ( theIndex >= [[self selectedResources] count] )
			enabled = NO;
		else
			enabled = YES;
	}
	
	return enabled;
}

#pragma mark -
#pragma mark Media Content Controller Delegation

- (void) contentController:(MediaContentController*)aController changedTitle:(NSString*)title
{
	if ( [[self delegate] respondsToSelector:@selector(resourceCellController:didChangeTitle:)] )
		[[self delegate] resourceCellController:self didChangeTitle:title];
}

- (void) contentController:(JournlerMediaContentController*)aController didLoadURL:(NSURL*)aURL
{
	//NSLog(@"%s",__PRETTY_FUNCTION__);
	
	
	Class pd_pdf_view_controller_class = NSClassFromString(@"PDPDFViewController");
	
	if ( pd_pdf_view_controller_class != nil && [aController isKindOfClass:pd_pdf_view_controller_class] )
	{
		// special case for pdf documents
		// take the opportunity to generate a new preview icon for the resource
		//NSLog(@"%s - we have a pdf document",__PRETTY_FUNCTION__);
		
		PDFDocument *pdfDoc = [(PDPDFViewController*)aController pdfDocument];
		if ( pdfDoc != nil && [pdfDoc pageCount] != 0 )
		{
			NSImage *pdfThumbnail = [pdfDoc efficientThumbnailForPage:0 size:128];
			if ( ![[[self selectedResource] path] isEqualToString:[[self selectedResource] originalPath]] )
			{
				[pdfThumbnail lockFocus];
				NSImage *aliasBadge = [JournlerResource iconBadgeForType:kJournlerResourceAliasBadge];
				[aliasBadge drawInRect:NSMakeRect(0,0,128,128) 
					fromRect:NSMakeRect(0,0,[aliasBadge size].width, [aliasBadge size].height) 
					operation:NSCompositeSourceOver fraction:1.0];
				[pdfThumbnail unlockFocus];
			}
		
			// update the icon
			[[self selectedResource] setIcon:pdfThumbnail];
			
			// and don't forget to write it to file
			[[self selectedResource] cacheIconToDisk];
			
			// and have the resource cell's owner perform any necessary ui updating
			if ( [[self delegate] respondsToSelector:@selector(resourceCellController:didChangePreviewIcon:forResource:)] )
				[[self delegate] resourceCellController:self didChangePreviewIcon:pdfThumbnail forResource:[self selectedResource]];
		}
	}
}

#pragma mark -
#pragma mark PhotoView Delegation

- (NSString*) photoView:(MUPhotoView*)photoView titleForObjectAtIndex:(NSUInteger)index
{
	if ( index >= [[self selectedResources] count] )
		return nil;
	
	return [[[self selectedResources] objectAtIndex:index] valueForKey:@"title"];
}

- (NSString*) photoView:(MUPhotoView*)photoView tooltipForObjectAtIndex:(NSUInteger)index
{
	if ( index >= [[self selectedResources] count] )
		return nil;
	
	NSString *tooltip = nil;
	JournlerResource *theResource = [[self selectedResources] objectAtIndex:index];
	
	if ( [theResource representsJournlerObject] )
	{
		id journlerObject = [theResource journlerObject];
		
		if ( journlerObject == nil )
			tooltip = @"?";
		else if ( [journlerObject isKindOfClass:[JournlerEntry class]] )
		{
			NSString *plainContent = [journlerObject content];
		
			if ( plainContent == nil )
				tooltip =  [journlerObject valueForKey:@"title"];
			else
			{
				SKSummaryRef summaryRef = SKSummaryCreateWithString((CFStringRef)plainContent);
				
				if ( summaryRef == NULL )
					tooltip = [journlerObject valueForKey:@"title"];
				else
				
				tooltip = [(NSString*)SKSummaryCopySentenceSummaryString(summaryRef,1) autorelease];
				if ( tooltip == nil )
					tooltip = [journlerObject valueForKey:@"title"];
			}
		}
		else
			tooltip = [journlerObject valueForKey:@"title"];
	}
	else if ( [theResource representsFile] )
	{
		NSString *title = [theResource valueForKey:@"title"];
		if ( title == nil )
			title = NSLocalizedString(@"untitled title",@"");
		
		NSString *path = [theResource originalPath];
		if ( path == nil )
			path = NSLocalizedString(@"resource tooltip bad alias",@"");
			//path = [theResource path];
		if ( path == nil )
			path = NSLocalizedString(@"resource tooltip no file",@"");
		
		tooltip = [NSString stringWithFormat:@"%@\n%@",title,path];
	}
	else
	{
		tooltip = [theResource valueForKey:@"title"];
	}
	
	return tooltip;
	
}

- (void)photoView:(MUPhotoView *)view doubleClickOnPhotoAtIndex:(NSUInteger)index withFrame:(NSRect)frame
{
	// do something *cool* here
	NSLog(@"%s",__PRETTY_FUNCTION__);
	
	if ( index >= [[self selectedResources] count] )
		return;
}

- (NSIndexSet *)photoView:(MUPhotoView *)view willSetSelectionIndexes:(NSIndexSet *)indexes
{
	// do something *cool* here
	NSInteger firstIndex = [indexes firstIndex];
	if ( firstIndex < 0 || firstIndex >= [[self selectedResources] count] )
		return indexes;
	
	if ( [[self delegate] respondsToSelector:@selector(selectResources:)] )
		[[self delegate] performSelector:@selector(selectResources:) withObject:[[self selectedResources] objectsAtIndexes:indexes]];
	else
	{
	
		ResourceInfoController *infoController = [[[ResourceInfoController alloc] init] autorelease];
		
		NSRect photoRect = [photoView photoRectForIndex:firstIndex];
		NSPoint photoInViewOrigin = photoRect.origin;
		NSPoint photoInWindowOrigin = [photoView convertPoint:photoInViewOrigin toView:nil];
		NSPoint photoInScreenOrigin = [[[self contentView] window] convertBaseToScreen:photoInWindowOrigin];
		
		photoInScreenOrigin.x -= 11;
		photoInScreenOrigin.y += 30;
		
		ResourceInfoAlignment alignment = ResourceInfoAlignLeft;
		
		NSRect screenFrame = [[NSScreen mainScreen] visibleFrame];
		if ( photoInScreenOrigin.x + [[infoController window] frame].size.width > ( screenFrame.origin.x + screenFrame.size.width ) )
		{
			photoInScreenOrigin.x = photoInScreenOrigin.x - [[infoController window] frame].size.width + photoRect.size.width + [photoView photoHorizontalSpacing];
			alignment = ResourceInfoAlignRight;
		}
		
		[infoController setViewAlignment:alignment];
		[infoController setResource:[[self selectedResources] objectAtIndex:firstIndex]];
		
		[[infoController window] setFrameTopLeftPoint:photoInScreenOrigin];
		[[infoController window] makeKeyAndOrderFront:self];
	
	}
	
	return indexes;
}

#pragma mark -
#pragma mark AddressRecordController delegation

- (void) addressRecordController:(AddressRecordController*)anAddressRecordController displayURL:(NSURL*)aURL
{
	// note that the selected resource does not change
	WebViewController *webController = [[[WebViewController alloc] init] autorelease];
	NSView *localContentView = [webController contentView];
		
	[webController setDelegate:self];
	[self setActiveContentView:localContentView];
	[self setMediaController:webController];
	
	[webController loadURL:aURL];
}

#pragma mark -
#pragma mark WebViewController delegation

- (void) webViewController:(WebViewController*)aController appendPasteboardLink:(NSPasteboard*)pboard
{
	if ( [delegate respondsToSelector:@selector(webViewController:appendPasteboardLink:)] )
		[delegate webViewController:aController appendPasteboardLink:pboard];
}

- (void) webViewController:(WebViewController*)aController appendPasteboardContents:(NSPasteboard*)pboard
{
	if ( [delegate respondsToSelector:@selector(webViewController:appendPasteboardContents:)] )
		[delegate webViewController:aController appendPasteboardContents:pboard];
}

- (void) webViewController:(WebViewController*)aController appendPasetboardWebArchive:(NSPasteboard*)pboard
{
	if ( [delegate respondsToSelector:@selector(webViewController:appendPasetboardWebArchive:)] )
		[delegate webViewController:aController appendPasetboardWebArchive:pboard];
}


//- (void) contentController:(MediaContentController*)aController showLexiconSelection:(id)anObject term:(NSString*)aTerm
- (void) contentController:(JournlerMediaContentController*)aController showLexiconSelection:(id)anObject term:(NSString*)aTerm
{
	#ifdef __DEBUG__
	NSLog(aTerm);
	#endif
	
	if ( ![anObject isKindOfClass:[JournlerObject class]] 
		|| ![[self delegate] respondsToSelector:@selector(contentController:showLexiconSelection:term:)] )
	{
		NSBeep(); return;
	}
	
	[[self delegate] contentController:aController showLexiconSelection:anObject term:aTerm];
}

#pragma mark -
#pragma mark Default WebView Delegation

- (WebView *)webView:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request 
{	
	NSURL *aURL = [request URL];
	
	if ( ![aURL isFileURL] )
	{
		NSBeep(); return nil;
	}
	
	NSString *path = [aURL path];
	if ( ![[NSFileManager defaultManager] fileExistsAtPath:path] )
	{
		NSBeep(); return nil;
	}
	
	NSString *uti = [[NSWorkspace sharedWorkspace] UTIForFile:[[NSWorkspace sharedWorkspace] resolveForAliases:path]];
	if ( uti == nil ) 
	{
		NSLog(@"%s - unable to determine uti file at path %@, launching with Finder", __PRETTY_FUNCTION__, path);
		[[NSWorkspace sharedWorkspace] openFile:path];
		return nil;
	}
	
	if ( ![JournlerMediaViewer canDisplayMediaOfType:uti url:aURL] )
	{
		NSLog(@"%s - cannot view file with Journler at url %@", __PRETTY_FUNCTION__, aURL);
		[[NSWorkspace sharedWorkspace] openFile:path];
		return nil;
	}
	
	// if we made it this far, open the file up with journler
	JournlerMediaViewer *mediaViewer = [[[JournlerMediaViewer alloc] initWithURL:aURL uti:uti] autorelease];
	if ( mediaViewer == nil )
	{
		NSLog(@"%s - problem allocating media viewer for url %@", __PRETTY_FUNCTION__, aURL);
		[[NSWorkspace sharedWorkspace] openFile:path];
		return nil;
	}
	
	[mediaViewer showWindow:self];
	
	return nil;
}

- (void)webView:(WebView *)sender mouseDidMoveOverElement:(NSDictionary *)element modifierFlags:(NSUInteger)modifierFlags
{
	NSURL *targetLink = [element objectForKey:WebElementLinkURLKey];
	
	if ( targetLink != nil && [targetLink isFileURL] )
		[defaultStatus setStringValue:[targetLink path]];
	else
		[defaultStatus setStringValue:[NSString string]];
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems {
	
	// remove a few default items that I don't implement, add option to open with finder
	
	NSMutableArray *items = [[defaultMenuItems mutableCopyWithZone:[self zone]] autorelease];
	NSURL *targetLink = [element objectForKey:WebElementLinkURLKey];
	//NSLog([targetLink description]);
	
	NSInteger i;
	for ( i = [items count] - 1; i >= 0; i-- ) 
	{
		NSMenuItem *aMenuItem = [items objectAtIndex:i];
		if ( !([aMenuItem action] == @selector(copyLinkToClipboard:) || [aMenuItem action] == @selector(openLinkInNewWindow:) ) )
			[items removeObjectAtIndex:i];
		
		if ( [aMenuItem action] == @selector(openLinkInNewWindow:) && targetLink != nil )
		{
			[items insertObject:[NSMenuItem separatorItem] atIndex:i];
			
			NSMenuItem *revealWithFinderItem = [[[NSMenuItem alloc] 
					initWithTitle:NSLocalizedString(@"menuitem reveal link in finder",@"") 
					action:@selector(revealLinkInFinder:) 
					keyEquivalent:@""] autorelease];
					
			[revealWithFinderItem setTarget:self];
			[revealWithFinderItem setRepresentedObject:targetLink];
			[items insertObject:revealWithFinderItem atIndex:i];
			
			NSMenuItem *openWithFinderItem = [[[NSMenuItem alloc] 
					initWithTitle:NSLocalizedString(@"menuitem open link with finder",@"") 
					action:@selector(openLinkInFinder:) 
					keyEquivalent:@""] autorelease];
					
			[openWithFinderItem setTarget:self];
			[openWithFinderItem setRepresentedObject:targetLink];
			[items insertObject:openWithFinderItem atIndex:i];
		}
		
		//NSLog(@"%s",[aMenuItem title],[aMenuItem action]);
	}
	
	return items;
}

#pragma mark -

- (IBAction) openLinkInFinder:(id)sender
{
	NSURL *url = [sender representedObject];
	if ( url == nil )
	{
		NSBeep(); return;
	}
	
	[[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction) revealLinkInFinder:(id)sender
{
	NSURL *url = [sender representedObject];

	if ( url == nil || ![url isFileURL] )
	{
		NSBeep(); return;
	}
	
	NSString *path = [url path];
	[[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:[path stringByDeletingLastPathComponent]];
}

#pragma mark -
#pragma mark - Missing File Controller Delegation

- (void) fileController:(MissingFileController*)aFileController wantsToNavBack:(JournlerResource*)aResource;
{
	if ( [[self delegate] respondsToSelector:@selector(selectEntries:)] && [[self delegate] respondsToSelector:@selector(selectResources:)] )
	{
		[[self delegate] selectEntries:[NSArray arrayWithObject:[aResource valueForKey:@"entry"]]];
		[[self delegate] selectResources:nil];
	}
	else
	{
		NSBeep();
	}
}

- (void) fileController:(MissingFileController*)aFileController willDeleteResource:(JournlerResource*)aResource
{
	return;
}

- (void) fileController:(MissingFileController*)aFileController didRelocateResource:(JournlerResource*)aResource
{
	// reload the resource
	[self loadMediaViewerForResource:aResource];
}

#pragma mark -

- (IBAction) jumpToEntryFromPhotoView:(id)sender
{
	NSUInteger theIndex = [photoView indexForMenuEvent];
	if ( theIndex >= [[self selectedResources] count] )
	{
		NSBeep(); return;
	}
	
	JournlerResource *theResource = [[self selectedResources] objectAtIndex:theIndex];
	if ( [[self delegate] respondsToSelector:@selector(_showEntryForSelectedResources:)] )
		[[self delegate] performSelector:@selector(_showEntryForSelectedResources:) withObject:[NSArray arrayWithObject:theResource]];
	else
		NSBeep();
}

- (IBAction) openInFinderFromPhotoView:(id)sender
{
	NSUInteger theIndex = [photoView indexForMenuEvent];
	if ( theIndex >= [[self selectedResources] count] )
	{
		NSBeep(); return;
	}
	
	JournlerResource *theResource = [[self selectedResources] objectAtIndex:theIndex];
	[theResource openWithFinder];
	
}
- (IBAction) revealInFinderFromPhotoView:(id)sender
{
	NSUInteger theIndex = [photoView indexForMenuEvent];
	if ( theIndex >= [[self selectedResources] count] )
	{
		NSBeep(); return;
	}
	
	JournlerResource *theResource = [[self selectedResources] objectAtIndex:theIndex];
	[theResource revealInFinder];
}

- (IBAction) openInNewTabFromPhotoView:(id)sender
{
	NSUInteger theIndex = [photoView indexForMenuEvent];
	if ( theIndex >= [[self selectedResources] count] )
	{
		NSBeep(); return;
	}
	
	JournlerResource *theResource = [[self selectedResources] objectAtIndex:theIndex];
	if ( [[self delegate] respondsToSelector:@selector(openAResourceInNewTab:)] )
		[[self delegate] performSelector:@selector(openAResourceInNewTab:) withObject:theResource];
	else
		NSBeep();
}

- (IBAction) openInNewWindowFromPhotoView:(id)sender
{
	NSUInteger theIndex = [photoView indexForMenuEvent];
	if ( theIndex >= [[self selectedResources] count] )
	{
		NSBeep(); return;
	}
	
	JournlerResource *theResource = [[self selectedResources] objectAtIndex:theIndex];
	if ( [[self delegate] respondsToSelector:@selector(openAResourceInNewWindow:)] )
		[[self delegate] performSelector:@selector(openAResourceInNewWindow:) withObject:theResource];
	else
		NSBeep();
}

- (IBAction) getInfoFromPhotoView:(id)sender
{
	NSUInteger theIndex = [photoView indexForMenuEvent];
	if ( theIndex >= [[self selectedResources] count] )
	{
		NSBeep(); return;
	}
	
	JournlerResource *theResource = [[self selectedResources] objectAtIndex:theIndex];
	
	ResourceInfoController *infoController = [[[ResourceInfoController alloc] init] autorelease];
	
	[infoController setViewAlignment:ResourceInfoAlignLeft];
	[infoController setResource:theResource];
	
	[[infoController window] center];
	[infoController showWindow:sender];
}

#pragma mark -
#pragma mark Mediabar Delegation

- (void) setupMediabar:(PDMediaBar*)aMediabar url:(NSURL*)aURL
{
	if ( ![self canCustomizeMediabar:aMediabar] )
		return;
	else
	{
		[aMediabar setDelegate:self];
		[aMediabar loadItems];
		[aMediabar displayItems];
	}
}

- (NSImage*) defaultOpenWithFinderImage:(PDMediaBar*)aMediabar
{
	// subclasses should override to provide a default "open with finder" icon
	return [[NSImage imageNamed:@"NSApplicationIcon"] imageWithWidth:24 height:24];
}

- (float) mediabarMinimumWidthForUnmanagedControls:(PDMediaBar*)aMediabar
{
	// subclasses should override to provide the minimum width needed for default controls that aren't managed by the media bar
	return 0; // -- neither has a space requirement
}

#pragma mark -

- (BOOL) canCustomizeMediabar:(PDMediaBar*)aMediabar
{
	// subclasses should override and return YES if they allow media bar customization
	if ( aMediabar == defaultContentMediabar )
		return YES; // -- can customize both media bars
	else if ( aMediabar == photoContainerMediabar )
		return YES; // -- can customize the multiselection
	else
		return NO;
}

- (NSString*) mediabarIdentifier:(PDMediaBar*)aMediabar
{
	static NSString *kDefaultContentMediabarIdentifier = @"kDefaultContentMediabarIdentifier";
	static NSString *kMultipleSelectionMediabarIdentifier = @"kMultipleSelectionMediabarIdentifier";
	
	// subclasses may override to provide a different classname
	if ( aMediabar == defaultContentMediabar )
		return kDefaultContentMediabarIdentifier;
		
	else if ( aMediabar == photoContainerMediabar )
		return kMultipleSelectionMediabarIdentifier;
	
	else return [self className];
}


#pragma mark -

- (IBAction) perfomCustomMediabarItemAction:(PDMediabarItem*)anItem
{
	BOOL success = NO;
	static NSString *perform_action_handler = @"perform_action";
	
	// subclasses may override although it isn't necessary
	
	if ( [[anItem typeIdentifier] integerValue] == kMenubarItemURI )
	{
		// throw the uri at the workspace
		NSURL *applicationURI = [anItem targetURI];
		NSURL *fileURI = [self mediaURL];
		
		if ( fileURI != nil && [applicationURI isFileURL] && [fileURI isFileURL] )
		{
			success = [[NSWorkspace sharedWorkspace] openFile:[fileURI path] withApplication:[applicationURI path]];
		}
		else
		{
			NSBeep();
			NSLog(@"%s - curretly, only file based urls are supported %@", __PRETTY_FUNCTION__, [applicationURI absoluteString]);
			success = NO;
		}
	}
	
	else if ( [[anItem typeIdentifier] integerValue] == kMenubarItemAppleScript )
	{
		NSDictionary *errorDictionary;
		NSString *scriptSource = [[anItem targetScript] string];
		
		NSString *resourceURI = [[self mediaURL] absoluteString];
		id theRepresentedObject = (id)[NSNull null];
		
		if ( resourceURI == nil )
		{
			success = NO;
			NSBeep();
			NSLog(@"%s - no media url", __PRETTY_FUNCTION__);
			return;
		}
		
		//id theRepresentedObject = ( [self representedObject] != nil ? [[self representedObject] aeDescriptorValue] : (id)[NSNull null] );
		//id theRepresentedObject = ( [self representedObject] != nil && [[self representedObject] respondsToSelector:@selector(objectSpecifier)] 
		//? [[self representedObject] objectSpecifier] : (id)[NSNull null] );
		
		NSAppleScript *script = [[[NSAppleScript alloc] initWithSource:scriptSource] autorelease];
		if ( script == nil )
		{
			success = NO;
			NSLog(@"%s - unable to initalize script with source %@", __PRETTY_FUNCTION__, scriptSource);
			
			NSBeep();
			AppleScriptAlert *scriptAlert = [[[AppleScriptAlert alloc] initWithSource:[anItem targetScript] error:[NSString string]] autorelease];
			
			NSBeep();
			[scriptAlert showWindow:self];
			goto bail;
		}
		
		if ( [script compileAndReturnError:&errorDictionary] == NO )
		{
			success = NO;
			NSLog(@"%s - unable to compile the script %@, error: %@", __PRETTY_FUNCTION__, scriptSource, errorDictionary);
			
			id theSource = [script richTextSource];
			if ( theSource == nil ) theSource = [script source];
			AppleScriptAlert *scriptAlert = [[[AppleScriptAlert alloc] initWithSource:[anItem targetScript] error:errorDictionary] autorelease];
			
			NSBeep();
			[scriptAlert showWindow:self];
			goto bail;
		}
		
		if ( ![script executeHandler:perform_action_handler error:&errorDictionary withParameters: resourceURI, theRepresentedObject, nil] 
			&& [[errorDictionary objectForKey:NSAppleScriptErrorNumber] integerValue] != kScriptWasCancelledError )
		{
			success = NO;
			NSLog(@"%s - unable to execute handler of script %@, error: %@", __PRETTY_FUNCTION__, scriptSource, errorDictionary);
			
			id theSource = [script richTextSource];
			if ( theSource == nil ) theSource = [script source];
			AppleScriptAlert *scriptAlert = [[[AppleScriptAlert alloc] initWithSource:theSource error:errorDictionary] autorelease];
			
			NSBeep();
			[scriptAlert showWindow:self];
			goto bail;
		}
		
		// we made it through!
		success = YES;
	}

bail:
	
	return;
}

#pragma mark -

- (PDMediabarItem*) mediabar:(PDMediaBar *)mediabar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoMediabar:(BOOL)flag
{
	// subclasses should override to build the media bar
	// call super to get some default support for the get info, show in finder and open with finder items
	
	NSURL *aURL = [self mediaURL];
	NSBundle *sproutedInterfaceBundle = [NSBundle bundleWithIdentifier:@"com.sprouted.interface"];
	PDMediabarItem *anItem = [[[PDMediabarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
	
	if ( [itemIdentifier isEqualToString:PDMediaBarItemGetInfo] )
	{
		[anItem setTitle:NSLocalizedStringFromTableInBundle(@"get info title",@"Mediabar",sproutedInterfaceBundle,@"")];
		[anItem setToolTip:NSLocalizedStringFromTableInBundle(@"get info tip",@"Mediabar",sproutedInterfaceBundle,@"")];
		[anItem setTag:kMediaBarGetInfo];
		[anItem setTypeIdentifier:[NSNumber numberWithInteger:kMenubarItemDefault]];
		
		NSImage *theImage = BundledImageWithName(@"InfoBarSmall.png", @"com.sprouted.interface");
		[anItem setImage:theImage];
		
		[anItem setTarget:self];
		if ( mediabar == defaultContentMediabar )
			[anItem setAction:@selector(mediabarDefaultContentGetInfo:)];
		else if ( mediabar == photoContainerMediabar )
			[anItem setAction:@selector(mediabarMultipleSelectionGetInfo:)];
	}
	
	else if ( [itemIdentifier isEqualToString:PDMediabarItemShowInFinder] )
	{
		[anItem setTitle:NSLocalizedStringFromTableInBundle(@"reveal in finder title",@"Mediabar",sproutedInterfaceBundle,@"")];
		[anItem setToolTip:NSLocalizedStringFromTableInBundle(@"reveal in finder tip",@"Mediabar",sproutedInterfaceBundle,@"")];
		[anItem setTag:kMediaBarShowInFinder];
		[anItem setTypeIdentifier:[NSNumber numberWithInteger:kMenubarItemDefault]];
		
		NSImage *theImage = BundledImageWithName(@"RevealInFinderBarSmall.png", @"com.sprouted.interface");
		[anItem setImage:theImage];
		
		[anItem setTarget:self];
		if ( mediabar == defaultContentMediabar )
			[anItem setAction:@selector(mediabarDefaultContentShowInFinder:)];
		else if ( mediabar == photoContainerMediabar )
			[anItem setAction:@selector(mediabarMultipleSelectionShowInFinder:)];
	}
	
	else if ( [itemIdentifier isEqualToString:PDMediabarItemOpenWithFinder] )
	{
		[anItem setTitle:NSLocalizedStringFromTableInBundle(@"open in finder title",@"Mediabar",sproutedInterfaceBundle,@"")];
		[anItem setTag:kMediaBarOpenWithFinder];
		[anItem setTypeIdentifier:[NSNumber numberWithInteger:kMenubarItemDefault]];
		[anItem setToolTip:NSLocalizedStringFromTableInBundle(@"open in finder tip",@"Mediabar",sproutedInterfaceBundle,@"")];
		
		[anItem setTarget:self];
		if ( mediabar == defaultContentMediabar )
			[anItem setAction:@selector(mediabarDefaultContentOpenInFinder:)];
		else if ( mediabar == photoContainerMediabar )
			[anItem setAction:@selector(mediabarMultipleSelectionOpenInFinder:)];
		
		if ( [aURL isFileURL] )
		{
			NSImage *imageIcon;
			NSString *appName, *fileType, *appPath;
			NSString *filename = [aURL path];
			
			if ( ![[NSWorkspace sharedWorkspace] getInfoForFile:filename application:&appName type:&fileType] || appName == nil )
			{
				NSLog(@"%s - unable to get workspace information for file at path %@", __PRETTY_FUNCTION__, filename);
				// use the default image
				[anItem setImage:[self defaultOpenWithFinderImage:mediabar]];
			}
			else
			{
				appPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:appName];
				
				if ( appPath == nil )
				{
					NSLog(@"%s - unable to get application path for file at path %@", __PRETTY_FUNCTION__, filename);
					// use the default image
					[anItem setImage:[self defaultOpenWithFinderImage:mediabar]];
				}
				else
				{
					#ifdef __DEBUG__
					NSLog(appPath);
					#endif
					
					imageIcon = [[NSWorkspace sharedWorkspace] iconForFile:appPath];
					
					// use a more indicative tooltip
					NSString *appDisplayName = [[NSFileManager defaultManager] displayNameAtPath:appName];
					[anItem setToolTip:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"open with tip",@"Mediabar",sproutedInterfaceBundle,@""), appDisplayName]];
					
					if ( imageIcon == nil )
					{
						NSLog(@"%s - unable to get icon path for application at path %@", __PRETTY_FUNCTION__, appPath);
						// use the default image
						[anItem setImage:[self defaultOpenWithFinderImage:mediabar]];
					}
					else
					{
						[anItem setImage:[imageIcon imageWithWidth:24 height:24]];
					}
				}
			}
		}
		else
		{
			// use the default image
			[anItem setImage:[self defaultOpenWithFinderImage:mediabar]];
		}
	}
	
	else
	{
		// return nil - the setup method will handle custom attributes
		anItem = nil;
	}
	
	return anItem;
}

- (NSArray*) mediabarDefaultItemIdentifiers:(PDMediaBar *)mediabar
{
	// subclasses should override to provide an array of default items
	if ( mediabar == defaultContentMediabar )
		return [NSArray arrayWithObjects:PDMediaBarItemGetInfo, PDMediabarItemShowInFinder, PDMediabarItemOpenWithFinder, nil];
	else if ( mediabar == photoContainerMediabar )
		return [NSArray arrayWithObjects:PDMediaBarItemGetInfo, PDMediabarItemShowInFinder, PDMediabarItemOpenWithFinder, nil];
	else
		return nil;
}

#pragma mark -
#pragma mark Mediabar Methods

- (IBAction) mediabarDefaultContentGetInfo:(id)sender
{	
	JournlerResource *aResource = [self selectedResource];
	if ( aResource == nil )
	{
		NSBeep(); return;
	}
	
	if ( [aResource representsFile] && [self mediaURL] != nil
			&& [[self mediaURL] isFileURL] && ![[self mediaURL] isEqualTo:[NSURL fileURLWithPath:[aResource originalPath]]] )
	{
		// the loaded url takes precedence over the resource's url
		NSLog(@"%s - loaded url is file url and different than resource url", __PRETTY_FUNCTION__);
	}
	
	ResourceInfoController *infoController = [[[ResourceInfoController alloc] init] autorelease];
	
	[infoController setViewAlignment:ResourceInfoAlignLeft];
	[infoController setResource:aResource];
	[[infoController window] center];
	[infoController showWindow:sender];
}

- (IBAction) mediabarDefaultContentShowInFinder:(id)sender
{
	JournlerResource *aResource = [self selectedResource];
	if ( aResource == nil )
	{
		NSBeep(); return;
	}
	
	if ( [aResource representsFile] && [self mediaURL] != nil
			&& [[self mediaURL] isFileURL] && ![[self mediaURL] isEqualTo:[NSURL fileURLWithPath:[aResource originalPath]]] )
	{
		// the loaded url takes precedence over the resource's url
		NSLog(@"%s - loaded url is file url and different than resource url", __PRETTY_FUNCTION__);
		
		NSString *path = [[self mediaURL] path];
		[[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:[path stringByDeletingLastPathComponent]];
	}
	else
	{
		// the resource knows what to do
		[aResource revealInFinder];
	}
}

- (IBAction) mediabarDefaultContentOpenInFinder:(id)sender
{
	JournlerResource *aResource = [self selectedResource];
	if ( aResource == nil )
	{
		NSBeep(); return;
	}
	
	if ( [aResource representsFile] && [self mediaURL] != nil
			&& [[self mediaURL] isFileURL] && ![[self mediaURL] isEqualTo:[NSURL fileURLWithPath:[aResource originalPath]]] )
	{
		// the loaded url takes precedence over the resource's url
		NSLog(@"%s - loaded url is file url different than resource url", __PRETTY_FUNCTION__);
		
		[[NSWorkspace sharedWorkspace] openURL:[self mediaURL]];
	}
	else
	{
		// the resource knows what to do
		[aResource openWithFinder];
	}
}

#pragma mark -

- (IBAction) mediabarMultipleSelectionGetInfo:(id)sender
{
	NSArray *theResources = [self selectedResources];
	if ( theResources == nil || [theResources count] == 0 )
	{
		NSBeep(); return;
	}
	
	BOOL first = YES;
    for ( JournlerResource *aResource in theResources )
	{
		ResourceInfoController *infoController = [[[ResourceInfoController alloc] init] autorelease];
		
		[infoController setViewAlignment:ResourceInfoAlignLeft];
		[infoController setResource:aResource];
		
		if ( first )
		{
			[[infoController window] center];
			first = NO;
		}
		
		[infoController showWindow:sender];
	}
}

- (IBAction) mediabarMultipleSelectionShowInFinder:(id)sender
{
	NSArray *theResources = [self selectedResources];
	if ( theResources == nil || [theResources count] == 0 )
	{
		NSBeep(); 
        return;
	}
	
    for ( JournlerResource *aResource in theResources )
		// the resource knows what to do
		[aResource revealInFinder];
}

- (IBAction) mediabarMultipleSelectionOpenInFinder:(id)sender
{
	NSArray *theResources = [self selectedResources];
	if ( theResources == nil || [theResources count] == 0 )
	{
		NSBeep(); 
        return;
	}
	
    for ( JournlerResource *aResource in theResources )
		// the resource knows what to do
		[aResource openWithFinder];
}


@end

#pragma mark -

@implementation ResourceCellController (FindPanelSupport)

- (BOOL) handlesFindCommand
{
	return [[self mediaController] handlesFindCommand];
}

- (void) performCustomFindPanelAction:(id)sender
{
	if ( [[self mediaController] respondsToSelector:@selector(performCustomFindPanelAction:)] )
		[[self mediaController] performSelector:@selector(performCustomFindPanelAction:) withObject:sender];
}

- (void) checkCustomFindPanelAction
{
	//if ( [mediaController handlesFindCommand] )
	//	[[NSApp delegate] performSelector:@selector(setFindPanelPerformsCustomAction:) withObject:[NSNumber numberWithBool:YES]];
	//else
	//	[[NSApp delegate] performSelector:@selector(setFindPanelPerformsCustomAction:) withObject:[NSNumber numberWithBool:NO]];
}

#pragma mark -

- (BOOL) handlesTextSizeCommand
{
	return [[self mediaController] handlesTextSizeCommand];
}

- (void) performCustomTextSizeAction:(id)sender
{
	if ( [[self mediaController] respondsToSelector:@selector(performCustomTextSizeAction:)] )
		[[self mediaController] performSelector:@selector(performCustomTextSizeAction:) withObject:sender];
}

- (void) checkCustomTextSizeAction
{
	//if ( [[self mediaController] handlesTextSizeCommand] )
	//	[[NSApp delegate] performSelector:@selector(setTextSizePerformsCustomAction:) withObject:[NSNumber numberWithBool:YES]];
	//else
	//	[[NSApp delegate] performSelector:@selector(setTextSizePerformsCustomAction:) withObject:[NSNumber numberWithBool:NO]];
}

@end
