//
//  ImportReviewSourceList.h
//  Journler
//
//  Created by Phil Dow on 1/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ImportReviewSourceList : NSOutlineView {

}

@end

@interface NSObject (ImportReviewSourceListDelegate)

- (void) importReviewSourceList:(ImportReviewSourceList*)aSourceList deleteFolders:(NSNotification*)aNotification;

@end