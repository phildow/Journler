//
//  NSNSApplicationAdditions.h
//
//  Created by Cédric Luthi on 13.06.06.
//  Copyright 2006 Cédric Luthi. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSApplication (RelaunchAdditions)

/* Relaunch yourself If the call returns, then the relaunch was not successful. */
- (void)relaunch:(id)sender;

@end
