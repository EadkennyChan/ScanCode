//
//  CornerView.m
//  TestBarcode
//
//  Created by chenpeng on 16/5/10.
//  Copyright © 2016年 chenzw. All rights reserved.
//

#import "ZWCornerView.h"
/*
 *  @description: 两头颜色宽度与中间部分不同的边
 *
 *   ________________
 *   ˉˉˉ          ˉˉˉ
 *
 */
typedef NS_ENUM(NSInteger, EdgeViewType)//边类型
{
    EdgeViewType_Top = 0,
    EdgeViewType_Right,
    EdgeViewType_Bottom,
    EdgeViewType_Left
};

@interface ZWPoleEdgeView : UIView
{
    UIView *m_viewLeftPole;
    UIView *m_viewTrunk;
    UIView *m_viewRightPole;
}
@property (nonatomic, retain)UIColor *colorPole;
@property (nonatomic, assign)CGFloat fWidthPole; //default is 25.
@property (nonatomic, retain)UIColor *colorTrunk;
@property (nonatomic, assign)CGFloat fHeightTrunk;//default is 1.
@property (nonatomic, assign)EdgeViewType edgeType;//垂直线标志
@end

@implementation ZWPoleEdgeView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self initValues];
        [self initSubviews];
    }
    return self;
}

- (void)initValues
{
    _fWidthPole = 25.0;
    _fHeightTrunk = 1.0;
    _colorPole = [UIColor colorWithRed:3.0/255 green:169.0/255 blue:244.0/255 alpha:1];
//    _szCornerEdge = CGSizeMake(3, 25);
    
    _colorTrunk = [UIColor colorWithRed:132.0/255 green:133.0/255 blue:134.0/255 alpha:1];
//    _fBorderWidth = 1.0;
}

- (void)initSubviews
{
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = _colorPole;
    [self addSubview:view];
    m_viewLeftPole = view;
    view = [[UIView alloc] init];
    view.backgroundColor = _colorTrunk;
    [self addSubview:view];
    m_viewTrunk = view;
    view = [[UIView alloc] init];
    view.backgroundColor = _colorPole;
    [self addSubview:view];
    m_viewRightPole = view;
}

#pragma mark - property

- (void)setColorPole:(UIColor *)colorPole
{
    _colorPole = colorPole;
    m_viewLeftPole.backgroundColor = colorPole;
    m_viewRightPole.backgroundColor = colorPole;
}

- (void)setColorTrunk:(UIColor *)colorTrunk
{
    _colorTrunk = colorTrunk;
    m_viewTrunk.backgroundColor = colorTrunk;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect frame = self.bounds;
    if (_edgeType == EdgeViewType_Right || _edgeType == EdgeViewType_Left)
    {
        frame.size.height = _fWidthPole;
        m_viewLeftPole.frame = frame;
        frame.origin.y = self.bounds.size.height - frame.size.height;
        m_viewRightPole.frame = frame;
        
        frame = CGRectInset(self.bounds, 0, _fWidthPole);
        frame.size.width = _fHeightTrunk;
        if (_edgeType == EdgeViewType_Right)
        {
            frame.origin.x = self.bounds.size.width - frame.size.width;
        }
        m_viewTrunk.frame = frame;
    }
    else
    {
        frame.size.width = _fWidthPole;
        m_viewLeftPole.frame = frame;
        frame.origin.x = self.bounds.size.width - frame.size.width;
        m_viewRightPole.frame = frame;
        
        frame = CGRectInset(self.bounds, _fWidthPole, 0);
        frame.size.height = _fHeightTrunk;
        if (_edgeType == EdgeViewType_Bottom)
        {
            frame.origin.y = self.bounds.size.height - frame.size.height;
        }
        m_viewTrunk.frame = frame;
    }
}

@end

#pragma mark -

@interface ZWCornerView ()
{
    ZWPoleEdgeView *m_edgeViewTop;
    ZWPoleEdgeView *m_edgeViewRight;
    ZWPoleEdgeView *m_edgeViewBottom;
    ZWPoleEdgeView *m_edgeViewLeft;
    //扫描线
    UIView *m_viewScanLine;
    CAGradientLayer *m_layerGradientScanLine;
}
@end

