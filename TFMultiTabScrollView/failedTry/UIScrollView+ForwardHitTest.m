//
//  UIScrollView+ForwardHitTest.m
//  MultiTableView
//
//  Created by shiwei on 2017/6/4.
//  Copyright © 2017年 wei shi. All rights reserved.
//

#import "UIScrollView+ForwardHitTest.h"
#import <objc/runtime.h>
#import "TFScrollSimulateView.h"

const static NSString *forwradViewKey = @"";

@implementation UIScrollView (ForwardHitTest)

-(TFScrollSimulateView *)forwardView{
    return objc_getAssociatedObject(self, &forwradViewKey);
}

-(void)setForwardView:(UIView *)forwardView{
    objc_setAssociatedObject(self, &forwradViewKey, forwardView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    if (self.forwardView) {
        TFScrollSimulateView *temp = self.forwardView;
        self.forwardView = nil;
        return [temp superHitTest:point withEvent:event];
    }
    
    return [super hitTest:point withEvent:event];
}

@end
