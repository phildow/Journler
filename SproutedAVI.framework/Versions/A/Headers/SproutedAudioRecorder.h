/* SproutedAudioRecorder */

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import <ID3/TagAPI.h>
#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>

#import <SproutedAVI/SproutedRecorder.h>

@class SeqGrab;
@class SproutedLAMEInstaller;
@class PDMeteringView;
@class PDMovieSlider;

typedef enum {
	kSproutedAudioSavedToiTunes = 1,
	kSproutedAudioSavedToTemporaryLocation = 2
} SproutedAudioSaveAction;

extern NSString *kSproutedAudioRecordingTitleKey;
extern NSString *kSproutedAudioRecordingAlbumKey;
//extern NSString *kSproutedAudioRecordingPlaylistKey;
extern NSString *kSproutedAudioRecordingDateKey;

@interface SproutedAudioRecorder : SproutedRecorder
{
	// main recording window
	IBOutlet NSTextField			*recTitleField;
	IBOutlet NSTextField			*recArtistField;
	IBOutlet NSTextField			*recAlbumField;
	IBOutlet NSButton				*insertButton;
	IBOutlet NSButton				*recordButton;
	
	IBOutlet	NSTextField			*timeField;
	IBOutlet	NSSlider			*volumeSlider;
	IBOutlet	NSImageView			*volumeImage;
	IBOutlet	QTMovieView			*player;
	IBOutlet	NSButton			*fastforward;
	IBOutlet	NSButton			*rewind;
	IBOutlet	PDMovieSlider		*playbackLocSlider;
	
	//and for the notifications during convert
	IBOutlet NSWindow				*recProgressWin;
	IBOutlet NSTextField			*recProgressText;
	IBOutlet NSProgressIndicator	*recProgress;
	
	IBOutlet NSView *playbackLockHolder;
	IBOutlet NSObjectController		*recorderController;
	
	EventTime			_recordingStart;
	BOOL				_recording;
	BOOL _unsavedRecording;
	
	NSTimer				*mUpdateMeterTimer;
	NSTimer				*idleTimer;
	NSTimer				*updatePlaybackLocTimer;
	
	NSString			*_recordingTitle;	
	NSCalendarDate		*_recordingDate;
	
	NSString			*movPath;
	NSString			*mp3Path;
	
	BOOL				recordingDisabled;
	BOOL				_playingMovie;
	BOOL				_sequenceComponentsClosed;
	
	BOOL convertToMp3;
	NSInteger saveAction;	
}

- (void) setRecordingAttributes:(NSDictionary*)aDictionary;

- (NSString*) recordingTitle;
- (void) setRecordingTitle:(NSString*)title;

- (NSString*) recordingArtist;
- (void) setRecordingArtist:(NSString*)artist;

- (NSString*) recordingAlbum;
- (void) setRecordingAlbum:(NSString*)album;

- (NSCalendarDate*) recordingDate;
- (void) setRecordingDate:(NSCalendarDate*)aDate;

- (BOOL) recordingDisabled;
- (void) setRecordingDisabled:(BOOL)disabled;

- (int) saveAction;
- (void) setPathTitle:(NSString*)aString;

- (NSString*) movPath;
- (void) setMovPath:(NSString*)path;

- (NSString*) mp3Path;
- (void) setMp3Path:(NSString*)path;

- (BOOL) setupRecording;
- (BOOL) takedownRecording;

- (IBAction) recordPause:(id)sender;
- (IBAction) startRecording:(id)sender;

- (IBAction) changePlaybackLocation:(id)sender;
- (IBAction) changePlaybackVolume:(id)sender;
- (IBAction) setChannelGain:(id)sender;

- (void) prepareForPlaying;

- (void) playlockCallback:(id)object;
- (void) movieEnded:(NSNotification*)aNotification;

- (IBAction) fastForward:(id)sender;
- (IBAction) rewind:(id)sender;

- (IBAction) insert:(id)sender;

- (int) tagMP3:(NSString*)path;
- (Component) lameMP3ConverterComponent;

- (BOOL) prepareRecording:(NSString*)path asMovie:(NSString**)savedPath error:(NSError**)anError;
- (BOOL) prepareRecording:(NSString*)path asMP3:(NSString**)savedPath error:(NSError**)anError;
- (BOOL) addRecording:(NSString*)path toiTunes:(NSString**)savedPath error:(NSError**)anError;

- (void) addMovieMetadata:(QTMovie *)aQTMovie;
- (void) setMetadata:(NSDictionary*)metadata userLanguage:(NSString*)language forMovie:(QTMovie*)movie;

- (NSString*) userLanguage;

- (NSImage*) volumeImage:(float)volume minimumVolume:(float)minimum;
- (NSString*) cachesFolder;
- (NSString*) audioCaptureError;

@end

@interface NSObject (SproutedAudioRecorderTarget)

- (void) sproutedAudioRecorder:(SproutedRecorder*)recorder insertRecording:(NSString*)path title:(NSString*)title;

@end
