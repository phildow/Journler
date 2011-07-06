//
//  SproutedLeopardVideoRecorder.h
//  Sprouted AVI
//
//  Created by Philip Dow on 4/30/08.
//  Copyright 2008 Lead Developer, Journler Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTkit.h>
#import <Carbon/Carbon.h>
#import <SproutedAVI/SproutedRecorder.h>

@interface SproutedLeopardVideoRecorder : SproutedRecorder {
	
	IBOutlet QTCaptureView *mCaptureView;
	IBOutlet NSLevelIndicator *mAudioLevelMeter;
	IBOutlet NSSlider *mVolumeSlider;
	IBOutlet NSTextField *mTimeField;
	IBOutlet NSTextField *mSizeField;
	
	IBOutlet NSButton *mRecordPauseButton;
	IBOutlet NSButton *mFastforwardButton;
	IBOutlet NSButton *mRewindButton;
	IBOutlet NSButton *mInsertButton;
	IBOutlet NSImageView *mVolumeImage;
	
	IBOutlet QTMovieView *mPlayer;
	IBOutlet NSView *mPlaybackHolder;
	IBOutlet NSSlider *mPlaybackLocSlider;
    
    QTCaptureSession            *mCaptureSession;
    QTCaptureMovieFileOutput    *mCaptureMovieFileOutput;
    QTCaptureDeviceInput        *mCaptureVideoDeviceInput;
    QTCaptureDeviceInput        *mCaptureAudioDeviceInput;
	
	NSString *mMoviePath;
	NSTimer *mAudioLevelTimer;
	NSTimer *mUpdatePlaybackLocTimer;
	
	BOOL mRecording;
	BOOL mPlayingMovie;
	BOOL mUnsavedRecording;
	
	EventTime mRecordingStart;
}

- (NSString*) videoCaptureError;

- (IBAction) recordPause:(id)sender;
- (IBAction) startRecording:(id)sender;
- (IBAction) stopRecording:(id)sender;

- (IBAction) saveRecording:(id)sender;

- (void) takedownRecording;
- (void) prepareForPlaying;

- (IBAction) changePlaybackVolume:(id)sender;
- (IBAction) changePlaybackLocation:(id)sender;

- (IBAction) fastForward:(id)sender; 
- (IBAction) rewind:(id)sender;

- (void) updateAudioLevels:(NSTimer *)aTimer;
- (void) updateTimeAndSizeDisplay:(NSTimer*)aTimer;

- (NSImage*) volumeImage:(float)volume minimumVolume:(float)minimum;

@end

@interface NSObject (SproutedLeopardVideoRecorderTarget)

- (void) sproutedVideoRecorder:(SproutedRecorder*)recorder insertRecording:(NSString*)path title:(NSString*)title;

@end
