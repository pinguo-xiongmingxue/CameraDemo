//
//  CameraFilterVC.m
//  CameraDemo
//
//  Created by pinguo on 15/3/30.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "CameraFilterVC.h"
#import "AVFoundationHandler.h"

@interface CameraFilterVC ()

@property (weak, nonatomic) IBOutlet UIButton *closeBtn;

@property (weak, nonatomic) IBOutlet UISegmentedControl *filterSegmentBtn;

@end

@implementation CameraFilterVC

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.filterSegmentBtn.selectedSegmentIndex = [[AVFoundationHandler shareInstance] currentFilterMode];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
   
    self.filterSegmentBtn.selectedSegmentIndex = [[AVFoundationHandler shareInstance] currentFilterMode];
    
}

#pragma mark - btn action
- (IBAction)filterSegmentBtnClick:(id)sender
{
    UISegmentedControl * seg = sender;
    [[AVFoundationHandler shareInstance] setUpCustomFilterMode:(FilterShowMode)seg.selectedSegmentIndex];
}

- (IBAction)closeBtnClick:(id)sender
{
    if ([_delegate respondsToSelector:@selector(cameraFilterVCClosed:)]) {
        [_delegate cameraFilterVCClosed:self];
    }
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
