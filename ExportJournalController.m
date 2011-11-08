
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

#import "ExportJournalController.h"

@implementation ExportJournalController

- (id) init 
{
	if ( self = [super init] ) 
	{
		[NSBundle loadNibNamed:@"JournalExportAccessory" owner:self];
	}
	return self;
}

- (void) awakeFromNib 
{
	//[_dateFrom setDateValue:[NSDate date]];
	//[_dateTo setDateValue:[NSDate date]];
}

- (void) dealloc 
{
	[_contentView release];
	_contentView = nil;
	
	[super dealloc];
}

#pragma mark -

- (NSView*) contentView 
{ 
	return _contentView; 
}

- (NSInteger) dataFormat 
{ 
	return [[_dataFormat selectedItem] tag];
}

- (void) setDataFormat:(NSInteger)format 
{
	[_dataFormat selectItemWithTag:format];
}

- (NSDate*) dateFrom 
{ 
	return [_dateFrom dateValue]; 
}

- (void) setDateFrom:(NSDate*)date 
{
	[_dateFrom setDateValue:date];
}

- (NSDate*) dateTo 
{ 
	return [_dateTo dateValue]; 
}

- (void) setDateTo:(NSDate*)date 
{
	[_dateTo setDateValue:date];
}

- (NSInteger) fileMode 
{ 
	return [[_fileMode selectedCell] tag]; 
}

- (void) setFileMode:(NSInteger)mode 
{
	[_fileMode selectCellWithTag:mode];
}

- (BOOL) modifiesFileCreationDate 
{ 
	return ( [_modifiesFileCreation state] == NSOnState ); 
}

- (void) setModifiesFileCreationDate:(BOOL)modifies 
{
	[_modifiesFileCreation setState:( modifies ? NSOnState : NSOffState )];
}

- (BOOL) modifiesFileModifiedDate
{
	return ( [_modifiesFileModified state] == NSOnState );
}

- (void) setModifiesFileModifiedDate:(BOOL)modifies
{
	[_modifiesFileModified setState:( modifies ? NSOnState : NSOffState )];
}

- (BOOL) includeHeader
{
	return ( [_includeHeaderCheck state] == NSOnState );
}

- (void) setIncludeHeader:(BOOL)include
{
	[_includeHeaderCheck setState:( include ? NSOnState : NSOffState )];
}

@end
