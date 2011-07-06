//
// KFASHanderAdditions-TypeTranslation.h
// KFAppleScriptHandlerAdditions v. 2.3, 12/31, 2004
//
// Copyright (c) 2003-2004 Ken Ferry. Some rights reserved.
// http://homepage.mac.com/kenferry/software.html
//
// This work is licensed under a Creative Commons license:
// http://creativecommons.org/licenses/by-nc/1.0/
//

// This file deals with converting ObjC objects to AppleScript objects and back.
// The methods here are called automatically by 
// -[NSAppleScript executeHandler:error:withParameters:] and friends to translate
// parameters and returns.  
//
// This means that you don't need to pay attention to this file unless,
// a) you need/want to know details about how and what ObjC and AS objects are converted, or
// b) you want to add automatic conversion of an object that isn't already covered.
//
// To partially answer a), we try to conform to the behavior of Cocoa's built in translation
// (which we can't access, at least through public methods).  This behavior is documented
// in Apple's CocoaScripting release note.  Especially note the behavior 
// as regards NSDictionaries/records (if you plan to use it).
//
// Here's an overview of what's going on in this file.
//
// OBJC -> AS:
//    -[NSObject aeDescriptorValue] converts ObjC objects to
//    AS objects (i.e. instances of NSAppleEventDescriptor).  It's overridden 
//    as appropriate, and you can override it in your classes to provide automatic
//    translation of your objects when using -[NSAppleScript executeHandler:error:withParameters:].
//    All of the overrides, as well as the NSObject implementation, are described below.
//
// AS -> OBJC
//    -[NSAppleEventDescriptor objCObjectValue] is the method that converts AS objects to
//    ObjC objects.  However, none of the work is actually done in that method.  Rather,
//    helper objects claim types they want to translate with 
//    +[NSAppleEventDescriptor registerConversionHandler:selector:forDescriptorTypes:].
//    A number of default conversion methods are defined in this file and registered
//    automatically.  These are listed below, with descriptions where there's something to say.
//    For example, +[NSString stringWithAEDesc:] is such a method.
//    See +[NSAppleEventDescriptor registerConversionHandler:selector:forDescriptorTypes:] for
//    the list of descriptor type codes that are handled by default.


#import <Foundation/Foundation.h>


// A 'collection' (responds to -objectEnumerator) is translated to an AS list.
// For any other  object obj, this returns [[obj description] aeDescriptorValue], mainly
// intended for debugging purposes.
@interface NSObject (KFAppleScriptHandlerAdditions)
- (NSAppleEventDescriptor *)aeDescriptorValue;
@end

// wrap the NSAppleEventDescriptor string methods
@interface NSString (KFAppleScriptHandlerAdditions)
- (NSAppleEventDescriptor *)aeDescriptorValue;
+ (NSString *)stringWithAEDesc:(NSAppleEventDescriptor *)desc;
@end

// wrap the NSAppleEventDescriptor longDateTime methods
@interface NSDate (KFAppleScriptHandlerAdditions)
- (NSAppleEventDescriptor *)aeDescriptorValue;
+ (NSDate *)dateWithAEDesc:(NSAppleEventDescriptor *)desc;
@end

// these are fairly complicated methods, due to having to try to match up the various
// AS number types (see NSAppleEventDescriptor for the primitive number methods) 
// with NSNumber variants.  For complete behavior it's best to look at the implementation.
// Some notes:
//    NSNumbers created with numberWithBool should be correctly translated to AS booleans and vice versa.
//    NSNumbers created with large integer types may have to be translated to AS doubles,
//      so be careful if checking equality (you may have to check equality within epsilon).
//    Since NSNumbers can't remember if they were created with an unsigned value, 
//      [[NSNumber numberWithUnsignedChar:255] aeDescriptorValue] is going to get you an AS integer
//      with value -1.  If you really need a descriptor with an unsigned value, you'll need to do it
//      manually using the primitive methods on NSAppleEventDescriptor.  The resulting descriptor
//      can still be passed to AS with -[NSAppleScript executeHandler:error:withParameters:].
@interface NSNumber (KFAppleScriptHandlerAdditions)
- (NSAppleEventDescriptor *)aeDescriptorValue;
+ (id)numberWithAEDesc:(NSAppleEventDescriptor *)desc;
@end

