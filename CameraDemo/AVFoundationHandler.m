//
//  AVFoundationHandler.m
//  CameraDemo
//
//  Created by pinguo on 15/3/24.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "AVFoundationHandler.h"

@interface AVFoundationHandler ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@end

@implementation AVFoundationHandler

+(instancetype)shareInstance
{
    static AVFoundationHandler * _av = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _av = [[self alloc] init];
    });
    
    return _av;
}

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}


+ (BOOL)isAuthorizatonToUseCamera
{
    __block BOOL isAvalible = NO;
    AVAuthorizationStatus  authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (authStatus) {
        case AVAuthorizationStatusNotDetermined:{
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    
                    // 不用处理
                    isAvalible = YES;
                }else{
                    
                   //提示不授权，无法使用。
                    isAvalible = NO;
                }
            }];
            
            break;
        }
        case AVAuthorizationStatusAuthorized:{
            
            // 不用处理
            isAvalible = YES;
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:{
            
            isAvalible = NO;
            //提示去授权
            
            break;
        }
        
    }
    return isAvalible;
}


#pragma mark - SetUp AVFoundation

- (void)setUpCaptureDevice
{
    if (!self.avCaptureDevice) {
        self.avCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }

}

- (void)setUpDeviceInput
{
    if (!self.avDeviceInput) {
        [self setUpCaptureDevice];
        NSError * error = nil;
        self.avDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.avCaptureDevice error:&error];
    }
   
}

- (void)setUpStillImageOutPut
{
    if (!self.stillImageOutput) {
        self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    }
    
    NSDictionary * outputSetting = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSetting];
    
}

- (void)setUpVideoDataOutPut
{
    if (!self.videoDataOutput) {
        self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    }
    
//    int x = kCVPixelFormatType_32BGRA;
//    NSString * str = [NSString stringWithFormat:@"%@",@(x)];
//    NSDictionary * outputSetting = [[NSDictionary alloc] initWithObjectsAndKeys:str,kCVPixelBufferPixelFormatTypeKey, nil];
    
    NSDictionary * outputSetting = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA],(id)kCVPixelBufferPixelFormatTypeKey, nil];
  
    self.videoDataOutput.videoSettings = outputSetting;
    
    self.videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    
     dispatch_queue_t queue = dispatch_queue_create("CameraVideoQueue", DISPATCH_QUEUE_SERIAL);
    
    [self.videoDataOutput setSampleBufferDelegate:self queue:queue];
  
}



- (void)setUpCaptureSession
{
    if (!self.avCaptureSession) {
         self.avCaptureSession = [[AVCaptureSession alloc] init];
    }
    
    [self.avCaptureSession beginConfiguration];
    
    if ([self.avCaptureSession canSetSessionPreset:AVCaptureSessionPresetPhoto]) {
        self.avCaptureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    }
    
    [self setUpDeviceInput];
    if ([self.avCaptureSession canAddInput:self.avDeviceInput]) {
        [self.avCaptureSession addInput:self.avDeviceInput];
    }
    
    
    //添加接口，设置不同的输出
//    [self setUpVideoDataOutPut];
//    
//    if ([self.avCaptureSession canAddOutput:self.videoDataOutput]) {
//        [self.avCaptureSession addOutput:self.videoDataOutput];
//    }

    [self setUpStillImageOutPut];
    if ([self.avCaptureSession canAddOutput:self.stillImageOutput]) {
        [self.avCaptureSession addOutput:self.stillImageOutput];
    }
    
    
    [self.avCaptureSession commitConfiguration];
}





