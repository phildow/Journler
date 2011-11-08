
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

#import "MovieViewController.h"
#import "NSAlert+JournlerAdditions.h"

#import <SproutedInterface/SproutedInterface.h>

@implementation MovieViewController

- (id) init 
{
	if ( self = [super init] ) 
	{
		//[NSBundle loadNibNamed:@"MovieFileView" owner:self];
		current_scale = 100;
		
		static NSString *kNibName = @"MovieFileView";
		NSString *kNibName105 = [NSString stringWithFormat:@"%@_105",kNibName];
		
		if ( [[NSBundle mainBundle] respondsToSelector:@selector(executableArchitectures)] 
				&& [[NSBundle mainBundle] pathForResource:kNibName105 ofType:@"nib"] != nil )
			[NSBundle loadNibNamed:kNibName105 owner:self];
		else
			[NSBundle loadNibNamed:kNibName owner:self];
	}
	
	return self;
}

- (void) awakeFromNib 
{
	// remove the arrows from the scale popup
	
	[super awakeFromNib];
		
	[movieContainer setPostsFrameChangedNotifications:YES];
	[[NSNotificationCenter defaultCenter] addObserver:self 
			selector:@selector(movieContainerFrameChanged:) 
			name:NSViewFrameDidChangeNotification 
			object:movieContainer];
		
}

- (void) dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

#pragma mark -

- (BOOL) loadURL:(NSURL*)aURL 
{
	
	NSError *error;
	QTMovie *movie = [QTMovie movieWithURL:aURL error:&error];
	if ( movie == nil ) 
	{
		NSBeep();
		NSLog(@"Unable to load video at path %@, error: %@", aURL, [error localizedDescription]);
		[[NSAlert mediaError] runModal];
		return NO;
	}
	
	NSValue *value = [movie attributeForKey:QTMovieNaturalSizeAttribute];
	if ( value ) 
	{
		NSSize natural_size = [value sizeValue];
		NSSize container_size = [self _containerSizeForMovieSize:natural_size scale:1.0];
		NSSize content_size = [contentView bounds].size;
		
		if ( container_size.width > content_size.width || container_size.height > content_size.height - 66 ) 
		{
			container_size.width = content_size.width;
			container_size.height = content_size.height - 66;
		}
		
		NSRect new_container_frame = 
			NSMakeRect(	floor((content_size.width/2 - container_size.width/2)),
						floor((content_size.height/2 - container_size.height/2)),
						container_size.width, container_size.height );
		
		[movieContainer setFrame:new_container_frame];

	}
	
	[movieView setMovie:movie];
	[movieView gotoBeginning:self];
	
	[contentView setNeedsDisplay:YES];
	
	[super loadURL:aURL];
	return YES;
}

- (void) stopContent 
{
	[movieView pause:self];
}


#pragma mark -

- (NSResponder*) preferredResponder
{
	return movieView;
}

- (void) appropriateFirstResponder:(NSWindow*)window 
{
	[window makeFirstResponder:movieView];
}

- (IBAction) printDocument:(id)sender 
{
	NSPrintingOrientation orientation = NSPortraitOrientation;
	
	NSValue *value = [[movieView movie] attributeForKey:QTMovieNaturalSizeAttribute];
	if ( !value ) 
	{ 
		NSBeep(); return; 
	}
	
	NSSize natural_size = [value sizeValue];
	if ( natural_size.width > natural_size.height ) orientation = NSLandscapeOrientation;
	
	NSPrintInfo *modifiedInfo = [[[NSPrintInfo sharedPrintInfo] copyWithZone:[self zone]] autorelease];
	
	[modifiedInfo setOrientation:orientation];
	
	[modifiedInfo setHorizontalPagination:NSFitPagination];
	[modifiedInfo setVerticalPagination:NSFitPagination];
    [modifiedInfo setHorizontallyCentered:YES];
    [modifiedInfo setVerticallyCentered:YES];
	[[modifiedInfo dictionary] setValue:[NSNumber numberWithBool:NO] forKey:NSPrintHeaderAndFooter];
	
	[[NSPrintOperation printOperationWithView:movieView printInfo:modifiedInfo] runOperation];
}

#pragma mark -

- (BOOL) handlesTextSizeCommand
{
	return YES;
}

- (void) performCustomTextSizeAction:(id)sender
{	
	NSInteger currentIndex = [scalePop indexOfItemWithTag:current_scale];
	
	if ( [sender tag] == 3 )
	{
		if ( currentIndex < 9 )
		{
			[scalePop selectItemAtIndex:[scalePop indexOfItemWithTag:currentIndex+1]];
			[self setScale:[scalePop itemAtIndex:currentIndex+1]];
		}
		else
			NSBeep();
	}
	else if ( [sender tag] == 4 )
	{
		if ( currentIndex > 1 )
		{
			[scalePop selectItemAtIndex:[scalePop indexOfItemWithTag:currentIndex-1]];
			[self setScale:[scalePop itemAtIndex:currentIndex-1]];
		}
		else
			NSBeep();
	}
	else if ( [sender tag] == 99 )
	{
		[scalePop selectItemAtIndex:[scalePop indexOfItemWithTag:100]];
		[self setScale:[scalePop itemAtIndex:[scalePop indexOfItemWithTag:100]]];
	}
}


