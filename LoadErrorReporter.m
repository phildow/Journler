
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

#import "LoadErrorReporter.h"

#import "JournlerJournal.h"

#import <SproutedInterface/SproutedInterface.h>
//#import "ImageAndTextCell.h"


@implementation LoadErrorReporter

- (id) initWithJournal:(JournlerJournal*)aJournal errors:(NSArray*)anArray
{
	if ( self = [super initWithWindowNibName:@"LoadErrorReport"] )
	{
		[self setJournal:aJournal];
		[self setErrorInfo:anArray];
		[self retain];
	}
	
	return self;
}

- (void) windowDidLoad
{	
	NSSortDescriptor *kindSort = [[[NSSortDescriptor alloc] initWithKey:@"objectType" ascending:YES selector:@selector(compare:)] autorelease];
	NSSortDescriptor *titleSort = [[[NSSortDescriptor alloc] initWithKey:@"errorString" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] autorelease];
	NSArray *sortDescriptors = [NSArray arrayWithObjects:kindSort, titleSort, nil];
	
	[errorController setSortDescriptors:sortDescriptors];
}

- (void) dealloc
{
	[journal release];
	[errorInfo release];
	[super dealloc];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[errorController unbind:@"contentArray"];
	[errorController setContent:nil];
	[self autorelease];
}

#pragma mark -

- (JournlerJournal*) journal
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

- (NSArray*) errorInfo
{
	return errorInfo;
}

- (void) setErrorInfo:(NSArray*)anArray
{
	if ( errorInfo != anArray )
	{
		[errorInfo release];
		errorInfo = [anArray retain];
	}
}

#pragma mark -

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if ( [[aTableColumn identifier] isEqualToString:@"objectType"] )
	{
		NSString *typeString = nil;
		switch ( [[[[errorController arrangedObjects] objectAtIndex:rowIndex] objectForKey:@"objectType"] integerValue] )
		{
			case 0:
				typeString = @"Entry";
				break;
			case 1:
				typeString = @"Folder";
				break;
			case 2:
				typeString = @"Blog";
				break;
			default:
				typeString = @"Unknown";
				break;
		}
		
		[aCell setStringValue:typeString];
	}
}

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell 
		rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation 
{
	NSDictionary *aReport = [[errorController arrangedObjects] objectAtIndex:row];
	return [[aReport objectForKey:@"localException"] description];
}

#pragma mark -

- (IBAction)showWindow:(id)sender
{
	[NSApp runModalForWindow:[self window]];
}

- (IBAction)dismiss:(id)sender
{
	[NSApp stopModal];
	[[self window] orderOut:sender];
}

- (IBAction) showHelp:(id)sender
{
	NSBeep();
}

@end
