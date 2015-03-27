//
//  AVFoundationHandler.m
//  CameraDemo
//
//  Created by pinguo on 15/3/24.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "AVFoundationHandler.h"


static NSString * const ExposurationModeKey    = @"avDeviceInput.device.exposureMode";
static NSString * const ExpurationDurationKey  = @"avDeviceInput.device.exposureDuration";
static NSString * const ISOChangeKey           = @"avDeviceInput.device.ISO";

static void * ExposureModeContext = &ExposureModeContext;
static void * ExposureDurationContext = &ExposureDurationContext;
static void * ISOContext = &ISOContext;


static float EXPOSURE_MINIMUM_DURATION = 1.0/1000;


@interface AVFoundationHandler ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession * avCaptureSession;
@property (nonatomic, strong) AVCaptureDevice * avCaptureDevice;
@property (nonatomic, strong) AVCaptureStillImageOutput * stillImageOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput * videoDataOutput;
@property (nonatomic, strong) AVCaptureDeviceInput * avDeviceInput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer * previewLayer;

@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic, readwrite) float minISO;
@property (nonatomic, readwrite) float maxISO;
@property (nonatomic, readwrite) ResolutionMode currentPixel;
@property (nonatomic, readwrite) double currentExposureDuration;
@property (nonatomic, readwrite) float currentISOValue;


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
        _sessionQueue = dispatch_queue_create("sessionQueue", DISPATCH_QUEUE_SERIAL);
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

#pragma mark - Open Property

- (float)minISO
{
    if (self.avCaptureDevice) {
        return self.avCaptureDevice.activeFormat.minISO;
    }
    return -1;
}

- (float)maxISO
{
    if (self.avCaptureDevice) {
        return self.avCaptureDevice.activeFormat.maxISO;
    }
    return -1;
}

- (void)setCameraOKImageBlock:( void(^)(NSData * imageData)) imageBlock
{
    _imageBlock = imageBlock;
}

- (FlashMode)currentFlashMode
{
    switch (self.avCaptureDevice.flashMode) {
        case AVCaptureFlashModeAuto:
            
            return FlashModeAtuo;
        case AVCaptureFlashModeOff:
            
            return FlashModeOff;
        case AVCaptureFlashModeOn:
            
            return FlashModeOn;
    }
}

- (FocusMode)currentFocusMode
{
    switch (self.avCaptureDevice.focusMode) {
        case AVCaptureFocusModeLocked:
            return FocusModeLocked;
            break;
        case AVCaptureFocusModeAutoFocus:
            return FocusModeAutoFocus;
            break;
        case AVCaptureFocusModeContinuousAutoFocus:
            return FocusModeContinuousAutoFocus;
            break;
    }
}

- (ExposureMode)currentExposureMode
{
    switch (self.avCaptureDevice.exposureMode) {
        case AVCaptureExposureModeLocked:
            return ExposureModeLocked;
            break;
        case AVCaptureExposureModeAutoExpose:
            return ExposureModeAutoExpose;
            break;
        case AVCaptureExposureModeContinuousAutoExposure:
            return ExposureModeContinuousAutoExposure;
            break;
        case AVCaptureExposureModeCustom:
            return ExposureModeCustom;
            break;
    }
}

- (double)currentExposureDuration
{
   // AVCaptureExposureDurationCurrent
    return _currentExposureDuration;
}

- (float)currentISOValue
{
    return _currentISOValue;
}

- (ResolutionMode)currentPixel
{
    return _currentPixel;
}

#pragma mark - SetUp AVFoundation