- (void)initAVFoundationHandlerWithView:(UIView *)preView
{
    effectiveScale = 1.0;
    
    [self setUpCaptureSession];
    
    
//    if ([self.avCaptureSession canSetSessionPreset:AVCaptureSessionPresetInputPriority]) {
//        
//    }
    
 //   self.avCaptureSession.sessionPreset = AVCaptureSessionPresetInputPriority;
    
//    [self setDevicePosition:YES];
//    [self setFocus:.5f focusy:.5f];
//    [self setFlash:NO];
    
 //   [self setUpStillImageOutPut];
    
//    
//    if ([self.avCaptureSession canAddOutput:self.stillImageOutput]) {
//        [self.avCaptureSession addOutput:self.stillImageOutput];
//    }
    
    
    
    
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.avCaptureSession];
    self.previewLayer.frame = preView.bounds;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.previewLayer setAffineTransform:CGAffineTransformMakeScale(effectiveScale, effectiveScale)];
    [preView.layer addSublayer:self.previewLayer];
    
    
}

- (void)removeAVFoundatio
{
    if (self.avCaptureSession) {
        self.avCaptureSession = nil;
    }
    self.avCaptureDevice = nil;
    [self.previewLayer removeFromSuperlayer];
    
}



#pragma mark -- Founction 

//启动
- (void)startVideo
{
    [self.avCaptureSession startRunning];
}

//停止
- (void)stopVideo
{
    if (self.avCaptureSession) {
        [self.avCaptureSession stopRunning];
    }
}

//拍照
- (void)cameraOK
{
    if (self.stillImageOutput == nil) {
        [self setUpStillImageOutPut];
        [self.avCaptureSession addOutput:self.stillImageOutput];
    }
    
    AVCaptureConnection * videoConnection = nil;
    for (AVCaptureConnection * connection in self.stillImageOutput.connections) {
        for (AVCaptureInputPort * port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) {
            break;
        }
    }
    
    if ([videoConnection isVideoOrientationSupported]) {
        [videoConnection setVideoOrientation:(AVCaptureVideoOrientation)[UIApplication sharedApplication].statusBarOrientation];
    }
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        if (error) {
            NSLog(@"camera error: %@",error);
        }
        
        NSData * imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        [self.delegate postImageData:imageData];
        
    }];
    
    
}



#pragma mark -- Set Property

