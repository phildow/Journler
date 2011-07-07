/*
 *  Debug_Macros.h
 *  Journler
 *
 *  Created by Philip Dow on 2/1/07.
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 *
 */

// #include "Debug_Macros.h"

#import <Cocoa/Cocoa.h>
#include <Carbon/Carbon.h>

// #define __DEBUG__

#define LogEntry() NSLog(@"%s - beginning", __PRETTY_FUNCTION__)
#define LogExit() NSLog(@"%s - ending", __PRETTY_FUNCTION__)

#define LogIfDebugging(x,y) if ( [[NSUserDefaults standardUserDefaults] integerForKey:@"DebugLevel"] >= x ) NSLog(y)
#define MethodEntryDescription() [NSString stringWithFormat:@"%s - beginning", __PRETTY_FUNCTION__]
#define MethodExitDescription() [NSString stringWithFormat:@"%s - ending", __PRETTY_FUNCTION__]
