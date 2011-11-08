
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

#import "BulkImportController.h"

#import "JournlerJournal.h"
#import "JRLRBulkImport.h"

#import "JournlerEntry.h"
#import "JournlerCollection.h"


//#import "PDGradientView.h"
//#import "JUtility.h"

#import "Definitions.h"

@implementation BulkImportController

- (id)init 
{    
	return [self initWithJournal:nil];
}

- (id) initWithJournal:(JournlerJournal*)aJournal
{
	if ( self = [self initWithWindowNibName:@"BulkImportSheet"] ) 
	{
		//[self window];
		importOptions = [[JRLRBulkImport alloc] initWithJournal:aJournal];
		journal = [aJournal retain];
		importLog = [[NSMutableString alloc] init];
		fm = [[NSFileManager defaultManager] retain];
		
		// all entries to keep track of every entry
		allEntries = [[NSMutableArray alloc] init];
		// the root folders object to preserve the folder structure if requested
		rootFolders = [[NSMutableArray alloc] init];
				
		[self retain];
    }
    return self;
}

- (void) windowDidLoad 
{		
	[optionsPlace addSubview:[importOptions view]];
	[[importOptions view] setFrameOrigin:NSZeroPoint];
	
	NSInteger borders[4] = {0,0,0,0};
	[gradient setBorders:borders];
	[gradient setBordered:NO];

}

- (void) dealloc 
{	
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	[importOptions release];
	[journal release];
	[importLog release];
	[fm release];
	
	[allEntries release];
	[rootFolders release];
	
	[super dealloc];	
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[importOptions ownerWillClose:nil];
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
		[importOptions setJournal:journal];
	}
}

- (BOOL) userInteraction
{
	return _userInteraction; 
}

- (void) setUserInteraction:(BOOL)visual 
{ 
	_userInteraction = visual; 
}

- (void) setTargetCollection:(JournlerCollection*)collection 
{
	[importOptions setTargetCollection:collection];
}

- (JournlerCollection*) targetCollection 
{
	return [importOptions targetCollection];
}

- (void) setTargetDate:(NSCalendarDate*)date 
{
	[importOptions setTargetDate:date];
}

- (BOOL) preserveModificationDate
{
	return [importOptions preserveDateModified];
}

- (void) setPreserveModificationDate:(BOOL)preserve
{

}

#pragma mark -

- (NSInteger) runAsSheetForWindow:(NSWindow*)window attached:(BOOL)sheet 
		files:(NSArray*)filenames folders:(NSArray**)importedFolders entries:(NSArray**)importedEntries;
{
	BOOL dir;
	NSInteger i, result = NSRunStoppedResponse;
	
	if ( _userInteraction ) 
	{
		if ( sheet )
			[NSApp beginSheet:[self window] 
					modalForWindow:window 
					modalDelegate:nil
					didEndSelector:nil 
					contextInfo: nil];
					
		result = [NSApp runModalForWindow: [self window]];
		// Sheet is up here.
	
		if ( result != NSRunStoppedResponse ) 
		{
			if ( sheet ) [NSApp endSheet: [self window]];
			[self close];
			return result;
		}
	}
	
	[importOptions commitEditing];
	
	// depends on selection made in the importer window
	if ( _userInteraction ) 
		datePreference = [importOptions datePreference];
	else 
		datePreference = 99;
	
	if ( _userInteraction ) 
	{
		// this causes a system freeze on a tiny fraction of users
		// it has to do with the progress indicator in the modal window
		// a. calling startAnimation
		// b. calling display on the window
		// c. stopping the modal
		// d. closing the sheet
		
		//NSLog(@"%s - starting progress indicator",__PRETTY_FUNCTION__);
		//[progress setHidden:NO];
		//[progressLabel setHidden:NO];
		//[progress startAnimation:self];
		//NSLog(@"%s - finished starting progress indicator",__PRETTY_FUNCTION__);
		
		//NSLog(@"%s - [[self window] display]",__PRETTY_FUNCTION__);
		//[[self window] display];
		
	}
	
	for ( i = 0; i < [filenames count]; i++ ) 
	{
		NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
		
		NSString *aPath = [filenames objectAtIndex:i];
		
		// do not import invisible files
		NSString *localPath = [aPath lastPathComponent];
		if ( [localPath length] > 0 && [localPath characterAtIndex:0] == '.' )
		{
			[innerPool release];
			continue;
		}
		
		// if the file is a directory but not a package, import its contents as a folder
		if ( ([fm fileExistsAtPath:aPath isDirectory:&dir] && dir) && ![[NSWorkspace sharedWorkspace] isFilePackageAtPath:aPath] ) 
			[self importContentsOfDirectory:aPath targetFolder:nil];
		
		// this is your regular file, attempt to import it
		else 	
			[self importContentsOfFile:aPath targetFolder:nil];
		
		[innerPool release];
	}
	
	// write out the import log
	//[importLog writeToFile:@"/tmp/jrlrbulkimportlog.txt" atomically:NO];
	NSError *error;
	[importLog writeToFile:@"/tmp/jrlrbulkimportlog.txt" atomically:NO encoding:NSUnicodeStringEncoding error:&error];
	
	if ( _userInteraction ) 
	{
		//NSLog(@"%s - [progress stopAnimation:self]",__PRETTY_FUNCTION__);
		//[progress stopAnimation:self];
		
		if (sheet ) [NSApp endSheet: [self window]];
		[self close];
	}
	
	*importedFolders = rootFolders;
	*importedEntries = allEntries;
	
	return result;
}

#pragma mark -

