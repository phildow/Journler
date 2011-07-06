/*	Copyright: 	© Copyright 2005 Apple Computer, Inc. All rights reserved.

	Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
			("Apple") in consideration of your agreement to the following terms, and your
			use, installation, modification or redistribution of this Apple software
			constitutes acceptance of these terms.  If you do not agree with these terms,
			please do not use, install, modify or redistribute this Apple software.

			In consideration of your agreement to abide by the following terms, and subject
			to these terms, Apple grants you a personal, non-exclusive license, under Apple’s
			copyrights in this original Apple software (the "Apple Software"), to use,
			reproduce, modify and redistribute the Apple Software, with or without
			modifications, in source and/or binary forms; provided that if you redistribute
			the Apple Software in its entirety and without modifications, you must retain
			this notice and the following text and disclaimers in all such redistributions of
			the Apple Software.  Neither the name, trademarks, service marks or logos of
			Apple Computer, Inc. may be used to endorse or promote products derived from the
			Apple Software without specific prior written permission from Apple.  Except as
			expressly stated in this notice, no other rights or licenses, express or implied,
			are granted by Apple herein, including but not limited to any patent rights that
			may be infringed by your derivative works or by other works in which the Apple
			Software may be incorporated.

			The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
			WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
			WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
			PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
			COMBINATION WITH YOUR PRODUCTS.

			IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
			CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
			GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
			ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
			OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
			(INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN
			ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>
#import <CoreAudioKit/CoreAudioKit.h>

@class SGChan;
@class SGAudio;
@class SGSound;

extern NSString * SeqGrabChannelKey;

// following notifications send the SeqGrab * instance as the [notification object], and 
// the SGChan * in question as the value for the one key in the [notification userInfo] dictionary,
// where the key is SeqGrabChannelKey (above)

extern NSString * SeqGrabChannelRemovedNotification; 
extern NSString * SeqGrabChannelAddedNotification;



// this is a Cocoa wrapper for a SeqGrabComponent

@interface SeqGrab : NSObject {
    SeqGrabComponent    mSeqGrab;
	NSMutableArray *	mChans;
    UInt32              mIdlesPerSecond;
    BOOL                mStopRequested;
	
	NSString *			mCapturePath;
	long				mCaptureFlags;
	
    // This Cocoa wrapping of the Sequence Grabber overrides
    // the built in SeqGrab preview behavior - it never calls
    // SGStartPreview.  To accomplish preview, it calls SGStartRecord
    // + SGSetDataRef(dontMakeMovie).  We do this because we are
    // using the SGDataProc to preview video to an NSOpenGLView
    // subclass.  The SGDataProc does not fire when the Sequence Grabber
    // is in preview mode.  We need it to fire when previewing.
    // Since we're overriding preview, we need to keep track of
    // our state independent of the Sequence Grabber's built in
    // machinery (i.e. SGGetMode)
    BOOL				mPreviewing; 
	BOOL				mRecording;
	
    // Before previewing, we have to alter the usage of each channel,
    // so we stow each channel's usage away while previewing, then
    // restore it afterwards.
	NSMutableArray *	mSavedChannelUsages; 
	NSString *			mSavedCapturePath;
	long				mSavedCaptureFlags;
}

- (id)init;

- (NSArray *)channels;	// returns an array of all SGChan's instantiated
- (OSStatus)addChannel:(SGChan*)chan;
- (OSStatus)removeChannel:(SGChan*)chan;


- (SeqGrabComponent)seqGrabComponent;

- (OSStatus)setCapturePath:(NSString*)filePath flags:(long)flags;

- (OSStatus)setSettings:(NSData*)blob;
- (NSData *)settings;

- (void)setIdleFrequency:(UInt32)idlesPerSecond;
- (UInt32)idleFrequency;

- (OSStatus)setMaxRecordTime:(float)seconds;

- (OSStatus)preview;
- (OSStatus)record;
- (OSStatus)stop;
- (OSStatus)pause;
- (OSStatus)resume;

- (BOOL)isStopped;
- (BOOL)isRecording;
- (BOOL)isPreviewing;
- (BOOL)isPaused;

@end