- (void)setUpCaptureDevice
{
    if (!self.avCaptureDevice) {
        self.avCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        [self setFocusMode:FocusModeAutoFocus];
        [self setExposure:ExposureModeAutoExpose];
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
    
    [self setResolutionMode:ResolutionModeDefault];
    
//    if ([self.avCaptureSession canSetSessionPreset:AVCaptureSessionPresetPhoto]) {
//        self.avCaptureSession.sessionPreset = AVCaptureSessionPresetPhoto;
//    }
    
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



- (void)setAVFoundationHandlerWithView:(UIView *)preView
{
   // effectiveScale = 1.0;
    
    [self setUpCaptureSession];
    [self focusWithMode:FocusModeContinuousAutoFocus exposeWithMode:ExposureModeContinuousAutoExposure whiteBalanceMode:WhiteBalanceModeContinuousAutoWhiteBalance monitorSubjectAreaChange:NO];


    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.avCaptureSession];
    self.previewLayer.frame = preView.bounds;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//    [self.previewLayer setAffineTransform:CGAffineTransformMakeScale(effectiveScale, effectiveScale)];
    [preView.layer addSublayer:self.previewLayer];
}


- (void)removeAVFoundation
{
    [self stopVideo];
    if (self.avCaptureSession) {
        self.avCaptureSession = nil;
    }
    self.avCaptureDevice = nil;
    if (self.previewLayer) {
        [self.previewLayer removeFromSuperlayer];
    }
    
}



#pragma mark -- Founction 

//启动
- (void)startVideo
{
    dispatch_async(self.sessionQueue, ^{
        [self addObservers];
        [self.avCaptureSession startRunning];
    });
    
}

//停止
- (void)stopVideo
{
    dispatch_async(self.sessionQueue, ^{
        if (self.avCaptureSession) {
            [self.avCaptureSession stopRunning];
        }
        
        [self removeObservers];
    });

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
        //[self.delegate postImageData:imageData];
        self.imageBlock(imageData);
        
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

//聚焦模式
- (void)setFocusMode:(FocusMode)focusmode
{
    AVCaptureFocusMode mode;
    switch (focusmode) {
        case FocusModeLocked:
            
            mode = AVCaptureFocusModeLocked;
            break;
        case FocusModeAutoFocus:
            mode = AVCaptureFocusModeAutoFocus;
            break;
            
        case FocusModeContinuousAutoFocus:
            mode = AVCaptureFocusModeContinuousAutoFocus;
            break;
    }
    
    NSError * error = nil;
    if ([self.avCaptureDevice isFocusModeSupported:mode]) {
        if ([self.avCaptureDevice lockForConfiguration:&error]) {
            [self.avCaptureDevice setFocusMode:mode];
            [self.avCaptureDevice unlockForConfiguration];
        }
    }
    
}


//测光
- (void)setExposureX:(float)exposureX exposureY:(float)exposureY
{
    if ([self.avCaptureDevice isExposurePointOfInterestSupported]) {
        NSError * error = nil;
        if ([self.avCaptureDevice lockForConfiguration:&error]) {
            CGPoint autoExposurePoint = CGPointMake(exposureX, exposureY);
            [self.avCaptureDevice setExposurePointOfInterest:autoExposurePoint];
           // [self.avCaptureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
            
            [self.avCaptureDevice unlockForConfiguration];
        }
    }
}

//曝光
- (void)setExposure:(ExposureMode)exposureMode
{
    AVCaptureExposureMode mode;
    switch (exposureMode) {
        case ExposureModeLocked:
            mode = AVCaptureExposureModeLocked;
            break;
            
        case ExposureModeAutoExpose:
            mode = AVCaptureExposureModeAutoExpose;
            break;
        case ExposureModeContinuousAutoExposure:
            mode = AVCaptureExposureModeContinuousAutoExposure;
            break;
        case ExposureModeCustom:
            mode = AVCaptureExposureModeCustom;
            break;
    }
    
    NSError * error = nil;
    if ([self.avCaptureDevice isExposureModeSupported:mode]) {
        if ([self.avCaptureDevice lockForConfiguration:&error]) {
            [self.avCaptureDevice setExposureMode:mode];
            [self.avCaptureDevice unlockForConfiguration];
        }
    }
    
}

//曝光时间
- (void)setExposureDuration:(float)duration
{
    NSError * error = nil;
    
    double p = pow(duration, 5);
    double minDuration = MAX(CMTimeGetSeconds(self.avCaptureDevice.activeVideoMinFrameDuration), EXPOSURE_MINIMUM_DURATION);
    double maxDuration = CMTimeGetSeconds(self.avCaptureDevice.activeVideoMaxFrameDuration);
    double newDuration = p * (maxDuration - minDuration) + minDuration;
    
    if ([self.avCaptureDevice lockForConfiguration:&error]) {
        [self.avCaptureDevice setExposureModeCustomWithDuration:CMTimeMakeWithSeconds(newDuration, 1000*1000*1000) ISO:AVCaptureISOCurrent completionHandler:nil];
        [self.avCaptureDevice unlockForConfiguration];
    }
    
}

//ISO
- (void)setISO:(float)isoValue
{
    NSError * error = nil;
    
    if ([self.avCaptureDevice lockForConfiguration:&error]) {
        [self.avCaptureDevice setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:isoValue completionHandler:nil];
        [self.avCaptureDevice unlockForConfiguration];
    }
}


//白平衡
- (void)setWhiteBanlance:(WhiteBalanceMode)whiteBalanceMode
{
    AVCaptureWhiteBalanceMode mode;
    switch (whiteBalanceMode) {
        case WhiteBalanceModeLocked:
            mode = AVCaptureWhiteBalanceModeLocked;
            break;
        case WhiteBalanceModeAutoWhiteBalance:
            mode = AVCaptureWhiteBalanceModeAutoWhiteBalance;
            break;
            
        case WhiteBalanceModeContinuousAutoWhiteBalance:
            mode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
            break;
    }
    
    NSError * error = nil;
    if ([self.avCaptureDevice isWhiteBalanceModeSupported:mode]) {
        if ([self.avCaptureDevice lockForConfiguration:&error]) {
            [self.avCaptureDevice setWhiteBalanceMode:mode];
            [self.avCaptureDevice unlockForConfiguration];
        }
    }
    
}




//闪光
- (void)setFlashMode:(FlashMode)flashMode
{
    NSError * error = nil;
    
    AVCaptureFlashMode mode;
    
    switch (flashMode) {
        case FlashModeOff:
            mode = AVCaptureFlashModeOff;
            break;
        case FlashModeAtuo:
            mode = AVCaptureFlashModeAuto;
            break;
        case FlashModeOn:
            mode = AVCaptureFlashModeOn;
            break;
    }
    
    if ([self.avCaptureDevice hasFlash] && [self.avCaptureDevice isFlashModeSupported:mode]) {
        if ([self.avCaptureDevice lockForConfiguration:&error]) {
            [self.avCaptureDevice setFlashMode:mode];
            [self.avCaptureDevice unlockForConfiguration];
        }
    }

}

//切换镜头
- (void)setDevicePositionChange
{
    dispatch_async(self.sessionQueue, ^{
        
        AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
        AVCaptureDevicePosition currentPosition = [self.avCaptureDevice position];
        
        switch (currentPosition)
        {
            case AVCaptureDevicePositionUnspecified:
                preferredPosition = AVCaptureDevicePositionBack;
                break;
            case AVCaptureDevicePositionBack:
                preferredPosition = AVCaptureDevicePositionFront;
                break;
            case AVCaptureDevicePositionFront:
                preferredPosition = AVCaptureDevicePositionBack;
                break;
        }
        
        NSArray * cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice * device in cameras) {
            if (device.position == preferredPosition){
                self.avCaptureDevice = device;
                break;
            }
        
        }
        
        [self setFocusMode:FocusModeAutoFocus];
        
        [self.avCaptureSession removeInput:self.avDeviceInput];
        
        self.avDeviceInput  = [AVCaptureDeviceInput deviceInputWithDevice:self.avCaptureDevice error:nil];
        
        if ([self.avCaptureSession canAddInput:self.avDeviceInput]) {
            
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:nil];
            
            [self.avCaptureSession addInput:self.avDeviceInput];
        }
        
        
        [self.avCaptureSession commitConfiguration];
    });
  
    
    
}

