//
//  YHResourceCacheManager.h
//  YHResource
//
//  Created by 苏威 on 2017/4/21.
//  Copyright © 2017年 刘欢庆. All rights reserved.
//

#import <Foundation/Foundation.h>

#define AppResourceRegisterKeyAndValue(KEY, VALUE) \
({ \
[YHResourceCacheManager registerKey:KEY value:VALUE]; \
})

#define AppResourceRegisterKeyAndValueAndTarget(KEY, VALUE, TARGET) \
({ \
[YHResourceCacheManager registerKey:KEY value:VALUE target:TARGET]; \
})

@interface YHResourceCacheManager : NSObject

+ (instancetype)defaultCacheManager;

+ (void)registerKey:(NSString *)key value:(NSString *)value target:(NSObject *)target;

+ (void)registerKey:(NSString *)key value:(id)value;

+ (BOOL)hasCachedWithKey:(NSString *)key;

+ (id)getCacheValueWithKey:(NSString *)key;


@end
