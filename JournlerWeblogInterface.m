//
//  JournlerWeblogInterface.m
//  Journler
//
//  Created by Philip Dow on 11/12/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import "JournlerWeblogInterface.h"
#import "JournlerEntry.h"

// Constants for External Weblog Editor Interface according to http://ranchero.com/netnewswire/developers/externalinterface.php
// We are not using all of them yet, but they might become useful in the future.
const AEKeyword EditDataItemAppleEventClass = 'EBlg';
const AEKeyword EditDataItemAppleEventID = 'oitm';

const AEKeyword DataItemTitle = 'titl';
const AEKeyword DataItemDescription = 'desc';
const AEKeyword DataItemSummary = 'summ';
const AEKeyword DataItemLink = 'link';
const AEKeyword DataItemPermalink = 'plnk';
const AEKeyword DataItemSubject = 'subj';
const AEKeyword DataItemCreator = 'crtr';
const AEKeyword DataItemCommentsURL = 'curl';
const AEKeyword DataItemGUID = 'guid';
const AEKeyword DataItemSourceName = 'snam';
const AEKeyword DataItemSourceHomeURL = 'hurl';
const AEKeyword DataItemSourceFeedURL = 'furl';

NSString *kPDAppleScriptErrorDictionaryScriptSource = @"PDAppleScriptErrorDictionaryScriptSource";

typedef void (*JournlerWeblogInterfaceDidChoosePreferredEditorIMP)(id, SEL, id, int, id);
//- (void) didChoosePreferredEditor:(JournlerWeblogInterface*)weblogInterface returnCode:(int)returnCode editor:(NSString*)filename;

@implementation JournlerWeblogInterface

- (void) dealloc
{
	[weblogEditorIdentifiers release];
	[super dealloc];
}

#pragma mark -

- (NSDictionary*) weblogEditorIdentifiers
{
	return weblogEditorIdentifiers;
}

- (void) setWeblogEditorIdentifiers:(NSDictionary*)aDictionary
{
	if ( weblogEditorIdentifiers != aDictionary )
	{
		[weblogEditorIdentifiers release];
		weblogEditorIdentifiers = [aDictionary copyWithZone:[self zone]];
	}
}

#pragma mark -

- (void) choosePreferredEditor:(id)aDelegate didEndSelector:(SEL)didChooseSelector modalForWindow:(NSWindow*)aWindow
{
	NSOpenPanel *op = [NSOpenPanel openPanel];
	NSArray *types = [NSArray arrayWithObjects:
			@"scpt", @"scptd",
			@"applescript", @"app", 
			@"com.apple.applescript.text", @"com.apple.applescript.script", 
			(NSString*)kUTTypeApplication,nil];

	[op setMessage:NSLocalizedString(@"locate weblog editor",@"")];
	[op setAllowedFileTypes:types];
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSLocalDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
	
	delegate = aDelegate;
	didChooseEditorCallback = didChooseSelector;
	
	[op beginSheetForDirectory:basePath 
			file:nil 
			types:types 
			modalForWindow:aWindow 
			modalDelegate:self 
			didEndSelector:@selector(weblogEditorOpenPanelDidEnd:returnCode:contextInfo:) 
			contextInfo:nil];
}

- (void)weblogEditorOpenPanelDidEnd:(NSOpenPanel *)sheet 
		returnCode:(int)returnCode  
		contextInfo:(void  *)contextInfo
{
	NSString *filename = nil;
	
	if ( returnCode == NSOKButton )
		filename = [sheet filename];
	
	JournlerWeblogInterfaceDidChoosePreferredEditorIMP didChoose;
	didChoose = (JournlerWeblogInterfaceDidChoosePreferredEditorIMP)[delegate methodForSelector:didChooseEditorCallback];
	didChoose(delegate, didChooseEditorCallback, self, returnCode, filename);
}

#pragma mark -

