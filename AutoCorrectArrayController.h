//
//  AutoCorrectArrayController.h
//  Journler
//
//  Created by Philip Dow on 11/17/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AutoCorrectArrayController : NSArrayController {
	
	IBOutlet NSTableView *wordPairTable;
	NSString *searchString;
}

- (IBAction)search:(id)sender;
- (void)setSearchString:(NSString *)aString;


@end
