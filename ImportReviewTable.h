//
//  ImportReviewTable.h
//  Journler
//
//  Created by Philip Dow on 1/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ImportReviewTable : NSTableView {
	
	BOOL _editingCategory;
}

- (BOOL) editingCategory;

@end

@interface NSObject (ImportReviewTableDelegate)

- (void) importReviewTable:(ImportReviewTable*)aTable deleteEntries:(NSNotification*)aNotification;

@end