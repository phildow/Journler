//
//  NSAttributedString+JournlerrAdditions.m
//  Journler
//
//  Created by Philip Dow on 6/10/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import "NSAttributedString+JournlerAdditions.h"
#import "NSURL+JournlerAdditions.h"
#import "JournlerJournal.h"
#import "JournlerEntry.h"

@implementation NSAttributedString (JournlerAdditions)

- (NSAttributedString*) attributedStringWithoutTextAttachments
{
	NSInteger i, length = [self length];
	NSMutableAttributedString *attributedString = [[self mutableCopyWithZone:[self zone]] autorelease];
	
	for ( i = length - 1; i > 0; i-- )
	{
		id attachment = [attributedString attribute:NSAttachmentAttributeName atIndex:i effectiveRange:nil];
		if ( attachment != nil )
			[attributedString deleteCharactersInRange:NSMakeRange(i,1)];
	}
	
	return attributedString;
}

- (NSAttributedString*) attributedStringWithoutJournlerLinks {
	
	NSMutableAttributedString *mutable_str = [self mutableCopyWithZone:[self zone]];
	
	NSRange limitRange;
	NSRange effectiveRange;
	id attr_value;
	 
	limitRange = NSMakeRange(0, [mutable_str length]);
	 
	while (limitRange.length > 0) {
		
		attr_value = [mutable_str attribute:NSLinkAttributeName atIndex:limitRange.location 
				longestEffectiveRange:&effectiveRange inRange:limitRange];
		
		if ( attr_value != nil ) {
		
			if ( [attr_value isKindOfClass:[NSURL class]] && 
					( [attr_value isJournlerEntry] || [attr_value isJournlerResource] ) )
				[mutable_str removeAttribute:NSLinkAttributeName range:effectiveRange];
			else if ( [attr_value isKindOfClass:[NSString class]] ) {
				
				NSURL *aURL = [NSURL URLWithString:attr_value];
				if ( aURL != nil && ( [aURL isJournlerEntry] || [aURL isJournlerResource] ) )
					[mutable_str removeAttribute:NSLinkAttributeName range:effectiveRange];
				
			}
			
		}
	
		limitRange = NSMakeRange(NSMaxRange(effectiveRange), NSMaxRange(limitRange) - NSMaxRange(effectiveRange));
	}
	
	return [mutable_str autorelease];
	
}

- (NSString*) iPodLinkedNote:(JournlerJournal*)aJournal {
	
	NSMutableAttributedString *mutable_str = [self mutableCopyWithZone:[self zone]];
	
	NSRange limitRange;
	NSRange effectiveRange;
	id attr_value;
	 
	limitRange = NSMakeRange(0, [mutable_str length]);
	 
	while (limitRange.length > 0) {
		
		attr_value = [mutable_str attribute:NSLinkAttributeName atIndex:limitRange.location 
				longestEffectiveRange:&effectiveRange inRange:limitRange];
			
		if ( [attr_value isKindOfClass:[NSURL class]] && [attr_value isJournlerEntry] ) 
		{
			// journler entry link, make an ipod link
			JournlerEntry *anEntry = [aJournal entryForTagString:[[attr_value absoluteString] lastPathComponent]];
			if ( anEntry ) {
				
				NSString *noteTitle = [NSString stringWithFormat:@"%@ %@ 1.txt", [anEntry pathSafeTitle], [anEntry tagID]];
				NSString *currentText = [[mutable_str string] substringWithRange:effectiveRange];
				
				NSString *linkedText = [NSString stringWithFormat:@"<a href=\"%@\">%@</a>", 
						noteTitle, currentText];
				
				[mutable_str removeAttribute:NSLinkAttributeName range:effectiveRange];
				[mutable_str replaceCharactersInRange:effectiveRange withString:linkedText];
			}
		}
	
		limitRange = NSMakeRange(NSMaxRange(effectiveRange), NSMaxRange(limitRange) - NSMaxRange(effectiveRange));
	}
	
	return [[mutable_str autorelease] string];

}

