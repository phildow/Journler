//
//  SproutedLeopardAudioRecorder.h
//  Sprouted AVI
//
//  Created by Philip Dow on 5/1/08.
//  Copyright 2008 Lead Developer, Journler Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTkit.h>
#import <ID3/TagAPI.h>
#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>
#import <SproutedAVI/SproutedAudioRecorder.h>

@class SproutedLAMEInstaller;
@class PDMovieSlider;

@interface SproutedLeopardAudioRecorder : SproutedAudioRecorder {
	
	// in addition to what's provided by the sproutedrecorder
	
	IBOutlet NSLevelIndicator *mAudioLevelMeter;
	IBOutlet NSTextField *sizeField;
	
	// QTKit capture session
	QTCaptureSession *mCaptureSession;
    QTCaptureMovieFileOutput *mCaptureMovieFileOutput;
	QTCaptureDeviceInput *mCaptureAudioDeviceInput;
	
	NSTimer	*mAudioLevelTimer;
}

- (BOOL) setupRecording;
- (BOOL) takedownRecording;
- (void) prepareForPlaying;

// making the recording

- (IBAction) recordPause:(id)sender;
- (IBAction) startRecording:(id)sender;
- (IBAction) setChannelGain:(id)sender;

// playing the recording

- (IBAction) playPause:(id)sender;
- (IBAction) changePlaybackVolume:(id)sender;
- (void) playlockCallback:(NSTimer*)aTimer;

- (IBAction) fastForward:(id)sender;
- (IBAction) rewind:(id)sender;

- (void) updateAudioLevels:(NSTimer *)aTimer;
- (void) updateTimeAndSizeDisplay:(NSTimer*)aTimer;

@end
