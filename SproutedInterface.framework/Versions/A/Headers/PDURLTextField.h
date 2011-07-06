//
//  PDURLTextField.h
//  Journler
//
//  Created by Philip Dow on 5/28/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PDURLTextField : NSTextField {
	
	NSString *_url_title;
}

+ (NSImage*) defaultImage;

- (NSString*)URLTitle;
- (void) setURLTitle:(NSString*)aTitle;

- (NSImage*) image;
- (void) setImage:(NSImage*)anImage;

- (double) estimatedProgress;
- (void) setEstimatedProgress:(double)estimate;

@end
