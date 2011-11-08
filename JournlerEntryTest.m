//
//  JournlerEntryTest.m
//  Journler
//
//  Created by Philip Dow on 8/20/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

/*
 Redistribution and use in source and binary forms, with or without modification, are permitted
 provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions
 and the following disclaimer in the documentation and/or other materials provided with the
 distribution.
 
 * Neither the name of the author nor the names of its contributors may be used to endorse or
 promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// Basically, you can use the code in your free, commercial, private and public projects
// as long as you include the above notice and attribute the code to Philip Dow / Sprouted
// If you use this code in an app send me a note. I'd love to know how the code is used.

// Please also note that this copyright does not supersede any other copyrights applicable to
// open source code used herein. While explicit credit has been given in the Journler about box,
// it may be lacking in some instances in the source code. I will remedy this in future commits,
// and if you notice any please point them out.

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