- (void)setLensPosition:(float)len
{
    NSError * error = nil;
    if ([self.avCaptureDevice lockForConfiguration:&error]) {
        [self.avCaptureDevice setFocusModeLockedWithLensPosition:len completionHandler:nil];
        [self.avCaptureDevice unlockForConfiguration];
    }
}


//分辨率
- (void)setResolutionMode:(ResolutionMode)resolution
{

    
    switch (resolution) {
        case ResolutionModeDefault:{
            if ([self.avCaptureSession canSetSessionPreset:AVCaptureSessionPresetPhoto]) {
                self.avCaptureSession.sessionPreset = AVCaptureSessionPresetPhoto;
                self.currentPixel = ResolutionModeDefault;
            }
            break;
        }
        case ResolutionModeLow:{
            if ([self.avCaptureSession canSetSessionPreset:AVCaptureSessionPresetLow]) {
                self.avCaptureSession.sessionPreset = AVCaptureSessionPresetLow;
                self.currentPixel = ResolutionModeLow;
            }
            break;
        }
        case ResolutionModeMedium:{
            if ([self.avCaptureSession canSetSessionPreset:AVCaptureSessionPresetMedium]) {
                self.avCaptureSession.sessionPreset = AVCaptureSessionPresetMedium;
                self.currentPixel = ResolutionModeMedium;
            }
            break;
        }
        case ResolutionModeHigh:{
            if ([self.avCaptureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
                self.avCaptureSession.sessionPreset = AVCaptureSessionPresetHigh;
                self.currentPixel = ResolutionModeHigh;
            }
            break;
        }
    }
    
}


#pragma mark - NotificationCenter

- (void)subjectAreaDidChange:(NSNotification * )notification
{
    [self focusWithMode:FocusModeContinuousAutoFocus exposeWithMode:ExposureModeContinuousAutoExposure whiteBalanceMode:WhiteBalanceModeContinuousAutoWhiteBalance monitorSubjectAreaChange:NO];
}




#pragma mark - AVCaptureVideoDataOutputSampleBufferDeegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    
}

