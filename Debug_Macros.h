/*
 *  Debug_Macros.h
 *  Journler
 *
 *  Created by Phil Dow on 2/1/07.
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 *
 */

// #include "Debug_Macros.h"

#import <Cocoa/Cocoa.h>
#include <Carbon/Carbon.h>

// #define __DEBUG__

#define LogEntry() NSLog(@"%@ %s - beginning", [self className], _cmd)
#define LogExit() NSLog(@"%@ %s - ending", [self className], _cmd)

#define LogIfDebugging(x,y) if ( [[NSUserDefaults standardUserDefaults] integerForKey:@"DebugLevel"] >= x ) NSLog(y)
#define MethodEntryDescription() [NSString stringWithFormat:@"%@ %s - beginning", [self className], _cmd]
#define MethodExitDescription() [NSString stringWithFormat:@"%@ %s - ending", [self className], _cmd]
