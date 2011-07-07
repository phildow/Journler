#import "JournlerConditionController.h"

#import <SproutedUtilities/SproutedUtilities.h>

typedef enum {
	PDConditionTitle = 0,		PDConditionCategory = 1,		PDConditionKeywords = 2,
	PDConditionDate = 3,		PDConditionTime = 4,			PDConditionBlogged = 5,
	PDConditionFlagged = 6,		PDConditionModified = 7,		PDConditionLabel = 8,
	PDConditionContent = 9,		PDConditionEntire = 10,			PDConditionNotBlogged = 11,
	PDConditionNotFlagged = 12,	PDConditionMarking = 13,		PDConditionDateDue = 14,
	PDConditionResources = 15,	PDConditionTags = 16
}PDConditionKey;

typedef enum {
	PDResourceTypeWebPage = 0, PDResourceTypeWebArchive = 1, PDResourceTypeImage = 2,
	PDResourceTypeAudio = 3, PDResourceTypeVideo = 4, PDResourceTypePDFDocument = 5,
	PDResourceTypeABRecord = 6, PDResourceTypeAny = 7, PDResourceTypeCorrespondence = 8,
	PDResourceTypeTextDocument = 9
}PDResourceConditionType;

#define PDConditionContains		0
#define PDConditionNotContains	1
#define PDConditionBeginsWith	2
#define PDConditionEndsWith		3
#define PDConditionIs			4

#define PDConditionIsEmpty		11
#define PDConditionIsNotEmpty	12

#define PDConditionBefore		0
#define PDConditionAfter		1
#define PDConditionBetween		2
#define PDConditionInTheLast	3
#define PDConditionInTheNext	4

#define PDConditionDay			0
#define PDConditionWeek			1
#define PDConditionMonth		2

#define PDConditionMarkFlagged					0
#define PDConditionMarkNotFlagged				1
#define PDConditionMarkChecked					2
#define PDConditionMarkNotChecked				3
#define PDConditionMarkFlaggedOrChecked			4
#define PDConditionMarkNotFlaggedNorChecked		5

#define PDConditionResourcesInclude			0
#define PDConditionResourcesDoNotInclude	1

static NSString *kAndSeparatorString = @" && ";

@implementation JournlerConditionController

- (id) initWithTarget:(id)anObject
{
	if ( self = [super init] ) 
	{
		static NSString *kNibName = @"Condition";
		NSString *kNibName105 = [NSString stringWithFormat:@"%@_105",kNibName];
		
		if ( [[NSBundle mainBundle] respondsToSelector:@selector(executableArchitectures)] 
				&& [[NSBundle mainBundle] pathForResource:kNibName105 ofType:@"nib"] != nil )
			[NSBundle loadNibNamed:kNibName105 owner:self];
		else
			[NSBundle loadNibNamed:kNibName owner:self];
		
		//[NSBundle loadNibNamed:@"Condition" owner:self];
		
		target = anObject;
		tag = 0;
		
		_allowsEmptyCondition = NO;
		
		// set the initial view
		[stringConditionView setFrame:[specifiedConditionView bounds]];
		[specifiedConditionView addSubview:stringConditionView];
	}

	return self;
}

- (void) dealloc {
	
	[conditionView release];
		conditionView = nil;
	
	[stringConditionView release];
		stringConditionView = nil;
	
	[dateConditionView release];
		dateConditionView = nil;
	
	[labelConditionView release];
		labelConditionView = nil;
		
	[markingConditionView release];
		markingConditionView = nil;
	
	[super dealloc];
	
}

- (void) awakeFromNib 
{	
	[labelPicker setTarget:self];
	[labelPicker setAction:@selector(changeCondition:)];
	
	[dateConditionAValue setDateValue:[NSCalendarDate date]];
	[dateConditionBValue setDateValue:[NSCalendarDate date]];
	
	dateDetailsView = dateDetailsPlaceholder;
	
	[dateDatedView setFrame:[dateDetailsView frame]];
	[dateConditionView replaceSubview:dateDetailsView with:dateDatedView];
	
	dateDetailsView = dateDatedView;
}

- (void) appropriateFirstResponder:(NSWindow*)aWindow
{
	// should depend on the condition 
	[aWindow makeFirstResponder:stringConditionValue];
}

#pragma mark -

- (int) tag 
{ 
	return tag; 
}

- (void) setTag:(int)newTag 
{
	tag = newTag;
}

- (BOOL) sendsLiveUpdate 
{ 
	return _sendsLiveUpdate; 
}

- (void) setSendsLiveUpdate:(BOOL)updates 
{
	_sendsLiveUpdate = updates;
}

- (BOOL) autogeneratesDynamicDates
{
	return _autogeneratesDynamicDates;
}

- (void) setAutogeneratesDynamicDates:(BOOL)autogenerate
{
	_autogeneratesDynamicDates = autogenerate;
}

- (BOOL) allowsEmptyCondition
{
	return _allowsEmptyCondition;
}

- (void) setAllowsEmptyCondition:(BOOL)allowsEmpty
{
	_allowsEmptyCondition = allowsEmpty;
}

#pragma mark -

- (void)controlTextDidChange:(NSNotification *)aNotification {
	[self _sendUpdateIfRequested];
}

- (IBAction) changeCondition:(id)sender {
	[self _sendUpdateIfRequested];
}

- (void) _sendUpdateIfRequested {
	if ( [self sendsLiveUpdate] && [target respondsToSelector:@selector(conditionDidChange:)] )
		[target conditionDidChange:self];
}

#pragma mark -

- (NSView*) conditionView { return conditionView; }

#pragma mark -
#pragma mark Interpreting and Producing the Predicate String

