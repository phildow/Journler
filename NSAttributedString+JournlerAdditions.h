//
//  NSAttributedString+JournlerAdditions.h
//  Journler
//
//  Created by Philip Dow on 6/10/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef UInt32 RichTextToHTMLOptions;
enum RichTextToHTML {
	kUseJournlerHTMLConversion = 0,
	kUseSystemHTMLConversion = 1 << 1,
	kUseInlineStyleDefinitions = 1 << 2,
	kConvertSmartQuotesToRegularQuotes = 1 << 3
};


@class JournlerEntry;
@class JournlerJournal;

@interface NSAttributedString (JournlerAdditions)

- (NSAttributedString*) attributedStringWithoutTextAttachments;
- (NSAttributedString*) attributedStringWithoutJournlerLinks;
- (NSString*) iPodLinkedNote:(JournlerJournal*)aJournal;
- (NSData*) firstImageData:(NSRange)aRange fileType:(NSBitmapImageFileType)type;

//- (id) htmlRepresentation:(BOOL)systemConversion documentAttributes:(NSDictionary*)options;

- (NSString*) attributedStringAsHTML:(RichTextToHTMLOptions)options documentAttributes:(NSDictionary*)docAttrs avoidStyleAttributes:(NSString*)noList;
- (NSString*) _htmlUsingJournlerConverter;
- (NSString*) _htmlWithInlineStyleDefinitions:(NSString*)html bannedStyleAttributes:(NSString*)noList;

@end
