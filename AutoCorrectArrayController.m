//
//  AutoCorrectArrayController.m
//  Journler
//
//  Created by Philip Dow on 11/17/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

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
