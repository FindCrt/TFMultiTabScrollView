//
//  TRMultiTabTableView.m
//  MultiTableView
//
//  Created by wei shi on 2017/3/31.
//  Copyright © 2017年 wei shi. All rights reserved.
//

#import "TFMultiTabScrollView.h"

#define kTabButtonTag               1000
#define kNormalTextColor            [UIColor darkTextColor]
#define kResetedVisableHeaderH      -1000
#define kTFDestinationsIndexEmpty   -1

/**
 * 头部视图的容器，为了用于处理头部的滚动手势
 */
@interface TFTabScrollHeaderView : UIView

//横向滑动的内容视图容器，需要屏蔽它的横向滑动手势
@property (nonatomic, weak) UIScrollView *tabContainer;

@end

@interface TFTabScrollHeaderView ()<UIGestureRecognizerDelegate>{
    UIPanGestureRecognizer *_pan;
}

@end

@implementation TFTabScrollHeaderView

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    
    return self;
}

-(void)commonInit{
    _pan = [[UIPanGestureRecognizer alloc] initWithTarget:nil action:nil];
    _pan.delegate = self;
    //_pan.cancelsTouchesInView = NO;
    [self addGestureRecognizer:_pan];
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    
    //_tabContainer是横向滑动的scrollView,而在头部视图横向滑动的时候，不能触发内容横向滑动，所以这里的手势冲突时，不让_tabContainer的手势优先判断
    if (otherGestureRecognizer.view == _tabContainer) {
        return NO;
    }
    
    return YES;
}

@end


#pragma mark - TFMultiTabScrollView

@interface TFMultiTabScrollView ()<UIScrollViewDelegate,UIGestureRecognizerDelegate>{
    
    //头部视图的高度
    CGFloat _topHeight;
    //tab栏按钮的名称数组
    NSArray *_tabNames;
    //tab栏按钮
    NSMutableArray *_tabButtons;
    //tab栏的选中指示器
    UIView *_tabIndicator;
    
    //头部视图容器
    TFTabScrollHeaderView *_headerContainer;
    
    //内容视图容器
    UIScrollView *_tabViewContainer;
    
    //每个分页的内容视图数组
    NSMutableArray *_tabScrollViews;
    
    //构建一次标记
    BOOL _hasConstructed;
    
    //当前的头部视图可见高度，范围在[tab栏高度，头部高度]
    CGFloat _currentVisableHeaderH;
    //内容滑到底部时，头部的可见高度
    CGFloat _contentBottomVisableHeaderH;
    
    //点击切换分页时目标位置，只是用来区分点击切换分页和滚动切换
    NSInteger _destinationsIndex;
    
    //记录离开某个分页时，头部当时的可见高度,用来在再次回到那个页面时让内容和头部保持不变相对位置
    NSMutableDictionary *_visableHeaderHDic;
    
    UIScrollView *_ignoreOffsetChangesScrollView;
}

@property (nonatomic, strong) UIView *headerView;

@property (nonatomic, assign) BOOL moveHeaderOnlyContentTop;

@end

@implementation TFMultiTabScrollView

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        _tabHighlightColor = [UIColor redColor];
        _autoFillContent = YES;
        _moveHeaderOnlyContentTop = YES;
        _visableHeaderHDic = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    
    if (!_hasConstructed) {
        [self constructSubviews];
        _hasConstructed = YES;
    }
}

-(void)constructSubviews{
    
    [self setupTabScrollViews];
    [self setupHeaderView];
}

