#import "ImageViewController.h"
#import "NSAlert+JournlerAdditions.h"
#import "JournlerMediaViewer.h"
#import "PDExportableImageView.h"

#import <SproutedInterface/SproutedInterface.h>

@implementation ImageViewController

- (id) init
{
	if ( self = [super init] )
	{
		[NSBundle loadNibNamed:@"ImageFileView" owner:self];
	}
	
	return self;	
}

- (void) dealloc 
{ 
	[_contextual release];
		_contextual = nil;
	
	[super dealloc];
}

- (void) awakeFromNib 
{
	[super awakeFromNib];
	[_imageView setFocusRingType:NSFocusRingTypeNone];
}

#pragma mark -

- (BOOL) loadURL:(NSURL*)aURL {
	
	NSImage *img = [[[NSImage alloc] initWithContentsOfURL:aURL] autorelease];
	if ( !img ) 
	{
		NSLog(@"ImageViewController updateContent does not understand image at %@",aURL);
		NSBeep();
		[[NSAlert mediaError] runModal];
		return NO;
	}
	else 
	{
		[_imageView setImage:img];
		if ( [aURL isFileURL] ) [_imageView setFilename:[aURL path]];
	}
	
	[super loadURL:aURL];
	return YES;
}

- (void) stopContent 
{
	
}

- (NSResponder*) preferredResponder
{
	return _imageView;
}

- (void) appropriateFirstResponder:(NSWindow*)window 
{
	[window makeFirstResponder:_imageView];
}

- (IBAction) printDocument:(id)sender 
{
	
	NSPrintingOrientation orientation = NSPortraitOrientation;
	NSImage *current_image = [_imageView image];
	
	if ( !current_image ) 
	{ 
		NSBeep(); return; 
	}
	
	NSSize image_size = [current_image size];
	if ( image_size.width > image_size.height ) 
		orientation = NSLandscapeOrientation;
	
	NSPrintInfo *modifiedInfo = [[[NSPrintInfo sharedPrintInfo] copyWithZone:[self zone]] autorelease];
	
	[modifiedInfo setOrientation:orientation];
	
	[modifiedInfo setHorizontalPagination:NSFitPagination];
	[modifiedInfo setVerticalPagination:NSFitPagination];
    [modifiedInfo setHorizontallyCentered:YES];
    [modifiedInfo setVerticallyCentered:YES];
	[[modifiedInfo dictionary] setValue:[NSNumber numberWithBool:NO] forKey:NSPrintHeaderAndFooter];
	
	[[NSPrintOperation printOperationWithView:_imageView printInfo:modifiedInfo] runOperation];
}

#pragma mark -

- (IBAction)openInNewWindow:(id)sender
{
	JournlerMediaViewer *mediaViewer = [[[JournlerMediaViewer alloc] initWithURL:[self URL] uti:(NSString*)kUTTypePDF] autorelease];
	if ( mediaViewer == nil )
	{
		NSLog(@"%@ %s - problem allocating media viewer for url %@", [self className], _cmd, [self URL]);
		[[NSWorkspace sharedWorkspace] openURL:[self URL]];
	}
	else
	{
		[mediaViewer setRepresentedObject:[self representedObject]];
		[mediaViewer showWindow:self];
	}
}

- (IBAction)openInPreview:(id)sender
{
	static NSString *appPreview = @"Preview.app";
	if ( [[self URL] isFileURL] )
	{
		[[NSWorkspace sharedWorkspace] openFile:[[self URL] path] withApplication:appPreview];
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
	return BundledImageWithName(@"PreviewBarSmall.png", @"com.sprouted.interface");
}

- (NSArray*) mediabarDefaultItemIdentifiers:(PDMediaBar *)mediabar
{
	return [NSArray arrayWithObjects:PDMediaBarItemGetInfo, PDMediabarItemShowInFinder, PDMediabarItemOpenWithFinder, nil];
}

@end
