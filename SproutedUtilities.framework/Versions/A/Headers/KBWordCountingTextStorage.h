//
//  KBWordCountingTextStorage.h
//  ---------------------------
//
//  (c) Keith Blount 2005
//
//	A simple text storage subclass that provides a live word count, and ensures that no more
//	attributes than necessary get stripped in -fixAttachmentAttributeInRange:.
//

#import <Cocoa/Cocoa.h>

extern NSString *KBTextStorageStatisticsDidChangeNotification;

@interface KBWordCountingTextStorage : NSTextStorage
{
	NSMutableAttributedString *text;
	unsigned wordCount;
}

/* Restore text with word count intact */
- (id)initWithAttributedString:(NSAttributedString *)aString wordCount:(unsigned)wc;

/* Word count accessor */
- (unsigned)wordCount;

@end
