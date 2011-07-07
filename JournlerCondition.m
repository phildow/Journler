//
//  JournlerCondition.m
//  Journler
//
//  Created by Phil Dow on 2/14/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "JournlerCondition.h"
#import "JournlerEntry.h"

static NSString *kAndSeparatorString = @" && ";

@implementation JournlerCondition

+ (NSDictionary*) operationForCondition:(NSString*)condition entry:(JournlerEntry*)anEntry
{
	#warning need some serious improvements to the error checking
	
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	
	if ( condition == nil )
		return nil;
	
	// and in with the new
	if ( [condition rangeOfString:@"allResourceTypes"].location == 0 || [condition rangeOfString:@"not allResourceTypes"].location == 0 )
	{
		// not supported
		return nil;
	}
	
	else if ( [condition rangeOfString:@"title"].location == 0 || [condition rangeOfString:@"not title"].location == 0)
	{
		NSScanner *scanner;
		NSString *value = nil;
		
		[dictionary setObject:@"title" forKey:kOperationDictionaryKeyKey];
					
		if ( [condition rangeOfString:@"not"].location != NSNotFound )
			[dictionary setObject:[NSNumber numberWithInt:kKeyOperationRemoveString] forKey:kOperationDictionaryKeyOperation];
			
		else if ( [condition rangeOfString:@"contains"].location != NSNotFound )
			[dictionary setObject:[NSNumber numberWithInt:kKeyOperationAppendString] forKey:kOperationDictionaryKeyOperation];
			
		else if ( [condition rangeOfString:@"beginswith"].location != NSNotFound )
			[dictionary setObject:[NSNumber numberWithInt:kKeyOperationPrependString] forKey:kOperationDictionaryKeyOperation];
			
		else if ( [condition rangeOfString:@"endswith"].location != NSNotFound )
			return nil; // not supported
			
		else if ( [condition rangeOfString:@"matches"].location != NSNotFound )
			[dictionary setObject:[NSNumber numberWithInt:kKeyOperationSetString] forKey:kOperationDictionaryKeyOperation];
			
		scanner = [NSScanner scannerWithString:condition];
		while ( ![scanner isAtEnd] ) {
			[scanner scanUpToString:@"'" intoString:nil];
			[scanner scanString:@"'" intoString:nil];
			[scanner scanUpToString:@"'" intoString:&value];
		}
		
		if ( value ) [dictionary setObject:value forKey:kOperationDictionaryKeyValue];
		
	}
	
	else if ( [condition rangeOfString:@"category"].location == 0 || [condition rangeOfString:@"not category"].location == 0) 
	{
		NSScanner *scanner;
		NSString *value = nil;
		
		[dictionary setObject:@"category" forKey:kOperationDictionaryKeyKey];
		
		if ( [condition rangeOfString:@"not"].location != NSNotFound )
			[dictionary setObject:[NSNumber numberWithInt:kKeyOperationRemoveString] forKey:kOperationDictionaryKeyOperation];
			
		else if ( [condition rangeOfString:@"contains"].location != NSNotFound )
			[dictionary setObject:[NSNumber numberWithInt:kKeyOperationAppendString] forKey:kOperationDictionaryKeyOperation];
			
		else if ( [condition rangeOfString:@"beginswith"].location != NSNotFound )
			[dictionary setObject:[NSNumber numberWithInt:kKeyOperationPrependString] forKey:kOperationDictionaryKeyOperation];
			
		else if ( [condition rangeOfString:@"endswith"].location != NSNotFound )
			return nil; // not supported
			
		else if ( [condition rangeOfString:@"matches"].location != NSNotFound )
			[dictionary setObject:[NSNumber numberWithInt:kKeyOperationSetString] forKey:kOperationDictionaryKeyOperation];
	
		scanner = [NSScanner scannerWithString:condition];
		while ( ![scanner isAtEnd] ) {
			[scanner scanUpToString:@"'" intoString:nil];
			[scanner scanString:@"'" intoString:nil];
			[scanner scanUpToString:@"'" intoString:&value];
		}
		
		if ( value ) [dictionary setObject:value forKey:kOperationDictionaryKeyValue];
	
	}
	
	else if ( [condition rangeOfString:@"keywords"].location == 0 || [condition rangeOfString:@"not keywords"].location == 0 ) 
	{
		NSScanner *scanner;
		NSString *value = nil;
		
		[dictionary setObject:@"keywords" forKey:kOperationDictionaryKeyKey];
		
		if ( [condition rangeOfString:@"not"].location != NSNotFound )
			[dictionary setObject:[NSNumber numberWithInt:kKeyOperationRemoveString] forKey:kOperationDictionaryKeyOperation];
			
		else if ( [condition rangeOfString:@"contains"].location != NSNotFound )
			[dictionary setObject:[NSNumber numberWithInt:kKeyOperationAppendString] forKey:kOperationDictionaryKeyOperation];
			
		else if ( [condition rangeOfString:@"beginswith"].location != NSNotFound )
			[dictionary setObject:[NSNumber numberWithInt:kKeyOperationPrependString] forKey:kOperationDictionaryKeyOperation];
			
		else if ( [condition rangeOfString:@"endswith"].location != NSNotFound )
			return nil; // not supported
			
		else if ( [condition rangeOfString:@"matches"].location != NSNotFound )
			[dictionary setObject:[NSNumber numberWithInt:kKeyOperationSetString] forKey:kOperationDictionaryKeyOperation];
	
		scanner = [NSScanner scannerWithString:condition];
		while ( ![scanner isAtEnd] ) 
		{
			[scanner scanUpToString:@"'" intoString:nil];
			[scanner scanString:@"'" intoString:nil];
			[scanner scanUpToString:@"'" intoString:&value];
		}
		
		if ( value ) [dictionary setObject:value forKey:kOperationDictionaryKeyValue];

	}
	
	else if ( [condition rangeOfString:@"in tags" options:NSBackwardsSearch].location == ( [condition length] - 7 ) || [condition rangeOfString:@"tags.@count"].location == 0 )
	{
		// no support for autotagging an empty/not empty condition just yet
		if ( [condition isEqualToString:@"tags.@count == 0"] )
		{
			[dictionary setObject:@"tags" forKey:kOperationDictionaryKeyKey];
			[dictionary setObject:[NSNumber numberWithInt:kKeyOperationNilOut] forKey:kOperationDictionaryKeyOperation];
			[dictionary setObject:[NSNull null] forKey:kOperationDictionaryKeyValue];
		}
		else if ( [condition isEqualToString:@"tags.@count != 0"] )
		{
			return nil;
		}
		else
		{
		
			[dictionary setObject:@"tags" forKey:kOperationDictionaryKeyKey];
			
			int tokenOperation = -1;
			NSArray *thePieces = [condition componentsSeparatedByString:kAndSeparatorString];
			NSMutableArray *theTokens = [NSMutableArray array];
			NSScanner *scanner;
			
			NSString *aPiece;
			NSEnumerator *enumerator = [thePieces objectEnumerator];
			
			while ( aPiece = [enumerator nextObject] )
			{
				NSString *aToken = nil;
				scanner = [NSScanner scannerWithString:aPiece];
				
				[scanner scanUpToString:@"'" intoString:nil];
				[scanner scanString:@"'" intoString:nil];
				[scanner scanUpToString:@"'" intoString:&aToken];
				
				if ( aToken != nil )
					[theTokens addObject:aToken];
				
				// determine the operation
				if ( tokenOperation == -1 )
				{
					if ( [aPiece rangeOfString:@"not" options:NSCaseInsensitiveSearch].location == 0 )
						tokenOperation = kKeyOperationRemoveObjects;
					else
						tokenOperation = kKeyOperationAddObjects;
				}
			}
			
			if ( tokenOperation == -1 )
				tokenOperation = kKeyOperationAddObjects;
			
			[dictionary setObject:[NSNumber numberWithInt:tokenOperation] forKey:kOperationDictionaryKeyOperation];

			if ( [theTokens count] != 0 )
				[dictionary setObject:theTokens forKey:kOperationDictionaryKeyValue];
		}
	}
	
	else if ( [condition rangeOfString:@"content"].location == 0 || [condition rangeOfString:@"not content"].location == 0 ) 
	{
		// entire entry and content not supported right now - stick with metadata
		return nil;
		
		/*
		NSScanner *scanner;
		NSString *value = nil;
		
		[dictionary setObject:@"attributedContent" forKey:kOperationDictionaryKeyKey];
		
		if ( [condition rangeOfString:@"not"].location != NSNotFound )
			[dictionary setObject:[NSNumber numberWithInt:kKeyOperationRemoveAttributedString] forKey:kOperationDictionaryKeyOperation];
			
		else if ( [condition rangeOfString:@"contains"].location != NSNotFound )
			[dictionary setObject:[NSNumber numberWithInt:kKeyOperationAppendAttributedString] forKey:kOperationDictionaryKeyOperation];
			
		else if ( [condition rangeOfString:@"beginswith"].location != NSNotFound )
			[dictionary setObject:[NSNumber numberWithInt:kKeyOperationPrependAttributedString] forKey:kOperationDictionaryKeyOperation];
			
		else if ( [condition rangeOfString:@"endswith"].location != NSNotFound )
			return nil; // not supported
			
		else if ( [condition rangeOfString:@"matches"].location != NSNotFound )
			[dictionary setObject:[NSNumber numberWithInt:kKeyOperationSetAttributedString] forKey:kOperationDictionaryKeyOperation];
	
		scanner = [NSScanner scannerWithString:condition];
		while ( ![scanner isAtEnd] ) {
			[scanner scanUpToString:@"'" intoString:nil];
			[scanner scanString:@"'" intoString:nil];
			[scanner scanUpToString:@"'" intoString:&value];
		}
		
		if ( value ) [dictionary setObject:value forKey:kOperationDictionaryKeyValue];
		*/

	}
	
	else if ( [condition rangeOfString:@"entireEntry"].location == 0 || [condition rangeOfString:@"not entireEntry"].location == 0) 
	{
		// entire entry and content not supported right now - stick with metadata
		return nil;
		
		/*
		NSScanner *scanner;
		NSString *value = nil;
		
		[dictionary setObject:@"attributedContent" forKey:kOperationDictionaryKeyKey];
		
		if ( [condition rangeOfString:@"not"].location != NSNotFound )
			[dictionary setObject:[NSNumber numberWithInt:kKeyOperationRemoveAttributedString] forKey:kOperationDictionaryKeyOperation];
			
		else if ( [condition rangeOfString:@"contains"].location != NSNotFound )
			[dictionary setObject:[NSNumber numberWithInt:kKeyOperationAppendAttributedString] forKey:kOperationDictionaryKeyOperation];
			
		else if ( [condition rangeOfString:@"beginswith"].location != NSNotFound )
			[dictionary setObject:[NSNumber numberWithInt:kKeyOperationPrependAttributedString] forKey:kOperationDictionaryKeyOperation];
			
		else if ( [condition rangeOfString:@"endswith"].location != NSNotFound )
			return nil; // not supported
			
		else if ( [condition rangeOfString:@"matches"].location != NSNotFound )
			[dictionary setObject:[NSNumber numberWithInt:kKeyOperationSetAttributedString] forKey:kOperationDictionaryKeyOperation];
	
		scanner = [NSScanner scannerWithString:condition];
		while ( ![scanner isAtEnd] ) {
			[scanner scanUpToString:@"'" intoString:nil];
			[scanner scanString:@"'" intoString:nil];
			[scanner scanUpToString:@"'" intoString:&value];
		}
		
		if ( value ) [dictionary setObject:value forKey:kOperationDictionaryKeyValue];
		*/

	}
		
	else if ( [condition rangeOfString:@"flagged"].location == 0 ) 
	{
		NSNumber *value = nil;
		
		[dictionary setObject:@"marked" forKey:kOperationDictionaryKeyKey];
		[dictionary setObject:[NSNumber numberWithInt:kKeyOperationSetNumber] forKey:kOperationDictionaryKeyOperation];
		
		if ( [condition rangeOfString:@"YES"].location != NSNotFound )
			value = [NSNumber numberWithInt:1];
			
		else
			value = [NSNumber numberWithInt:0];
		
		if ( value ) [dictionary setObject:value forKey:kOperationDictionaryKeyValue];
				
	}
	
	else if ( [condition rangeOfString:@"markedInt"].location == 0 ) 
	{
		NSNumber *value = nil;
		
		[dictionary setObject:@"marked" forKey:kOperationDictionaryKeyKey];
		[dictionary setObject:[NSNumber numberWithInt:kKeyOperationSetNumber] forKey:kOperationDictionaryKeyOperation];
		
		if ( [condition rangeOfString:@"OR" options:NSCaseInsensitiveSearch].location != NSNotFound )
		{
			// if the value is already one or the other, go with that
			if ( anEntry != nil && ( [[anEntry valueForKey:@"marked"] intValue] == 1 || [[anEntry valueForKey:@"marked"] intValue] == 2 ) )
				value = nil;
			else
				value = [NSNumber numberWithInt:1]; // go with flagged
		}
		else if ( [condition rangeOfString:@"== 0"].location != NSNotFound )
			value = [NSNumber numberWithInt:0];
		else if ( [condition rangeOfString:@"== 1"].location != NSNotFound )
			value = [NSNumber numberWithInt:1];
		else if ( [condition rangeOfString:@"!= 1"].location != NSNotFound )
		{
			// if the value is already not flagged, go with that
			if ( anEntry != nil && ( [[anEntry valueForKey:@"marked"] intValue] != 1 ) )
				value = nil;
			else
				value = [NSNumber numberWithInt:0];
		}
		else if ( [condition rangeOfString:@"== 2"].location != NSNotFound )
			value = [NSNumber numberWithInt:2];
		else if ( [condition rangeOfString:@"!= 2"].location != NSNotFound )
		{
			// if the value is already not checked
			if ( anEntry != nil && ( [[anEntry valueForKey:@"marked"] intValue] != 2 ) )
				value = nil;
			else
				value = [NSNumber numberWithInt:0];
		}
		
		if ( value ) [dictionary setObject:value forKey:kOperationDictionaryKeyValue];

	}

	else if ( [condition rangeOfString:@"labelInt"].location == 0 )
	{
		/*
		NSScanner *scanner;
		int labelVal = 0;
		
		replacingView = labelConditionView;
		
		if ( [condition rangeOfString:@"=="].location != NSNotFound )
			[labelOperationPop selectItemWithTag:PDConditionContains];
		else if ( [condition rangeOfString:@"!="].location != NSNotFound )
			[labelOperationPop selectItemWithTag:PDConditionNotContains];
		else
			[labelOperationPop selectItemWithTag:PDConditionContains];
		
		scanner = [NSScanner scannerWithString:condition];
		while ( ![scanner isAtEnd] ) {
			[scanner scanUpToString:@"=" intoString:nil];
			[scanner scanString:@"=" intoString:nil];
			[scanner scanInt:&labelVal];
		}
		
		[labelPicker setLabelSelection:labelVal];
		[keyPop selectItemWithTag:PDConditionLabel];
		*/
		
		// not supported yet
		
		int intValue = 0;
		NSNumber *value = nil;
		NSScanner *scanner;
		
		[dictionary setObject:@"label" forKey:kOperationDictionaryKeyKey];
		[dictionary setObject:[NSNumber numberWithInt:kKeyOperationSetNumber] forKey:kOperationDictionaryKeyOperation];
		
		scanner = [NSScanner scannerWithString:condition];
		while ( ![scanner isAtEnd] ) {
			[scanner scanUpToString:@"=" intoString:nil];
			[scanner scanString:@"=" intoString:nil];
			[scanner scanInt:&intValue];
		}
		
		value = [NSNumber numberWithInt:intValue];
		
		if ( [condition rangeOfString:@"=="].location != NSNotFound )
			; // no need to do anything else, just set the label
		else if ( [condition rangeOfString:@"!="].location != NSNotFound )
		{
			// set the label to 0 or 1 if explicity requested against the label the entry already has
			if ( anEntry != nil && ( ![[anEntry valueForKey:@"label"] isEqualToNumber:value] ) )
				value = [NSNumber numberWithInt:!intValue];
				
		}
		
		if ( value ) [dictionary setObject:value forKey:kOperationDictionaryKeyValue];

	}
	
	else if ( [condition rangeOfString:@"dateInt"].location == 0 ) 
	{
		// dates are not supported
		return nil;
	}
	
	else if ( [condition rangeOfString:@"dateModifiedInt"].location == 0 ) 
	{
		// dates are not supported
		return nil;
	}
	
	else if ( [condition rangeOfString:@"dateDueInt"].location == 0 ) 
	{
		// dates are not supported
		return nil;
	}
	
	else if ( [condition rangeOfString:@"blogged"].location == 0 ) 
	{
		// dates are not supported
		return nil;
	}

	
	return dictionary;
}