- (void) setInitialCondition:(NSString*)condition {
	
	//
	// used to reproduce the saved condition visually
	//
	
	NSView *replacingView = nil;
	
	// clear out the old condition
	if ( [[specifiedConditionView subviews] count] != 0 )
		[[[specifiedConditionView subviews] objectAtIndex:0] removeFromSuperview];
	
	// and in with the new
	if ( [condition rangeOfString:@"allResourceTypes"].location == 0 || [condition rangeOfString:@"not allResourceTypes"].location == 0 ) 
	{
		// beginning with this guy because "content" may appear in one of the utis
		replacingView = resourcesConditionView;
		[keyPop selectItemWithTag:PDConditionResources];
		
		//if ( [condition rangeOfString:@"not "].location != NSNotFound )
		if ( [condition rangeOfString:@"not "].location == 0 )
			[resourcesOperationPop selectItemWithTag:1];
		else
			[resourcesOperationPop selectItemWithTag:0];
		
		if ( [condition rangeOfString:@"com.journler.url"].location != NSNotFound || [condition rangeOfString:(NSString*)kUTTypeURL].location != NSNotFound )
			[resourcesTypePop selectItemWithTag:PDResourceTypeWebPage];
		else if ( [condition rangeOfString:(NSString*)kUTTypeWebArchive].location != NSNotFound )
			[resourcesTypePop selectItemWithTag:PDResourceTypeWebArchive];
		else if ( [condition rangeOfString:(NSString*)kUTTypeImage].location != NSNotFound )
			[resourcesTypePop selectItemWithTag:PDResourceTypeImage];
		else if ( [condition rangeOfString:(NSString*)kUTTypeAudio].location != NSNotFound )
			[resourcesTypePop selectItemWithTag:PDResourceTypeAudio];
		else if ( [condition rangeOfString:(NSString*)@"public.movie"].location != NSNotFound )
			[resourcesTypePop selectItemWithTag:PDResourceTypeVideo];
		else if ( [condition rangeOfString:(NSString*)kUTTypePDF].location != NSNotFound )
			[resourcesTypePop selectItemWithTag:PDResourceTypePDFDocument];
		else if ( [condition rangeOfString:@"com.journler.abperson"].location != NSNotFound )
			[resourcesTypePop selectItemWithTag:PDResourceTypeABRecord];
		else if ( [condition rangeOfString:(NSString*)kUTTypeMessage].location != NSNotFound )
			[resourcesTypePop selectItemWithTag:PDResourceTypeCorrespondence];
		else if ( [condition rangeOfString:(NSString*)kUTTypePlainText].location != NSNotFound )
			[resourcesTypePop selectItemWithTag:PDResourceTypeTextDocument];
			
		else if ( [condition rangeOfString:(NSString*)kUTTypeItem].location != NSNotFound )
			[resourcesTypePop selectItemWithTag:PDResourceTypeAny];

	}
	
	else if ( [condition rangeOfString:@"title"].location == 0 || [condition rangeOfString:@"not title"].location == 0) 
	{
		
		NSScanner *scanner;
		NSString *value = nil;
		
		replacingView = stringConditionView;
		[keyPop selectItemWithTag:PDConditionTitle];
		
		//if ( [condition rangeOfString:@"not "].location != NSNotFound )
		if ( [condition rangeOfString:@"not "].location == 0 )
			[stringOperationPop selectItemWithTag:PDConditionNotContains];
		else if ( [condition rangeOfString:@"contains"].location != NSNotFound )
			[stringOperationPop selectItemWithTag:PDConditionContains];
		else if ( [condition rangeOfString:@"beginswith"].location != NSNotFound )
			[stringOperationPop selectItemWithTag:PDConditionBeginsWith];
		else if ( [condition rangeOfString:@"endswith"].location != NSNotFound )
			[stringOperationPop selectItemWithTag:PDConditionEndsWith];
		else if ( [condition rangeOfString:@"matches"].location != NSNotFound )
			[stringOperationPop selectItemWithTag:PDConditionIs];
			
		scanner = [NSScanner scannerWithString:condition];
		while ( ![scanner isAtEnd] ) 
		{
			[scanner scanUpToString:@"'" intoString:nil];
			[scanner scanString:@"'" intoString:nil];
			[scanner scanUpToString:@"'" intoString:&value];
		}
		
		if ( value && ![value isEqualToString:@"^"])
			[stringConditionValue setStringValue:value];
		
	}
	
	else if ( [condition rangeOfString:@"category"].location == 0 || [condition rangeOfString:@"not category"].location == 0) 
	{
		NSScanner *scanner;
		NSString *value = nil;
		
		replacingView = stringConditionView;
		[keyPop selectItemWithTag:PDConditionCategory];
		
		//if ( [condition rangeOfString:@"not "].location != NSNotFound )
		if ( [condition rangeOfString:@"not "].location == 0 )
			[stringOperationPop selectItemWithTag:PDConditionNotContains];
		else if ( [condition rangeOfString:@"contains"].location != NSNotFound )
			[stringOperationPop selectItemWithTag:PDConditionContains];
		else if ( [condition rangeOfString:@"beginswith"].location != NSNotFound )
			[stringOperationPop selectItemWithTag:PDConditionBeginsWith];
		else if ( [condition rangeOfString:@"endswith"].location != NSNotFound )
			[stringOperationPop selectItemWithTag:PDConditionEndsWith];
		else if ( [condition rangeOfString:@"matches"].location != NSNotFound )
			[stringOperationPop selectItemWithTag:PDConditionIs];
	
		scanner = [NSScanner scannerWithString:condition];
		while ( ![scanner isAtEnd] ) 
		{
			[scanner scanUpToString:@"'" intoString:nil];
			[scanner scanString:@"'" intoString:nil];
			[scanner scanUpToString:@"'" intoString:&value];
		}
		
		if ( value && ![value isEqualToString:@"^"])
			[stringConditionValue setStringValue:value];
	}
	
	else if ( [condition rangeOfString:@"keywords"].location == 0 || [condition rangeOfString:@"not keywords"].location == 0 ) 
	{
		NSScanner *scanner;
		NSString *value = nil;
		
		replacingView = stringConditionView;
		[keyPop selectItemWithTag:PDConditionKeywords];
		
		//if ( [condition rangeOfString:@"not "].location != NSNotFound )
		if ( [condition rangeOfString:@"not "].location == 0 )
			[stringOperationPop selectItemWithTag:PDConditionNotContains];
		else if ( [condition rangeOfString:@"contains"].location != NSNotFound )
			[stringOperationPop selectItemWithTag:PDConditionContains];
		else if ( [condition rangeOfString:@"beginswith"].location != NSNotFound )
			[stringOperationPop selectItemWithTag:PDConditionBeginsWith];
		else if ( [condition rangeOfString:@"endswith"].location != NSNotFound )
			[stringOperationPop selectItemWithTag:PDConditionEndsWith];
		else if ( [condition rangeOfString:@"matches"].location != NSNotFound )
			[stringOperationPop selectItemWithTag:PDConditionIs];
		
		scanner = [NSScanner scannerWithString:condition];
		while ( ![scanner isAtEnd] ) 
		{
			[scanner scanUpToString:@"'" intoString:nil];
			[scanner scanString:@"'" intoString:nil];
			[scanner scanUpToString:@"'" intoString:&value];
		}
		
		if ( value && ![value isEqualToString:@"^"])
			[stringConditionValue setStringValue:value];
	}
	
	else if ( [condition rangeOfString:@"content"].location == 0 || [condition rangeOfString:@"not content"].location == 0 ) 
	{
		NSScanner *scanner;
		NSString *value = nil;
		
		replacingView = stringConditionView;
		[keyPop selectItemWithTag:PDConditionContent];
		
		//if ( [condition rangeOfString:@"not "].location != NSNotFound )
		if ( [condition rangeOfString:@"not "].location == 0 )
			[stringOperationPop selectItemWithTag:PDConditionNotContains];
		else if ( [condition rangeOfString:@"contains"].location != NSNotFound )
			[stringOperationPop selectItemWithTag:PDConditionContains];
		else if ( [condition rangeOfString:@"beginswith"].location != NSNotFound )
			[stringOperationPop selectItemWithTag:PDConditionBeginsWith];
		else if ( [condition rangeOfString:@"endswith"].location != NSNotFound )
			[stringOperationPop selectItemWithTag:PDConditionEndsWith];
		else if ( [condition rangeOfString:@"matches"].location != NSNotFound )
			[stringOperationPop selectItemWithTag:PDConditionIs];
		
		scanner = [NSScanner scannerWithString:condition];
		while ( ![scanner isAtEnd] ) 
		{
			[scanner scanUpToString:@"'" intoString:nil];
			[scanner scanString:@"'" intoString:nil];
			[scanner scanUpToString:@"'" intoString:&value];
		}
		
		if ( value && ![value isEqualToString:@"^"])
			[stringConditionValue setStringValue:value];

	}
	
	else if ( [condition rangeOfString:@"entireEntry"].location == 0 || [condition rangeOfString:@"not entireEntry"].location == 0) 
	{
		NSScanner *scanner;
		NSString *value = nil;
		
		replacingView = stringConditionView;
		[keyPop selectItemWithTag:PDConditionEntire];
		
		//if ( [condition rangeOfString:@"not "].location != NSNotFound )
		if ( [condition rangeOfString:@"not "].location == 0 )
			[stringOperationPop selectItemWithTag:PDConditionNotContains];
		else if ( [condition rangeOfString:@"contains"].location != NSNotFound )
			[stringOperationPop selectItemWithTag:PDConditionContains];
		else if ( [condition rangeOfString:@"beginswith"].location != NSNotFound )
			[stringOperationPop selectItemWithTag:PDConditionBeginsWith];
		else if ( [condition rangeOfString:@"endswith"].location != NSNotFound )
			[stringOperationPop selectItemWithTag:PDConditionEndsWith];
		else if ( [condition rangeOfString:@"matches"].location != NSNotFound )
			[stringOperationPop selectItemWithTag:PDConditionIs];
		
		scanner = [NSScanner scannerWithString:condition];
		while ( ![scanner isAtEnd] ) {
			[scanner scanUpToString:@"'" intoString:nil];
			[scanner scanString:@"'" intoString:nil];
			[scanner scanUpToString:@"'" intoString:&value];
		}
		
		if ( value && ![value isEqualToString:@"^"])
			[stringConditionValue setStringValue:value];

	}
	
	else if ( [condition rangeOfString:@"in tags" options:NSBackwardsSearch].location == ( [condition length] - 7 ) || [condition rangeOfString:@"tags.@count"].location == 0 )
	{
		// split the string up as tags supports multiple items
		//	'%@' in[cd] tags
		//	not '%@' in[cd] tags
		
		int tokenOperation = -1;
		NSMutableArray *theTokens = [NSMutableArray array];
		
		if ( [condition isEqualToString:@"tags.@count == 0"] )
		{
			tokenOperation = PDConditionIsEmpty;
			[tagsField setEnabled:NO];
		}
		else if ( [condition isEqualToString:@"tags.@count != 0"] )
		{
			tokenOperation = PDConditionIsNotEmpty;
			[tagsField setEnabled:NO];
		}
		else
		{
			NSArray *thePieces = [condition componentsSeparatedByString:kAndSeparatorString];
			NSScanner *scanner;
			
            for ( NSString *aPiece in thePieces )
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
						tokenOperation = PDConditionNotContains;
					else
						tokenOperation = PDConditionContains;
				}
			}
			
			[tagsField setEnabled:YES];
		}
		
		if ( tokenOperation == -1 )
			tokenOperation = PDConditionContains;
		
		[tagsField setObjectValue:theTokens];
		[tagsOperationPop selectItemWithTag:tokenOperation];
		
		replacingView = tagsView;
		[keyPop selectItemWithTag:PDConditionTags];
	}
	
	else if ( [condition rangeOfString:@"dateInt"].location == 0 ) 
	{
		NSView *newDetailsView;
		replacingView = dateConditionView;
		[keyPop selectItemWithTag:PDConditionDate];
		
		if ( [condition rangeOfString:@"between"].location != NSNotFound ) 
		{
			NSScanner *scanner;
			NSString *dateAfter, *dateBefore;
			
			[dateOperationPop selectItemWithTag:PDConditionBetween];
			
			scanner = [NSScanner scannerWithString:condition];
			while ( ![scanner isAtEnd] ) 
			{
				[scanner scanUpToString:@"{" intoString:nil];
				[scanner scanString:@"{" intoString:nil];
				[scanner scanUpToString:@"," intoString:&dateAfter];
				[scanner scanString:@"," intoString:nil];
				[scanner scanUpToString:@"}" intoString:&dateBefore];
			}
			
			if ( dateAfter && dateBefore ) 
			{
				[dateAndLabel setHidden:NO];
				[dateConditionBValue setHidden:NO];
				
				[dateConditionAValue setDateValue:[NSCalendarDate dateWithString:dateAfter calendarFormat:@"%Y%m%d"]];
				
				[dateConditionBValue setDateValue:[NSCalendarDate dateWithString:dateBefore calendarFormat:@"%Y%m%d"]];
			}
			
			newDetailsView = dateDatedView;
		}
		else if ( [condition rangeOfString:@"after"].location != NSNotFound || [condition rangeOfString:@">="].location != NSNotFound 
					|| [condition rangeOfString:@"before"].location != NSNotFound || [condition rangeOfString:@"<="].location != NSNotFound ) 
		{
			
			NSScanner *scanner;
			int dateValue;
			
			if ( [condition rangeOfString:@"after"].location != NSNotFound || [condition rangeOfString:@">="].location != NSNotFound )
				[dateOperationPop selectItemWithTag:PDConditionAfter];
			else if ( [condition rangeOfString:@"before"].location != NSNotFound || [condition rangeOfString:@"<="].location != NSNotFound )
				[dateOperationPop selectItemWithTag:PDConditionBefore];
			
			scanner = [NSScanner scannerWithString:condition];
			while ( ![scanner isAtEnd] ) 
			{
				[scanner scanUpToString:@"=" intoString:nil];
				[scanner scanString:@"=" intoString:nil];
				[scanner scanInt:&dateValue];
			}
			
			[dateConditionAValue setDateValue:[NSCalendarDate dateWithString:
					[[NSNumber numberWithInt:dateValue] stringValue] calendarFormat:@"%Y%m%d"]];
			
			newDetailsView = dateDatedView;
				
		}
		else if ( [condition rangeOfString:@"inthelast" options:NSLiteralSearch range:NSMakeRange(0,[condition length])].location != NSNotFound ||
				[condition rangeOfString:@"inthenext" options:NSLiteralSearch range:NSMakeRange(0,[condition length])].location != NSNotFound )
		{
				
			if ( [condition rangeOfString:@"inthelast" options:NSLiteralSearch range:NSMakeRange(0,[condition length])].location != NSNotFound )
				[dateOperationPop selectItemWithTag:PDConditionInTheLast];
			else if ( [condition rangeOfString:@"inthenext" options:NSLiteralSearch range:NSMakeRange(0,[condition length])].location != NSNotFound )
				[dateOperationPop selectItemWithTag:PDConditionInTheNext];
			
			int dateTag, dateValue;
			NSScanner *theScanner = [NSScanner scannerWithString:condition];
			
			[theScanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil];
			[theScanner scanInt:&dateTag];
			[theScanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil];
			[theScanner scanInt:&dateValue];
			
			[dateNumberedPop selectItemWithTag:dateTag];
			[dateNumberedValue setIntValue:dateValue];
			
			newDetailsView = dateNumberedView;
		}
	
		if ( newDetailsView != dateDetailsView )
		{
			[dateDetailsView retain];
			
			[newDetailsView setFrame:[dateDetailsView frame]];
			[dateConditionView replaceSubview:dateDetailsView with:newDetailsView];
			
			dateDetailsView = newDetailsView;
		}
	}
	
	else if ( [condition rangeOfString:@"dateModifiedInt"].location == 0 )
	{
		NSView *newDetailsView;
		replacingView = dateConditionView;
		[keyPop selectItemWithTag:PDConditionModified];
		
		if ( [condition rangeOfString:@"between"].location != NSNotFound ) 
		{
			NSScanner *scanner;
			NSString *dateAfter, *dateBefore;
			
			[dateOperationPop selectItemWithTag:PDConditionBetween];
			
			scanner = [NSScanner scannerWithString:condition];
			while ( ![scanner isAtEnd] ) {
				[scanner scanUpToString:@"{" intoString:nil];
				[scanner scanString:@"{" intoString:nil];
				[scanner scanUpToString:@"," intoString:&dateAfter];
				[scanner scanString:@"," intoString:nil];
				[scanner scanUpToString:@"}" intoString:&dateBefore];
			}
			
			if ( dateAfter && dateBefore ) 
			{
				[dateAndLabel setHidden:NO];
				[dateConditionBValue setHidden:NO];
				
				[dateConditionAValue setDateValue:[NSCalendarDate dateWithString:dateAfter calendarFormat:@"%Y%m%d"]];
				[dateConditionBValue setDateValue:[NSCalendarDate dateWithString:dateBefore calendarFormat:@"%Y%m%d"]];
			}
			
			newDetailsView = dateDatedView;
		}
		else if ( [condition rangeOfString:@"after"].location != NSNotFound || [condition rangeOfString:@">="].location != NSNotFound 
					|| [condition rangeOfString:@"before"].location != NSNotFound || [condition rangeOfString:@"<="].location != NSNotFound ) 
		{
			NSScanner *scanner;
			int dateValue;
			
			if ( [condition rangeOfString:@"after"].location != NSNotFound || [condition rangeOfString:@">="].location != NSNotFound )
				[dateOperationPop selectItemWithTag:PDConditionAfter];
			else if ( [condition rangeOfString:@"before"].location != NSNotFound || [condition rangeOfString:@"<="].location != NSNotFound )
				[dateOperationPop selectItemWithTag:PDConditionBefore];
			
			scanner = [NSScanner scannerWithString:condition];
			while ( ![scanner isAtEnd] ) 
			{
				[scanner scanUpToString:@"=" intoString:nil];
				[scanner scanString:@"=" intoString:nil];
				[scanner scanInt:&dateValue];
			}
			
			[dateConditionAValue setDateValue:[NSCalendarDate dateWithString:
			[[NSNumber numberWithInt:dateValue] stringValue] calendarFormat:@"%Y%m%d"]];
			
			newDetailsView = dateDatedView;
				
		}
		else if ( [condition rangeOfString:@"inthelast" options:NSLiteralSearch range:NSMakeRange(0,[condition length])].location != NSNotFound 
					|| [condition rangeOfString:@"inthenext" options:NSLiteralSearch range:NSMakeRange(0,[condition length])].location != NSNotFound )
		{
				
			if ( [condition rangeOfString:@"inthelast" options:NSLiteralSearch range:NSMakeRange(0,[condition length])].location != NSNotFound )
				[dateOperationPop selectItemWithTag:PDConditionInTheLast];
			else if ( [condition rangeOfString:@"inthenext" options:NSLiteralSearch range:NSMakeRange(0,[condition length])].location != NSNotFound )
				[dateOperationPop selectItemWithTag:PDConditionInTheNext];
			
			int dateTag, dateValue;
			NSScanner *theScanner = [NSScanner scannerWithString:condition];
			
			[theScanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil];
			[theScanner scanInt:&dateTag];
			[theScanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil];
			[theScanner scanInt:&dateValue];
			
			[dateNumberedPop selectItemWithTag:dateTag];
			[dateNumberedValue setIntValue:dateValue];
			
			newDetailsView = dateNumberedView;
			
		}
	
		if ( newDetailsView != dateDetailsView )
		{
			[dateDetailsView retain];
			
			[newDetailsView setFrame:[dateDetailsView frame]];
			[dateConditionView replaceSubview:dateDetailsView with:newDetailsView];
			
			dateDetailsView = newDetailsView;
		}
	}
	
	else if ( [condition rangeOfString:@"dateDueInt"].location == 0 ) 
	{
		NSView *newDetailsView;
		replacingView = dateConditionView;
		[keyPop selectItemWithTag:PDConditionDateDue];
		
		if ( [condition rangeOfString:@"between"].location != NSNotFound ) 
		{
			NSScanner *scanner;
			NSString *dateAfter, *dateBefore;
			
			[dateOperationPop selectItemWithTag:PDConditionBetween];
			
			scanner = [NSScanner scannerWithString:condition];
			while ( ![scanner isAtEnd] ) {
				[scanner scanUpToString:@"{" intoString:nil];
				[scanner scanString:@"{" intoString:nil];
				[scanner scanUpToString:@"," intoString:&dateAfter];
				[scanner scanString:@"," intoString:nil];
				[scanner scanUpToString:@"}" intoString:&dateBefore];
			}
			
			if ( dateAfter && dateBefore ) 
			{
				[dateAndLabel setHidden:NO];
				[dateConditionBValue setHidden:NO];
				
				[dateConditionAValue setDateValue:[NSCalendarDate dateWithString:dateAfter calendarFormat:@"%Y%m%d"]];
				[dateConditionBValue setDateValue:[NSCalendarDate dateWithString:dateBefore calendarFormat:@"%Y%m%d"]];
			}
			
			newDetailsView = dateDatedView;
		}
		else if ( [condition rangeOfString:@"after"].location != NSNotFound || [condition rangeOfString:@">="].location != NSNotFound 
					|| [condition rangeOfString:@"before"].location != NSNotFound || [condition rangeOfString:@"<="].location != NSNotFound ) 
		{
			NSScanner *scanner;
			int dateValue;
			
			if ( [condition rangeOfString:@"after"].location != NSNotFound || [condition rangeOfString:@">="].location != NSNotFound )
				[dateOperationPop selectItemWithTag:PDConditionAfter];
			else if ( [condition rangeOfString:@"before"].location != NSNotFound || [condition rangeOfString:@"<="].location != NSNotFound )
				[dateOperationPop selectItemWithTag:PDConditionBefore];
			
			scanner = [NSScanner scannerWithString:condition];
			while ( ![scanner isAtEnd] ) 
			{
				[scanner scanUpToString:@"=" intoString:nil];
				[scanner scanString:@"=" intoString:nil];
				[scanner scanInt:&dateValue];
			}
			
			[dateConditionAValue setDateValue:[NSCalendarDate dateWithString:
					[[NSNumber numberWithInt:dateValue] stringValue] calendarFormat:@"%Y%m%d"]];
			
			newDetailsView = dateDatedView;
				
		}
		else if ( [condition rangeOfString:@"inthelast" options:NSLiteralSearch range:NSMakeRange(0,[condition length])].location != NSNotFound 
					|| [condition rangeOfString:@"inthenext" options:NSLiteralSearch range:NSMakeRange(0,[condition length])].location != NSNotFound )
		{
			if ( [condition rangeOfString:@"inthelast" options:NSLiteralSearch range:NSMakeRange(0,[condition length])].location != NSNotFound )
				[dateOperationPop selectItemWithTag:PDConditionInTheLast];
			else if ( [condition rangeOfString:@"inthenext" options:NSLiteralSearch range:NSMakeRange(0,[condition length])].location != NSNotFound )
				[dateOperationPop selectItemWithTag:PDConditionInTheNext];
			
			int dateTag, dateValue;
			NSScanner *theScanner = [NSScanner scannerWithString:condition];
			
			[theScanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil];
			[theScanner scanInt:&dateTag];
			[theScanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil];
			[theScanner scanInt:&dateValue];
			
			[dateNumberedPop selectItemWithTag:dateTag];
			[dateNumberedValue setIntValue:dateValue];
			
			newDetailsView = dateNumberedView;
		}
	
		if ( newDetailsView != dateDetailsView )
		{
			[dateDetailsView retain];
			
			[newDetailsView setFrame:[dateDetailsView frame]];
			[dateConditionView replaceSubview:dateDetailsView with:newDetailsView];
			
			dateDetailsView = newDetailsView;
		}
	}
	
	else if ( [condition rangeOfString:@"blogged"].location == 0 ) 
	{
		replacingView = nil;
		
		if ( [condition rangeOfString:@"YES"].location != NSNotFound )
			[keyPop selectItemWithTag:PDConditionBlogged];
		else
			[keyPop selectItemWithTag:PDConditionNotBlogged];
	}
	
	else if ( [condition rangeOfString:@"flagged"].location == 0 ) 
	{
		replacingView = markingConditionView;
		[keyPop selectItemWithTag:PDConditionMarking];
		
		if ( [condition rangeOfString:@"YES"].location != NSNotFound )
			[markingOperationPop selectItemWithTag:PDConditionMarkFlagged];
		else
			[markingOperationPop selectItemWithTag:PDConditionMarkNotFlagged];
		
		/*
		replacingView = nil;
		if ( [condition rangeOfString:@"YES"].location != NSNotFound )
			[keyPop selectItemWithTag:PDConditionFlagged];
		else
			[keyPop selectItemWithTag:PDConditionNotFlagged];
		*/
	}
	
	else if ( [condition rangeOfString:@"markedInt"].location == 0 ) 
	{
		replacingView = markingConditionView;
		[keyPop selectItemWithTag:PDConditionMarking];
		
		if ( [condition rangeOfString:@"OR" options:NSCaseInsensitiveSearch].location != NSNotFound )
			[markingOperationPop selectItemWithTag:PDConditionMarkFlaggedOrChecked];
		else if ( [condition rangeOfString:@"== 0"].location != NSNotFound )
			[markingOperationPop selectItemWithTag:PDConditionMarkNotFlaggedNorChecked];
		else if ( [condition rangeOfString:@"== 1"].location != NSNotFound )
			[markingOperationPop selectItemWithTag:PDConditionMarkFlagged];
		else if ( [condition rangeOfString:@"!= 1"].location != NSNotFound )
			[markingOperationPop selectItemWithTag:PDConditionMarkNotFlagged];
		else if ( [condition rangeOfString:@"== 2"].location != NSNotFound )
			[markingOperationPop selectItemWithTag:PDConditionMarkChecked];
		else if ( [condition rangeOfString:@"!= 2"].location != NSNotFound )
			[markingOperationPop selectItemWithTag:PDConditionMarkNotChecked];
	}
	
	else if ( [condition rangeOfString:@"labelInt"].location == 0 ) 
	{
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
		while ( ![scanner isAtEnd] ) 
		{
			[scanner scanUpToString:@"=" intoString:nil];
			[scanner scanString:@"=" intoString:nil];
			[scanner scanInt:&labelVal];
		}
		
		[labelPicker setLabelSelection:labelVal];
		[keyPop selectItemWithTag:PDConditionLabel];
	}
	
	if ( replacingView ) 
	{
		[replacingView setFrame:[specifiedConditionView bounds]];
		[specifiedConditionView addSubview:replacingView];
	}
}