- (NSData*) firstImageData:(NSRange)aRange fileType:(NSBitmapImageFileType)type	
{

	//
	// parse the string for an image, return it

	NSData *returnData = nil;
	
	NSRange limitRange;
	NSRange effectiveRange;
	id attr_value;
	
	limitRange = aRange;
	if ( limitRange.location + limitRange.length > [self length] ) limitRange.length = [self length] - limitRange.length;
	 
	while (limitRange.length > 0) 
	{
		attr_value = [self attribute:NSAttachmentAttributeName atIndex:limitRange.location 
				longestEffectiveRange:&effectiveRange inRange:limitRange];
			
		limitRange = NSMakeRange(NSMaxRange(effectiveRange), NSMaxRange(limitRange) - NSMaxRange(effectiveRange));	
		
		if ( ![attr_value isKindOfClass:[NSTextAttachment class]] )
			continue;
		
		NSFileWrapper *wrapper = [attr_value fileWrapper];
		if ( !wrapper ) 
			continue;
		
		NSImage *image = [[[NSImage alloc] initWithData:[wrapper regularFileContents]] autorelease];
		if ( !image )
			continue;
		
		NSBitmapImageRep *bitmapRep = [[[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]] autorelease];
		if ( !bitmapRep ) 
			continue;
						
		NSData *imageData = [bitmapRep representationUsingType:type properties:nil];
		if ( !imageData ) 
			continue;
		
		// if we made it this far, this is a valid image
		returnData = imageData;
		break;
	}

	return returnData;
}

#pragma mark -

