
#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

// NOTE TO SELF: Where is this from?  CocoaTech Open Source I think.
// needed for the PDWeblocFile class, a derivative of CocoaTech open source.

@interface NTResourceFork : NSObject
{
    short fileReference;
}

+ (id)resourceForkForReadingAtURL:(NSURL *)aURL;
+ (id)resourceForkForWritingAtURL:(NSURL *)aURL;
+ (id)resourceForkForReadingAtPath:(NSString *)aPath;
+ (id)resourceForkForWritingAtPath:(NSString *)aPath;

- (id)initForReadingAtURL:(NSURL *)aURL;
- (id)initForWritingAtURL:(NSURL *)aURL;
- (id)initForReadingAtPath:(NSString *)aPath;
- (id)initForWritingAtPath:(NSString *)aPath;
- (id)initForPermission:(char)aPermission AtURL:(NSURL *)aURL;
- (id)initForPermission:(char)aPermission AtPath:(NSString *)aPath;

- (BOOL)addData:(NSData *)aData type:(ResType)aType Id:(short)anID name:(NSString *)aName;
- (NSData *)dataForType:(ResType)aType Id:(short)anID;

    /*
     * string methods handle converting between an NSString and a pascal string
     * as stored in a resource fork
     */
- (BOOL)addString:(NSString *)aString type:(ResType)aType Id:(short)anID name:(NSString *)aName;
- (NSString *)stringForType:(ResType)aType Id:(short)anID;

- (BOOL)removeType:(ResType)aType Id:(short)anID;

@end
