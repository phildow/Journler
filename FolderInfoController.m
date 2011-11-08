//
//  FolderInfoController.m
//  Journler
//
//  Created by Philip Dow on 11/1/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
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
		[labelPicker setLabelSelection:[[collection valueForKey:@"label"] integerValue]];
	
	NSInteger borders[4] = {0,0,0,0};
	[gradient setBordered:NO];
	[gradient setBorders:borders];
	
	[imageGradient setBordered:NO];
	[imageGradient setBorders:borders];
	
	// prepare the images for the buttons
	
    for ( NSView *aView in [imageGradient subviews] )
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
	return [NSNumber numberWithInteger:[labelPicker labelSelection]];
}

- (void) setLabel:(NSNumber*)aNumber
{
	[labelPicker setLabelSelection:[aNumber integerValue]];
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
	NSInteger result;
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
