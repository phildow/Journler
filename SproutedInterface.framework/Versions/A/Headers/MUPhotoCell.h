//
//  MUPhotoCell.h
//  Journler
//
//  Created by Phil Dow on 1/19/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MUPhotoCell : NSImageCell <NSCopying> {
	
	NSString *imageTitle;
}

- (NSString*) title;
- (void) setTitle:(NSString*)aString;

@end
