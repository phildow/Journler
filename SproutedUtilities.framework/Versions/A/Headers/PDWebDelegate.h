//
//  PDWebDelegate.h
//  SproutedUtilities
//
//  Created by Philip Dow on 6/2/06.
//  Copyright 2006 Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface PDWebDelegate : NSObject {
	
	WebView *_master_view;
	BOOL _finished_loading;
}

- (id) initWithWebView:(WebView*)webView;

- (void) waitForView:(double)maxTime;

- (BOOL) finishedLoading;
- (void) setFinishedLoading:(BOOL)finished;

@end
