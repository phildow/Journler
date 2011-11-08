//
//  AutoCorrectArrayController.m
//  Journler
//
//  Created by Philip Dow on 11/17/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
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

#import "AutoCorrectArrayController.h"


@implementation AutoCorrectArrayController

- (id) init {
	if ( self = [super init] ) {
		searchString = [[NSString alloc] init];
	}
	return self;
}

- (void) dealloc {
	[searchString release];
		searchString = nil;
	
	[super dealloc];
}


#pragma mark -

- (void)setSearchString:(NSString *)aString
{
    if ( searchString != aString ) {
		[searchString release];
		searchString = [aString copyWithZone:[self zone]];
	}
}

#pragma mark -

- (IBAction)search:(id)sender {
    // set the search string by getting the stringValue
    // from the sender
    [self setSearchString:[sender stringValue]];
    [self rearrangeObjects];    
}

- (NSArray *)arrangeObjects:(NSArray *)objects {
    
	NSArray *returnArray = nil;
	
    if (searchString == nil || [searchString length] == 0) 
	{
		returnArray = [super arrangeObjects:objects];
	}
	else 
	{
        NSMutableArray *filteredObjects = [NSMutableArray arrayWithCapacity:[objects count]];
        
        for (id item in objects) {
			if ([[item valueForKey:@"misspelledWord"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound)
				[filteredObjects addObject:item];
			else if ([[item valueForKey:@"correctWord"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound)
				[filteredObjects addObject:item];

		}
		
		returnArray = [super arrangeObjects:filteredObjects];
	}
	
	return returnArray;
}

#pragma mark -

- (void)add:(id)sender
{
	[super add:sender];
	[wordPairTable editColumn:0 row:[wordPairTable selectedRow] withEvent:nil select:YES];
}

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView
{
	if ( [aTableView selectedRow] == -1 )
		return YES;
	
	NSString *misspelling = [[[self arrangedObjects] objectAtIndex:[aTableView selectedRow]] valueForKey:@"misspelledWord"];
	NSString *properSpelling = [[[self arrangedObjects] objectAtIndex:[aTableView selectedRow]] valueForKey:@"correctWord"];
	
	if ( [misspelling rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound  || 
			[misspelling length] == 0 || [properSpelling length] == 0 )
	{
		NSBeep();
		return NO;
	}
	else
	{
		return YES;
	}
}

@end
