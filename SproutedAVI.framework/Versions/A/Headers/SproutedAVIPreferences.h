//
//  SproutedAVIPreferences.h
//  Sprouted AVI
//
//  Created by Philip Dow on 4/25/08.
//  Copyright 2008 Lead Developer, Journler Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedAVI/SproutedRecorder.h>

@interface SproutedAVIPreferences : SproutedRecorder {
	IBOutlet NSMatrix *audioFormatMatrix;
}

- (IBAction) setAudioFormat:(id)sender;

@end
