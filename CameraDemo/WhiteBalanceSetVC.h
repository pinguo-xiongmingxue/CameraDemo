//
//  WhiteBalanceSetVC.h
//  CameraDemo
//
//  Created by pinguo on 15/4/1.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WhiteBalanceSetVC;

@protocol WhiteBalanceSetVCDelegate <NSObject>

- (void)whiteBalanceSetVCClosed:(WhiteBalanceSetVC *)whiteBalanceSetVC;

@end


@interface WhiteBalanceSetVC : UIViewController

@property (nonatomic, assign) id<WhiteBalanceSetVCDelegate> delegate;

@end
