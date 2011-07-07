//
//  NSAlert+JournlerAdditions.m
//  Journler
//
//  Created by Philip Dow on 6/1/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import "NSAlert+JournlerAdditions.h"


@implementation NSAlert (JournlerAdditions)

+ (NSAlert*) noSearchIndex {
	
	NSAlert *alert = [[NSAlert alloc] init];
		
	[alert setMessageText:NSLocalizedStringFromTable(@"no search index msg", 
			@"JAlerts", 
			@"")];
			
	[alert setInformativeText:NSLocalizedStringFromTable(@"no search index info", 
			@"JAlerts", 
			@"")];
	
	[alert addButtonWithTitle:NSLocalizedStringFromTable(@"no search index default", 
			@"JAlerts", 
			@"")];
	
	[alert addButtonWithTitle:NSLocalizedStringFromTable(@"no search index alt", 
			@"JAlerts", 
			@"")];
	
	return [alert autorelease];

}

+ (NSAlert*) overwritePreviousJournal
{
	NSAlert *alert = [[NSAlert alloc] init];
		
	[alert setMessageText:NSLocalizedStringFromTable(@"error create overwrite msg", 
			@"JAlerts", 
			@"")];
		
	[alert setInformativeText:NSLocalizedStringFromTable(@"error create overwrite info", 
			@"JAlerts", 
			@"")];
		
	[alert addButtonWithTitle:NSLocalizedStringFromTable(@"error create overwrite yes", 
			@"JAlerts", 
			@"")];
		
	[alert addButtonWithTitle:NSLocalizedStringFromTable(@"error create overwrite no", 
			@"JAlerts", 
			@"")];
	
	return [alert autorelease];
}

+ (NSAlert*) journalFormatPre117
{
	NSAlert *alert = [[NSAlert alloc] init];
		
	[alert setMessageText:NSLocalizedStringFromTable(@"error pre117 format msg", 
			@"JAlerts", 
			@"")];
	
	[alert setInformativeText:NSLocalizedStringFromTable(@"error pre117 format info", 
			@"JAlerts", 
			@"")];
	
	[alert addButtonWithTitle:NSLocalizedStringFromTable(@"error pre117 format quit", 
			@"JAlerts", 
			@"")];
	
	[alert addButtonWithTitle:NSLocalizedStringFromTable(@"error pre117 format website", 
			@"JAlerts", 
			@"")];
	
	return [alert autorelease];
}

+ (NSAlert*) criticalLoadError
{
	NSAlert *alert = [[NSAlert alloc] init];
		
	[alert setMessageText:NSLocalizedStringFromTable(@"load error msg", 
			@"JAlerts", 
			@"")];
	
	[alert setInformativeText:NSLocalizedStringFromTable(@"load error info", 
			@"JAlerts", 
			@"")];
	
	[alert addButtonWithTitle:NSLocalizedStringFromTable(@"load error locate", 
			@"JAlerts", 
			@"")];
	
	[alert addButtonWithTitle:NSLocalizedStringFromTable(@"load error create", 
			@"JAlerts", 
			@"")];
	
	[alert addButtonWithTitle:NSLocalizedStringFromTable(@"load error quit", 
			@"JAlerts", 
			@"")];
	
	return [alert autorelease];
}

#pragma mark -

+ (NSAlert*) servicesMenuFailure {
	
	NSAlert *alert = [[NSAlert alloc] init];
		
	[alert setMessageText:NSLocalizedStringFromTable(@"services error msg", 
			@"JAlerts", 
			@"")];
			
	[alert setInformativeText:NSLocalizedStringFromTable(@"services error info", 
			@"JAlerts", 
			@"")];
	
	return [alert autorelease];

}

+ (NSAlert*) pasteboardImportFailure
{
	NSAlert *alert = [[NSAlert alloc] init];
		
	[alert setMessageText:NSLocalizedStringFromTable(@"pasteboard import error msg", 
			@"JAlerts", 
			@"")];
			
	[alert setInformativeText:NSLocalizedStringFromTable(@"pasteboard import error info", 
			@"JAlerts", 
			@"")];
	
	return [alert autorelease];

}

