//
//  EtchedPopUpButtonCell.h
//  Journler
//
//  Created by Phil Dow on 3/22/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface EtchedPopUpButtonCell : NSPopUpButtonCell {
	NSColor *mShadowColor;
}

-(void)setShadowColor:(NSColor *)aColor;

@end
