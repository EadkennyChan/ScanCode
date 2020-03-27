//
//  FunctionListVC.m
//  0327AAA
//
//  Created by  eadkenny on 2020/3/27.
//  Copyright © 2020  eadkenny. All rights reserved.
//

#import "FunctionListVC.h"
#import "Masonry.h"

@interface FunctionListVC ()

@property (nonatomic, retain)NSArray *datas;
@property (nonatomic, retain)UITableView *tableView;
@end

@implementation FunctionListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
  self.view.backgroundColor = [UIColor whiteColor];
  self.title = @"功能列表";
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStyleDone target:self action:@selector(btnClickClose)];
  
  self.datas = @[@{@"name": @"扫码", @"vc": @"ZWScannerVC"}, @{@"name": @"扫码2", @"vc": @"ScanCodeVC"}, @{@"name": @"CustomVC", @"vc": @"CustomVC"}];
  self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  [self.view addSubview:self.tableView];
  [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
  }];
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"TableViewCID"];
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)btnClickClose {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showNewPageVC:(UIViewController *)vc {
  if (self.navigationController) {
    [self.navigationController pushViewController:vc animated:YES];
  } else {
    [self presentViewController:vc animated:YES completion:nil];
  }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return 50.0;
}

///*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TableViewCID" forIndexPath:indexPath];
  
  [cell.contentView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    [obj removeFromSuperview];
  }];
  if (indexPath.section == 0) {
    if (indexPath.row < self.datas.count) {
      UILabel *l = [[UILabel alloc] init];
      l.text = [self.datas[indexPath.row] objectForKey:@"name"];
      l.textColor = [UIColor blueColor];
      [cell.contentView addSubview:l];
      [l mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(cell.contentView);
      }];
      return cell;
    }
  }
  UITextField *tf = [[UITextField alloc] init];
  tf.placeholder = [@"-----" stringByAppendingFormat:@"%ld", indexPath.row];
  [cell.contentView addSubview:tf];
  [tf mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.top.equalTo(cell.contentView).offset(10);
    make.right.bottom.equalTo(cell.contentView).offset(-10);
  }];
  tf.borderStyle = UITextBorderStyleRoundedRect;
  
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
  if (section == 0)
  {
    return 20;
  }
  return 40.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
  if (section == 1)
  {
    UILabel *view = [[UILabel alloc] init];
    view.text = @"--------123456633";
    view.textColor = [UIColor redColor];
    return view;
  }
  UIView *view = [[UIView alloc] init];
  return view;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section == 0) {
    if (indexPath.row < self.datas.count) {
      NSString *strVC = [self.datas[indexPath.row] objectForKey:@"vc"];
      UIViewController *vc = [[NSClassFromString(strVC) alloc] init];
      [self showNewPageVC:vc];
    }
  }
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