/*
- (id) htmlRepresentation:(BOOL)systemConversion documentAttributes:(NSDictionary*)options {
	
	//Returns NSData on sysemConversion, NSString if not.
	//
	//An attempt to handle some basic rich text to html parsing
	//	1) bold
	//	2) italic
	//	3) underline
	//	4) links
	//	5) misc special characters such as greater than, less than, and NSAttachmentCharacter
	//
	
	BOOL sys_converted = NO;
	
	id return_object;	
	
	if ( systemConversion ) {
		
		NSMutableDictionary *docAttributes;
		NSError *conversionError;
		NSData *htmlData;
		
		//
		// prepare the standard items
		NSArray *excludedItems = [NSArray arrayWithObjects:
				@"APPLET", @"BASEFONT", @"CENTER", @"DIR", @"FONT", @"ISINDEX", @"MENU", @"S", @"STRIKE", @"U", nil];
		
		docAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				NSHTMLTextDocumentType, NSDocumentTypeDocumentAttribute, 
				[NSNumber numberWithInteger:2], NSPrefixSpacesDocumentAttribute,
				excludedItems, NSExcludedElementsDocumentAttribute, nil];

		//
		// add any additional items
		if ( options != nil )
			[docAttributes addEntriesFromDictionary:options];
		
		
		htmlData = [self dataFromRange:NSMakeRange(0,[self length]) 
				documentAttributes:docAttributes error:&conversionError];
		
		if ( htmlData ) {
			sys_converted = YES;
			return_object = [htmlData retain];
						
		}
		else {
			
			NSLog(@"htmlRepresentation:documentAttributes: conversion error %@", [conversionError description]);
			sys_converted = NO;
			
		}
		
	}
	
	if ( !sys_converted ) {
	
		NSFontManager *fontManager = [[NSFontManager sharedFontManager] retain];
		NSMutableString *html = [[NSMutableString alloc] init];
		
		NSFont *lastFont = [[NSFont systemFontOfSize:12.0] retain];
		NSFont *thisFont;
		
		NSNumber *lastUnderline = nil;
		NSNumber *thisUnderline = nil;
		
		NSRange effectiveRange;
		
		NSInteger i;
		for ( i = 0; i < [self length]; i++ ) {
			
			//grab the attributes of our current character
			//if the current character is a newline or return, we need to clear its traits
			if ( [[self string] characterAtIndex:i] == NSNewlineCharacter || 
					[[self string] characterAtIndex:i] == NSCarriageReturnCharacter ) {
				thisFont = [NSFont systemFontOfSize:12.0];				// neutral font
				thisUnderline = nil;									// neutral underline
			}
			else {
				thisFont = [self attribute:NSFontAttributeName atIndex:i effectiveRange:nil];
				thisUnderline = [self attribute:NSUnderlineStyleAttributeName atIndex:i effectiveRange:nil];
			}
			
			//check for a link
			if ( [self attribute:NSLinkAttributeName atIndex:i effectiveRange:&effectiveRange] ) {
				
				//grab the link text
				NSString *linkSub = [[self string] substringWithRange:effectiveRange];
				NSString *linkString;
				
				//grab the url from this guy and use it if it exists
				id linkURL = [self attribute:NSLinkAttributeName atIndex:i effectiveRange:nil];
				
				if ( linkURL && [linkURL isKindOfClass:[NSURL class]] ) {
					
					if ( [linkURL isJournlerEntry] || [linkURL isJournlerResource] ) {
						
						//
						// watch out for attachments at the link as well
						
						NSString *blue_text;
						if ( [[self string] characterAtIndex:i] == NSAttachmentCharacter )
							blue_text = @"<journler info='rtfd' note='insert image here'></journler>";
						else
							blue_text = (NSString*)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,(CFStringRef)linkSub,CFSTR(""),kCFStringEncodingUTF8);
						
						linkString = [NSString stringWithFormat:@"<journler info='link' note='%@'>%@</journler>", 
								[linkURL absoluteString], blue_text];
						
					}
					else {
					
						linkString = [NSString stringWithFormat:@"<a href='%@'>%@</a>", [linkURL absoluteString],
							(NSString*)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,(CFStringRef)linkSub,CFSTR(""),kCFStringEncodingUTF8)];
						
					}
				}
				else if ( linkURL && [linkURL isKindOfClass:[NSString class]] ) {
					linkString = [NSString stringWithFormat:@"<a href='%@'>%@</a>", linkURL,
						(NSString*)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,(CFStringRef)linkSub,CFSTR(""),kCFStringEncodingUTF8)];
				}
				else {
					linkString = [NSString stringWithFormat:@"<a href='%@'>%@</a>", linkSub,
						(NSString*)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,(CFStringRef)linkSub,CFSTR(""),kCFStringEncodingUTF8)];
				}
				
				//append it and change the distance
				[html appendString:linkString];
				i+= (effectiveRange.length - 1);
				
			}
			else {
			
				//check for old attribtues in order reverse to new
				if ( lastUnderline && !thisUnderline )
					[html appendString:@"</u>"];
					
				if ( [fontManager fontNamed:[lastFont fontName] hasTraits:NSItalicFontMask]
					&& ![fontManager fontNamed:[thisFont fontName] hasTraits:NSItalicFontMask] )
					[html appendString:@"</em>"];		// italic
					
				if ( [fontManager fontNamed:[lastFont fontName] hasTraits:NSBoldFontMask]
					&& ![fontManager fontNamed:[thisFont fontName] hasTraits:NSBoldFontMask] )
					[html appendString:@"</strong>"];	// bold
				
				//check for new attributes
				if ( ![fontManager fontNamed:[lastFont fontName] hasTraits:NSBoldFontMask]
					&& [fontManager fontNamed:[thisFont fontName] hasTraits:NSBoldFontMask] )
					[html appendString:@"<strong>"];
				
				if ( ![fontManager fontNamed:[lastFont fontName] hasTraits:NSItalicFontMask]
					&& [fontManager fontNamed:[thisFont fontName] hasTraits:NSItalicFontMask] )
					[html appendString:@"<em>"];
				
				if ( !lastUnderline && thisUnderline )
					[html appendString:@"<u>"];
			
				//and append our character, weeding out greater than and less than signs
				if ( [[self string] characterAtIndex:i] == '<' )
					[html appendString:@"&lt;"];
				else if ( [[self string] characterAtIndex:i] == '>' )
					[html appendString:@"&gt;"];
				else if ( [[self string] characterAtIndex:i] == NSCarriageReturnCharacter )
					[html appendString:[NSString stringWithCharacters:(const unichar[]) {NSNewlineCharacter} length:1]];
				else if ( [[self string] characterAtIndex:i] == NSAttachmentCharacter )
					[html appendString:@"<journler info='rtfd' note='insert image here'></journler>"];
				else
					[html appendString:[[self string] substringWithRange:NSMakeRange(i,1)]];
				
				//set our last font to this font
				[lastFont release];
				lastFont = [thisFont copyWithZone:[self zone]];
				
				if ( lastUnderline ) [lastUnderline release];
				lastUnderline = ( thisUnderline ? [thisUnderline copy] : nil );
			
			}
		}
		
		//once we are through the processing, we must append any closing markup, again in reverse order for consistency
		if ( lastUnderline ) [html appendString:@"</u>"];
		if ( [fontManager fontNamed:[lastFont fontName] hasTraits:NSItalicFontMask] ) [html appendString:@"</em>"];
		if ( [fontManager fontNamed:[lastFont fontName] hasTraits:NSBoldFontMask] ) [html appendString:@"</strong>"];
		
		// clean up
		[fontManager release];
		[lastFont release];
		
		return_object = html;
	
	}
	
	return [return_object autorelease];
	
}
*/

