//
//  MP3Header.h
//  ID3
//
//  Created by Chris Drew on Tue Jul 22 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//
#ifdef __APPLE__
#import <Foundation/Foundation.h>
#else
#ifndef _ID3FRAMEWORK_MP3HEADER_H_
#define _ID3FRAMEWORK_MP3HEADER_H_

#include <Foundation/NSObject.h>
#endif
#endif

// defines for MPEG Stream Type
#define MPEG1 1
#define MPEG2 2
#define MPEG25 3
#define RESERVED 0

// defines for MPEG audio Layer
#define LAYERIII 3
#define LAYERII  2
#define LAYERI   1

// defines for channel types
#define STEREO 0
#define JOINTSTEREO 1
#define DUALCHANNEL 2
#define SINGLECHANNEL 3

@interface MP3Header : NSObject {
    NSData * buffer;
    NSData * hash;
    int startFrame;
    int bufferOffsetInFile;
    unsigned long long fileSize;
    
    //MPEG information
    int version;
    int layer;
    int bitRate;
    int frequency;
    int channels;
    int seconds;
    int numberOfFrames;
    BOOL XINGHeaderFound;
}
-(id) init;
-(BOOL) openFile:(NSString *)File withTag:(int)TagLength;
-(void) dealloc;


-(int) getSeconds;
-(NSString *) getSecondsString;
-(int) getVersion;
-(NSString *) getVersionString;
-(int) getLayer;
-(NSString *) getLayerString;
-(int) getBitRate;
-(NSString *) getBitRateString;
-(int) getFrequency;
-(NSString *) getFrequencyString;
-(int) getChannels;
-(NSString *) getChannelString;
-(int) getNumberOfFrames;
-(BOOL) getXINGHeaderFound;
-(NSMutableString *) getEncodingString;
-(NSData *) getHash;

-(int) fileSize;
-(void) releaseAttributes;
-(NSData *) hash;
-(BOOL) findHeader;
-(BOOL) decodeHeader;
@end