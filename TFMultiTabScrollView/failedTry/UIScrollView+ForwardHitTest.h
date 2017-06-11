//
//  UIScrollView+ForwardHitTest.h
//  MultiTableView
//
//  Created by shiwei on 2017/6/4.
//  Copyright © 2017年 wei shi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TFScrollSimulateView;
@interface UIScrollView (ForwardHitTest)

@property (nonatomic, strong) TFScrollSimulateView *forwardView;

@end