- (NSString*) attributedStringAsHTML:(RichTextToHTMLOptions)options documentAttributes:(NSDictionary*)docAttrs avoidStyleAttributes:(NSString*)noList
{
	if ( [self length] == 0 )
		return [NSString string];
	
	NSString *htmlString = nil;
	
	if ( options & kUseSystemHTMLConversion )
	{
		NSMutableDictionary *docAttributes;
		NSError *conversionError;
		NSData *htmlData;
		
		// prepare the standard items
		NSArray *excludedItems = [NSArray arrayWithObjects:
				@"APPLET", @"BASEFONT", @"CENTER", @"DIR", @"FONT", @"ISINDEX", @"MENU", @"S", @"STRIKE", @"U", nil];
		
		// document atttributes
		docAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				NSHTMLTextDocumentType, NSDocumentTypeDocumentAttribute, 
				[NSNumber numberWithInteger:2], NSPrefixSpacesDocumentAttribute,
				excludedItems, NSExcludedElementsDocumentAttribute, nil];
		
		[docAttributes addEntriesFromDictionary:docAttrs];
		
		htmlData = [self dataFromRange:NSMakeRange(0,[self length]) documentAttributes:docAttributes error:&conversionError];
		if ( htmlData == nil )
		{
			NSLog(@"%s - unable to generate html data from rich text", __PRETTY_FUNCTION__ );
			htmlString = nil;
			goto bail;
		}
		else
		{
			NSString *tentative = [[[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding] autorelease];
			if ( options & kUseInlineStyleDefinitions )
				htmlString = [self _htmlWithInlineStyleDefinitions:tentative bannedStyleAttributes:noList];
			else
				htmlString = tentative;
		}
		
	}
	else
	{
		htmlString = [self _htmlUsingJournlerConverter];
	}
	
bail:
	
	if ( options & kConvertSmartQuotesToRegularQuotes )
	{
		static unichar kOpenSmartQuote = 0x201C; // 0x201C; //0x0093;
		static unichar kCloseSmartQuote = 0x201D; // 0x201D; // 0x0094;
		//static unichar kRegularQuote = 0x22;
		NSString *openSmartQuote = [[[NSString alloc] initWithCharacters:(const unichar[]){kOpenSmartQuote} length:1] autorelease];
		NSString *closeSmartQuote = [[[NSString alloc] initWithCharacters:(const unichar[]){kCloseSmartQuote} length:1] autorelease];
		
		NSMutableString *workingString = [[htmlString mutableCopyWithZone:[self zone]] autorelease];
		[workingString replaceOccurrencesOfString:openSmartQuote withString:@"\"" options:NSLiteralSearch range:NSMakeRange(0,[workingString length])];
		[workingString replaceOccurrencesOfString:closeSmartQuote withString:@"\"" options:NSLiteralSearch range:NSMakeRange(0,[workingString length])];
		
		htmlString = workingString;
		
		//htmlString = [htmlString stringByReplacingOccurrencesOfCharacter:kOpenSmartQuote withCharacter:kRegularQuote];
		//htmlString = [htmlString stringByReplacingOccurrencesOfCharacter:kCloseSmartQuote withCharacter:kRegularQuote];
		
	}
	
	return htmlString;
	
}

