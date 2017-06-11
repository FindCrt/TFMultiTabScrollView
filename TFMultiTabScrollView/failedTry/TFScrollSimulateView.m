//
//  TRScrollSimulateView.m
//  MultiTableView
//
//  Created by wei shi on 2017/4/1.
//  Copyright © 2017年 wei shi. All rights reserved.
//

#import "TFScrollSimulateView.h"
//#import "UIScrollView+ForwardHitTest.h"
////#import "YMScrollSimulateRefreshHeader.h"

#define KTimerInterval  (1/60.0)

@interface TFScrollSimulateView ()<UIGestureRecognizerDelegate>{
    UIPanGestureRecognizer *_pan;
    
    CGPoint _lastTranslation;
    NSTimer *_timer;
    
    CGPoint _velocity;
    CGFloat _friction; //阻力系数
    
    NSMutableDictionary *_eventTag;
}

@end

@implementation TFScrollSimulateView

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        _pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        //[self addGestureRecognizer:_pan];
        
        _pan.delaysTouchesBegan = YES;
        
        _friction = 0.004;
        
        _eventTag = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

-(void)handlePan:(UIPanGestureRecognizer *)pan{
    NSLog(@"pan state: %ld",(long)pan.state);
    
    CGPoint translation = [pan translationInView:[UIApplication sharedApplication].keyWindow];
    
    if (pan.state == UIGestureRecognizerStateBegan) {
        [_timer invalidate];
        _timer = nil;
        
        [_scrollView setContentOffset:_scrollView.contentOffset animated:NO];
        //_scrollView.TRMJ_Draging = YES;
        
    }else if (pan.state == UIGestureRecognizerStateChanged) {
        
        CGPoint deltaOffset = CGPointMake(_lastTranslation.x - translation.x, _lastTranslation.y - translation.y);
        
        [self translateOffsetToScrollView:deltaOffset];
        
    }else if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        
        //_scrollView.TRMJ_Draging = NO;
        
        
        if ([self checkScrollViewExceedAndReset]) {
            return;
        }
        
        _velocity = [pan velocityInView:[UIApplication sharedApplication].keyWindow];
        
        CGFloat module = sqrt(_velocity.x * _velocity.x + _velocity.y * _velocity.y);
        
        
        if (module < 10) {
            return;
        }
        
        _timer = [NSTimer timerWithTimeInterval:KTimerInterval target:self selector:@selector(handleTimer:) userInfo:nil repeats:YES];
        //[_timer addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [[NSRunLoop currentRunLoop]addTimer:_timer forMode:NSRunLoopCommonModes];
        //[_displayLink fire];
        
        
    }
    
    _lastTranslation = translation;
}

-(void)handleTimer:(NSTimer *)timer{
    if (_scrollView.dragging) {
        [_timer invalidate];
        _timer = nil;
    }
    
    CGFloat maxOffsetX = _scrollView.contentSize.width + _scrollView.contentInset.right - _scrollView.frame.size.width;
    CGFloat maxOffsetY = _scrollView.contentSize.height + _scrollView.contentInset.bottom - _scrollView.frame.size.height;
    CGFloat minOffsetX = -_scrollView.contentInset.left;
    CGFloat minOffsetY = -_scrollView.contentInset.top;
    
    if ((_scrollView.contentOffset.x <= minOffsetX && _velocity.x > 0 ) || (_scrollView.contentOffset.x >= maxOffsetX && _velocity.x < 0)) {
        _velocity.x = 0;
    }
    if ((_scrollView.contentOffset.y <= minOffsetY && _velocity.y > 0 ) || (_scrollView.contentOffset.y >= maxOffsetY && _velocity.y < 0)) {
        _velocity.y = 0;
    }
    
    //手势滑动方向和contentOffset的增减方向是相反的
    CGPoint deltaOffset = CGPointMake(-_velocity.x * KTimerInterval, -_velocity.y * KTimerInterval);
    
    CGFloat module = sqrt(_velocity.x * _velocity.x + _velocity.y * _velocity.y);
    CGFloat xRate = _velocity.x / module;
    CGFloat yRate = _velocity.y / module;
    
    module -= KTimerInterval * _friction * (10000 + module * module);  //阻力和速度平方成正比，速度减去a*t
    
    if (module <= 0) {
        
        [_timer invalidate];
        _timer = nil;
        [self checkScrollViewExceedAndReset];
        
        return;
    }
    _velocity = CGPointMake(module * xRate, module * yRate);
    
    [self translateOffsetToScrollView:deltaOffset];
}

