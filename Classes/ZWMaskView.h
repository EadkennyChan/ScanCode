//
//  MaskView.h
//  CodeScannerLib
//
//  Created by EadkennyChan on 16/5/13.
//  Copyright © 2016年 EadkennyChan. All rights reserved.
//

#import <UIKit/UIKit.h>
/*
 *  中间透明，四周蒙蔽遮照
 *           _____________
 *          │             │
 *          │             │
 *          │             │
 *          │             │
 *          │             │
 *           ￣￣￣￣￣￣￣￣
 */
@interface ZWMaskView : UIView

@property (nonatomic, assign)CGRect rectNonMask;

@property (nonatomic, retain)UIColor *colorMask;//default is black color.
@property (nonatomic, assign)CGFloat fMaskAlpha;//default is 0.5.

@end