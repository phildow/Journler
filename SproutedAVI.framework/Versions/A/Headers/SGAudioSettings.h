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
#import <AudioToolbox/AudioFormat.h>
#import <CoreAudioKit/CoreAudioKit.h>

#import <SproutedAVI/MeteringView.h>

@class SGAudio;
@class NSOpaqueGrayRulerView;

// This is the controller class for the SGAudioChannel settings dialog.
// See the SGAudioSettings.nib file for corresponding UI outlets and actions.

@interface SGAudioSettings : NSObject 
{	
	IBOutlet NSView *				mSettingsView;
   
	IBOutlet NSPopUpButton *		mRecDevicesPopUp;
	IBOutlet NSPopUpButton *		mRecDeviceInputsPopUp;
	IBOutlet NSSlider *				mRecMasterGainSlider;
	IBOutlet NSTextField *			mRecMasterGainText;
	IBOutlet NSButton *				mUseHardwareGainButton;
	IBOutlet NSScrollView *			mRecDeviceChannelsScrollView;
    IBOutlet NSView					*mRecDeviceChannelsContainerView;
    
	IBOutlet NSPopUpButton *		mPrevDevicesPopUp;
	IBOutlet NSPopUpButton *		mPrevDeviceOutputsPopUp;
	IBOutlet NSSlider *				mPrevMasterGainSlider;
	IBOutlet NSTextField *			mPrevMasterGainText;   
	IBOutlet NSButton *				mPreviewWhileRecordingButton; 

	BOOL							mOutputFormatWasSetByUser;

	
	SGAudio *						mChan;
    UserData                        mSavedSettings;
    NSMutableArray *				mRecDeviceChannelStrips;
	
	BOOL							mGrabberWasRecording;
	BOOL							mGrabberWasPreviewing;
	BOOL							mGrabberWasPaused;
	NSTimer *                       mPreviewTimer;
    
}

- (id)initWithSGChan:(SGAudio *)chan;

- (SGAudio *)sgchan;

- (OSStatus)setSGAudioPropertyWithClass:(ComponentPropertyClass)theClass
                                id:(ComponentPropertyID)theID
                                size:(ByteCount)sz
                                address:(ConstComponentValuePtr)addr;
                                
- (NSArray*)recDeviceChannelStrips;


- (IBAction)showPanel:(id)sender;
- (IBAction)closePanel:(id)sender;

- (UInt32)enabledChannelsCount;

- (IBAction)selectRecordDevice:(id)sender;
- (IBAction)selectRecordInput:(id)sender;
- (IBAction)selectRecordDeviceFormat:(id)sender;
- (IBAction)toggleUseHardwareGainControls:(id)sender;
- (IBAction)setRecordMasterGain:(id)sender;

- (IBAction)selectPreviewDevice:(id)sender;
- (IBAction)selectPreviewOutput:(id)sender;
- (IBAction)selectPreviewDeviceFormat:(id)sender;
- (IBAction)toggleHardwarePlaythru:(id)sender;
- (IBAction)togglePlayWhileRecording:(id)sender;
- (IBAction)setPreviewMasterGain:(id)sender;
- (IBAction)setPreviewFlags:(id)sender;

- (IBAction)selectOutputFormat:(id)sender;

- (void)updateRecordDevicesPopUp:(id)sender;
- (void)updateRecordDeviceInputPopUp:(id)sender;
- (void)updateRecordDeviceFormatPopUp:(id)sender;
- (void)updateRecordDeviceMasterGainSlider:(id)sender;
- (void)updateRecordDeviceChannelsBox:(id)sender;
- (void)updateUseHardwareGainControls:(id)sender;
- (void)updatePreviewDevicesPopUp:(id)sender;
- (void)updatePreviewDeviceOutputPopUp:(id)sender;
- (void)updatePreviewDeviceFormatPopUp:(id)sender;
- (void)updatePreviewDeviceMasterGainSlider:(id)sender;
- (void)updatePreviewFlagsPopUp:(id)sender;
- (void)updateHardwarePlaythruButton:(id)sender;
- (void)updatePlayWhileRecordingButton:(id)sender;
- (void)updateOutputFormat;
- (void)updateOutputFormatText:(id)sender;
- (void)updateOutputControls:(id)sender;

- (BOOL)usingHardwareGainControls;

- (void)startChannelPreview;
- (void)stopChannelPreview;

- (NSView*)mSettingsView;
- (void) togglePreview;
- (void) disablePreview;
- (void) enablePreview;
- (int) previewState;
- (void) setPreviewState:(int)state;

- (void) stopMetering;

@end