@implementation ZWCornerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self initValues];
        [self initSubviews];
    }
    return self;
}

- (void)initValues
{
    _szCornerEdge = CGSizeMake(3, 25);
    
    _fBorderWidth = 1.0;
}

- (void)initSubviews
{
    /*
    NSMutableArray *mtArrayCorner = [NSMutableArray arrayWithCapacity:8];
    CGSize szCornerVertical = CGSizeMake(3, 25);
    CGRect frameCorner = CGRectZero;
    //左上角
    frameCorner.size = szCornerVertical;
    UIView *view = [[UIView alloc] initWithFrame:frameCorner];
    view.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    view.backgroundColor = _colorCornerLine;
    [self addSubview:view];
    [mtArrayCorner addObject:view];
    frameCorner.size.width = szCornerVertical.height;
    frameCorner.size.height = szCornerVertical.width;
    view = [[UIView alloc] initWithFrame:frameCorner];
    view.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    view.backgroundColor = _colorCornerLine;
    [self addSubview:view];
    [mtArrayCorner addObject:view];
    //右上角
    frameCorner.origin.x = self.bounds.size.width - frameCorner.size.width;
    view = [[UIView alloc] initWithFrame:frameCorner];
    view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    view.backgroundColor = _colorCornerLine;
    [self addSubview:view];
    [mtArrayCorner addObject:view];
    frameCorner.size = szCornerVertical;
    frameCorner.origin.x = self.bounds.size.width - frameCorner.size.width;
    view = [[UIView alloc] initWithFrame:frameCorner];
    view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    view.backgroundColor = _colorCornerLine;
    [self addSubview:view];
    [mtArrayCorner addObject:view];
    //右下角
    frameCorner.origin.y = self.bounds.size.height - frameCorner.size.height;
    view = [[UIView alloc] initWithFrame:frameCorner];
    view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin| UIViewAutoresizingFlexibleTopMargin;
    view.backgroundColor = _colorCornerLine;
    [self addSubview:view];
    [mtArrayCorner addObject:view];
    frameCorner.size.width = szCornerVertical.height;
    frameCorner.size.height = szCornerVertical.width;
    frameCorner.origin.y = self.bounds.size.height - frameCorner.size.height;
    frameCorner.origin.x = self.bounds.size.width - frameCorner.size.width;
    view = [[UIView alloc] initWithFrame:frameCorner];
    view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin| UIViewAutoresizingFlexibleTopMargin;
    view.backgroundColor = _colorCornerLine;
    [self addSubview:view];
    [mtArrayCorner addObject:view];
    //左下角
    frameCorner.origin.x = 0;
    view = [[UIView alloc] initWithFrame:frameCorner];
    view.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    view.backgroundColor = _colorCornerLine;
    [self addSubview:view];
    [mtArrayCorner addObject:view];
    frameCorner.size = szCornerVertical;
    frameCorner.origin.y = self.bounds.size.height - frameCorner.size.height;
    view = [[UIView alloc] initWithFrame:frameCorner];
    view.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    view.backgroundColor = _colorCornerLine;
    [self addSubview:view];
    [mtArrayCorner addObject:view];
    m_arrayCorner = [mtArrayCorner copy];*/
    //中间分隔线
    CGRect frame = self.bounds;
    frame.size.height = _szCornerEdge.width;
    ZWPoleEdgeView *edgeView = [[ZWPoleEdgeView alloc] initWithFrame:frame];
    edgeView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addSubview:edgeView];
    m_edgeViewTop = edgeView;
    
    frame = self.bounds;
    frame.size.width = _szCornerEdge.width;
    frame.origin.x = self.bounds.size.width - frame.size.width;
    edgeView = [[ZWPoleEdgeView alloc] initWithFrame:frame];
    edgeView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
    edgeView.edgeType = EdgeViewType_Right;
    [self addSubview:edgeView];
    m_edgeViewRight = edgeView;
    
    frame = self.bounds;
    frame.size.height = _szCornerEdge.width;
    frame.origin.y = self.bounds.size.height - frame.size.height;
    edgeView = [[ZWPoleEdgeView alloc] initWithFrame:frame];
    edgeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    edgeView.edgeType = EdgeViewType_Bottom;
    [self addSubview:edgeView];
    m_edgeViewBottom = edgeView;
    
    frame = self.bounds;
    frame.size.width = _szCornerEdge.width;
    edgeView = [[ZWPoleEdgeView alloc] initWithFrame:frame];
    edgeView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    edgeView.edgeType = EdgeViewType_Left;
    [self addSubview:edgeView];
    m_edgeViewLeft = edgeView;
}

