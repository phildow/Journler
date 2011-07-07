//
//  JournlerCondition.h
//  Journler
//
//  Created by Philip Dow on 2/14/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	kKeyOperationSetString = 1,
	kKeyOperationAppendString = 2,
	kKeyOperationRemoveString = 3,
	kKeyOperationPrependString = 4,
	kKeyOperationSetAttributedString = 5,
	kKeyOperationAppendAttributedString = 6,
	kKeyOperationRemoveAttributedString = 7,
	kKeyOperationPrependAttributedString = 8,
	kKeyOperationSetNumber = 9,
	kKeyOperationAddObjects = 10,
	kKeyOperationRemoveObjects = 11,
	kKeyOperationNilOut = 12
} ConditionKeyOperation;

#define kOperationDictionaryKeyKey			@"kOperationDictionaryKeyKey"
#define kOperationDictionaryKeyValue		@"kOperationDictionaryKeyValue"
#define kOperationDictionaryKeyOperation	@"kOperationDictionaryKeyOperation"

@class JournlerEntry;

@interface JournlerCondition : NSObject {

}

// operationForCondition
// returns a dictionary with the object/values
//	1. theKey -> key which is changed
//	2. theValue -> value which is applied
//	3. theOperation -> operation

+ (NSDictionary*) operationForCondition:(NSString*)condition entry:(JournlerEntry*)anEntry;
+ (BOOL) condition:(NSString*)aCondition affectsKey:(NSString*)aKey;

+ (NSString*) normalizedTagCondition:(NSString*)tagCondition;

@end
