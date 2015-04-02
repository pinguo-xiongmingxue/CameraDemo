//
//  FocusLensVC.m
//  CameraDemo
//
//  Created by pinguo on 15/4/1.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "FocusLensVC.h"
#import "AVFoundationHandler.h"

@interface FocusLensVC ()


@property (weak, nonatomic) IBOutlet UIButton *closeBtn;

@property (weak, nonatomic) IBOutlet UISlider *focusLensBtn;
@property (weak, nonatomic) IBOutlet UISegmentedControl *focusLensModebtn;

@end

@implementation FocusLensVC


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    [[AVFoundationHandler shareInstance] addObserver:self selector:@selector(focusLensChanged:) dataType:ObserverTypeFocusLens];
//    [[AVFoundationHandler shareInstance] addObserver:self selector:@selector(focusModeChanged:) dataType:ObserverTypeFocusMode];
    
    //注册聚焦模式，距离改变的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(focusLensChanged:) name:kLensPositionNotificationKey object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(focusModeChanged:) name:kFocusModeNotificationKey object:nil];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
//    [[AVFoundationHandler shareInstance] removeObserver:self dataType:ObserverTypeFocusMode];
//    [[AVFoundationHandler shareInstance] removeObserver:self dataType:ObserverTypeFocusLens];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLensPositionNotificationKey object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kFocusModeNotificationKey object:nil];

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.focusLensBtn.minimumValue = 0.0;
    self.focusLensBtn.maximumValue = 1.0;
    
    NSInteger mode = [[AVFoundationHandler shareInstance] currentFocusMode];
    
    self.focusLensModebtn.selectedSegmentIndex = mode;
    
    if (mode == 0) {
        self.focusLensBtn.enabled = NO;
    }else{
        self.focusLensBtn.enabled = YES;
    }
    
}


#pragma mark - Notification
- (void)focusLensChanged:(NSNotification *)notification
{
    NSDictionary * dict = [notification userInfo];
    float lens = [[dict objectForKey:@"value"] floatValue];
    [self.focusLensBtn setValue:lens animated:YES];
}

- (void)focusModeChanged:(NSNotification *)notification
{
    NSDictionary * dict = [notification userInfo];
    NSInteger mode = [[dict objectForKey:@"value"] integerValue];
    [self.focusLensModebtn setSelectedSegmentIndex:mode];
    if (mode == 0) {
        self.focusLensBtn.enabled = NO;
    }else{
        self.focusLensBtn.enabled = YES;
    }
}


#pragma btn action
- (IBAction)closeBtnClick:(id)sender
{
    if ([_delegate respondsToSelector:@selector(focusLensVCClosed:)]) {
        [_delegate focusLensVCClosed:self];

    }
    
}


- (IBAction)focusLensBtnClick:(id)sender
{
    UISlider * slider = sender;
    
    [[AVFoundationHandler shareInstance] setLensPosition:slider.value];
    
    
}

- (IBAction)focusModeBtnClick:(id)sender
{
    UISegmentedControl * seg = sender;
    [[AVFoundationHandler shareInstance] setFocusMode:(FocusMode)seg.selectedSegmentIndex];
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
