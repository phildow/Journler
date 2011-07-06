//
//  PDMeteringView.h
//  VideoCapturePlugin
//
//  Created by Philip Dow on 1/18/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SproutedAVI/MeteringView.h>

// same as MeteringView, except displayed horizontally

@interface PDMeteringView : MeteringView {
	NSImage *meterImage;
	NSColor *borderColor;
}

- (void) updateMeters: (float *) meterValues;	// takes an array of floats
												// meterValue[0]: db value for channel 0
												// meterValue[1]: db peak for channel 0
												// meterValue[2]: db value for channel 1
												// meterValue[3]: db peak for channel 1 ...etc

@end
