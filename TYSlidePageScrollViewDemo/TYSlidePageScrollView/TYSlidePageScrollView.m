//
//  TYSlidePageScrollView.m
//  TYSlidePageScrollViewDemo
//
//  Created by tanyang on 15/7/16.
//  Copyright (c) 2015年 tanyang. All rights reserved.
//

#import "TYSlidePageScrollView.h"

@interface TYSlidePageScrollView ()<UIScrollViewDelegate>
@property (nonatomic, weak) UIScrollView    *horScrollView;     // horizen scroll View
@property (nonatomic, weak) UIView          *headerContentView; // contain header and pageTab

@property (nonatomic, strong) NSArray       *pageViewArray;

@end

@implementation TYSlidePageScrollView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        [self setPropertys];
        
        [self addHorScrollView];
        
        [self addHeaderContentView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self setPropertys];
        
        [self addHorScrollView];
        
        [self addHeaderContentView];
    }
    return self;
}

#pragma mark - setter getter

- (void)setPropertys
{
    _curPageIndex = 0;
}

- (void)resetPropertys
{
    [self addPageViewKeyPathWithOldIndex:_curPageIndex newIndex:-1];
    _curPageIndex = 0;
    [_headerContentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_footerView removeFromSuperview];
    [_pageViewArray makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _pageViewArray = nil;
}

#pragma mark - add subView

- (void)addHorScrollView
{
    UIScrollView *scrollView = [[UIScrollView alloc]init];
    scrollView.backgroundColor = [UIColor whiteColor];
    scrollView.delegate = self;
    scrollView.pagingEnabled = YES;
    [self addSubview:scrollView];
    _horScrollView = scrollView;
}

- (void)addHeaderContentView
{
    UIView *headerContentView = [[UIView alloc]init];
    [self addSubview:headerContentView];
    _headerContentView = headerContentView;
}

#pragma mark - private method

- (void)updateHeaderContentView
{
    CGFloat viewWidth = CGRectGetWidth(self.frame);
    CGFloat headerContentViewHieght = 0;
    
    if (_headerView) {
        _headerView.frame = CGRectMake(0, 0, viewWidth, CGRectGetHeight(_headerView.frame));
        [_headerContentView addSubview:_headerView];
        headerContentViewHieght += CGRectGetHeight(_headerView.frame);
    }
    
    if (_pageTabBar) {
        _pageTabBar.frame = CGRectMake(0, headerContentViewHieght, viewWidth, CGRectGetHeight(_pageTabBar.frame));
        [_headerContentView addSubview:_pageTabBar];
        headerContentViewHieght += CGRectGetHeight(_pageTabBar.frame);
    }
    
    _headerContentView.frame = CGRectMake(0, 0, viewWidth, headerContentViewHieght);
}

- (void)updateFooterView
{
    if (_footerView) {
        CGFloat footerViewY = CGRectGetHeight(self.frame)-CGRectGetHeight(_footerView.frame);
        _footerView.frame = CGRectMake(0, footerViewY, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
        [self addSubview:_footerView];
    }
}

- (void)updatePageViews
{
    _horScrollView.frame = self.bounds;
    
    CGFloat viewWidth = CGRectGetWidth(self.frame);
    CGFloat viewHight = CGRectGetHeight(self.frame);
    CGFloat headerContentViewHieght = CGRectGetHeight(_headerContentView.frame);
    CGFloat footerViewHieght = CGRectGetHeight(_footerView.frame);
    
    NSInteger pageNum = [_dataSource numberOfPageViewOnSlidePageScrollView];
    NSMutableArray *scrollViewArray = [NSMutableArray arrayWithCapacity:pageNum];
    for (NSInteger index = 0; index < pageNum; ++index) {
        UIScrollView *pageVerScrollView = [_dataSource slidePageScrollView:self pageVerticalScrollViewForIndex:index];
        pageVerScrollView.frame = CGRectMake(index * viewWidth, 0, viewWidth, viewHight);
        pageVerScrollView.contentInset = UIEdgeInsetsMake(headerContentViewHieght, 0, footerViewHieght, 0);
        pageVerScrollView.scrollIndicatorInsets = UIEdgeInsetsMake(headerContentViewHieght, 0, footerViewHieght, 0);
        [_horScrollView addSubview:pageVerScrollView];
        [scrollViewArray addObject:pageVerScrollView];
    }
    
    _pageViewArray = [scrollViewArray copy];
    _horScrollView.contentSize = CGSizeMake(viewWidth*pageNum, 0);
}

- (void)addPageViewKeyPathWithOldIndex:(NSInteger)oldIndex newIndex:(NSInteger)newIndex
{
    if (oldIndex == newIndex) {
        return;
    }
    
    if (oldIndex >= 0 && oldIndex < _pageViewArray.count) {
        [_pageViewArray[oldIndex] removeObserver:self forKeyPath:@"contentOffset" context:nil];
    }
    if (newIndex >= 0 && newIndex < _pageViewArray.count) {
        [_pageViewArray[newIndex] addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isKindOfClass:[UIScrollView class]]) {
        [self pageScrollViewDidScroll:object];
    }
}

- (void)changeAllPageScrollViewOffsetY:(CGFloat)offsetY
{
    [_pageViewArray enumerateObjectsUsingBlock:^(UIScrollView *pageScrollView, NSUInteger idx, BOOL *stop) {
        if (idx != _curPageIndex) {
            pageScrollView.contentOffset = CGPointMake(pageScrollView.contentOffset.x, offsetY);
        }
    }];
}

#pragma mark - public method

- (void)reloadData
{
    [self resetPropertys];
    
    [self updateHeaderContentView];
    
    [self updateFooterView];
    
    [self updatePageViews];
    
    [self addPageViewKeyPathWithOldIndex:-1 newIndex:_curPageIndex];
}

#pragma mark - delegate

// horizen scrollView
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSInteger index = (NSInteger)(scrollView.contentOffset.x/CGRectGetWidth(scrollView.frame) + 0.4);
    if (_curPageIndex != index) {
        [self addPageViewKeyPathWithOldIndex:_curPageIndex newIndex:index];
        _curPageIndex = index;
        NSLog(@"index %ld",_curPageIndex);
    }
}

// page scrollView
- (void)pageScrollViewDidScroll:(UIScrollView *)pageScrollView
{
    CGFloat viewWidth = CGRectGetWidth(self.frame);
    CGFloat viewHight = CGRectGetHeight(self.frame);
    CGFloat headerContentViewheight = CGRectGetHeight(_headerContentView.frame);
    CGFloat pageTabBarHieght = CGRectGetHeight(_pageTabBar.frame);
    
    if (pageScrollView.contentSize.height < viewHight - pageTabBarHieght) {
        pageScrollView.contentSize = CGSizeMake(pageScrollView.contentSize.width, viewHight - pageTabBarHieght);
    }
    
    CGFloat offsetY = pageScrollView.contentOffset.y;
    if (offsetY <= -headerContentViewheight) {
        CGRect frame = CGRectMake(0, 0, viewWidth, headerContentViewheight);
        if (!CGRectEqualToRect(_headerContentView.frame, frame)) {
            _headerContentView.frame = frame;
            [self changeAllPageScrollViewOffsetY:-headerContentViewheight];
        }
    }else if (offsetY < -pageTabBarHieght) {
        CGRect frame = CGRectMake(0, -(offsetY+headerContentViewheight), viewWidth, headerContentViewheight);
        _headerContentView.frame = frame;
        [self changeAllPageScrollViewOffsetY:pageScrollView.contentOffset.y];
        
    }else {
        CGRect frame = CGRectMake(0, -headerContentViewheight+pageTabBarHieght, viewWidth, headerContentViewheight);
        if (!CGRectEqualToRect(_headerContentView.frame, frame)) {
            _headerContentView.frame = frame;
            [self changeAllPageScrollViewOffsetY:-pageTabBarHieght];
        }
    }

}

@end
