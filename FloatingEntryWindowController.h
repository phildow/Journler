//
//  FloatingEntryWindowController.h
//  Journler
//
//  Created by Philip Dow on 3/31/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JournlerWindowController.h"

@class BrowseTableFieldEditor;
@class PDPopUpButtonToolbarItem;

@interface FloatingEntryWindowController : JournlerWindowController {
	
	IBOutlet NSView *initalTabPlaceholder;
	IBOutlet BrowseTableFieldEditor	*browseTableFieldEditor;
}

@end