- (BOOL) sendEntries:(NSArray*)theEntries 
		toPreferredEditor:(NSString*)editorFilename 
		options:(int)options error:(id*)anError
{
	// what kind of file do we have at the path?
	BOOL success = NO;
	NSString *uti = [[NSWorkspace sharedWorkspace] UTIForFile:editorFilename];
	
	NSArray *exectuableUTIs = [NSArray arrayWithObjects: @"com.apple.applescript.text", @"com.apple.applescript.script", nil];
	NSArray *executableExtensions = [NSArray arrayWithObjects:@"scpt", @"scptd", nil];
	
	if ( UTTypeConformsTo((CFStringRef)uti, kUTTypeApplication) )
	{
		NSString *appName = [[editorFilename lastPathComponent] stringByDeletingPathExtension];
		NSString *appIdentifier = [[NSBundle bundleWithPath:editorFilename] bundleIdentifier];
		
		if ( [[[self weblogEditorIdentifiers] allValues] containsObject:appName] 
				&& [[[self weblogEditorIdentifiers] allKeysForObject:appName] containsObject:appIdentifier] )
		{
			// this app should support the weblog protocol
			NSLog(@"%s - sending entries using weblog editor protocol: %@", __PRETTY_FUNCTION__, editorFilename);
			success = [self sendEntries:theEntries 
					toWeblogProtocolPreferredEditor:appIdentifier 
					options:options 
					error:anError];
		}
		else
		{
			// regular application
			NSLog(@"%s - sending entries to regular application: %@", __PRETTY_FUNCTION__, editorFilename);
			success = [self sendEntries:theEntries 
					toApplicationPreferredEditor:editorFilename 
					options:options 
					error:anError];
		}
	}
	if ( [[NSWorkspace sharedWorkspace] file:editorFilename confromsToUTIInArray:exectuableUTIs] 
				|| [executableExtensions containsObject:[editorFilename pathExtension]] )
	{
		// applescript
		NSLog(@"%s - sending entries using applescript: %@", __PRETTY_FUNCTION__, editorFilename);
		success = [self sendEntries:theEntries 
				toAppleScriptPreferredEditor:editorFilename 
				options:options 
				error:anError];
	}
	else
	{
		// invalid file type, put up an error
		success = NO;
	}
	
	return success;
}

