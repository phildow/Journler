//
//  SproutedAVIAlerts.h
//  Sprouted AVI
//
//  Created by Philip Dow on 4/22/08.
//  Copyright 2008 Lead Developer, Journler Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSAlert (SproutedAVIAlerts)

+ (NSAlert*) snapshotUnavailable;
+ (NSAlert*) audioRecordingUnavailable;
+ (NSAlert*) videoRecordingUnavailable;

+ (NSAlert*) lameInstallRequired;
+ (NSAlert*) lameInstallSuccess;
+ (NSAlert*) lameInstallFailure;

+ (NSAlert*) unableToStartRecording;
+ (NSAlert*) unableToWriteMP3;

+ (NSAlert*) lameEncoderUnavailable;
+ (NSAlert*) iTunesImportScriptUnavailable;
+ (NSAlert*) unreadableAudioFile;

+ (NSAlert*) unableToStopVideoRecording;
+ (NSAlert*) unreadableVideoFile;

@end
