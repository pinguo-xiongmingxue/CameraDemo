//
//  WhiteBalanceSetVC.m
//  CameraDemo
//
//  Created by pinguo on 15/4/1.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "WhiteBalanceSetVC.h"
#import "AVFoundationHandler.h"

@interface WhiteBalanceSetVC ()
@property (weak, nonatomic) IBOutlet UIButton *closeBtn;

@property (weak, nonatomic) IBOutlet UISegmentedControl *whiteBalanceModeBtn;

@property (weak, nonatomic) IBOutlet UISlider *temperatureBtn;

@property (weak, nonatomic) IBOutlet UISlider *tintBtn;

@end

@implementation WhiteBalanceSetVC

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //注册白平衡mode改变，Gains改变的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(whiteBalanceModeChanged:) name:kWhiteBalanceModeNotificationKey object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(whiteBalanceGainsChanged:) name:kWhiteBalanceGainsNotificationKey object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kWhiteBalanceModeNotificationKey object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kWhiteBalanceGainsNotificationKey object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSInteger mode;
    mode = [[AVFoundationHandler shareInstance] currentWBMode];
    self.whiteBalanceModeBtn.selectedSegmentIndex = mode;
    
    [self.temperatureBtn setMaximumValue:8000];
    [self.temperatureBtn setMinimumValue:3000];
    
    [self.tintBtn setMaximumValue:150];
    [self.tintBtn setMinimumValue:-150];
    
    if (mode == 0) {
        self.temperatureBtn.enabled = YES;
        self.tintBtn.enabled = YES;
    }else{
        self.temperatureBtn.enabled = NO;
        self.temperatureBtn.enabled = NO;
    }
    
    
}

#pragma mark - Notification

- (void)whiteBalanceModeChanged:(NSNotification *)notification
{
    NSDictionary * dict = [notification userInfo];
    NSInteger mode = [dict[@"value"] integerValue];
    self.whiteBalanceModeBtn.selectedSegmentIndex = mode;
    if (mode == 0) {
        self.temperatureBtn.enabled = YES;
        self.tintBtn.enabled = YES;
    }else{
        self.temperatureBtn.enabled = NO;
        self.temperatureBtn.enabled = NO;
    }
}

- (void)whiteBalanceGainsChanged:(NSNotification *)notification
{
    NSDictionary * dict = [notification userInfo];
    float temp = [dict[@"value1"] floatValue];
    float tint = [dict[@"value2"] floatValue];
    [self.temperatureBtn setValue:temp animated:YES];
    [self.tintBtn setValue:tint animated:YES];
    
}

#pragma mark - btn action

- (IBAction)closeBtnClick:(id)sender
{
    if ([_delegate respondsToSelector:@selector(whiteBalanceSetVCClosed:)]) {
        [_delegate whiteBalanceSetVCClosed:self];
    }
}

- (IBAction)whiteBalanceModeBtnClick:(id)sender
{
    UISegmentedControl * seg = sender;
    [[AVFoundationHandler shareInstance] setWhiteBanlance:(WhiteBalanceMode)seg.selectedSegmentIndex];
}

- (IBAction)temperatureBtnClick:(id)sender
{
    UISlider * slider = sender;
    [[AVFoundationHandler shareInstance] setTemperature:slider.value tint:self.tintBtn.value];
}

- (IBAction)tintBtnClick:(id)sender
{
     UISlider * slider = sender;
    [[AVFoundationHandler shareInstance] setTemperature:self.temperatureBtn.value tint:slider.value];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}






@end
