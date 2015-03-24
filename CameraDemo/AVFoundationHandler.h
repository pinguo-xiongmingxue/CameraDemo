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


@protocol AVFoundationHandlerDelegate <NSObject>

- (void)postImageData:(NSData *)imageData;

@end

@interface AVFoundationHandler : NSObject
{
   // CMBufferQueueRef previewBufferQueue;
    float effectiveScale;
}

@property (nonatomic, strong) AVCaptureSession * avCaptureSession;
@property (nonatomic, strong) AVCaptureDevice * avCaptureDevice;
@property (nonatomic, strong) AVCaptureStillImageOutput * stillImageOutput;
//@property (nonatomic, strong) AVCaptureVideoDataOutput * stillVideoOutput;
@property (nonatomic, strong) AVCaptureDeviceInput * avDeviceInput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer * previewLayer;

@property (nonatomic, assign) id<AVFoundationHandlerDelegate> delegate;

+ (instancetype)shareInstance;

- (void)initAVFoundationHandlerWithView:(UIView *)preView;

- (void)startVideo;
- (void)stopVideo;
- (void)cameraOK;


@end
