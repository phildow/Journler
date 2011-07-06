//
//  NSNotification_ColloquyAdditions.h
//  Journler
//
//  Created by Phil Dow on 1/19/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//
//	From the Colloquy Source Code: http://colloquy.info/

#import <Cocoa/Cocoa.h>

@interface NSNotificationCenter (NSNotificationCenterAdditions)
- (void) postNotificationOnMainThread:(NSNotification *) notification;
- (void) postNotificationOnMainThread:(NSNotification *) notification waitUntilDone:(BOOL) wait;

- (void) postNotificationOnMainThreadWithName:(NSString *) name object:(id) object;
- (void) postNotificationOnMainThreadWithName:(NSString *) name object:(id) object userInfo:(NSDictionary *) userInfo;
- (void) postNotificationOnMainThreadWithName:(NSString *) name object:(id) object userInfo:(NSDictionary *) userInfo waitUntilDone:(BOOL) wait;
@end

@interface NSNotificationQueue (NSNotificationQueueAdditions)
- (void) enqueueNotificationOnMainThread:(NSNotification *) notification postingStyle:(NSPostingStyle) postingStyle;
- (void) enqueueNotificationOnMainThread:(NSNotification *) notification postingStyle:(NSPostingStyle) postingStyle coalesceMask:(unsigned) coalesceMask forModes:(NSArray *) modes;
@end
