//
//  SproutedRecorder.h
//  Sprouted AVI
//
//  Created by Philip Dow on 4/23/08.
//  Copyright 2008 Lead Developer, Journler Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *kSproutedAVIFrameworkErrorDomain;
#define kTryingToCloseWhileRecordingError 101
#define kUnsavedRecordingError 102

@class SproutedAVIController;

@interface SproutedRecorder : NSObject {
	IBOutlet NSView *view;
	
	NSString *error;
}

- (id) initWithController:(SproutedAVIController*)controller;

- (NSString*) error;
- (void) setError:(NSString*)anError;

- (NSView*) view;
- (BOOL) warnsWhenUnsavedChanges;

- (NSError*) stillRecordingError;
- (NSError*) unsavedChangesError;

- (BOOL) recorderShouldClose:(NSNotification*)aNotification error:(NSError**)anError;

- (BOOL) recorderWillLoad:(NSNotification*)aNotification;
- (BOOL) recorderDidLoad:(NSNotification*)aNotification;
- (BOOL) recorderWillClose:(NSNotification*)aNotification;
- (BOOL) recorderDidClose:(NSNotification*)aNotification;

- (IBAction) stopRecording:(id)sender;
- (IBAction) saveRecording:(id)sender;

@end