- (NSString*) _htmlUsingJournlerConverter
{	
	NSFontManager *fontManager = [[NSFontManager sharedFontManager] retain];
	NSMutableString *html = [[NSMutableString alloc] init];
	
	NSFont *lastFont = [[NSFont systemFontOfSize:12.0] retain];
	NSFont *thisFont;
	
	NSNumber *lastUnderline = nil;
	NSNumber *thisUnderline = nil;
	
	NSRange effectiveRange;
	
	NSInteger i;
	for ( i = 0; i < [self length]; i++ ) {
		
		//grab the attributes of our current character
		//if the current character is a newline or return, we need to clear its traits
		if ( [[self string] characterAtIndex:i] == NSNewlineCharacter || 
				[[self string] characterAtIndex:i] == NSCarriageReturnCharacter ) 
		{
			thisFont = [NSFont systemFontOfSize:12.0];				// neutral font
			thisUnderline = nil;									// neutral underline
			
			// add paragraph and br tags
			if ( i + 1 < [self length] - 1 )
			{
				if ( i != 0 && ( [[self string] characterAtIndex:i-1] == NSNewlineCharacter || [[self string] characterAtIndex:i-1] == NSCarriageReturnCharacter ) )
				{
					// don't do anything if the previous character was a newline
				}
				else
				{
					// if the next character is also newline, this is a paragraph break, otherwise just a line break
					if ( [[self string] characterAtIndex:i+1] == NSNewlineCharacter || [[self string] characterAtIndex:i+1] == NSCarriageReturnCharacter )
						[html appendString:@"<p></p>"];
					else
						[html appendString:@"<br />"];
				}
			}
			else
			{
				// if we're at the end encountering newline then just add a line break
				[html appendString:@"<br />"];
			}
		}
		else 
		{
			thisFont = [self attribute:NSFontAttributeName atIndex:i effectiveRange:nil];
			thisUnderline = [self attribute:NSUnderlineStyleAttributeName atIndex:i effectiveRange:nil];
		}
		
		//check for a link
		if ( [self attribute:NSLinkAttributeName atIndex:i effectiveRange:&effectiveRange] ) {
			
			//grab the link text
			NSString *linkSub = [[self string] substringWithRange:effectiveRange];
			NSString *linkString;
			
			//grab the url from this guy and use it if it exists
			id linkURL = [self attribute:NSLinkAttributeName atIndex:i effectiveRange:nil];
			
			if ( linkURL && [linkURL isKindOfClass:[NSURL class]] ) {
				
				if ( [linkURL isJournlerEntry] || [linkURL isJournlerResource] ) {
					
					//
					// watch out for attachments at the link as well
					
					NSString *blue_text;
					if ( [[self string] characterAtIndex:i] == NSAttachmentCharacter )
						blue_text = @"<journler info=\"rtfd\" note=\"insert image here\"></journler>";
					else
						blue_text = (NSString*)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,(CFStringRef)linkSub,CFSTR(""),kCFStringEncodingUTF8);
					
					linkString = [NSString stringWithFormat:@"<journler info=\"link\" note=\"%@\">%@</journler>", 
							[linkURL absoluteString], blue_text];
					
				}
				else {
				
					linkString = [NSString stringWithFormat:@"<a href=\"%@\">%@</a>", [linkURL absoluteString],
						(NSString*)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,(CFStringRef)linkSub,CFSTR(""),kCFStringEncodingUTF8)];
					
				}
			}
			else if ( linkURL && [linkURL isKindOfClass:[NSString class]] ) {
				linkString = [NSString stringWithFormat:@"<a href=\"%@\">%@</a>", linkURL,
					(NSString*)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,(CFStringRef)linkSub,CFSTR(""),kCFStringEncodingUTF8)];
			}
			else {
				linkString = [NSString stringWithFormat:@"<a href=\"%@\">%@</a>", linkSub,
					(NSString*)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,(CFStringRef)linkSub,CFSTR(""),kCFStringEncodingUTF8)];
			}
			
			//append it and change the distance
			[html appendString:linkString];
			i+= (effectiveRange.length - 1);
			
		}
		else {
			
			//check for old attribtues in order reverse to new
			if ( lastUnderline && !thisUnderline )
				[html appendString:@"</span>"];
				
			if ( [fontManager fontNamed:[lastFont fontName] hasTraits:NSItalicFontMask]
				&& ![fontManager fontNamed:[thisFont fontName] hasTraits:NSItalicFontMask] )
				[html appendString:@"</em>"];		/* italic */
				
			if ( [fontManager fontNamed:[lastFont fontName] hasTraits:NSBoldFontMask]
				&& ![fontManager fontNamed:[thisFont fontName] hasTraits:NSBoldFontMask] )
				[html appendString:@"</strong>"];	/* bold */
			
			//check for new attributes
			if ( ![fontManager fontNamed:[lastFont fontName] hasTraits:NSBoldFontMask]
				&& [fontManager fontNamed:[thisFont fontName] hasTraits:NSBoldFontMask] )
				[html appendString:@"<strong>"];
			
			if ( ![fontManager fontNamed:[lastFont fontName] hasTraits:NSItalicFontMask]
				&& [fontManager fontNamed:[thisFont fontName] hasTraits:NSItalicFontMask] )
				[html appendString:@"<em>"];
			
			if ( !lastUnderline && thisUnderline )
				[html appendString:@"<span style=\"text-decoration: underline\">"];
		
			//and append our character, weeding out greater than and less than signs
			if ( [[self string] characterAtIndex:i] == '<' )
				[html appendString:@"&lt;"];
			else if ( [[self string] characterAtIndex:i] == '>' )
				[html appendString:@"&gt;"];
			else if ( [[self string] characterAtIndex:i] == NSCarriageReturnCharacter )
				[html appendString:[NSString stringWithCharacters:(const unichar[]) {NSNewlineCharacter} length:1]];
			else if ( [[self string] characterAtIndex:i] == NSAttachmentCharacter )
				[html appendString:@"<journler info=\"rtfd\" note=\"insert image here\"></journler>"];
			else
				[html appendString:[[self string] substringWithRange:NSMakeRange(i,1)]];
			
			//set our last font to this font
			[lastFont release];
			lastFont = [thisFont copyWithZone:[self zone]];
			
			if ( lastUnderline ) [lastUnderline release];
			lastUnderline = ( thisUnderline ? [thisUnderline copy] : nil );
		
		}
	}
	
	//once we are through the processing, we must append any closing markup, again in reverse order for consistency
	if ( lastUnderline ) [html appendString:@"</u>"];
	if ( [fontManager fontNamed:[lastFont fontName] hasTraits:NSItalicFontMask] ) [html appendString:@"</em>"];
	if ( [fontManager fontNamed:[lastFont fontName] hasTraits:NSBoldFontMask] ) [html appendString:@"</strong>"];
	
	// clean up
	[fontManager release];
	[lastFont release];
	
	return html;
}