#pragma mark - Utilities

- (void)focusWithMode:(FocusMode)focusMode exposeWithMode:(ExposureMode)exposureMode whiteBalanceMode:(WhiteBalanceMode)whiteBalanceMode monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    dispatch_async(self.sessionQueue, ^{
        [self setFocusMode:focusMode];
        [self setFocus:.5f focusy:.5f];
        [self setFlashMode:NO];
        [self setExposure:exposureMode];
        [self setExposureX:.5f exposureY:.5f];
        [self setWhiteBanlance:whiteBalanceMode];
        
        NSError * error = nil;
        if ([self.avCaptureDevice lockForConfiguration:&error]) {
            [self.avCaptureDevice setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
            [self.avCaptureDevice unlockForConfiguration];
        }
    });
    
}

#pragma mark - KVO

- (void)addObservers
{
    [self addObserver:self forKeyPath:ExposurationModeKey options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:ExposureModeContext];
    [self addObserver:self forKeyPath:ExpurationDurationKey options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:ExposureDurationContext];
    [self addObserver:self forKeyPath:ISOChangeKey options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:ISOContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:nil];

}

- (void)removeObservers
{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:nil];
    [self removeObserver:self forKeyPath:ExposurationModeKey context:ExposureModeContext];
    [self removeObserver:self forKeyPath:ExpurationDurationKey context:ExposureDurationContext];
    [self removeObserver:self forKeyPath:ISOChangeKey context:ISOContext];
    
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == ExposureModeContext) {
        AVCaptureExposureMode oldMode = [change[NSKeyValueChangeOldKey] intValue];
        if (oldMode == AVCaptureExposureModeCustom)
        {
            NSError *error = nil;
            if ([self.avCaptureDevice lockForConfiguration:&error])
            {
                [self.avCaptureDevice setActiveVideoMaxFrameDuration:kCMTimeInvalid];
                [self.avCaptureDevice setActiveVideoMinFrameDuration:kCMTimeInvalid];
                [self.avCaptureDevice unlockForConfiguration];
            }
        }
        
    }else if (context == ExposureDurationContext) {
        
        double newDuration = CMTimeGetSeconds([change[NSKeyValueChangeNewKey] CMTimeValue]);
        if (self.avCaptureDevice.exposureMode != AVCaptureExposureModeCustom) {
            
            double minDuration = MAX(CMTimeGetSeconds(self.avCaptureDevice.activeFormat.minExposureDuration), EXPOSURE_MINIMUM_DURATION);
            double maxDuratino = CMTimeGetSeconds(self.avCaptureDevice.activeFormat.maxExposureDuration);
            
            double p = (newDuration - minDuration) / (maxDuratino - minDuration);
            
            //这里返回一个当前的曝光的时间值
            double returnValue = pow(p, 1 / EXPOSURE_MINIMUM_DURATION);
            self.currentExposureDuration = returnValue;
           // [[NSNotificationCenter defaultCenter] postNotificationName:@"ExposureDuration" object:nil userInfo:nil];
        }
        
        
        
    }else if (context == ISOContext){
    
        float newISO = [change[NSKeyValueChangeNewKey] floatValue];
        if (self.avCaptureDevice.exposureMode != AVCaptureExposureModeCustom) {
            //这里返回一个当前的ISO值。newISO
            
            _currentISOValue = newISO;
            
        }
        
    }
}






@end
