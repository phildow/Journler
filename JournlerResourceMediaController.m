//
//  JournlerResourceMediaController.m
//  Journler
//
//  Created by Philip Dow on 10/29/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "JournlerResourceMediaController.h"
#import "ResourceInfoView.h"
#import "JournlerJournal.h"
#import "JournlerResource.h"

#import <SproutedInterface/SproutedInterface.h>

@implementation JournlerResourceMediaController

- (id) init
{
	if ( self = [super init] )
	{
		[NSBundle loadNibNamed:@"JournlerResourceMediaView" owner:self];
	}
	
	return self;
}

- (void) awakeFromNib
{
	int borders[4] = {1,0,0,0};
	PDBorderedView *borderedContent = (PDBorderedView*)[self contentView];
	[borderedContent setBorders:borders];
}

- (BOOL) loadURL:(NSURL*)aURL 
{
	BOOL success = NO;
	JournlerObject *journlerObject = [self representedObject];
	
	if ( journlerObject == nil || ![journlerObject isKindOfClass:[JournlerResource class]] )
	{
		success = NO;
	}
	else
	{
		success = YES;
		[infoView setResource:(JournlerResource*)journlerObject];
	}
	
	return success;
}

@end
