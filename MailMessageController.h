//
//  MailMessageController.h
//  Journler
//
//  Created by Philip Dow on 1/12/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <Pantomime/Pantomime.h>

#import "JournlerMediaContentController.h"

@interface MailMessageController : JournlerMediaContentController 
{
	IBOutlet WebView *webView;
	IBOutlet NSObjectController *objectController;
	
	IBOutlet NSTokenField *fromToken;
	IBOutlet NSTokenField *toToken;
	
	IBOutlet NSTextField *subjectField;
	IBOutlet NSTextField *dateField;
	
	IBOutlet NSMenu *emailTokenMenu;
	IBOutlet NSMenuItem *emailMenuItem;
	
	IBOutlet NSWindow *webviewFindPanel;
	IBOutlet NSTextField *webviewFindQueryField;
	
	NSString *defaultSender;
}

- (NSString*) defaultSender;
- (void) setDefaultSender:(id)sender;

- (IBAction)performWebViewFindPanelAction:(id)sender;

- (IBAction)sendEmailMessage:(id)sender;
- (IBAction) sendEmailToDefaultSender:(id)sender;

@end