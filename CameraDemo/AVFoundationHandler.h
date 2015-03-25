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



@protocol AVFoundationHandlerDelegate <NSObject>

- (void)postImageData:(NSData *)imageData;
@end

@interface AVFoundationHandler : NSObject
{
    CMBufferQueueRef previewBufferQueue;
    float effectiveScale;
}

@property (nonatomic, strong) AVCaptureSession * avCaptureSession;
@property (nonatomic, strong) AVCaptureDevice * avCaptureDevice;
@property (nonatomic, strong) AVCaptureStillImageOutput * stillImageOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput * videoDataOutput;
@property (nonatomic, strong) AVCaptureDeviceInput * avDeviceInput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer * previewLayer;

@property (nonatomic, assign) id<AVFoundationHandlerDelegate> delegate;

+ (instancetype)shareInstance;

- (void)initAVFoundationHandlerWithView:(UIView *)preView;

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
 *  @param flashMode 枚举类型
 */
- (void)setFlashMode:(FlashMode)flashMode;

/**
 *  聚焦点设置
 *
 *  @param focusx 在x方向的值，范围【0，1】
 *  @param focusy 在y方向的值，范围【0，1】
 */
- (void)setFocus:(float)focusx focusy:(float)focusy;

/**
 *  曝光模式
 *
 *  @param exposureMode 其中用户自定义模式需要提供ISO和曝光时间
 */
- (void)setExposure:(ExposureMode)exposureMode;

/**
 *  白平衡模式
 *
 *  @param whiteBalanceMode 白平衡模式，还需要添加一种用户手动的模式，更改色温。
 */
- (void)setWhiteBanlance:(WhiteBalanceMode)whiteBalanceMode;

















@end
