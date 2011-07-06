//
//  NSTBFAttributedString.h
//  SproutedUtilities
//
//  Created by Philip Dow on 7/12/06.
//  Copyright 2006 Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSTBFTextBlock : NSTextBlock {

}

@end

@interface NSTextBlock (CoderCorrectionCategory)

- (void) _createFloatStorage;

@end