+ (NSAlert*) resourceToEntryError
{
	NSAlert *alert = [[NSAlert alloc] init];
		
	[alert setMessageText:NSLocalizedStringFromTable(@"resourcetoentry error msg", 
			@"JAlerts", 
			@"")];
			
	[alert setInformativeText:NSLocalizedStringFromTable(@"resourcetoentry error info", 
			@"JAlerts", 
			@"")];
	
	return [alert autorelease];
}

+ (NSAlert*) dropboxError
{
	NSAlert *alert = [[NSAlert alloc] init];
		
	[alert setMessageText:NSLocalizedStringFromTable(@"dropbox error msg", 
			@"JAlerts", 
			@"")];
			
	[alert setInformativeText:NSLocalizedStringFromTable(@"dropbox error info", 
			@"JAlerts", 
			@"")];
	
	return [alert autorelease];
}

+ (NSAlert*) pasteboardFolderWarning
{
	NSAlert *alert = [[NSAlert alloc] init];
		
	[alert setMessageText:NSLocalizedStringFromTable(@"pasteboard folder warning msg", 
			@"JAlerts", 
			@"")];
	
	[alert setInformativeText:NSLocalizedStringFromTable(@"pasteboard folder warning info", 
			@"JAlerts", 
			@"")];
	
	[alert addButtonWithTitle:NSLocalizedStringFromTable(@"pasteboard folder warning ok", 
			@"JAlerts", 
			@"")];
	
	[alert addButtonWithTitle:NSLocalizedStringFromTable(@"pasteboard folder warning cancel", 
			@"JAlerts", 
			@"")];
	
	return [alert autorelease];

}

+ (NSAlert*) importError
{
	NSAlert *alert = [[NSAlert alloc] init];
		
	[alert setMessageText:NSLocalizedStringFromTable(@"import error msg", 
			@"JAlerts", 
			@"")];
			
	[alert setInformativeText:NSLocalizedStringFromTable(@"import error info", 
			@"JAlerts", 
			@"")];
	
	return [alert autorelease];
}

+ (NSAlert*) uriError
{
	NSAlert *alert = [[NSAlert alloc] init];
		
	[alert setMessageText:NSLocalizedStringFromTable(@"uri error msg", 
			@"JAlerts", 
			@"")];
	
	[alert setInformativeText:NSLocalizedStringFromTable(@"uri error info", 
			@"JAlerts", 
			@"")];
	
	return [alert autorelease];
}

+ (NSAlert*) favoriteError
{
	NSAlert *alert = [[NSAlert alloc] init];
		
	[alert setMessageText:NSLocalizedStringFromTable(@"favorite error msg", 
			@"JAlerts", 
			@"")];
	
	[alert setInformativeText:NSLocalizedStringFromTable(@"favorite error info",
			@"JAlerts", 
			@"")];
	
	return [alert autorelease];
}

+ (NSAlert*) saveError
{
	NSAlert *alert = [[NSAlert alloc] init];
		
	[alert setMessageText:NSLocalizedStringFromTable(@"save error msg", 
			@"JAlerts", 
			@"")];
			
	[alert setInformativeText:NSLocalizedStringFromTable(@"save error info", 
			@"JAlerts", 
			@"")];
	
	return [alert autorelease];
}

#pragma mark -

+ (NSAlert*) wordlistSaveError
{
	NSAlert *alert = [[NSAlert alloc] init];
		
	[alert setMessageText:NSLocalizedStringFromTable(@"wordlist save error msg", 
			@"JAlerts", 
			@"")];
	
	[alert setInformativeText:NSLocalizedStringFromTable(@"wordlist save error info", 
			@"JAlerts", 
			@"")];
	
	return [alert autorelease];
}

+ (NSAlert*) wordlistCreationError
{
	NSAlert *alert = [[NSAlert alloc] init];
		
	[alert setMessageText:NSLocalizedStringFromTable(@"wordlist creation error msg", 
			@"JAlerts", 
			@"")];
	
	[alert setInformativeText:NSLocalizedStringFromTable(@"wordlist creation error info", 
			@"JAlerts", 
			@"")];
	
	return [alert autorelease];
}

