//
//  GenericMediaController.m
//  Journler
//
//  Created by Philip Dow on 6/17/07.
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

#import "GenericMediaController.h"
#import "CHEmbeddedMediaQuicklookObject.h"

//static NSString *kQLFrameworkPath = @"/System/Library/PrivateFrameworks/QuickLookUI.framework";

@interface NSObject (GenericMediaControllerAdditions)

- (void)setURL:(id)fp8;
- (void)_startLoadingURL:(id)fp8 timeoutDate:(id)fp12;

@end

@implementation GenericMediaController

@synthesize quicklookItem;

- (id) init
{	
	if ( self = [super init] )
	{
		/*
        if ( [[NSFileManager defaultManager] fileExistsAtPath:kQLFrameworkPath] )
		{
			NSBundle *qlPreviewBundle = [NSBundle bundleWithPath:kQLFrameworkPath];
			if ( ![qlPreviewBundle isLoaded] && ![qlPreviewBundle load] )
			{
				NSLog(@"%s - unable to load QuickLookUI.framework bundle at path %@", __PRETTY_FUNCTION__, kQLFrameworkPath);
			}
		}
		else
		{
			NSLog(@"%s - no quicklook framework at path %@", __PRETTY_FUNCTION__, kQLFrameworkPath);
		}
        */
		
		usesQuickLook = YES;
		[NSBundle loadNibNamed:@"GenericFileContentView" owner:self];
	}
	
	return self;
}

- (void) dealloc
{
	[infoView release], infoView = nil;
	[previewView release], previewView = nil;
	
    self.quicklookItem = nil;
    
	[super dealloc];
}

#pragma mark -

- (BOOL) usesQuickLook 
{
	return usesQuickLook;
}

- (void) setUsesQuickLook:(BOOL)ql 
{
	usesQuickLook = ql;
}

#pragma mark -

- (BOOL) loadURL:(NSURL*)aURL 
{
	if ( [self usesQuickLook] /*&& [previewPlaceholder respondsToSelector:@selector(addTrackingArea:)]*/ )
		[self _showQLPreviewForURL:aURL];
	else
		[self _showFileInfoForURL:aURL];
		
	BOOL success = [super loadURL:aURL];
	return success;
}

- (void) _showQLPreviewForURL:(NSURL*)url
{
	// set up the QLPreviewView // 10.6 & 10.7
    previewView = [[QLPreviewView alloc] initWithFrame:[previewPlaceholder frame]];
    
    [previewView setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
    [[previewPlaceholder superview] replaceSubview:previewPlaceholder with:previewView];
    
    // create a generic preview item for the url and load it
    
    NSString *title = [NSString string];
    CHEmbeddedMediaQuicklookObject *item = [[[CHEmbeddedMediaQuicklookObject alloc] initWithURL:url title:title] autorelease];
    self.quicklookItem = item;
    
    // load the item
    
    previewView.previewItem = self.quicklookItem;
    
    /*
    Class ql_preview_view = NSClassFromString(@"QLPreviewView");
	if ( ql_preview_view == nil )
	{
		NSLog(@"%s - unable to find the QLPreviewView class in the runtime", __PRETTY_FUNCTION__);
	}
	else
	{
		if ( previewView == nil )
		{
			previewView = [[ql_preview_view alloc] initWithFrame:[previewPlaceholder frame]];
			
			[previewView setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
			[[previewPlaceholder superview] replaceSubview:previewPlaceholder with:previewView];
		}
		
		[previewView setURL:url];
		[previewView _startLoadingURL:url timeoutDate:[NSDate dateWithTimeIntervalSinceNow:30]];
	}
    */
}

- (void) _showFileInfoForURL:(NSURL*)url
{
	if ( infoView == nil )
	{
		infoView = [[PDFileInfoView alloc] initWithFrame:[previewPlaceholder frame]];
		
		[infoView setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
		[[previewPlaceholder superview] replaceSubview:previewPlaceholder with:infoView];
	}
	
	[infoView setURL:url];
}

- (IBAction) printDocument:(id)sender
{
	return;
}

#pragma mark -

#pragma mark -
#pragma mark The Media Bar

- (BOOL) canCustomizeMediabar:(PDMediaBar*)aMediabar
{
	return YES;
}

- (NSImage*) defaultOpenWithFinderImage:(PDMediaBar*)aMediabar
{
	return BundledImageWithName(@"RevealInFinderBarSmall.png", @"com.sprouted.interface");
}

- (NSArray*) mediabarDefaultItemIdentifiers:(PDMediaBar *)mediabar
{
	return [NSArray arrayWithObjects:PDMediaBarItemGetInfo, PDMediabarItemShowInFinder, PDMediabarItemOpenWithFinder, nil];
}

@end