-(void)setupTabScrollViews{
    
    CGFloat totalWidth = self.bounds.size.width;
    
    if ([self.delegate respondsToSelector:@selector(headerHeightForMultiTabScrollView:)]) {
        _topHeight = [self.delegate headerHeightForMultiTabScrollView:self];
    }
    
    _tabNames = [self.delegate tabNamesForMultiTabScrollView:self];
    
    //横向scrollView
    _tabViewContainer = [[UIScrollView alloc] initWithFrame:self.bounds];
    _tabViewContainer.pagingEnabled = YES;
    _tabViewContainer.bounces = NO;
    _tabViewContainer.showsHorizontalScrollIndicator = NO;
    _tabViewContainer.contentSize = CGSizeMake(totalWidth * _tabNames.count,1);
    _tabViewContainer.delegate = self;
    [self addSubview:_tabViewContainer];
    
    //添加每个tab的子scrollVew
    _tabScrollViews = [[NSMutableArray alloc] init];
    for (int i = 0; i < _tabNames.count; i++) {
        
        [_visableHeaderHDic setObject:@(_topHeight + kMultiScrollViewTabHeight) forKey:@(i)];
        
        UIScrollView *tabScrollView = [self.delegate tabScrollviewForMultiTabScrollView:self atTabIndex:i];
        
        tabScrollView.contentInset = UIEdgeInsetsMake(_topHeight + kMultiScrollViewTabHeight, 0, 0, 0);
        
        //一开始滚动在顶部
        tabScrollView.contentOffset = CGPointMake(0, -tabScrollView.contentInset.top);
        
        tabScrollView.frame = CGRectMake(totalWidth * i, 0, totalWidth, _tabViewContainer.frame.size.height);
        [_tabViewContainer addSubview:tabScrollView];
        
        tabScrollView.tag = 10000 + i;
        [tabScrollView addObserver:self forKeyPath:@"contentOffset" options:(NSKeyValueObservingOptionNew) context:nil];
        
        if (_autoFillContent) {
            [tabScrollView addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:nil];
        }
        
        if (![tabScrollView isKindOfClass:[UITableView class]]) {
            tabScrollView.contentSize = CGSizeMake(tabScrollView.frame.size.width, tabScrollView.contentSize.height);
        }
        
        [_tabScrollViews addObject:tabScrollView];
    }
}

-(void)setupHeaderView{
    
    CGFloat totalWidth = self.bounds.size.width;
    
    //头部view覆盖
    _headerContainer = [[TFTabScrollHeaderView alloc] initWithFrame:(CGRectMake(0, -(_topHeight + kMultiScrollViewTabHeight), totalWidth, _topHeight + kMultiScrollViewTabHeight))];
    _headerContainer.tabContainer = _tabViewContainer;
    
    //初始时头部全部显示
    _currentVisableHeaderH = _topHeight + kMultiScrollViewTabHeight;
    
    UIScrollView *currentScrollView = _tabScrollViews[0];
    [currentScrollView addSubview:_headerContainer];
    
    if ([self.delegate respondsToSelector:@selector(headerViewForMultiTabScrollView:)]) {
        _headerView = [self.delegate headerViewForMultiTabScrollView:self];
        _headerView.frame = CGRectMake(0, 0, totalWidth, _topHeight);
        
        [_headerContainer addSubview:_headerView];
    }
    
    //分页栏
    UIView *tabView = [[UIView alloc] initWithFrame:(CGRectMake(0, _topHeight, totalWidth, kMultiScrollViewTabHeight))];
    tabView.backgroundColor = [UIColor whiteColor];
    
    UIView *line = [[UIView alloc] initWithFrame:(CGRectMake(0, kMultiScrollViewTabHeight-1, totalWidth, 0.5))];
    line.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    [tabView addSubview:line];
    
    _tabButtons = [[NSMutableArray alloc] init];
    CGFloat tabWidth = totalWidth / _tabNames.count;
    for (int i = 0; i<_tabNames.count; i++) {
        UIButton *tabButton = [[UIButton alloc] initWithFrame:(CGRectMake(tabWidth * i, 0, tabWidth, kMultiScrollViewTabHeight))];
        [tabButton setTitle:_tabNames[i] forState:(UIControlStateNormal)];
        [tabButton setTitleColor:i == _selectedTabIndex ? _tabHighlightColor : kNormalTextColor forState:(UIControlStateNormal)];
        [tabButton setContentHorizontalAlignment:(UIControlContentHorizontalAlignmentCenter)];
        tabButton.tag = kTabButtonTag + i;
        [tabButton addTarget:self action:@selector(switchTabView:) forControlEvents:(UIControlEventTouchUpInside)];
        
        [tabView addSubview:tabButton];
        
        [_tabButtons addObject:tabButton];
    }
    
    //指示器
    CGFloat width = MIN(tabWidth, 80);
    _tabIndicator = [[UIView alloc] initWithFrame:(CGRectMake((tabWidth-width)/2.0, kMultiScrollViewTabHeight - 2, width, 2))];
    _tabIndicator.backgroundColor = _tabHighlightColor;
    [tabView addSubview:_tabIndicator];
    
    [_headerContainer addSubview:tabView];

}

