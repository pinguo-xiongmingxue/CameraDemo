//
//  ViewController.m
//  CameraDemo
//
//  Created by pinguo on 15/3/23.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "ViewController.h"
#import "Masonry.h"
#import "BlocksKit.h"
#import "BlocksKit+UIKit.h"
#import "AVFoundationHandler.h"
#import "CameraViewModeClass.h"
#import "CameraView.h"
#import "CommonDefine.h"
#import "ExposureSetVC.h"
#import "FrameRateSetVC.h"
#import "CameraFilterVC.h"
#import "FocusLensVC.h"
#import "WhiteBalanceSetVC.h"


#define BOTTOM_VIEW_H 150


@interface ViewController ()<ExposureSetVCDelegate,CameraViewDelegate,FrameRateSetVCDelegate,CameraFilterVCDelegate,FocusLensVCDelegate,WhiteBalanceSetVCDelegate>
{
    BOOL isFocusOrLightTest;   //YES 测焦   NO  测光
    BOOL isStillImageOrVideo;  //YES 静态图  NO 效果图
}

@property (weak, nonatomic) IBOutlet CameraView *cameraView;        // 拍照预览界面
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIButton *cameraOkBtn;         // 拍照
@property (weak, nonatomic) IBOutlet UIButton *directionBtn;        // 切换镜头
@property (weak, nonatomic) IBOutlet UIButton *preImageBtn;         // 照片预览，相册入口
@property (weak, nonatomic) IBOutlet UIButton *flashBtn;            // 闪光
@property (weak, nonatomic) IBOutlet UIButton *pixelBtn;            // 像素设置
@property (weak, nonatomic) IBOutlet UIButton *FocusBtn;            // 聚焦设置
@property (weak, nonatomic) IBOutlet UIButton *ExposureBtn;         // 曝光设置
@property (weak, nonatomic) IBOutlet UIButton *WBBtn;               // 白平衡
@property (weak, nonatomic) IBOutlet UIButton *lightAndFocusBtn;    // 测光和测焦
@property (weak, nonatomic) IBOutlet UIButton *frameRateBtnClick;   // 帧率
@property (weak, nonatomic) IBOutlet UIButton *filterBtn;           // 滤镜
@property (weak, nonatomic) IBOutlet UISwitch *doubleExposureBtn;   // 双重曝光相机


@property (strong, nonatomic) ExposureSetVC * exposureSetView;
@property (strong, nonatomic) FrameRateSetVC * frameRateSetView;
@property (strong, nonatomic) CameraFilterVC * cameraFilterSetView;
@property (strong, nonatomic) FocusLensVC * focusLensSetView;
@property (strong, nonatomic) WhiteBalanceSetVC * whiteBalanceSetView;

@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(filterModeChanged:) name:kFilterModeNotificationKey object:nil];
    [[AVFoundationHandler shareInstance] startVideo];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
 
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[AVFoundationHandler shareInstance] stopVideo];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kFilterModeNotificationKey object:nil];
}


- (void)awakeFromNib
{
    [super awakeFromNib];
    
   
}

#pragma mark - CameraViewDelegate
- (void)isFocusOrLightTest:(BOOL *)isFocusOrLight
{
    *isFocusOrLight = isFocusOrLightTest;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    isFocusOrLightTest = YES;
    isStillImageOrVideo = YES;
    self.cameraView.delegate = self;
    
   [[AVFoundationHandler shareInstance] setAVFoundationHandlerWithView:self.cameraView];
    [self.cameraView buildInterface];
    
    //初始化UI状态
    [self flashBtnChangeUI:[[AVFoundationHandler shareInstance] currentFlashMode]];
    [self resolutionBtnChangeUI:[[AVFoundationHandler shareInstance] currentPixel]];
   // [self focusBtnChangeUI:[[AVFoundationHandler shareInstance] currentFocusMode]];
  //  [self whiteBanlanceBtnChangeUI:[[AVFoundationHandler shareInstance] currentWBMode]];
    [self lightAndFocusBtnChangeUI];
    
    if ([[AVFoundationHandler shareInstance] curentDoubleExposureState]) {
        self.filterBtn.enabled = NO;
        [self.doubleExposureBtn setOn: [[AVFoundationHandler shareInstance] curentDoubleExposureState] animated:NO];
        isStillImageOrVideo = NO;
    }else{
        self.filterBtn.enabled = YES;
    }
    
    //判断当前曝光相机和滤镜的状态
    if ([[AVFoundationHandler shareInstance] currentFilterMode] ==  0) {
        [[AVFoundationHandler shareInstance] openOrCloseFilter:NO];
    }else{
        [[AVFoundationHandler shareInstance] openOrCloseFilter:YES];
        isStillImageOrVideo = NO;
    }
    
    //设置预览按钮的背景图
    CameraViewModeClass * mv = [[CameraViewModeClass alloc] init];
    [self.preImageBtn setImage:[mv getImage] forState:UIControlStateNormal];
    
    
    __weak __typeof(&*self)weakSelf = self;
    [[AVFoundationHandler shareInstance] setCameraOKImageBlock:^(NSData * imageData) {
        UIImage * newImage = [UIImage imageWithData:imageData];
        [weakSelf storeImageToDiskWithImage:newImage];
        [weakSelf.preImageBtn setBackgroundImage:newImage forState:UIControlStateNormal];
    }];
}

