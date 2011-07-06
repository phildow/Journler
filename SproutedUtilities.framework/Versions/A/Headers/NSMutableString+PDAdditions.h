//
//  NSMutableString (PDAdditions).h
//  SproutedUtilities
//
//  Created by Philip Dow on 7/22/06.
//  Copyright 2006 Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSMutableString (PDAdditions)

- (void) replaceOccurrencesOfCharacterFromSet:(NSCharacterSet*)aSet 
		withString:(NSString*)aString options:(unsigned int)mask range:(NSRange)searchRange;

@end
