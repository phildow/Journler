//
//  ResourceNode.h
//  Journler
//
//  Created by Philip Dow on 11/12/06.
//  Copyright 2006 Sprouted, Philip Dow. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JournlerResource;

@interface ResourceNode : NSObject {
	
	NSNumber *label;
	NSString *labelTitle;
	
	JournlerResource *resource;
	ResourceNode *parent;
	NSArray *children;
}

- (NSNumber*) label;
- (void) setLabel:(NSNumber*)aNumber;

- (NSString*) labelTitle;
- (void) setLabelTitle:(NSString*)aString;

- (JournlerResource*) resource;
- (void) setResource:(JournlerResource*)aResource;

- (ResourceNode*) parent;
- (void) setParent:(ResourceNode*)aResourceNode;

- (NSArray*) children;
- (void) setChildren:(NSArray*)anArray;

- (BOOL) isLeafNode;
- (BOOL) isExpandable;

- (NSUInteger) countOfChildren;
- (ResourceNode*) childAtIndex:(NSUInteger)index;

@end
