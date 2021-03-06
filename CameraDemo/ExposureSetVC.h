//
//  ExposureSetVC.h
//  CameraDemo
//
//  Created by pinguo on 15/3/27.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ExposureSetVC;

@protocol ExposureSetVCDelegate <NSObject>

- (void)exposureSetVCClosed:(ExposureSetVC *)exposureVC;

@end

@interface ExposureSetVC : UIViewController

@property (nonatomic, assign) id<ExposureSetVCDelegate> delegate;


@end