- (NSString*) predicateString {
	
	//
	// builds the predicate string from our current conditions
	//
	
	NSString *returnString = nil;
	NSString *uttype = nil;
	
	//NSMutableCharacterSet *charSet = [[[NSCharacterSet punctuationCharacterSet] mutableCopyWithZone:[self zone]] autorelease];
	//[charSet addCharactersInString:@"\"'"];
	NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"\"'"];
	
	switch ( [[keyPop selectedItem] tag] ) {
		
		case PDConditionTitle:
			
			if ( [[stringConditionValue stringValue] length] == 0 )
			{
				if ( _allowsEmptyCondition == NO )
					return nil;
				else if ( [[stringOperationPop selectedItem] tag] == PDConditionNotContains )
					return [NSString stringWithFormat:@"not title matches '^'"];
				else
					return [NSString stringWithFormat:@"title matches '^'"];
			}
			
			else if ( [[stringConditionValue stringValue] rangeOfCharacterFromSet:charSet].location != NSNotFound )
				return nil;
			
			switch ( [[stringOperationPop selectedItem] tag] ) {
				
				case PDConditionContains:
					returnString = [NSString stringWithFormat:@"title contains[cd] '%@'", 
							[stringConditionValue stringValue]];
					break;
				
				case PDConditionNotContains:
					returnString = [NSString stringWithFormat:@"not title contains[cd] '%@'", 
							[stringConditionValue stringValue]];
					break;
				
				case PDConditionBeginsWith:
					returnString = [NSString stringWithFormat:@"title beginswith[cd] '%@'", 
							[stringConditionValue stringValue]];
					break;
				
				case PDConditionEndsWith:
					returnString = [NSString stringWithFormat:@"title endswith[cd] '%@'", 
							[stringConditionValue stringValue]];
					break;
				
				case PDConditionIs:
					returnString = [NSString stringWithFormat:@"title matches[cd] '%@'", 
							[stringConditionValue stringValue]];
					break;
				
			}
			
			break;
		
		case PDConditionCategory:
			
			if ( [[stringConditionValue stringValue] length] == 0 )
			{
				if ( _allowsEmptyCondition == NO )
					return nil;
				else if ( [[stringOperationPop selectedItem] tag] == PDConditionNotContains )
					return [NSString stringWithFormat:@"not category matches '^'"];
				else
					return [NSString stringWithFormat:@"category matches '^'"];
			}
			
			else if ( [[stringConditionValue stringValue] rangeOfCharacterFromSet:charSet].location != NSNotFound )
				return nil;
			
			switch ( [[stringOperationPop selectedItem] tag] ) {
				
				case PDConditionContains:
					returnString = [NSString stringWithFormat:@"category contains[cd] '%@'", 
							[stringConditionValue stringValue]];
					break;
				
				case PDConditionNotContains:
					returnString = [NSString stringWithFormat:@"not category contains[cd] '%@'", 
							[stringConditionValue stringValue]];
					break;
				
				case PDConditionBeginsWith:
					returnString = [NSString stringWithFormat:@"category beginswith[cd] '%@'", 
							[stringConditionValue stringValue]];
					break;
				
				case PDConditionEndsWith:
					returnString = [NSString stringWithFormat:@"category endswith[cd] '%@'", 
							[stringConditionValue stringValue]];
					break;
				
				case PDConditionIs:
					returnString = [NSString stringWithFormat:@"category matches[cd] '%@'", 
							[stringConditionValue stringValue]];
					break;
				
			}

			break;
		
		case PDConditionKeywords:
		// comments
				
			if ( [[stringConditionValue stringValue] length] == 0 )
			{
				if ( _allowsEmptyCondition == NO )
					return nil;
				else if ( [[stringOperationPop selectedItem] tag] == PDConditionNotContains )
					return [NSString stringWithFormat:@"not keywords matches '^'"];
				else
					return [NSString stringWithFormat:@"keywords matches '^'"];
			}
				
			else if ( [[stringConditionValue stringValue] rangeOfCharacterFromSet:charSet].location != NSNotFound )
				return nil;
			
			switch ( [[stringOperationPop selectedItem] tag] ) {
				
				case PDConditionContains:
					returnString = [NSString stringWithFormat:@"keywords contains[cd] '%@'", 
							[stringConditionValue stringValue]];
					break;
				
				case PDConditionNotContains:
					returnString = [NSString stringWithFormat:@"not keywords contains[cd] '%@'", 
							[stringConditionValue stringValue]];
					break;
				
				case PDConditionBeginsWith:
					returnString = [NSString stringWithFormat:@"keywords beginswith[cd] '%@'", 
							[stringConditionValue stringValue]];
					break;
				
				case PDConditionEndsWith:
					returnString = [NSString stringWithFormat:@"keywords endswith[cd] '%@'", 
							[stringConditionValue stringValue]];
					break;
				
				case PDConditionIs:
					returnString = [NSString stringWithFormat:@"keywords matches[cd] '%@'", 
							[stringConditionValue stringValue]];
					break;
				
			}
			
			break;
		
		case PDConditionContent:
			
			if ( [[stringConditionValue stringValue] length] == 0 )
			{
				if ( _allowsEmptyCondition == NO )
					return nil;
				else if ( [[stringOperationPop selectedItem] tag] == PDConditionNotContains )
					return [NSString stringWithFormat:@"not content matches '^'"];
				else
					return [NSString stringWithFormat:@"content matches '^'"];
			}
			
			else if ( [[stringConditionValue stringValue] rangeOfCharacterFromSet:charSet].location != NSNotFound )
				return nil;
			
			switch ( [[stringOperationPop selectedItem] tag] ) {
				
				case PDConditionContains:
					returnString = [NSString stringWithFormat:@"content contains[cd] '%@'", 
							[stringConditionValue stringValue]];
					break;
				
				case PDConditionNotContains:
					returnString = [NSString stringWithFormat:@"not content contains[cd] '%@'", 
							[stringConditionValue stringValue]];
					break;
				
				case PDConditionBeginsWith:
					returnString = [NSString stringWithFormat:@"content beginswith[cd] '%@'", 
							[stringConditionValue stringValue]];
					break;
				
				case PDConditionEndsWith:
					returnString = [NSString stringWithFormat:@"content endswith[cd] '%@'", 
							[stringConditionValue stringValue]];
					break;
				
				case PDConditionIs:
					returnString = [NSString stringWithFormat:@"content matches[cd] '%@'", 
							[stringConditionValue stringValue]];
					break;
				
			}
			
			break;
			
		case PDConditionEntire:
			
			if ( [[stringConditionValue stringValue] length] == 0 )
			{
				if ( _allowsEmptyCondition == NO )
					return nil;
				else if ( [[stringOperationPop selectedItem] tag] == PDConditionNotContains )
					return [NSString stringWithFormat:@"not entireEntry matches '^'"];
				else
					return [NSString stringWithFormat:@"entireEntry matches '^'"];
			}
				
			else if ( [[stringConditionValue stringValue] rangeOfCharacterFromSet:charSet].location != NSNotFound )
				return nil;
							
			switch ( [[stringOperationPop selectedItem] tag] ) {
				
				case PDConditionContains:
					returnString = [NSString stringWithFormat:@"entireEntry contains[cd] '%@'", 
							[stringConditionValue stringValue]];
					break;
				
				case PDConditionNotContains:
					returnString = [NSString stringWithFormat:@"not entireEntry contains[cd] '%@'", 
							[stringConditionValue stringValue]];
					break;
				
				case PDConditionBeginsWith:
					returnString = [NSString stringWithFormat:@"entireEntry beginswith[cd] '%@'", 
							[stringConditionValue stringValue]];
					break;
				
				case PDConditionEndsWith:
					returnString = [NSString stringWithFormat:@"entireEntry endswith[cd] '%@'", 
							[stringConditionValue stringValue]];
					break;
				
				case PDConditionIs:
					returnString = [NSString stringWithFormat:@"entireEntry matches[cd] '%@'", 
							[stringConditionValue stringValue]];
					break;
				
			}
			
			break;
			
		case PDConditionTags:
			
			if ( [[tagsOperationPop selectedItem] tag] == PDConditionIsEmpty )
			{
				//if ( _allowsEmptyCondition == NO )
				//	return nil;
				//else
					return [NSString stringWithFormat:@"tags.@count == 0"];
			}
					
			else if ( [[tagsOperationPop selectedItem] tag] == PDConditionIsNotEmpty )
			{
				//if ( _allowsEmptyCondition == NO )
				//	return nil;
				//else
					return [NSString stringWithFormat:@"tags.@count != 0"];
			}
			
			else if ( [[tagsField objectValue] count] == 0 )
			{
				
				if ( _allowsEmptyCondition == NO )
					return nil;
				else if ( [[tagsOperationPop selectedItem] tag] == PDConditionContains )
					return [NSString stringWithFormat:@"tags.@count == 0"];
				else if ( [[tagsOperationPop selectedItem] tag] == PDConditionNotContains )
					return [NSString stringWithFormat:@"tags.@count != 0"];
				else
					return nil;
			}
				
			else
			{
				
				NSMutableArray *tagConditions = [NSMutableArray array];
               
                for ( NSString *aTag in [tagsField objectValue] )
				{
					NSString *aTagCondition = nil;
					switch ( [[tagsOperationPop selectedItem] tag] ) {
				
					case PDConditionContains:
						aTagCondition = [NSString stringWithFormat:@"'%@' in tags", aTag];
						break;
					
					case PDConditionNotContains:
						aTagCondition = [NSString stringWithFormat:@"not '%@' in tags", aTag];
						break;
					
					}
					
					if ( aTagCondition != nil )
						[tagConditions addObject:aTagCondition];
				}
				
				NSString *completedCondition = [tagConditions componentsJoinedByString:kAndSeparatorString];
				//NSLog(completedCondition);
				return completedCondition;
			}
			
			break;
		
		case PDConditionDate:
			
			switch ( [[dateOperationPop selectedItem] tag] ) {
				
				case PDConditionBefore:
					returnString = [NSString stringWithFormat:@"dateInt <= %i", 
							[[[dateConditionAValue dateValue] descriptionWithCalendarFormat:
							@"%Y%m%d" timeZone:nil locale:nil] intValue]];
					break;
				
				case PDConditionAfter:
					returnString = [NSString stringWithFormat:@"dateInt >= %i", 
							[[[dateConditionAValue dateValue] descriptionWithCalendarFormat:
							@"%Y%m%d" timeZone:nil locale:nil] intValue]];
					break;
				
				case PDConditionBetween:
					returnString = [NSString stringWithFormat:@"dateInt between { %i , %i }", 
							[[[dateConditionAValue dateValue] descriptionWithCalendarFormat:
							@"%Y%m%d" timeZone:nil locale:nil] intValue],
							[[[dateConditionBValue dateValue] descriptionWithCalendarFormat:
							@"%Y%m%d" timeZone:nil locale:nil] intValue]];
					break;
				
				// dynamically updated
				case PDConditionInTheLast:
					if ( [self autogeneratesDynamicDates] )
					{
						NSString *todayString, *targetString;
						NSCalendarDate *today = [NSCalendarDate calendarDate];
						todayString = [today descriptionWithCalendarFormat:@"%Y%m%d"];
						
						if ( [[dateNumberedPop selectedItem] tag] == 0 )
							targetString = [[today dateByAddingYears:0 months:0 days:-[dateNumberedValue intValue] hours:0 minutes:0 seconds:0] 
									descriptionWithCalendarFormat:@"%Y%m%d"];
						else if ( [[dateNumberedPop selectedItem] tag] == 1 )
							targetString = [[today dateByAddingYears:0 months:0 days:-[dateNumberedValue intValue]*7 hours:0 minutes:0 seconds:0] 
									descriptionWithCalendarFormat:@"%Y%m%d"];
						else if ( [[dateNumberedPop selectedItem] tag] == 2 )
							targetString = [[today dateByAddingYears:0 months:-[dateNumberedValue intValue] days:0 hours:0 minutes:0 seconds:0] 
									descriptionWithCalendarFormat:@"%Y%m%d"];
						
						returnString = [NSString stringWithFormat:@"dateInt between { %@, %@ }", targetString, todayString];
					}
					else
						returnString = [NSString stringWithFormat:@"dateInt inthelast %i %i", 
								[[dateNumberedPop selectedItem] tag], [dateNumberedValue intValue]];
					break;
				
				// dynamically updated
				case PDConditionInTheNext:
					if ( [self autogeneratesDynamicDates] )
					{
						NSString *todayString, *targetString;
						NSCalendarDate *today = [NSCalendarDate calendarDate];
						todayString = [today descriptionWithCalendarFormat:@"%Y%m%d"];
						
						if ( [[dateNumberedPop selectedItem] tag] == 0 )
							targetString = [[today dateByAddingYears:0 months:0 days:[dateNumberedValue intValue] hours:0 minutes:0 seconds:0] 
									descriptionWithCalendarFormat:@"%Y%m%d"];
						else if ( [[dateNumberedPop selectedItem] tag] == 1 )
							targetString = [[today dateByAddingYears:0 months:0 days:[dateNumberedValue intValue]*7 hours:0 minutes:0 seconds:0] 
									descriptionWithCalendarFormat:@"%Y%m%d"];
						else if ( [[dateNumberedPop selectedItem] tag] == 2 )
							targetString = [[today dateByAddingYears:0 months:[dateNumberedValue intValue] days:0 hours:0 minutes:0 seconds:0] 
									descriptionWithCalendarFormat:@"%Y%m%d"];
						
						returnString = [NSString stringWithFormat:@"dateInt between { %@, %@ }", todayString, targetString];
					}
					else
						returnString = [NSString stringWithFormat:@"dateInt inthenext %i %i", 
								[[dateNumberedPop selectedItem] tag], [dateNumberedValue intValue]];
					break;
			}
			
			break;
		
		case PDConditionModified:
			
			switch ( [[dateOperationPop selectedItem] tag] ) {
				
				case PDConditionBefore:
					returnString = [NSString stringWithFormat:@"dateModifiedInt <= %i", 
							[[[dateConditionAValue dateValue] descriptionWithCalendarFormat:
							@"%Y%m%d" timeZone:nil locale:nil] intValue]];
					break;
				
				case PDConditionAfter:
					returnString = [NSString stringWithFormat:@"dateModifiedInt >= %i", 
							[[[dateConditionAValue dateValue] descriptionWithCalendarFormat:
							@"%Y%m%d" timeZone:nil locale:nil] intValue]];
					break;
				
				case PDConditionBetween:
					returnString = [NSString stringWithFormat:@"dateModifiedInt between { %i , %i }", 
							[[[dateConditionAValue dateValue] descriptionWithCalendarFormat:
							@"%Y%m%d" timeZone:nil locale:nil] intValue],
							[[[dateConditionBValue dateValue] descriptionWithCalendarFormat:
							@"%Y%m%d" timeZone:nil locale:nil] intValue]];
					break;
				
				// dynamically updated
				case PDConditionInTheLast:
					if ( [self autogeneratesDynamicDates] )
					{
						NSString *todayString, *targetString;
						NSCalendarDate *today = [NSCalendarDate calendarDate];
						
						todayString = [today descriptionWithCalendarFormat:@"%Y%m%d"];
						if ( [[dateNumberedPop selectedItem] tag] == 0 )
							targetString = [[today dateByAddingYears:0 months:0 days:-[dateNumberedValue intValue] hours:0 minutes:0 seconds:0] 
									descriptionWithCalendarFormat:@"%Y%m%d"];
						else if ( [[dateNumberedPop selectedItem] tag] == 1 )
							targetString = [[today dateByAddingYears:0 months:0 days:-[dateNumberedValue intValue]*7 hours:0 minutes:0 seconds:0] 
									descriptionWithCalendarFormat:@"%Y%m%d"];
						else if ( [[dateNumberedPop selectedItem] tag] == 2 )
							targetString = [[today dateByAddingYears:0 months:-[dateNumberedValue intValue] days:0 hours:0 minutes:0 seconds:0] 
									descriptionWithCalendarFormat:@"%Y%m%d"];
						
						returnString = [NSString stringWithFormat:@"dateModifiedInt between { %@, %@ }", targetString, todayString];
					}
					else
						returnString = [NSString stringWithFormat:@"dateModifiedInt inthelast %i %i", 
								[[dateNumberedPop selectedItem] tag], [dateNumberedValue intValue]];
					break;
				
				// dynamically updated
				case PDConditionInTheNext:
					if ( [self autogeneratesDynamicDates] )
					{
						NSString *todayString, *targetString;
						NSCalendarDate *today = [NSCalendarDate calendarDate];
						todayString = [today descriptionWithCalendarFormat:@"%Y%m%d"];
						
						if ( [[dateNumberedPop selectedItem] tag] == 0 )
							targetString = [[today dateByAddingYears:0 months:0 days:[dateNumberedValue intValue] hours:0 minutes:0 seconds:0] 
									descriptionWithCalendarFormat:@"%Y%m%d"];
						else if ( [[dateNumberedPop selectedItem] tag] == 1 )
							targetString = [[today dateByAddingYears:0 months:0 days:[dateNumberedValue intValue]*7 hours:0 minutes:0 seconds:0] 
									descriptionWithCalendarFormat:@"%Y%m%d"];
						else if ( [[dateNumberedPop selectedItem] tag] == 2 )
							targetString = [[today dateByAddingYears:0 months:[dateNumberedValue intValue] days:0 hours:0 minutes:0 seconds:0] 
									descriptionWithCalendarFormat:@"%Y%m%d"];
						
						returnString = [NSString stringWithFormat:@"dateModifiedInt between { %@, %@ }", todayString, targetString];
					}
					else
						returnString = [NSString stringWithFormat:@"dateModifiedInt inthenext %i %i", 
								[[dateNumberedPop selectedItem] tag], [dateNumberedValue intValue]];
					break;
			}
			
			break;
		
		case PDConditionDateDue:
			
			switch ( [[dateOperationPop selectedItem] tag] ) {
				
				case PDConditionBefore:
					returnString = [NSString stringWithFormat:@"dateDueInt <= %i", 
							[[[dateConditionAValue dateValue] descriptionWithCalendarFormat:
							@"%Y%m%d" timeZone:nil locale:nil] intValue]];
					break;
				
				case PDConditionAfter:
					returnString = [NSString stringWithFormat:@"dateDueInt >= %i", 
							[[[dateConditionAValue dateValue] descriptionWithCalendarFormat:
							@"%Y%m%d" timeZone:nil locale:nil] intValue]];
					break;
				
				case PDConditionBetween:
					returnString = [NSString stringWithFormat:@"dateDueInt between { %i , %i }", 
							[[[dateConditionAValue dateValue] descriptionWithCalendarFormat:
							@"%Y%m%d" timeZone:nil locale:nil] intValue],
							[[[dateConditionBValue dateValue] descriptionWithCalendarFormat:
							@"%Y%m%d" timeZone:nil locale:nil] intValue]];
					break;
				
				// dynamically updated
				case PDConditionInTheLast:
					if ( [self autogeneratesDynamicDates] )
					{
						NSString *todayString, *targetString;
						NSCalendarDate *today = [NSCalendarDate calendarDate];
						
						todayString = [today descriptionWithCalendarFormat:@"%Y%m%d"];
						if ( [[dateNumberedPop selectedItem] tag] == 0 )
							targetString = [[today dateByAddingYears:0 months:0 days:-[dateNumberedValue intValue] hours:0 minutes:0 seconds:0] 
									descriptionWithCalendarFormat:@"%Y%m%d"];
						else if ( [[dateNumberedPop selectedItem] tag] == 1 )
							targetString = [[today dateByAddingYears:0 months:0 days:-[dateNumberedValue intValue]*7 hours:0 minutes:0 seconds:0] 
									descriptionWithCalendarFormat:@"%Y%m%d"];
						else if ( [[dateNumberedPop selectedItem] tag] == 2 )
							targetString = [[today dateByAddingYears:0 months:-[dateNumberedValue intValue] days:0 hours:0 minutes:0 seconds:0] 
									descriptionWithCalendarFormat:@"%Y%m%d"];
						
						returnString = [NSString stringWithFormat:@"dateDueInt between { %@, %@ }", targetString, todayString];
					}
					else
						returnString = [NSString stringWithFormat:@"dateDueInt inthelast %i %i", 
								[[dateNumberedPop selectedItem] tag], [dateNumberedValue intValue]];
					break;
				
				// dynamically updated
				case PDConditionInTheNext:
					if ( [self autogeneratesDynamicDates] )
					{
						NSString *todayString, *targetString;
						NSCalendarDate *today = [NSCalendarDate calendarDate];
						todayString = [today descriptionWithCalendarFormat:@"%Y%m%d"];
						
						if ( [[dateNumberedPop selectedItem] tag] == 0 )
							targetString = [[today dateByAddingYears:0 months:0 days:[dateNumberedValue intValue] hours:0 minutes:0 seconds:0] 
									descriptionWithCalendarFormat:@"%Y%m%d"];
						else if ( [[dateNumberedPop selectedItem] tag] == 1 )
							targetString = [[today dateByAddingYears:0 months:0 days:[dateNumberedValue intValue]*7 hours:0 minutes:0 seconds:0] 
									descriptionWithCalendarFormat:@"%Y%m%d"];
						else if ( [[dateNumberedPop selectedItem] tag] == 2 )
							targetString = [[today dateByAddingYears:0 months:[dateNumberedValue intValue] days:0 hours:0 minutes:0 seconds:0] 
									descriptionWithCalendarFormat:@"%Y%m%d"];
						
						returnString = [NSString stringWithFormat:@"dateDueInt between { %@, %@ }", todayString, targetString];
					}
					else
						returnString = [NSString stringWithFormat:@"dateDueInt inthenext %i %i", 
								[[dateNumberedPop selectedItem] tag], [dateNumberedValue intValue]];
					break;
			}
			
			break;
		
		case PDConditionBlogged:
			
			// much simpler
			return [NSString stringWithString:@"blogged == YES"];
			break;
			
		case PDConditionNotBlogged:
		
			return [NSString stringWithString:@"blogged == NO"];
			break;
			
		case PDConditionFlagged:
			
			// much simpler
			return [NSString stringWithString:@"flaggedBool == YES"];
			break;
		
		case PDConditionNotFlagged:
			
			return [NSString stringWithString:@"flaggedBool == NO"];
			break;
		
		case PDConditionLabel:
			
			switch ( [[labelOperationPop selectedItem] tag] ) {
				
				case PDConditionContains:		// is
					returnString = [NSString stringWithFormat:@"labelInt == %i", [labelPicker labelSelection]];
					break;
				
				case PDConditionNotContains:	// is not
					returnString = [NSString stringWithFormat:@"labelInt != %i", [labelPicker labelSelection]];
					break;
				
			}
			
			break;
			
		case PDConditionMarking:
			
			switch ( [[markingOperationPop selectedItem] tag] ) {
				
				case PDConditionMarkFlagged:
					returnString = [NSString stringWithString:@"markedInt == 1"];
					break;
				case PDConditionMarkNotFlagged:
					returnString = [NSString stringWithString:@"markedInt != 1"];
					break;
				case PDConditionMarkChecked:
					returnString = [NSString stringWithString:@"markedInt == 2"];
					break;
				case PDConditionMarkNotChecked:
					returnString = [NSString stringWithString:@"markedInt != 2"];
					break;
				case PDConditionMarkFlaggedOrChecked:
					returnString = [NSString stringWithString:@"markedInt == 1 OR markedInt == 2"];
					break;
				case PDConditionMarkNotFlaggedNorChecked:
					returnString = [NSString stringWithString:@"markedInt == 0"];
					break;
				
			}
			
			break;
		
		case PDConditionResources:
			
			if ( [[resourcesTypePop selectedItem] tag] == 8 )
			{
				// special case for the correspondence type
				if ( [[resourcesOperationPop selectedItem] tag] == 0 )
					returnString = [NSString stringWithFormat:@"(allResourceTypes contains[cd] '%@') OR (allResourceTypes contains[cd] '%@') OR (allResourceTypes contains[cd] '%@')", 
					(NSString*)kUTTypeMessage, @"com.apple.mail.emlx", @"com.apple.ichat.ichat"];
				else
					returnString = [NSString stringWithFormat:@"(not allResourceTypes contains[cd] '%@') AND (not allResourceTypes contains[cd] '%@') AND (not allResourceTypes contains[cd] '%@')", 
					(NSString*)kUTTypeMessage, @"com.apple.mail.emlx", @"com.apple.ichat.ichat"];
			}
			else
			{
				switch ( [[resourcesTypePop selectedItem] tag] )
				{
					case PDResourceTypeWebPage:
						uttype = (NSString*)kUTTypeURL;
						break;
					case PDResourceTypeWebArchive:
						uttype = (NSString*)kUTTypeWebArchive;
						break;
					case PDResourceTypeImage:
						uttype = (NSString*)kUTTypeImage;
						break;
					case PDResourceTypeAudio:
						uttype = (NSString*)kUTTypeAudio;
						break;
					case PDResourceTypeVideo:
						uttype = (NSString*)@"public.movie";
						break;
					case PDResourceTypePDFDocument:
						uttype = (NSString*)kUTTypePDF;
						break;
					case PDResourceTypeABRecord:
						uttype = @"com.journler.abperson";
						break;
					case PDResourceTypeTextDocument:
						uttype = (NSString*)kUTTypePlainText;
						break;
					
					case PDResourceTypeAny:
						uttype = (NSString*)kUTTypeItem;
						break;
				}
			
				if ( [[resourcesOperationPop selectedItem] tag] == 0 )
					returnString = [NSString stringWithFormat:@"allResourceTypes contains[cd] '%@'", uttype];
				else
					returnString = [NSString stringWithFormat:@"not allResourceTypes contains[cd] '%@'", uttype];
			}
			
			break;
	}
	
	return returnString;
	
}

