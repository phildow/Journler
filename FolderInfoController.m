//
//  FolderInfoController.m
//  Journler
//
//  Created by Philip Dow on 11/1/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import "FolderInfoController.h"

#import "JournlerCollection.h"
#import "JournlerJournal.h"

#import "NSAlert+JournlerAdditions.h"

#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>

/*
#import "LabelPicker.h"
#import "PDGradientView.h"
#import "NSImage_PDCategories.h"
*/

@implementation FolderInfoController

- (id) init
{
	return [self initWithCollection:nil journal:nil];
}

- (id) initWithCollection:(JournlerCollection*)aCollection journal:(JournlerJournal*)aJournal;
{
	if ( self = [super initWithWindowNibName:@"FolderInfo"] )
	{
		collection = [aCollection retain];
		journal = [aJournal retain];
		
		title = [[aCollection valueForKey:@"title"] retain];
		image = [[aCollection valueForKey:@"icon"] retain];
		
		[self retain];
	}
	
	return self;
}

- (void) dealloc
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	[collection release];
	[journal release];
	[title release];
	[image release];
	
	[super dealloc];
}

- (void) windowDidLoad
{
	if ( collection != nil )
		[labelPicker setLabelSelection:[[collection valueForKey:@"label"] intValue]];
	
	int borders[4] = {0,0,0,0};
	[gradient setBordered:NO];
	[gradient setBorders:borders];
	
	[imageGradient setBordered:NO];
	[imageGradient setBorders:borders];
	
	// prepare the images for the buttons
	NSView *aView;
	NSEnumerator *enumerator = [[imageGradient subviews] objectEnumerator];
	
	while ( aView = [enumerator nextObject] )
	{
		if ( [aView isKindOfClass:[NSButton class]] )
			[(NSButton*)aView setImage:[[JournlerCollection defaultImageForID:[aView tag]] imageWithWidth:48 height:48]];
	}
	
}

#pragma mark -

- (void)windowWillClose:(NSNotification *)aNotification 
{
	[objectController unbind:@"contentObject"];
	[objectController setContent:nil];
	
	[self autorelease];
}

#pragma mark -

- (JournlerCollection*)collection
{
	return collection;
}

- (void) setCollection:(JournlerCollection*)aCollection
{
	if ( collection != aCollection )
	{
		[collection release];
		collection = [aCollection retain];
		
		[self setValue:[aCollection valueForKey:@"icon"] forKey:@"image"];
		[self setValue:[aCollection valueForKey:@"title"] forKey:@"title"];
	}
}

- (JournlerJournal*)journal
{
	return journal;
}

- (void) setJournal:(JournlerJournal*)aJournal
{
	if ( journal != aJournal )
	{
		[journal release];
		journal = [aJournal retain];
	}
}

#pragma mark -

- (NSImage*)image
{
	return image;
}

- (void) setImage:(NSImage*)anImage
{
	if ( image != anImage )
	{
		[image release];
		image = [anImage copyWithZone:[self zone]];
	}
}

- (NSString*)title
{
	return title;
}

- (void) setTitle:(NSString*)aString
{
	if ( title != aString )
	{
		[title release];
		title = [aString copyWithZone:[self zone]];
	}
}

- (NSNumber*)label
{
	return [NSNumber numberWithInt:[labelPicker labelSelection]];
}

- (void) setLabel:(NSNumber*)aNumber
{
	[labelPicker setLabelSelection:[aNumber intValue]];
}

#pragma mark -

- (IBAction) okay:(id)sender
{
	if ( ![objectController commitEditing] )
		NSLog(@"%s - unable to commit editing", __PRETTY_FUNCTION__);
	
	[collection setValue:[self valueForKey:@"image"] forKey:@"icon"];
	[collection setValue:[self valueForKey:@"title"] forKey:@"title"];
	[collection setValue:[self valueForKey:@"label"] forKey:@"label"];
	
	[journal saveCollection:collection];
	[[self window] close];
}

- (IBAction) cancel:(id)sender
{
	[[self window] close];
}

- (IBAction) editImage:(id)sender
{
	[imageWindow makeKeyAndOrderFront:sender];
}

- (IBAction) verifyDraggedImage:(id)sender
{
	NSImage *anImage = [sender image];
	NSSize size = [anImage size];
	
	if ( size.height == 128 && size.width == 128 && !(GetCurrentKeyModifiers() & shiftKey ) )
		[self setImage:anImage];
	else
	{
		NSImage *resizedImage = [anImage imageWithWidth:128 height:128 inset:9];
		[self setImage:resizedImage];
	}
}

#pragma mark -

- (IBAction) selectImage:(id)sender
{
	[imageWindow orderOut:sender];
	[self setImage:[JournlerCollection defaultImageForID:[sender tag]]];
}

- (IBAction) searchImage:(id)sender
{
	int result;
	NSArray *fileTypes = [NSImage imageFileTypes];
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
 
    result = [openPanel runModalForDirectory:nil file:nil types:fileTypes];
	
    if (result == NSOKButton) 
	{
        NSString *filename = [openPanel filename];
		NSImage *anImage = [[[NSImage alloc] initWithContentsOfFile:filename] autorelease];
		if ( anImage == nil )
		{
			NSBeep();
			[[NSAlert nilImageError] runModal];
			NSLog(@"%s - unable to initalize image from contents of file %@", __PRETTY_FUNCTION__, filename);
		}
		else
		{
			NSSize size = [anImage size];
			if ( size.height == 128 && size.width == 128 && !(GetCurrentKeyModifiers() & shiftKey ) )
				[self setImage:anImage];
			else
			{
				NSImage *sizedImage = [anImage imageWithWidth:128 height:128 inset:9];
				[self setImage:sizedImage];
			}
		}
	}
	
	[imageWindow orderOut:sender];
}

@end
