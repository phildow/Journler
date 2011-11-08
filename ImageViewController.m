
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
		NSLog(@"%s - problem allocating media viewer for url %@", __PRETTY_FUNCTION__, [self URL]);
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
