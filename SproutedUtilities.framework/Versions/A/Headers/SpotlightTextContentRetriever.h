//
//  SpotlightTextContentRetriever.h
//  SpotInside
//
//  Created by Masatoshi Nishikata on 06/11/22.
//  Copyright 2006 www.oneriver.jp. All rights reserved.
//
//	http://www.cocoadev.com/index.pl?MDItem
//	http://www.oneriver.jp/

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreFoundation/CFPlugInCOM.h>

@interface SpotlightTextContentRetriever : NSObject {

}

+(void)initialize;
+(BOOL)loadPlugIns;
+(NSArray* )loadedPlugIns;
+(NSArray* )unloadedPlugIns;
+(NSMutableDictionary* )metaDataOfFileAtPath:(NSString*)targetFilePath;
+(NSString* )textContentOfFileAtPath:(NSString*)targetFilePath;
+(NSMutableDictionary*)executeMDImporterAtPath:(NSString*)mdimportPath forPath:(NSString*)path uti:(NSString*)uti;
+(int)OSVersion;
+(NSString*)readTextAtPath:(NSString*)path;

@end