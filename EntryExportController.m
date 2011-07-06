#import "EntryExportController.h"

@implementation EntryExportController

- (id) init 
{
	if ( self = [super init] ) 
	{
		fileMode = [[NSUserDefaults standardUserDefaults] integerForKey:@"EntryExportMode"];
		dataFormat = [[NSUserDefaults standardUserDefaults] integerForKey:@"EntryExportFormat"];
		includeHeader = [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryExportIncludeHeader"];
		modifiesFileCreationDate = [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryExportSetCreationDate"];
		modifiesFileModifiedDate = [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryExportSetModificationDate"];
		
		[NSBundle loadNibNamed:@"FileExportAccessory" owner:self];
	}
	return self;
}

- (void) dealloc 
{	
	[_contentView release];
	[objectController release];
	
	[super dealloc];
}

- (void) ownerWillClose:(NSNotification*)aNotification
{
	[objectController unbind:@"contentObject"];
	[objectController setContent:nil];
}

#pragma mark -

- (NSView*) contentView 
{ 
	return _contentView; 
}

- (int) dataFormat 
{ 
	return dataFormat;
}

- (void) setDataFormat:(int)format 
{
	dataFormat = format;
	[[NSUserDefaults standardUserDefaults] setInteger:format forKey:@"EntryExportFormat"];
}

- (int) fileMode 
{ 
	return fileMode;
}

- (void) setFileMode:(int)mode 
{
	fileMode = mode;
	[[NSUserDefaults standardUserDefaults] setInteger:mode forKey:@"EntryExportMode"];
}

- (BOOL) includeHeader
{
	return includeHeader;
}

- (void) setIncludeHeader:(BOOL)include
{
	includeHeader = include;
	[[NSUserDefaults standardUserDefaults] setBool:include forKey:@"EntryExportIncludeHeader"];
}

- (BOOL) modifiesFileCreationDate 
{ 
	return modifiesFileCreationDate;
}

- (void) setModifiesFileCreationDate:(BOOL)modifies 
{
	modifiesFileCreationDate = modifies;
	[[NSUserDefaults standardUserDefaults] setBool:modifies forKey:@"EntryExportSetCreationDate"];
}

- (BOOL) modifiesFileModifiedDate
{
	return modifiesFileModifiedDate;
}

- (void) setModifiesFileModifiedDate:(BOOL)modifies
{
	modifiesFileModifiedDate = modifies;
	[[NSUserDefaults standardUserDefaults] setBool:modifies forKey:@"EntryExportSetModificationDate"];
}

#pragma mark -

- (BOOL) updatesFileExtension
{
	return updatesFileExtension;
}

- (void) setUpdatesFileExtension:(BOOL)updates
{
	updatesFileExtension = updates;
	[self changeFileType:[_dataFormat selectedItem]];
}

- (BOOL) choosesFileMode 
{ 
	return [_fileMode isEnabled]; 
}

- (void) setChoosesFileMode:(BOOL)chooses 
{
	[_fileMode setEnabled:chooses];
}

#pragma mark -

- (IBAction) changeFileMode:(id)sender
{
	
}

- (IBAction) changeFileType:(id)sender
{
	// 0 rtf	1 doc	2 rtfd	3 pdf	4 html	5 txt	8 webarchive
	//NSLog(@"%@ %s - %i", [self className], _cmd, [sender tag]);
	
	// do nothing if this is not an actual save panel
	if ( ![[_contentView window] isKindOfClass:[NSSavePanel class]] )
		return;
	
	// if not "together in a single file" then set required type to nil
	if ( ![self fileMode] == 2 )
	{
		[(NSSavePanel*)[_contentView window] setRequiredFileType:nil];
	}
	
	if ( [self updatesFileExtension] )
	{
		NSString *extension = nil;
		int senderTag = [sender tag];
		
		switch ( senderTag )
		{
		case 0:
			extension = @"rtf";
			break;
		case 1:
			extension = @"doc";
			break;
		case 2:
			extension = @"rtfd";
			break;
		case 3:
			extension = @"pdf";
			break;
		case 4:
			extension = @"html";
			break;
		case 5:
			extension = @"txt";
			break;
		case 8:
			extension = @"webarchive";
			break;
		}
		
		// set the required file type
		[(NSSavePanel*)[_contentView window] setRequiredFileType:extension];
		//NSLog(@"%@ %s - %@", [self className], _cmd, extension);
	}
	else
	{
		// nil out the required file type
		[(NSSavePanel*)[_contentView window] setRequiredFileType:nil];
	}
	
	[self setDataFormat:[sender tag]];
	
	// update user defaults
	//int tag = [sender tag];
	//[[NSUserDefaults standardUserDefaults] setInteger:[sender tag] forKey:@"EntryExportFormat"];
}

- (BOOL) commitEditing
{
	BOOL success = [objectController commitEditing];
	if ( !success ) NSLog(@"%@ %s - unable to commit editing", [self className], _cmd);
	return success;
}

@end
