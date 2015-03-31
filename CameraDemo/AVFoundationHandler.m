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
{
    BOOL _openOrcloseFilter;
    BOOL _openDoubleExposure; //
    BOOL _isFirst;
    BOOL _isSecond;

}

@property (nonatomic, strong) AVCaptureSession * avCaptureSession;
@property (nonatomic, strong) AVCaptureDevice * avCaptureDevice;
@property (nonatomic, strong) AVCaptureStillImageOutput * stillImageOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput * videoDataOutput;
@property (nonatomic, strong) AVCaptureDeviceInput * avDeviceInput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer * previewLayer;

@property (nonatomic, strong) CALayer * filterLayer;

@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic, readwrite) float minISO;
@property (nonatomic, readwrite) float maxISO;
@property (nonatomic, readwrite) ResolutionMode currentPixel;
@property (nonatomic, readwrite) double currentExposureDuration;
@property (nonatomic, readwrite) float currentISOValue;
@property (nonatomic, readwrite) NSInteger numbersOfSupportFormats;
@property (nonatomic, readwrite) Float64 activeMaxFrameRate;
@property (nonatomic, readwrite) Float64 activeMinFrameRate;
@property (nonatomic, readwrite) FilterShowMode currentFilterMode;
@property (nonatomic, readwrite) BOOL curentDoubleExposureState;


@property (nonatomic, strong) CIFilter * customFilter;
@property (nonatomic, strong) CIContext * ciContext;
@property (nonatomic, strong) CIImage * outPutImage;

@property (nonatomic, strong) UIImage * frontImage;

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
        _openOrcloseFilter = NO;
        _openDoubleExposure = NO;
        _isFirst = YES;
        _isSecond = NO;
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


- (Float64)activeMaxFrameRate
{
    NSArray * array  = self.avCaptureDevice.activeFormat.videoSupportedFrameRateRanges;
    AVFrameRateRange * range = [array lastObject];
    return range.maxFrameRate;
}

- (Float64)activeMinFrameRate
{
    NSArray * array  = self.avCaptureDevice.activeFormat.videoSupportedFrameRateRanges;
    AVFrameRateRange * range = [array lastObject];
    return range.minFrameRate;
}

- (NSInteger)numbersOfSupportFormats
{
    return self.avCaptureDevice.formats.count;
}



- (void)setCameraOKImageBlock:( void(^)(NSData * imageData)) imageBlock
{
    _imageBlock = imageBlock;
}

