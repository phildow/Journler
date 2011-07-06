//
//  NSWorkspace_PDCategories.h
//  SproutedUtilities
//
//  Created by Philip Dow on 9/9/06.
//  Copyright 2006 Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

static short GetLabelNumber (short flags);
static void SetLabelInFlags (short *flags, short labelNum);
static OSErr FSpGetPBRec(const FSSpec* fileSpec, CInfoPBRec *infoRec);

@interface NSWorkspace (PDCategories)

- (NSString*) UTIForFile:(NSString*)path;
- (NSString*) allParentsForUTI:(NSString*)uti;
- (NSArray*) allParentsAsArrayForUTI:(NSString*)uti;

- (BOOL) file:(NSString*)path conformsToUTI:(NSString*)uti;
- (BOOL) file:(NSString*)path confromsToUTIInArray:(NSArray*)anArray;

- (short) finderLabelColorForFile:(NSString*)inPath;
- (BOOL) setLabel:(short)labelNum forFile:(NSString*)path;

- (BOOL) fileIsVCF:(NSString*)filePath;
- (BOOL) fileIsClipping:(NSString*)filePath;

- (BOOL) moveToTrash:(NSString*)path;
- (NSString*) resolveForAliases:(NSString*)path;
- (BOOL) createAliasForPath:(NSString*)targetPath toPath:(NSString*)destinationPath;

- (NSString*) mdTitleForFile:(NSString*)filename;

- (BOOL) canPlayFile:(NSString*)filename;
- (BOOL) canWatchFile:(NSString*)filename;
- (BOOL) canViewFile:(NSString*)filename;

@end