// Here we're following the behavior described in the CocoaScripting release note.
//
// NSPoint -> list of two numbers: {x, y}
// NSRange -> list of two numbers: {begin offset, end offset}
// NSRect  -> list of four numbers: {left, bottom, right, top}
// NSSize  -> list of two numbers: {width, height}
@interface NSValue (KFAppleScriptHandlerAdditions)
- (NSAppleEventDescriptor *)aeDescriptorValue;
@end

// No need for ObjC -> AS conversion here, we fall through to NSObject as a collection.
// For AS -> ObjC conversion, we build an array using the primitive list methods on
// NSAppleEventDescriptor.
@interface NSArray (KFAppleScriptHandlerAdditions)
+ (NSArray *)arrayWithAEDesc:(NSAppleEventDescriptor *)desc;
@end


// Please see the CocoaScripting release note for behavior.  It's kind of complicated.
// 
// methods wrap the primitive record methods on NSAppleEventDescriptor.  
@interface NSDictionary (KFAppleScriptHandlerAdditions)
- (NSAppleEventDescriptor *)aeDescriptorValue;
+ (NSDictionary *)dictionaryWithAEDesc:(NSAppleEventDescriptor *)desc;
@end

// be aware that a null descriptor does not correspond to the 'null' keyword in 
// AppleScript - it's more like nothing at all.  For example, the return
// from an empty handler.
@interface NSNull (KFAppleScriptHandlerAdditions)
- (NSAppleEventDescriptor *)aeDescriptorValue;
+ (NSNull *)nullWithAEDesc:(NSAppleEventDescriptor *)desc;
@end



@interface NSAppleEventDescriptor (KFAppleScriptHandlerAdditions)

// just returns self.  This means that you can pass custom descriptors
// to -[NSAppleScript executeHandler:error:withParameters:].  
- (NSAppleEventDescriptor *)aeDescriptorValue;

// working with primitive descriptor types
+ (id)descriptorWithInt16:(SInt16)val;
- (SInt16)int16Value;
+ (id)descriptorWithUnsignedInt32:(UInt32)val;
- (UInt32)unsignedInt32Value;
+ (id)descriptorWithFloat32:(Float32)val;
- (Float32)float32Value;
+ (id)descriptorWithFloat64:(Float64)val;
- (Float64)float64Value;
+ (id)descriptorWithLongDateTime:(LongDateTime)val;
- (LongDateTime)longDateTimeValue;


// These are the methods for converting AS objects to objective-C objects.  
// -[NSAppleEventDescriptor objCObjectValue] is the general method for converting
// AS objects to ObjC objects, and is called by -[NSAppleScript executeHandler:error:withParameters:].
// It does no work itself.  It finds a handler based on the type of the descriptor and lets that
// handler object do the work.  If there is no handler type registered for a the type of a descriptor, 
// the raw descriptor is returned.
//
// You can designate a handlers for descriptor types with 
// +[NSAppleEventDescriptor registerConversionHandler:selector:forDescriptorTypes:].  Please note
// that this method does _not_ retain the handler object (for now anyway).  The selector should
// take a single argument, a descriptor to translate, and should return an object.  An example such 
// selector is @selector(dictionaryWithAEDesc:), for which the handler object would be [NSDictionary class].
// 
// A number of handlers are designated by default.  The methods and objects can be easily inferred (or check 
// the implementation), but the automatically handled types are
//    typeUnicodeText,
//    typeText,
//    typeUTF8Text, 
//    typeCString,
//    typeChar,
//    typeBoolean,
//    typeTrue,
//    typeFalse,
//    typeSInt16, 
//    typeSInt32,
//    typeUInt32,
//    typeSInt64,
//    typeIEEE32BitFloatingPoint,
//    typeIEEE64BitFloatingPoint,
//    type128BitFloatingPoint,
//    typeAEList,
//    typeAERecord,
//    typeLongDateTime,
//    typeNull.
- (id)objCObjectValue;
+ (void)registerConversionHandler:(id)anObject
                         selector:(SEL)aSelector
               forDescriptorTypes:(DescType)firstType, ...;

@end
    