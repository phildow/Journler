#import "JournlerMediaViewer.h"
#import "JournlerMediaContentController.h"

#import "AudioViewController.h"
#import "MovieViewController.h"
#import "WebViewController.h"
#import "PDPDFViewController.h"
#import "ImageViewController.h"
#import "AddressRecordController.h"
#import "MailMessageController.h"
#import "WordDocumentController.h"
#import "TextDocumentController.h"

#import "JournlerResource.h"

#import <SproutedUtilities/SproutedUtilities.h>
//#import "NSWorkspace_PDCategories.h"

@implementation JournlerMediaViewer

+ (BOOL) canDisplayMediaOfType:(NSString*)uti url:(NSURL*)aURL
{
	BOOL can_display = NO;
	
	if ( uti == nil ) 
		return NO;
	
	NSString *path = nil;
	if ( [aURL isFileURL] )
		path = [aURL path];
		
	NSString *mime_type = (NSString*)UTTypeCopyPreferredTagWithClass((CFStringRef)uti,kUTTagClassMIMEType);
		
	if ( UTTypeConformsTo((CFStringRef)uti,kUTTypeWebArchive) || UTTypeConformsTo( (CFStringRef)uti, kUTTypeHTML) )
		can_display = YES;
	else if ( UTTypeConformsTo((CFStringRef)uti,kUTTypePDF) )
		can_display = YES;
	else if ( UTTypeConformsTo((CFStringRef)uti,kUTTypeImage) )
		can_display = YES;
	else if ( [[NSWorkspace sharedWorkspace] canPlayFile:path] )
		can_display = YES;
	else if ( [[NSWorkspace sharedWorkspace] canWatchFile:path] )
		can_display = YES;
	else if ( UTTypeConformsTo((CFStringRef)uti,kUTTypeURL) || UTTypeConformsTo((CFStringRef)uti,(CFStringRef)ResourceURLUTI) )
		can_display = YES;
	else if ( UTTypeConformsTo((CFStringRef)uti,(CFStringRef)ResourceABPersonUTI) )
		can_display = YES;
	else if ( UTTypeConformsTo((CFStringRef)uti,(CFStringRef)ResourceMailUTI) )
		can_display = YES;
	else if ( UTTypeConformsTo((CFStringRef)uti,(CFStringRef)ResourceMailStandardEmailUTI))
		can_display = YES;
	else if ( UTTypeConformsTo( (CFStringRef)uti, (CFStringRef)@"com.microsoft.word.doc") )
		can_display = YES;
	else if ( mime_type != nil && [WebView canShowMIMEType:mime_type] )
		can_display = YES;
	else if ( UTTypeConformsTo( (CFStringRef)uti, kUTTypeRTF ) || UTTypeConformsTo( (CFStringRef)uti, kUTTypeRTFD ) || UTTypeConformsTo( (CFStringRef)uti, kUTTypePlainText ) )
		can_display = YES;
	else
		can_display = NO;
		
	if ( mime_type != nil ) 
		[mime_type release];
		
	return can_display;
}

#pragma mark -

- (id) initWithURL:(NSURL*)url uti:(NSString*)uti
{
	_contentController = nil;
	Class controllerClass = nil;
	
	// first determine if we can display the media
	if ( [url isFileURL] ) 
	{
		if ( UTTypeConformsTo((CFStringRef)uti,kUTTypeWebArchive) || UTTypeConformsTo( (CFStringRef)uti, kUTTypeHTML) )
			controllerClass = [WebViewController class];
			
		else if ( UTTypeConformsTo((CFStringRef)uti,(CFStringRef)kUTTypePDF) )
			controllerClass = [PDPDFViewController class];
		
		else if ( UTTypeConformsTo((CFStringRef)uti,(CFStringRef)kUTTypeImage) )
			controllerClass = [ImageViewController class];
		
		else if ( UTTypeConformsTo((CFStringRef)uti,(CFStringRef)kUTTypeAudio) )
			controllerClass = [AudioViewController class];
		
		else if ( UTTypeConformsTo((CFStringRef)uti,(CFStringRef)@"public.movie") )
			controllerClass = [MovieViewController class];
		
		else if ( UTTypeConformsTo((CFStringRef)uti,(CFStringRef)ResourceMailUTI) )
			controllerClass = [MailMessageController class];
		
		else if ( UTTypeConformsTo((CFStringRef)uti,(CFStringRef)ResourceMailStandardEmailUTI) )
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
		}
	}
	
	else 
	{
		if ( UTTypeConformsTo((CFStringRef)uti,kUTTypeURL) || UTTypeConformsTo((CFStringRef)uti,(CFStringRef)ResourceURLUTI) )
			controllerClass = [WebViewController class];
		else if ( UTTypeConformsTo((CFStringRef)uti,(CFStringRef)ResourceABPersonUTI) )
			controllerClass = [AddressRecordController class];
	}
	
	
	if ( controllerClass == nil ) 
	{
		[self release];
		return nil;
	}
	
	else if ( self = [self initWithWindowNibName:@"MediaViewer"] ) 
	{
		// take control of ourselves
		//[self setShouldCascadeWindows:NO];
		
		homeURL = [url retain];
		_contentController = [[controllerClass alloc] init];
		[self retain];
	}
	
	return self;
}


