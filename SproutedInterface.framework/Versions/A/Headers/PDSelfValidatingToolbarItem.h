//
//  PDSelfEnablingToolbarItem.h
//  Journler
//
//  Created by Phil Dow on 12/1/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PDSelfValidatingToolbarItem : NSToolbarItem {
	
	BOOL forcedEnabled;
	BOOL forcedEnabling;
}

- (BOOL) forcedEnabled;
- (void) setForcedEnabled:(BOOL)doEnable;

- (BOOL) forcedEnabling;
- (void) setForcedEnabling:(BOOL)doForce;

@end
