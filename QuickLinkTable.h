//
//  QuickLinkTable.h
//  Journler
//
//  Created by Philip Dow on 2/15/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QuickLinkTable : NSTableView {
	
	id _draggingObject;
	id _draggingObjects;
	
	BOOL _alternateForRevealDown;
	
}

- (id) draggingObject;
- (void) setDraggingObject:(id)object;

- (id) draggingObjects;
- (void) setDraggingObjects:(id)objects;

@end