-(void)switchTabView:(UIButton *)button{
    
    NSInteger tabIndex = button.tag - kTabButtonTag;
    
    if (tabIndex == _selectedTabIndex) {
        return;
    }
    
    [self startSwitchTabView];
    
    //点击造成的横向滚动过程中不再响应事件，知道滚动结束
    self.userInteractionEnabled = NO;
    
    CGFloat totalWidth = _tabViewContainer.frame.size.width;
    _destinationsIndex = tabIndex;
    
    [_tabViewContainer setContentOffset:(CGPointMake(totalWidth * tabIndex, 0)) animated:YES];
}

-(void)changeIndicatorToIndex:(NSInteger)index{
    if (_selectedTabIndex == index) {
        return;
    }
    
    CGFloat totalWidth = _tabViewContainer.frame.size.width;
    CGFloat tabWidth = totalWidth / _tabNames.count;
    
    [UIView animateWithDuration:0.15 animations:^{
        _tabIndicator.transform = CGAffineTransformMakeTranslation(tabWidth * index, 0);
    }];
    
    UIButton *lastTabButton = _tabButtons[_selectedTabIndex];
    [lastTabButton setTitleColor:kNormalTextColor forState:(UIControlStateNormal)];
    UIButton *curTabButton = _tabButtons[index];
    [curTabButton setTitleColor:_tabHighlightColor forState:(UIControlStateNormal)];
    
    _selectedTabIndex = index;
    
    if ([self.delegate respondsToSelector:@selector(multiTabScrollView:switchToTab:)]) {
        [self.delegate multiTabScrollView:self switchToTab:_selectedTabIndex];
    }
}

#pragma mark - header pan gesture delegate

-(void)headerPan:(UIPanGestureRecognizer *)pan{
    NSLog(@"headerPan");
}

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    return YES;
}

