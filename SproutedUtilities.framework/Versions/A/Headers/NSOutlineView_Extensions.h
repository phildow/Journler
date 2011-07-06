//
//  NSOutlineView_Extensions.h
//
//  Copyright (c) 2001-2005, Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSOutlineView (PDExtensions)

- (id)selectedItem;
- (void) selectItem:(id)anObject;

- (NSArray*)allSelectedItems;
- (void)selectItems:(NSArray*)items byExtendingSelection:(BOOL)extend;

@end