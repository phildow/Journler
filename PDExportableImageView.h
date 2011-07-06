//
//  PDExportableImageView.h
//  Journler
//
//  Created by Philip Dow on 10/30/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//
//	Supports editing to the extent that images may be 
//	copied and dragged out of the view 

#import <Cocoa/Cocoa.h>


@interface PDExportableImageView : NSImageView {
	NSString *filename;
}

- (NSString*) filename;
- (void) setFilename:(NSString*)aFilename;

@end