//聚焦点设置
- (void)setFocus:(float)focusx focusy:(float)focusy
{
    if ([self.avCaptureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus] || [self.avCaptureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        NSError * error = nil;
        if ([self.avCaptureDevice lockForConfiguration:&error]) {
            CGPoint autofocusPoint = CGPointMake(focusx, focusy);
            [self.avCaptureDevice setFocusPointOfInterest:autofocusPoint];
            self.avCaptureDevice.focusMode = AVCaptureFocusModeAutoFocus;
         //   self.avCaptureDevice.whiteBalanceMode = AVCaptureWhiteBalanceModeAutoWhiteBalance;
            [self.avCaptureDevice unlockForConfiguration];
        }
    }
}

//曝光
- (void)setExposure:(ExposureMode)exposureMode
{
    NSError * error = nil;
    switch (exposureMode) {
        case ExposureModeLocked:{
            
            if ([self.avCaptureDevice isExposureModeSupported:AVCaptureExposureModeLocked]) {
                if ([self.avCaptureDevice lockForConfiguration:&error]) {
                    [self.avCaptureDevice setExposureMode:AVCaptureExposureModeLocked];
                }
                [self.avCaptureDevice unlockForConfiguration];
                
            }

            
            break;
        }
        case ExposureModeAutoExpose:{
        
            if ([self.avCaptureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
                if ([self.avCaptureDevice lockForConfiguration:&error]) {
                    [self.avCaptureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
                }
                [self.avCaptureDevice unlockForConfiguration];
                
            }
            
            
            break;
        }
        case ExposureModeContinuousAutoExposure:{
        
            if ([self.avCaptureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                if ([self.avCaptureDevice lockForConfiguration:&error]) {
                    [self.avCaptureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
                }
                [self.avCaptureDevice unlockForConfiguration];
                
            }
            
            break;
        }
        case ExposureModeCustom:{
        
            //Indicates that the device should only adjust exposure according to user provided ISO, exposureDuration values.
            
            break;
        }
    }
    
}

//白平衡
- (void)setWhiteBanlance:(WhiteBalanceMode)whiteBalanceMode
{
    NSError * error = nil;
    switch (whiteBalanceMode) {
        case WhiteBalanceModeLocked:{
            
            if ([self.avCaptureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeLocked]) {
                if ([self.avCaptureDevice lockForConfiguration:&error]) {
                    [self.avCaptureDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeLocked];
                }
                [self.avCaptureDevice unlockForConfiguration];
            }
            
            break;
        }
        case WhiteBalanceModeAutoWhiteBalance:{
            
            if ([self.avCaptureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
                if ([self.avCaptureDevice lockForConfiguration:&error]) {
                    [self.avCaptureDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
                }
                [self.avCaptureDevice unlockForConfiguration];
            }
            
            break;
        }
        case WhiteBalanceModeContinuousAutoWhiteBalance:{
            
            if ([self.avCaptureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
                if ([self.avCaptureDevice lockForConfiguration:&error]) {
                    [self.avCaptureDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
                }
                [self.avCaptureDevice unlockForConfiguration];
            }
            
            break;
        }
    }
   
}


//闪光
- (void)setFlashMode:(FlashMode)flashMode
{
    NSError * error = nil;
    switch (flashMode) {
        case FlashModeOff:{
            
            if ([self.avCaptureDevice isFlashModeSupported:AVCaptureFlashModeOff]) {
                if ([self.avCaptureDevice lockForConfiguration:&error]) {
                    [self.avCaptureDevice setFlashMode:AVCaptureFlashModeOff];
                }
                [self.avCaptureDevice unlockForConfiguration];
            }

            
            break;
        }
        case FlashModeAtuo:{
            
            if ([self.avCaptureDevice isFlashModeSupported:AVCaptureFlashModeAuto]) {
                if ([self.avCaptureDevice lockForConfiguration:&error]) {
                    [self.avCaptureDevice setFlashMode:AVCaptureFlashModeAuto];
                }
                [self.avCaptureDevice unlockForConfiguration];
            }
            
            break;
        }
        case FlashModeOn:{
      
            if ([self.avCaptureDevice isFlashModeSupported:AVCaptureFlashModeOn]) {
                if ([self.avCaptureDevice lockForConfiguration:&error]) {
                    [self.avCaptureDevice setFlashMode:AVCaptureFlashModeOn];
                }
                [self.avCaptureDevice unlockForConfiguration];
            }
            
            break;
        }
            

    }

}

//切换镜头
- (void)setDevicePosition:(BOOL)backOrFront
{
    [self.avCaptureSession beginConfiguration];
    
    if (self.avCaptureSession != nil) {
        [self.avCaptureSession removeInput:self.avDeviceInput];
    }
    
    NSArray * cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice * device in cameras) {
        if (device.position == AVCaptureDevicePositionBack && backOrFront){
            self.avCaptureDevice = device;
            break;
        }else if (device.position == AVCaptureDevicePositionFront && !backOrFront){
            self.avCaptureDevice = device;
            break;
        }
    }
    
   // [self setUpCaptureDevice];
    
    [self setUpDeviceInput];
    
    [self.avCaptureSession addInput:self.avDeviceInput];
    [self.avCaptureSession commitConfiguration];
    
    
}

//缩放
- (void)imageToBigOrToSmall:(float)bigScale
{
    if (bigScale < 1.0) {
        bigScale = 1.0;
    }
    effectiveScale = bigScale;
    [CATransaction begin];
    [CATransaction setAnimationDuration:.025];
    [self.previewLayer setAffineTransform:CGAffineTransformMakeScale(bigScale, bigScale)];
    [CATransaction commit];
}

//分辨率
- (void)setPixelState:(NSInteger)state
{
    
}


#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    
}






@end
