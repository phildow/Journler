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
