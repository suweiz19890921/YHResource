//
//  YHResourceCacheManager.m
//  YHResource
//
//  Created by 苏威 on 2017/4/21.
//  Copyright © 2017年 刘欢庆. All rights reserved.
//

#import "YHResourceCacheManager.h"

@interface YHResourceCacheManager ()

@property (nonatomic, strong) NSMutableDictionary *mainDict;  //没有加缓存及时清除功能 加了更影响性能

@end

@implementation YHResourceCacheManager

+ (instancetype)defaultCacheManager
{
    static YHResourceCacheManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] init];
        sharedInstance.mainDict = [NSMutableDictionary dictionary];
    });
    return sharedInstance;
}

+ (void)registerKey:(NSString *)key value:(NSString *)value target:(NSObject *)target {
    NSAssert(key, @"key 不能为空");
    [[YHResourceCacheManager defaultCacheManager].mainDict setValue:value forKey:key];
}

+ (void)registerKey:(NSString *)key value:(id)value {
    if (![key isKindOfClass:[NSString class]] || !value) {
        return;
    }
    [[YHResourceCacheManager defaultCacheManager].mainDict setValue:value forKey:key];
}

+ (BOOL)hasCachedWithKey:(NSString *)key {
    if ([[YHResourceCacheManager  defaultCacheManager].mainDict valueForKey:key]) {
        //已经缓存过
        return YES;
    } else {
        return NO;
    }
}

+ (id)getCacheValueWithKey:(NSString *)key {
    id value = [[YHResourceCacheManager defaultCacheManager].mainDict objectForKey:key];
    return value;
}
@end
