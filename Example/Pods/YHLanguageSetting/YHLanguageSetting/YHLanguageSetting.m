//
//  YHLanguageSetting.m
//  tt
//
//  Created by solot10 on 17/4/17.
//  Copyright © 2017年 solot10. All rights reserved.
//



#import "YHLanguageSetting.h"
#include <sys/sysctl.h>
#import <CommonCrypto/CommonCrypto.h>
//#import "NSData+GZIP.h"
#import <GZIP/GZIP.h>
#define DIRECTORY [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]
#define LOCALIZABLE_EXTENSION  @"strings"
#define FILE_NAME(x) [x stringByAppendingPathExtension:LOCALIZABLE_EXTENSION]
NSString * const CanUseLanguageKey = @"CanUseLanguageKey";
NSString * const LanguageSetUpKey = @"LanguageSetUpKey";
NSString * const FirstCopyLanguageKey = @"FirstCopyLanguageKey";
#define LANG_APP_VERSION [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleVersionKey]

@implementation LanguageModel
@end

@interface YHLanguageSetting()
@property (nonatomic, strong) NSString *currentLanguage;
@property (nonatomic, strong) NSDictionary *currentLocalizable;
@end

@implementation YHLanguageSetting

+ (void)setLanguage:(NSString *)language completion:(void(^)(BOOL success))completion
{
    [[YHLanguageSetting shareInstance] setLanguage:language completion:completion];
}

+ (NSString *)currentLanguage
{
    return [YHLanguageSetting shareInstance].currentLanguage;
}
+ (instancetype)shareInstance
{
    static YHLanguageSetting *setting = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        setting = [[YHLanguageSetting alloc] init];
    });
    return setting;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        //默认支持的语言
        if (![[NSUserDefaults standardUserDefaults] objectForKey:CanUseLanguageKey]) {
            [[NSUserDefaults standardUserDefaults] setObject:DEFALUT_SUPPORT_LANGUAGE forKey:CanUseLanguageKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        [self initLanguage];
        [self firstCopy];
        [self loadLocalizable];
    }
    return self;
}

