//
//  ScannerView.h
//  CodeScannerLib
//
//  Created by EadkennyChan on 16/7/19.
//  Copyright © 2016年 EadkennyChan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZWCornerView.h"
#import "ZWMaskView.h"

@interface ScannerView : UIView

@property (nonatomic, retain, readonly)UIView *viewToptipPan;
@property (nonatomic, retain, readonly)ZWCornerView *viewScanFrame;
@property (nonatomic, retain, readonly)UIView *viewBottomTipPan;

@property (nonatomic, retain, readonly)ZWMaskView *viewMask;

@property (nonatomic, assign)CGFloat fExNavHeight;//导航栏和状态栏高度是否排除，值大于0则排除
@property (nonatomic, assign)CGFloat fToptipHeight;
@property (nonatomic, assign)CGSize sizeScanner;//default is (150,150).

- (BOOL)isLoadingAnimate;
- (void)startIndicatorAnimate;
- (void)stopIndicatorAnimate;

@end
