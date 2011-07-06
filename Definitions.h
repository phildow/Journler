/*
 *  Definitions.h
 *  Cocoa Journler
 *
 *  Created by Philip Dow on 12.08.05.
 *  Copyright 2005 __MyCompanyName__. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>
// NSAppleScriptErrorNumber
#define kScriptWasCancelledError	-128

// macros
// ----------------------------------------------------------------------------------

#define defaultBool(x) [[NSUserDefaults standardUserDefaults]boolForKey:x]
#define BeepAndBail() NSBeep(); return
#define BeepAndBoolBail(x) NSBeep(); return x

#define TempDirectory() ( NSTemporaryDirectory() != nil ? NSTemporaryDirectory() : [NSString stringWithString:@"/tmp"] )

#define WebURLsWithTitlesPboardType @"WebURLsWithTitlesPboardType"
#define kMVMessageContentsPboardType @"MVMessageContentsPboardType"

typedef enum {
	kOpenMediaIntoTab = 0,
	kOpenMediaIntoWindow = 1,
	kOpenMediaIntoFinder = 2
} OpenMediaIntoPreference;


// pasteboard defintions
// ----------------------------------------------------------------------------------
#define PDEntryIDPboardType		@"PDEntryIDPboardType"
#define PDFolderIDPboardType	@"PDFolderIDPboardType"
#define PDResourceIDPboardType	@"PDResourceIDPboardType"


#define PDAutosaveNotification	@"PDAutosaveNotification"
