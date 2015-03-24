//
//  AVFoundationHandler.m
//  CameraDemo
//
//  Created by pinguo on 15/3/24.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "AVFoundationHandler.h"

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

- (void)initAVFoundationHandlerWithView:(UIView *)preView
{
    effectiveScale = 1.0;
    
    if (!self.avCaptureSession) {
        self.avCaptureSession = [[AVCaptureSession alloc] init];
    }
    
    
//    if ([self.avCaptureSession canSetSessionPreset:AVCaptureSessionPresetInputPriority]) {
//        
//    }
    
    self.avCaptureSession.sessionPreset = AVCaptureSessionPresetInputPriority;
    
    [self setDevicePosition:YES];
    [self setFocus:.5f focusy:.5f];
    [self setFlash:NO];
    
    [self createStillImageOutPut];
    
    
    if ([self.avCaptureSession canAddOutput:self.stillImageOutput]) {
        [self.avCaptureSession addOutput:self.stillImageOutput];
    }
    
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

- (void)createStillImageOutPut
{
    if (!self.stillImageOutput) {
        self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    }
    
    NSDictionary * outputSetting = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSetting];
    
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
        [self createStillImageOutPut];
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
    if ([self.avCaptureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError * error = nil;
        if ([self.avCaptureDevice lockForConfiguration:&error]) {
            CGPoint autofocusPoint = CGPointMake(focusx, focusy);
            [self.avCaptureDevice setFocusPointOfInterest:autofocusPoint];
            self.avCaptureDevice.focusMode = AVCaptureFocusModeAutoFocus;
           // self.avCaptureDevice.whiteBalanceMode = AVCaptureWhiteBalanceModeAutoWhiteBalance;
            [self.avCaptureDevice unlockForConfiguration];
        }
    }
}

//曝光
- (void)setExposure:(BOOL)is
{
    if ([self.avCaptureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
        NSError * error = nil;
        if ([self.avCaptureDevice lockForConfiguration:&error]) {
            [self.avCaptureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        
        [self.avCaptureDevice unlockForConfiguration];
        
    }
}

//白平衡
- (void)setWhiteBanlance:(BOOL)is
{
    if ([self.avCaptureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
        
    }
}


//闪光
- (void)setFlash:(BOOL)onOrOff
{
    if (onOrOff) {
        if ([self.avCaptureDevice isFlashModeSupported:AVCaptureFlashModeOn]) {
            NSError * error = nil;
            if ([self.avCaptureDevice lockForConfiguration:&error]) {
                [self.avCaptureDevice setFlashMode:AVCaptureFlashModeAuto];
            }
            [self.avCaptureDevice unlockForConfiguration];
        }
    }else{
        if ([self.avCaptureDevice isFlashModeSupported:AVCaptureFlashModeOff]) {
            NSError * error = nil;
            if ([self.avCaptureDevice lockForConfiguration:&error]) {
                [self.avCaptureDevice setFlashMode:AVCaptureFlashModeOff];
            }
            [self.avCaptureDevice unlockForConfiguration];
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
    
    if (self.avCaptureDevice == nil) {
        self.avCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
    }
    
    NSError * error = nil;
    self.avDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.avCaptureDevice error:&error];
    
    if (!self.avDeviceInput) {
        self.avDeviceInput = nil;
    }
    
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









@end
