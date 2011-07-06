//
//  EtchedPopUpButton.h
//  Journler
//
//  Created by Phil Dow on 3/22/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface EtchedPopUpButton : NSPopUpButton {

}

+ (Class)cellClass;
-(void)setShadowColor:(NSColor *)color;

@end
