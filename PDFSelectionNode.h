//
//  PDFSelectionNode.h
//  PDFViewer
//
//  Created by Philip Dow on 10/20/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface PDFSelectionNode : NSObject {
	
	PDFSelection *selection;
	
	NSAttributedString *attributedPreview;
	NSString *preview;
	
	PDFPage *page;
	NSNumber *pageIndex;
	NSNumber *characterIndex;
}

- (id) initWithSelection:(PDFSelection*)aSelection;

- (PDFSelection*) selection;
- (PDFPage*) page;

- (NSAttributedString*) attributedPreview;
- (NSString*) preview;

- (NSNumber*) pageIndex;
- (NSNumber*) characterIndex;

@end
