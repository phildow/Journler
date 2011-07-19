//
//  IndexNode.h
//  Journler
//
//  Created by Philip Dow on 2/6/07.
//  Copyright 2007 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JournlerObject;

@interface IndexNode : NSObject <NSCopying> {
	
	NSInteger count;
	NSInteger frequency;
	NSString *title;
	
	IndexNode *parent;
	NSArray *children;
	
	id representedObject;
}

- (NSInteger) count;
- (void) setCount:(NSInteger)aCount;

- (NSInteger) frequency;
- (void) setFrequency:(NSInteger)aFrequency;

- (NSString*) title;
- (void) setTitle:(NSString*)aString;

- (id) representedObject;
- (void) setRepresentedObject:(id)anObject;

- (IndexNode*) parent;
- (void) setParent:(IndexNode*)aNode;

- (NSArray*) children;
- (void) setChildren:(NSArray*)anArray;

- (NSUInteger) childCount;
- (BOOL) isLeaf;

@end