#pragma mark - UI
//闪光模式UI
- (void)flashBtnChangeUI:(FlashMode)mode
{
    [[AVFoundationHandler shareInstance] setFlashMode:mode];
    switch (mode) {
        case FlashModeOn:
            [self.flashBtn setBackgroundImage:[UIImage imageNamed:@"flash_open"] forState:UIControlStateNormal];
            break;
        case FlashModeOff:
            [self.flashBtn setBackgroundImage:[UIImage imageNamed:@"flash_close"] forState:UIControlStateNormal];
            break;
            
        case FlashModeAtuo:
            [self.flashBtn setBackgroundImage:[UIImage imageNamed:@"flash_auto"] forState:UIControlStateNormal];
            break;
    }
}

//像素UI
- (void)resolutionBtnChangeUI:(ResolutionMode)mode
{
    [[AVFoundationHandler shareInstance] setResolutionMode:mode];
    switch (mode) {
        case ResolutionModeDefault:
            [self.pixelBtn setTitle:@"默认像素" forState:UIControlStateNormal];
           
            break;
        case ResolutionModeLow:
           [self.pixelBtn setTitle:@"低像素" forState:UIControlStateNormal];
            break;
            
        case ResolutionModeMedium:
            [self.pixelBtn setTitle:@"中像素" forState:UIControlStateNormal];
            break;
            
        case ResolutionModeHigh:
            [self.pixelBtn setTitle:@"高像素" forState:UIControlStateNormal];
            
            break;
    
    }
}

//- (void)focusBtnChangeUI:(FocusMode)mode
//{
//    [[AVFoundationHandler shareInstance] setFocusMode:mode];
//    switch (mode) {
//        case FocusModeLocked:
//            [self.FocusBtn setTitle:@"聚焦关" forState:UIControlStateNormal];
//            break;
//        case FocusModeContinuousAutoFocus:
//            [self.FocusBtn setTitle:@"聚焦1" forState:UIControlStateNormal];
//            break;
//    }
//}

//- (void)whiteBanlanceBtnChangeUI:(WhiteBalanceMode)mode
//{
//    [[AVFoundationHandler shareInstance] setWhiteBanlance:mode];
//    
//    switch (mode) {
//        case WhiteBalanceModeLocked:
//            [self.WBBtn setTitle:@"WB关" forState:UIControlStateNormal];
//            break;
//
//            
//        case WhiteBalanceModeContinuousAutoWhiteBalance:
//            [self.WBBtn setTitle:@"WB1" forState:UIControlStateNormal];
//            
//    }
//}

//测焦和测光UI
- (void)lightAndFocusBtnChangeUI
{
    //YES 测焦   NO  测光
    if (isFocusOrLightTest) {
        [self.lightAndFocusBtn setTitle:@"测光" forState:UIControlStateNormal];
    }else{
        [self.lightAndFocusBtn setTitle:@"测焦" forState:UIControlStateNormal];
    }
}

#pragma mark - Button Action

//切换镜头
- (IBAction)directionCameraBtnClick:(id)sender
{
    
    [[AVFoundationHandler shareInstance] setDevicePositionChange];
}

//拍照
- (IBAction)cameraOkBtnClick:(id)sender
{
    if (isStillImageOrVideo) {
         [[AVFoundationHandler shareInstance] cameraImageOK];
    }else{
        [[AVFoundationHandler shareInstance] cameraVideoOk];
    }
    
}

//相册入口
- (IBAction)preImageBtnClick:(id)sender
{
    CameraViewModeClass * cameraViewMode = [[CameraViewModeClass alloc] init];
    [cameraViewMode photoDetailWithViewController:self];
    
}

