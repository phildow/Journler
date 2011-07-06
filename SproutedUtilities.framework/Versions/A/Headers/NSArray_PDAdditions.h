//
//  NSArray_PDAdditions.h
//  SproutedUtilities
//
//  Created by Philip Dow on 11/9/06.
//  Copyright 2006 Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSArray (PDAdditions)

- (BOOL) allObjectsAreEqual;
- (BOOL) containsObjects:(NSArray*)anArray;
- (BOOL) containsAnObjectInArray:(NSArray*)anArray;

- (int) stateForInteger:(int)aValue;
- (NSArray*) objectsWithValue:(id)aValue forKey:(NSString*)aKey;

@end
