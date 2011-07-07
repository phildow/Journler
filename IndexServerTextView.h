//
//  IndexServerTextView.h
//  Journler
//
//  Created by Philip Dow on 3/5/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


// the IndexServerTextView provides built-in support for accessing the lexicon from the context menu
@interface IndexServerTextView : NSTextView {
	
	BOOL insertsLexiconContextSeparator;
}

- (BOOL) insertsLexiconContextSeparator;
- (void) setInsertsLexiconContextSeparator:(BOOL)withSeparator;

@end 

@interface NSObject (IndexServerTextViewDelegate)

- (void) indexServerTextView:(IndexServerTextView*)aTextView showLexiconSelection:(id)anObject term:(NSString*)aTerm;
// - (id) representedObject; -- the delegate must also respond to representedObject

@end