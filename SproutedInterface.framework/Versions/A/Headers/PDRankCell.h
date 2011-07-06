//
//  PDRankCell.h
//  Journler XD Lite
//
//  Created by Philip Dow on 9/13/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PDRankCell : NSTextFieldCell {
	float minRank, maxRank, rank;
}

- (float) minRank;
- (void) setMinRank:(float)value;

- (float) maxRank;
- (void) setMaxRank:(float)value;

- (float) rank;
- (void) setRank:(float)value;


@end
