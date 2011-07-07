//
//  JournlerMediaContentController.m
//  Journler
//
//  Created by Philip Dow on 6/11/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import "JournlerMediaContentController.h"
#import "Definitions.h"

// I would prefer to keep the resource related methods out of this file
#import "ResourceInfoController.h"
#import "JournlerResource.h"

#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>

@implementation JournlerMediaContentController

- (id) init 
{
	if ( self = [super init] )
	{
		URL = [[NSURL alloc] initWithString:@"http://journler.com"];
	}
	return self;
}

- (void) awakeFromNib
{
	// sublcasses should call super's implementation
	[self prepareTitleBar];
}

- (void) dealloc
{
	#ifdef __DEBUG__
	NSLog(@"%s", __PRETTY_FUNCTION__);
	#endif
	
	// top level nib objects
	[contentView release];
	
	// local variables
	[URL release];
	[searchString release];
	[representedObject release];
	
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

- (id) representedObject
{
	return representedObject;
}

- (void) setRepresentedObject:(id)anObject
{
	if ( representedObject != anObject )
	{
		[representedObject release];
		representedObject = [anObject retain];
	}
}

- (NSURL*) URL
{
	return URL;
}

- (void) setURL:(NSURL*)aURL
{
	if ( URL != aURL )
	{
		[URL release];
		URL = [aURL copyWithZone:[self zone]];
	}
}

- (NSString*) searchString
{
	return searchString;
}

- (void) setSearchString:(NSString*)aString
{
	if ( searchString != aString )
	{
		[searchString release];
		searchString = [aString retain];
	}
}

#pragma mark -

- (BOOL) loadURL:(NSURL*)aURL
{
	// overridden by subclasses to load the given url
	// subclasses must set the url, or subclasses should call super's implementation
	
	[self setURL:aURL];
	[self setupMediabar:bar url:aURL];
	[self setWindowTitleFromURL:aURL];
	
	// call back to the delegate
	if ( [[self delegate] respondsToSelector:@selector(contentController:didLoadURL:)] )
		[[self delegate] contentController:self didLoadURL:aURL];
	
	return YES;
}

- (BOOL) highlightString:(NSString*)aString
{
	if ( aString == nil || [aString length] == 0 )
		return NO;
	
	// overridden by subclasses to highlight a string in their view
	NSPasteboard *findBoard = [NSPasteboard pasteboardWithName:NSFindPboard];
	[findBoard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
	[findBoard setString:aString forType:NSStringPboardType];
	
	return NO;
}

- (IBAction) printDocument:(id)sender 
{
	// overridden by subclasses to handle document type specific printing
	return;
}

- (IBAction) exportSelection:(id)sender
{
	// subclasses should override if the url does not point to a file or if they want special behavior
	if ( [[self URL] isFileURL] )
	{
		NSSavePanel *savePanel = [NSSavePanel savePanel];
		[savePanel setRequiredFileType:nil];
		[savePanel setCanSelectHiddenExtension:YES];
	
		//[openPanel setMessage:NSLocalizedString(@"export resources panel text",@"")];
		//[openPanel setTitle:NSLocalizedString(@"export resources panel title",@"")];
		//[openPanel setPrompt:NSLocalizedString(@"export resources panel prompt",@"")];
		
		if ( [savePanel runModalForDirectory:nil file:[[[self URL] path] lastPathComponent]] == NSOKButton )
		{
			NSString *filename = [savePanel filename];
			if ( ![[NSFileManager defaultManager] copyPath:[[self URL] path] toPath:filename handler:self] )
			{
				NSString *errorTitle = NSLocalizedString(@"file manager error title",@"");
				NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(@"file manager error msg",@""), 
				[fileError objectForKey:@"Error"], [fileError objectForKey:@"Path"]];
				
				NSBeep();
				NSRunAlertPanel(errorTitle, errorMessage, nil, nil, nil); 
				
				[fileError release];
				fileError = nil;
			}
			else
			{
				NSDictionary *fileAttributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:[savePanel isExtensionHidden]] forKey:NSFileExtensionHidden];
				[[NSFileManager defaultManager] changeFileAttributes:fileAttributes atPath:[savePanel filename]];
			}
		}
	}
	else
	{
		NSBeep();
		return;
	}
}

#pragma mark -

- (IBAction) getInfo:(id)sender
{
	if ( [[self representedObject] isKindOfClass:[JournlerResource class]] )
		[self showInfoForResource:[self representedObject]];
	else
		NSBeep();
}

- (IBAction) showInFinder:(id)sender 
{
	// subclasses may override to provide more specific behavior
	if ( [[self URL] isFileURL] )
	{
		if ( ![[NSWorkspace sharedWorkspace] selectFile:[[self URL] path] 
				inFileViewerRootedAtPath:[[[self URL] path] stringByDeletingLastPathComponent]] )
			NSBeep();
	}
	else
		[self openInFinder:sender];
}

