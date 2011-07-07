//
//  IndexServerPDFView.h
//  Journler
//
//  Created by Philip Dow on 3/5/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface IndexServerPDFView : PDFView {
	
	BOOL insertsLexiconContextSeparator;
}

- (BOOL) insertsLexiconContextSeparator;
- (void) setInsertsLexiconContextSeparator:(BOOL)withSeparator;

@end

@interface NSObject (IndexServerPDFViewDelegate)

- (void) indexServerPDFView:(IndexServerPDFView*)aPDFView showLexiconSelection:(id)anObject term:(NSString*)aTerm;
// - (id) representedObject; -- the delegate must also respond to representedObject

@end