#pragma mark -

- (IBAction)addCondition:(id)sender
{
	[target performSelector:@selector(addCondition:) withObject:self];
	
	//NSLog([self predicateString]); -- for debugging
	//[self _sendUpdateIfRequested];
}

- (IBAction)removeCondition:(id)sender
{
	[target performSelector:@selector(removeCondition:) withObject:self];
	//[self _sendUpdateIfRequested];
}

- (IBAction) addOrRemoveCondition:(id)sender
{
	int clickedSegment = [sender selectedSegment];
    int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
	
	if ( clickedSegmentTag == 0 ) [self removeCondition:self];
	else if ( clickedSegmentTag == 1 ) [self addCondition:self];
	else NSBeep();
}

- (IBAction)changeConditionKey:(id)sender
{
	//
	// remove and add superviews as needed
	//
	
	NSView *replacingView = nil;
	
	//
	// cheat if the sender is the popup button rather than one of the menu items therein
	
	if ( [sender isKindOfClass:[NSPopUpButton class]] )
		[sender setTag:[[sender selectedItem] tag]];
	
	
	if ( [[specifiedConditionView subviews] count] != 0 )
		[[[specifiedConditionView subviews] objectAtIndex:0] removeFromSuperview];
	
	switch ( [sender tag] ) {
		
		case PDConditionTitle:
			replacingView = stringConditionView;
			break;
		
		case PDConditionCategory:
			replacingView = stringConditionView;
			break;
		
		case PDConditionKeywords:
			replacingView = stringConditionView;
			break;
		
		case PDConditionContent:
			replacingView = stringConditionView;
			break;
		
		case PDConditionEntire:
			replacingView = stringConditionView;
			break;
		
		case PDConditionDate:
			replacingView = dateConditionView;
			break;
				
		case PDConditionModified:
			replacingView = dateConditionView;
			break;
		
		case PDConditionDateDue:
			replacingView = dateConditionView;
			break;
		
		case PDConditionLabel:
			replacingView = labelConditionView;
			break;
			
		case PDConditionMarking:
			replacingView = markingConditionView;
			break;
		
		case PDConditionResources:
			replacingView = resourcesConditionView;
			break;
		
		case PDConditionTags:
			replacingView = tagsView;
			break;
	}
	
	if ( replacingView ) {
		[replacingView setFrame:[specifiedConditionView bounds]];
		[specifiedConditionView addSubview:replacingView];
	}

	if ( [sender isKindOfClass:[NSPopUpButton class]] )
		[sender setTag:0];
	
	[self _sendUpdateIfRequested];
	
}

