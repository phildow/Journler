
#import "FiltersArrayController.h"

@implementation FiltersArrayController

- (id) init {
	if ( self = [super init] ) {
		searchString = [[NSString alloc] init];
		resultString = [[NSString alloc] init];
		filterKey = [[NSString alloc] init];
	}
	return self;
}

- (void) dealloc {
	[searchString release];
		searchString = nil;
	[resultString release];
		resultString = nil;
	[filterKey release];
		filterKey = nil;
	
	[super dealloc];
}


#pragma mark -

- (void) setFilterKey:(NSString*)key {
	if ( filterKey != key ) {
		[filterKey release];
		filterKey = [key copyWithZone:[self zone]];
	}
}

- (NSString*) filterKey {
	return filterKey;
}

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
	
    if (searchString == nil || [searchString length] == 0) {
		
		returnArray = [super arrangeObjects:objects];
		if ( resultField )
			[resultField setStringValue:[NSString stringWithFormat:@"%i links", [returnArray count]]];
	
	}
	else {
    
		NSMutableArray *filteredObjects = [NSMutableArray arrayWithCapacity:[objects count]];
		NSEnumerator *objectsEnumerator = [objects objectEnumerator];
		id item;
		
		while (item = [objectsEnumerator nextObject]) {
			if ([[item valueForKeyPath:filterKey] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound)
				[filteredObjects addObject:item];
		}
		
		returnArray = [super arrangeObjects:filteredObjects];
		if ( resultField )
			[resultField setStringValue:[NSString stringWithFormat:@"%i found", [returnArray count]]];
	
	}
	
	return returnArray;
}

@end
