//
//  PDTableView.h
//  Journler
//
//  Created by Phil Dow on 2/1/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PDTableView : NSTableView {

}

@end


@interface NSObject (PDTableViewDelegate)

- (void) tableView:(NSTableView*)aTableView leftNavigationEvent:(NSEvent*)anEvent;
- (void) tableView:(NSTableView*)aTableView rightNavigationEvent:(NSEvent*)anEvent;

@end