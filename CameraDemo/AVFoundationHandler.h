//
//  AVFoundationHandler.h
//  CameraDemo
//
//  Created by pinguo on 15/3/24.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/CGImageProperties.h>
#import <CoreMedia/CMBufferQueue.h>
#import <AVFoundation/AVVideoSettings.h>
#import <UIKit/UIKit.h>
#import <CoreVideo/CVPixelBuffer.h>
#import <AVFoundation/AVMediaFormat.h>
#import <QuartzCore/QuartzCore.h>


//外部通知key
extern NSString * const kExposureModeNotificationKey;
extern NSString * const kExposureDurationNotificationKey;
extern NSString * const kExposureTargetOffsetNotificationKey;
extern NSString * const kExposureTargetBiasNotificationKey;
extern NSString * const kISOChangeNotificationKey;
extern NSString * const kLensPositionNotificationKey;
extern NSString * const kWhiteBalanceModeNotificationKey;
extern NSString * const kWhiteBalanceGainsNotificationKey;
extern NSString * const kFocusModeNotificationKey;
extern NSString * const kFilterModeNotificationKey;

//闪光
typedef enum {
    FlashModeOff          = 0,    
    FlashModeOn           = 1,
    FlashModeAtuo         = 2,
}FlashMode;

//曝光
typedef enum {
    ExposureModeLocked                      = 0,
    ExposureModeContinuousAutoExposure      = 1,
    ExposureModeCustom                      = 2
}ExposureMode;

//白平衡
typedef enum {
    WhiteBalanceModeLocked                          = 0,
    WhiteBalanceModeContinuousAutoWhiteBalance      = 1
}WhiteBalanceMode;

//聚焦
typedef enum {
    FocusModeLocked                     = 0,
    FocusModeContinuousAutoFocus        = 1,

}FocusMode;

//分辨率,有多种，这里用四种。
typedef enum {
    ResolutionModeDefault               = 0,   //默认AVCaptureSessionPresetPhoto
    ResolutionModeLow                   = 1,
    ResolutionModeMedium                = 2,
    ResolutionModeHigh                  = 3,
}ResolutionMode;

//实时滤镜
typedef enum {
    FilterShowModeNone                  = 0,
    FilterShowModeCustomFirst           = 1,
    FilterShowModeCustomSecond          = 2,
    FilterShowModeCustomThird           = 3
}FilterShowMode;

//typedef enum {
//    ObserverTypeFocusMode               = 0,
//    ObserverTypeFocusLens               = 1,
//
//}ObserverType;

typedef struct {
    Float64 maxFrameRate;
    Float64 minFrameRate;
}FlameRate;


typedef void (^CameraImageBlock)(NSData * imageData);
typedef void (^CameraVideoBlock)(BOOL *isOk);

@interface AVFoundationHandler : NSObject
{
 //   CMBufferQueueRef previewBufferQueue;
}

@property (nonatomic, strong) CameraImageBlock imageBlock;
@property (nonatomic, strong) CameraVideoBlock videoBlock;

@property (nonatomic, readonly) float minISO;
@property (nonatomic, readonly) float maxISO;
@property (nonatomic, readonly) float currentISOValue;
@property (nonatomic, readonly) float maxExposureBias;
@property (nonatomic, readonly) float minExposureBias;
@property (nonatomic, readonly) float currentExposureBias;
@property (nonatomic, readonly) double currentExposureDuration;
@property (nonatomic, readonly) NSInteger numbersOfSupportFormats;
@property (nonatomic, readonly) FlashMode currentFlashMode;
@property (nonatomic, readonly) ResolutionMode currentPixel;
@property (nonatomic, readonly) FocusMode currentFocusMode;
@property (nonatomic, readonly) ExposureMode currentExposureMode;
@property (nonatomic, readonly) WhiteBalanceMode currentWBMode;
@property (nonatomic, readonly) Float64 activeMaxFrameRate;
@property (nonatomic, readonly) Float64 activeMinFrameRate;
@property (nonatomic, readonly) FlameRate currentFrameRate;
@property (nonatomic, readonly) FilterShowMode currentFilterMode;
@property (nonatomic, readonly) BOOL curentDoubleExposureState;


+ (instancetype)shareInstance;


/**
 *  用于静态图片拍照
 *
 *  @param imageBlock
 */
- (void)setCameraOKImageBlock:( void(^)(NSData * imageData)) imageBlock;

