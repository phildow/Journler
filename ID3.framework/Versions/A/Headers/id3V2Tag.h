//
//  id3Tags.h
//  id3Tag
//
//  Created by Chris Drew on Sat Nov 02 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
#ifdef __APPLE__
#import <Foundation/Foundation.h>
#import "id3V2Frame.h"
#else
#ifndef _ID3FRAMEWORK_ID3V2TAG_H_
#define _ID3FRAMEWORK_ID3V2TAG_H_

#include "id3V2Frame.h"
#include <Foundation/NSObject.h>

@class NSMutableDictionary;
#endif
#endif



// Constants for defining size and location of elements within V22 and V23 headers and frames
#define IdLength	4 // length of header id characters


@interface id3V2Tag : NSObject {
    //ID3 tag header variables
    BOOL present;
    BOOL parsed;
    int majorVersion;
    int minorVersion;
    int flag;
    int tagLength;
    int paddingLength;
    int positionInFile;
    int frameSetLength;
    BOOL atStart;
    int	tagChanged;
    
    //Parsing properties
    BOOL exhastiveSearch;
	
	BOOL iTunesV24CompatabilityMode;
    
    //storage for tag
    NSMutableDictionary *frameSet;  // stores the frame set
    NSMutableData * extendedHeader;
    
    //tag contents variables 
    int extendedHeaderPresent; // YES if Tag has an extended header
    
    // file properties
    NSString *path;
    unsigned long long fileSize;
    
    //error variables
    int errorNo;
    NSString *errorDescription;
    
    //frame dictionary 
    NSDictionary *frameSetDictionary;
	
	//iTunes Comment headers
	NSArray * iTunesCommentFields;
}

-(id)initWithFrameDictionary:(NSDictionary *)Dictionary;
-(BOOL)openPath:(NSString *)Path;

-(void)setITunesCompatability:(BOOL)Value;

// information
-(int)tagVersion;
-(BOOL)tagPresent;
-(BOOL)extendedHeader;
-(BOOL)tagUnsynch;
-(BOOL)compressTag;
-(BOOL)footer;

-(BOOL)setExtendedHeader:(BOOL)Flag;
-(BOOL)setTagUnsynch:(BOOL)Flag;
-(BOOL)setCompressTag:(BOOL)Flag;
-(BOOL)setFooter:(BOOL)Flag;

-(BOOL)setPath:(NSString *)Path;

// read ID3 v2 header information
- (int)scanForHeader:(NSData *)Data;
- (BOOL)parseExtendedHeader:(NSData *)Header;
- (NSMutableData *)desynchData:(NSData *)Data offset:(int)Offset;
- (int)tagLength;
- (int)tagPositionInFile;

// id3V2 tag processing
-(BOOL)getTag;
- (int)readPackedLengthFrom:(char *)Bytes;
-(id)getFramesTitled:(NSString *)Name;
-(int)getPaddingLength;
-(NSData *)renderHeader;
-(NSData *)renderExtendedHeader;

// id3V2 tag editing
-(BOOL)dropTag:(BOOL)NewTag;
-(BOOL)newTag:(int)MajorVersion minor:(int)MinorVersion;
-(BOOL)dropFrame:(NSString *)Name frame:(int)index;
-(BOOL)dropFrame:(id3V2Frame *)Frame;
-(BOOL)writeTag;
-(BOOL)addUpdateFrame:(id3V2Frame *)Frame replace:(BOOL)Replace frame:(int)index;
-(BOOL)setFrames:(NSMutableArray *)newFrames;
-(NSData *)writePackedLength:(int)Length;
-(void)dealloc;

// set attributes
-(BOOL)setTitle:(NSString *)Title;
-(BOOL)setArtist:(NSString *)Artist;
-(BOOL)setAlbum:(NSString *)Album;
-(BOOL)setYear:(int)Year;
-(BOOL)setTrack:(int)Track totalTracks:(int)Total;
-(BOOL)setDisk:(int)Disk totalDisks:(int)Total;
-(BOOL)setGenreName:(NSArray *)GenreName;
-(BOOL)setComments:(NSString *)Comment;
-(BOOL)setImages:(NSMutableArray *)Images;
-(BOOL)setEncodedBy:(NSString *)Text;
-(BOOL)setComposer:(NSString *)Text;
-(BOOL)setContent:(NSArray *)Content  forFrame:(NSString *)IDAlias replace:(BOOL)Replace;

// get attributes
-(NSString *)getTitle;
-(NSString *)getArtist;
-(NSString *)getAlbum;
-(int)getYear;
-(int)getTrack;
-(int)getTotalNumberDisks;
-(int)getDisk;
-(int)getTotalNumberTracks;
-(NSArray *)getGenreNames;
-(NSString *)getComments;
-(NSMutableArray *)getImage;
-(NSArray *)frameList;
-(NSString *)getEncodedBy;
-(NSString *)getComposer;
- (NSArray *) getContentForFrameID:(NSString *)ID;

// these are private functions do not use
- (void) getActualFrameID:(NSString **)Name andRecord:(NSDictionary **)Record forID:(NSString *)ID;
-(NSMutableDictionary *)getImageFrom2Frame:(id3V2Frame *)frame;
-(NSMutableDictionary *)getImageFrom3Frame:(id3V2Frame *)frame;
-(NSString *)decodeImageType:(int)encodedValue;
-(id3V2Frame *)getFirstFrameNamed:(NSString *)Name;

-(int)numberInSetString:(NSString *)Set;
-(int)setSizeInSetString:(NSString *)Set;

@end
