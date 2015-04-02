//
//  FrameRateSetVC.m
//  CameraDemo
//
//  Created by pinguo on 15/3/28.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "FrameRateSetVC.h"
#import "AVFoundationHandler.h"

@interface FrameRateSetVC ()
@property (weak, nonatomic) IBOutlet UIButton *closeBtn;

@property (weak, nonatomic) IBOutlet UISlider *frameRateSlider;
@end

@implementation FrameRateSetVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.frameRateSlider.maximumValue = [[AVFoundationHandler shareInstance] activeMaxFrameRate];
    self.frameRateSlider.minimumValue = [[AVFoundationHandler shareInstance] activeMinFrameRate];
    
    NSLog(@"%@  %@",@(self.frameRateSlider.maximumValue),@(self.frameRateSlider.minimumValue));
    
    
}

#pragma mark - btn action
- (IBAction)closeBtnClick:(id)sender
{
    if ([_delegate respondsToSelector:@selector(frameRateSetVCClosed:)]) {
         [_delegate frameRateSetVCClosed:self];
    }
   
}


- (IBAction)frameRateChange:(id)sender
{
    UISlider * slider = sender;
    [[AVFoundationHandler shareInstance] setFrameRate:slider.value];
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
