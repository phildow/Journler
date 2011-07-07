//
//  JournlerResourceTest.m
//  Journler
//
//  Created by Philip Dow on 8/27/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import "JournlerResourceTest.h"
#import "JournlerResource.h"

@implementation JournlerResourceTest

- (void) testOriginalPathDerivation
{
	JournlerResource *aResource = [[[JournlerResource alloc] initFileResource:@"/Volumes/External HD 1/SomeFile.zip"] autorelease];
	STAssertNil([aResource originalPath], @"");
}

@end
