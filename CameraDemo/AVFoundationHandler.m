//
//  AVFoundationHandler.m
//  CameraDemo
//
//  Created by pinguo on 15/3/24.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "AVFoundationHandler.h"
#import "CTargetAction.h"

/*

@class AVFoundationHandler;

@interface CHandleOperation : NSOperation

@property (nonatomic, strong) NSDictionary * infoDict;

@end

@implementation CHandleOperation

- (id)initWithResponseInfo:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        _infoDict = dictionary;
    }
    return self;
}

- (void)main
{
    @autoreleasepool {
        [[AVFoundationHandler shareInstance] performSelector:@selector(handleResponseObserverTypeInfo:) withObject:self.infoDict];
    }
}

- (void)cancel
{
    [super cancel];
}

@end

*/
NSString * const kExposureModeNotificationKey = @"kExposureModeNotificationKey";
NSString * const kExposureDurationNotificationKey = @"kExposureDurationNotificationKey";
NSString * const kExposureTargetOffsetNotificationKey = @"kExposureTargetOffsetNotificationKey";
NSString * const kExposureTargetBiasNotificationKey = @"kExposureTargetBiasNotificationKey";
NSString * const kISOChangeNotificationKey = @"kISOChangeNotificationKey";
NSString * const kLensPositionNotificationKey = @"kLensPositionNotificationKey";
NSString * const kWhiteBalanceModeNotificationKey = @"kWhiteBalanceModeNotificationKey";
NSString * const kWhiteBalanceGainsNotificationKey = @"kWhiteBalanceGainsNotificationKey";
NSString * const kFocusModeNotificationKey = @"kFocusModeNotificationKey";
NSString * const kFilterModeNotificationKey = @"kFilterModeNotificationKey";

static float EXPOSURE_MINIMUM_DURATION = 1.0/1000;

@interface AVFoundationHandler ()<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    BOOL _openOrcloseFilter;   // 是否开启实时滤镜
    BOOL _openDoubleExposure;  //是否开启双重曝光相机
    BOOL _isFirstCameraOK;     // 双重曝光相机第一次按下拍照
    BOOL _isSecondCameraOK;    // 双重曝光相机第二次按下拍照
    /* !!!!!
        实时滤镜和双重曝光相机互斥使用
     */
    
    
//    NSMutableDictionary * _observeres;
//    NSLock * _lock;
//    NSOperationQueue * _operationQueue;
    
}

@property (nonatomic) dispatch_queue_t sessionQueue;

@property (nonatomic, strong) AVCaptureSession * avCaptureSession;
@property (nonatomic, strong) AVCaptureDevice * avCaptureDevice;
@property (nonatomic, strong) AVCaptureStillImageOutput * stillImageOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput * videoDataOutput;
@property (nonatomic, strong) AVCaptureDeviceInput * avDeviceInput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer * previewLayer;

@property (nonatomic, strong) CALayer * filterLayer;  //实时滤镜效果layer和双重曝光相机第一次曝光层


@property (nonatomic, readwrite) float minISO;
@property (nonatomic, readwrite) float maxISO;
@property (nonatomic, readwrite) float currentISOValue;
@property (nonatomic, readwrite) float maxExposureBias;
@property (nonatomic, readwrite) float minExposureBias;
@property (nonatomic, readwrite) float currentExposureBias;
@property (nonatomic, readwrite) ResolutionMode currentPixel;
@property (nonatomic, readwrite) double currentExposureDuration;
@property (nonatomic, readwrite) NSInteger numbersOfSupportFormats;
@property (nonatomic, readwrite) Float64 activeMaxFrameRate;
@property (nonatomic, readwrite) Float64 activeMinFrameRate;
@property (nonatomic, readwrite) FlameRate currentFrameRate;
@property (nonatomic, readwrite) FilterShowMode currentFilterMode;
@property (nonatomic, readwrite) BOOL curentDoubleExposureState;


@property (nonatomic, strong) CIFilter * customFilter;
@property (nonatomic, strong) CIContext * ciContext;
@property (nonatomic, strong) CIImage * outPutImage;
@property (nonatomic, strong) UIImage * frontImage;

//- (void)handleResponseObserverTypeInfo:(NSDictionary *)infoDict;

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
        _isFirstCameraOK = YES;
        _isSecondCameraOK = NO;
//        _operationQueue = [[NSOperationQueue alloc] init];
//        [_operationQueue setMaxConcurrentOperationCount:2];
//        _lock = [[NSLock alloc] init];
    }
    return self;
}

