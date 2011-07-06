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
				
				int totalSeconds = (int)(floor([duration floatValue]));
		
				int hours = (int)(floor(totalSeconds / 3600));
				int hoursLeftover = (int)(floor(totalSeconds % 3600));
				
				int minutes = (int)(floor(hoursLeftover / 60 ));
				int seconds = (int)floor(hoursLeftover) % 60;

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
