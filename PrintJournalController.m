
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
