//
//  CameraViewModeClass.h
//  CameraDemo
//
//  Created by pinguo on 15/3/25.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "ViewModelClass.h"

@class UIViewController;
@class UIImage;
@interface CameraViewModeClass : ViewModelClass

/**
 *  推送到相册界面
 *
 *  @param superViewController
 */
- (void)photoDetailWithViewController:(UIViewController * )superViewController;

/**
 *  存储某张照片
 *
 *  @param image
 *  @param albumTitle 相册名称
 */
- (void)saveImage:(UIImage *)image WithAblumTitle:(NSString *)albumTitle;

/**
 *  得到最新的一张照片用于展示
 *
 *  @return UIImage
 */
- (UIImage *)getImage;

@end
