//
//  NSString+JournlerUtilities.h
//  Journler
//
//  Created by Philip Dow on 8/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (NSString_JournlerUtilities)

- (NSArray*) jn_rangesOfString:(NSString*)aString options:(NSUInteger)mask range:(NSRange)aRange;

@end
