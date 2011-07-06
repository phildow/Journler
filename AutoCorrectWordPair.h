//
//  AutoCorrectWordPair.h
//  Journler
//
//  Created by Phil Dow on 11/17/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AutoCorrectWordPair : NSObject {
	
	NSString *misspelledWord;
	NSString *correctWord;
}

- (id) initWithMisspelledWord:(NSString*)incorrect correctWord:(NSString*)correct;

- (NSString*) misspelledWord;
- (void) setMisspelledWord:(NSString*)aString;

- (NSString*) correctWord;
- (void) setCorrectWord:(NSString*)aString;

@end
