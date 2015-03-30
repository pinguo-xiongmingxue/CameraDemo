//
//  CameraView.h
//  CameraDemo
//
//  Created by pinguo on 15/3/26.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CameraViewDelegate <NSObject>

- (void)cameraViewTapedPoint:(CGPoint)point;

- (void)isFocusOrLightTest:(BOOL *)isFocusOrLight;

@end


@interface CameraView : UIView
{
   
}
@property (nonatomic, assign) id<CameraViewDelegate> delegate;
@property (nonatomic, strong) UIImageView * foucusImageView;


- (void)buildInterface;

@end
