//
//  CameraView.h
//  CameraDemo
//
//  Created by pinguo on 15/3/26.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVCaptureSession;

@interface CameraView : UIView

@property (nonatomic) AVCaptureSession * session;

@end