#pragma mark -

+ (NSAlert*) digestCreationError
{
	NSAlert *alert = [[NSAlert alloc] init];
		
	[alert setMessageText:NSLocalizedStringFromTable(@"md5digest cannot create msg", 
			@"JAlerts", 
			@"")];
	
	[alert setInformativeText:NSLocalizedStringFromTable(@"md5digest cannot create info", 
			@"JAlerts", 
			@"")];
	
	return [alert autorelease];
}

+ (NSAlert*) passfileCreationError
{
	NSAlert *alert = [[NSAlert alloc] init];
		
	[alert setMessageText:NSLocalizedStringFromTable(@"passfile creation error msg", 
			@"JAlerts", 
			@"")];
	
	[alert setInformativeText:NSLocalizedStringFromTable(@"passfile creation error info", 
			@"JAlerts", 
			@"")];
	
	return [alert autorelease];
}

+ (NSAlert*) passfileDeletionError
{
	NSAlert *alert = [[NSAlert alloc] init];
		
	[alert setMessageText:NSLocalizedStringFromTable(@"passfile deletion error msg", 
			@"JAlerts", 
			@"")];
			
	[alert setInformativeText:NSLocalizedStringFromTable(@"passfile deletion error info", 
			@"JAlerts", 
			@"")];
	
	return [alert autorelease];
}

+ (NSAlert*) resourceNotFound
{
	NSAlert *alert = [[NSAlert alloc] init];
		
	[alert setMessageText:NSLocalizedStringFromTable(@"resource not found msg", 
			@"JAlerts", 
			@"")];
			
	[alert setInformativeText:NSLocalizedStringFromTable(@"resource not found info", 
			@"JAlerts", 
			@"")];
	
	return [alert autorelease];
}

#pragma mark -

+ (NSAlert*) noMediaToShow {
	
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:NSLocalizedStringFromTable(@"no media msg", 
			@"JAlerts", 
			@"")];
			
	[alert setInformativeText:NSLocalizedStringFromTable(@"no media info", 
			@"JAlerts", 
			@"")];
			
	[alert addButtonWithTitle:NSLocalizedStringFromTable(@"no media default",
		@"JAlerts", 
		@"")];

	return [alert autorelease];
	
}

+ (NSAlert*) mediaUnreadable {

	NSAlert *alert = [[NSAlert alloc] init];

	[alert setMessageText:NSLocalizedStringFromTable(@"media unreadable msg", 
			@"JAlerts", 
			@"")];
			
	[alert setInformativeText:NSLocalizedStringFromTable(@"media unreadable info", 
			@"JAlerts", 
			@"")];
		
	return [alert autorelease];
}

#pragma mark -

+ (NSAlert*) requestMailPreference
{
	NSAlert *alert = [[NSAlert alloc] init];

	[alert setMessageText:NSLocalizedStringFromTable(@"mail preference msg", @"JAlerts", @"")];
	[alert setInformativeText:NSLocalizedStringFromTable(@"mail preference info", @"JAlerts", @"")];
		
	[alert addButtonWithTitle:NSLocalizedStringFromTable(@"mail preferece use mail", @"JAlerts", @"")];
	[alert addButtonWithTitle:NSLocalizedStringFromTable(@"mail preference use default", @"JAlerts", @"")];
	
	return [alert autorelease];

}

#pragma mark -

+ (NSAlert*) iPodNotConnected {
	
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:
		NSLocalizedStringFromTable(@"no ipod connected msg", @"JAlerts", @"")];
	[alert setInformativeText:
		NSLocalizedStringFromTable(@"no ipod connected info", @"JAlerts", @"")];

	return [alert autorelease];
	
}

+ (NSAlert*) iPodNoNotes {
	
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:
		NSLocalizedStringFromTable(@"no ipod notes msg", @"JAlerts", @"")];
	[alert setInformativeText:
		NSLocalizedStringFromTable(@"no ipod notes info", @"JAlerts", @"")];

	return [alert autorelease];
	
}