- (void)setLanguage:(NSString *)language completion:(void(^)(BOOL success))completion;
{
    if([language isEqualToString:self.currentLanguage]) {
        !completion ?: completion(YES);
        return;
    };
    if ([self languageExists:language]) {
        [[NSUserDefaults standardUserDefaults] setObject:language forKey:LanguageSetUpKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        self.currentLanguage = language;
        [self loadLocalizable];
        !completion ?: completion(YES);
        [[NSNotificationCenter defaultCenter] postNotificationName:HQLocalizableDidChangeNotification object:nil];
    } else {
        //下载
        [self downloadLanguage:language completion:^(NSError *error) {
            if (!error) {
                self.currentLanguage = language;
                !completion ?: completion(YES);
                [[NSNotificationCenter defaultCenter] postNotificationName:HQLocalizableDidChangeNotification object:nil];
            } else {
                !completion ?: completion(NO);
            }
        }];
    }
}


- (BOOL)languageExists:(NSString *)language
{
    NSString *documentPath = DIRECTORY;
    NSString *fileName = [language stringByAppendingPathExtension:@"strings"];
    NSFileManager *manager = [NSFileManager defaultManager];
    return [manager fileExistsAtPath:[documentPath stringByAppendingPathComponent:fileName]];
}

- (void)firstCopy
{
    BOOL hasCopyied = [self hasCopiedLanguage];
    hasCopyied = NO;
    if (!hasCopyied) {
        NSFileManager *filemanager = [NSFileManager defaultManager];
        NSArray *languagePaths = [[NSBundle mainBundle] pathsForResourcesOfType:@"lproj" inDirectory:nil];
        NSString *documentPath = DIRECTORY;
        for (NSString *path in languagePaths) {
            NSString *lastComponent = path.lastPathComponent;
            NSString *filePath = [path stringByAppendingPathComponent:@"Localization.strings"];
            //拷贝
            if ([lastComponent hasPrefix:@"en"]) {
                NSString *toPath = [documentPath stringByAppendingPathComponent:@"en.strings"];
                if ([filemanager fileExistsAtPath:filePath]) {
                    NSError *error;
                    if ([filemanager fileExistsAtPath:toPath]) {
                        [filemanager removeItemAtPath:toPath error:nil];
                    }
                    [filemanager copyItemAtPath:filePath toPath:toPath error:&error];
                    NSLog(@"error : %@", error);
                }
            } else if ([lastComponent hasPrefix:@"zh-Hans"]) {
                NSString *toPath = [documentPath stringByAppendingPathComponent:@"zh_Hans.strings"];
                if ([filemanager fileExistsAtPath:filePath]) {
                    if ([filemanager fileExistsAtPath:toPath]) {
                        [filemanager removeItemAtPath:toPath error:nil];
                    }
                    NSError *error;
                    [filemanager copyItemAtPath:filePath toPath:toPath error:&error];
                }
            } else if ([lastComponent hasPrefix:@"zh-Hant"]) {
                NSString *toPath = nil;
                if ([lastComponent hasPrefix:@"zh-Hant-TW"]) {
                    toPath = [documentPath stringByAppendingPathComponent:@"zh_Hant_TW.strings"];
                } else {
                    toPath = [documentPath stringByAppendingPathComponent:@"zh_Hant_HK.strings"];
                }
                if ([filemanager fileExistsAtPath:filePath]) {
                    if ([filemanager fileExistsAtPath:toPath]) {
                        [filemanager removeItemAtPath:toPath error:nil];
                    }
                    NSError *error;
                    [filemanager copyItemAtPath:filePath toPath:toPath error:&error];
                }
            } else if ([lastComponent hasPrefix:@"ja"]) {
                NSString *toPath = [documentPath stringByAppendingPathComponent:@"ja.strings"];
                if ([filemanager fileExistsAtPath:filePath]) {
                    if ([filemanager fileExistsAtPath:toPath]) {
                        [filemanager removeItemAtPath:toPath error:nil];
                    }
                    NSError *error;
                    [filemanager copyItemAtPath:filePath toPath:toPath error:&error];
                }
            }
        }
    }
}

- (void)downloadLanguage:(NSString *)language completion:(void(^)(NSError *error))completion
{
    if (!self.downloadUrl || ![self.downloadUrl isKindOfClass:[NSString class]] || self.downloadUrl.length == 0) {
        NSError *error = [NSError errorWithDomain:@"url为空" code:-1 userInfo:nil];
        completion(error);
        return;
    }
    NSString *urlString = [NSString stringWithFormat:@"%@?lang=%@", self.downloadUrl, language];
    NSString *path = [DIRECTORY stringByAppendingPathComponent:FILE_NAME(language)];
    if([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        NSData *data = [[NSData alloc] initWithContentsOfFile:path];
        if (data) {
            NSString *md5String = [[self class] toHexStringData:[[self class] MD5ForData:data]];
            urlString = [NSString stringWithFormat:@"%@&md5=%@", urlString, md5String];
        }
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    [request setValue:[[self class] userAgent] forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSData *data = [NSData dataWithContentsOfURL:location];
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data.gunzippedData options:kNilOptions error:nil];
        if (dic.allKeys.count > 0) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                for (NSString *key in dic.allKeys)
                {
                    NSString *value = [dic objectForKey:key];
                    NSString *path = [DIRECTORY stringByAppendingPathComponent:[key stringByAppendingPathExtension:LOCALIZABLE_EXTENSION]];
                    [value writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:NULL];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    !completion ?: completion(error);
                });
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([NSError errorWithDomain:@"not resource" code:-1 userInfo:nil]);
            });
        }
        
    }];
    [task resume];
}