+ (BOOL) condition:(NSString*)aCondition affectsKey:(NSString*)aKey
{
	// should cover both actual and not conditions
	return ( [aCondition rangeOfString:aKey options:NSCaseInsensitiveSearch].location == 0 || [aCondition rangeOfString:aKey options:NSCaseInsensitiveSearch].location == 4 );
}

+ (NSString*) normalizedTagCondition:(NSString*)tagCondition
{
	// extracts the tags against we're checking, makes them lowercase, ensures we checking against the lowercase tags value
	// ie
	// 'Money' in tags -> 'money' in tags.lowercaseString
	// 'Money' in tags && 'AB' in tags -> 'money' in tags.lowercaseString && 'ab' in tags.lowercaseString
	
	NSString *normalizedCondition = nil;
	
	if ( [tagCondition rangeOfString:@"in tags" options:NSBackwardsSearch].location != ( [tagCondition length] - 7 ) )
	{
		return normalizedCondition = tagCondition;
	}
	else
	{
		// split the string up as tags supports multiple items
		//	'%@' in[cd] tags
		//	not '%@' in[cd] tags
		
		BOOL notOperation = NO;
		NSMutableArray *theTokens = [NSMutableArray array];
		
		NSString *aTag;
		NSMutableArray *tagConditions = [NSMutableArray array];
		
		NSString *aPiece;
		NSArray *thePieces = [tagCondition componentsSeparatedByString:kAndSeparatorString];
		NSEnumerator *enumerator = [thePieces objectEnumerator];
		
		NSScanner *scanner;
				
		while ( aPiece = [enumerator nextObject] )
		{
			NSString *aToken = nil;
			scanner = [NSScanner scannerWithString:aPiece];
			
			[scanner scanUpToString:@"'" intoString:nil];
			[scanner scanString:@"'" intoString:nil];
			[scanner scanUpToString:@"'" intoString:&aToken];
			
			if ( aToken != nil )
				[theTokens addObject:aToken];
			
			// determine the operation
			if ( [aPiece rangeOfString:@"not" options:NSCaseInsensitiveSearch].location == 0 )
				notOperation = YES;
			else
				notOperation = NO;
		}
		
		// with the tokens extracted and the not operation determine, build the normalized string
		enumerator = [theTokens objectEnumerator];
		while ( (aTag = [[enumerator nextObject] lowercaseString]) )
		{
			NSString *aTagCondition = nil;
			
			if ( notOperation == YES )
				aTagCondition = [NSString stringWithFormat:@"not '%@' in tags.lowercaseString", aTag];
			else
				aTagCondition = [NSString stringWithFormat:@"'%@' in tags.lowercaseString", aTag];
			
			if ( aTagCondition != nil )
				[tagConditions addObject:aTagCondition];
		}
		
		normalizedCondition = [tagConditions componentsJoinedByString:kAndSeparatorString];
	}
	
	return normalizedCondition;
}

@end
