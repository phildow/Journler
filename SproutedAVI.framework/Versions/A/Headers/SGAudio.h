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
#import <CoreAudioKit/CoreAudioKit.h>

#import <SproutedAVI/SGChan.h>
#import <SproutedAVI/SGAudioSettings.h>


/*___________________________________________________________________________________________
*/

// notifications
extern NSString * SGAudioDeviceListChangedNotification;
extern NSString * SGAudioRecordDeviceDiedNotification;
extern NSString * SGAudioRecordDeviceHoggedChangedNotification;
extern NSString * SGAudioRecordDeviceInUseChangedNotification;
extern NSString * SGAudioRecordDeviceStreamFormatChangedNotification;
extern NSString * SGAudioRecordDeviceStreamFormatListChangedNotification;
extern NSString * SGAudioRecordDeviceInputSelectionNotification;
extern NSString * SGAudioRecordDeviceInputListChangedNotification;
extern NSString * SGAudioPreviewDeviceDiedNotification;
extern NSString * SGAudioPreviewDeviceHoggedChangedNotification;
extern NSString * SGAudioPreviewDeviceInUseChangedNotification;
extern NSString * SGAudioPreviewDeviceStreamFormatChangedNotification;
extern NSString * SGAudioPreviewDeviceStreamFormatListChangedNotification;
extern NSString * SGAudioPreviewDeviceOutputSelectionChangedNotification;
extern NSString * SGAudioPreviewDeviceOutputListChangedNotification;
extern NSString * SGAudioOutputStreamFormatChangedNotification;


/*___________________________________________________________________________________________
*/

#define kMaxFXUnits     6


// this is a Cocoa wrapper for an SGAudioMediaType SGChannel

@interface SGAudio : SGChan {
    SInt32                  mPullUnitIndex;
    AudioBufferList *       mPullBuffer;
    AudioUnit               mFXUnits[kMaxFXUnits];
    UInt32                  mFXUnitsCount;
    BOOL                    mDoInitFXUnits;
	
	SGAudioSettings * settings;
}


- (id)initWithSeqGrab:(SeqGrab*)sg;


- (OSStatus)getPropertyInfoWithClass:(ComponentPropertyClass)theClass
                                    id:(ComponentPropertyID)theID
                                    type:(ComponentValueType*)type
                                    size:(ByteCount*)sz
                                    flags:(UInt32*)flags;

- (OSStatus)getPropertyWithClass:(ComponentPropertyClass)theClass
                                    id:(ComponentPropertyID)theID
                                    size:(ByteCount)sz
                                    address:(ComponentValuePtr)addr
                                    sizeUsed:(ByteCount*)szUsed;
            
- (OSStatus)setPropertyWithClass:(ComponentPropertyClass)theClass
                                    id:(ComponentPropertyID)theID
                                    size:(ByteCount)sz
                                    address:(ConstComponentValuePtr)addr;
                                    
                                    
// convenience functions which use the property methods above
- (NSArray*)deviceList;
- (NSArray*)recordCapableDeviceList;
- (NSArray*)previewCapableDeviceList;

                                    
- (void)notifyOfChangeInPropClass:(ComponentPropertyClass)theClass 
        id:(ComponentPropertyID)theID;

- (OSStatus)showSettingsDialog;

- (NSString*)summaryString;

- (OSType)channelType;
- (BOOL)isVideoChannel;
- (BOOL)isAudioChannel;

- (AudioUnit *)fxUnits;
- (UInt32)fxUnitsCount;

- (NSView*) showSettingsView;
- (void) disablePreview;
- (void) enablePreview;
- (int) previewState;
- (void) setPreviewState:(int)state;

// insert point for 'aufx' audio units
- (AudioUnit)insertAUFXUnit:(ComponentDescription *)fxUnitDesc;
- (BOOL)removeAUFXUnit:(AudioUnit)doomedFXUnit;

- (void) stopMetering;

- (OSStatus)sgAudioCallbackRender:
                (SGAudioCallbackFlags *)ioFlags
                timestamp:(const AudioTimeStamp *)inTimeStamp
                numPackets:(const UInt32 *)inNumberPackets
                buffer:(const AudioBufferList *)inData
                packetDescs:(const AudioStreamPacketDescription*)inPacketDescriptions;
            
                                                            
- (OSStatus)fxUnitRender:(AudioUnitRenderActionFlags *)ioActionFlags
                            timestamp:(const AudioTimeStamp *)inTimeStamp
                            bus:(UInt32)inBusNumber 
                            numFrames:(UInt32)inNumberFrames
                            buffer:(AudioBufferList *)ioData;

@end
