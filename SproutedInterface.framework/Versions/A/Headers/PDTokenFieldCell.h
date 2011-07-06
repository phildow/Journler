//
//  PDTokenFieldCell.h
//  Journler
//
//  Created by Phil Dow on 7/16/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//
//	Note that PDTokenFieldCell does not require PDTokenField
//

#import <Cocoa/Cocoa.h>


@interface PDTokenFieldCell : NSTokenFieldCell {

}

@end

@interface NSTokenFieldCell (SuperImplemented)

- (id) _tokensFromPasteboard:(id)fp8;

@end

@interface NSObject (PDTokenFieldCellDelegate)

- (void)tokenFieldCell:(PDTokenFieldCell *)tokenFieldCell didReadTokens:(NSArray*)theTokens fromPasteboard:(NSPasteboard *)pboard;

@end