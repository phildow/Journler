//
//  BrowseTableFieldEditor.h
//  Journler
//
//  Created by Philip Dow on 7/5/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BrowseTableFieldEditor : NSTextView {
	
	BOOL _completes;
	NSArray *_completions;
	
}

- (BOOL) completes;
- (void) setCompletes:(BOOL)shouldComplete;

- (NSArray*) completions;
- (void) setCompletions:(NSArray*)anArray;

@end
