/* FiltersArrayController */

#import <Cocoa/Cocoa.h>

@interface FiltersArrayController : NSArrayController
{
	IBOutlet NSTextField	*resultField;
	
	NSString *searchString;
	NSString *resultString;
	NSString *filterKey;
}

- (IBAction)search:(id)sender;
- (void)setSearchString:(NSString *)aString;

- (void) setFilterKey:(NSString*)key;
- (NSString*) filterKey;

@end
