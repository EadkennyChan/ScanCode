/*
     File: AVCamViewController.m
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

#import "ZWScannerVC.h"
#import "AVCamRecorder.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "AVCamPreviewView.h"
#import "ScannerView.h"

static void *AVCamFocusModeObserverContext = &AVCamFocusModeObserverContext;

@interface ZWScannerVC () <UIGestureRecognizerDelegate>
{
    ScannerView *m_scan;
    AVCamPreviewView *m_viewVideoPreview;
    AVCamCaptureManager *m_captureManager;
    
    CGFloat m_fZoomScale;//default is 1.6;镜头拉伸比例
    BOOL m_bCanManualAdjustZoom;//是否能够手动调整摄像头缩放比例
    
    //导航栏设置
    UIView *m_viewNavBkHidden;
    BOOL m_bTranslucentOld;
    UIBarStyle m_barStyleOld;
    UIStatusBarStyle m_statusBarSytleOld;
    
    UIBarButtonItem *m_barItemLight;
}
@end

@interface ZWScannerVC (InternalMethods)
- (void)pinchZoomCamera:(UIPinchGestureRecognizer *)pinch;
- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer;
- (void)tapToContinouslyAutoFocus:(UIGestureRecognizer *)gestureRecognizer;
- (void)adjustRectOfInterest;
@end

@interface ZWScannerVC (AVCamCaptureManagerDelegate) <AVCamCaptureManagerDelegate>
@end

@implementation ZWScannerVC

- (NSString *)stringForFocusMode:(AVCaptureFocusMode)focusMode
{
	NSString *focusString = @"";
	
	switch (focusMode) {
		case AVCaptureFocusModeLocked:
			focusString = @"locked";
			break;
		case AVCaptureFocusModeAutoFocus:
			focusString = @"auto";
			break;
		case AVCaptureFocusModeContinuousAutoFocus:
			focusString = @"continuous";
			break;
	}
	
	return focusString;
}

- (void)dealloc
{
    @try {
        [self removeObserver:self forKeyPath:@"m_captureManager.videoInput.device.focusMode"];
    } @catch (NSException *exception) {
    } @finally {        
    }
#ifdef DEBUG
    NSLog(@"ZWScannerVC dealloc");
#endif
}

- (id)init
{
    self = [super init];
    if (self)
    {
        m_fZoomScale = 1.6;
        _bTranslucentNav = YES;
        
        CGFloat fWidth = [UIScreen mainScreen].bounds.size.width;
        m_scan = [[ScannerView alloc] initWithFrame:CGRectMake(0, 0, fWidth, 100)];
        
        [self setupSession];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initSubviews];
//    if (_nCameraMode == CameraMode_Scan)
//        [m_captureManager setupScanCodeMode];
//    else
//        [m_captureManager setupStillImageMode];
    
    [self setupTranslucentNav];
    self.parentViewController.edgesForExtendedLayout = UIRectEdgeAll;
    self.edgesForExtendedLayout = UIRectEdgeAll;
    m_statusBarSytleOld = [UIApplication sharedApplication].statusBarStyle;
    
    // Start the session. This is done asychronously since -startRunning doesn't return until the session is running.
    [m_scan startIndicatorAnimate];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self adjustRectOfInterest];
        [[m_captureManager session] startRunning];
    });
}

- (void)initSubviews
{
    self.view.backgroundColor = [UIColor whiteColor];
    AVCamPreviewView *view = [[AVCamPreviewView alloc] initWithFrame:self.view.bounds];
    view.session = m_captureManager.session;
    m_viewVideoPreview = view;
    [self.view addSubview:view];
    [self setupPreviewVideo];
    
    ScannerView *scann = m_scan;
    scann.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scann.frame = self.view.bounds;
    [self.view addSubview:scann];
}

- (void)setupSession
{
    if (m_captureManager == nil)
    {
        AVCamCaptureManager *manager = [[AVCamCaptureManager alloc] init];
        [manager setDelegate:self];
        
        if ([manager setupSession])
        {
            m_captureManager = manager;
            
            // Create the focus mode UI overlay
            [self addObserver:self forKeyPath:@"m_captureManager.videoInput.device.focusMode" options:NSKeyValueObservingOptionNew context:AVCamFocusModeObserverContext];
            [self setupPreviewVideo];
            
            AVCaptureDevice *captureDevice = m_captureManager.videoInput.device;
            if (m_fZoomScale < 1.0)
                m_fZoomScale = 1.0;
            else if (m_fZoomScale > captureDevice.activeFormat.videoMaxZoomFactor)
                m_fZoomScale = captureDevice.activeFormat.videoMaxZoomFactor;
        }
    }
    AVCaptureDevice *captureDevice = m_captureManager.videoInput.device;
    NSError *error;
    if ([captureDevice lockForConfiguration:&error])
    {
        captureDevice.videoZoomFactor = m_fZoomScale;
        [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        [captureDevice unlockForConfiguration];
    }
    if (_nCameraMode == CameraMode_Scan)
        [self adjustRectOfInterest];
}

- (void)setupPreviewVideo
{
    AVCamPreviewView *viewPreview = m_viewVideoPreview;
    if (viewPreview == nil) return;
    // Create video preview layer and add it to the UI
    [viewPreview setSession:[m_captureManager session]];
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchZoomCamera:)];
    [viewPreview addGestureRecognizer:pinch];
    m_bCanManualAdjustZoom = YES;
    
    // Add a single tap gesture to focus on the point tapped, then lock focus
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToAutoFocus:)];
    [singleTap setDelegate:self];
    [singleTap setNumberOfTapsRequired:1];
    [viewPreview addGestureRecognizer:singleTap];
    
    // Add a double tap gesture to reset the focus mode to continuous auto focus
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToContinouslyAutoFocus:)];
    [doubleTap setDelegate:self];
    [doubleTap setNumberOfTapsRequired:2];
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [viewPreview addGestureRecognizer:doubleTap];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [m_captureManager.session startRunning];
    if (_nCameraMode == CameraMode_Scan && ![m_scan isLoadingAnimate] && m_captureManager.session)
        [m_scan.viewScanFrame startScanAnimate];
    
    m_viewNavBkHidden.hidden = _bTranslucentNav;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [self tapToAutoFocus:nil];
    [super viewDidAppear:animated];
    
    __weak UIView *viewNavBk = m_viewNavBkHidden;
    dispatch_async(dispatch_get_main_queue(), ^{
        viewNavBk.hidden = _bTranslucentNav;
    });
    m_viewNavBkHidden.hidden = _bTranslucentNav;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    AVCaptureDevice *captureDevice = m_captureManager.videoInput.device;
    UIButton *btn = (UIButton *)m_barItemLight.customView;
    if (captureDevice && btn)
    {
        btn.selected = captureDevice.torchMode == AVCaptureTorchModeOn;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    m_viewNavBkHidden.hidden = NO;
    self.navigationController.navigationBar.translucent = m_bTranslucentOld;
    self.navigationController.navigationBar.barStyle = m_barStyleOld;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [m_scan startIndicatorAnimate];
    [m_captureManager.session stopRunning];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (_bTranslucentNav)
        return UIStatusBarStyleLightContent;
    else
        return m_statusBarSytleOld;
}

- (void)setupTranslucentNav
{
    m_barStyleOld = self.navigationController.navigationBar.barStyle;
    m_bTranslucentOld = self.navigationController.navigationBar.translucent;
    for (UIView *subview in self.navigationController.navigationBar.subviews)
    {
        NSString *strClassName = NSStringFromClass(subview.class);
        NSRange range = [strClassName rangeOfString:@"BarBackground"];
        if (range.location != NSNotFound)
        {
            subview.hidden = _bTranslucentNav;
            m_viewNavBkHidden = subview;
            break;
        }
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == AVCamFocusModeObserverContext)
    {
        AVCaptureDevice *deviceCapture = m_captureManager.videoInput.device;
        if (![deviceCapture isAdjustingFocus])
        {
            __block ScannerView *scan = m_scan;
            dispatch_async(dispatch_get_main_queue(), ^{
                [scan stopIndicatorAnimate];
                if (_nCameraMode != CameraMode_Scan && [m_scan.viewScanFrame isScanAnimating])
                {
                    [m_scan.viewScanFrame stopScanAnimate];
                }
                else if (_nCameraMode == CameraMode_Scan && ![m_scan.viewScanFrame isScanAnimating])
                {
                    [m_scan.viewScanFrame startScanAnimate];
                }
            });
        }
	}
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)appDidBecomeActive
{
    if ([m_captureManager.session isRunning])
    {
        if (_nCameraMode == CameraMode_Scan)
            [m_scan.viewScanFrame startScanAnimate];
    }
    
    AVCaptureDevice *captureDevice = m_captureManager.videoInput.device;
    UIButton *btn = (UIButton *)m_barItemLight.customView;
    btn.selected = captureDevice.torchMode == AVCaptureTorchModeOn;
}

- (void)appDidEnterBackground
{
    [m_scan.viewScanFrame stopScanAnimate];
}

#pragma mark - Tip View

- (UIView *)viewTopTipPan
{
    return m_scan.viewToptipPan;
}

- (void)setFTopHeight:(CGFloat)fTopHeight
{
    m_scan.fToptipHeight = fTopHeight;
    if (_nCameraMode == CameraMode_Scan)
        [self adjustRectOfInterest];
}
- (CGFloat)fTopHeight
{
    return m_scan.fToptipHeight;
}

- (UIView *)viewBottomTipPan
{
    return m_scan.viewBottomTipPan;
}

- (void)setSizeScanner:(CGSize)sizeScanner
{
    m_scan.sizeScanner = sizeScanner;
    if (_nCameraMode == CameraMode_Scan)
        [self adjustRectOfInterest];
}

- (CGSize)sizeScanner
{
    return m_scan.sizeScanner;
}

- (void)setBTranslucentNav:(BOOL)bTransparentNav
{
    _bTranslucentNav = bTransparentNav;
    m_viewNavBkHidden.hidden = bTransparentNav;
    if (bTransparentNav)
    {
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
        self.navigationController.navigationBar.translucent = YES;
    }
    else
    {
        self.navigationController.navigationBar.translucent = m_bTranslucentOld;
        self.navigationController.navigationBar.barStyle = m_barStyleOld;
    }
    if ([self isViewLoaded])
        [self.view setNeedsLayout];
}

- (void)changeMetaObjectType:(NSArray *)metadataObjectTypes
{
    if (metadataObjectTypes == nil)
        metadataObjectTypes = m_captureManager.metadataOutput.availableMetadataObjectTypes;
    NSArray *arrayOldTypes = m_captureManager.metadataOutput.metadataObjectTypes;
    BOOL bHasChanged = NO;
    if (metadataObjectTypes.count != arrayOldTypes.count)
        bHasChanged = YES;
    else
    {
        NSInteger nIndex = 0;
        NSString *strTypeOld;
        BOOL bContainType = NO;
        for (NSString *strType in metadataObjectTypes)
        {
            strTypeOld = arrayOldTypes[nIndex];
            if (![strType isEqualToString:strTypeOld])
            {
                for (strTypeOld in arrayOldTypes)
                {
                    if ([strType isEqualToString:strTypeOld])
                    {
                        bContainType = YES;
                        break;
                    }
                }
                if (!bContainType)
                {
                    bHasChanged = YES;
                    break;
                }
            }
            nIndex++;
        }
    }
    if (bHasChanged)
    {
        [m_scan startIndicatorAnimate];
        __block AVCaptureMetadataOutput *outputMeta = m_captureManager.metadataOutput;
        __block ZWScannerVC *selfBlock = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            outputMeta.metadataObjectTypes = metadataObjectTypes;
            [selfBlock tapToContinouslyAutoFocus:nil];
        });
    }
}

- (void)setNCameraMode:(CameraMode)nCameraMode
{
    _nCameraMode = nCameraMode;
    [m_scan startIndicatorAnimate];
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (_nCameraMode)
        {
            case CameraMode_TakePhoto:
            case CameraMode_TakePhotoSV:
            {
                [m_scan.viewScanFrame stopScanAnimate];
//                [m_captureManager setupStillImageMode];
            }
                break;
            default:
//                [m_captureManager setupScanCodeMode];
                break;
        }
    });
}

- (void)setIntervalScan:(NSTimeInterval)intervalScan
{
    m_captureManager.intervalScan = intervalScan;
}

- (void)setVideoZoom:(CGFloat)fZoomFactor canManual:(BOOL)bManual
{
    AVCaptureDevice *captureDevice = m_captureManager.videoInput.device;
    if (fZoomFactor < 1.0)
        fZoomFactor = 1.0;
    else if (fZoomFactor > captureDevice.activeFormat.videoMaxZoomFactor)
        fZoomFactor = captureDevice.activeFormat.videoMaxZoomFactor;
    NSError *error;
    if ([captureDevice lockForConfiguration:&error])
    {
        captureDevice.videoZoomFactor = fZoomFactor;
        [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        [captureDevice unlockForConfiguration];
        m_fZoomScale = fZoomFactor;
    }
    m_bCanManualAdjustZoom = bManual;
}

- (UILabel *)defaultTopLabelTipWithFont:(CGFloat)fontSize
{
    UIView *viewTopPan = m_scan.viewToptipPan;
    
    CGRect frame = CGRectInset(viewTopPan.bounds, 30, 0);
    frame.size.height = fontSize;
    frame.origin.y = viewTopPan.bounds.size.height - frame.size.height - 12;
    UILabel *lTopTip = [[UILabel alloc] initWithFrame:frame];
    lTopTip.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    lTopTip.textAlignment = NSTextAlignmentCenter;
    lTopTip.font = [UIFont systemFontOfSize:fontSize];
    lTopTip.textColor = [UIColor whiteColor];
    [viewTopPan addSubview:lTopTip];
    return lTopTip;
}

- (UILabel *)defaultBottomLabelTip
{
    UIView *viewBottomPan = m_scan.viewBottomTipPan;
    
    CGRect frame = CGRectInset(viewBottomPan.bounds, 30, 0);
    frame.size.height = 12;
    frame.origin.y = 12;
    UILabel *lBottomTip = [[UILabel alloc] initWithFrame:frame];
    lBottomTip.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    lBottomTip.textAlignment = NSTextAlignmentCenter;
    lBottomTip.font = [UIFont systemFontOfSize:12];
    lBottomTip.textColor = [UIColor colorWithRed:228/225.0 green:228/225.0 blue:228/225.0 alpha:1];
    [viewBottomPan addSubview:lBottomTip];
    return lBottomTip;
}

- (void)hiddenControls:(BOOL)bHidden
{
    __block ScannerView *scan = m_scan;
    if (!bHidden)
        scan.hidden = bHidden;
    [UIView animateWithDuration:0.3 animations:^{
        scan.alpha = bHidden ? 0 : 1;
    } completion:^(BOOL finished) {
        scan.hidden = bHidden;
    }];
}

#pragma mark Actions

- (IBAction)toggleCamera:(id)sender
{
    // Toggle between cameras when there is more than one
    [m_captureManager toggleCamera];
    
    // Do an initial focus
    [m_captureManager continuousFocusAtPoint:CGPointMake(.5f, .5f)];
}

- (IBAction)captureStillImage:(id)sender
{
    // Capture a still image
    if ([sender isKindOfClass:[UIControl class]])
    {
        ((UIControl *)sender).enabled = NO;
    }
    [m_captureManager captureStillImage];
    
    // Flash the screen white and fade it out to give UI feedback that a still image was taken
    UIView *flashView = [[UIView alloc] initWithFrame:[m_viewVideoPreview frame]];
    [flashView setBackgroundColor:[UIColor whiteColor]];
    [[[self view] window] addSubview:flashView];
    
    [UIView animateWithDuration:.4f animations:^{[flashView setAlpha:0.f];}completion:^(BOOL finished){[flashView removeFromSuperview];}];
}

- (UIBarButtonItem *)addLightSettingBtn:(UINavigationItem *)navItem atRight:(BOOL)bRight
{
    if (m_barItemLight == nil)
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *imageOpen = [UIImage imageNamed:@"CodeScanner.bundle/icon-lightOpen"];
        UIImage *imageClose = [UIImage imageNamed:@"CodeScanner.bundle/icon-lightClose"];
        CGRect frame = CGRectZero;
        if (imageOpen == nil || imageClose == nil)
        {
            [btn setTitle:@"开灯" forState:UIControlStateNormal];
            [btn setTitle:@"关灯" forState:UIControlStateSelected];
            frame.size = CGSizeMake(40, 22);
        }
        else
        {
            [btn setImage:imageOpen forState:UIControlStateNormal];
            [btn setImage:imageClose forState:UIControlStateSelected];
            frame.size = imageOpen.size;
        }
        [btn addTarget:self action:@selector(btnClickedTurnOnLight:) forControlEvents:UIControlEventTouchUpInside];
        btn.frame = frame;
        UIBarButtonItem *itemLightBtn = [[UIBarButtonItem alloc] initWithCustomView:btn];
        m_barItemLight = itemLightBtn;
    }
    UINavigationItem *navItemTmp = navItem != nil ? navItem : self.navigationItem;
    if (bRight)
    {
        NSMutableArray *mtArray = [NSMutableArray arrayWithArray:navItem.rightBarButtonItems];
        [mtArray addObject:m_barItemLight];
        navItemTmp.rightBarButtonItems = mtArray;
    }
    else
    {
        NSMutableArray *mtArray = [NSMutableArray arrayWithArray:navItem.leftBarButtonItems];
        [mtArray addObject:m_barItemLight];
        navItemTmp.leftBarButtonItems = mtArray;
    }
    return m_barItemLight;
}

- (void)removeLightBtn
{
    NSMutableArray *mtArray = [NSMutableArray arrayWithArray:self.navigationItem.leftBarButtonItems];
    [mtArray removeObject:m_barItemLight];
    self.navigationItem.leftBarButtonItems = mtArray;
}

- (void)btnClickedTurnOnLight:(UIButton *)btn
{
    AVCaptureDevice *captureDevice = m_captureManager.videoInput.device;
    if ([captureDevice hasTorch] && [captureDevice hasFlash])
    {
        [captureDevice lockForConfiguration:nil];
        if (captureDevice.torchMode == AVCaptureTorchModeOff)
        {
            [captureDevice setTorchMode:AVCaptureTorchModeOn];
            [captureDevice setFlashMode:AVCaptureFlashModeOn];
            btn.selected = YES;
        }
        else
        {
            [captureDevice setTorchMode:AVCaptureTorchModeOff];
            [captureDevice setFlashMode:AVCaptureFlashModeOff];
            btn.selected = NO;
        }
        [captureDevice unlockForConfiguration];
    }
}

- (CGRect)cutoutRect:(UIImage *)imageOrgin
{
    CGFloat fScaleWidth = imageOrgin.size.width / self.view.bounds.size.width;
    CGFloat fScaleHeight = imageOrgin.size.height / self.view.bounds.size.height;
    if (fScaleWidth < fScaleHeight)
        fScaleWidth = fScaleHeight;
    CGRect rect;
    rect.size = CGSizeMake(600, 600);
    rect.origin.x = (imageOrgin.size.width - rect.size.width) / 2;    
    CGRect rectScanFrame = [self.view convertRect:m_scan.viewMask.rectNonMask fromView:m_scan];
    rect.origin.y = rectScanFrame.origin.y * fScaleHeight;
    
    if (rect.origin.x < rect.origin.y)
    {
        CGFloat x = rect.origin.x;
        rect.origin.x = rect.origin.y;
        rect.origin.y = x;
    }
    return rect;
}

- (void)startScan
{
    if (![m_captureManager.session isRunning])
        [m_captureManager.session startRunning];
    if (_nCameraMode == CameraMode_Scan)
        [m_scan.viewScanFrame startScanAnimate];
}

- (void)stopScan
{
    [m_captureManager.session stopRunning];
    [m_scan.viewScanFrame stopScanAnimate];
}

@end

#pragma mark -
@implementation ZWScannerVC (InternalMethods)

- (void)pinchZoomCamera:(UIPinchGestureRecognizer *)pinch
{
    if (!m_bCanManualAdjustZoom) return;
    [self setVideoZoom:m_fZoomScale + (pinch.velocity / 15) canManual:YES];
}

// Auto focus at a particular point. The focus mode will change to locked once the auto focus happens.
- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer
{
    if ([[[m_captureManager videoInput] device] isFocusPointOfInterestSupported])
    {
        CGPoint tapPoint = [gestureRecognizer locationInView:m_viewVideoPreview];
		CGPoint convertedFocusPoint = [(AVCaptureVideoPreviewLayer *)m_viewVideoPreview.layer captureDevicePointOfInterestForPoint:tapPoint];
        [m_captureManager autoFocusAtPoint:convertedFocusPoint];
    }
}

// Change to continuous auto focus. The camera will focus as needed at the point choosen.
- (void)tapToContinouslyAutoFocus:(UIGestureRecognizer *)gestureRecognizer
{
    AVCaptureDevice *device = [[m_captureManager videoInput] device];
    if ([device isFocusPointOfInterestSupported])
    {
        CGFloat fPt = device.focusPointOfInterest.x;
        if (fPt == 0.5)
            fPt = 0.49;
        else
            fPt = 0.5;
        [m_captureManager continuousFocusAtPoint:CGPointMake(fPt, fPt)];
    }
}

- (void)endAdjustFocus
{
    [m_scan stopIndicatorAnimate];
    if (_nCameraMode == CameraMode_Scan)
        [m_scan.viewScanFrame startScanAnimate];
}

- (void)adjustRectOfInterest
{
    if (![self isViewLoaded])
        return;
    CGRect rectScanFrame = [self.view convertRect:m_scan.viewMask.rectNonMask fromView:m_scan];
    CGRect rect;
    rect.origin.x = rectScanFrame.origin.y / self.view.bounds.size.height;
    rect.origin.y = rectScanFrame.origin.x / self.view.bounds.size.width;
    rect.size.width = rectScanFrame.size.height / self.view.bounds.size.height;
    rect.size.height = rectScanFrame.size.width / self.view.bounds.size.width;
    m_captureManager.metadataOutput.rectOfInterest = rect;
}

@end

#pragma mark -
@implementation ZWScannerVC (AVCamCaptureManagerDelegate)

- (void)captureManager:(AVCamCaptureManager *)captureManager didFailWithError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_delegateCamera respondsToSelector:@selector(qrScanner:didFailWithError:)])
        {
            [_delegateCamera qrScanner:self didFailWithError:error];
        }
    });
}

- (void)captureManager:(AVCamCaptureManager *)captureManager stillImageCaptured:(NSData *)dataImage
{
    //__block对象在block中不会被block强引用一次;__block对象在block中是可以被修改、重新赋值的
    __block id<ZWScannerDelegate> delegate = _delegateCamera;
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        if ([delegate respondsToSelector:@selector(qrScanner:didOutputImage:)])
        {
            [delegate qrScanner:self didOutputImage:dataImage];
        }
    });
}

- (void)captureManagerDeviceConfigurationChanged:(AVCamCaptureManager *)captureManager
{
}

- (void) captureManagerAuthorized:(AVCamCaptureManager *)captureManager
{
    __block ZWScannerVC *vcBlockSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [m_scan startIndicatorAnimate];
        [vcBlockSelf setupSession];
        m_captureManager.metadataOutput.metadataObjectTypes = m_captureManager.metadataOutput.availableMetadataObjectTypes;
        [[m_captureManager session] startRunning];
    });
}

- (void)captureManager:(AVCamCaptureManager *)captureManager codeValue:(NSString *)strValue
{
    __block id<ZWScannerDelegate> delegate = _delegateCamera;
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        if ([delegate respondsToSelector:@selector(qrScanner:didOutputValue:)])
        {
            [delegate qrScanner:self didOutputValue:strValue];
        }
    });
}
@end
