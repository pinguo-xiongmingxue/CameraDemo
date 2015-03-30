//
//  FrameRateSetVC.h
//  CameraDemo
//
//  Created by pinguo on 15/3/28.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FrameRateSetVC;
@protocol FrameRateSetVCDelegate <NSObject>

- (void)frameRateSetVCClosed:(FrameRateSetVC *)frameRateSetVC;

@end

@interface FrameRateSetVC : UIViewController

@property (nonatomic, assign) id<FrameRateSetVCDelegate> delegate;

@end
