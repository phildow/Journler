//
//  NSAlert+JournlerAdditions.h
//  Journler
//
//  Created by Philip Dow on 6/1/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSAlert (JournlerAdditions)

+ (NSAlert*) noSearchIndex;
+ (NSAlert*) overwritePreviousJournal;
+ (NSAlert*) journalFormatPre117;
+ (NSAlert*) criticalLoadError;

+ (NSAlert*) servicesMenuFailure;
+ (NSAlert*) pasteboardImportFailure;
+ (NSAlert*) resourceToEntryError;
+ (NSAlert*) dropboxError;

+ (NSAlert*) pasteboardFolderWarning;
+ (NSAlert*) importError;
+ (NSAlert*) uriError;
+ (NSAlert*) favoriteError;
+ (NSAlert*) saveError;

+ (NSAlert*) wordlistSaveError;
+ (NSAlert*) wordlistCreationError;

+ (NSAlert*) digestCreationError;
+ (NSAlert*) passfileCreationError;
+ (NSAlert*) passfileDeletionError;

+ (NSAlert*) entryExportError;

+ (NSAlert*) noMediaToShow;
+ (NSAlert*) mediaUnreadable;
+ (NSAlert*) nilImageError;

+ (NSAlert*) resourceNotFound;

+ (NSAlert*) iPodNotConnected;
+ (NSAlert*) iPodNoNotes;
+ (NSAlert*) iPodNoJournlerFolder;

+ (NSAlert*) lameInstallRequired;
+ (NSAlert*) lameInstallSuccess;
+ (NSAlert*) lameInstallFailure;

+ (NSAlert*) iWebNotFound;
+ (NSAlert*) badConditions;

+ (NSAlert*) mediaError;
+ (NSAlert*) googleSearchError;

+ (NSAlert*) requestMailPreference;

#pragma mark -

+ (NSAlert*) noVideoCapture;
+ (NSAlert*) noAudioCapture;
+ (NSAlert*) noSnapshotCapture;

#pragma mark -

+ (NSAlert*) confirmEntryDelete;
+ (NSAlert*) confirmResourceDelete;
+ (NSAlert*) confirmFolderDelete;
+ (NSAlert*) confirmEmptyTrash;

#pragma mark -

+ (NSAlert*) upgradeCreateBackupDirectoryFailure;
+ (NSAlert*) upgradeBackupOldEntriesFailure;
+ (NSAlert*) upgradeCreateCollectionsFolderFailure;
+ (NSAlert*) upgradeCreateResourcesFolderFailure;
+ (NSAlert*) upgradeRecreateSearchIndexFailure;
+ (NSAlert*) upgradeEncryptionNoLongerSupported;

#pragma mark -

+ (NSAlert*) liveJournalLogInMessage:(NSString*)message;
+ (NSAlert*) liveJournalException:(NSString*)message;

+ (NSAlert*) bloggerXMLRPCError:(NSString*)title message:(NSString*)message;
+ (NSAlert*) metaweblogXMLRPCError:(NSString*)title message:(NSString*)message;

+ (NSAlert*) blogModeWarning;

@end
