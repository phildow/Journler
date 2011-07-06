//
//  JournlerEntryTest.m
//  Journler
//
//  Created by Philip Dow on 8/20/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "JournlerEntryTest.h"
#import "JournlerEntry.h"

@implementation JournlerEntryTest

- (void) setUp
{
	entry = [[JournlerEntry alloc] init];
	
	[entry setValue:@"Entry Title" forKey:@"title"];
	[entry setValue:@"Category A" forKey:@"category"];
	[entry setValue:@"Comments" forKey:@"comments"];
	[entry setValue:[NSArray arrayWithObjects:@"science", @"politics", nil] forKey:@"tags"];
	[entry setValue:[[[NSAttributedString alloc] initWithString:@"plain content"] autorelease] forKey:@"attributedContent"];
}

- (void) tearDown
{
	[entry release];
}

#pragma mark -

- (void) testModel
{
	NSString *title = @"Entry Title";
	NSString *category = @"Category A";
	NSString *comments = @"Comments";
	NSArray *tags = [NSArray arrayWithObjects:@"science", @"politics", nil];
	NSAttributedString *content = [[[NSAttributedString alloc] initWithString:@"plain content"] autorelease];
	
	NSString *searchableContent = @"Entry Title Entry Title Entry Title Comments Comments Comments science politics science politics science politics Category A plain content";
	
	
	STAssertEqualObjects(title, [entry valueForKey:@"title"], @"");
	STAssertEqualObjects(category, [entry valueForKey:@"category"], @"");
	STAssertEqualObjects(tags, [entry valueForKey:@"tags"], @"");
	STAssertEqualObjects(comments, [entry valueForKey:@"comments"], @"");
	STAssertEqualObjects(content, [entry valueForKey:@"attributedContent"], @"");
	
	STAssertEqualObjects(searchableContent, [entry valueForKey:@"searchableContent"], @"");
}

- (void) testWikiTitleGeneration
{
	NSString *wikiTitle;
	
	wikiTitle = @"AnEntry";
	[entry setValue:@"An entry" forKey:@"title"];
	STAssertEqualObjects(wikiTitle, [entry valueForKey:@"wikiTitle"], @"");
	
	wikiTitle = @"AMuchLargerEntry";
	[entry setValue:@"a much larger Entry" forKey:@"title"];
	STAssertEqualObjects(wikiTitle, [entry valueForKey:@"wikiTitle"], @"");
	
	wikiTitle = nil;
	[entry setValue:@"OneWord" forKey:@"title"];
	STAssertNil([entry valueForKey:@"wikiTitle"], @"");
	
}

@end
