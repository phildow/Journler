/* SproutedVideoRecorder */

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <QuartzCore/QuartzCore.h>
#import <QuickTime/QuickTime.h>
#import <QTKit/QTKit.h>

#import <SproutedAVI/SproutedRecorder.h>

@class PDMeteringView;

typedef struct {
	
	/* general items */
	Movie						outputMovie;					// recorded movie
	SeqGrabComponent			seqGrab;						// sequence grabber
	DataHandler					outputMovieDataHandler;			// movie header storage
	
	/* movie items */
	Media						videoMedia;						// the movie's video track
	SGChannel					videoChan;						// sequence grabber video channel
	
	/* audio items */
	Media						soundMedia;						// the movie's sound track
	SGChannel					audioChan;						// the sequence grabber audio channel
	
	BOOL						recording;						// recording or previewing?
	
	long						length;
	
	CGContextRef				graphicsContext;				// graphics context (window)
	CGColorSpaceRef				colorspace;						// graphics colorspace
	
	CGRect						targetRect;						// target rect within graphics context
	TimeScale					timeScale;
	
	/* deciding to drop a frame */
	Boolean						dropFrame;
	float						mDesiredPreviewFrameRate;
	TimeValue                   mMinPreviewFrameDuration;
	CodecQ						previewQuality;
	
	Boolean						didBeginVideoMediaEdits;
	int							width;
	int							height;
	CodecType					codecType;
	SInt32						averageDataRate;
	
	ICMDecompressionSessionRef	decompressionSession;
	ICMCompressionSessionRef	compressionSession;
	
	Boolean						verbose;
    TimeValue					lastTime;
	int							desiredFramesPerSecond;
	TimeValue					minimumFrameDuration;
    long						frameCount;
    Boolean						isGrabbing;
	
	Boolean						didBeginSoundMediaEdits;
	TimeScale                   audioTimeScale;
	SoundDescriptionHandle      audioDescH;
	AudioStreamBasicDescription asbd;
	
} PDCaptureRecord, *PDCaptureRecordPtr;

@interface SproutedVideoRecorder : SproutedRecorder
{
	
	IBOutlet NSView *previewPlaceholder;
	IBOutlet PDMeteringView *mMeteringView;
	
	IBOutlet NSTextField *timeField;
	IBOutlet NSTextField *sizeField;
	
	IBOutlet NSImageView *volumeImage;
	IBOutlet NSSlider *volumeSlider;
	IBOutlet NSButton *mRecordPauseButton;
	IBOutlet NSSlider *playbackLocSlider;
	
	IBOutlet NSButton *fastforward;
	IBOutlet NSButton *rewind;
	
	IBOutlet NSView *playbackHolder;
	IBOutlet QTMovieView *player;
	
	int							_encodingOption;				// currently supports two: 0 = MPEG4, 1 = H264
	CodecQ						_mPreviewQuality;
	float						_previewFrameRate;
	NSString					*_moviePath;
	
	// for the metering
	NSTimer						*idleTimer;
	NSTimer						*mUpdateMeterTimer;				// will double as a seconds display
	NSTimer						*updatePlaybackLocTimer;
	QTMLMutex                   mMutex;
	
	EventTime					_recordingStart;
	
	BOOL _unsavedRecording;
	BOOL						_playingMovie;
	
	UInt32                      mChannelNumber;
	Float32 *                   mLevelsArray;
	UInt32						mMyIndex;
	UInt32                      mLevelsArraySize;
	
	// data structure passed to sequence grabber callbacks
	PDCaptureRecordPtr	captureData;
	
	BOOL _prepped;
	BOOL _preppedForPlaying;
	
	// changes for the plugin
	IBOutlet NSButton *insertButton;

	BOOL _inserted;
	BOOL _alreadyPrepared;
	
}

- (int) encodingOption;
- (void) setEncodingOption:(int)option;

- (void)setPreviewQuality:(CodecQ)quality;
- (CodecQ)previewQuality;

- (float) previewFrameRate;
- (void) setPreviewFrameRate:(float)rate;

- (NSString*) moviePath;
- (void) setMoviePath:(NSString*)path;


- (BOOL) inserted;
- (BOOL) prepareForRecording;


- (OSErr) _initDataAndProc;
- (OSErr) _prepareCaptureData;
- (OSErr) finishOutputMovie;

- (BOOL)_addVideoTrack;
- (BOOL)_addAudioTrack;

- (void) meterTimerCallback:(id)object;
- (void) updateChannelLevel;

- (IBAction)recordPause:(id)sender;
- (IBAction)stop:(id)sender;

- (BOOL) takedownRecording;

- (IBAction) prepareForPlaying:(id)sender;
- (IBAction) playPause:(id)sender;
- (IBAction) changePlaybackVolume:(id)sender;
- (IBAction) changePlaybackLocation:(id)sender;

- (IBAction) fastForward:(id)sender;
- (IBAction) rewind:(id)sender;

- (void) playlockCallback:(id)object;
	
- (void)idleTimer:(NSTimer*)timer;

- (IBAction)setChannelGain:(id)sender;

- (NSImage*) volumeImage:(float)volume minimumVolume:(float)minimum;

- (IBAction) insertEntry:(id)sender;

- (NSString*) videoCaptureError;

@end

@interface NSObject (SproutedVideoRecorderTarget)

- (void) sproutedVideoRecorder:(SproutedRecorder*)recorder insertRecording:(NSString*)path title:(NSString*)title;

@end
