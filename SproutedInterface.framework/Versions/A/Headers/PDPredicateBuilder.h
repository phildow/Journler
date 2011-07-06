/*
 *  ConditionCollectionProtocol.h
 *  Lex
 *
 *  Created by Phil Dow on 4/10/07.
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 *
 */

@protocol PDPredicateBuilder

- (NSCompoundPredicateType) compoundPredicateType;
- (void) setCompoundPredicateType:(NSCompoundPredicateType)predicateType;

- (NSPredicate*) predicate;
- (void) setPredicate:(NSPredicate*)aPredicate;

- (id) delegate;
- (void) setDelegate:(id)anObject;

- (NSView*) contentView;

- (NSSize) requiredSize;
- (void) setMinWidth:(float)width;

- (BOOL) validatePredicate;

@end

@interface NSObject (PDPredicateBuilderDelegate)

- (void) predicateBuilder:(id)aPredicateBuilder predicateDidChange:(NSPredicate*)newPredicate;
- (void) predicateBuilder:(id)aPredicateBuilder sizeDidChange:(NSSize)newSize;

@end