- (void)dealloc
{
    self.imageBlock = nil;
    self.videoBlock = nil;
   // [_operationQueue cancelAllOperations];
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
/*
- (NSNumber *)numberWithObserverType:(ObserverType)dataType
{
    return [NSNumber numberWithInteger:dataType];
}


- (void)addObserver:(NSObject *)observer selector:(SEL)aSelector dataType:(ObserverType)dataType
{
    [_lock lock];
    if (!_observeres) {
        _observeres = [NSMutableDictionary dictionary];
    }
    
    NSNumber * key = [self numberWithObserverType:dataType];
    NSMutableArray * array = [_observeres objectForKey:key];
    if (!array) {
        array = [NSMutableArray array];
        [_observeres setObject:array forKey:key];
    }
    
    CTargetAction * ta = [[CTargetAction alloc] init];
    ta.target = observer;
    ta.action = aSelector;
    [array addObject:ta];
    
    [_lock unlock];
}

- (void)removeObserver:(NSObject *)observer dataType:(ObserverType)dataType
{
    [_lock lock];
    
    NSNumber * key = [self numberWithObserverType:dataType];
    NSMutableArray * array = [_observeres objectForKey:key];
    if (array) {
        for (NSInteger i = (array.count -1); i > 0; i--) {
            CTargetAction * ta = [array objectAtIndex:i];
            if (ta.target == observer) {
                [array removeObjectAtIndex:i];
            }
        }
    }
    
    [_lock unlock];
}
*/

//返回主要属性的当前值
#pragma mark - Open Property

- (float)minISO
{

    return self.avCaptureDevice.activeFormat.minISO;
 
}

- (float)maxISO
{
    
    return self.avCaptureDevice.activeFormat.maxISO;
  
}

- (float)currentISOValue
{
    return _currentISOValue;
}


- (float)minExposureBias
{
    return self.avCaptureDevice.minExposureTargetBias;
}

- (float)maxExposureBias
{
    return self.avCaptureDevice.maxExposureTargetBias;
}

- (float)currentExposureBias
{
    return _currentExposureBias;
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

- (FlameRate)currentFrameRate
{
    
    Float64 maxFR = 0.0;
    Float64 minFR = 0.0;
    NSArray * array  = self.avCaptureDevice.activeFormat.videoSupportedFrameRateRanges;

    for (AVFrameRateRange * range in array) {
        if (range.maxFrameRate > maxFR) {
            maxFR = range.maxFrameRate;
        }
    }
   
    
    for (AVFrameRateRange * range in array) {
        if (range.minFrameRate < minFR) {
            minFR = range.minFrameRate;
        }
    }
    
    FlameRate flameRate;
    flameRate.maxFrameRate = maxFR;
    flameRate.minFrameRate = minFR;
    return flameRate;
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

//聚焦模式
- (FocusMode)currentFocusMode
{
    switch (self.avCaptureDevice.focusMode) {
        case AVCaptureFocusModeLocked:
            return FocusModeLocked;
            break;
        case AVCaptureFocusModeAutoFocus:
        case AVCaptureFocusModeContinuousAutoFocus:
            return FocusModeContinuousAutoFocus;
            break;
        
    }
}

//
- (WhiteBalanceMode)currentWBMode
{
    switch (self.avCaptureDevice.whiteBalanceMode) {
        case AVCaptureWhiteBalanceModeLocked:
            return WhiteBalanceModeLocked;
            break;
        case AVCaptureWhiteBalanceModeAutoWhiteBalance:
        case AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance:
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
    return _currentExposureDuration;
}


- (FilterShowMode)currentFilterMode
{
    return _currentFilterMode;
}

- (ResolutionMode)currentPixel
{
    return _currentPixel;
}

- (BOOL)curentDoubleExposureState
{
    return _openDoubleExposure;
}

#pragma mark - SetUp AVFoundation

//开启或关闭滤镜
- (void)openOrCloseFilter:(BOOL)openOrcloseFilter
{
    if (openOrcloseFilter) {
        _openDoubleExposure = NO;
        _openOrcloseFilter = YES;
        self.filterLayer.contents = nil;
        [self setUpCIContext];
        [self setUpCustomFilterMode:self.currentFilterMode];
    }else{
        _openOrcloseFilter = NO;
        self.customFilter = nil;
        self.ciContext = nil;
        self.filterLayer.contents = nil;
    }
}

//开启或关闭双重曝光
- (void)openDoubleExposure:(BOOL)isOpenDoubleExposure
{
    if (isOpenDoubleExposure) {
        _openOrcloseFilter = NO;
        _openDoubleExposure = YES;
        [self setUpCIContext];
        _isFirstCameraOK = YES;
        _isSecondCameraOK = NO;
        self.filterLayer.contents = nil;
    }else{
        _openDoubleExposure = NO;
        self.ciContext = nil;
        self.filterLayer.contents = nil;
    }
}

- (void)setUpCIContext
{
    if (!self.ciContext) {
        EAGLContext * eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
        self.ciContext = [CIContext contextWithEAGLContext:eaglContext
                                            options:nil];
    }
}

//设置滤镜
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
    
    NSDictionary * dict = @{@"value":@(_currentFilterMode)};
    [[NSNotificationCenter defaultCenter] postNotificationName:kFilterModeNotificationKey object:self userInfo:dict];
    
    if (filterName == nil) {
        self.customFilter = nil;
    }else{
        self.customFilter = [CIFilter filterWithName:filterName];
    }
    
    
}

//设置各种模式的初始状态
- (void)setDefaultModes
{
    [self setFocusMode:FocusModeContinuousAutoFocus];
    [self setExposure:ExposureModeContinuousAutoExposure];
    //设置分辨率
    [self setFlashMode:FlashModeOff];
    [self setResolutionMode:ResolutionModeDefault];
    //关闭滤镜
    [self openOrCloseFilter:NO];
    [self openDoubleExposure:NO];
}

//设置设备
- (void)setUpCaptureDevice
{
    if (!self.avCaptureDevice) {
        self.avCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        [self setDefaultModes];
    }

}

//设置设备输入
- (void)setUpDeviceInput
{
    if (!self.avDeviceInput) {
        [self setUpCaptureDevice];
        NSError * error = nil;
        self.avDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.avCaptureDevice error:&error];
    }
   
}

//创建静态图片的输出
- (void)setUpStillImageOutPut
{
    if (!self.stillImageOutput) {
        self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    }
    
    NSDictionary * outputSetting = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSetting];
    
}

//创建video的输出
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
    

    //设置输入设备
    [self setUpDeviceInput];
    if ([self.avCaptureSession canAddInput:self.avDeviceInput]) {
        [self.avCaptureSession addInput:self.avDeviceInput];
    }
    
    
    //设置不同的输出
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
    //设置AVCaptureSession
    [self setUpCaptureSession];
    
//    [self focusWithMode:FocusModeContinuousAutoFocus exposeWithMode:ExposureModeContinuousAutoExposure whiteBalanceMode:WhiteBalanceModeContinuousAutoWhiteBalance monitorSubjectAreaChange:NO];
    
    //拍照显示层
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.avCaptureSession];
    self.previewLayer.frame = preView.bounds;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [preView.layer addSublayer:self.previewLayer];
    
    //设置滤镜显示层
    self.filterLayer = [CALayer layer];
    self.filterLayer.frame = self.previewLayer.bounds;
    [preView.layer insertSublayer:self.filterLayer above:self.previewLayer];
    
}


