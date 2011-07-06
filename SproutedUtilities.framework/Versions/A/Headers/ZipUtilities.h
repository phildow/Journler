//
//  ZipUtilities.h
//  Journler
//
//  Created by Philip Dow on 8/21/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ZipUtilities : NSObject {

}

+ (BOOL) zip:(NSString*)targetPath toFile:(NSString*)targetZip;
+ (BOOL) unzipPath:(NSString*)sourcePath toPath:(NSString*)destinationPath;

@end