- (BOOL) sendEntries:(NSArray*)theEntries 
		toWeblogProtocolPreferredEditor:(NSString*)editorBundleIdentifier 
		options:(int)options 
		error:(id*)anError
{
	BOOL success = YES;
	NSString *dummyLink = @"http://remove.this.link/";
	
	// launch the application
	if (![[[[NSWorkspace sharedWorkspace] launchedApplications] valueForKey:@"NSApplicationBundleIdentifier"] containsObject:editorBundleIdentifier])
	{
		[[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:editorBundleIdentifier 
				options:NSWorkspaceLaunchWithoutActivation
				additionalEventParamDescriptor:NULL 
				launchIdentifier:nil];
	}
	
    for ( JournlerEntry *anEntry in theEntries )
	{
		NSAppleEventDescriptor * eventRecord;
		NSAppleEventDescriptor * target;
		NSAppleEventDescriptor * event;
		
		NSString *theContent = nil;
		NSString *theTitle = [anEntry valueForKey:@"title"];
		
		// The record descriptor which will hold the information about the post.
		eventRecord = [NSAppleEventDescriptor recordDescriptor];

		// Setting the target application.
		target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplicationBundleID 
				data:[editorBundleIdentifier 
				dataUsingEncoding:NSUTF8StringEncoding]];

		// The actual Apple Event that will get sent to the target.
		event = [NSAppleEventDescriptor appleEventWithEventClass:EditDataItemAppleEventClass 
				eventID:EditDataItemAppleEventID
				targetDescriptor:target 
				returnID:kAutoGenerateReturnID 
				transactionID:kAnyTransactionID];
		
		// are we sending straight text or html?
		if ( options & kJournlerWeblogInterfaceSendHTML ) theContent = [anEntry valueForKey:@"htmlString"];
		else theContent = [anEntry valueForKey:@"stringValue"];
		
		// Inserting the data about the post we want the target to create.
		[eventRecord setDescriptor:[NSAppleEventDescriptor descriptorWithString:theTitle] forKeyword:DataItemTitle];
		[eventRecord setDescriptor:[NSAppleEventDescriptor descriptorWithString:theContent] forKeyword:DataItemDescription];
		[eventRecord setDescriptor:[NSAppleEventDescriptor descriptorWithString:dummyLink] forKeyword:DataItemLink];
		
		//[eventRecord setDescriptor:[NSAppleEventDescriptor descriptorWithString:[anEntry valueForKeyPath:@"journal.title"]] forKeyword:DataItemCreator];
		//[eventRecord setDescriptor:[NSAppleEventDescriptor descriptorWithString:[anEntry valueForKeyPath:@"journal.title"]] forKeyword:DataItemSourceName];
		//[eventRecord setDescriptor:[NSAppleEventDescriptor descriptorWithString:dummyLink] forKeyword:DataItemSourceHomeURL];
		//[eventRecord setDescriptor:[NSAppleEventDescriptor descriptorWithString:dummyLink] forKeyword:DataItemSourceFeedURL];
		//[eventRecord setDescriptor:[NSAppleEventDescriptor descriptorWithString:[[anEntry valueForKey:@"tagID"] stringValue]] forKeyword:DataItemGUID];
		

		// Add the recordDescriptor whe just created to the actual event.
		[event setDescriptor: eventRecord forKeyword:'----'];

		// Send our Apple Event.
		OSStatus err = AESendMessage([event aeDesc], NULL, kAENoReply | kAEDontReconnect | kAENeverInteract | kAEDontRecord, kAEDefaultTimeout);
		if (err != noErr)
		{
			success = NO;
			anError = nil;
			NSLog(@"Error sending Apple Event: %d", err);
		}
		else
		{
			success = ( success && YES );
		}
	}
	
	return success;
}

- (BOOL) sendEntries:(NSArray*)theEntries 
		toApplicationPreferredEditor:(NSString*)editorFilename 
		options:(int)options 
		error:(id*)anError
{
	BOOL success = YES;
	
    for ( JournlerEntry *anEntry in theEntries )
	{
		NSString *tempDirectory = TempDirectory();
		NSString *filename = [[tempDirectory stringByAppendingPathComponent:[[anEntry pathSafeTitle] 
		stringByAppendingPathExtension:@"rtfd"]] pathWithoutOverwritingSelf];
		
		if ( [anEntry writeToFile:filename as:kEntrySaveAsRTFD flags:0] )
		{
			success = ( [[NSWorkspace sharedWorkspace] openFile:filename withApplication:editorFilename] && success );
		}
		else
		{
			// error
			success = NO;
			*anError = nil;
			NSLog(@"%s - unable to write entry to file at path %@", __PRETTY_FUNCTION__, filename);
		}
	}
	
	return success;
}

- (BOOL) sendEntries:(NSArray*)theEntries 
		toAppleScriptPreferredEditor:(NSString*)editorFilename 
		options:(int)options 
		error:(id*)anError
{
	BOOL success = YES;
	NSDictionary *error = nil;
	
	NSAppleScript *script = [[[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:editorFilename] error:&error] autorelease];
	if ( script == nil )
	{
		success = NO;
		*anError = error;
	}
	else
	{
		NSAppleEventDescriptor *descriptor = [script executeAndReturnError:&error];
		if ( descriptor == nil )
		{
			success = NO;
			NSMutableDictionary *comprehensiveError = [NSMutableDictionary dictionaryWithDictionary:error];
			
			[comprehensiveError setObject:[script richTextSource] forKey:kPDAppleScriptErrorDictionaryScriptSource];
			*anError = comprehensiveError;
		}
		else
		{
			success = YES;
		}
	}
	
	return success;
}

// 11/13/07 5:54:49 PM ecto[28182] *** -[NSCFString stringValue]: unrecognized selector sent to instance 0x1010b0 

@end
