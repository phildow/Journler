//
//  TermIndexWindowController.h
//  Journler
//
//  Created by Phil Dow on 1/31/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "JournlerWindowController.h"

@class IndexLetterView;
@class JournlerIndexServer;

@interface TermIndexWindowController : JournlerWindowController {
	
	IBOutlet NSView *navOutlet;
	IBOutlet NSButton *navBack;
	IBOutlet NSButton *navForward;
	
	IBOutlet IndexLetterView *letterView;
	IBOutlet NSView *initalTabPlaceholder;
	
	IBOutlet NSWindow *stopwordsWindow;
	IBOutlet NSTextView *stopwordsTextView;
	
	JournlerIndexServer *indexServer;
}

- (JournlerIndexServer*) indexServer;
- (void) setIndexServer:(JournlerIndexServer*)aServer;

- (IBAction) gotoLetter:(id)sender;
- (IBAction) editSynonyms:(id)sender;
- (IBAction) showLexiconHelp:(id)sender;

- (IBAction) editStopWords:(id)sender;
- (IBAction) saveStopwordsChanges:(id)sender;
- (IBAction) cancelStopwordsChanges:(id)sender;

@end

@interface TermIndexWindowController (Toolbars)

- (void) setupToolbar;

@end