#pragma mark - property

- (void)setColorCornerLine:(UIColor *)color
{
    m_edgeViewTop.colorPole = color;
    m_edgeViewRight.colorPole = color;
    m_edgeViewBottom.colorPole = color;
    m_edgeViewRight.colorPole = color;
}

- (UIColor *)colorCornerLine
{
    return m_edgeViewLeft.colorPole;
}

- (void)setSzCornerEdge:(CGSize)szCornerEdge
{
    _szCornerEdge = szCornerEdge;
}

- (void)setColorMainBorder:(UIColor *)color
{
    m_edgeViewTop.colorTrunk = color;
    m_edgeViewRight.colorTrunk = color;
    m_edgeViewBottom.colorTrunk = color;
    m_edgeViewRight.colorTrunk = color;
}

- (UIColor *)colorMainBorder
{
    return m_edgeViewTop.colorTrunk;
}

- (void)setFBorderWidth:(CGFloat)fBorderWidth
{
    _fBorderWidth = fBorderWidth;
}

#pragma mark

- (void)layoutSubviews
{
    [super layoutSubviews];
    if ([self isScanAnimating])
    {
        [self startScanAnimate];
    }
}

#pragma mark - Method

#pragma mark 扫描线
- (BOOL)isScanAnimating
{
    return [[m_viewScanLine.layer animationKeys] count] > 0;
}

- (void)startScanAnimate
{
    [m_viewScanLine.layer removeAllAnimations];
    [self addSubview:m_viewScanLine];
    
    CGRect frame = self.bounds;
    frame.size.height = 2.0;
    if (m_viewScanLine == nil)
    {
        UIImage *image = [UIImage imageNamed:@"CodeScanner.bundle/scannerLine"];
        if (image == nil)
        {
            NSString *strPath = [[NSBundle mainBundle] pathForResource:@"CodeScannerLib.framework" ofType:nil];
            image = [UIImage imageNamed:[strPath stringByAppendingString:@"scannerLine.png"]];
        }
        if (image)
        {
            UIImageView *imgV = [[UIImageView alloc] initWithFrame:frame];
            imgV.image = image;
            [self addSubview:imgV];
            m_viewScanLine = imgV;
        }
        else
        {
            UIView *view = [[UIView alloc] initWithFrame:frame];
            view.backgroundColor = [UIColor clearColor];
            [self addSubview:view];
            m_viewScanLine = view;
            
            CAGradientLayer *layerGradient = [CAGradientLayer layer];  // 设置渐变效果
            layerGradient.borderWidth = 0;
            layerGradient.frame = view.bounds;
            layerGradient.colors = @[(id)[[UIColor whiteColor] CGColor],
                                     (id)[self.colorCornerLine CGColor],
                                     (id)[[UIColor whiteColor] CGColor]];
            layerGradient.startPoint = CGPointMake(0.1, 0);
            layerGradient.endPoint = CGPointMake(0.9, 0);
            [view.layer insertSublayer:layerGradient atIndex:0];
            m_layerGradientScanLine = layerGradient;
        }
    }
    else
    {
        m_viewScanLine.frame = frame;
    }
    
    __block UIView *view = m_viewScanLine;
    CGRect frameBounds = self.bounds;
    [UIView animateWithDuration:2.5 delay:0.0
                        options:UIViewAnimationOptionRepeat
                     animations:^{
                         CGRect frameDest = frameBounds;
                         frameDest.size.height = 2.0;
                         frameDest.origin.y = frameBounds.size.height - frameDest.size.height;
                         view.frame = frameDest;
                     }
                     completion:nil];
}

- (void)stopScanAnimate
{
    [m_viewScanLine removeFromSuperview];
    [m_viewScanLine.layer removeAllAnimations];
}

@end