-(void)translateOffsetToScrollView:(CGPoint)deltaOffset{
    
    CGFloat maxOffsetX = _scrollView.contentSize.width + _scrollView.contentInset.right - _scrollView.frame.size.width;
    CGFloat maxOffsetY = _scrollView.contentSize.height + _scrollView.contentInset.bottom - _scrollView.frame.size.height;
    CGFloat minOffsetX = -_scrollView.contentInset.left;
    CGFloat minOffsetY = -_scrollView.contentInset.top;
    
    //边缘弹性处理
    //根据超出距离的多少来决定移动量的衰减，所谓“弹性”就是手指滑动了1，而scrollView实际滚动了0.5,这之间存在一个衰减
    CGFloat exceedOffsetX = MAX(_scrollView.contentOffset.x - maxOffsetX, minOffsetX -_scrollView.contentOffset.x);
    if (exceedOffsetX > 0) {
        deltaOffset.x = [self dampingOffset:deltaOffset.x exceedOffset:exceedOffsetX];
    }
    
    CGFloat exceedOffsetY = MAX(_scrollView.contentOffset.y - maxOffsetY, minOffsetY -_scrollView.contentOffset.y);
    if (exceedOffsetY > 0) {
        deltaOffset.y = [self dampingOffset:deltaOffset.y exceedOffset:exceedOffsetY];
    }
    
    CGFloat offsetX = _scrollView.contentOffset.x + deltaOffset.x;//MAX(MIN(maxOffsetX, _scrollView.contentOffset.x + deltaOffset.x), minOffsetX);
    CGFloat offsetY = _scrollView.contentOffset.y + deltaOffset.y; //MAX(MIN(maxOffsetY, _scrollView.contentOffset.y + deltaOffset.y), minOffsetY);
    
    if (_lockAxis == TRScrollSimulateViewLockHorizontal) {
        offsetX = _scrollView.contentOffset.x;
    }else if(_lockAxis == TRScrollSimulateViewLockVertical){
        offsetY = _scrollView.contentOffset.y;
    }
    
    [_scrollView setContentOffset:CGPointMake(offsetX, offsetY) animated:NO];
}

-(CGFloat)dampingOffset:(CGFloat)offset exceedOffset:(CGFloat)exceedOffset{
    return offset / (1+exceedOffset/100);
}

//放手后检测scrollView是否超出，是则恢复
-(BOOL)checkScrollViewExceedAndReset{
    CGFloat maxOffsetX = _scrollView.contentSize.width + _scrollView.contentInset.right - _scrollView.frame.size.width;
    CGFloat maxOffsetY = _scrollView.contentSize.height + _scrollView.contentInset.bottom - _scrollView.frame.size.height;
    CGFloat minOffsetX = -_scrollView.contentInset.left;
    CGFloat minOffsetY = -_scrollView.contentInset.top;
    
    BOOL exceed = NO;
    CGPoint resetOffset = CGPointZero;
    if (_scrollView.contentOffset.x < minOffsetX) {
        exceed = YES;
        resetOffset.x = minOffsetX;
    }else if (_scrollView.contentOffset.x > maxOffsetX){
        exceed = YES;
        resetOffset.x = maxOffsetX;
    }
    
    if (_scrollView.contentOffset.y < minOffsetY) {
        exceed = YES;
        resetOffset.y = minOffsetY;
    }else if (_scrollView.contentOffset.y > maxOffsetY){
        exceed = YES;
        resetOffset.y = maxOffsetY;
    }
    
    if (exceed) {
        [_scrollView setContentOffset:resetOffset animated:YES];
    }
    
    return exceed;
}

#pragma mark - 属性

-(UIPanGestureRecognizer *)pan{
    return _pan;
}

-(void)setScrollView:(UIScrollView *)scrollView{
    _scrollView = scrollView;
    
    if (_scrollView != scrollView) {
        [_timer invalidate];
        _timer = nil;
    }
}

//-(UIView *)superHitTest:(CGPoint)point withEvent:(UIEvent *)event{
//    return [super hitTest:point withEvent:event];
//}
//
//-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
//    
//    _scrollView.forwardView = self;
//    return _scrollView;
//    
////    NSValue *key = [NSValue valueWithNonretainedObject:event];
////    if ([[_eventTag objectForKey:key] integerValue] > 0) {
////        
////        NSLog(@"hit test super");
////        
////        [_eventTag removeObjectForKey:key];
////        return [super hitTest:point withEvent:event];
////    }else{
////        
////        NSLog(@"hit test forward");
////        
////        _scrollView.forwardView = self;
////        NSInteger count = [[_eventTag objectForKey:key] integerValue];
////        count ++;
////        [_eventTag setObject:@(count) forKey:key];
////        return _scrollView;
////    }
//}

@end
