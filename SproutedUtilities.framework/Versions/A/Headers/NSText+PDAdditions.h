//
//  NSText+PDAdditions.h
//  Journler
//
//  Created by Philip Dow on 6/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSText (PDAdditions)

- (void)setFont:(NSFont *)aFont ranges:(NSArray*)theRanges;
- (void)setTextColor:(NSColor *)aColor ranges:(NSArray*)theRanges;

@end
