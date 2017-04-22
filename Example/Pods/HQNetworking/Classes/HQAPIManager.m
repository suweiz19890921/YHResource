//
//  HQAPIManager.m
//  APIDemo
//
//  Created by 刘欢庆 on 2017/3/26.
//  Copyright © 2017年 刘欢庆. All rights reserved.
//

#import "HQAPIManager.h"
#import "AFHTTPSessionManager.h"
#import "HQAPIUtils.h"
#import "YYModel.h"

static NSString *specialCharacters = @"/?&.";

@interface HQAPIManager()
@property (nonatomic, strong) NSCache *sessionManagers;
@property (nonatomic, strong) NSMutableDictionary *sessionTasks;
@property (nonatomic, strong) dispatch_queue_t completionQueue;
@end
@implementation HQAPIManager
+ (instancetype)sharedInstance
{
    static HQAPIManager *_sharedInstance;
    static dispatch_once_t _onceToken;
    dispatch_once(&_onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

#pragma mark - 系统
- (instancetype)init
{
    self = [super init];
    if(self)
    {
        //初始化
        _sessionManagers = [[NSCache alloc] init];
        _sessionTasks = [NSMutableDictionary dictionary];
        _completionQueue = dispatch_queue_create("com.liuhuanqing.api",NULL);
    }
    return self;
}

#pragma mark - 初始化
- (AFHTTPRequestSerializer *)requestSerializerWithAPI:(HQBaseAPI *)api
{
    AFHTTPRequestSerializer *requestSerializer;
    if ([api requestSerializerType] == HQRequestSerializerTypeJSON)
    {
        requestSerializer = [AFJSONRequestSerializer serializer];
    }
    else
    {
        requestSerializer = [AFHTTPRequestSerializer serializer];
    }
    requestSerializer.timeoutInterval = api.requestTimeoutInterval;
    NSDictionary *HTTPHeaderFields = [api HTTPHeaderFields];
    if (HTTPHeaderFields)
    {
        [HTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
         {
             [requestSerializer setValue:obj forHTTPHeaderField:key];
         }];
    }
    return requestSerializer;
}

- (AFHTTPResponseSerializer *)responseSerializerWithAPI:(HQBaseAPI *)api
{
    AFHTTPResponseSerializer *responseSerializer;
    if ([api responseSerializerType] == HQResponseSerializerTypeHTTP)
    {
        responseSerializer = [AFHTTPResponseSerializer serializer];
    }
    else
    {
        responseSerializer = [AFJSONResponseSerializer serializer];
    }
    responseSerializer.acceptableContentTypes = [api responseAcceptableContentTypes];
    return responseSerializer;
}

- (NSURL *)baseURLWithAPI:(HQBaseAPI *)api
{
    return [NSURL URLWithString:@"/" relativeToURL:[NSURL URLWithString:api.baseURL]];
}

- (AFHTTPSessionManager *)sessionManagerWithBaseURL:(NSURL *)baseURL
{
    
    AFHTTPSessionManager *sessionManager = [self.sessionManagers objectForKey:baseURL.absoluteString];
    if(!sessionManager)
    {
        sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
        [self.sessionManagers setObject:sessionManager forKey:baseURL.absoluteString];
        sessionManager.completionQueue = self.completionQueue;
    }
    return sessionManager;
}

#pragma mark - 公共
- (void)sendAPIRequest:(HQBaseAPI *)api
{
    NSParameterAssert(api);
    //生成请求序列化方法
    AFHTTPRequestSerializer *requestSerializer = [self requestSerializerWithAPI:api];
    
    //生成响应响应序列化方法
    AFHTTPResponseSerializer *responseSerializer = [self responseSerializerWithAPI:api];
    
    //生成请求域
    NSURL *baseURL = [self baseURLWithAPI:api];
    
    //生成SessionManager
    AFHTTPSessionManager *sessionManager = [self sessionManagerWithBaseURL:baseURL];
    sessionManager.requestSerializer     = requestSerializer;
    sessionManager.responseSerializer    = responseSerializer;
    
    //成功回调
    void (^successBlock)(NSURLSessionDataTask *task, id responseObject) = ^(NSURLSessionDataTask * task, id responseObject){
        [self.sessionTasks removeObjectForKey:@(task.taskIdentifier)];
        if([api.responseResultMapping count])
        {
            NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[api.responseResultMapping count]];
            [api.responseResultMapping enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                id nodeResult = [HQAPIUtils responseResult:responseObject keyPath:key ClassName:obj];
                if(nodeResult)
                {
                    [result setObject:nodeResult forKey:key];
                }
            }];

            if(api.mainThreadCompleteHandler && ![NSThread isMainThread])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(api.completeHandler)api.completeHandler(result,nil);
                });
            }
            else
            {
                if(api.completeHandler)api.completeHandler(result,nil);
            }

        }
        else
        {
            if(api.mainThreadCompleteHandler && ![NSThread isMainThread])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(api.completeHandler)api.completeHandler(responseObject,nil);
                });
            }
            else
            {
                if(api.completeHandler)api.completeHandler(responseObject,nil);
            }
        }
    };

    void (^failureBlock)(NSURLSessionDataTask * task, NSError * error) = ^(NSURLSessionDataTask * task, NSError * error) {
        [self.sessionTasks removeObjectForKey:@(api.identifier)];
        if(api.mainThreadCompleteHandler && ![NSThread isMainThread])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(api.completeHandler)api.completeHandler(nil,error);
            });
        }
        else
        {
            if(api.completeHandler)api.completeHandler(nil,error);
        }
    };

    NSDictionary *requestParams = [api requestParams];
    if(!requestParams)
    {
        requestParams = [api yy_modelToJSONObject];
    }
    
    NSString *requestURL = [api requestURL];

    //处理Resuful Url
    NSMutableDictionary *tmpRequestParams = [requestParams mutableCopy];
    NSString *newRequestURL = [requestURL copy];
    NSMutableArray *placeholders = [NSMutableArray array];
    NSInteger startIndexOfColon = 0;
    for (int i = 0; i < requestURL.length; i++)
    {
        NSString *character = [NSString stringWithFormat:@"%c", [requestURL characterAtIndex:i]];
        if ([character isEqualToString:@":"]) {
            startIndexOfColon = i;
        }
        if ([specialCharacters rangeOfString:character].location != NSNotFound && i > (startIndexOfColon + 1) && startIndexOfColon) {
            NSRange range = NSMakeRange(startIndexOfColon, i - startIndexOfColon);
            NSString *placeholder = [requestURL substringWithRange:range];
            if (![self checkIfContainsSpecialCharacter:placeholder]) {
                [placeholders addObject:placeholder];
                startIndexOfColon = 0;
            }
        }
        if (i == requestURL.length - 1 && startIndexOfColon) {
            NSRange range = NSMakeRange(startIndexOfColon, i - startIndexOfColon + 1);
            NSString *placeholder = [requestURL substringWithRange:range];
            if (![self checkIfContainsSpecialCharacter:placeholder]) {
                [placeholders addObject:placeholder];
            }
        }
    }
    for (NSString *ph in placeholders)
    {
        NSString *key = [ph substringFromIndex:1];
        NSString *val = [NSString stringWithFormat:@"%@",requestParams[key]];
        newRequestURL = [newRequestURL stringByReplacingOccurrencesOfString:ph withString:val];
        [tmpRequestParams removeObjectForKey:key];
    }
    requestURL = newRequestURL;
    requestParams = [tmpRequestParams copy];
    NSURLSessionDataTask *dataTask = nil;
    switch ([api requestMethod])
    {
        case HQRequestMethodGET:
        {
            dataTask = [sessionManager GET:requestURL parameters:requestParams progress:nil success:successBlock failure:failureBlock];
        }
            break;
        case HQRequestMethodPOST:
        {
            dataTask = [sessionManager POST:requestURL parameters:requestParams progress:nil success:successBlock failure:failureBlock];
        }
            break;
        case HQRequestMethodDELETE:
        {
            dataTask = [sessionManager DELETE:requestURL parameters:requestParams success:successBlock failure:failureBlock];
        }
            break;
    }
    [api setIdentifier:dataTask.taskIdentifier];
    [self.sessionTasks setObject:dataTask forKey:@(dataTask.taskIdentifier)];
}

- (void)cancelAPIRequest:(HQBaseAPI *)api
{
    NSURLSessionDataTask *dataTask = [self.sessionTasks objectForKey:@(api.identifier)];
    [dataTask cancel];
}

- (BOOL)checkIfContainsSpecialCharacter:(NSString *)checkedString {
    NSCharacterSet *specialCharactersSet = [NSCharacterSet characterSetWithCharactersInString:specialCharacters];
    return [checkedString rangeOfCharacterFromSet:specialCharactersSet].location != NSNotFound;
}
#pragma mark - getter
- (NSCache *)sessionManagers
{
    if (!_sessionManagers)
    {
        _sessionManagers = [[NSCache alloc] init];
    }
    return _sessionManagers;
}

- (NSMutableDictionary *)sessionTasks
{
    if(!_sessionTasks)
    {
        _sessionTasks = [NSMutableDictionary dictionary];
    }
    return _sessionTasks;
}

- (dispatch_queue_t)completionQueue
{
    if(!_completionQueue)
    {
        _completionQueue = dispatch_queue_create("com.liuhuanqing.api",NULL);
    }
    return _completionQueue;
}

@end
