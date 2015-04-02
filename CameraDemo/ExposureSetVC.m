//
//  ExposureSetVC.m
//  CameraDemo
//
//  Created by pinguo on 15/3/27.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "ExposureSetVC.h"
#import "AVFoundationHandler.h"

static void * ExposureDurationContext = &ExposureDurationContext;

@interface ExposureSetVC ()

@property (weak, nonatomic) IBOutlet UIButton *closeBtn;

@property (weak, nonatomic) IBOutlet UISegmentedControl *exposureModeBtn;

@property (weak, nonatomic) IBOutlet UISlider *biasBtn;

@property (weak, nonatomic) IBOutlet UISlider *offsetBtn;

@property (weak, nonatomic) IBOutlet UISlider *iSOBtn;


@property (weak, nonatomic) IBOutlet UISlider *durationBtn;

@end

@implementation ExposureSetVC

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //注册曝光模式，ISO，曝光时间，曝光档数，曝光档数目标偏移的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exposureModeChanged:) name:kExposureModeNotificationKey object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iOSChanged:) name:kISOChangeNotificationKey object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(durationChanged:) name:kExposureDurationNotificationKey object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(offsetChanged:) name:kExposureTargetOffsetNotificationKey object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(biasChanged:) name:kExposureTargetBiasNotificationKey object:nil];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
   
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kExposureModeNotificationKey object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kExposureDurationNotificationKey object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kExposureTargetOffsetNotificationKey object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kISOChangeNotificationKey object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kExposureTargetBiasNotificationKey object:nil];
    
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSInteger mode;
    mode = [[AVFoundationHandler shareInstance] currentExposureMode];
    self.exposureModeBtn.selectedSegmentIndex = mode;
    
    [self.durationBtn setMaximumValue:1.0];
    [self.durationBtn setMinimumValue:0.0];
    
    [self.iSOBtn setMaximumValue:[[AVFoundationHandler shareInstance] maxISO]];
    [self.iSOBtn setMinimumValue:[[AVFoundationHandler shareInstance] minISO]];
    [self.iSOBtn setValue:[[AVFoundationHandler shareInstance] currentISOValue]];
    
    [self.biasBtn setMaximumValue:[[AVFoundationHandler shareInstance] maxExposureBias]];
    [self.biasBtn setMinimumValue:[[AVFoundationHandler shareInstance] minExposureBias]];
    [self.biasBtn setValue:[[AVFoundationHandler shareInstance] currentExposureBias]];
    
    [self.offsetBtn setMaximumValue:[[AVFoundationHandler shareInstance] maxExposureBias]];
    [self.offsetBtn setMinimumValue:[[AVFoundationHandler shareInstance] minExposureBias]];

    self.offsetBtn.enabled = NO;
    self.biasBtn.enabled = YES;
    
    if (mode == 2) {
        self.durationBtn.enabled = YES;
        self.iSOBtn.enabled = YES;
    }else{
        self.durationBtn.enabled = NO;
        self.iSOBtn.enabled = NO;
    }
    
}

#pragma mark - Notification
- (void)exposureModeChanged:(NSNotification *)notification
{
    NSDictionary * dict = [notification userInfo];
    NSInteger mode = [dict[@"value"] integerValue];
    
    self.exposureModeBtn.selectedSegmentIndex = mode;
    if (mode == 2) {
        self.durationBtn.enabled = YES;
        self.iSOBtn.enabled = YES;
    }else{
        self.durationBtn.enabled = NO;
        self.iSOBtn.enabled = NO;
    }
    
}

- (void)iOSChanged:(NSNotification *)notification
{
    NSDictionary * dict = [notification userInfo];
    float value = [dict[@"value"] floatValue];
    [self.iSOBtn setValue:value animated:YES];
}

- (void)durationChanged:(NSNotification *)notification
{
    NSDictionary * dict = [notification userInfo];
    double duration = [dict[@"value"] doubleValue];
    [self.durationBtn setValue:duration animated:YES];
}

- (void)offsetChanged:(NSNotification *)notification
{
    NSDictionary * dict = [notification userInfo];
    float offset = [dict[@"value"] floatValue];
    [self.offsetBtn setValue:offset animated:YES];
}

- (void)biasChanged:(NSNotification *)notification
{
    NSDictionary * dict = [notification userInfo];
    float bias = [dict[@"value"] floatValue];
    [self.biasBtn setValue:bias animated:YES];
}


#pragma mark - btn action

- (IBAction)closeBtnClick:(id)sender
{
    if ([_delegate respondsToSelector:@selector(exposureSetVCClosed:)]) {
        [_delegate exposureSetVCClosed:self];

    }
}

- (IBAction)exposureModeBtnClick:(id)sender
{
    UISegmentedControl * seg = sender;
    [[AVFoundationHandler shareInstance] setExposure:(ExposureMode)seg.selectedSegmentIndex];
}

- (IBAction)biasBtnClick:(id)sender
{
    UISlider * slider = sender;
    [[AVFoundationHandler shareInstance] setExposureTargetBias:slider.value];
}

- (IBAction)offsetBtnClick:(id)sender
{
    
}


- (IBAction)iSOBtnClick:(id)sender
{
    UISlider * slider = sender;
    [[AVFoundationHandler shareInstance] setISO:slider.value];
}

- (IBAction)durationBtnClick:(id)sender
{
    UISlider * slider = sender;
    [[AVFoundationHandler shareInstance] setExposureDuration:slider.value];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