#pragma mark - 监听内部scrollView滚动

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"contentOffset"]) {
        UIScrollView *scrollView = (UIScrollView*)object;
        
        if (_ignoreOffsetChangesScrollView == scrollView) {
            return;
        }
        
        CGFloat offsetY = [[change objectForKey:NSKeyValueChangeNewKey] CGPointValue].y;
        CGFloat maxOffsetY = MAX(0, scrollView.contentSize.height - scrollView.frame.size.height);
        
        //头部悬浮视图跟随offset改变，但是保持tab栏可见，即最小值-_topHeight+_topSpace;当offset.y为-_topHeight时，tab栏正好贴住顶部，_topSpace是跟顶部距离
        
        //这个是tab顶部和控件总体最顶部的距离，一般就是手机屏幕顶部了
        CGRect headerFrame = _headerContainer.frame;
        _currentVisableHeaderH = headerFrame.origin.y + headerFrame.size.height - offsetY;
        
        
        if (_moveHeaderOnlyContentTop) {
            
            //内容没有滑到顶部时，保持头部不移动
            if (headerFrame.origin.y > -headerFrame.size.height) {
                
                headerFrame.origin.y = _topSpace + offsetY + kMultiScrollViewTabHeight - headerFrame.size.height;
                
            }else if (headerFrame.origin.y < -headerFrame.size.height){
                
                //内容区域低于头部的底部时，矫正到相等
                CGFloat minHeaderY = _topSpace + offsetY + kMultiScrollViewTabHeight - headerFrame.size.height;
                headerFrame.origin.y = MAX(-headerFrame.size.height,minHeaderY);
                NSLog(@"adjust");
            }
        }else{
            //向上拉出弹簧效果时，不处理
            
            if (offsetY > maxOffsetY) {
                return;
                
            }
        }
        
        CGFloat minOffset = -scrollView.contentInset.top;
        //向下拉出弹簧效果时不做处理
        if (offsetY > minOffset) {
            
            //向上滚到一定程度，悬浮头部，保持可见高度为tab栏的高度+_topSpace，设计_topSpace是为了能够调控选为位置
            if (_currentVisableHeaderH < _topSpace + kMultiScrollViewTabHeight) {
                
                headerFrame.origin.y = _topSpace + offsetY + kMultiScrollViewTabHeight - headerFrame.size.height;
                
            }else if (_currentVisableHeaderH > headerFrame.size.height){
                //向下滚到一定程度，悬浮头部，这时是头部整个可见
                
                headerFrame.origin.y = offsetY;
            }
            _headerContainer.frame = headerFrame;
            [_headerContainer.superview bringSubviewToFront:_headerContainer];
        }
        
//        //头部跟随滑动时，即内容视图到顶时，每页的scrollView的offset要相同，否则横向滑动会出现内容没到顶和头部没到顶共存的情况
//        if (offsetY <= -kMultiScrollViewTabHeight-_topSpace && _moveHeaderOnlyContentTop) {
//            [self synctabScrollViewOffsetY:offsetY exclusive:scrollView];
//        }
        
        //加上contentInset.top后为内容超出顶部的实际距离
        if ([self.delegate respondsToSelector:@selector(multiTabScrollView:offsetChanged:)]) {
            [self.delegate multiTabScrollView:self offsetChanged:CGPointMake(scrollView.contentOffset.x, offsetY)];
        }
        
    }else if ([keyPath isEqualToString:@"contentSize"]){
        
        if (!_autoFillContent) {
            return;
        }
        
        UIScrollView *scrollView = (UIScrollView*)object;
        
        //视图框的高度，减去tab栏高度，减去顶部高度，就是tab内容子视图（scrollView）的窗口高度，减去scrollView的内容高度，就是底部edgeInset的补充高度
        CGFloat bottom = (_tabViewContainer.frame.size.height - kMultiScrollViewTabHeight) - scrollView.contentSize.height - _topSpace;
        if (bottom > 0 ) {
            
            scrollView.contentInset = UIEdgeInsetsMake(scrollView.contentInset.top, 0,bottom , 0);
        }else if (scrollView.contentInset.bottom != 0){ //bottom小于0时，要重置回来
            scrollView.contentInset = UIEdgeInsetsMake(scrollView.contentInset.top, 0,0 , 0);
        }
    }
}

-(void)synctabScrollViewOffsetY:(CGFloat)offsetY exclusive:(UIScrollView *)currentScrollView{
    for (int i = 0; i<_tabScrollViews.count; i++) {
        UIScrollView *tabScrollView = _tabScrollViews[i];
        if (tabScrollView == currentScrollView) {
            continue;
        }
        
        _ignoreOffsetChangesScrollView = tabScrollView;
        tabScrollView.contentOffset = CGPointMake(tabScrollView.contentOffset.x,offsetY);
        _ignoreOffsetChangesScrollView = nil;
    }
}

