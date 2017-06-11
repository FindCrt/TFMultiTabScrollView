//
//  TRScrollSimulateView.h
//  MultiTableView
//
//  Created by wei shi on 2017/4/1.
//  Copyright © 2017年 wei shi. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    TRScrollSimulateViewLockNone,
    TRScrollSimulateViewLockHorizontal,
    TRScrollSimulateViewLockVertical
} TRScrollSimulateViewLockAxis;

@class TFScrollSimulateView;

@interface TFScrollSimulateView : UIView

@property (nonatomic, weak) UIScrollView *scrollView;

@property (nonatomic, assign) TRScrollSimulateViewLockAxis lockAxis;

@property (nonatomic, strong, readonly) UIPanGestureRecognizer *pan;

-(UIView *)superHitTest:(CGPoint)point withEvent:(UIEvent *)event;

@end
