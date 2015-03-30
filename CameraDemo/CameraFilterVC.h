//
//  CameraFilterVC.h
//  CameraDemo
//
//  Created by pinguo on 15/3/30.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import <UIKit/UIKit.h>


@class CameraFilterVC;

@protocol CameraFilterVCDelegate <NSObject>

- (void)cameraFilterVCClosed:(UIViewController *)cameraFilterVC;

@end

@interface CameraFilterVC : UIViewController

@property (nonatomic, assign) id<CameraFilterVCDelegate> delegate;


@end