//闪光
- (IBAction)flashBtnClick:(id)sender
{
    FlashMode currentMode = [[AVFoundationHandler shareInstance] currentFlashMode];
    switch (currentMode) {
        case FlashModeAtuo:
            
            [self flashBtnChangeUI:FlashModeOff];
            
            break;
        case FlashModeOn:
            [self flashBtnChangeUI:FlashModeAtuo];
            
            break;
            
        case FlashModeOff:
            [self flashBtnChangeUI:FlashModeOn];
            break;
    }
}

//像素
- (IBAction)pixelBtnClick:(id)sender
{
    ResolutionMode currentMode = [[AVFoundationHandler shareInstance] currentPixel];
    switch (currentMode) {
        case ResolutionModeDefault:
            [self resolutionBtnChangeUI:ResolutionModeLow];
            break;
        case ResolutionModeLow:
            [self resolutionBtnChangeUI:ResolutionModeMedium];
            break;
            
        case ResolutionModeMedium:
            [self resolutionBtnChangeUI:ResolutionModeHigh];
            break;
            
        case ResolutionModeHigh:
            [self resolutionBtnChangeUI:ResolutionModeDefault];
            break;
            
    }
}

//聚焦
- (IBAction)focusBtnClick:(id)sender
{
    
    if (!self.focusLensSetView) {
        _focusLensSetView = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]]instantiateViewControllerWithIdentifier:@"FocusLensVC"];
        _focusLensSetView.view.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width,BOTTOM_VIEW_H);
        _focusLensSetView.delegate = self;
    }
    
    [self addChildViewController:self.focusLensSetView];
    [self.view addSubview:self.focusLensSetView.view];
    [self.focusLensSetView didMoveToParentViewController:self];
    
    [self showAnimationWithView:self.focusLensSetView.view];
    
}

//白平衡
- (IBAction)whiteBalanceBtnClick:(id)sender
{
    if (!self.whiteBalanceSetView) {
        _whiteBalanceSetView = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]]instantiateViewControllerWithIdentifier:@"WhiteBalanceSetVC"];
        _whiteBalanceSetView.view.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width,BOTTOM_VIEW_H);
        _whiteBalanceSetView.delegate = self;
    }
    
    [self addChildViewController:self.whiteBalanceSetView];
    [self.view addSubview:self.whiteBalanceSetView.view];
    [self.whiteBalanceSetView didMoveToParentViewController:self];

    [self showAnimationWithView:self.whiteBalanceSetView.view];
    
}

//曝光
- (IBAction)exposureBtnClick:(id)sender
{
    if (!self.exposureSetView) {
        _exposureSetView = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]]instantiateViewControllerWithIdentifier:@"ExposureSetVC"];
        _exposureSetView.view.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width,BOTTOM_VIEW_H);
        _exposureSetView.delegate = self;
      
    }
    
    [self.view addSubview:_exposureSetView.view];
    
    if (self.exposureSetView) {
          [self showAnimationWithView:self.exposureSetView.view];
    }
    
}

//帧率
- (IBAction)frameRateBtnClick:(id)sender
{
    if (!self.frameRateSetView) {
        _frameRateSetView = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]]instantiateViewControllerWithIdentifier:@"FrameRateSetVC"];
        _frameRateSetView.view.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, BOTTOM_VIEW_H);
        _frameRateSetView.delegate = self;
    }
    [self.view addSubview:_frameRateSetView.view];
    [[AVFoundationHandler shareInstance] openOrCloseFilter:YES];
    if (self.frameRateSetView) {
        [self showAnimationWithView:self.frameRateSetView.view];
    }
}

//滤镜
- (IBAction)fliterBtnClick:(id)sender
{
    [[AVFoundationHandler shareInstance] openOrCloseFilter:YES];
    if (!self.cameraFilterSetView) {
        _cameraFilterSetView = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]]instantiateViewControllerWithIdentifier:@"CameraFilterVC"];
        _cameraFilterSetView.view.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, BOTTOM_VIEW_H);
        _cameraFilterSetView.delegate = self;
    }
    [self.view addSubview:_cameraFilterSetView.view];
    if (self.cameraFilterSetView) {
        [self showAnimationWithView:self.cameraFilterSetView.view];
    }
}

//测光和测焦
- (IBAction)lightAndFocusBtnClick:(id)sender
{
    //YES 测焦   NO  测光
    if (isFocusOrLightTest) {
        isFocusOrLightTest = NO;
    }else{
        isFocusOrLightTest = YES;
       
    }
     [self lightAndFocusBtnChangeUI];
}