- (NSString*) _htmlWithInlineStyleDefinitions:(NSString*)html bannedStyleAttributes:(NSString*)noList
{	
	// the bannedStyleAttributes contains a comma separated list of style attributes that should be removed from the conversion
	// substyles are also removes, so specifying "outline" will remove outline-color, outline-style and outline-width
	
	if ( html == nil || [html length] == 0 )
		return [NSString string];
	
	NSInteger i;
	NSMutableArray *bannedAttributesList = nil;
	
	if ( noList != nil && [noList length] != 0 )
	{
		NSArray *separatedList = [noList componentsSeparatedByString:@","];
		bannedAttributesList = [NSMutableArray arrayWithCapacity:[separatedList count]];
		
		for ( i = 0; i < [separatedList count]; i++ )
		{
			NSString *anItem = [separatedList objectAtIndex:i];
			[bannedAttributesList addObject:[anItem stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
		}
	
	}
	
	NSScanner *scanner = [NSScanner scannerWithString:html];
	NSMutableDictionary *stylesDictionary = [NSMutableDictionary dictionary];
	
	NSString *bodyOnly = nil;
	NSMutableString *htmlInline = nil;
	
	NSString *styleDefinition = nil;
	NSArray *styleDefinitions = nil;
	
	static NSString *styleBegin = @"<style type=\"text/css\">";
	static NSString *styleEnd = @"</style>";
	
	static NSString *bodyBegin = @"<body>";
	static NSString *bodyEnd = @"</body>";
	
	static NSString *zeroMargin = @"margin: 0.0px 0.0px 0.0px 0.0px; ";
	static NSString *emptyStyle = @" style=\"\"";
	static NSString *emptyParagraph = @"<p><br /></p>";
	
	static NSString *boldOpen = @"<b>";
	static NSString *boldClose = @"</b>";
	static NSString *strongOpen = @"<strong>";
	static NSString *strongClose = @"</strong>";
	
	static NSString *italicOpen = @"<i>";
	static NSString *italicClose = @"</i>";
	static NSString *emphasisOpen = @"<em>";
	static NSString *emphasisClose = @"</em>";
	
	[scanner scanUpToString:styleBegin intoString:nil];
	[scanner scanString:styleBegin intoString:nil];
	[scanner scanUpToString:styleEnd intoString:&styleDefinition];
	
	[scanner scanUpToString:bodyBegin intoString:nil];
	[scanner scanString:bodyBegin intoString:nil];
	[scanner scanUpToString:bodyEnd intoString:&bodyOnly];
	
	htmlInline = [[bodyOnly mutableCopyWithZone:[self zone]] autorelease];
	
	styleDefinitions = [styleDefinition componentsSeparatedByString:@"\n"];
	
	//NSLog([styleDefinitions description]);
	
    for ( NSString *aStyleDefinition in styleDefinitions )
	{
		aStyleDefinition = [aStyleDefinition stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		NSArray *styleComponents = [aStyleDefinition componentsSeparatedByString:@" {"];
		if ( [styleComponents count] != 2 )
			continue;
		
		NSString *aStyleKey = [styleComponents objectAtIndex:0];
		NSString *aStyleDeclaration = [styleComponents objectAtIndex:1];
		
		if ( [aStyleDeclaration characterAtIndex:[aStyleDeclaration length]-1] == '}' )
			aStyleDeclaration = [aStyleDeclaration substringToIndex:[aStyleDeclaration length]-1];
		
		NSArray *keyComponents = [aStyleKey componentsSeparatedByString:@"."];
		if ( [keyComponents count] != 2 )
			continue;
		
		// filter out the prohibited styles from the style declaration if requested
		if ( bannedAttributesList != nil && [bannedAttributesList count] != 0 )
		{
			NSInteger i;
			aStyleDeclaration = [[aStyleDeclaration mutableCopyWithZone:[self zone]] autorelease];
			NSCharacterSet *attributeEndSet = [NSCharacterSet characterSetWithCharactersInString:@";\""];
			
			for ( i = 0; i < [bannedAttributesList count]; i++ )
			{
				NSInteger startIndex, endIndex;
				NSString *bannedAttribute = [bannedAttributesList objectAtIndex:i];
				NSScanner *bannedScanner;
				
				restart:
				bannedScanner = [NSScanner scannerWithString:aStyleDeclaration];
				
				// first the variations
				while ( YES )
				{
					// find the banned string and note the location
					if ( [aStyleDeclaration rangeOfString:bannedAttribute options:NSCaseInsensitiveSearch range:NSMakeRange(0,[aStyleDeclaration length])].location == 0 )
						startIndex = 0;
					else
					{
						if ( ![bannedScanner scanUpToString:bannedAttribute intoString:nil] )
							break;
						
						startIndex = [bannedScanner scanLocation];
					}
					
					// find the end of the attribute and note the location
					if ( ![bannedScanner scanUpToCharactersFromSet:attributeEndSet intoString:nil] )
						break;
					
					endIndex = [bannedScanner scanLocation];
					
					// modify the end index to get rid of extra spaces and the ending colon
					if ( endIndex + 1 < [aStyleDeclaration length] )
						endIndex+=2;
					
					// simple error checking
					if ( endIndex < startIndex )
						break;
					
					NSRange bannedRange = NSMakeRange(startIndex, endIndex - startIndex);
					[(NSMutableString*)aStyleDeclaration deleteCharactersInRange:bannedRange];
					
					if ( [bannedScanner isAtEnd] )
						break;
					else
						goto restart;
				}
			}
		}
		
		//NSLog(aStyleDeclaration);
		
		//NSString *keyObject = [keyComponents objectAtIndex:0];
		NSString *keyClass = [keyComponents objectAtIndex:1];
		
		NSString *classProperty = [NSString stringWithFormat:@"class=\"%@\"", keyClass];
		NSString *styleProperty = [NSString stringWithFormat:@"style=\"%@\"", aStyleDeclaration];
		
		[stylesDictionary setObject:aStyleDeclaration forKey:aStyleKey];
		
		[htmlInline replaceOccurrencesOfString:classProperty withString:styleProperty options:NSLiteralSearch range:NSMakeRange(0,[htmlInline length])];
	}
	
	//NSLog([stylesDictionary description]);
	
	// do some final clean up 
	[htmlInline replaceOccurrencesOfString:zeroMargin withString:@"" options:NSLiteralSearch range:NSMakeRange(0,[htmlInline length])];
	[htmlInline replaceOccurrencesOfString:emptyStyle withString:@"" options:NSLiteralSearch range:NSMakeRange(0,[htmlInline length])];
	[htmlInline replaceOccurrencesOfString:emptyParagraph withString:@"" options:NSLiteralSearch range:NSMakeRange(0,[htmlInline length])];
	
	[htmlInline replaceOccurrencesOfString:boldOpen withString:strongOpen options:NSLiteralSearch range:NSMakeRange(0,[htmlInline length])];
	[htmlInline replaceOccurrencesOfString:boldClose withString:strongClose options:NSLiteralSearch range:NSMakeRange(0,[htmlInline length])];
	
	[htmlInline replaceOccurrencesOfString:italicOpen withString:emphasisOpen options:NSLiteralSearch range:NSMakeRange(0,[htmlInline length])];
	[htmlInline replaceOccurrencesOfString:italicClose withString:emphasisClose options:NSLiteralSearch range:NSMakeRange(0,[htmlInline length])];
	
	return htmlInline;
}


@end
