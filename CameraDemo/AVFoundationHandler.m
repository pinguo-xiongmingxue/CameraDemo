//
//  AVFoundationHandler.m
//  CameraDemo
//
//  Created by pinguo on 15/3/24.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "AVFoundationHandler.h"


static NSString * const ExpurationDurationKey  = @"ExpurationDurationKey";
static NSString * const ISOChangeKey           = @"ISOChangeKey";

static void * ExposureDurationContext = &ExposureDurationContext;
static void * ISOContext = &ISOContext;


static float EXPOSURE_MINIMUM_DURATION = 1.0/1000;


@interface AVFoundationHandler ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong, readwrite) AVCaptureSession * avCaptureSession;
@property (nonatomic, strong) AVCaptureDevice * avCaptureDevice;
@property (nonatomic, strong) AVCaptureStillImageOutput * stillImageOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput * videoDataOutput;
@property (nonatomic, strong) AVCaptureDeviceInput * avDeviceInput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer * previewLayer;

@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic, readwrite) float minISO;
@property (nonatomic, readwrite) float maxISO;




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


- (AVCaptureSession *)avCaptureSession
{
    if (!self.avCaptureSession) {
        [self setUpCaptureSession];
        [self focusWithMode:FocusModeContinuousAutoFocus exposeWithMode:ExposureModeContinuousAutoExposure whiteBalanceMode:WhiteBalanceModeContinuousAutoWhiteBalance monitorSubjectAreaChange:NO];
    }
    
    return self.avCaptureSession;
}

//- (AVCaptureSession *)captureSession
//{
//   
//}


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
    NSError * error = nil;
    switch (focusmode) {
        case FocusModeLocked:{
            if ([self.avCaptureDevice isFocusModeSupported:AVCaptureFocusModeLocked]) {
                if ([self.avCaptureDevice lockForConfiguration:&error]) {
                    [self.avCaptureDevice setFocusMode:AVCaptureFocusModeLocked];
                    [self.avCaptureDevice unlockForConfiguration];
                }
                
            }
            break;
        }
        case FocusModeAutoFocus:{
            if ([self.avCaptureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                if ([self.avCaptureDevice lockForConfiguration:&error]) {
                    [self.avCaptureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
                    [self.avCaptureDevice unlockForConfiguration];
                }
                
            }
            break;
        }
        case FocusModeContinuousAutoFocus:{
            if ([self.avCaptureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                if ([self.avCaptureDevice lockForConfiguration:&error]) {
                    [self.avCaptureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
                    [self.avCaptureDevice unlockForConfiguration];
                }
                
            }
            break;
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
            [self.avCaptureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
            
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
        
            if ([self.avCaptureDevice isExposureModeSupported:AVCaptureExposureModeCustom]) {
                if ([self.avCaptureDevice lockForConfiguration:&error]) {
                    [self.avCaptureDevice setExposureMode:AVCaptureExposureModeCustom];

                    [self.avCaptureDevice unlockForConfiguration];
                }
                
               
//                [self.avCaptureDevice setExposureModeCustomWithDuration:<#(CMTime)#> ISO:<#(float)#> completionHandler:^(CMTime syncTime) {
//                    
//                }];
              //  self.avCaptureDevice setExposureTargetBias:<#(float)#> completionHandler:<#^(CMTime syncTime)handler#>
            }
            
            
            //Indicates that the device should only adjust exposure according to user provided ISO, exposureDuration values.
            
            break;
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
    dispatch_async(self.sessionQueue, ^{
        
        
        
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
        
    
        [self setUpDeviceInput];
        
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

////缩放
//- (void)imageToBigOrToSmall:(float)bigScale
//{
//    if (bigScale < 1.0) {
//        bigScale = 1.0;
//    }
//    effectiveScale = bigScale;
//    [CATransaction begin];
//    [CATransaction setAnimationDuration:.025];
//    [self.previewLayer setAffineTransform:CGAffineTransformMakeScale(bigScale, bigScale)];
//    [CATransaction commit];
//}

//分辨率
- (void)setResolutionMode:(ResolutionMode)resolution
{
    switch (resolution) {
        case ResolutionModeDefault:{
            if ([self.avCaptureSession canSetSessionPreset:AVCaptureSessionPresetPhoto]) {
                self.avCaptureSession.sessionPreset = AVCaptureSessionPresetPhoto;
            }
            break;
        }
        case ResolutionModeLow:{
            if ([self.avCaptureSession canSetSessionPreset:AVCaptureSessionPresetLow]) {
                self.avCaptureSession.sessionPreset = AVCaptureSessionPresetLow;
            }
            break;
        }
        case ResolutionModeMedium:{
            if ([self.avCaptureSession canSetSessionPreset:AVCaptureSessionPresetMedium]) {
                self.avCaptureSession.sessionPreset = AVCaptureSessionPresetMedium;
            }
            break;
        }
        case ResolutionModeHigh:{
            if ([self.avCaptureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
                self.avCaptureSession.sessionPreset = AVCaptureSessionPresetHigh;
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
    [self addObserver:self forKeyPath:ExpurationDurationKey options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:ExposureDurationContext];
    [self addObserver:self forKeyPath:ISOChangeKey options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:ISOContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:nil];

    
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:nil];
    [self removeObserver:self forKeyPath:ExpurationDurationKey context:ExposureDurationContext];
    [self removeObserver:self forKeyPath:ISOChangeKey context:ISOContext];
    
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == ExposureDurationContext) {
        
        double newDuration = CMTimeGetSeconds([change[NSKeyValueChangeNewKey] CMTimeValue]);
        if (self.avCaptureDevice.exposureMode != AVCaptureExposureModeCustom) {
            
            double minDuration = MAX(CMTimeGetSeconds(self.avCaptureDevice.activeFormat.minExposureDuration), EXPOSURE_MINIMUM_DURATION);
            double maxDuratino = CMTimeGetSeconds(self.avCaptureDevice.activeFormat.maxExposureDuration);
            
            double p = (newDuration - minDuration) / (maxDuratino - minDuration);
            
            //这里返回一个当前的曝光的时间值
           double returnValue = pow(p, 1 / EXPOSURE_MINIMUM_DURATION);
            
        }
        
        
        
    }else if (context == ISOContext){
    
        float newISO = [change[NSKeyValueChangeNewKey] floatValue];
        if (self.avCaptureDevice.exposureMode != AVCaptureExposureModeCustom) {
            //这里返回一个当前的ISO值。newISO
        }
        
    }
}






@end