+ (NSString *)userAgent
{
    float scale = [[UIScreen mainScreen] scale];
    NSString *UserAgent = [NSString stringWithFormat:@"catches/%@ (iOS %@; %@; %@; %@; Scale/%0.2f;%@)"
                           , LANG_APP_VERSION
                           , [[UIDevice currentDevice] systemVersion]
                           , [self platform]
                           , [YHLanguageSetting currentLanguage]
                           , [NSString stringWithFormat:@"%d*%d", (int)([UIScreen mainScreen].bounds.size.width * scale), (int)([UIScreen mainScreen].bounds.size.height * scale)]
                           , scale
                           , @""];
    return UserAgent;
}

- (void)loadLocalizable
{
    NSString *fileName = [self.currentLanguage stringByAppendingPathExtension:@"strings"];
    NSString *documentPath = DIRECTORY;
    NSString *path = [documentPath stringByAppendingPathComponent:fileName];
    _currentLocalizable = [[NSDictionary alloc] initWithContentsOfFile:path];
    if (!_currentLanguage) {
        //没有默认用英语
        fileName = [@"en" stringByAppendingPathExtension:@"strings"];
        path = [documentPath stringByAppendingPathComponent:fileName];
        _currentLocalizable = [[NSDictionary alloc] initWithContentsOfFile:path];
        _currentLanguage = @"en";
    }
}

- (BOOL)hasCopiedLanguage
{
    NSString *key = [NSString stringWithFormat:@"LanguageHasCopied_%@", LANG_APP_VERSION];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:key]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:key];
        return NO;
    }
    return YES;
}

- (void)initLanguage
{
    NSString *language = [[NSUserDefaults standardUserDefaults] objectForKey:LanguageSetUpKey];
    NSString *currentLanguage = nil;
    if(language)
    {
        currentLanguage = language;
    }
    else
    {
        NSDictionary *components = [NSLocale componentsFromLocaleIdentifier:[[NSLocale currentLocale] localeIdentifier]];
        NSString *languageCode = components[NSLocaleLanguageCode];
        NSString *countryCode = components[NSLocaleCountryCode];
        NSString *scriptCode = components[NSLocaleScriptCode];
        
        if([languageCode isEqualToString:@"zh"])
        {
            if([scriptCode isEqualToString:@"Hans"])
            {
                //zh_Hans
                currentLanguage = @"zh_Hans";
            }
            else if([scriptCode isEqualToString:@"Hant"])
            {
                if([countryCode isEqualToString:@"TW"])
                {
                    //zh_Hant_TW
                    currentLanguage = @"zh_Hant_TW";
                    
                }
                else
                {
                    //zh_Hant_HK
                    currentLanguage = @"zh_Hant_HK";
                }
            }
            else
            {
                if([countryCode isEqualToString:@"TW"])
                {
                    //zh_Hant_TW
                    currentLanguage = @"zh_Hant_TW";
                    
                }
                else if([countryCode isEqualToString:@"HK"] || [countryCode isEqualToString:@"MO"])
                {
                    //zh_Hant_HK
                    currentLanguage = @"zh_Hant_HK";
                    
                }
                else
                {
                    //zh_Hans
                    currentLanguage = @"zh_Hans";
                    
                }
            }
        }
        else
        {
            if([[[self class] _allLangeuageKeys] containsObject:languageCode])
            {
                //languageDesignator
                currentLanguage = languageCode;
                
            }
            else
            {
                //en
                currentLanguage = @"en";
            }
        }
    }
    _currentLanguage = currentLanguage;
}

+ (NSString *)localizable:(NSString *)key
{
    if([YHLanguageSetting shareInstance].currentLocalizable)
    {
        
        NSString *lang = [[YHLanguageSetting shareInstance].currentLocalizable objectForKey:key];
        if(lang)
        {
            return lang;
        }
        return key;
    }
    else
    {
        return NSLocalizedString(key, nil);
    }
}


