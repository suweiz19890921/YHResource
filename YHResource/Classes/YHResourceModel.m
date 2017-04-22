//
//  YHResourceModel.m
//  YHResource
//
//  Created by 苏威 on 2017/4/20.
//  Copyright © 2017年 刘欢庆. All rights reserved.
//

#import "YHResourceModel.h"
#import "YHResourceCacheManager.h"
#import <YHLanguageSetting/YHLanguageSetting.h>
@implementation YHResourceModel

+ (nullable NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{@"ID":@"id",@"updateTime":@"updatetime"};
}

+ (NSString *)contentWithType:(NSString *)type key:(NSString *)key {
    if (![key isKindOfClass:[NSString class]] || !key || key.length <= 0 || ![type isKindOfClass:[NSString class]] || !type || type.length <= 0 ) {
        return key;
    }
    NSString *lan = [YHLanguageSetting currentLanguage];
    NSString *dictKey = ApplocalStringFormart(type, lan, key);
    if ([YHResourceCacheManager hasCachedWithKey:dictKey]) {
        //缓存过直接返回值
        return [YHResourceCacheManager getCacheValueWithKey:dictKey];
    } else {
        YHResourceModel *model = [[YHResourceModel hq_selectByWHERE:@"type = :type AND name = :name" withDictionary:@{@"type" : type,@"name" : key}] firstObject];
        NSString *value;
        if ([lan hasPrefix:@"zh_Hant"]) {
            value = model.resource.zh_Hant;
        } else if ([lan hasPrefix:@"zh_Hans"]) {
            value = model.resource.zh_Hans;
        } else if ([lan hasPrefix:@"ja"]) {
            value = model.resource.ja;
        } else if ([lan hasPrefix:@"en"]) {
            value = model.resource.en;
        }

        AppResourceRegisterKeyAndValue(dictKey, value ? value : key);
        return value;
    }
}

+ (NSString *)error:(NSString *)code
{
    if (![code isKindOfClass:[NSString class]] || !code) {
        return code;
    }
    NSString *lan = [YHLanguageSetting currentLanguage];
    NSString *type = @"error_code";
    NSString *dictKey = ApplocalStringFormart(type, lan, code);
    if ([YHResourceCacheManager hasCachedWithKey:dictKey]) {
        //缓存过直接返回值
        return [YHResourceCacheManager getCacheValueWithKey:dictKey];
    } else {
        YHResourceModel *model = [[YHResourceModel hq_selectByWHERE:@"type = :type AND name = :name" withDictionary:@{@"type" : type,@"name" : code}] firstObject];
        NSString *value;
        if ([lan hasPrefix:@"zh_Hant"]) {
            value = model.resource.zh_Hant;
        } else if ([lan hasPrefix:@"zh_Hans"]) {
            value = model.resource.zh_Hans;
        } else if ([lan hasPrefix:@"ja"]) {
            value = model.resource.ja;
        } else if ([lan hasPrefix:@"en"]) {
            value = model.resource.en;
        }
        
        AppResourceRegisterKeyAndValue(dictKey, value ? value : code);
        return value;
    }
}


//** 忽略字段列表*/
+ (nullable NSArray<NSString *> *)hq_propertyIgnoredList {
    return @[@"languageContent"];
}

//** 主键列表*/
+ (nullable NSArray<NSString *> *)hq_propertyPrimarykeyList {
    return @[@"ID"];
}

//** 所属库名称/
+ (nonnull NSString *)hq_dbName {
    return @"resource.db";
}

//返回容器类中的所需要存放的数据类型 (以 Class 或 Class Name 的形式)。modelContainerPropertyGenericClass
//modelContainerPropertyGenericClass
//此方法为YYModel中的的容器类对应表

@end

@implementation YHResourceSubModel

+ (nullable NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{@"zh_Hans":@"zhHans",@"zh_Hant":@"zhHant"};
}

@end

@implementation YHResourceBaitSubModel



@end

@implementation YHResourceBaitModel

+ (nullable NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{@"ID":@"id",@"lastTime":@"lasttime"};
}

+ (nullable NSArray<NSString *> *)hq_propertyIgnoredList {
    return @[@"languageName"];
}

//** 主键列表*/
+ (nullable NSArray<NSString *> *)hq_propertyPrimarykeyList {
    return @[@"ID"];
}

//** 所属库名称/
+ (nonnull NSString *)hq_dbName {
    return @"resource.db";
}

+ (instancetype)resourceBaitWithID:(NSString *)ID {
    return [[YHResourceBaitModel hq_selectByWHERE:@"ID = :ID" withDictionary:@{@"ID" : ID?:@""}] firstObject];
}

- (NSString *)languageName {
    if (_languageName) {
        return _languageName;
    }
   NSString *language = [YHLanguageSetting currentLanguage];
    NSString *languageName;
    if ([language hasPrefix:@"zh_Hans"]) {
        languageName = self.name.zh_Hans;
    } else if ([language hasPrefix:@"zh_Hant"]) {
        languageName = self.name.zh_Hant;
    } else {
        languageName = self.name.en;
    }
    self.languageName = languageName;
    return languageName;
    //先缓存
    
}

@end
