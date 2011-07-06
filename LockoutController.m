//
//  LockoutController.m
//  Journler
//
//  Created by Phil Dow on 10/24/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "LockoutController.h"
#import "NSString+JournlerAdditions.h"

#import <SproutedUtilities/SproutedUtilities.h>
#import <SproutedInterface/SproutedInterface.h>

#warning progress indicator: progress

@implementation LockoutController

- (id) initWithPassword:(NSString*)aString
{
	if ( self = [super initWithWindowNibName:@"Lockout"] ) 
	{
		numAttempts = 1;
		mode = kLockoutModePassword;
		checksum = nil;
		validatedPassword = nil;
		password = [aString copyWithZone:[self zone]];
	}
	return self;
}

- (id) initWithChecksum:(NSString*)aString
{
	if ( self = [super initWithWindowNibName:@"Lockout"] ) 
	{
		numAttempts = 1;
		mode = kLockoutModeChecksum;
		password = nil;
		validatedPassword = nil;
		checksum = [aString copyWithZone:[self zone]];
	}
	return self;
}

- (void) awakeFromNib
{
	int borders[4] = {0,0,0,0};
	[gradient setBorders:borders];
	[gradient setBordered:NO];
}

- (void) dealloc 
{
	[password release];
	[checksum release];
	[validatedPassword release];
	
	[super dealloc];
}

#pragma mark -

- (BOOL) confirmPassword 
{
	return ( [NSApp runModalForWindow:[self window]] == NSRunStoppedResponse );
}

- (BOOL) confirmChecksum
{
	return ( [NSApp runModalForWindow:[self window]] == NSRunStoppedResponse );
}

- (NSString*) validatedPassword
{
	return validatedPassword;
}

#pragma mark -

- (IBAction) okay:(id)sender 
{
	//NSLog(@"%@ %s - beginning",[self className],_cmd);
	
	NSString *passwordCheck = [passwordField stringValue];
	
	if ( mode == kLockoutModePassword )
	{
		//NSLog(@"%@ %s - kLockoutModePassword, beginning",[self className],_cmd);
		
		if ( [passwordCheck isEqualToString:password] ) 
		{
			//NSLog(@"%@ %s - correct password, stopping modal, beginning",[self className],_cmd);
			
			validatedPassword = [passwordCheck retain];
			[NSApp stopModal];
			
			//NSLog(@"%@ %s - correct password, stopping modal, ending",[self className],_cmd);
		}
		else 
		{
			//NSLog(@"%@ %s - incorrect password, beginning",[self className],_cmd);
			
			NSBeep();
			if ( ++numAttempts > 3 )
				[NSApp abortModal];
				
			[attemptsField setStringValue:[NSString stringWithFormat:@"%i/3",numAttempts]];
			
			//NSLog(@"%@ %s - incorrect password, ending",[self className],_cmd);
		}
		
		//NSLog(@"%@ %s - kLockoutModePassword, ending",[self className],_cmd);
	}
	else if ( mode == kLockoutModeChecksum )
	{
		//NSLog(@"%@ %s - kLockoutModeChecksum, beginning",[self className],_cmd);
		
		NSString *aDigest = [passwordCheck journlerMD5Digest];
		if ( [aDigest isEqualToString:checksum] ) 
		{
			//NSLog(@"%@ %s - correct password, stopping modal, beginning",[self className],_cmd);
			
			validatedPassword = [passwordCheck retain];
			[NSApp stopModal];
			
			//NSLog(@"%@ %s - correct password, stopping modal, ending",[self className],_cmd);
		}
		else 
		{
			//NSLog(@"%@ %s - incorrect password, beginning",[self className],_cmd);
			
			NSBeep();
			if ( ++numAttempts > 3 )
				[NSApp abortModal];
				
			[attemptsField setStringValue:[NSString stringWithFormat:@"%i/3",numAttempts]];
			
			//NSLog(@"%@ %s - incorrect password, ending",[self className],_cmd);
		}
		
		//NSLog(@"%@ %s - kLockoutModeChecksum, ending",[self className],_cmd);
	}
	
	//NSLog(@"%@ %s - ending",[self className],_cmd);
}

- (IBAction) cancel:(id)sender 
{
	[NSApp abortModal];
}

- (IBAction) hide:(id)sender 
{	
	[NSApp hide:sender];
}

- (IBAction) unhide:(id)sender
{
	[[self window] setDefaultButtonCell:[okButton cell]];
	[[self window] enableKeyEquivalentForDefaultButtonCell];
}

- (IBAction) showProgressIndicator:(id)sender
{
	//NSLog(@"%@ %s - beginning",[self className],_cmd);
	
	if ( ![self isWindowLoaded] )
		[self window];
	
	//NSLog(@"[progress setIndeterminate:YES]");
	[progress setIndeterminate:YES];
	
	//NSLog(@"[progress setHidden:NO]");
	[progress setHidden:NO];
	
	//NSLog(@"[progressLabel setHidden:NO]");
	[progressLabel setHidden:NO];
	
	//NSLog(@"[progressLabel display]");
	[progressLabel display];
	
	//NSLog(@"[progress startAnimation:sender]");
	[progress startAnimation:sender];
	
	//[[self window] display];
	
	//NSLog(@"%@ %s - ending",[self className],_cmd);
}

- (IBAction) hideProgressIndicator:(id)sender
{
	if ( ![self isWindowLoaded] )
		[self window];

	[progress stopAnimation:sender];
	[progress setHidden:YES];
	[progressLabel setHidden:YES];
	
	//[[self window] display];
}

- (IBAction) enableLockedOutControls:(id)sender
{
	if ( ![self isWindowLoaded] )
		[self window];

	[lockoutField setHidden:NO];
	[hideButton setHidden:NO];
}

@end