- (void)setCameraOKVideoBlock:(void(^)(BOOL *isOk)) videoBlock
{
    _videoBlock = videoBlock;
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

- (WhiteBalanceMode)currentWBMode
{
    switch (self.avCaptureDevice.whiteBalanceMode) {
        case AVCaptureWhiteBalanceModeLocked:
            return WhiteBalanceModeLocked;
            break;
//        case AVCaptureWhiteBalanceModeAutoWhiteBalance:
//            return WhiteBalanceModeAutoWhiteBalance;
//            break;
        case AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance:
            return WhiteBalanceModeContinuousAutoWhiteBalance;
            break;
        default:
            return WhiteBalanceModeContinuousAutoWhiteBalance;
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

//- (FilterShowMode)currentFilterMode
//{
//    return self.currentFilterMode;
//}

- (ResolutionMode)currentPixel
{
    return _currentPixel;
}

- (BOOL)curentDoubleExposureState
{
    return _openDoubleExposure;
}

#pragma mark - SetUp AVFoundation

- (void)openOrCloseFilter:(BOOL)openOrcloseFilter
{
    if (openOrcloseFilter) {
        _openOrcloseFilter = YES;
     //   self.currentFilterMode = FilterShowModeNone;
        [self setUpCIContext];
        [self setUpCustomFilterMode:self.currentFilterMode];
    }else{
      //  self.currentFilterMode = FilterShowModeNone;
        _openOrcloseFilter = NO;
        self.customFilter = nil;
        self.ciContext = nil;
    }
}

- (void)openDoubleExposure:(BOOL)isOpenDoubleExposure
{
    if (isOpenDoubleExposure) {
        _openOrcloseFilter = NO;
        _openDoubleExposure = YES;
        [self setUpCIContext];
        _isFirst = YES;
        _isSecond = NO;
    }else{
        _openDoubleExposure = NO;
        self.ciContext = nil;
    }
}

- (void)setUpCIContext
{
    if (!self.ciContext) {
    
      //  CIContext * context;
        EAGLContext * eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
        self.ciContext = [CIContext contextWithEAGLContext:eaglContext
                                            options:nil];
        //@{kCIContextOutputColorSpace:[NSNull null]}
    }
}

- (void)setUpCustomFilterMode:(FilterShowMode)mode
{
    NSString * filterName = nil;
    switch (mode) {
        case FilterShowModeNone:{
            self.currentFilterMode = FilterShowModeNone;
            break;
        }
        case FilterShowModeCustomFirst:{
            filterName = @"CIColorInvert";
            self.currentFilterMode = FilterShowModeCustomFirst;
            break;
        }
        case FilterShowModeCustomSecond:{
            filterName = @"CIPhotoEffectInstant";
            self.currentFilterMode = FilterShowModeCustomSecond;
            break;
        }
        case FilterShowModeCustomThird:{
            filterName = @"CIPhotoEffectTransfer";
            self.currentFilterMode = FilterShowModeCustomThird;
            break;
        }
    }
    
    if (filterName == nil) {
        self.customFilter = nil;
    }else{
        self.customFilter = [CIFilter filterWithName:filterName];
    }
    
    
}



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
    
    NSDictionary * outputSetting = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA],(id)kCVPixelBufferPixelFormatTypeKey, nil];
  

    self.videoDataOutput.videoSettings = outputSetting;
    
    self.videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    
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
    [self setUpVideoDataOutPut];
    
    if ([self.avCaptureSession canAddOutput:self.videoDataOutput]) {
        [self.avCaptureSession addOutput:self.videoDataOutput];
    }
    dispatch_queue_t queue = dispatch_queue_create("CameraVideoQueue", DISPATCH_QUEUE_SERIAL);
    
    [self.videoDataOutput setSampleBufferDelegate:self queue:queue];
    
    
    
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

    [self openOrCloseFilter:NO];
    
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.avCaptureSession];
    self.previewLayer.frame = preView.bounds;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//    [self.previewLayer setAffineTransform:CGAffineTransformMakeScale(effectiveScale, effectiveScale)];
    [preView.layer addSublayer:self.previewLayer];
    
  
    self.filterLayer = [CALayer layer];
//    [self.filterLayer setBackgroundColor:[UIColor redColor].CGColor];
    self.filterLayer.frame = self.previewLayer.bounds;
    [preView.layer insertSublayer:self.filterLayer above:self.previewLayer];
    
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
        [self stopVideo];
        self.imageBlock(imageData);
        [self startVideo];
        
    }];

    
//    CGImageRef  cgImage = [self.ciContext createCGImage:self.outPutImage fromRect:[self.outPutImage extent]];
//    UIImage * image = [UIImage imageWithCGImage:cgImage];
//    NSData * data = UIImageJPEGRepresentation(image, 1);
//    
//    [self stopVideo];
//    self.imageBlock(data);
//    [self startVideo];
}



#pragma mark -- Set Property