- (IBAction) openInFinder:(id)sender 
{
	// subclasses may override to provide more specific behavior
	if ( ![[NSWorkspace sharedWorkspace] openURL:[self URL]] )
	{
		if ( ![[NSWorkspace sharedWorkspace] selectFile:[[self URL] path] 
				inFileViewerRootedAtPath:[[[self URL] path] stringByDeletingLastPathComponent]] )
			NSBeep();
	}
}

#pragma mark -

- (void) prepareTitleBar
{
	// subclasses may override to provide special behavior
	int whichBorders[4] = {1,0,1,0};
	[bar setBordered:YES];
	[bar setBorderColor:[NSColor colorWithCalibratedRed:155.0/255.0 green:155.0/255.0 blue:155.0/255.0 alpha:1.0]];
	[bar setBorders:whichBorders];
}

- (void) setWindowTitleFromURL:(NSURL*)aURL
{
	// subclasses may override to provide custom behavior
	if ( delegate && [delegate respondsToSelector:@selector(contentController:changedTitle:)] )
	{
		if ( [aURL isFileURL] )
			[delegate contentController:self changedTitle:[[[aURL path] lastPathComponent] stringByDeletingPathExtension]];
		else
			[delegate contentController:self changedTitle:[aURL absoluteString]];
	}
}

- (NSResponder*) preferredResponder
{
	// meant to be overridden by subclasses
	NSLog(@"%s - **** subclasses must override ****", __PRETTY_FUNCTION__);
	return nil;
}

- (void) appropriateFirstResponder:(NSWindow*)window 
{
	// meant to be overridden by subclasses
	return;
}

- (void) appropriateAlternateResponder:(NSWindow*)aWindow
{
	// meant to be overridden by subclasses
	return;
}

- (void) establishKeyViews:(NSView*)previous nextKeyView:(NSView*)next
{
	// meant to be overridden by subclasses
	// establish a connection between the two provided views if you don't need them
	[previous setNextKeyView:next];
	NSLog(@"%s - **** subclasses must override ****", __PRETTY_FUNCTION__);
	return;
}

#pragma mark -

- (BOOL) handlesFindCommand
{
	// subclasses should override and return yes if they handle the find panel in their own way, including windowing
	return NO;
}

- (void) performCustomFindPanelAction:(id)sender
{
	// subclasses should override and return perform the handling in their own specific way
	return;
}

- (BOOL) handlesTextSizeCommand
{
	// subclasses should override and return yes if the handle the cmd +/- menu items (bigger/smaller)
	return NO;
}

- (void) performCustomTextSizeAction:(id)sender
{
	// subclasses should override and return perform the handling in their own specific way
	return;
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	// subclasses should override and validate/invalidate their own way (specifically for the custom find panel action and +/- actions)
	return YES;
}

#pragma mark -

- (void) ownerWillClose:(NSNotification*)aNotification
{
	// subclasses should override to unhook bindings, etc. aNotification is currently nil
	[self stopContent];
	[contentView removeFromSuperview];
}

- (void) updateContent 
{
	//meant to be overriddden by subclasses
	return;
}

- (void) stopContent 
{
	//meant to be overridden by subclasses
	return;
}

#pragma mark -

- (BOOL)fileManager:(NSFileManager *)manager shouldProceedAfterError:(NSDictionary *)errorInfo
{
	NSLog(@"%s - file error: %@", __PRETTY_FUNCTION__, errorInfo);
	fileError = [errorInfo retain];
	return NO;
}

- (void)fileManager:(NSFileManager *)manager willProcessPath:(NSString *)path
{
	return;
}

#pragma mark -
#pragma mark MediaBar Implementation

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
	return nil;
}

- (float) mediabarMinimumWidthForUnmanagedControls:(PDMediaBar*)aMediabar
{
	// subclasses should override to provide the minimum width needed for default controls that aren't managed by the media bar
	return 0;
}

#pragma mark -

- (BOOL) canCustomizeMediabar:(PDMediaBar*)aMediabar
{
	// subclasses should override and return YES if they allow media bar customization
	return NO;
}

- (NSString*) mediabarIdentifier:(PDMediaBar*)aMediabar
{
	// subclasses may override to provide a different classname
	return [self className];
}


#pragma mark -


