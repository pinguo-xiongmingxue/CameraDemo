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



@end

@implementation ExposureSetVC

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeExposureValue:) name:@"ExposureDuration" object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.exposureDurationBtn.enabled = NO;
    self.iSOBtn.enabled = NO;
    //    self.iSOBtn.maximumValue = [[AVFoundationHandler shareInstance] maxISO];
    //    self.iSOBtn.minimumValue = [[AVFoundationHandler shareInstance] minISO];
    //    self.iSOBtn.value = [[AVFoundationHandler shareInstance] currentISOValue];
    
    
    
    [self.iSOBtn setMaximumValue:[[AVFoundationHandler shareInstance] maxISO]];
    [self.iSOBtn setMinimumValue:[[AVFoundationHandler shareInstance] minISO]];
    [self.iSOBtn setValue:[[AVFoundationHandler shareInstance] currentISOValue]];
    
    NSLog(@"maxISO %f  minISO  %f  current %f  btn max %f  btn min %f btn current %f",[[AVFoundationHandler shareInstance] maxISO],[[AVFoundationHandler shareInstance] minISO],[[AVFoundationHandler shareInstance] currentISOValue],self.iSOBtn.maximumValue,self.iSOBtn.minimumValue,self.iSOBtn.value);
    
    
    
    self.exposureDurationBtn.value = [[AVFoundationHandler shareInstance] currentExposureDuration];
    self.exposureModeBtn.selectedSegmentIndex = [[AVFoundationHandler shareInstance] currentExposureMode];
    [self checkExposureDuration:self.exposureModeBtn.selectedSegmentIndex];

    
}

- (void)checkExposureDuration:(NSInteger)value
{
    if (value == 3) {
        self.exposureDurationBtn.enabled = YES;
        self.iSOBtn.enabled = YES;
    }else{
        self.exposureDurationBtn.enabled = NO;
        self.iSOBtn.enabled = NO;
    }
}

- (IBAction)closeBtnClick:(id)sender
{
    [_delegate exposureSetVCClosed:self];
}


- (IBAction)exposureModeChange:(id)sender
{
    UISegmentedControl * control = sender;
   
    [[AVFoundationHandler shareInstance] setExposure:(ExposureMode)control.selectedSegmentIndex];
    [self checkExposureDuration:control.selectedSegmentIndex];
}


- (IBAction)exposureDurationChange:(id)sender
{
    UISlider * slider = sender;
    [[AVFoundationHandler shareInstance] setExposureDuration:slider.value];
}

- (IBAction)iOSValueChange:(id)sender
{
    UISlider * slider = sender;
    NSLog(@"sldierValue %f",slider.value);
    [[AVFoundationHandler shareInstance] setISO:slider.value];
}


- (void)changeExposureValue:(NSNotification * )info
{
     self.exposureDurationBtn.value = [[AVFoundationHandler shareInstance] currentExposureDuration];
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