- (void) windowDidLoad 
{	
	[[self window] setFrameUsingName:@"Media Viewer Window" force:YES];
	[[self window] setBackgroundColor:[NSColor whiteColor]];
	
	[[_contentController contentView] setFrame:[contentPlaceholder frame]];
	[[[self window] contentView] replaceSubview:contentPlaceholder with:[_contentController contentView]];
	
	//[[self window] setContentView:[_contentController contentView]];
	
	[_contentController setDelegate:self];
	[_contentController loadURL:homeURL];
	
}

- (void) dealloc 
{
	#ifdef __DEBUG__
	NSLog(@"%s", __PRETTY_FUNCTION__);
	#endif
	
	[_contentController ownerWillClose:nil];
	[_contentController release];
	[homeURL release];
	
	[super dealloc];
}

- (void)windowWillClose:(NSNotification *)aNotification 
{
	[self autorelease];
}

#pragma mark -

- (id) representedObject
{
	return [_contentController representedObject];
}

- (void) setRepresentedObject:(id)anObject
{
	[_contentController setRepresentedObject:anObject];
}

#pragma mark -

- (MediaContentController*) contentController
{
	return _contentController;
}

#pragma mark -

- (void) contentController:(MediaContentController*)controller changedTitle:(NSString*)title 
{
	if ( controller != _contentController ) 
		return;
	
	if ( title != nil ) 
		[[self window] setTitle:title];
}

#pragma mark -

- (BOOL) highlightString:(NSString*)aString
{
	// pass it on to the controller
	return [_contentController highlightString:aString];
}

- (IBAction) printDocument:(id)sender 
{
	// pass it on to the controller
	[_contentController printDocument:sender];
}

- (IBAction) save:(id)sender
{
	NSBeep();
	return;
}

- (IBAction) exportSelection:(id)sender
{
	// pass it on to the controller
	[_contentController exportSelection:sender];
}

- (IBAction) doPageSetup:(id) sender 
{	
	NSPageLayout *pageLayout = [NSPageLayout pageLayout];
	[pageLayout setAccessoryView:[[PageSetupController sharedPageSetup] contentView]];
	
	if ( [[self window] isMainWindow] )
		[pageLayout beginSheetWithPrintInfo:[NSPrintInfo sharedPrintInfo] modalForWindow:[self window] 
				delegate:nil didEndSelector:nil contextInfo:nil];
	else
		[pageLayout runModalWithPrintInfo:[NSPrintInfo sharedPrintInfo]];
	
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	BOOL enabled = YES;
	SEL action = [menuItem action];
	
	if ( action == @selector(printDocument:) )
		enabled = YES;
		
	else if ( action == @selector(doPageSetup:) )
		enabled = YES;
		
	else if ( action == @selector(exportSelection:) )
		enabled = YES;
		
	else if ( action == @selector(save:) )
		enabled = NO;
	
	else if ( action == @selector(performCustomFindPanelAction:) )
		enabled = [_contentController handlesFindCommand];
	
	else if ( action == @selector(performCustomTextSizeAction:) )
		enabled = [_contentController handlesTextSizeCommand];
	
	return enabled;
}

@end

#pragma mark -

@implementation JournlerMediaViewer (CustomMenuSupport)

- (void)performCustomFindPanelAction:(id)sender
{
	// the first responder should only make it this far under special circumstances
	if ( [_contentController handlesFindCommand] && [_contentController respondsToSelector:@selector(performCustomFindPanelAction:)] )
		[_contentController performSelector:@selector(performCustomFindPanelAction:) withObject:sender];
	else
	{
		NSBeep();
	}
}

- (void) performCustomTextSizeAction:(id)sender
{
	// the first responder should only make it this far under special circumstances
	if ( [_contentController handlesTextSizeCommand] && [_contentController respondsToSelector:@selector(performCustomTextSizeAction:)] )
		[_contentController performSelector:@selector(performCustomTextSizeAction:) withObject:sender];
	else
	{
		NSBeep();
	}
}

@end