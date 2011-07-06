//
//  NSString+PDStringAdditions.h
//  SproutedUtilities
//
//  Created by Philip Dow on 5/30/06.
//  Copyright 2006 Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSString (PDStringAdditions)

- (BOOL) matchesRegex:(NSString*)regex;
- (BOOL) regexMatches:(NSString*)aString;

- (BOOL) isOnlyWhitespace;

- (NSArray*) substringsWithRanges:(NSArray*)ranges;
- (NSArray*) rangesOfString:(NSString*)aString options:(unsigned)mask range:(NSRange)aRange;

- (NSString*) pathSafeString;
- (BOOL) isFilePackage;
- (NSString*) stringByStrippingAttachmentCharacters;

- (NSString*) MD5Digest;

- (NSString*) pathWithoutOverwritingSelf;
- (NSString*) capitalizedStringWithoutAffectingOtherLetters;

- (NSAttributedString*) attributedStringSyntaxHighlightedForHTML;
- (NSString*) stringAsHTMLDocument:(NSString*)title;

- (NSComparisonResult) compareVersion:(NSString*)versionB;

@end
