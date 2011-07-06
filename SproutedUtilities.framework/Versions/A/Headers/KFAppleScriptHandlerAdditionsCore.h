//
// KFAppleScriptHandlerAdditionsCore.h
// KFAppleScriptHandlerAdditions v. 2.3, 12/31, 2004
//
// Copyright (c) 2003-2004 Ken Ferry. Some rights reserved.
// http://homepage.mac.com/kenferry/software.html
//
// This work is licensed under a Creative Commons license:
// http://creativecommons.org/licenses/by-nc/1.0/
//
// Send me an email if you have any problems (after you've read what there is to read).

#import <Foundation/Foundation.h>

// Name of exception thrown by execute methods below.  
// -[exception userInfo] will retrieve the error dictionary
// from -[NSAppleScript executeAppleEvent:error:].  See the NSAppleScript docs
// for how to use that dictionary.
extern NSString *KFASException;

@interface NSAppleScript (KFAppleScriptHandlerAdditions)

// These four methods make up the recommended API.
// The arguments and returns are standard objective-c objects, not
// (necessarily) apple event descriptors.
// 
// They raise KFASException on AppleScript errors, as described above.

- (id)executeHandler:(NSString *)handlerName;

// raises NSInvalidArgumentException on parameter nil
- (id)executeHandler:(NSString *)handlerName
       withParameter:(id)arg;

- (id)executeHandler:(NSString *)handlerName
      withParameters:(id)firstArg, ...;

- (id)executeHandler:(NSString *)handlerName
withParametersFromArray:(NSArray *)argumentsArray;


// Methods below are for compatibility with KFAppleScriptHandlerAdditions 2.0.
// I'd recommend using the new versions if you're starting a new project.
// The new versions throw exceptions instead of using an error dictionary.
- (id)executeHandler:(NSString *)handlerName
               error:(NSDictionary **)errorInfo;
- (id)executeHandler:(NSString *)handlerName
               error:(NSDictionary **)errorInfo
       withParameter:(id)arg;
- (id)executeHandler:(NSString *)handlerName
               error:(NSDictionary **)errorInfo
      withParameters:(id)firstArg, ...;
- (id)executeHandler:(NSString *)handlerName
               error:(NSDictionary **)errorInfo
withParametersFromArray:(NSArray *)argumentsArray;

@end
