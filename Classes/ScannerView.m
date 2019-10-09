//
//  ScannerView.m
//  CodeScannerLib
//
//  Created by EadkennyChan on 16/7/19.
//  Copyright © 2016年 EadkennyChan. All rights reserved.
//

#import "ScannerView.h"
#import "ZWMaskView.h"

@interface ScannerView ()
{
    UIView *m_viewTopTip;
    ZWCornerView *m_viewScannerCenter;
    UIView *m_viewBottomTip;
    
    ZWMaskView *m_viewMask;
    
    UIView *m_viewLoading;//显示加载指示器
    UIActivityIndicatorView *m_indicatorView;
    NSTimer *m_timerIndicator;
}
@end

@implementation ScannerView

@synthesize viewToptipPan = m_viewTopTip;
@synthesize viewBottomTipPan = m_viewBottomTip;
@synthesize viewScanFrame = m_viewScannerCenter;
@synthesize viewMask = m_viewMask;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self initValues];
        UIView *viewActivity = [[UIView alloc] initWithFrame:self.bounds];
        viewActivity.backgroundColor = [UIColor blackColor];
        viewActivity.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        viewActivity.hidden = YES;
        [self addSubview:viewActivity];
        m_viewLoading = viewActivity;
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [viewActivity addSubview:indicator];
        m_indicatorView = indicator;
        
        ZWMaskView *viewMask = [[ZWMaskView alloc] initWithFrame:self.bounds];
        viewMask.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        viewMask.userInteractionEnabled = NO;
        [self addSubview:viewMask];
        m_viewMask = viewMask;
        
        UIView *view = [[UIView alloc] initWithFrame:self.bounds];
        [self addSubview:view];
        m_viewTopTip = view;
        ZWCornerView *viewCorner = [[ZWCornerView alloc] initWithFrame:self.bounds];
        viewCorner.userInteractionEnabled = NO;
        [self addSubview:viewCorner];
        m_viewScannerCenter = viewCorner;
        view = [[UIView alloc] initWithFrame:self.bounds];
        [self addSubview:view];
        m_viewBottomTip = view;
    }
    return self;
}

- (void)initValues
{
    _fToptipHeight = 0;
    _sizeScanner = CGSizeMake(150, 150);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frameBounds = self.bounds;    
    //计算导航栏和状态栏高度
    if (_fExNavHeight > 0)
    {
        frameBounds.origin.y += _fExNavHeight;
        frameBounds.size.height -= _fExNavHeight;
    }
    CGRect frame = frameBounds;
    if (_fToptipHeight > 0)
        frame.size.height = _fToptipHeight;
    else
        frame.size.height = (frameBounds.size.height - _sizeScanner.height) / 2;
    m_viewTopTip.frame = frame;
    frame.origin.y += frame.size.height;
    frame.size = _sizeScanner;
    frame.origin.x = (frameBounds.size.width - frame.size.width) / 2;
    m_viewScannerCenter.frame = frame;
    frame.origin.y += frame.size.height;
    frame.origin.x = 0;
    frame.size.width = frameBounds.size.width;
    frame.size.height = ceil(frameBounds.size.height - frame.origin.y);
    m_viewBottomTip.frame = frame;
    
    m_viewMask.rectNonMask = m_viewScannerCenter.frame;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *viewHit = [super hitTest:point withEvent:event];
    if (viewHit == self || viewHit == m_viewBottomTip || viewHit == m_viewTopTip)
        viewHit = nil;
    return viewHit;
}

#pragma mark - property

- (void)setFExNavHeight:(CGFloat)fExNavHeight
{
    if (_fExNavHeight == fExNavHeight)
        return;
    _fExNavHeight = fExNavHeight;
    [self setNeedsLayout];
}

- (void)setFToptipHeight:(CGFloat)fHeight
{
    if (_fToptipHeight == fHeight)
        return;
    _fToptipHeight = fHeight;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setSizeScanner:(CGSize)sizeScanner
{
    if (CGSizeEqualToSize(_sizeScanner, sizeScanner))
        return;
    _sizeScanner = sizeScanner;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - Method

- (BOOL)isLoadingAnimate
{
    return m_indicatorView.isAnimating;
}

- (void)startIndicatorAnimate
{
    if (m_viewLoading.hidden)
    {
        m_viewLoading.hidden = NO;
        [m_indicatorView startAnimating];
        
        [m_viewScannerCenter stopScanAnimate];
        
        [m_timerIndicator invalidate];
        m_timerIndicator = [NSTimer scheduledTimerWithTimeInterval:2.5 target:self selector:@selector(stopIndicatorAnimate) userInfo:nil repeats:NO];
    }
    CGPoint ptScanCenter = [m_viewScannerCenter.superview convertPoint:m_viewScannerCenter.center toView:m_viewLoading];
    m_indicatorView.center = ptScanCenter;
}

- (void)stopIndicatorAnimate
{
    [m_timerIndicator invalidate];
    m_timerIndicator = nil;
    
    __block UIView *view = m_viewLoading;
    if (view.hidden) return;
    __block UIActivityIndicatorView *indicatorView = m_indicatorView;
    [UIView animateWithDuration:0.25 animations:^{
        view.alpha = 0.0;
    } completion:^(BOOL finished) {
        view.hidden = YES;
        [indicatorView stopAnimating];
        view.alpha = 1.0;
    }];
}

@end