#pragma mark - 横向滑动scrollView

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [self startSwitchTabView];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    NSInteger tabIndex = scrollView.contentOffset.x / scrollView.frame.size.width + 0.5;
    [self changeIndicatorToIndex:tabIndex];
    
    //把头部调到横向滑动的scrollView上去
    if (_headerContainer.superview != _tabViewContainer) {
        
        CGRect headerFrame = _headerContainer.frame;
        
        _headerContainer.frame = [_tabViewContainer convertRect:headerFrame fromView:_headerContainer.superview];
        [_tabViewContainer addSubview:_headerContainer];
    }
    
    CGRect frame = _headerContainer.frame;
    frame.origin.x = scrollView.contentOffset.x;
    _headerContainer.frame = frame;
    
    //调用srollView的setContentOffset不执行EndDecelerating代理，只有在这里处理一下了
    if (_destinationsIndex != kTFDestinationsIndexEmpty && scrollView.contentOffset.x == _destinationsIndex * scrollView.frame.size.width && !scrollView.isDragging) {
        
        [self switchTabViewCompleted];
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self switchTabViewCompleted];
    
}

-(void)startSwitchTabView{
    [_visableHeaderHDic setObject:@(_currentVisableHeaderH) forKey:@(_selectedTabIndex)];
    [self adjustContentScrollViewOffsetToFollowHeader];
}

-(void)switchTabViewCompleted{
    
    self.userInteractionEnabled = YES;
    _destinationsIndex = kTFDestinationsIndexEmpty;
    
    [self moveHeaderToContentView];
    [self clampContentScrollViewOffset];
}

#pragma mark - 切换分页时调整


//滑动结束时，把头部再放回当前显示的scrolView
-(void)moveHeaderToContentView{
    if (_headerContainer.superview == _tabViewContainer) {
        UIScrollView *currentContentView = _tabScrollViews[_selectedTabIndex];
        
        CGRect frame = [currentContentView convertRect:_headerContainer.frame fromView:_tabViewContainer];
        frame.origin.y = _currentVisableHeaderH + currentContentView.contentOffset.y - _headerContainer.frame.size.height;
        _headerContainer.frame = frame;
        
        [currentContentView addSubview:_headerContainer];
    }
}

//调整分页scrollView，让内容跟随头部移动；离开时头部靠着什么内容，回来时还是什么内容
-(void)adjustContentScrollViewOffsetToFollowHeader{
    for (int i = 0; i<_tabScrollViews.count; i++) {
        if (i == _selectedTabIndex) {
            continue;
        }
        
        UIScrollView *tabScrollView = _tabScrollViews[i];
        CGFloat headerYChange = _currentVisableHeaderH - [[_visableHeaderHDic objectForKey:@(i)] floatValue];
        CGPoint contentOffset = tabScrollView.contentOffset;
        contentOffset.y -= headerYChange;
        
        _ignoreOffsetChangesScrollView = tabScrollView;
        tabScrollView.contentOffset = contentOffset;
        _ignoreOffsetChangesScrollView = nil;
    }
}

//如果分页scrollView的内容比较少，可能当前contentOffset超过最大值了，调整回来
-(void)clampContentScrollViewOffset{
    if (_autoFillContent) {
        return;
    }
    
    UIScrollView *currentContentView = _tabScrollViews[_selectedTabIndex];
    
    //scrollView无法滚动的时候，即使contentSize设成0，但实际有空间展示内容，这里求的就是最少的展示空间高度
    CGFloat showContentY = MAX(currentContentView.contentSize.height, currentContentView.frame.size.height - currentContentView.contentInset.top - currentContentView.contentInset.bottom);
    
    CGFloat maxContentOffsetY = showContentY - currentContentView.frame.size.height;
    if (currentContentView.contentOffset.y > maxContentOffsetY) {
        [currentContentView setContentOffset:CGPointMake(currentContentView.contentOffset.x, maxContentOffsetY) animated:YES];
    }
}

-(void)dealloc{
    for (int i = 0; i<_tabScrollViews.count; i++) {
        UIScrollView *tabScrollView = _tabScrollViews[i];
        [tabScrollView removeObserver:self forKeyPath:@"contentOffset"];
        
        if (_autoFillContent) {
            [tabScrollView removeObserver:self forKeyPath:@"contentSize"];
        }
    }
}


@end
