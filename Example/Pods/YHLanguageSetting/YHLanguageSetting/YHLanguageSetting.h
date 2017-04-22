//
//  YHLanguageSetting.h
//  tt
//
//  Created by solot10 on 17/4/17.
//  Copyright © 2017年 solot10. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
static NSString * const HQLocalizableDidChangeNotification = @"HQLocalizableDidChangeNotification";
#define DEFALUT_SUPPORT_LANGUAGE @[@"zh_Hans", @"zh_Hant", @"en", @"ja"]
#define Locale(str) [YHLanguageSetting localizable:str]
@interface LanguageModel : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *languageCode;
@property (nonatomic, assign) BOOL isSupport;

@end

@interface YHLanguageSetting : NSObject
@property (nonatomic, strong) NSString *downloadUrl; //@"https://testapi.solot.co/catches/syncResource"

+ (instancetype)shareInstance;

- (void)downloadLanguage:(NSString *)language completion:(void(^)(NSError *error))completion;

+ (NSArray<LanguageModel *> *)allLangualges;

+ (NSString *)currentLanguage;

+ (void)setLanguage:(NSString *)language completion:(void(^)(BOOL success))completion;

+ (NSString *)localizable:(NSString *)key;

@end