//注销
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

//静态图片拍照
- (void)cameraImageOK
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
    
    __weak __typeof(&*self)weakSelf = self;
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        if (error) {
            NSLog(@"camera error: %@",error);
        }
    
        NSData * imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
    
        [weakSelf stopVideo];
        if (weakSelf.imageBlock) {
            weakSelf.imageBlock(imageData);
 
        }
        [weakSelf startVideo];
        
    }];
}

- (void)runStillImageCaptureAnimaiton
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.previewLayer setOpacity:0];
        [UIView animateWithDuration:.25 animations:^{
            [self.previewLayer setOpacity:1.0];
        }];
    });
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
            [self.avCaptureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
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
- (void)setExposureDuration:(double)duration
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
    
        //重新设置各种模式
        [self setDefaultModes];
    
        
        //切换镜头后，需要重新设置输入
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

//镜头远近
- (void)setLensPosition:(float)len
{
    NSError * error = nil;
    if ([self.avCaptureDevice lockForConfiguration:&error]) {
        [self.avCaptureDevice setFocusModeLockedWithLensPosition:len completionHandler:nil];
        [self.avCaptureDevice unlockForConfiguration];
    }
}

//曝光档数偏移
- (void)setExposureTargetBias:(float)bias
{
    NSError * error = nil;
    if ([self.avCaptureDevice lockForConfiguration:&error]) {
        [self.avCaptureDevice setExposureTargetBias:bias completionHandler:nil];
        [self.avCaptureDevice unlockForConfiguration];
    }
}

- (AVCaptureWhiteBalanceGains)normalizedGains:(AVCaptureWhiteBalanceGains) gains
{
    AVCaptureWhiteBalanceGains g = gains;
    
    g.redGain = MAX(1.0, g.redGain);
    g.greenGain = MAX(1.0, g.greenGain);
    g.blueGain = MAX(1.0, g.blueGain);
    
    g.redGain = MIN(self.avCaptureDevice.maxWhiteBalanceGain, g.redGain);
    g.greenGain = MIN(self.avCaptureDevice.maxWhiteBalanceGain, g.greenGain);
    g.blueGain = MIN(self.avCaptureDevice.maxWhiteBalanceGain, g.blueGain);
    
    return g;
}


- (void)setWhiteBalanceGains:(AVCaptureWhiteBalanceGains)gains
{
    NSError * error = nil;
    if ([self.avCaptureDevice lockForConfiguration:&error]) {
        AVCaptureWhiteBalanceGains norgains = [self normalizedGains:gains];
        [self.avCaptureDevice setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains:norgains completionHandler:nil];
        [self.avCaptureDevice unlockForConfiguration];
    }
}

//设置色温和色彩
- (void)setTemperature:(float)temperature tint:(float)tint
{
    AVCaptureWhiteBalanceTemperatureAndTintValues temperatureAndTint = {
        .temperature = temperature,
        .tint        = tint,
    };
    
    [self setWhiteBalanceGains:[self.avCaptureDevice deviceWhiteBalanceGainsForTemperatureAndTintValues:temperatureAndTint]];
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



//设置帧率
- (void)setFrameRate:(double)desiredFrameRate
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


//确认帧率设备是否支持
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

    if (_openOrcloseFilter) {
        
        [self.avCaptureSession stopRunning];
        CGImageRef cgImageRef = [self.ciContext createCGImage:self.outPutImage fromRect:[self.outPutImage extent]];
        UIImage * image = [UIImage imageWithCGImage:cgImageRef];
        NSData * imageData = UIImagePNGRepresentation(image);
        
        if (self.imageBlock) {
           self.imageBlock(imageData);
        }
    
        [self.avCaptureSession startRunning];
        
    }else if (_openDoubleExposure){
        if (_isFirstCameraOK) {
            [self.avCaptureSession stopRunning];
            
            CGImageRef cgImageRef = [self.ciContext createCGImage:self.outPutImage fromRect:[self.outPutImage extent]];
            
            UIImage * image = [UIImage imageWithCGImage:cgImageRef];
            
            if (image) {
                UIImage * frontImage = [self imageByApplyingAlpha:0.5 image:image];
                self.frontImage = image;
                self.filterLayer.contents = (__bridge id)([frontImage CGImage]);
                CGImageRelease(cgImageRef);
                
            }
            
            
            _isFirstCameraOK = NO;
            _isSecondCameraOK = YES;
            [self.avCaptureSession startRunning];
            
            
        }else if(_isSecondCameraOK){
            
            [self.avCaptureSession stopRunning];
            
            CGImageRef cgImageRef = [self.ciContext createCGImage:self.outPutImage fromRect:[self.outPutImage extent]];
            
            UIImage * image = [UIImage imageWithCGImage:cgImageRef];
            
            CGImageRelease(cgImageRef);
            
            
            if (image) {
                
                UIImage * resultImage = [self processUsingPixels:image];
                NSData * imageData = UIImagePNGRepresentation(resultImage);
                
                if (self.imageBlock) {
                    self.imageBlock(imageData);
                }
            
            }
            
            _isFirstCameraOK = YES;
            _isSecondCameraOK = NO;
            [self.avCaptureSession startRunning];
            self.filterLayer.contents = nil;
        }

    }else{
        
    
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
        
        if (_isFirstCameraOK || _isSecondCameraOK) {

            
           
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
            
            
        }else{
        
    
            
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


//合成两张图片
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

static NSString * const StillImageOutputKey     = @"stillImageOutput.capturingStillImage";
static NSString * const ExposureModeKey         = @"avDeviceInput.device.exposureMode";
static NSString * const ExposureDurationKey     = @"avDeviceInput.device.exposureDuration";
static NSString * const ExposureTargetOffsetKey = @"avDeviceInput.device.exposureTargetOffset";
static NSString * const ExposureTargetBiasKey   = @"avDeviceInput.device.exposureTargetBias";
static NSString * const ISOChangeKey            = @"avDeviceInput.device.ISO";
static NSString * const LensPositionKey         = @"avDeviceInput.device.lensPosition";
static NSString * const WhiteBalanceModeKey     = @"avDeviceInput.device.whiteBalanceMode";
static NSString * const WhiteBalanceGainsKey       = @"avDeviceInput.device.deviceWhiteBalanceGains";
static NSString * const FocusModeKey            = @"avDeviceInput.device.focusMode";



static void * StillImageOutputContext           = &StillImageOutputContext;
static void * ExposureModeContext               = &ExposureModeContext;
static void * ExposureDurationContext           = &ExposureDurationContext;
static void * ExposureTargetOffsetContext       = &ExposureTargetOffsetContext;
static void * ExposureTargetBiasContext         = &ExposureTargetBiasContext;
static void * ISOContext                        = &ISOContext;
static void * LensPositionContext               = &LensPositionContext;
static void * WhiteBalanceModeContext           = &WhiteBalanceModeContext;
static void * WhiteBalanceGainsContext          = &WhiteBalanceGainsContext;
static void * FocusModeContext                  = &FocusModeContext;

- (void)addObservers
{
    [self addObserver:self forKeyPath:StillImageOutputKey options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:StillImageOutputContext];
    [self addObserver:self forKeyPath:ExposureModeKey options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:ExposureModeContext];
    [self addObserver:self forKeyPath:ExposureDurationKey options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:ExposureDurationContext];
    [self addObserver:self forKeyPath:ExposureTargetOffsetKey options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:ExposureTargetOffsetContext];
    [self addObserver:self forKeyPath:ExposureTargetBiasKey options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:ExposureTargetBiasContext];
    [self addObserver:self forKeyPath:ISOChangeKey options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:ISOContext];
    [self addObserver:self forKeyPath:LensPositionKey options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:LensPositionContext];
    [self addObserver:self forKeyPath:WhiteBalanceModeKey options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:WhiteBalanceModeContext];
    [self addObserver:self forKeyPath:WhiteBalanceGainsKey options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:WhiteBalanceGainsContext];
    [self addObserver:self forKeyPath:FocusModeKey options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:FocusModeContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:nil];

}

- (void)removeObservers
{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:nil];
    [self removeObserver:self forKeyPath:StillImageOutputKey context:StillImageOutputContext];
    [self removeObserver:self forKeyPath:ExposureModeKey context:ExposureModeContext];
    [self removeObserver:self forKeyPath:ExposureDurationKey context:ExposureDurationContext];
    [self removeObserver:self forKeyPath:ExposureTargetOffsetKey context:ExposureTargetOffsetContext];
    [self removeObserver:self forKeyPath:ExposureTargetBiasKey context:ExposureTargetBiasContext];
    [self removeObserver:self forKeyPath:ISOChangeKey context:ISOContext];
    [self removeObserver:self forKeyPath:LensPositionKey context:LensPositionContext];
    [self removeObserver:self forKeyPath:WhiteBalanceModeKey context:WhiteBalanceModeContext];
    [self removeObserver:self forKeyPath:WhiteBalanceGainsKey context:WhiteBalanceGainsContext];
    [self removeObserver:self forKeyPath:FocusModeKey context:FocusModeContext];
    //可以添加activeVideoMaxFrameDuration和activeVideoMinFrameDuration的观察。
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == StillImageOutputContext) {
        
//        BOOL isStillImageCapture = [change[NSKeyValueChangeNewKey] boolValue];
//        if (isStillImageCapture) {
//            [self  runStillImageCaptureAnimaiton];
//        }
        
    }else if (context == ExposureModeContext) {
        AVCaptureExposureMode oldMode = [change[NSKeyValueChangeOldKey] intValue];
        AVCaptureExposureMode newMode = [change[NSKeyValueChangeNewKey] intValue];
        
        NSInteger value;
        if (newMode == AVCaptureExposureModeLocked) {
            value = 0;
        }else if (newMode == AVCaptureExposureModeContinuousAutoExposure){
            value = 1;
        }else if(newMode == AVCaptureExposureModeCustom){
            value = 2;
        }else{
            value = 1;
        }
        
        NSDictionary * dict = @{@"value":@(value)};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kExposureModeNotificationKey object:self userInfo:dict];
        
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
            
            NSDictionary * dict = @{@"value":@(returnValue)};
            [[NSNotificationCenter defaultCenter] postNotificationName:kExposureDurationNotificationKey object:self userInfo:dict];
        }
        
        
        
    }else if (context == ExposureTargetOffsetContext){
        float newExposureTargetOffset = [change[NSKeyValueChangeNewKey] floatValue];
        
        NSDictionary * dict = @{@"value":@(newExposureTargetOffset)};
        [[NSNotificationCenter defaultCenter] postNotificationName:kExposureTargetOffsetNotificationKey object:self userInfo:dict];
        
    }else if (context == ExposureTargetBiasContext){
        float exposureBias = [change[NSKeyValueChangeNewKey] floatValue];
        self.currentExposureBias = exposureBias;
        
        NSDictionary * dict = @{@"value":@(exposureBias)};
        [[NSNotificationCenter defaultCenter] postNotificationName:kExposureTargetBiasNotificationKey object:self userInfo:dict];
        
    }else if (context == ISOContext){
    
        float newISO = [change[NSKeyValueChangeNewKey] floatValue];
        if (self.avCaptureDevice.exposureMode != AVCaptureExposureModeCustom) {
            //这里返回一个当前的ISO值。newISO
            
            self.currentISOValue = newISO;
            
            NSDictionary * dict = @{@"value":@(newISO)};
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kISOChangeNotificationKey object:self userInfo:dict];
            
        }
        
    }else if (context == LensPositionContext){
    
        float newLensPosition = [change[NSKeyValueChangeNewKey] floatValue];
        NSDictionary * dict = @{@"value":@(newLensPosition)};
    
        [[NSNotificationCenter defaultCenter] postNotificationName:kLensPositionNotificationKey object:self userInfo:dict];
        
        
    }else if (context == WhiteBalanceModeContext){
        AVCaptureWhiteBalanceMode newMode = [change[NSKeyValueChangeNewKey] intValue];
        
        NSInteger value;
        if (newMode == AVCaptureWhiteBalanceModeLocked) {
            value = 0;
        }else{
            value = 1;
        }
        
        NSDictionary * dict = @{@"value":@(value)};
        [[NSNotificationCenter defaultCenter] postNotificationName:kWhiteBalanceModeNotificationKey object:self userInfo:dict];
        
    }else if (context == WhiteBalanceGainsContext){
    
        AVCaptureWhiteBalanceGains newGains;
        [change[NSKeyValueChangeNewKey] getValue:&newGains];
        AVCaptureWhiteBalanceTemperatureAndTintValues newTemperatureAndTint = [self.avCaptureDevice temperatureAndTintValuesForDeviceWhiteBalanceGains:newGains];
        
        if (self.avCaptureDevice.whiteBalanceMode != AVCaptureWhiteBalanceModeLocked) {
            NSInteger valueTemp = newTemperatureAndTint.temperature;
            NSInteger valueTint = newTemperatureAndTint.tint;
            
            NSDictionary * dict = @{@"value1":@(valueTemp),@"value2":@(valueTint)};
            [[NSNotificationCenter defaultCenter] postNotificationName:kWhiteBalanceGainsNotificationKey object:self userInfo:dict];
        }
        
    }else if (context == FocusModeContext){
        
        AVCaptureFocusMode newMode = [change[NSKeyValueChangeNewKey] intValue];
        
        NSInteger value;
        if (newMode == AVCaptureExposureModeLocked) {
            value = 0;
        }else{
            value = 1;
        }
        
        NSDictionary * dict = @{@"value":@(value)};
        [[NSNotificationCenter defaultCenter] postNotificationName:kFocusModeNotificationKey object:self userInfo:dict];

    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
    

    
}


/*
- (void)handleResponseObserverTypeInfo:(NSDictionary *)infoDict
{
    [_lock lock];
    
    ObserverType type = (ObserverType)[[infoDict objectForKey:@"type"] integerValue];
    NSArray * observers = [_observeres objectForKey:[self numberWithObserverType:type]];
    
    for (CTargetAction * ta in observers) {
        if ([ta.target respondsToSelector:ta.action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [ta.target performSelector:ta.action withObject:infoDict];
#pragma clang diagnostic pop
        }
    }
    
    
    [_lock unlock];
}
*/



@end
