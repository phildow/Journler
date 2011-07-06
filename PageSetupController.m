#import "PageSetupController.h"

@implementation PageSetupController

static PageSetupController *sharedPageSetupController = nil;

+ (id) sharedPageSetup {

    if (!sharedPageSetupController) {
        sharedPageSetupController = [[PageSetupController allocWithZone:NULL] init];
    }

    return sharedPageSetupController;
}

- (id) init {
	if ( self = [super init] ) {
		[NSBundle loadNibNamed:@"PageSetupAccessory" owner:self];
	}
	return self;
}

- (void) dealloc {
	[contentView release];
		contentView = nil;
	
	[super dealloc];
}


- (NSView*) contentView { return contentView; }

@end