//聚焦点设置
- (void)setFocus:(float)focusx focusy:(float)focusy
{
    if ([self.avCaptureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus] || [self.avCaptureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        NSError * error = nil;
        if ([self.avCaptureDevice lockForConfiguration:&error]) {
            self.avCaptureDevice.focusMode = AVCaptureFocusModeAutoFocus;
            CGPoint autofocusPoint = CGPointMake(focusx, focusy);
            [self.avCaptureDevice setFocusPointOfInterest:autofocusPoint];
            [self.avCaptureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
            [self.avCaptureDevice setExposurePointOfInterest:autofocusPoint];
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
//        case WhiteBalanceModeAutoWhiteBalance:
//            mode = AVCaptureWhiteBalanceModeAutoWhiteBalance;
//            break;
            
        case WhiteBalanceModeContinuousAutoWhiteBalance:
            mode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
            break;
    }
    if ([self.avCaptureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
        NSLog(@"support");
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

- (void)setFrameRate:(int)desiredFrameRate
{
    BOOL isSupported = NO;
    for (AVFrameRateRange * range in self.avCaptureDevice.activeFormat.videoSupportedFrameRateRanges) {
        if (range.maxFrameRate >= desiredFrameRate && range.minFrameRate <= desiredFrameRate) {
            isSupported = YES;
            break;
        }
    }
    if (isSupported) {
        NSError * error;
        if ([self.avCaptureDevice lockForConfiguration:&error]) {
            self.avCaptureDevice.activeVideoMaxFrameDuration = CMTimeMake(1, desiredFrameRate);
            self.avCaptureDevice.activeVideoMinFrameDuration = CMTimeMake(1, desiredFrameRate);
            [self.avCaptureDevice unlockForConfiguration];
        }
    }
}

- (void)configureFrameRate:(int)desiredFrameRate
{
    AVCaptureDeviceFormat * desiredFormat = nil;
    for (AVCaptureDeviceFormat * format in self.avCaptureDevice.formats) {
        for (AVFrameRateRange * range  in format.videoSupportedFrameRateRanges) {
            if (range.maxFrameRate >= desiredFrameRate && range.minFrameRate <= desiredFrameRate) {
                desiredFormat = format;
                goto DesiredFormatFound;
            }
        }
    }
DesiredFormatFound:
    if (desiredFormat) {
        NSError * error = nil;
        [self.avCaptureSession beginConfiguration];
        if ([self.avCaptureDevice lockForConfiguration:&error]) {
            self.avCaptureDevice.activeFormat = desiredFormat;
            self.avCaptureDevice.activeVideoMaxFrameDuration = CMTimeMake(1, desiredFrameRate);
            self.avCaptureDevice.activeVideoMinFrameDuration = CMTimeMake(1, desiredFrameRate);
            [self.avCaptureDevice unlockForConfiguration];
        }
        [self.avCaptureSession commitConfiguration];
    }
    
}


#pragma mark - NotificationCenter

- (void)subjectAreaDidChange:(NSNotification * )notification
{
    [self focusWithMode:FocusModeContinuousAutoFocus exposeWithMode:ExposureModeContinuousAutoExposure whiteBalanceMode:WhiteBalanceModeContinuousAutoWhiteBalance monitorSubjectAreaChange:NO];
}



#pragma mark - AVCaptureVideoDataOutputSampleBufferDeegate

- (void)cameraVideoOk
{
    //_isCameraVideoOk = YES;
    
    if (_isFirst) {
        [self.avCaptureSession stopRunning];
        
        CGImageRef cgImageRef = [self.ciContext createCGImage:self.outPutImage fromRect:[self.outPutImage extent]];
        
//        UIImage * image = [UIImage imageWithCGImage:cgImageRef];
//        NSData * imageData = UIImagePNGRepresentation(image);
//        
//        self.imageBlock(imageData);
        
        UIImage * image = [UIImage imageWithCGImage:cgImageRef];
        
        if (image) {
            UIImage * frontImage = [self imageByApplyingAlpha:0.5 image:image];
            self.frontImage = image;
            self.filterLayer.contents = (__bridge id)([frontImage CGImage]);
            CGImageRelease(cgImageRef);
            
        }
      
        
         _isFirst = NO;
         _isSecond = YES;
        [self.avCaptureSession startRunning];
        
       
    }else if(_isSecond){
        
        [self.avCaptureSession stopRunning];
        
        CGImageRef cgImageRef = [self.ciContext createCGImage:self.outPutImage fromRect:[self.outPutImage extent]];
        
        //        UIImage * image = [UIImage imageWithCGImage:cgImageRef];
        //        NSData * imageData = UIImagePNGRepresentation(image);
        //
        //        self.imageBlock(imageData);
        
        UIImage * image = [UIImage imageWithCGImage:cgImageRef];
        
        CGImageRelease(cgImageRef);
        
        
        
        if (image) {
            
            UIImage * resultImage = [self processUsingPixels:image];
            NSData * imageData = UIImagePNGRepresentation(resultImage);
            self.imageBlock(imageData);
          
          
        }
        
        
        
        _isFirst = YES;
        _isSecond = NO;
        [self.avCaptureSession startRunning];
        self.filterLayer.contents = nil;
    }
    
  
    
    
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (_openOrcloseFilter) {
        CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
       
        CGAffineTransform transform;
        UIDeviceOrientation  orientation = [[UIDevice currentDevice] orientation];
        if (orientation == UIDeviceOrientationPortrait) {
            transform = CGAffineTransformMakeRotation(-M_PI/2.0);
        }else if (orientation == UIDeviceOrientationPortraitUpsideDown){
            transform = CGAffineTransformMakeRotation(M_PI/2.0);
        }else if (orientation == UIDeviceOrientationLandscapeRight){
            transform = CGAffineTransformMakeRotation(M_PI);
        }else{
            transform = CGAffineTransformMakeRotation(0);
        }
        
        self.outPutImage = [[CIImage imageWithCVPixelBuffer:pixelBuffer] imageByApplyingTransform:transform];

        
        if (self.customFilter) {
            [self.customFilter setDefaults];
            [self.customFilter setValue:self.outPutImage forKey:kCIInputImageKey];
            self.outPutImage = self.customFilter.outputImage;
        
        }
    
        CGImageRef cgImageRef = [self.ciContext createCGImage:self.outPutImage fromRect:[self.outPutImage extent]];

        
        dispatch_sync(dispatch_get_main_queue(), ^{
    
            self.filterLayer.contents = (__bridge id)(cgImageRef);

            CGImageRelease(cgImageRef);
        });
    }else if(_openDoubleExposure){
        if (_isFirst || _isSecond) {

            
           
            CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            
            CGAffineTransform transform;
            UIDeviceOrientation  orientation = [[UIDevice currentDevice] orientation];
            if (orientation == UIDeviceOrientationPortrait) {
                transform = CGAffineTransformMakeRotation(-M_PI/2.0);
            }else if (orientation == UIDeviceOrientationPortraitUpsideDown){
                transform = CGAffineTransformMakeRotation(M_PI/2.0);
            }else if (orientation == UIDeviceOrientationLandscapeRight){
                transform = CGAffineTransformMakeRotation(M_PI);
            }else{
                transform = CGAffineTransformMakeRotation(0);
            }
            
            self.outPutImage = [[CIImage imageWithCVPixelBuffer:pixelBuffer] imageByApplyingTransform:transform];
            
        
            
        
//            CGImageRef cgImageRef = [self.ciContext createCGImage:self.outPutImage fromRect:[self.outPutImage extent]];
//            
//            UIImage * image = [UIImage imageWithCGImage:cgImageRef];
//            
//            UIImage * frontImage = [self imageByApplyingAlpha:0.5 image:image];
//            
//            
//            dispatch_sync(dispatch_get_main_queue(), ^{
//                
//                self.filterLayer.contents = (__bridge id)([frontImage CGImage]);
//                
//                CGImageRelease(cgImageRef);
//            });
            
            
            
            
        }else{
        
    
            
//            _isFirst = NO;
        }
        
        
    }else{
        
    }

    
}

//设置图片透明度
- (UIImage *)imageByApplyingAlpha:(CGFloat)alpha  image:(UIImage*)image
{
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0.0f);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    NSLog(@"rect %@",NSStringFromCGSize(image.size));
    
    CGRect area = CGRectMake(0, 0, image.size.width, image.size.height);
    
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -area.size.height);
    
    CGContextSetBlendMode(ctx, kCGBlendModeMultiply);
    
    CGContextSetAlpha(ctx, alpha);
    
    CGContextDrawImage(ctx, area, image.CGImage);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

#define Mask8(x) ( (x) & 0xFF )
#define R(x) ( Mask8(x) )
#define G(x) ( Mask8(x >> 8 ) )
#define B(x) ( Mask8(x >> 16) )
#define A(x) ( Mask8(x >> 24) )
#define RGBAMake(r, g, b, a) ( Mask8(r) | Mask8(g) << 8 | Mask8(b) << 16 | Mask8(a) << 24 )

- (UIImage *)processUsingPixels:(UIImage *)inputImage
{
    if (!self.frontImage) {
        return nil;
    }
    
    
//    UIGraphicsBeginImageContext(inputImage.size);
//    
//    // Draw image1
//    [self.frontImage drawInRect:CGRectMake(0, 0, self.frontImage.size.width, self.frontImage.size.height)];
//    
//    // Draw image2
//    [inputImage drawInRect:CGRectMake(0, 0, inputImage.size.width, inputImage.size.height)];
//    
//    UIImage *processedImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
    
    
    UInt32 * backPixels;
    
    CGImageRef backCGImage = [inputImage CGImage];
    NSUInteger backWidth = CGImageGetWidth(backCGImage);
    NSUInteger backHeight = CGImageGetHeight(backCGImage);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bitsPerComponent = 8;
    
    NSUInteger inputBytesPerRow = bytesPerPixel * backWidth;
    
    backPixels = (UInt32 *)calloc(backHeight * backWidth, sizeof(UInt32));
    
    CGContextRef context = CGBitmapContextCreate(backPixels, backWidth, backHeight,
                                                 bitsPerComponent, inputBytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(context, CGRectMake(0, 0, backWidth, backHeight), backCGImage);
    
    
    
    if (self.frontImage) {
        NSLog(@"xxxx");
    }
    
    CGImageRef frontCGImage = [self.frontImage CGImage];
    
    NSUInteger frontW = CGImageGetWidth(frontCGImage);
    NSUInteger frontH = CGImageGetHeight(frontCGImage);
    CGColorSpaceRef colorSpace1 = CGColorSpaceCreateDeviceRGB();
    NSUInteger bytesPerPixel1 = 4;
    NSUInteger bitsPerComponent1 = 8;
    
    NSUInteger inputBytesPerRow1 = bytesPerPixel1 * frontW;
    
    UInt32 * frontPixels = (UInt32 *)calloc(frontW * frontH, sizeof(UInt32));
    
    CGContextRef frontContext = CGBitmapContextCreate(frontPixels, frontW, frontH,
                                                      bitsPerComponent1, inputBytesPerRow1, colorSpace1,
                                                      kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(frontContext, CGRectMake(0, 0, frontW, frontH),frontCGImage);
  /*
    假设一幅图象是A，另一幅透明的图象是B，那么透过B去看A，看上去的图象C就是B和A的混合图象，
    设B图象的透明度为alpha(取值为0-1，1为完全透明，0为完全不透明).
    Alpha混合公式如下：
    R(C)=(1-alpha)*R(B) + alpha*R(A)
    G(C)=(1-alpha)*G(B) + alpha*G(A)
    B(C)=(1-alpha)*B(B) + alpha*B(A)
    R(x)、G(x)、B(x)分别指颜色x的RGB分量原色值。
    */
    
    for (NSUInteger j = 0; j < frontH; j++) {
        for (NSUInteger i = 0; i < frontW; i++) {
            UInt32 * backPixel = backPixels + j * backWidth + i;
            UInt32 backColor = *backPixel;
            
            UInt32 * frontPixel = frontPixels + j * (int)frontW + i;
            UInt32 frontColor = *frontPixel;
            
        
            CGFloat ghostAlpha = 0.5f * (A(frontColor) / 255.0);
            UInt32 newR = R(frontColor) * (1 - ghostAlpha) + R(backColor) * ghostAlpha;
            UInt32 newG = G(frontColor) * (1 - ghostAlpha) + G(backColor) * ghostAlpha;
            UInt32 newB = B(frontColor) * (1 - ghostAlpha) + B(backColor) * ghostAlpha;
            
            newR = MAX(0,MIN(255, newR));
            newG = MAX(0,MIN(255, newG));
            newB = MAX(0,MIN(255, newB));
            
            *backPixel = RGBAMake(newR, newG, newB, A(backColor));
        }
        
    }
    
    
    CGImageRef newCGImage = CGBitmapContextCreateImage(context);
    UIImage * processedImage = [UIImage imageWithCGImage:newCGImage];
    
    // 5. Cleanup!
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CGContextRelease(frontContext);
    free(backPixels);
    free(frontPixels);
    
    return processedImage;

}

#undef RGBAMake
#undef R
#undef G
#undef B
#undef A
#undef Mask8

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
    
    //可以添加activeVideoMaxFrameDuration和activeVideoMinFrameDuration的观察。
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
