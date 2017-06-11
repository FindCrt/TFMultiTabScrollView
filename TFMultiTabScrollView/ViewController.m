//
//  ViewController.m
//  MultiTableView
//
//  Created by wei shi on 2017/3/31.
//  Copyright © 2017年 wei shi. All rights reserved.
//

#import "ViewController.h"
#import "TFMultiTabScrollView.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource, TFMultiTabScrollViewDelegate>{
    TFMultiTabScrollView *_tabScrollView;
    
    UITableView *_booksTableView;
    UITableView *_moviesTableView;
    UIScrollView *_musicView;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //三个分页
    _booksTableView = [[UITableView alloc] initWithFrame:(CGRectZero) style:(UITableViewStyleGrouped)];
    _booksTableView.delegate = self;
    _booksTableView.dataSource = self;
    
    _moviesTableView = [[UITableView alloc] initWithFrame:(CGRectZero) style:(UITableViewStyleGrouped)];
    _moviesTableView.delegate = self;
    _moviesTableView.dataSource = self;
    
    _musicView = [[UIScrollView alloc] initWithFrame:(CGRectZero)];
    _musicView.contentSize = CGSizeMake(100, 100);
    UILabel *label = [[UILabel alloc] initWithFrame:(CGRectMake(30, 50, [UIScreen mainScreen].bounds.size.width - 60, 120))];
    label.text = @"Music List";
    label.backgroundColor = [UIColor orangeColor];
    label.textColor = [UIColor whiteColor];
    label.layer.cornerRadius = 5;
    label.layer.masksToBounds = YES;
    label.textAlignment = NSTextAlignmentCenter;
    [_musicView addSubview:label];
    
    
    _tabScrollView = [[TFMultiTabScrollView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _tabScrollView.delegate = self;
    _tabScrollView.moveHeaderOnlyContentTop = YES;
    [self.view addSubview:_tabScrollView];
}

#pragma mark - TFMultiTabScrollViewDelegate

-(CGFloat)headerHeightForMultiTabScrollView:(TFMultiTabScrollView *)multiTabScrollView{
    return 280;
}

-(UIView *)headerViewForMultiTabScrollView:(TFMultiTabScrollView *)multiTabScrollView{
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 375, 280)];
    header.backgroundColor = [UIColor whiteColor];
    
    
    //在头部视图里添加一个scrollView，测试头部的滚动事件是否正确
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:header.bounds];
    scrollView.pagingEnabled = YES;
    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width*3, 280);
    scrollView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    NSArray *cardImgNames = @[@"flowers",@"river",@"ice"];
    for (int i = 0; i<3; i++) {
        UIImageView *card = [[UIImageView alloc] initWithFrame:CGRectMake(375*i+35, 20, 300, 200)];
        card.image = [UIImage imageNamed:cardImgNames[i]];
        card.layer.cornerRadius = 5;
        card.layer.masksToBounds = YES;
        
        [scrollView addSubview:card];
    }
    [header addSubview:scrollView];
    
    
    //头部添加一个按钮，测试点击事件是否正确
    UIButton *headerBtn = [[UIButton alloc] initWithFrame:(CGRectMake([UIScreen mainScreen].bounds.size.width / 2.0 - 50, 230, 100, 40))];
    headerBtn.backgroundColor = [UIColor whiteColor];
    [headerBtn setTitle:@"touch test" forState:(UIControlStateNormal)];
    [headerBtn setTitleColor:[UIColor orangeColor] forState:(UIControlStateNormal)];
    [headerBtn addTarget:self action:@selector(tapHeaderButton) forControlEvents:(UIControlEventTouchUpInside)];
    [header addSubview:headerBtn];
    
    return header;
}



-(NSArray *)tabNamesForMultiTabScrollView:(TFMultiTabScrollView *)multiTabScrollView{
    return @[@"Book",@"Movie",@"Music"];
}

-(UIScrollView *)tabScrollviewForMultiTabScrollView:(TFMultiTabScrollView *)multiTabScrollView atTabIndex:(NSInteger)index{
    if (index == 0) {
        return _booksTableView;
    }else if (index == 1){
        return _moviesTableView;
    }else{
        return _musicView;
    }
}

-(void)tapHeaderButton{
    NSLog(@"tap header button");
    
    [_booksTableView self];
}

#pragma mark - tableView delegate & data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if (tableView == _booksTableView){
        return 2;
    }else{
        return 1;
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (tableView == _booksTableView){
        if (section == 0) {
            return 1;
        }else{
            return 20;
        }
    }else{
        return 10;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == _booksTableView){
        if (indexPath.section == 0) {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleDefault) reuseIdentifier:nil];
            cell.textLabel.text = @"Book Descriptions";
            cell.textLabel.font = [UIFont systemFontOfSize:24];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            return cell;
        }else{
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleDefault) reuseIdentifier:nil];
            cell.textLabel.text = [NSString stringWithFormat:@"book %ld",(long)indexPath.row];
            return cell;
        }
    }else{
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleDefault) reuseIdentifier:nil];
        cell.textLabel.text = [NSString stringWithFormat:@"movie %ld",(long)indexPath.row];
        return cell;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == _booksTableView){
        if (indexPath.section == 0) {
            return 200;
        }else{
            return 40;
        }
    }else{
        return 50;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 15;
}

@end