#pragma mark -

- (IBAction) openWithQuicktime:(id)sender 
{
	static NSString *appQuickTimePlayer = @"QuickTime Player.app";
	if ( [[self URL] isFileURL] )
	{
		[[NSWorkspace sharedWorkspace] openFile:[[self URL] path] withApplication:appQuickTimePlayer];
	}
}

- (IBAction) setScale:(id)sender 
{
	if ( [movieView movie] == nil ) 
	{ 
		NSBeep(); return; 
	}
	
	NSValue *value = [[movieView movie] attributeForKey:QTMovieNaturalSizeAttribute];
	if ( !value ) 
	{ 
		NSBeep(); return; 
	}
	
	NSSize natural_size = [value sizeValue];
	
	float scale = ( sender ? ( [sender tag] / 100.0 ) : 100.0 );
	
	NSSize container_size = [self _containerSizeForMovieSize:natural_size scale:scale];
	NSSize content_size = [contentView bounds].size;
	
	if ( container_size.width > content_size.width || container_size.height > content_size.height - 66 ) 
	{
		container_size.width = content_size.width;
		container_size.height = content_size.height - 66;
	}
	
	NSRect new_container_frame = 
			NSMakeRect(	floor((content_size.width/2 - container_size.width/2)),
						floor((content_size.height/2 - container_size.height/2)),
						container_size.width, container_size.height );
		
	[movieContainer setFrame:new_container_frame];
	[contentView setNeedsDisplay:YES];
	
	current_scale = [sender tag];
}

- (NSSize) _containerSizeForMovieSize:(NSSize)movieSize scale:(float)sizeMultiple 
{
	if ( movieSize.width == 0 && movieSize.height == 0 )
		return NSMakeSize(600,200);
	
	NSSize container_size = movieSize;
	
	container_size.width*=sizeMultiple;
	container_size.height*=sizeMultiple;
	
	container_size.width+=16;
	container_size.height+=34;
	
	floor( container_size.width );
	floor( container_size.height );
	
	// what if the dimensions hide the movie completely?
	//if ( container_size.height < 100 )
	//	container_size.height = 100;
	
	return container_size;
}

- (void) movieContainerFrameChanged:(NSNotification*)aNotification 
{
	NSSize container_size = [movieContainer bounds].size;
	NSSize content_size = [contentView bounds].size;
	
	if ( container_size.width > content_size.width || container_size.height > content_size.height - 66 ) 
	{
		container_size.width = content_size.width;
		container_size.height = content_size.height - 66;
		
		NSRect new_container_frame = 
				NSMakeRect(	floor((content_size.width/2 - container_size.width/2)),
							floor((content_size.height/2 - container_size.height/2)),
							container_size.width, container_size.height );
			
		[movieContainer setFrame:new_container_frame];
		[contentView setNeedsDisplay:YES];
	}
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem 
{
	BOOL enabled = YES;
	NSInteger theTag = [menuItem tag];
	SEL action = [menuItem action];
	
	if ( action == @selector(setScale:) )
	{
		enabled = YES;
		[menuItem setState: ( [menuItem tag] == current_scale ? NSOnState : NSOffState ) ];
	}
	
	else if ( action == @selector(performCustomTextSizeAction:) )
	{
		NSInteger currentIndex = [scalePop indexOfItemWithTag:current_scale];
	
		if ( ( theTag == 3 && currentIndex < 9 ) || ( theTag == 4 && currentIndex > 1 ) || ( theTag == 99 ) )
			enabled = YES;
		else
			enabled = NO;
	}
	
	return enabled;
}

#pragma mark -
#pragma mark The Media Bar

- (BOOL) canCustomizeMediabar:(PDMediaBar*)aMediabar
{
	return YES;
}

- (NSImage*) defaultOpenWithFinderImage:(PDMediaBar*)aMediabar
{
	return BundledImageWithName(@"QTBarSmall.png", @"com.sprouted.interface");
}

- (float) mediabarMinimumWidthForUnmanagedControls:(PDMediaBar*)aMediabar
{
	// leave room for the scale pop
	return 92;
}

- (NSArray*) mediabarDefaultItemIdentifiers:(PDMediaBar *)mediabar
{
	return [NSArray arrayWithObjects:PDMediaBarItemGetInfo, PDMediabarItemShowInFinder, PDMediabarItemOpenWithFinder, nil];
}


@end
