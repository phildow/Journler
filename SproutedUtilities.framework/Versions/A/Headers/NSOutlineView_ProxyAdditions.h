//
//  NSOutlineView_ProxyAdditions.h
//  SproutedUtilities
//
//  Created by Philip Dow on 9/11/06.
//  Copyright 2006 Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSOutlineView (ProxyAdditions)

- (id)originalItemAtRow:(int)row;
- (int)rowForOriginalItem:(id)originalItem;
- (NSArray*)originalItemsAtRows:(NSIndexSet*)indexSet;

@end


@interface NSObject (PrivateObservedObjectMethod)

- (id)observedObject;

@end