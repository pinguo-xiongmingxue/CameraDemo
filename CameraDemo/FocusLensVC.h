//
//  FocusLensVC.h
//  CameraDemo
//
//  Created by pinguo on 15/4/1.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FocusLensVC;

@protocol FocusLensVCDelegate <NSObject>

- (void)focusLensVCClosed:(FocusLensVC *)focusLensVC;

@end


@interface FocusLensVC : UIViewController

@property (nonatomic, assign) id<FocusLensVCDelegate> delegate;

@end