/**
 *  用于实时滤镜和双重曝光相机拍照
 *
 *  @param videoBlock
 */
- (void)setCameraOKVideoBlock:(void(^)(BOOL *isOk)) videoBlock;

/**
 *  传入一个显示相机的view
 *
 *  @param preView
 */
- (void)setAVFoundationHandlerWithView:(UIView *)preView;

/**
 *  是否授权使用相机
 *
 *  @return YES，授权，NO，未授权
 */
+ (BOOL)isAuthorizatonToUseCamera;

/**
 *  启动相机
 */
- (void)startVideo;

/**
 *  停止相机
 */
- (void)stopVideo;

/**
 *  拍照，还需要添加模式，待定。
 */
- (void)cameraImageOK;

/**
 *  加滤镜的拍照
 */
- (void)cameraVideoOk;


/**
 *  切换镜头
 *
 */
- (void)setDevicePositionChange;

/**
 *  闪光模式
 *
 *  @param flashMode 枚举类型 默认NO
 */
- (void)setFlashMode:(FlashMode)flashMode;

/**
 *  曝光模式
 *
 *  @param exposureMode 其中用户自定义模式需要提供ISO和曝光时间
 */
- (void)setExposure:(ExposureMode)exposureMode;

/**
 *  白平衡模式
 *
 *  @param whiteBalanceMode 白平衡模式，？还需要添加一种用户手动的模式，更改色温。
 */
- (void)setWhiteBanlance:(WhiteBalanceMode)whiteBalanceMode;

/**
 *  聚焦模式
 *
 *  @param focusmode FocusMode枚举
 */
- (void)setFocusMode:(FocusMode)focusmode;

/**
 *  聚焦点设置
 *
 *  @param focusx 在x方向的值，范围[0，1]
 *  @param focusy 在y方向的值，范围[0，1]
 */
- (void)setFocus:(float)focusx focusy:(float)focusy;

/**
 *  测光点
 *
 *  @param exposureX 在x方向的值，范围[0，1]
 *  @param exposureY 在y方向的值，范围[0，1]
 */
- (void)setExposureX:(float)exposureX exposureY:(float)exposureY;

/**
 *  分辨率模式，共有四种，默认，低，中，高
 *
 *  @param resolution ResolutionMode模式的一种
 */
- (void)setResolutionMode:(ResolutionMode)resolution;

/**
 *  设置聚焦的距离
 *
 *  @param len float值。[0，1]
 */
- (void)setLensPosition:(float)len;

/**
 *  设置曝光时间
 *
 *  @param duration double [0,1]
 */
- (void)setExposureDuration:(double)duration;

/**
 *  ISO
 *
 *  @param isoValue float [minISO,maxISO]
 */
- (void)setISO:(float)isoValue;

/**
 *  设置色温和色彩
 *
 *  @param temperature 色温  【3000，8000】
 *  @param tint        色彩  【-150，150】
 */
- (void)setTemperature:(float)temperature tint:(float)tint;

/**
 *  曝光档数的目标偏移
 *
 *  @param bias bias description
 */
- (void)setExposureTargetBias:(float)bias;


/**
 *  帧率
 *
 *  @param desiredFrameRate 当前activeFormat，支持的帧率的数值的倒数
 */
- (void)setFrameRate:(double)desiredFrameRate;

/**
 *  在设备支持的所有格式中是否 有要设置的帧率的格式，如果有将activeFormat设置为这个格式
 *
 *  @param desiredFrameRate desiredFrameRate
 */
- (void)configureFrameRate:(int)desiredFrameRate;

/**
 *  是否开启实时滤镜
 *
 *  @param openOrcloseFilter YES，开启，默认FilterShowModeNone。
 */
- (void)openOrCloseFilter:(BOOL)openOrcloseFilter;

/**
 *  设置滤镜模式
 *
 *  @param mode
 */
- (void)setUpCustomFilterMode:(FilterShowMode)mode;


/**
 *  打开双重曝光
 *
 *  @param isOpenDoubleExposure
 */
- (void)openDoubleExposure:(BOOL)isOpenDoubleExposure;



//- (void)addObserver:(NSObject *)observer selector:(SEL)aSelector dataType:(ObserverType)dataType;
//
//- (void)removeObserver:(NSObject *)observer dataType:(ObserverType)dataType;

@end