#pragma mark -

- (IBAction)changeMarkingCondition:(id)sender 
{
	
	if ( [sender isKindOfClass:[NSPopUpButton class]] )
		[sender setTag:[[sender selectedItem] tag]];
	
	// no further action required
	if ( [sender isKindOfClass:[NSPopUpButton class]] )
		[sender setTag:0];
	
	[self _sendUpdateIfRequested];
}

- (IBAction)changeStringCondition:(id)sender
{
	// cheat if the sender is the popup button rather than one of the menu items therein
	if ( [sender isKindOfClass:[NSPopUpButton class]] )
		[sender setTag:[[sender selectedItem] tag]];
	
	// no further action required
	if ( [sender isKindOfClass:[NSPopUpButton class]] )
		[sender setTag:0];
	
	[self _sendUpdateIfRequested];
}

- (IBAction)changeDateCondition:(id)sender
{
	// cheat if the sender is the popup button rather than one of the menu items therein
	if ( [sender isKindOfClass:[NSPopUpButton class]] )
		[sender setTag:[[sender selectedItem] tag]];
	
	int senderTag = [sender tag];
	NSView *newDetailsView = nil;
	
	if ( senderTag == PDConditionBefore || senderTag == PDConditionAfter || senderTag == PDConditionBetween )
	{
		BOOL toHide = !(senderTag == PDConditionBetween);
		[dateAndLabel setHidden:toHide];
		[dateConditionBValue setHidden:toHide];
		
		newDetailsView = dateDatedView;
	}
	else if ( senderTag == PDConditionInTheLast || senderTag == PDConditionInTheNext )
	{
		newDetailsView = dateNumberedView;
		[dateNumberedPop selectItemWithTag:PDConditionDay];
		//[dateNumberedValue setIntValue:1];
	}
	
	if ( newDetailsView != dateDetailsView )
	{
		[dateDetailsView retain];
		
		[newDetailsView setFrame:[dateDetailsView frame]];
		[dateConditionView replaceSubview:dateDetailsView with:newDetailsView];
		
		dateDetailsView = newDetailsView;
	}
	
	/*
	switch ( [sender tag] ) 
	{
	case 2:
		toHide = NO;
		break;
	}
	
	[dateAndLabel setHidden:toHide];
	[dateConditionBValue setHidden:toHide];
	
	if ( [dateAndLabel isHidden] && !toHide || ![dateAndLabel isHidden] && toHide ) {
	
		NSViewAnimation *theAnim;
							
		NSDictionary *theDict = [[NSDictionary alloc] initWithObjectsAndKeys:
				dateAndLabel, NSViewAnimationTargetKey, 
				( toHide ? NSViewAnimationFadeOutEffect : NSViewAnimationFadeInEffect ),
					NSViewAnimationEffectKey, nil];
		
		NSDictionary *otherDict = [[NSDictionary alloc] initWithObjectsAndKeys:
				dateConditionBValue, NSViewAnimationTargetKey, 
				( toHide ? NSViewAnimationFadeOutEffect : NSViewAnimationFadeInEffect ), 
					NSViewAnimationEffectKey, nil];
		
		theAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray
			arrayWithObjects:theDict, otherDict, nil]];
		[theAnim startAnimation];
		
		// clean up
		[theAnim release];
		[theDict release];
		[otherDict release];
	
	}
	*/
	
	if ( [sender isKindOfClass:[NSPopUpButton class]] )
		[sender setTag:0];
	
	[self _sendUpdateIfRequested];
}

