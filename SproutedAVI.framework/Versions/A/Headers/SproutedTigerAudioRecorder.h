//
//  SproutedTigerAudioRecorder.h
//  Sprouted AVI
//
//  Created by Philip Dow on 5/1/08.
//  Copyright 2008 Lead Developer, Journler Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import <SproutedAVI/SproutedAudioRecorder.h>

@interface SproutedTigerAudioRecorder : SproutedAudioRecorder {
	
	IBOutlet	PDMeteringView		*mMeteringView;
	
	// the quicktime recording items
	SeqGrab				*mGrabber;
	SeqGrabComponent	seqGrab;
	SGChannel			audioChan;
	
	QTMLMutex			mMutex;
	UInt32				mLevelsArraySize;
	Float32 *			mLevelsArray;
	UInt32				mChannelNumber;
	UInt32				mMyIndex;
}

- (BOOL) _addAudioTrack;
- (IBAction) togglePlaythru:(id)sender;
- (OSStatus)setCapturePath:(NSString *)path flags:(long)flags;

- (void) idleTimerCallback:(NSTimer*)timer;
- (void) meterTimerCallback:(NSTimer*)timer;
- (void) updateTimer;
- (void) updateChannelLevel;

@end
