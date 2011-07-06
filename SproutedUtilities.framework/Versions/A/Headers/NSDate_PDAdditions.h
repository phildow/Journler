//
//  NSDate_PDAdditions.h
//  Journler
//
//  Created by Phil Dow on 1/10/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSDate (PDAdditions)

- (BOOL) fallsOnSameDay:(NSDate*)aDate;
- (NSString*) descriptionAsDifferenceBetweenDate:(NSDate*)aDate;

@end
