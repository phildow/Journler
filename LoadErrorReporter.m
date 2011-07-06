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

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if ( [[aTableColumn identifier] isEqualToString:@"objectType"] )
	{
		NSString *typeString = nil;
		switch ( [[[[errorController arrangedObjects] objectAtIndex:rowIndex] objectForKey:@"objectType"] intValue] )
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
		rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(int)row mouseLocation:(NSPoint)mouseLocation 
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
