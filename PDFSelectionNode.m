//
//  PDFSelectionNode.m
//  PDFViewer
//
//  Created by Philip Dow on 10/20/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import "PDFSelectionNode.h"

#define kEndExtension 16
#define kStartExtension 8

@implementation PDFSelectionNode

- (id) initWithSelection:(PDFSelection*)aSelection 
{
	if ( self = [super init] ) 
	{
		
		selection = [aSelection copy];
		
		[aSelection extendSelectionAtEnd:kEndExtension];
		[aSelection extendSelectionAtStart:kStartExtension];
		
		NSMutableString *string = [[[aSelection string] mutableCopyWithZone:[self zone]] autorelease];
		[string replaceOccurrencesOfString:@"\n" withString:@" " options:NSLiteralSearch range:NSMakeRange(0,[string length])];
		[string replaceOccurrencesOfString:@"\r" withString:@" " options:NSLiteralSearch range:NSMakeRange(0,[string length])];
		[string insertString:@"... " atIndex:0];
		[string appendString:@" ..."];
		
		preview = [string retain];
		NSMutableAttributedString *attrString = [[[NSMutableAttributedString alloc] initWithString:preview attributes:nil] autorelease];
		NSRange previewRange = [preview rangeOfString:[selection string] options:NSLiteralSearch range:NSMakeRange(0,[preview length])];
		
		[attrString addAttribute:NSFontAttributeName value:[NSFont boldSystemFontOfSize:[NSFont systemFontSize]] range:previewRange];
		
		attributedPreview = [attrString retain];
		
		page = [[[aSelection pages] objectAtIndex:0] retain];
		NSPoint origin = [aSelection boundsForPage:page].origin;
		
		characterIndex = [[NSNumber alloc] initWithInt:[page characterIndexAtPoint:origin]];
		pageIndex = [[NSNumber alloc] initWithInt:[[page document] indexForPage:page]];
		
	}
	return self;
}

- (void) dealloc {
	[selection release];
	[page release];
	[preview release];
	[attributedPreview release];
	[pageIndex release];
	[characterIndex release];
	
	[super dealloc];
}

#pragma mark -

- (PDFSelection*) selection {
	return selection;
}

- (PDFPage*) page {
	return page;
}

- (NSAttributedString*) attributedPreview {
	return attributedPreview;
}

- (NSString*) preview {
	return preview;
}	

- (NSNumber*) pageIndex {
	return pageIndex;
}

- (NSNumber*) characterIndex {
	return characterIndex;
}

@end
