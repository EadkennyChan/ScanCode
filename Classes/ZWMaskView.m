//
//  MaskView.m
//  CodeScannerLib
//
//  Created by EadkennyChan on 16/5/13.
//  Copyright © 2016年 EadkennyChan. All rights reserved.
//

#import "ZWMaskView.h"
@interface ZWMaskView()
{
    UIView *m_viewMaskTop;
    UIView *m_viewMaskBottom;
    UIView *m_viewMaskLeft;
    UIView *m_viewMaskRight;
}
@end

@implementation ZWMaskView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _colorMask = [UIColor blackColor];
        _fMaskAlpha = 0.5;
        [self initSubview];
    }
    return self;
}

- (void)initSubview
{
    UIView *view = [[UIView alloc] init];
    [self addSubview:view];
    m_viewMaskTop = view;
    view = [[UIView alloc] init];
    [self addSubview:view];
    m_viewMaskBottom = view;
    view = [[UIView alloc] init];
    [self addSubview:view];
    m_viewMaskLeft = view;
    view = [[UIView alloc] init];
    [self addSubview:view];
    m_viewMaskRight = view;
    for (UIView *subview in self.subviews)
    {
        subview.backgroundColor = _colorMask;
        subview.alpha = _fMaskAlpha;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect frame = self.bounds;
    frame.size.height = _rectNonMask.origin.y;
    m_viewMaskTop.frame = frame;
    frame.size.width = _rectNonMask.origin.x;
    frame.origin.y += frame.size.height;
    frame.size.height = _rectNonMask.size.height;
    m_viewMaskLeft.frame = frame;
    frame.origin.x += (frame.size.width + _rectNonMask.size.width);
    frame.size.width = self.bounds.size.width - frame.origin.x;
    m_viewMaskRight.frame = frame;
    frame.origin.x = 0;
    frame.size.width = self.bounds.size.width;
    frame.origin.y += frame.size.height;
    frame.size.height = self.bounds.size.height - frame.origin.y;
    m_viewMaskBottom.frame = frame;
}

- (void)setRectNonMask:(CGRect)rectNonMask
{
    _rectNonMask = rectNonMask;
    [self setNeedsLayout];
}

- (void)setColorMask:(UIColor *)colorMask
{
    _colorMask = colorMask;
    for (UIView *subview in self.subviews)
    {
        subview.backgroundColor = _colorMask;
    }
}

- (void)setFMaskAlpha:(CGFloat)fMaskAlpha
{
    _fMaskAlpha = fMaskAlpha;
    for (UIView *subview in self.subviews)
    {
        subview.alpha = fMaskAlpha;
    }
}

@end