- (BOOL) importContentsOfDirectory:(NSString*)path targetFolder:(JournlerCollection*)parentFolder
{
	// recursively import the contents of a folder at path, creating a journler folder for it
	
	BOOL dir;
	JournlerCollection *aFolder = nil;
	
	if ( _userInteraction && [importOptions preserveFolderStructure] )
	{
		aFolder = [[[JournlerCollection alloc] init] autorelease];
		
		[aFolder setTitle:[fm displayNameAtPath:path]];
		[aFolder setValue:[NSNumber numberWithInteger:PDCollectionTypeIDFolder] forKey:@"typeID"];
		[aFolder setValue:[NSNumber numberWithInteger:[[self journal] newFolderTag]] forKey:@"tagID"];
		[aFolder determineIcon];
		
		if ( parentFolder == nil )
			[rootFolders addObject:aFolder];
		else
			[parentFolder addChild:aFolder];
	}
	
    //DIRECTORY_ENUMERATOR
	NSString *completePath, *aPath;
	NSEnumerator *enumerator = [[fm directoryContentsAtPath:path] objectEnumerator];
	
	while ( aPath = [enumerator nextObject] )
	{
		completePath = [path stringByAppendingPathComponent:aPath];
		
		// do not import invisible files
		NSString *localPath = [aPath lastPathComponent];
		if ( [localPath length] > 0 && [localPath characterAtIndex:0] == '.' )
			continue;
		
		// if the file is a directory, but not a package, perform the recursion
		if ( ([fm fileExistsAtPath:completePath isDirectory:&dir] && dir) && ![[NSWorkspace sharedWorkspace] isFilePackageAtPath:completePath] )
		{
			if ( _userInteraction && [importOptions preserveFolderStructure] )
				[self importContentsOfDirectory:completePath targetFolder:aFolder];
			else
				[self importContentsOfDirectory:completePath targetFolder:parentFolder];
		}
		
		// otherwise try to import the file
		else
		{
			if ( _userInteraction && [importOptions preserveFolderStructure] )
				[self importContentsOfFile:completePath targetFolder:aFolder];
			else
				[self importContentsOfFile:completePath targetFolder:parentFolder];
		}
	}
	
	return YES;
}

- (BOOL) importContentsOfFile:(NSString*)path targetFolder:(JournlerCollection*)parentFolder
{
	// import the entry, adding it to the specified folder
	
	NSInteger entryImportOptions = 0;
	NSInteger kMaxWidth = ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EmbeddedImageUseFullSize"] ? 0
	: [[NSUserDefaults standardUserDefaults] integerForKey:@"EmbeddedImageMaxWidth"] );
	
	NSSize maxPreviewSize = NSMakeSize(kMaxWidth,kMaxWidth);
	
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"NewMediaLinkIncludeIcon"] )
		entryImportOptions |= kEntryImportIncludeIcon;
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryImportSetDefaultResource"] )
		entryImportOptions |= kEntryImportSetDefaultResource;
	
	JournlerEntry *newEntry = [[[JournlerEntry alloc] initWithImportAtPath:path options:entryImportOptions maxPreviewSize:maxPreviewSize] autorelease];
	if ( newEntry != nil ) 
	{
		// success! assign the guy a number, a date, a timestamp, a category, etc
		NSDate *creationDate;
		
		NSString *category = [importOptions category];
		NSArray *tags = [importOptions tags];
		
		NSNumber *theLabel = [importOptions labelValue];
		NSNumber *theMarking = [importOptions marking];
		
		// set a tag
		[newEntry setValue:[NSNumber numberWithInteger:[[self journal] newEntryTag]] forKey:@"tagID"];
		
		// set a category
		if ( [[newEntry category] length] == 0 )
			[newEntry setCategory:category];
		
		// set the keywords
		//if ( [[newEntry keywords] length] == 0 )
		//	[newEntry setKeywords:keywords];
		
		// set the tags
		if ( [[newEntry valueForKey:@"tags"] count] == 0 )
			[newEntry setValue:tags forKey:@"tags"];
		
		// set the label and marking
		if ( [[newEntry label] integerValue] == 0 )
			[newEntry setLabel:theLabel];
		
		[newEntry setMarked:theMarking];
		
		// determine the creation date
		switch ( datePreference ) 
		{
		// file creation date
		case 0:
			creationDate = [[fm fileAttributesAtPath:path traverseLink:YES] objectForKey:NSFileCreationDate];
			break;
		
		// file modification date
		case 1:
			creationDate = [[fm fileAttributesAtPath:path traverseLink:YES] objectForKey:NSFileModificationDate];
			break;
		
		// use preference
		case 2:
			creationDate = [importOptions date];
			break;
		
		// use today's date
		default:
			creationDate = [NSDate date];
			break;
		}
		
		// set the creation date
		[newEntry setCalDate:[creationDate dateWithCalendarFormat:nil timeZone:nil]];
		
		// set the date modified to today's date
		[newEntry setCalDateModified:[NSCalendarDate calendarDate]];
		
		// add the entry to the target folder
		if ( parentFolder != nil )
			[parentFolder addEntry:newEntry];
		
		// add the entry to the all entries array
		[allEntries addObject:newEntry];
		
		// log the import
		[importLog appendString:[NSString stringWithFormat:@"Imported %@\n", path]];
		
		return YES;
	}
	else 
	{
		// unable to import this file, log it
		[importLog appendString:[NSString stringWithFormat:@"Skipped or could not import %@\n", path]];
		return NO;
	}
}

#pragma mark -

- (IBAction)cancel:(id)sender
{
	[NSApp abortModal];
}

- (IBAction)okay:(id)sender
{
	[NSApp stopModal];
}

- (IBAction)help:(id)sender
{
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"JournlerImporting" inBook:@"JournlerHelp"];
}

@end
