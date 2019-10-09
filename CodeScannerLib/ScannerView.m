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
}
@end

@implementation ScannerView

@synthesize viewToptip = m_viewTopTip;
@synthesize viewBottomtip = m_viewBottomTip;
@synthesize viewScanFrame = m_viewScannerCenter;
@synthesize viewMask = m_viewMask;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self initValues];
        
        ZWMaskView *viewMask = [[ZWMaskView alloc] initWithFrame:self.bounds];
        viewMask.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        viewMask.userInteractionEnabled = NO;
        [self addSubview:viewMask];
        m_viewMask = viewMask;
        
        UIView *view = [[UIView alloc] init];
        [self addSubview:view];
        m_viewTopTip = view;
        ZWCornerView *viewCorner = [[ZWCornerView alloc] init];
        [self addSubview:viewCorner];
        m_viewScannerCenter = viewCorner;
        view = [[UIView alloc] init];
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
    frame.size.height = frameBounds.size.height - frame.origin.y;
    m_viewBottomTip.frame = frame;
    
    m_viewMask.rectNonMask = m_viewScannerCenter.frame;
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
}

- (void)setSizeScanner:(CGSize)sizeScanner
{
    if (CGSizeEqualToSize(_sizeScanner, sizeScanner))
        return;
    _sizeScanner = sizeScanner;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

@end