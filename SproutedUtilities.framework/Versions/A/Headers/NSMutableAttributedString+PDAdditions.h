//
//  NSMutableAttributedString+PDAdditions.h
//  SproutedUtilities
//
//  Created by Philip Dow on 6/26/06.
//  Copyright 2006 Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSMutableAttributedString (PDAdditions)

- (void)removeAttribute:(NSString *)name ranges:(NSArray*)theRanges;
- (void)addAttribute:(NSString *)name value:(id)value ranges:(NSArray*)theRanges;

- (void)replaceCharactersInRanges:(NSArray*)ranges withStrings:(NSArray*)strings;

- (NSString*) substringWithRange:(NSRange)aRange;
- (NSArray*) substringsWithRanges:(NSArray*)ranges;

@end
