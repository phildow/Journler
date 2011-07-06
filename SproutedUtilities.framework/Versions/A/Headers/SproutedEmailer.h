//
//  SproutedEmailer.h
//  Journler
//
//  Created by Philip Dow on 4/17/08.
//  Copyright 2008 Lead Developer, Journler Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Message/NSMailDelivery.h>

@interface SproutedEmailer : NSObject {

}

- (BOOL)sendRichMail:(NSAttributedString *)richBody 
		to:(NSString *)to 
		subject:(NSString *)subject 
		isMIME:(BOOL)isMIME 
		withNSMail:(BOOL)wM;

@end
