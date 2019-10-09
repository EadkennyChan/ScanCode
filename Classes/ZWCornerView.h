//
//  CornerView.h
//  TestBarcode
//
//  Created by chenpeng on 16/5/10.
//  Copyright © 2016年 chenzw. All rights reserved.
//

#import <UIKit/UIKit.h>
/*
 *  @description: 如下示意图，四角为设定颜色
 *           __         __
 *          │             │
 *
 *
 *
 *          │             │
 *           ￣          ￣
 */

@interface ZWCornerView : UIView

@property (nonatomic, retain)UIColor *colorMainBorder;//边框颜色    默认(132,133,134)
@property (nonatomic, assign)CGFloat fBorderWidth;//边框宽度 默认1.0

@property (nonatomic, retain)UIColor *colorCornerLine;//四角颜色    默认(3,169,244)
@property (nonatomic, assign)CGSize szCornerEdge;//四角的一条边的宽高 默认(3,25)

#pragma mark - 扫描线
- (BOOL)isScanAnimating;
- (void)startScanAnimate;
- (void)stopScanAnimate;

@end
