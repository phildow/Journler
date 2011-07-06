//
//  PDMediaBar.h
//  Journler
//
//  Created by Phil Dow on 2/21/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SproutedInterface/JournlerGradientView.h>

typedef enum {
	kMediaBarDefaultItem = 100,
	kMediaBarShowInFinder = 101,
	kMediaBarOpenWithFinder = 102,
	kMediaBarGetInfo = 103
} MediaBarDefaultActions;


@class PDMediabarItem;

@interface PDMediaBar : JournlerGradientView {
	
	id delegate;
	
	NSString *prefsIdentifier;
	NSDictionary *barDictionary;
	NSArray *itemIdentifiers;
	NSArray *customItemDictionaries;
	
	NSArray *itemArray;
}

- (id) delegate;
- (void) setDelegate:(id)anObject;

// the following accessors should not be called - think of them as private

- (NSString*)prefsIdentifier;
- (void) setPrefsIdentifier:(NSString*)aString;

- (NSDictionary*)barDictionary;
- (void) setBarDictionary:(NSDictionary*)aDictionary;

- (NSArray*)itemIdentifiers;
- (void) setItemIdentifiers:(NSArray*)anArray;

- (NSArray*)customItemDictionaries;
- (void) setCustomItemDictionaries:(NSArray*)anArray;

- (NSArray*) itemArray;
- (void) setItemArray:(NSArray*)anArray;

- (void) loadItems;
- (void) displayItems;

- (IBAction) addCustomMediabarItem:(id)sender;
- (IBAction) editCustomMediabarItem:(id)sender;
- (IBAction) removeCustomMediabarItem:(id)sender;

- (void) _removeCustomMediabarItem:(PDMediabarItem*)anItem;
- (void) _editCustomMediabarItem:(PDMediabarItem*)anItem;

- (void) _didChangeFrame:(NSNotification*)aNotification;

@end

@interface NSObject (PDMediaBarDelegate)

//
// for now the media bar only allows buttons
// it begins from the right with the first item returned by preferences

- (void) setupMediabar:(PDMediaBar*)aMediabar url:(NSURL*)aURL;

- (NSImage*) defaultOpenWithFinderImage:(PDMediaBar*)aMediabar;
- (float) mediabarMinimumWidthForUnmanagedControls:(PDMediaBar*)aMediabar;

- (BOOL) canCustomizeMediabar:(PDMediaBar*)aMediabar;
- (NSString*) mediabarIdentifier:(PDMediaBar*)aMediabar;

// the action method for user-defined mediabar items.
// to find out which mediabar the item is associated with, call -mediabar on it
- (IBAction) perfomCustomMediabarItemAction:(PDMediabarItem*)anItem;

// subclasses may override when offering their own default items,
// call super to get support for any standard items you also include
- (PDMediabarItem*) mediabar:(PDMediaBar *)mediabar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoMediabar:(BOOL)flag;

// subclasses should override to provide the default item identifiers
// listing is displayed from the right to the left in the media bar
- (NSArray*) mediabarDefaultItemIdentifiers:(PDMediaBar *)mediabar;

@end
