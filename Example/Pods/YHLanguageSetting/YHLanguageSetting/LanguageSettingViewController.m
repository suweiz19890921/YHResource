//
//  LanguageSettingViewController.m
//  tt
//
//  Created by solot10 on 17/4/18.
//  Copyright © 2017年 solot10. All rights reserved.
//

#import "LanguageSettingViewController.h"
#import "YHLanguageSetting.h"
#import <MBProgressHUD/MBProgressHUD.h>

static NSString * const LanguageCellIdentifier = @"LanguageCellIdentifier";

@interface LanguageSettingViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSArray *dataSource;
//@property (nonatomic, strong)
@property (nonatomic, strong) NSString *currentLanguage;
@end

@implementation LanguageSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = Locale(@"语言切换");
    self.dataSource = [YHLanguageSetting allLangualges];
    self.currentLanguage = [YHLanguageSetting currentLanguage];
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    tableView.delegate = self;
    tableView.dataSource = self;

    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:LanguageCellIdentifier];
    [self.view addSubview:tableView];
    [self loadNavItem];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *Cell = [tableView dequeueReusableCellWithIdentifier:LanguageCellIdentifier];
    LanguageModel *model = self.dataSource[indexPath.row];
    Cell.textLabel.text = model.name;
    Cell.textLabel.textColor = model.isSupport ? [UIColor blackColor] : [UIColor lightGrayColor];
    Cell.accessoryType = [self.currentLanguage isEqualToString:model.languageCode] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return Cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return CGFLOAT_MIN;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    LanguageModel *model = self.dataSource[indexPath.row];
    if (model.isSupport) {
        self.currentLanguage = model.languageCode;
        [tableView reloadData];
    }
}


- (void)loadNavItem
{
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:Locale(@"取消") style:0 target:self action:@selector(cancelAction:)];
    self.navigationItem.leftBarButtonItem = leftItem;
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:Locale(@"保存") style:0 target:self action:@selector(saveAction:)];
    self.navigationItem.rightBarButtonItem = rightItem;
}

- (void)cancelAction:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveAction:(id)saveAction
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    hud.labelText = Locale(@"切换中...");
    [YHLanguageSetting setLanguage:self.currentLanguage completion:^(BOOL success) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        if (success) {
            hud.labelText = Locale(@"切换成功");
            [hud hide:YES afterDelay:.5];
            [self performSelector:@selector(_dismiss) withObject:nil afterDelay:.5];
        } else {
            hud.labelText = Locale(@"切换失败");
            [hud hide:YES];
        }
    }];
}


- (void)_dismiss
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
