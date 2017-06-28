//
//  TRMultiTabTableView.h
//  MultiTableView
//
//  Created by wei shi on 2017/3/31.
//  Copyright © 2017年 wei shi. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kMultiScrollViewTabHeight          40

@class TFMultiTabScrollView;
@protocol TFMultiTabScrollViewDelegate <NSObject>

/**
 * 提供头部高度
 */

-(CGFloat )headerHeightForMultiTabScrollView:(TFMultiTabScrollView *)multiTabScrollView;

/**
 * 提供头部视图
 */
-(UIView *)headerViewForMultiTabScrollView:(TFMultiTabScrollView *)multiTabScrollView;

/**
 * 提供tab栏按钮的名称数组，元素NSString类型
 */
-(NSArray *)tabNamesForMultiTabScrollView:(TFMultiTabScrollView *)multiTabScrollView;

/**
 *  提供每个tab分页对应的内容视图
 * @param index 分页的索引
 */
-(UIScrollView *)tabScrollviewForMultiTabScrollView:(TFMultiTabScrollView *)multiTabScrollView atTabIndex:(NSInteger)index;


@optional

/**
 * tab分页视图切换时触发这个方法
 * @param tabIndex 切换后的分页索引
 */
-(void)multiTabScrollView:(TFMultiTabScrollView *)tabScrollView switchToTab:(NSInteger)tabIndex;

/**
 * 视图整体上下滚动时调用，可用于下拉刷新或导航栏透明度变化等效果的控制
 * @param offset  为当前分页的scrollView的contentOffset
 */
-(void)multiTabScrollView:(TFMultiTabScrollView *)tabScrollView offsetChanged:(CGPoint)offset;

@end




@interface TFMultiTabScrollView : UIView

/**
 委托对象
 */
@property (nonatomic, weak) id<TFMultiTabScrollViewDelegate>delegate;


/**
 tab栏的按钮在分页这一分页内容时的文字，以及滚动指示器的颜色
 */
@property (nonatomic, strong) UIColor *tabHighlightColor;


/**
 当前显示的内容分页索引
 */
@property (nonatomic, assign) NSInteger selectedTabIndex;


/**
 头部视图悬浮时，tab栏顶部距离整个视图框顶部的距离；可通过调整这个值，调整头部视图的悬浮位置。
 */
@property (nonatomic, assign) CGFloat topSpace;


/**
 YES时，内容视图部分的顶部要衔接到头部视图的顶部，才能拖动头部视图，即只有内容视图滑到顶才会移动头部；参考微博/简书个人中心
 NO时，只要滑动内容视图，头部都会跟随变化，类似safari的导航栏搜索框
 */
//@property (nonatomic, assign) BOOL moveHeaderOnlyContentTop;


/**
 当内容高度不够时，tab栏会滚不到顶部。如果设置这个值为YES时，会自动调整contentInsert.bottom来让内容可以充满。默认YES
 */
@property (nonatomic, assign) BOOL autoFillContent;

@end
