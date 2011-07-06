//
//  JournlerAddressBookWindow.m
//  Journler
//
//  Created by Philip Dow on 11/12/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "JournlerAddressBookWindow.h"


@implementation JournlerAddressBookWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation
{
	// textured on 10.5 leopard
	if ( [NSWindow instancesRespondToSelector:@selector(autorecalculatesContentBorderThicknessForEdge:)] )
		windowStyle |= NSTexturedBackgroundWindowMask;
		
	return [super initWithContentRect:contentRect styleMask:windowStyle backing:bufferingType defer:deferCreation];
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation screen:(NSScreen *)screen
{
	// textured on 10.5 leopard
	if ( [NSWindow instancesRespondToSelector:@selector(autorecalculatesContentBorderThicknessForEdge:)] )
		windowStyle |= NSTexturedBackgroundWindowMask;
		
	return [super initWithContentRect:contentRect styleMask:windowStyle backing:bufferingType defer:deferCreation screen:screen];
}

@end
