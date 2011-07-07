#import "DatesController.h"
#import "Definitions.h"

#import "Calendar.h"
#import "JournlerEntry.h"

@implementation DatesController

- (void) awakeFromNib
{
	
	//prep the dates array controller
	NSSortDescriptor *dateDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"dateCreatedInt" ascending:NO] autorelease];
	[self setSortDescriptors:[NSArray arrayWithObject:dateDescriptor]];

	//[self bind:@"selectedDate" toObject:calendar withKeyPath:@"selectedDate" options:nil];
	//[calendar bind:@"content" toObject:self withKeyPath:@"arrangedObjects" options:nil];
}

- (void) dealloc
{
	#ifdef __DEBUG__
	NSLog(@"%s",__PRETTY_FUNCTION__);
	#endif
	
	[datePredicate release];
	[selectedDate release];
	[calendar release];
	
	[super dealloc];
}

#pragma mark -

- (id) delegate 
{ 
	return delegate; 
}

- (void) setDelegate:(id)anObject 
{
	delegate = anObject;
}

- (NSDate*) selectedDate 
{
	return selectedDate;
}

- (void) setSelectedDate:(NSDate*)aDate 
{	
	if ( selectedDate != aDate ) 
	{
		if ( delegate != nil && [delegate respondsToSelector:@selector(datesController:willChangeDate:)] )
			[delegate datesController:self willChangeDate:selectedDate];
		
		[selectedDate release];
		selectedDate = [aDate retain];
		
		[self updateSelectedObjects:self];
		
		if ( delegate != nil && [delegate respondsToSelector:@selector(datesController:didChangeDate:)] )
			[delegate datesController:self didChangeDate:selectedDate];
	}
}

- (NSPredicate*) datePredicate 
{
	return datePredicate;
}

- (void) setDatePredicate:(NSPredicate*)aPredicate 
{
	if ( datePredicate != aPredicate ) {
		[datePredicate release];
		datePredicate = [aPredicate retain];
	}
}

- (Calendar*) calendar
{
	return calendar;
}

- (void) setCalendar:(Calendar*)aCalendar
{
	if ( calendar != aCalendar )
	{
		[calendar release];
		calendar = [aCalendar retain];
	}
}

#pragma mark -

- (void) updateSelectedObjects:(id)sender 
{
	int i;
	NSArray *objects = [self arrangedObjects];
	NSMutableArray *newSelection = [NSMutableArray array];
	int dateInt = [[selectedDate descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil] intValue];
	
	for ( i = 0; i < CFArrayGetCount((CFArrayRef)objects); i++ )
	{
		JournlerEntry *anEntry = (id)CFArrayGetValueAtIndex((CFArrayRef)objects,i);
		if ( [anEntry dateCreatedInt] == dateInt && ![[anEntry valueForKey:@"markedForTrash"] boolValue] )
			[newSelection addObject:anEntry];
	}
	
	[self setSelectedObjects:newSelection];
}

- (void)setContent:(id)content
{
	[super setContent:content];
	[self updateSelectedObjects:self];
}

@end