- (IBAction) perfomCustomMediabarItemAction:(PDMediabarItem*)anItem
{
	BOOL success = NO;
	static NSString *perform_action_handler = @"perform_action";
	
	// subclasses may override although it isn't necessary
	
	if ( [[anItem typeIdentifier] intValue] == kMenubarItemURI )
	{
		// throw the uri at the workspace
		NSURL *applicationURI = [anItem targetURI];
		NSURL *fileURI = [self URL];
		
		if ( [applicationURI isFileURL] && [fileURI isFileURL] )
		{
			success = [[NSWorkspace sharedWorkspace] openFile:[fileURI path] withApplication:[applicationURI path]];
			if ( !success )
				success = [[NSWorkspace sharedWorkspace] selectFile:[fileURI path] inFileViewerRootedAtPath:[[fileURI path] stringByDeletingLastPathComponent]];
		}
		else
		{
			NSLog(@"%s - curretly, only file based urls are supported %@", __PRETTY_FUNCTION__, [applicationURI absoluteString]);
			success = NO;
		}
	}
	
	else if ( [[anItem typeIdentifier] intValue] == kMenubarItemAppleScript )
	{
		NSDictionary *errorDictionary;
		NSString *scriptSource = [[anItem targetScript] string];
		
		NSString *resourceURI = [[self URL] absoluteString];
		id theRepresentedObject = (id)[NSNull null];
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
			AppleScriptAlert *scriptAlert = [[[AppleScriptAlert alloc] initWithSource:[anItem targetScript] error:errorDictionary] autorelease];
			
			NSBeep();
			[scriptAlert showWindow:self];
			goto bail;
		}
		
		if ( ![script executeHandler:perform_action_handler error:&errorDictionary withParameters: resourceURI, theRepresentedObject, nil] 
			 && [[errorDictionary objectForKey:NSAppleScriptErrorNumber] intValue] != kScriptWasCancelledError )
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
	
	NSURL *aURL = [self URL];
	NSBundle *myBundle = [NSBundle bundleWithIdentifier:@"com.sprouted.interface"];
	PDMediabarItem *anItem = [[[PDMediabarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
	
	if ( [itemIdentifier isEqualToString:PDMediaBarItemGetInfo] )
	{
		[anItem setTitle:NSLocalizedStringFromTableInBundle(@"get info title",@"Mediabar",myBundle,@"")];
		[anItem setToolTip:NSLocalizedStringFromTableInBundle(@"get info tip",@"Mediabar",myBundle,@"")];
		[anItem setTag:kMediaBarGetInfo];
		[anItem setTypeIdentifier:[NSNumber numberWithInt:kMenubarItemDefault]];
		
		NSImage *theImage = [[[NSImage alloc] initWithContentsOfFile:[myBundle pathForImageResource:@"InfoBarSmall.png"]] autorelease];
		[anItem setImage:theImage];
		
		[anItem setTarget:self];
		[anItem setAction:@selector(getInfo:)];
	}
	
	else if ( [itemIdentifier isEqualToString:PDMediabarItemShowInFinder] )
	{
		[anItem setTitle:NSLocalizedStringFromTableInBundle(@"reveal in finder title",@"Mediabar",myBundle,@"")];
		[anItem setToolTip:NSLocalizedStringFromTableInBundle(@"reveal in finder tip",@"Mediabar",myBundle,@"")];
		[anItem setTag:kMediaBarShowInFinder];
		[anItem setTypeIdentifier:[NSNumber numberWithInt:kMenubarItemDefault]];
		
		NSImage *theImage = [[[NSImage alloc] initWithContentsOfFile:[myBundle pathForImageResource:@"RevealInFinderBarSmall.png"]] autorelease];
		[anItem setImage:theImage];
		
		[anItem setTarget:self];
		[anItem setAction:@selector(showInFinder:)];
	}
	
	else if ( [itemIdentifier isEqualToString:PDMediabarItemOpenWithFinder] )
	{
		[anItem setTitle:NSLocalizedStringFromTableInBundle(@"open in finder title",@"Mediabar",myBundle,@"")];
		[anItem setTag:kMediaBarOpenWithFinder];
		[anItem setTypeIdentifier:[NSNumber numberWithInt:kMenubarItemDefault]];
		[anItem setToolTip:NSLocalizedStringFromTableInBundle(@"open in finder tip",@"Mediabar",myBundle,@"")];
		
		[anItem setTarget:self];
		[anItem setAction:@selector(openInFinder:)];
		
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
					[anItem setToolTip:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"open with tip",@"Mediabar",myBundle,@""), appDisplayName]];
					
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
	return nil;
}

@end

@implementation JournlerMediaContentController (JournlerResourceAdditions)

- (void) showInfoForResource:(JournlerResource*)aResource
{
	ResourceInfoController *infoController = [[[ResourceInfoController alloc] init] autorelease];
	
	[infoController setViewAlignment:ResourceInfoAlignLeft];
	[infoController setResource:aResource];
	
	[[infoController window] center];
	[infoController showWindow:self];
}

@end
