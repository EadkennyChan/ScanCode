/*
     File: AVCamCaptureManager.m
 Abstract: Uses the AVCapture classes to capture video and still images.
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

#import "AVCamCaptureManager.h"
#import "AVCamRecorder.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/CGImageProperties.h>

@interface AVCamCaptureManager (RecorderDelegate) <AVCamRecorderDelegate, AVCaptureMetadataOutputObjectsDelegate>
@end


#pragma mark -
@interface AVCamCaptureManager (InternalUtilityMethods)
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition)position;
- (AVCaptureDevice *) frontFacingCamera;
- (AVCaptureDevice *) backFacingCamera;
- (AVCaptureDevice *) audioDevice;
- (NSURL *) tempFileURL;
- (void) removeFile:(NSURL *)outputFileURL;
- (void) copyFileToDocuments:(NSURL *)fileURL;
@end


#pragma mark -
@implementation AVCamCaptureManager

- (id) init
{
    self = [super init];
    if (self != nil)
    {
        _intervalScan = 3;
        
		__weak AVCamCaptureManager *weakSelf = self;
        void (^deviceConnectedBlock)(NSNotification *) = ^(NSNotification *notification) {
			AVCaptureDevice *device = [notification object];
			
			BOOL sessionHasDeviceWithMatchingMediaType = NO;
			NSString *deviceMediaType = nil;
			if ([device hasMediaType:AVMediaTypeAudio])
                deviceMediaType = AVMediaTypeAudio;
			else if ([device hasMediaType:AVMediaTypeVideo])
                deviceMediaType = AVMediaTypeVideo;
			
			if (deviceMediaType != nil)
            {
				for (AVCaptureDeviceInput *input in [[weakSelf session] inputs])
				{
					if ([[input device] hasMediaType:deviceMediaType])
                    {
						sessionHasDeviceWithMatchingMediaType = YES;
						break;
					}
				}
				if (!sessionHasDeviceWithMatchingMediaType)
                {
					NSError	*error;
					AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
					if ([[weakSelf session] canAddInput:input])
						[[weakSelf session] addInput:input];
				}				
			}
            
			if ([[weakSelf delegate] respondsToSelector:@selector(captureManagerDeviceConfigurationChanged:)])
            {
				[[weakSelf delegate] captureManagerDeviceConfigurationChanged:weakSelf];
			}			
        };
        void (^deviceDisconnectedBlock)(NSNotification *) = ^(NSNotification *notification) {
			AVCaptureDevice *device = [notification object];
            if ([device hasMediaType:AVMediaTypeVideo]) {
				[[weakSelf session] removeInput:[weakSelf videoInput]];
				[weakSelf setVideoInput:nil];
			}
			
			if ([[weakSelf delegate] respondsToSelector:@selector(captureManagerDeviceConfigurationChanged:)]) {
				[[weakSelf delegate] captureManagerDeviceConfigurationChanged:weakSelf];
			}			
        };
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [self setDeviceConnectedObserver:[notificationCenter addObserverForName:AVCaptureDeviceWasConnectedNotification object:nil queue:nil usingBlock:deviceConnectedBlock]];
        [self setDeviceDisconnectedObserver:[notificationCenter addObserverForName:AVCaptureDeviceWasDisconnectedNotification object:nil queue:nil usingBlock:deviceDisconnectedBlock]];
		[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
		[notificationCenter addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
		_orientation = AVCaptureVideoOrientationPortrait;
    }
    
    return self;
}

- (void) dealloc
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:[self deviceConnectedObserver]];
    [notificationCenter removeObserver:[self deviceDisconnectedObserver]];
	[notificationCenter removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    [[self session] stopRunning];
}

- (BOOL) setupSession
{
    BOOL success = YES;
    
    AVCaptureDevice *deviceBackFacing = [self backFacingCamera];
	// Set torch and flash mode to auto
	if ([deviceBackFacing hasFlash])
    {
		if ([deviceBackFacing lockForConfiguration:nil])
        {
			if ([deviceBackFacing isFlashModeSupported:AVCaptureFlashModeAuto])
            {
				[deviceBackFacing setFlashMode:AVCaptureFlashModeAuto];
			}
			[deviceBackFacing unlockForConfiguration];
		}
	}
	if ([deviceBackFacing hasTorch])
    {
		if ([deviceBackFacing lockForConfiguration:nil])
        {
			if ([deviceBackFacing isTorchModeSupported:AVCaptureTorchModeAuto])
            {
				[deviceBackFacing setTorchMode:AVCaptureTorchModeAuto];
			}
			[deviceBackFacing unlockForConfiguration];
		}
	}
    //请求授权
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo])
    {
        case AVAuthorizationStatusAuthorized:
        {
            [self initSession:deviceBackFacing];
            break;
        }
        case AVAuthorizationStatusNotDetermined:
        {
            success = NO;
            __block id<AVCamCaptureManagerDelegate> delegate = _delegate;
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
                if ( ! granted )
                {
                    NSError *error = [NSError errorWithDomain:AVFoundationErrorDomain code:AVErrorApplicationIsNotAuthorizedToUseDevice userInfo:nil];
                    if ([delegate respondsToSelector:@selector(captureManager:didFailWithError:)])
                        [delegate captureManager:self didFailWithError:error];
                }
                else
                {
                    if ([delegate respondsToSelector:@selector(captureManagerAuthorized:)])
                        [delegate captureManagerAuthorized:self];
                }
            }];
            break;
        }
        default:
        {
            success = NO;
            NSError *error = [NSError errorWithDomain:AVFoundationErrorDomain code:AVErrorApplicationIsNotAuthorizedToUseDevice userInfo:nil];
            if ([_delegate respondsToSelector:@selector(captureManager:didFailWithError:)])
                [_delegate captureManager:self didFailWithError:error];
            break;
        }
    }
    return success;
}

- (BOOL)initSession:(AVCaptureDevice *)device
{
    BOOL success = YES;
    // Init the device inputs
    AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:nil];
    _videoInput = newVideoInput;
    if (newVideoInput == nil)
        success = NO;
    // Create session (use default AVCaptureSessionPresetHigh)
    AVCaptureSession *newCaptureSession = [[AVCaptureSession alloc] init];
    if ([newCaptureSession canSetSessionPreset:AVCaptureSessionPresetHigh])
        [newCaptureSession setSessionPreset:AVCaptureSessionPresetHigh];
    else
        success = NO;
    _session = newCaptureSession;
    // Add inputs and output to the capture session
    if ([newCaptureSession canAddInput:newVideoInput])
    {
        [newCaptureSession addInput:newVideoInput];
    }
    else
        success = NO;
    
    [self setupScanCodeMode];
    [self setupStillImageMode];
    return success;
}

- (BOOL)setupStillImageMode
{
    BOOL success = YES;
    AVCaptureSession *newCaptureSession = _session;
    AVCaptureStillImageOutput *newStillImageOutput = _stillImageOutput;
    
    if (newStillImageOutput == nil)
    {
        // Setup the still image file output
        newStillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        NSDictionary *outputSettings = @{AVVideoCodecKey: AVVideoCodecJPEG};
        [newStillImageOutput setOutputSettings:outputSettings];
        _stillImageOutput = newStillImageOutput;
    }
    if ([newCaptureSession canAddOutput:newStillImageOutput])
    {
        [newCaptureSession addOutput:newStillImageOutput];
//        [newCaptureSession removeOutput:_metadataOutput];
    }
    else
        success = NO;
    return success;
}

- (BOOL)setupScanCodeMode
{
    BOOL success = YES;
    AVCaptureSession *newCaptureSession = _session;
    AVCaptureMetadataOutput *metadataOutput = _metadataOutput;
    
    if (metadataOutput == nil)
    {
        metadataOutput = [[AVCaptureMetadataOutput alloc] init];
        metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes;
        dispatch_queue_t metadataQueue = dispatch_queue_create("scanner", 0);
        [metadataOutput setMetadataObjectsDelegate:self queue:metadataQueue];
        self.metadataOutput = metadataOutput;
    }
    if ([newCaptureSession canAddOutput:metadataOutput])
    {
        [newCaptureSession addOutput:metadataOutput];
//        [newCaptureSession removeOutput:_stillImageOutput];
    }
    else
        success = NO;
    return success;
}

- (void) captureStillImage
{
    AVCaptureConnection *stillImageConnection = [[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo];
    if ([stillImageConnection isVideoOrientationSupported])
        [stillImageConnection setVideoOrientation:self.orientation];
    void (^handle)(CMSampleBufferRef, NSError *);
    handle = ^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        ALAssetsLibraryWriteImageCompletionBlock completionBlock = ^(NSURL *assetURL, NSError *error) {
            if (error)
            {
                if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)])
                {
                    [[self delegate] captureManager:self didFailWithError:error];
                }
            }
        };
        if (imageDataSampleBuffer != NULL)
        {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            if ([[self delegate] respondsToSelector:@selector(captureManager:stillImageCaptured:)])
            {
                [[self delegate] captureManager:self stillImageCaptured:imageData];
            }
        }
        else
            completionBlock(nil, error);
    };
    [[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:stillImageConnection
                                                         completionHandler:handle];
}

// Toggle between the front and back camera, if both are present.
- (BOOL) toggleCamera
{
    BOOL success = NO;
    
    if ([self cameraCount] > 1)
    {
        NSError *error = nil;
        AVCaptureDeviceInput *newVideoInput = nil;
        AVCaptureDevicePosition position = [[self.videoInput device] position];
        
        if (position == AVCaptureDevicePositionBack)
            newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontFacingCamera] error:&error];
        else if (position == AVCaptureDevicePositionFront)
            newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backFacingCamera] error:&error];
        
        if (newVideoInput != nil)
        {
            [[self session] beginConfiguration];
            [[self session] removeInput:[self videoInput]];
            if ([[self session] canAddInput:newVideoInput])
            {
                [[self session] addInput:newVideoInput];
                [self setVideoInput:newVideoInput];
            }
            else
            {
                [[self session] addInput:[self videoInput]];
            }
            [[self session] commitConfiguration];
            success = YES;
        }
        else if (error)
        {
            if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)])
            {
                [[self delegate] captureManager:self didFailWithError:error];
            }
        }
    }
    return success;
}

#pragma mark Device Counts
- (NSUInteger) cameraCount
{
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
}

- (NSUInteger) micCount
{
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] count];
}

#pragma mark Camera Properties
// Perform an auto focus at the specified point. The focus mode will automatically change to locked once the auto focus is complete.
- (void) autoFocusAtPoint:(CGPoint)point
{
    AVCaptureDevice *device = [[self videoInput] device];
    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus])
    {
        NSError *error;
        if ([device lockForConfiguration:&error])
        {
            [device setFocusPointOfInterest:point];
            [device setFocusMode:AVCaptureFocusModeAutoFocus];
            [device unlockForConfiguration];
        }
        else
        {
            if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)])
            {
                [[self delegate] captureManager:self didFailWithError:error];
            }
        }        
    }
}

// Switch to continuous auto focus mode at the specified point
- (void) continuousFocusAtPoint:(CGPoint)point
{
    AVCaptureDevice *device = [[self videoInput] device];
    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
    {
		NSError *error;
		if ([device lockForConfiguration:&error])
        {
			[device setFocusPointOfInterest:point];
			[device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
			[device unlockForConfiguration];
		}
        else
        {
			if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)])
            {
                [[self delegate] captureManager:self didFailWithError:error];
			}
		}
	}
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects.count == 0)
        return;
    AVMetadataObject *obj = [metadataObjects firstObject];
    if ([obj isKindOfClass:[AVMetadataMachineReadableCodeObject class]])
    {
        AVMetadataMachineReadableCodeObject *code = (AVMetadataMachineReadableCodeObject *)obj;
        //        AVMetadataMachineReadableCodeObject *code = (AVMetadataMachineReadableCodeObject*)[m_layerPreviewCapture transformedMetadataObjectForMetadataObject:obj];
        NSString *strValue = [code.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (strValue.length > 0)
        {
            if (![m_strLastCode isEqualToString:strValue] || [m_dateLastCode timeIntervalSinceNow] < -_intervalScan)
            {
                m_dateLastCode = [NSDate date];
                m_strLastCode = strValue;
                if ([_delegate respondsToSelector:@selector(captureManager:codeValue:)])
                {
                    [_delegate captureManager:self codeValue:strValue];
                }
            }
        }
    }
}

@end

#pragma mark -
@implementation AVCamCaptureManager (InternalUtilityMethods)

// Keep track of current device orientation so it can be applied to movie recordings and still image captures
- (void)deviceOrientationDidChange
{	
	UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    
	if (deviceOrientation == UIDeviceOrientationPortrait)
		self.orientation = AVCaptureVideoOrientationPortrait;
	else if (deviceOrientation == UIDeviceOrientationPortraitUpsideDown)
		self.orientation = AVCaptureVideoOrientationPortraitUpsideDown;
	
	// AVCapture and UIDevice have opposite meanings for landscape left and right (AVCapture orientation is the same as UIInterfaceOrientation)
	else if (deviceOrientation == UIDeviceOrientationLandscapeLeft)
		self.orientation = AVCaptureVideoOrientationLandscapeRight;
	else if (deviceOrientation == UIDeviceOrientationLandscapeRight)
		self.orientation = AVCaptureVideoOrientationLandscapeLeft;
	
	// Ignore device orientations for which there is no corresponding still image orientation (e.g. UIDeviceOrientationFaceUp)
}

// Find a camera with the specificed AVCaptureDevicePosition, returning nil if one is not found
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position)
        {
            return device;
        }
    }
    return nil;
}

// Find a front facing camera, returning nil if one is not found
- (AVCaptureDevice *) frontFacingCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

// Find a back facing camera, returning nil if one is not found
- (AVCaptureDevice *) backFacingCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

// Find and return an audio device, returning nil if one is not found
- (AVCaptureDevice *) audioDevice
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    if ([devices count] > 0)
    {
        return devices[0];
    }
    return nil;
}

- (NSURL *) tempFileURL
{
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"]];
}

- (void) removeFile:(NSURL *)fileURL
{
    NSString *filePath = [fileURL path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error;
        if ([fileManager removeItemAtPath:filePath error:&error] == NO) {
            if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
                [[self delegate] captureManager:self didFailWithError:error];
            }            
        }
    }
}

- (void) copyFileToDocuments:(NSURL *)fileURL
{
	NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
	NSString *destinationPath = [documentsDirectory stringByAppendingFormat:@"/output_%@.mov", [dateFormatter stringFromDate:[NSDate date]]];
	NSError	*error;
	if (![[NSFileManager defaultManager] copyItemAtURL:fileURL toURL:[NSURL fileURLWithPath:destinationPath] error:&error]) {
		if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
			[[self delegate] captureManager:self didFailWithError:error];
		}
	}
}	

@end