+ (NSAlert*) iPodNoJournlerFolder {
	
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:
		NSLocalizedStringFromTable(@"no ipod journler folder msg", @"JAlerts", @"")];
	[alert setInformativeText:
		NSLocalizedStringFromTable(@"no ipod journler folder info", @"JAlerts", @"")];

	return [alert autorelease];

	
}

+ (NSAlert*) iWebNotFound {
	
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:
		NSLocalizedStringFromTable(@"no iweb msg", @"JAlerts", @"")];
	[alert setInformativeText:
		NSLocalizedStringFromTable(@"no iweb info", @"JAlerts", @"")];

	return [alert autorelease];
	
}

+ (NSAlert*) badConditions {
	
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:
		NSLocalizedStringFromTable(@"bad conditions msg", @"JAlerts", @"")];
	[alert setInformativeText:
		NSLocalizedStringFromTable(@"bad conditions info", @"JAlerts", @"")];

	return [alert autorelease];

}

#pragma mark -

+ (NSAlert*) lameInstallRequired
{
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:NSLocalizedStringFromTable(@"lameinstall required title", @"JAlerts", @"")];
	[alert setInformativeText:NSLocalizedStringFromTable(@"lameinstall required msg", @"JAlerts", @"")];
	[alert addButtonWithTitle:NSLocalizedStringFromTable(@"lameinstall required yes", @"JAlerts", @"")];
	[alert addButtonWithTitle:NSLocalizedStringFromTable(@"lameinstall required no", @"JAlerts", @"")];
	
	return [alert autorelease];
}

+ (NSAlert*) lameInstallSuccess {
	
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:
		NSLocalizedStringFromTable(@"lameinstall success title", @"JAlerts", @"")];
	[alert setInformativeText:
		NSLocalizedStringFromTable(@"lameinstall success msg", @"JAlerts", @"")];

	return [alert autorelease];
	
}

+ (NSAlert*) lameInstallFailure {
	
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:
		NSLocalizedStringFromTable(@"lameinstall failure title", @"JAlerts", @"")];
	[alert setInformativeText:
		NSLocalizedStringFromTable(@"lameinstall failure msg", @"JAlerts", @"")];

	return [alert autorelease];

	
}

#pragma mark -

+ (NSAlert*) noVideoCapture {
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:
		NSLocalizedStringFromTable(@"no video capture msg", @"JAlerts", @"")];
	[alert setInformativeText:
		NSLocalizedStringFromTable(@"no video capture info", @"JAlerts", @"")];

	return [alert autorelease];
}

+ (NSAlert*) noAudioCapture {
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:
		NSLocalizedStringFromTable(@"no audio capture msg", @"JAlerts", @"")];
	[alert setInformativeText:
		NSLocalizedStringFromTable(@"no audio capture info", @"JAlerts", @"")];

	return [alert autorelease];
}

+ (NSAlert*) noSnapshotCapture
{
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:
		NSLocalizedStringFromTable(@"no snapshot capture msg", @"JAlerts", @"")];
	[alert setInformativeText:
		NSLocalizedStringFromTable(@"no snapshot capture info", @"JAlerts", @"")];

	return [alert autorelease];
}

#pragma mark -

+ (NSAlert*) nilImageError
{
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:
		NSLocalizedStringFromTable(@"nil image error msg", @"JAlerts", @"")];
	[alert setInformativeText:
		NSLocalizedStringFromTable(@"nil image error info", @"JAlerts", @"")];

	return [alert autorelease];
}

+ (NSAlert*) mediaError {
	
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:
		NSLocalizedStringFromTable(@"media error msg", @"JAlerts", @"")];
	[alert setInformativeText:
		NSLocalizedStringFromTable(@"media error info", @"JAlerts", @"")];

	return [alert autorelease];
	
}

+ (NSAlert*) googleSearchError {
	
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:
		NSLocalizedStringFromTable(@"google search error msg", @"JAlerts", @"")];
	[alert setInformativeText:
		NSLocalizedStringFromTable(@"google search error info", @"JAlerts", @"")];

	return [alert autorelease];
	
}

