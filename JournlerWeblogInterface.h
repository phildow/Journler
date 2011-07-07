//
//  JournlerWeblogInterface.h
//  Journler
//
//  Created by Philip Dow on 11/12/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SproutedUtilities/SproutedUtilities.h>

typedef enum {
	kJournlerWeblogInterfaceSendHTML = 1
} JournlerWeblogInterfaceOptions;

extern NSString *kPDAppleScriptErrorDictionaryScriptSource;

@interface JournlerWeblogInterface : NSObject {	
	id delegate;
	SEL didChooseEditorCallback;
	NSDictionary *weblogEditorIdentifiers;
}

- (NSDictionary*) weblogEditorIdentifiers;
- (void) setWeblogEditorIdentifiers:(NSDictionary*)aDictionary;

- (void) choosePreferredEditor:(id)aDelegate 
		didEndSelector:(SEL)didChooseSelector 
		modalForWindow:(NSWindow*)aWindow;

- (BOOL) sendEntries:(NSArray*)theEntries 
		toPreferredEditor:(NSString*)editorFilename 
		options:(int)options 
		error:(id*)anError;
		
- (BOOL) sendEntries:(NSArray*)theEntries 
		toWeblogProtocolPreferredEditor:(NSString*)editorBundleIdentifier 
		options:(int)options 
		error:(id*)anError;
		
- (BOOL) sendEntries:(NSArray*)theEntries 
		toApplicationPreferredEditor:(NSString*)editorFilename 
		options:(int)options 
		error:(id*)anError;
		
- (BOOL) sendEntries:(NSArray*)theEntries 
		toAppleScriptPreferredEditor:(NSString*)editorFilename 
		options:(int)options 
		error:(id*)anError;

@end