- (IBAction) changeTagsCondition:(id)sender
{
	int sendersTag = ( [sender isKindOfClass:[NSPopUpButton class]] ? [[sender selectedItem] tag] : [sender tag] );
	[tagsField setEnabled:( sendersTag != PDConditionIsEmpty && sendersTag != PDConditionIsNotEmpty )];
	
	[self _sendUpdateIfRequested];
	
	// no further action required
}

#pragma mark -

- (void) setRemoveButtonEnabled:(BOOL)enabled 
{
	[removeButton setEnabled:enabled];
	[addAndRemoveButton setEnabled:enabled forSegment:0];
}

- (id) selectableView 
{
	// return the text field if that's the kind of condition I am, otherwise nil
	NSView *theView = nil;
	int selTag = [[keyPop selectedItem] tag];
	
	if ( selTag == PDConditionTitle || selTag == PDConditionKeywords || selTag == PDConditionCategory 
			|| selTag == PDConditionContent || selTag == PDConditionEntire )
		theView = stringConditionValue;
	else if ( selTag == PDConditionTags )
		theView = tagsField;
	else
		theView = nil;
	
	return theView;
}

- (void) removeFromSuper 
{
	[conditionView removeFromSuperviewWithoutNeedingDisplay];
}

#pragma mark -
#pragma mark NSTokenField Delegation

- (BOOL)tokenField:(NSTokenField *)tokenField hasMenuForRepresentedObject:(id)representedObject
{
	return NO;
}

- (NSMenu *)tokenField:(NSTokenField *)tokenField menuForRepresentedObject:(id)representedObject
{
	return nil;
}

- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring 
	indexOfToken:(int)tokenIndex indexOfSelectedItem:(int *)selectedIndex
{
	NSArray *completions = nil;
	
	if ( [target respondsToSelector:@selector(tokenField:completionsForSubstring:indexOfToken:indexOfSelectedItem:)] )
		completions = [target tokenField:tokenField completionsForSubstring:substring 
		indexOfToken:tokenIndex indexOfSelectedItem:selectedIndex];
		
	return completions;
}

- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(unsigned)index
{
	NSMutableArray *modifiedArray = [NSMutableArray array];
	
    for ( NSString *aString in tokens )
	{
		if ( ![aString isOnlyWhitespace] )
			//[modifiedArray addObject:[aString lowercaseString]];
			[modifiedArray addObject:aString];
	}
	
	return modifiedArray;
}

@end
