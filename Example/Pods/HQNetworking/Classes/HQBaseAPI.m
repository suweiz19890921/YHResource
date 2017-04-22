//
//  HQBaseAPI.m
//  APIDemo
//
//  Created by 刘欢庆 on 2017/3/25.
//  Copyright © 2017年 刘欢庆. All rights reserved.
//

#import "HQBaseAPI.h"
#import "HQAPIManager.h"
@interface HQBaseAPI()
{
    HQAPICompleteHandler _completeHandler;
    NSUInteger _identifier;
}
@end
@implementation HQBaseAPI
- (NSString *)baseURL
{
    return @"";
}

- (NSString *)requestURL
{
    return @"";
}

- (HQRequestMethod)requestMethod
{
    return HQRequestMethodGET;
}

- (HQRequestSerializerType)requestSerializerType
{
    return HQRequestSerializerTypeJSON;
}

- (HQResponseSerializerType)responseSerializerType
{
    return HQResponseSerializerTypeJSON;
}

- (NSDictionary *)requestParams
{
    return nil;
}

- (NSDictionary *)HTTPHeaderFields
{
    return @{};
}

- (NSDictionary *)responseResultMapping
{
    return @{};
}

- (NSTimeInterval)requestTimeoutInterval
{
    return HQ_API_REQUEST_TIME_OUT;
}


- (nullable NSSet *)responseAcceptableContentTypes
{
    return [NSSet setWithObjects:
            @"text/json",
            @"text/html",
            @"application/json",
            @"text/javascript", nil];
}

- (void)setCompleteHandler:(HQAPICompleteHandler)completeHandler
{
    if(!_completeHandler)
    {
        _completeHandler = completeHandler;
    }
}

- (__nullable HQAPICompleteHandler)completeHandler
{
    return _completeHandler;
}

- (NSUInteger)identifier
{
    return _identifier;
}

- (void)setIdentifier:(NSUInteger)identifier
{
    _identifier = identifier;
}

- (BOOL)mainThreadCompleteHandler
{
    return YES;
}

- (void)start
{
    [[HQAPIManager sharedInstance] sendAPIRequest:self];
}

- (void)stop
{
    [[HQAPIManager sharedInstance] cancelAPIRequest:self];
}
@end

