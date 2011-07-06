//
//  V20Tag.h
//  id3Tag
//
//  Created by Chris Drew on Thu Jan 16 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#ifdef __APPLE__
#import <Foundation/Foundation.h>
#import "id3V2Frame.h"
#else
#ifndef _ID3FRAMEWORK_V20FRAMESET_H_
#define _ID3FRAMEWORK_V20FRAMESET_H_
#include "id3V2Frame.h"
#include <Foundation/NSObject.h>
@class NSMutableDictionary;
#endif
#endif

#define MAXUNCOMPRESSEDFRAMESIZE 10000000

@interface V20FrameSet : NSObject {
    //ID3 tag header variables
    int minorVersion;
    int tagLength;
    int frameOffset;
    
    int currentFramePosition;
    int currentFrameLength;
    int framesEndAt;
    int padding;
        
    //storage for tag
    NSMutableData *v2Tag;
    unsigned char *Buffer;
    
    //error variables
    int errorNo;
    NSString *errorDescription;
    
    //valid frames
    NSDictionary *validFrames;
	NSCharacterSet *validChars;
}

// information 
-(id)init:(NSMutableData *)Frames version:(int)Minor validFrameSet:(NSDictionary *)FrameSet frameSet:(NSMutableDictionary *)frameSet offset:(int)Offset;
-(NSString *)getFrameID;
-(int)frameLength;
-(int)getFrameSetLength;

// id3V2 tag processing
-(id3V2Frame *)getFrame;
-(BOOL)nextFrame:(BOOL)atStart;
-(BOOL)atValidFrame;

-(void)dealloc;

@end