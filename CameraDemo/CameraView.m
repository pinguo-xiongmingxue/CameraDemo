//
//  CameraView.m
//  CameraDemo
//
//  Created by pinguo on 15/3/26.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "CameraView.h"
#import "CommonDefine.h"
#import "AVFoundationHandler.h"

@interface CameraView ()<UIGestureRecognizerDelegate>

@property (nonatomic, strong) CALayer * focusBox;   // 聚焦layer
@property (nonatomic, strong) CALayer * exposeBox;  // 曝光layer
@end

@implementation CameraView


- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.userInteractionEnabled = YES;
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
    [self addGestureRecognizer:tap];
    
    UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(hanldePanGestureRecognizer:)];
    [pan setDelaysTouchesEnded:NO];
    [pan setMinimumNumberOfTouches:1];
    [pan setMaximumNumberOfTouches:1];
    [pan setDelegate:self];
    [self addGestureRecognizer:pan];
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
    
    //YES 测焦   NO  测光
    if (isFocusOrLight) {
        [self drawLayer:self.exposeBox atPointOfInterest:point andRemove:YES];
        [[AVFoundationHandler shareInstance] setExposureX:point.x exposureY:point.y];
       
    }else{
        [self drawLayer:self.focusBox atPointOfInterest:point andRemove:YES];
        [[AVFoundationHandler shareInstance] setFocus:point.x focusy:point.y];
    }
}

- (void) hanldePanGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer
{
    BOOL isFocusOrLight = NO;
    if ([_delegate respondsToSelector:@selector(isFocusOrLightTest:)]) {
        [_delegate isFocusOrLightTest:&isFocusOrLight];
    }
    
    UIGestureRecognizerState state = panGestureRecognizer.state;
    CGPoint touchPoint = [panGestureRecognizer locationInView:self];
    
    //YES 测焦   NO  测光
    if (isFocusOrLight) {
        [self drawLayer:self.exposeBox atPointOfInterest:touchPoint andRemove:YES];
        [[AVFoundationHandler shareInstance] setExposureX:touchPoint.x exposureY:touchPoint.y];
        
    }else{
        [self drawLayer:self.focusBox atPointOfInterest:touchPoint andRemove:YES];
        [[AVFoundationHandler shareInstance] setFocus:touchPoint.x focusy:touchPoint.y];
    }
    
    switch (state) {
        case UIGestureRecognizerStateBegan:
            
            break;
        case UIGestureRecognizerStateChanged: {
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateEnded: {
            [self tapGesture:panGestureRecognizer];
            break;
        }
        default:
            break;
    }
}





@end
