/*
     File: AVCamViewController.h
 Abstract: A view controller that coordinates the transfer of information between the user interface and the capture manager.
  Version: 2.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import <UIKit/UIKit.h>
#import "AVCamCaptureManager.h"

typedef NS_ENUM(NSInteger, CameraMode)
{
    CameraMode_Scan = 0,
    CameraMode_TakePhoto,
    CameraMode_TakePhotoSV
};

@protocol ZWScannerDelegate;
@class AVCamCaptureManager, AVCamPreviewView, AVCaptureVideoPreviewLayer;

@interface ZWScannerVC : UIViewController <UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property(nonatomic, weak)id<ZWScannerDelegate> delegateCamera;

@property(nonatomic, retain, readonly)UIView *viewTopTipPan;
@property (nonatomic, assign)CGFloat fTopHeight;
@property(nonatomic, retain, readonly)UIView *viewBottomTipPan;
@property (nonatomic, assign)CGSize sizeScanner;//default is (150,150).
- (UILabel *)defaultTopLabelTipWithFont:(CGFloat)fontSize;
- (UILabel *)defaultBottomLabelTip;
@property(nonatomic, retain)UILabel *labelTipMsg;
@property(nonatomic, retain)UILabel *labelBottomTip;
- (void)hiddenControls:(BOOL)bHidden;

- (void)changeMetaObjectType:(NSArray *)metadataObjectTypes;
@property (nonatomic, assign)CameraMode nCameraMode;//default is CameraMode_Scan.
- (void)setVideoZoom:(CGFloat)fZoomFactor canManual:(BOOL)bManual;
@property (nonatomic, assign)NSTimeInterval intervalScan;//辨认同一个码的时间间隔， default is 3s.

//导航栏
@property (nonatomic, assign)BOOL bTranslucentNav;//default is YES.
- (UIBarButtonItem *)addLightSettingBtn:(UINavigationItem *)navItem atRight:(BOOL)bRight;
- (void)removeLightBtn;

#pragma mark Actions
- (IBAction)captureStillImage:(id)sender;
- (IBAction)toggleCamera:(id)sender;

//获取截取图片的矩形
- (CGRect)cutoutRect:(UIImage *)imageOrgin;

- (void)startScan;
- (void)stopScan;

@end

#pragma mark -
@protocol ZWScannerDelegate <NSObject>

- (void)qrScanner:(ZWScannerVC *)scanner didOutputValue:(NSString *)strValue;
@optional
- (void)qrScanner:(ZWScannerVC *)scanner didOutputImage:(NSData *)dataImage;
- (void)qrScanner:(ZWScannerVC *)scanner didFailWithError:(NSError *)error;

@end
