//
//  ResourceInfoController.m
//  Journler
//
//  Created by Philip Dow on 1/21/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ResourceInfoController.h"
#import "ResourceInfoView.h"
#import "JournlerResource.h"

@implementation ResourceInfoController

- (id) init
{
	return [self initWithResource:nil alignment:ResourceInfoAlignLeft];
}

- (id) initWithResource:(JournlerResource*)aResource alignment:(ResourceInfoAlignment)viewAlignment
{
	if ( self = [super initWithWindowNibName:@"ResourceInfoPanel" owner:self] )
	{
		[self retain];
	}
	return self;
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[self autorelease];
}

#pragma mark -

- (JournlerResource*) resource
{
	return [infoView resource];
}

- (void) setResource:(JournlerResource*)aResource
{
	if ( ![self isWindowLoaded] ) [self window];
	[infoView setResource:aResource];
	[[self window] setTitle:[aResource valueForKey:@"title"]]; 
}

- (ResourceInfoAlignment) viewAlignment
{
	return [infoView viewAlignment];
}

- (void) setViewAlignment:(ResourceInfoAlignment)alignment
{
	if ( ![self isWindowLoaded] ) [self window];
	[infoView setViewAlignment:alignment];
}

@end
