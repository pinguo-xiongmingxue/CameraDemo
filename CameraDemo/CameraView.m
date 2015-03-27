//
//  CameraView.m
//  CameraDemo
//
//  Created by pinguo on 15/3/26.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "CameraView.h"
#import "AVFoundationHandler.h"

@interface CameraView ()<UIGestureRecognizerDelegate>

@end

@implementation CameraView


- (void)awakeFromNib
{
    [super awakeFromNib];
    self.userInteractionEnabled = YES;
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
    [self addGestureRecognizer:tap];
}

- (CGFloat)selfWidth
{
    return self.frame.size.width;
}

- (CGFloat)selfHeight
{
    return self.frame.size.height;
}


- (void)tapGesture:(UIGestureRecognizer *)gesture
{
    CGPoint point = [gesture locationInView:self];
    
//     __weak __typeof(&*self)weakSelf = self;
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [weakSelf addfocusView:point];
//    });
    [self addfocusView:point];
}

- (void)addfocusView:(CGPoint)point
{
    self.foucusImageView = [[UIImageView alloc] initWithFrame:CGRectMake(point.x - 40, point.y - 40, 80, 80)];
    self.foucusImageView.image = [UIImage imageNamed:@"camera_foucs"];
    [self addSubview:self.foucusImageView];
    
    [UIView animateWithDuration:0.7 animations:^{
        self.foucusImageView.frame = CGRectMake(point.x-20, point.y-20, 40, 40);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:1.0 animations:^{
            [self.foucusImageView removeFromSuperview];
        }];
    }];
    
   
  //  [[AVFoundationHandler shareInstance] setFocus:point.x focusy:point.y];
    [[AVFoundationHandler shareInstance] setExposureX:point.x exposureY:point.y];
    
}






@end
