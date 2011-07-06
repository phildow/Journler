//
//  GenericMediaController.m
//  Journler
//
//  Created by Phil Dow on 6/17/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "GenericMediaController.h"

static NSString *kQLFrameworkPath = @"/System/Library/PrivateFrameworks/QuickLookUI.framework";

@interface NSObject (GenericMediaControllerAdditions)

- (void)setURL:(id)fp8;
- (void)_startLoadingURL:(id)fp8 timeoutDate:(id)fp12;

@end

@implementation GenericMediaController

- (id) init
{	
	if ( self = [super init] )
	{
		if ( [[NSFileManager defaultManager] fileExistsAtPath:kQLFrameworkPath] )
		{
			NSBundle *qlPreviewBundle = [NSBundle bundleWithPath:kQLFrameworkPath];
			if ( ![qlPreviewBundle isLoaded] && ![qlPreviewBundle load] )
			{
				NSLog(@"%@ %s - unable to load QuickLookUI.framework bundle at path %@", [self className], _cmd, kQLFrameworkPath);
			}
		}
		else
		{
			NSLog(@"%@ %s - no quicklook framework at path %@", [self className], _cmd, kQLFrameworkPath);
		}
		
		usesQuickLook = NO;
		[NSBundle loadNibNamed:@"GenericFileContentView" owner:self];
	}
	
	return self;
}

- (void) dealloc
{
	[infoView release], infoView = nil;
	[previewView release], previewView = nil;
	
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
	if ( [self usesQuickLook] && [previewPlaceholder respondsToSelector:@selector(addTrackingArea:)] )
		[self _showQLPreviewForURL:aURL];
	else
		[self _showFileInfoForURL:aURL];
		
	BOOL success = [super loadURL:aURL];
	return success;
}

- (void) _showQLPreviewForURL:(NSURL*)url
{
	Class ql_preview_view = NSClassFromString(@"QLPreviewView");
	if ( ql_preview_view == nil )
	{
		NSLog(@"%@ %s - unable to find the QLPreviewView class in the runtime", [self className], _cmd);
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