+ (NSAlert*) entryExportError
{
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:
		NSLocalizedStringFromTable(@"entry export error msg", @"JAlerts", @"")];
	[alert setInformativeText:
		NSLocalizedStringFromTable(@"entry export error info", @"JAlerts", @"")];

	return [alert autorelease];
}

#pragma mark -

+ (NSAlert*) confirmEntryDelete {
	
	NSAlert *alert = [[NSAlert alloc] init];

	[alert setMessageText:
		NSLocalizedStringFromTable(@"confirm delete multiple msg", @"JAlerts", @"")];
	[alert setInformativeText:
		NSLocalizedStringFromTable(@"confirm delete multiple info", @"JAlerts", @"")];
	[alert addButtonWithTitle:
		NSLocalizedStringFromTable(@"confirm delete multiple yes", @"JAlerts", @"")];
	[alert addButtonWithTitle:
		NSLocalizedStringFromTable(@"confirm delete multiple no", @"JAlerts", @"")];

	return [alert autorelease];
	
}

+ (NSAlert*) confirmResourceDelete
{
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	
	[alert setMessageText:
		NSLocalizedStringFromTable(@"delete resources msg", @"JAlerts", @"")];
	[alert setInformativeText:
		NSLocalizedStringFromTable(@"delete resources info", @"JAlerts", @"")];
	[alert addButtonWithTitle:
		NSLocalizedStringFromTable(@"delete resources yes", @"JAlerts", @"")];
	[alert addButtonWithTitle:
		NSLocalizedStringFromTable(@"delete resources no", @"JAlerts", @"")];
	
	return alert;
}

+ (NSAlert*) confirmFolderDelete
{
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	
	[alert setMessageText:
		NSLocalizedStringFromTable(@"delete folders msg", @"JAlerts", @"")];
	[alert setInformativeText:
		NSLocalizedStringFromTable(@"delete folders info", @"JAlerts", @"")];
	[alert addButtonWithTitle:
		NSLocalizedStringFromTable(@"delete folders yes", @"JAlerts", @"")];
	[alert addButtonWithTitle:
		NSLocalizedStringFromTable(@"delete folders no", @"JAlerts", @"")];
	
	return alert;
}

+ (NSAlert*) confirmEmptyTrash
{
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	
	[alert setMessageText:NSLocalizedStringFromTable(@"empty trash msg", 
			@"JAlerts", 
			@"")];
			
	[alert setInformativeText:NSLocalizedStringFromTable(@"empty trash info", 
			@"JAlerts", 
			@"")];
			
	[alert addButtonWithTitle:NSLocalizedStringFromTable(@"empty trash yes", 
			@"JAlerts", 
			@"")];
			
	[alert addButtonWithTitle:NSLocalizedStringFromTable(@"empty trash no", 
			@"JAlerts", 
			@"")];
	
	return alert;
}

#pragma mark -

+ (NSAlert*) upgradeCreateBackupDirectoryFailure {
	
	NSAlert *alert = [[NSAlert alloc] init];
			
	[alert setMessageText:
			NSLocalizedStringFromTable(@"backup directory no create msg", @"UpgradeController", @"")];
	[alert setInformativeText:
			NSLocalizedStringFromTable(@"backup directory no create info", @"UpgradeController", @"")];
	[alert addButtonWithTitle:
			NSLocalizedStringFromTable(@"backup directory no create default", @"UpgradeController", @"")];
	[alert addButtonWithTitle:
			NSLocalizedStringFromTable(@"backup directory no create alt", @"UpgradeController", @"")];
			
	return [alert autorelease];

}

+ (NSAlert*) upgradeBackupOldEntriesFailure {
	
	NSAlert *alert = [[NSAlert alloc] init];
			
	[alert setMessageText:
			NSLocalizedStringFromTable(@"backup zip fail msg", @"UpgradeController", @"")];
	[alert setInformativeText:
			NSLocalizedStringFromTable(@"backup zip fail info", @"UpgradeController", @"")];
	[alert addButtonWithTitle:
			NSLocalizedStringFromTable(@"backup zip fail default", @"UpgradeController", @"")];
	[alert addButtonWithTitle:
			NSLocalizedStringFromTable(@"backup zip fail alt", @"UpgradeController", @"")];

	return [alert autorelease];
	
}

