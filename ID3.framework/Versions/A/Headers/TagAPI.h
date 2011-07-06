//
//  TagAPI.h
//  id3Tag
//
//  Created by Chris Drew on Tue Nov 12 2002.
//  Copyright (c) 2002 . All rights reserved.
//

#ifdef __APPLE__
#import <Foundation/Foundation.h>
#import "id3V2Tag.h"
#import "id3V1Tag.h"
#import "id3V2Frame.h"
#import "MP3Header.h"
#else
#ifndef _ID3FRAMEWORK_TAGAPI_H_
#define _ID3FRAMEWORK_TAGAPI_H_
#include <Foundation/NSObject.h>
#include "id3V2Tag.h"
#include "id3V1Tag.h"
#include "id3V2Frame.h"
#include "MP3Header.h"
#endif
#endif


@interface TagAPI : NSObject {
//data dictionary used to store frame and genres information
    NSDictionary *dataDictionary;

 //standard decode variables
    BOOL modify;
    
    NSMutableDictionary *genreDictionary;
    NSMutableDictionary *preferences;
    BOOL externalPreferences;
    BOOL externalDictionary;
    
    id3V2Tag *v2Tag;
    id3V1Tag *v1Tag;
    int parse;
    BOOL parsedV1;

    MP3Header *mp3Header;
    NSString *path;
    NSMutableArray *frameList;
    long int fileSize;

}
// ********** initialise and examine files *********************
-(id)initWithGenreList:(NSMutableDictionary *)Dictionary;
-(BOOL)examineFile:(NSString *)Path;

// depricated function
-(id)initWithPath:(NSString *)Path genreDictionary:(NSMutableDictionary *)Dictionary;

- (void)dealloc;

// *********  methods to get tag data ************************** 
-(NSString *)getTitle;
-(NSString *)getArtist;
-(NSString *)getAlbum;
-(int)getYear;
-(int)getTrack;
-(int)getTotalNumberTracks;
-(int)getDisk;
-(int)getTotalNumberDisks;
-(NSArray *)getGenreNames;
-(NSString *)getComments;
-(NSMutableArray *)getImage;
-(NSString *)getComposer;
-(NSArray *)getGenreList;
-(NSString *)getEncodedBy;

-(void)selectTag:(int)TagVersion; // method use to explicitly set which whether tag (v1 or V2) TagAPI is parsed TagVersion = 1 V1, TagVersion = 2 V2, TagVersion = 0 automode.

-(NSMutableArray *)getFrame:(NSString *)Title;

- (NSArray *) getContentForFrameID:(NSString *)ID;

// ******** methods to get general file and  tag meta-data *****
-(NSArray *)getFrameList;
-(long int)getFileSize;
-(int)getPaddingLength;
-(int)getTagLength;
-(NSString *)getPath;

-(BOOL) tagFound;  // use to determine if a tag (v1 or v2) was found
-(BOOL)v1TagPresent; // use to check if a v1 tag is present (will force the Framework to check for a v1 tag)
-(BOOL)v2TagPresent; // 
-(int)v2TagVersion;

-(NSDictionary *)getFrameDescription:(NSString *)FrameID;

// ******* get mpeg file meta data ****************************
-(int) getDuration;
-(NSString *) getDurationString;
-(int) getBitRate;
-(NSMutableString *) getEncoding;
-(NSString *) getVersionString;
-(NSString *) getLayerString;
-(NSString *) getBitRateString;
-(int) getFrequency;
-(NSString *) getFrequencyString;
-(NSString *) getChannelString;
-(NSData *) getHash;

// ****** set tag data ***************************************
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

-(BOOL)setFrame:(id3V2Frame *)newFrame replace:(BOOL)Replace;
-(BOOL)setFrames:(NSMutableArray *)newFrames;

-(BOOL)setContent:(NSArray *)Content  forFrame:(NSString *)IDAlias;

// ***** update tag in file *********************************
-(int)updateFile;

// ***** create new, copy data between and drop tags *********************
-(BOOL)copyV2TagToV1Tag;
-(BOOL)copyV1TagToV2Tag;
-(BOOL)convertTagToV2:(int)minorversion;
-(BOOL)newTag:(int)Version;
-(BOOL)dropTag:(BOOL)Version;

//these two methods are an ugly hack to allow access to more complex features. I will address this in v2.  use with care...
-(id3V1Tag *)getV1Tag;
-(id3V2Tag *)getV2Tag;

-(BOOL)dropFrame:(id3V2Frame *)Frame;

-(void)releaseAttributes;
-(NSMutableArray *)processGenreArray:(NSArray *)Array;

@end