//双重曝光相机
- (IBAction)doubleBtnClick:(id)sender
{
    UISwitch * slider = sender;
    [[AVFoundationHandler shareInstance] openDoubleExposure:slider.on];
    if (slider.on) {
        self.filterBtn.enabled = NO;
        isStillImageOrVideo = NO;
    }else{
        isStillImageOrVideo = YES;
        self.filterBtn.enabled = YES;
    }
}

#pragma mark - Notification
- (void)filterModeChanged:(NSNotification *)notification
{
    NSDictionary * dict = [notification userInfo];
    FilterShowMode mode = (FilterShowMode)[dict[@"value"] integerValue];
    if (mode == 0) {
        self.doubleExposureBtn.enabled = YES;
        isStillImageOrVideo = YES;
    }else{
        self.doubleExposureBtn.enabled = NO;
        isStillImageOrVideo = NO;
    }
}


#pragma mark - show Animation


- (void)showAnimationWithView:(UIView *)view
{
    
    CGPoint point = view.center;
    point.y -= BOTTOM_VIEW_H;
    [UIView animateWithDuration:0.25 animations:^{
        view.center = point;
    } completion:^(BOOL finished) {
        
    }];
    
}

- (void)hideAnimationWithView:(UIView *)view
{
    CGPoint point = view.center;
    point.y += BOTTOM_VIEW_H;
    [UIView animateWithDuration:0.25 animations:^{
       view.center = point;
    } completion:^(BOOL finished) {
        
    }];
}
#pragma mark - SetVCS Delegates
//曝光VC
- (void)exposureSetVCClosed:(ExposureSetVC *)exposureVC
{
    CGPoint point = self.exposureSetView.view.center;
    point.y += BOTTOM_VIEW_H;
    [UIView animateWithDuration:0.25 animations:^{
        self.exposureSetView.view.center = point;
    } completion:^(BOOL finished) {
        [_exposureSetView.view removeFromSuperview];
        [_exposureSetView removeFromParentViewController];
        _exposureSetView = nil;
    }];
}

//帧率VC
- (void)frameRateSetVCClosed:(FrameRateSetVC *)frameRateSetVC
{
    CGPoint point = self.frameRateSetView.view.center;
    point.y += BOTTOM_VIEW_H;
    [UIView animateWithDuration:0.25 animations:^{
        self.frameRateSetView.view.center = point;
    } completion:^(BOOL finished) {
        [_frameRateSetView.view removeFromSuperview];
        [_frameRateSetView removeFromParentViewController];
        _frameRateSetView = nil;
    }];
}

//滤镜VC
- (void)cameraFilterVCClosed:(UIViewController *)cameraFilterVC
{
    CGPoint point = self.cameraFilterSetView.view.center;
    point.y += BOTTOM_VIEW_H;
    [UIView animateWithDuration:0.25 animations:^{
        self.cameraFilterSetView.view.center = point;
    } completion:^(BOOL finished) {
        [_cameraFilterSetView.view removeFromSuperview];
        [_cameraFilterSetView removeFromParentViewController];
        _cameraFilterSetView = nil;
    }];
}

//聚焦VC
- (void)focusLensVCClosed:(FocusLensVC *)focusLensVC
{
    CGPoint point = self.focusLensSetView.view.center;
    point.y += BOTTOM_VIEW_H;
    [UIView animateWithDuration:0.25 animations:^{
        self.focusLensSetView.view.center = point;
    } completion:^(BOOL finished) {
        [_focusLensSetView.view removeFromSuperview];
        [_focusLensSetView removeFromParentViewController];
        _focusLensSetView = nil;
    }];
}

//白平衡VC
- (void)whiteBalanceSetVCClosed:(WhiteBalanceSetVC *)whiteBalanceSetVC
{
    CGPoint point = self.whiteBalanceSetView.view.center;
    point.y += BOTTOM_VIEW_H;
    [UIView animateWithDuration:0.25 animations:^{
        self.whiteBalanceSetView.view.center = point;
    } completion:^(BOOL finished) {
        [_whiteBalanceSetView.view removeFromSuperview];
        [_whiteBalanceSetView removeFromParentViewController];
        _whiteBalanceSetView = nil;
    }];
}


#pragma mark - save image
- (void)storeImageToDiskWithImage:(UIImage *)image
{
    CameraViewModeClass * cm = [[CameraViewModeClass alloc] init];
    [cm saveImage:image WithAblumTitle:AlbumTitle];
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
