//
//  SproutedSnapshot.h
//  Journler
//
//  Created by Phil Dow on 11/6/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <SproutedInterface/SproutedInterface.h>

#import <SproutedAVI/SproutedRecorder.h>

@class CSGCamera;

@interface SproutedSnapshot : SproutedRecorder 
{
	IBOutlet NSImageView *cameraView;
	IBOutlet NSArrayController *photosArrayController;
	
	IBOutlet NSButton *resetButton;
	IBOutlet NSButton *insertButton;
	IBOutlet NSButton *takeButton;
	
	IBOutlet NSTextField *coundownField;
	
	IBOutlet PDPhotoView *photoView;
	
	BOOL capturing;
	CSGCamera *camera;
	
	int currentSlot;
	int slotsTaken;
	NSArray *images;
	NSIndexSet *selectionIndexes;
	
	int countdown;
	NSTimer *snapshotTimer;
	NSTimer *resetTimer;
	
	NSSound *shutterSound;
	NSSound *countdownSound;
}

- (NSArray*) images;
- (void) setImages:(NSArray*)anArray;

- (NSIndexSet*) selectionIndexes;
- (void) setSelectionIndexes:(NSIndexSet*)anIndexSet;

- (IBAction) takeSnapshot:(id)sender;
- (IBAction) reset:(id)sender;
- (IBAction) save:(id)sender;

- (void) _snapshotCountdown:(NSTimer*)aTimer;

@end

@interface NSObject (SproutedSnapshotTarget)

- (void) sproutedSnapshot:(SproutedRecorder*)recorder insertRecording:(NSString*)path title:(NSString*)title;

@end
