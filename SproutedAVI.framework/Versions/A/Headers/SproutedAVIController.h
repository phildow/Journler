//
//  SproutedAVIController.h
//  Sprouted AVI
//
//  Created by Philip Dow on 4/23/08.
//  Copyright 2008 Lead Developer, Journler Software. All rights reserved.
//

/*!
	@class SproutedAVIController
	@abstract Means of access to SproutedAVI audio, video and snapshot recording
	@discussion For most uses this is the only class you should need to interact with. 
		The framework handles the details internally. You may want to set a few items
		in the SproutedAudioController such as the recording's title and author.
		Refer to that documentation for more details.
		
		Include SproutedAVI/SproutedAVI.h in your source and then call into the controller as needed
*/

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>
#import <SproutedInterface/SproutedInterface.h>

extern NSString *kExpirationDate;

@class SproutedRecorder;

@interface SproutedAVIController : NSWindowController {
	
	IBOutlet NSView *placeholder;
	IBOutlet PDGradientView *placeholderGradient;
	
	IBOutlet NSImageView *sproutedImageView;
	IBOutlet NSImageView *errorImageView;
	IBOutlet NSTextField *errorField;
	
	NSView *activeView;
	SproutedRecorder *activeRecorder;
	NSString *selectedToolbarItemIdentifier;
	
	id delegate;
	
	NSDictionary *audioRecordingAttributes;
}

/*!
	@function sharedController
	@abstract Provides access to the shared SproutedAVI window controller.
*/

+ (id) sharedController;

/*!
	@function delegate
	@abstract Returns the receiver's delegate.
	@discussion See setDelegate: for more info.
	@result The receiver's delegate.
*/

- (id) delegate;

/*!
	@function setDelegate:
	@abstract Sets the recievers delegate.
	@discussion You must set the receiver's delegate and implement the delegate method
		validateYourself: returning the appropriate object so as to identify yourself
		as a legitimate user of the SproutedAVI framework.
	@param anObject the object that is to become the receiver's delegate.
*/

- (void) setDelegate:(id)anObject;

/*!
	@function setAudioRecordingAttriutes:
	@abstract Set attributes such as title and artist for an audio recording
	@param aDictionary A dictionary of key/value pairs corresponding to the attribute keys and their values.
		See the SproutedAudioRecorder header for more info
*/

- (void) setAudioRecordingAttributes:(NSDictionary*)aDictionary;

/*!
	@function showAVIPreferences:
	@abstract Display's the framework's recording preferences
	@param sender the method's caller.
*/

- (IBAction) showAVIPreferences:(id)sender;

/*!
	@function recordAudio:
	@abstract Activates the audio recorder.
	@discussion Error handling is taken care of internally.
		If the operation fails the framework will notify the user.
	@param sender the method's caller.
*/

- (IBAction) recordAudio:(id)sender;

/*!
	@function recordVideo:
	@abstract Activates the video recorder.
	@discussion Error handling is taken care of internally.
		If the operation fails the framework will notify the user.
	@param sender the method's caller.
*/

- (IBAction) takeSnapshot:(id)sender;

/*!
	@function takeSnapshot:
	@abstract Activates the snapshot
	@discussion Error handling is taken care of internally.
		If the operation fails the framework will notify the user.
	@param sender the method's caller.
*/

- (IBAction) takeSnapshot:(id)sender;

// ------------------------------------

- (void) showError:(NSString*)error;

- (SproutedRecorder*) activeRecorder;
- (void) setActiveRecorder:(SproutedRecorder*)aRecorder;

- (NSString*) selectedToolbarItemIdentifier;
- (void) setSelectedToolbarItemIdentifier:(NSString*)anIdentifier;

- (BOOL) _displayAVIPreferences;
- (BOOL) _displayAudioRecorder;
- (BOOL) _displayVideoRecorder;
- (BOOL) _displayPictureTaker;

- (BOOL) _shouldCloseActiveRecorder:(NSString*)wantedRecorder;

- (NSString*) noSnapshotError;
- (NSString*) noAudioError;
- (NSString*) noVideoError;

- (BOOL) delegateIsValid;
- (BOOL) frameworkHasntExpired;
- (void) _resizeWindowForContentSize:(NSSize)size;

- (void) setupToolbar;

@end

@interface NSObject (SproutedAVIControllerDelegate)

- (NSNumber*) validateYourself:(SproutedAVIController*)aController;

@end
