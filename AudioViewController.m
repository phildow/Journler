
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

#import "AudioViewController.h"
#import "NSAlert+JournlerAdditions.h"

#import <SproutedInterface/SproutedInterface.h>

@implementation AudioViewController

- (id) init
{	
	if ( self = [super init] )
	{
		[NSBundle loadNibNamed:@"AudioFileView" owner:self];
	}
	
	return self;
}

- (void) dealloc {
		
	[super dealloc];
}

- (void) awakeFromNib {
	
	[super awakeFromNib];
}

#pragma mark -

- (BOOL) loadURL:(NSURL*)aURL {
	
	NSError *error;
	QTMovie *movie = [QTMovie movieWithURL:aURL error:&error];

	if ( movie == nil ) 
	{
		NSLog(@"Unable to load audio at path %@, error: %@", aURL, [error localizedDescription]);
		NSBeep();
		[[NSAlert mediaError] runModal];
		return NO;
	}
	
	[player setMovie:movie];
	[player gotoBeginning:self];
	
	if ( [aURL isFileURL] ) 
	{
		NSString *path = [aURL path];
	
		NSImage *iconImg = [[NSWorkspace sharedWorkspace] iconForFile:path];
		if ( !iconImg )
			iconImg = [NSImage imageNamed:@"NSApplicationIcon"];
		
		[iconImg setSize:NSMakeSize(96,96)];
		[fileIcon setImage:iconImg];
		
		[_locationField setStringValue:path];
		
		// query spotlight for audio information on the file
		MDItemRef spotlightRef = MDItemCreate(NULL,(CFStringRef)path);
		if ( spotlightRef ) 
		{
			NSNumber *sampleRate = (NSNumber*)MDItemCopyAttribute(spotlightRef,kMDItemAudioSampleRate);
			if ( sampleRate ) 
			{
				[_rateField setFloatValue:[sampleRate floatValue]];
				[sampleRate release];
			}
			
			NSString *title = (NSString*)MDItemCopyAttribute(spotlightRef,kMDItemTitle);
			if ( title ) 
			{
				[_titleField setStringValue:title];
				[title release];
			}
			
			NSArray *authors = (NSArray*)MDItemCopyAttribute(spotlightRef,kMDItemAuthors);
			if ( authors ) 
			{
				static NSString *joiner = @", ";
				[_authorsField setStringValue:[authors componentsJoinedByString:joiner]];
				[authors release];
			}
			
			NSNumber *duration = (NSNumber*)MDItemCopyAttribute(spotlightRef,kMDItemDurationSeconds);
			if ( duration ) 
			{
				NSString *durationValue;
				
				NSInteger totalSeconds = (NSInteger)(floor([duration floatValue]));
		
				NSInteger hours = (NSInteger)(floor(totalSeconds / 3600));
				NSInteger hoursLeftover = (NSInteger)(floor(totalSeconds % 3600));
				
				NSInteger minutes = (NSInteger)(floor(hoursLeftover / 60 ));
				NSInteger seconds = (NSInteger)floor(hoursLeftover) % 60;

				if ( hours != 0 )
					durationValue = [NSString stringWithFormat:@"%i%i:%i%i'%i%i",
							hours/10,hours%10,minutes/10,minutes%10,seconds/10,seconds%10];
				else if ( hours == 0 && minutes != 0 )
					durationValue = [NSString stringWithFormat:@"%i%i'%i%i", minutes/10,minutes%10,seconds/10,seconds%10];
				else
					durationValue = [NSString stringWithFormat:@"00'%i%i", seconds/10,seconds%10];
				
				[_durationField setStringValue:durationValue];
				[duration release];
			}
			
			CFRelease(spotlightRef);
		}
	}
		
	[super loadURL:aURL];
	return YES;
}

- (void) stopContent 
{
	[player pause:self];
}

- (NSResponder*) preferredResponder
{
	return player;
}

- (void) appropriateFirstResponder:(NSWindow*)window 
{
	[window makeFirstResponder:player];
}

- (IBAction) printDocument:(id)sender 
{
	NSPrintingOrientation orientation = NSLandscapeOrientation;
	NSPrintInfo *modifiedInfo = [[[NSPrintInfo sharedPrintInfo] copyWithZone:[self zone]] autorelease];
	
	[modifiedInfo setOrientation:orientation];
	
	[modifiedInfo setHorizontalPagination:NSAutoPagination];
	[modifiedInfo setVerticalPagination:NSAutoPagination];
    [modifiedInfo setHorizontallyCentered:YES];
    [modifiedInfo setVerticallyCentered:YES];
	[[modifiedInfo dictionary] setValue:[NSNumber numberWithBool:NO] forKey:NSPrintHeaderAndFooter];
	
	[[NSPrintOperation printOperationWithView:containerView printInfo:modifiedInfo] runOperation];
}

#pragma mark -
#pragma mark The Media Bar

- (BOOL) canCustomizeMediabar:(PDMediaBar*)aMediabar
{
	return YES;
}

- (NSImage*) defaultOpenWithFinderImage:(PDMediaBar*)aMediabar
{
	return BundledImageWithName(@"iTunesBarSmall.png", @"com.sprouted.interface");
}

- (NSArray*) mediabarDefaultItemIdentifiers:(PDMediaBar *)mediabar
{
	return [NSArray arrayWithObjects:PDMediaBarItemGetInfo, PDMediabarItemShowInFinder, PDMediabarItemOpenWithFinder, nil];
}



@end