+ (NSAlert*) upgradeCreateCollectionsFolderFailure 
{	
	NSAlert *alert = [[NSAlert alloc] init];
			
	[alert setAlertStyle:NSCriticalAlertStyle];
	
	[alert setMessageText:
			NSLocalizedStringFromTable(@"collections folder create fail msg", @"UpgradeController", @"")];
	[alert setInformativeText:
			NSLocalizedStringFromTable(@"collections folder create fail info", @"UpgradeController", @"")];
	[alert addButtonWithTitle:
			NSLocalizedStringFromTable(@"collections folder create fail default", @"UpgradeController", @"")];
	
	return [alert autorelease];
	
}

+ (NSAlert*) upgradeCreateResourcesFolderFailure
{
	NSAlert *alert = [[NSAlert alloc] init];
			
	[alert setAlertStyle:NSCriticalAlertStyle];
	
	[alert setMessageText:
			NSLocalizedStringFromTable(@"resources folder create fail msg", @"UpgradeController", @"")];
	[alert setInformativeText:
			NSLocalizedStringFromTable(@"resources folder create fail info", @"UpgradeController", @"")];
	[alert addButtonWithTitle:
			NSLocalizedStringFromTable(@"resources folder create fail default", @"UpgradeController", @"")];
	
	return [alert autorelease];
}

+ (NSAlert*) upgradeRecreateSearchIndexFailure {
	
	NSAlert *alert = [[NSAlert alloc] init];
		
	[alert setMessageText:
			NSLocalizedStringFromTable(@"reset search index fail msg", @"UpgradeController", @"")];
	[alert setInformativeText:
			NSLocalizedStringFromTable(@"reset search index fail info", @"UpgradeController", @"")];
	[alert addButtonWithTitle:
			NSLocalizedStringFromTable(@"reset search index fail default", @"UpgradeController", @"")];
			
	return [alert autorelease];
	
}

+ (NSAlert*) upgradeEncryptionNoLongerSupported
{
	NSAlert *alert = [[NSAlert alloc] init];
			
	[alert setAlertStyle:NSCriticalAlertStyle];
	
	[alert setMessageText:NSLocalizedStringFromTable(@"no encryption support msg", 
			@"UpgradeController", 
			@"")];
			
	[alert setInformativeText:NSLocalizedStringFromTable(@"no encryption support info", 
			@"UpgradeController", 
			@"")];
			
	[alert addButtonWithTitle:NSLocalizedStringFromTable(@"no encryption support default", 
			@"UpgradeController", 
			@"")];
	
	return [alert autorelease];
}

#pragma mark -

+ (NSAlert*) liveJournalLogInMessage:(NSString*)message
{
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:NSLocalizedString(@"server message title", @"")];
	[alert setInformativeText:message];
	
	return [alert autorelease];
}

+ (NSAlert*) liveJournalException:(NSString*)message
{
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:NSLocalizedString(@"livejournal error title", @"")];
	[alert setInformativeText:message];
	
	return [alert autorelease];
}

+ (NSAlert*) bloggerXMLRPCError:(NSString*)title message:(NSString*)message
{
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:title];
	[alert setInformativeText:message];
	
	return [alert autorelease];
}

+ (NSAlert*) metaweblogXMLRPCError:(NSString*)title message:(NSString*)message
{
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:title];
	[alert setInformativeText:message];
	
	return [alert autorelease];
}

+ (NSAlert*) blogModeWarning
{
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:NSLocalizedStringFromTable(@"blogcenter mode warning msg", 
			@"JAlerts", 
			@"")];
			
	[alert setInformativeText:NSLocalizedStringFromTable(@"blogcenter mode warning info", 
			@"JAlerts", 
			@"")];
	
	return [alert autorelease];
}

@end
