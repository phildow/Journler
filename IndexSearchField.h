//
//  IndexSearchField.h
//  Journler
//
//  Created by Philip Dow on 3/20/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IndexSearchField : NSSearchField {

}

@end

@interface NSObject ( IndexSearchFieldDelegate )

- (void) searchFieldDidBecomeFirstResponder:(IndexSearchField*)aSearchField;

@end