//
//  PDTokenField.h
//  Journler
//
//  Created by Philip Dow on 8/20/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//
//	Note that PDTokenField does not require PDTokenFieldCell
//

#import <Cocoa/Cocoa.h>


@interface PDTokenField : NSTokenField {

}

@end

@interface NSObject (PDTokenFieldDelegate)

- (void)tokenField:(PDTokenField *)tokenField didReadTokens:(NSArray*)theTokens fromPasteboard:(NSPasteboard *)pboard;

@end