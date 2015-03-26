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

//闪光
typedef enum {
    FlashModeOff          = 0,    
    FlashModeOn           = 1,
    FlashModeAtuo         = 2,
}FlashMode;

//曝光
typedef enum {
    ExposureModeLocked                      = 0,
    ExposureModeAutoExpose                  = 1,
    ExposureModeContinuousAutoExposure      = 2,
    ExposureModeCustom                      = 3
}ExposureMode;

//白平衡
typedef enum {
    WhiteBalanceModeLocked                          = 0,
    WhiteBalanceModeAutoWhiteBalance                = 1,
    WhiteBalanceModeContinuousAutoWhiteBalance      = 2
}WhiteBalanceMode;

//聚焦
typedef enum {
    FocusModeLocked                     = 0,
    FocusModeAutoFocus                  = 1,
    FocusModeContinuousAutoFocus        = 2,

}FocusMode;

//分辨率,有多种，这里用四种。
typedef enum {
    ResolutionModeDefault               = 0,   //默认AVCaptureSessionPresetPhoto
    ResolutionModeLow                   = 1,
    ResolutionModeMedium                = 2,
    ResolutionModeHigh                  = 3,
}ResolutionMode;



typedef void (^CameraImageBlock)(NSData * imageData);

@interface AVFoundationHandler : NSObject
{
    CMBufferQueueRef previewBufferQueue;
   // float effectiveScale;
}

@property (nonatomic, strong) CameraImageBlock imageBlock;

@property (nonatomic, readonly) float minISO;
@property (nonatomic, readonly) float maxISO;
@property (nonatomic, strong, readonly) AVCaptureSession * avCaptureSession;

+ (instancetype)shareInstance;


- (void)setCameraOKImageBlock:( void(^)(NSData * imageData)) imageBlock;

/**
 *  可以直接调用session现实相机
 *
 *  @return 返回一个创建好的AVCaptureSession
 */
- (AVCaptureSession *)captureSession;

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
- (void)cameraOK;


/**
 *  切换镜头
 *
 *  @param backOrFront YES，后面的镜头，NO，前面的镜头
 */
- (void)setDevicePosition:(BOOL)backOrFront;

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
 *  @param duration float [0,1]
 */
- (void)setExposureDuration:(float)duration;

/**
 *  ISO
 *
 *  @param isoValue float [minISO,maxISO]
 */
- (void)setISO:(float)isoValue;










@end
