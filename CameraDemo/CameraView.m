//
//  CameraView.m
//  CameraDemo
//
//  Created by pinguo on 15/3/26.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "CameraView.h"
//#import "AVFoundationHandler.h"
#import "CommonDefine.h"

@interface CameraView ()<UIGestureRecognizerDelegate>

@property (nonatomic, strong) CALayer * focusBox;
@property (nonatomic, strong) CALayer * exposeBox;
@end

@implementation CameraView


- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.userInteractionEnabled = YES;
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
    [self addGestureRecognizer:tap];
}

- (void)buildInterface
{
    UIView *focusView = [[UIView alloc] initWithFrame:self.frame];
    focusView.backgroundColor = [UIColor clearColor];
    [focusView.layer addSublayer:self.focusBox];
    [self addSubview:focusView];
    
    UIView *exposeView = [[UIView alloc] initWithFrame:self.frame];
    exposeView.backgroundColor = [UIColor clearColor];
    [exposeView.layer addSublayer:self.exposeBox];
    [self addSubview:exposeView];

    
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

- (CALayer *)focusBox
{
    if (!_focusBox) {
        _focusBox = [[CALayer alloc] init];
        [_focusBox setCornerRadius:45.0f];
        [_focusBox setBounds:CGRectMake(0.0f, 0.0f, 90, 90)];
        [_focusBox setBorderWidth:5.0f];
        [_focusBox setBorderColor:[RGBColor(0xffffff, 1) CGColor]];
        [_focusBox setOpacity:0];
    }
    return _focusBox;
}

- (CALayer *)exposeBox
{
    if (!_exposeBox) {
        _exposeBox = [[CALayer alloc] init];
        [_exposeBox setCornerRadius:55.0f];
        [_exposeBox setBounds:CGRectMake(0.0f, 0.0f, 110, 110)];
        [_exposeBox setBorderWidth:5.0f];
        [_exposeBox setBorderColor:[UIColor redColor].CGColor];
        [_exposeBox setOpacity:0];
    }
    return _exposeBox;
}

- (void)drawLayer:(CALayer *)layer atPointOfInterest:(CGPoint)point andRemove:(BOOL)remove
{
    if (remove) {
        [layer removeAllAnimations];
    }
    if ([layer animationForKey:@"transform.scale"] == nil && [layer animationForKey:@"opacity"] == nil) {
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        [layer setPosition:point];
        [CATransaction commit];
        
        CABasicAnimation * scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        [scale setFromValue:[NSNumber numberWithFloat:1]];
        [scale setToValue:[NSNumber numberWithFloat:0.7]];
        [scale setDuration:0.8];
        [scale setRemovedOnCompletion:YES];
        
        CABasicAnimation * opactiy = [CABasicAnimation animationWithKeyPath:@"opacity"];
        [opactiy setFromValue:[NSNumber numberWithFloat:1]];
        [opactiy setToValue:[NSNumber numberWithFloat:0]];
        [opactiy setDuration:0.8];
        [opactiy setRemovedOnCompletion:YES];
        
        [layer addAnimation:scale forKey:@"transform.scale"];
        [layer addAnimation:opactiy forKey:@"opacity"];
        
    }
    
}

- (void)tapGesture:(UIGestureRecognizer *)gesture
{
    CGPoint point = [gesture locationInView:self];
    
    BOOL isFocusOrLight = NO;
    if ([_delegate respondsToSelector:@selector(isFocusOrLightTest:)]) {
        [_delegate isFocusOrLightTest:&isFocusOrLight];
    }
    
    if (isFocusOrLight) {
         [self drawLayer:self.focusBox atPointOfInterest:point andRemove:YES];
    }else{
        [self drawLayer:self.exposeBox atPointOfInterest:point andRemove:YES];
    }
   
    // [self drawLayer:self.exposeBox atPointOfInterest:point andRemove:YES];
    
    //[self addfocusView:point];
}

- (void)addfocusView:(CGPoint)point
{
    self.foucusImageView = [[UIImageView alloc] initWithFrame:CGRectMake(point.x - 40, point.y - 40, 80, 80)];
    self.foucusImageView.image = [UIImage imageNamed:@"camera_foucs"];
    [self addSubview:self.foucusImageView];
    
    [UIView animateWithDuration:0.7 animations:^{
        self.foucusImageView.frame = CGRectMake(point.x-20, point.y-20, 40, 40);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.7 animations:^{
            [self.foucusImageView removeFromSuperview];
        }];
    }];
    
    if ([_delegate respondsToSelector:@selector(cameraViewTapedPoint:)]) {
        [_delegate cameraViewTapedPoint:point];
    }
   
    
}






@end
