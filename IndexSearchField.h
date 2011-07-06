//
//  IndexSearchField.h
//  Journler
//
//  Created by Phil Dow on 3/20/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IndexSearchField : NSSearchField {

}

@end

@interface NSObject ( IndexSearchFieldDelegate )

- (void) searchFieldDidBecomeFirstResponder:(IndexSearchField*)aSearchField;

@end