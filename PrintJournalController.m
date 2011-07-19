#import "PrintJournalController.h"

@implementation PrintJournalController

- (id) init {
	
	if ( self = [self initWithWindowNibName:@"PrintJournalWindow"] ) {
	
	}
	return self;
}

- (void) dealloc {
	[super dealloc];
}

- (void) windowDidLoad {
	[_dateFrom setDateValue:[NSDate date]];
	[_dateTo setDateValue:[NSDate date]];
}

- (void)windowWillClose:(NSNotification *)aNotification {
	if ( [NSApp modalWindow] == [self window] ) [NSApp abortModal];
}

- (NSInteger) runAsSheetForWindow:(NSWindow*)window attached:(BOOL)sheet {
	
	NSInteger result;

	if ( sheet )
		[NSApp beginSheet:[self window] modalForWindow:window modalDelegate:nil
				didEndSelector:nil contextInfo:nil];
	
    result = [NSApp runModalForWindow:[self window]];
	
	if ( sheet )
		[NSApp endSheet: [self window]];
		
   [self close];
	return result;
	
}

#pragma mark -

- (NSDate*) dateFrom { return [_dateFrom dateValue]; }

- (void) setDateFrom:(NSDate*)date {
	[_dateFrom setDateValue:date];
}

- (NSDate*) dateTo { return [_dateTo dateValue]; }

- (void) setDateTo:(NSDate*)date {
	[_dateTo setDateValue:date];
}

- (NSInteger) printMode {
	return [[_printMode selectedCell] tag];
}

#pragma mark -

- (IBAction)cancelPrint:(id)sender
{
	[NSApp abortModal];
}

- (IBAction)changeMode:(id)sender
{
	if ( [[sender selectedCell] tag] == kPrintModeText )
		[_modeImageView setImage:[NSImage imageNamed:@"TextOnly.png"]];
	else if ( [[sender selectedCell] tag] == kPrintModeTextAndImages )
		[_modeImageView setImage:[NSImage imageNamed:@"TextAndPictures.png"]];
}

- (IBAction)continuePrint:(id)sender
{
	[NSApp stopModal];
}

@end
