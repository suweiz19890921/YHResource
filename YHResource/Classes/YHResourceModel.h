//
//  YHResourceModel.h
//  YHResource
//
//  Created by 苏威 on 2017/4/20.
//  Copyright © 2017年 刘欢庆. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HQDBDecode/NSObject+HQDBDecode.h>
#define Applocal(TYPE, KEY) \
({ \
[YHResourceModel contentWithType:TYPE key:KEY]; \
})

#define Apperror(code) \
({ \
[YHResourceModel error:code]; \
})

#define ApplocalStringFormart(TYPE, LANGUAGE, KEY) \
({\
[NSString stringWithFormat:@"%@%@%@", TYPE, LANGUAGE, KEY]; \
})

#define AppBait(ID) \
({ \
[YHResourceBaitModel resourceBaitWithID:ID]; \
})

@interface YHResourceSubModel :NSObject

@property (nonatomic, copy) NSString *en;

@property (nonatomic, copy) NSString *ja;

@property (nonatomic, copy) NSString *zh_Hans;

@property (nonatomic, copy) NSString *zh_Hant;

@end

@interface YHResourceModel : NSObject<HQDBDecode>

/**
 *  通过 type+name确定内容
 *  例子:type:"ship_detail" name:"length" -> 长度
 */
//"id": "12829",
//"type": "error_code",
//"name": "403161",
//"status": 1,
//"updatetime": 1490199900444,
//"resource": {
//    "en": " Not Promotional Period",
//    "ja": " Not Promotional Period",
//    "zhHans": "活动未开始",
//    "zhHant": " Not Promotional Period"
//}

@property (nonatomic, copy) NSString *ID;

@property (nonatomic, copy) NSString *type;

@property (nonatomic, copy) NSString *name;

@property (nonatomic, assign) NSInteger status;

@property (nonatomic, copy) NSString *updateTime;

@property (nonatomic, strong) YHResourceSubModel *resource;

@property (nonatomic, copy) NSString *languageContent;

+ (NSString *)contentWithType:(NSString *)type key:(NSString *)key;

+ (NSString *)error:(NSString *)code;

@end

@interface YHResourceBaitSubModel : NSObject

@property (nonatomic, copy) NSString *zh_Hans;
@property (nonatomic, copy) NSString *en;
@property (nonatomic, copy) NSString *zh_Hant;

@end

@interface YHResourceBaitModel : NSObject<HQDBDecode>

//
//"id": 67,
//"name": {
//    "zh_Hans": "蟋蟀",
//    "en": "cricket",
//    "zh_Hant": "蟋蟀"
//},
//"img": "http://bj.p.solot.com/baits/cricket.jpg",
//"lasttime": 1489170111915,
//"enable": true,
//"type": {
//    "zh_Hans": "荤饵",
//    "en": "Meat Bait",
//    "zh_Hant": "葷餌"
//}
@property (nonatomic, copy) NSString *ID;

@property (nonatomic, strong) YHResourceBaitSubModel *name;

@property (nonatomic, copy) NSString *img;

@property (nonatomic, assign) BOOL enable;

@property (nonatomic, copy) NSString *lastTime;

@property (nonatomic, strong) YHResourceBaitSubModel *type;

@property (nonatomic, copy) NSString *languageName;

+ (instancetype)resourceBaitWithID:(NSString *)ID;

@end
