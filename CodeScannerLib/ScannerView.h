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

@property (nonatomic, retain, readonly)UIView *viewToptip;
@property (nonatomic, retain, readonly)ZWCornerView *viewScanFrame;
@property (nonatomic, retain, readonly)UIView *viewBottomtip;

@property (nonatomic, assign)CGFloat fExNavHeight;//导航栏和状态栏高度是否排除，值大于0则排除
@property (nonatomic, assign)CGFloat fToptipHeight;
@property (nonatomic, assign)CGSize sizeScanner;//default is (150,150).

@property (nonatomic, retain, readonly)ZWMaskView *viewMask;

@end