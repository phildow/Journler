#import "ActivityViewer.h"
#import "JournlerJournal.h"

static NSString *kActivityViewerContext = @"ActivityViewerContext";

@implementation ActivityViewer

+ (id)sharedActivityViewer
{
    static ActivityViewer *sharedActivityViewer = nil;

    if (!sharedActivityViewer) 
	{
        sharedActivityViewer = [[ActivityViewer allocWithZone:NULL] init];
    }

    return sharedActivityViewer;
}

- (id) init
{
	return [self initWithJournal:nil];
}

- (id) initWithJournal:(JournlerJournal*)aJournal
{
	if ( self = [super initWithWindowNibName:@"ActivityViewer"] ) 
	{
		[self setWindowFrameAutosaveName:@"ActivityViewer"];
		
		journal = [aJournal retain];
		[journal addObserver:self 
				forKeyPath:@"activity" 
				options:0 
				context:kActivityViewerContext];
		
		[self retain];
	}
	
	return self;
}

- (void) windowDidLoad
{
	NSString *activity = [journal valueForKey:@"activity"];
	[textView setString:activity];
	[textView scrollRangeToVisible:NSMakeRange([activity length],0)];
}

- (void) dealloc
{
	#ifdef __DEBUG__
	NSLog(@"%@ %s", [self className], _cmd);
	#endif __DEBUG__
	
	[journal release];
	[super dealloc];
}

- (void)windowWillClose:(NSNotification *)aNotification 
{
	#ifdef __DEBUG__
	NSLog(@"%@ %s", [self className], _cmd);
	#endif __DEBUG__
	
	//[journal removeObserver:self forKeyPath:@"activity"];
	//[self autorelease];
}

- (JournlerJournal*) journal
{
	return journal;
}

- (void) setJournal:(JournlerJournal*)aJournal
{
	if ( journal != aJournal )
	{
		[journal release];
		[journal removeObserver:self forKeyPath:@"activity"];
		
		journal = [aJournal retain];
		
		[journal addObserver:self 
				forKeyPath:@"activity" 
				options:0 
				context:kActivityViewerContext];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath 
		ofObject:(id)object 
		change:(NSDictionary *)change 
		context:(void *)context
{
	//if ( object == journal && [keyPath isEqualToString:@"activity"] )
	if ( context == kActivityViewerContext )
	{
		NSString *activity = [journal valueForKey:@"activity"];
		[textView setString:activity];
		[textView scrollRangeToVisible:NSMakeRange([activity length],0)];
	}
	else
	{
		[super observeValueForKeyPath:keyPath 
				ofObject:object 
				change:change 
				context:context];
	}
}

@end