+ (NSArray<LanguageModel *> *)allLangualges
{
    NSMutableArray *tmpArr = [NSMutableArray array];
    NSArray *keys = [self _allLangeuageKeys];
    NSDictionary *maps = [self _allLangugaeMaps];
    NSArray *supportKeys = [self languagesCodeCanUse];
    
    for (NSString *languageCode in keys) {
        LanguageModel *model = [[LanguageModel alloc] init];
        model.languageCode = languageCode;
        model.name = maps[languageCode];
        
        BOOL isSupport = [supportKeys containsObject:languageCode];
        if (!isSupport) {
            isSupport = [languageCode hasPrefix:@"zh_Hant"];
        }
        
        model.isSupport = isSupport;
        [tmpArr addObject:model];
    }
    return [tmpArr copy];
}

+ (NSArray *)languagesCodeCanUse
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:CanUseLanguageKey];
}

+ (void)setLanguageCanUse:(NSArray *)arr
{
    [[NSUserDefaults standardUserDefaults] setObject:arr forKey:CanUseLanguageKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSArray *)_allLangeuageKeys
{
    return @[@"zh_Hans" ,
             @"zh_Hant_TW",
             @"zh_Hant_HK",
             @"en",
             @"ja",
             @"ko",
             @"th",
             @"vi",
             @"id",
             @"ms",
             @"fil",
             @"hi",
             @"ar" ,
             @"fr",
             @"de" ,
             @"it",
             @"es" ,
             @"pt",
             @"pl",
             @"tr",
             @"da",
             @"fi",
             @"sk",
             @"sv",
             @"hu",
             @"hr",
             @"uk",
             @"ru"
             ];
}

+ (NSDictionary *)_allLangugaeMaps
{
    return @{@"zh_Hans"            : @"简体中文",
             @"zh_Hant_TW"         : @"繁體中文(台灣)",
             @"zh_Hant_HK"         : @"繁體中文(香港)",
             @"en"                 : @"English",
             @"ja"                 : @"日本語",
             @"ko"                 : @"한국의",
             @"th"                 : @"ภาษาไทย",
             @"vi"                 : @"Tiếng việt",
             @"id"                 : @"Bahasa Indonesia",
             @"ms"                 : @"Bahasa Melayu",
             @"fil"                : @"Pilipino",
             @"hi"                 : @"हिन्दी",
             @"ar"                 : @"العربية",
             @"fr"                 : @"Français",
             @"de"                 : @"Deutsch",
             @"it"                 : @"Italiano",
             @"es"                 : @"Español",
             @"pt"                 : @"Português",
             @"pl"                 : @"Polski",
             @"tr"                 : @"Türkçe",
             @"da"                 : @"Dansk",
             @"fi"                 : @"Suomi",
             @"sk"                 : @"Slovenčina",
             @"sv"                 : @"Svenska",
             @"hu"                 : @"Magyar",
             @"hr"                 : @"Hrvatski",
             @"uk"                 : @"Yкраїнська",
             @"ru"                 : @"Pусский"
             };
}




//获取平台信息
+ (NSString *) getSysInfoByName:(char *)typeSpecifier
{
    size_t size;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
    
    char *answer = malloc(size);
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
    
    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
    
    free(answer);
    return results;
}

+ (NSString *) platform
{
    return [self getSysInfoByName:"hw.machine"];
}

// data 的 MD5 值
+ (NSData *)MD5ForData:(NSData *)data
{
    uint8_t result[16];
    CC_MD5(data.bytes, (CC_LONG)data.length, result);
    return [NSData dataWithBytes:result length:16];
}

+ (NSString *)toHexStringData:(NSData *)data
{
    unsigned char *bytes = (unsigned char *)data.bytes;
    NSMutableString *outPut = [[NSMutableString alloc] init];
    for (int i = 0; i < data.length; ++i) {
        [outPut appendFormat:@"%02x", bytes[i]];
    }
    return outPut;
}




@end
