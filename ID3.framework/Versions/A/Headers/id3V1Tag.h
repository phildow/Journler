//
//  id3V1Tag.h
//  id3Tag
//
//  Created by Chris Drew on Mon Nov 18 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
#ifdef __APPLE__
#import <Foundation/Foundation.h>
#else
#ifndef _ID3FRAMEWORK_ID3V1TAG_H_
#define _ID3FRAMEWORK_ID3V1TAG_H_

#include <Foundation/NSObject.h>
@class NSMutableData;
@class NSNumber;
#endif
#endif


@interface id3V1Tag : NSObject {
    //ID3 tag header variables
    int start;
    unsigned long long actualTagLength;
    BOOL present;
    BOOL changed;
    
    //storage for tag
    NSMutableData *tag;
    
    //error variables
    int errorNo;
    NSString *errorDescription;
    
     // file properties
    @public
    NSString *path;
    unsigned long long fileSize;
}

// initilize
-(id)init;
-(BOOL)openPath:(NSString *)Path;
-(void)dealloc;
// information 
-(int)getErrorCode;
-(NSString *)getErrorDescription;
-(BOOL)setError:(int)No reason:(NSString *)Description;
-(void)clearError;
-(BOOL)tagPresent;


// id3 tag processing
-(BOOL)getTag;
-(NSString *)getTitle;
-(NSString *)getArtist;
-(NSString *)getAlbum;
-(int)getYear;
-(NSString *)getComment;
-(int)getTrack;
-(int)getGenre;

// id3V1 tag editing
-(BOOL)newTag;
-(BOOL)writeTag;
-(BOOL)dropTag;
-(BOOL)setTitle:(NSString *)Title;
-(BOOL)setArtist:(NSString *)Artist;
-(BOOL)setAlbum:(NSString *)Album;
-(BOOL)setYear:(int)Year;
-(BOOL)setComment:(NSString *)Comment;
-(BOOL)setTrack:(int)Track;
-(BOOL)setGenre:(int)Genre;

// private functions
-(BOOL)setFieldWithNumber:(int)Number offset:(int)Offset length:(int)Length;
-(BOOL)setFieldWithString:(NSString *)String offset:(int)Offset length:(int)Length;
- (NSString *) getString:(int)Position length:(int)MaxLength;

@end

