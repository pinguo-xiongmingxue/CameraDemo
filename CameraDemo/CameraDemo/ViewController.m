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
#import "DateHandler.h"
#import "ImageCacheHandler.h"
#import "PhotoHandler.h"
#import "CameraViewModeClass.h"
#import "CameraView.h"
#import "CommonDefine.h"
#import "ExposureSetVC.h"
#import "FrameRateSetVC.h"
#import "CameraFilterVC.h"



@interface ViewController ()<ExposureSetVCDelegate,CameraViewDelegate,FrameRateSetVCDelegate,CameraFilterVCDelegate>
{
    //AVFoundationHandler * _AVHandler;
    BOOL isFocusOrLightTest;   //YES 测焦   NO  测光
}

@property (weak, nonatomic) IBOutlet CameraView *cameraView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIButton *cameraOkBtn;
@property (weak, nonatomic) IBOutlet UIButton *directionBtn;
@property (weak, nonatomic) IBOutlet UIButton *preImageBtn;
@property (weak, nonatomic) IBOutlet UIButton *flashBtn;
@property (weak, nonatomic) IBOutlet UIButton *pixelBtn;
@property (weak, nonatomic) IBOutlet UIButton *FocusBtn;
@property (weak, nonatomic) IBOutlet UIButton *ExposureBtn;

@property (weak, nonatomic) IBOutlet UIButton *WBBtn;

@property (weak, nonatomic) IBOutlet UIButton *lightAndFocusBtn;

@property (weak, nonatomic) IBOutlet UIButton *frameRateBtnClick;

@property (weak, nonatomic) IBOutlet UIButton *filterBtn;

@property (strong, nonatomic) ExposureSetVC * exposureSetView;
@property (strong, nonatomic) FrameRateSetVC * frameRateSetView;
@property (strong, nonatomic) CameraFilterVC * cameraFilterSetView;

@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
//    if (_AVHandler) {
//        [_AVHandler startVideo];
//    }
    
    [[AVFoundationHandler shareInstance] startVideo];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
  //  [_AVHandler stopVideo];
    
 
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[AVFoundationHandler shareInstance] stopVideo];
}


- (void)awakeFromNib
{
    [super awakeFromNib];
    
   
}

- (void)cameraViewTapedPoint:(CGPoint)point
{
    if (isFocusOrLightTest) {
         [[AVFoundationHandler shareInstance] setFocus:point.x focusy:point.y];
    }else{
         [[AVFoundationHandler shareInstance] setExposureX:point.x exposureY:point.y];
    }
   
}

- (void)isFocusOrLightTest:(BOOL *)isFocusOrLight
{
    *isFocusOrLight = isFocusOrLightTest;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    isFocusOrLightTest = YES;
    self.cameraView.delegate = self;
    
   [[AVFoundationHandler shareInstance] setAVFoundationHandlerWithView:self.cameraView];
    [self.cameraView buildInterface];
    
    [self flashBtnChangeUI:[[AVFoundationHandler shareInstance] currentFlashMode]];
    [self resolutionBtnChangeUI:[[AVFoundationHandler shareInstance] currentPixel]];
    [self focusBtnChangeUI:[[AVFoundationHandler shareInstance] currentFocusMode]];
    [self whiteBanlanceBtnChangeUI:[[AVFoundationHandler shareInstance] currentWBMode]];
    [self lightAndFocusBtnChangeUI];
   // [self.cameraView bringSubviewToFront:self.cameraOkBtn];
    PhotoInfo * photoInfo = [PhotoHandler getPhotoInfoWithAlbum:AlbumTitle];
     UIImage * image = [[ImageCacheHandler shareInstance] diskImageForKey:photoInfo.name withPath:photoInfo.address];
    [self.preImageBtn setImage:image forState:UIControlStateNormal];
    
    __weak __typeof(&*self)weakSelf = self;
    [[AVFoundationHandler shareInstance] setCameraOKImageBlock:^(NSData * imageData) {
        
        UIImage * newImage = [UIImage imageWithData:imageData];
        [weakSelf storeImageToDiskWithImage:newImage];
        
        [weakSelf.preImageBtn setBackgroundImage:newImage forState:UIControlStateNormal];
    }];
    
    
   
   
    
}

#pragma mark - UI

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

- (void)focusBtnChangeUI:(FocusMode)mode
{
    [[AVFoundationHandler shareInstance] setFocusMode:mode];
    switch (mode) {
        case FocusModeLocked:
            [self.FocusBtn setTitle:@"聚焦关" forState:UIControlStateNormal];
            break;
        case FocusModeAutoFocus:
            [self.FocusBtn setTitle:@"聚焦1" forState:UIControlStateNormal];
            break;
        case FocusModeContinuousAutoFocus:
            [self.FocusBtn setTitle:@"聚焦2" forState:UIControlStateNormal];
            break;
    }
}

- (void)whiteBanlanceBtnChangeUI:(WhiteBalanceMode)mode
{
    [[AVFoundationHandler shareInstance] setWhiteBanlance:mode];
//    switch (mode) {
//        case WhiteBalanceModeLocked:
//            [self.WBBtn setTitle:@"WB关" forState:UIControlStateNormal];
//            break;
//        case WhiteBalanceModeAutoWhiteBalance:
//            [self.WBBtn setTitle:@"WB1" forState:UIControlStateNormal];
//            break;
//        case WhiteBalanceModeContinuousAutoWhiteBalance:
//            [self.WBBtn setTitle:@"WB2" forState:UIControlStateNormal];
//
//    }
    
    switch (mode) {
        case WhiteBalanceModeLocked:
            [self.WBBtn setTitle:@"WB关" forState:UIControlStateNormal];
            break;
//        case WhiteBalanceModeAutoWhiteBalance:
//            [self.WBBtn setTitle:@"WB1" forState:UIControlStateNormal];
//            break;
        case WhiteBalanceModeContinuousAutoWhiteBalance:
            [self.WBBtn setTitle:@"WB1" forState:UIControlStateNormal];
            
    }
}

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

- (IBAction)directionCameraBtnClick:(id)sender
{
    
    [[AVFoundationHandler shareInstance] setDevicePositionChange];
}

- (IBAction)cameraOkBtnClick:(id)sender
{
    //[_AVHandler cameraOK];
    [[AVFoundationHandler shareInstance] cameraOK];
}

- (IBAction)preImageBtnClick:(id)sender
{
    CameraViewModeClass * cameraViewMode = [[CameraViewModeClass alloc] init];
    [cameraViewMode photoDetailWithViewController:self];
    
}

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

- (IBAction)focusBtnClick:(id)sender
{
    FocusMode mode = [[AVFoundationHandler shareInstance] currentFocusMode];
    switch (mode) {
        case FocusModeLocked:
            [self focusBtnChangeUI:FocusModeAutoFocus];
            break;
        case FocusModeAutoFocus:
            [self focusBtnChangeUI:FocusModeContinuousAutoFocus];
            break;
        case FocusModeContinuousAutoFocus:
            [self focusBtnChangeUI:FocusModeLocked];
            
            break;
    }
}

- (IBAction)whiteBalanceBtnClick:(id)sender
{
    WhiteBalanceMode mode = [[AVFoundationHandler shareInstance] currentWBMode];
//    switch (mode) {
//        case WhiteBalanceModeLocked:
//            [self whiteBanlanceBtnChangeUI:WhiteBalanceModeAutoWhiteBalance];
//            break;
//        case WhiteBalanceModeAutoWhiteBalance:
//            [self whiteBanlanceBtnChangeUI:WhiteBalanceModeContinuousAutoWhiteBalance];
//            break;
//        case WhiteBalanceModeContinuousAutoWhiteBalance:
//            [self whiteBanlanceBtnChangeUI:WhiteBalanceModeLocked];
//            break;
//     
//    }
    
    switch (mode) {
        case WhiteBalanceModeLocked:
            [self whiteBanlanceBtnChangeUI:WhiteBalanceModeContinuousAutoWhiteBalance];
            break;
        case WhiteBalanceModeContinuousAutoWhiteBalance:
            [self whiteBanlanceBtnChangeUI:WhiteBalanceModeLocked];
            break;
            
    }
}

- (IBAction)exposureBtnClick:(id)sender
{
    if (!self.exposureSetView) {
        _exposureSetView = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]]instantiateViewControllerWithIdentifier:@"ExposureSetVC"];
        _exposureSetView.view.frame = CGRectMake(0, self.view.frame.size.height, 320, 100);
        _exposureSetView.delegate = self;
      
    }
    
    [self.view addSubview:_exposureSetView.view];
    
    if (self.exposureSetView) {
          [self showAnimationWithView:self.exposureSetView.view];
    }
    
}

- (IBAction)frameRateBtnClick:(id)sender
{
    if (!self.frameRateSetView) {
        _frameRateSetView = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]]instantiateViewControllerWithIdentifier:@"FrameRateSetVC"];
        _frameRateSetView.view.frame = CGRectMake(0, self.view.frame.size.height, 320, 100);
        _frameRateSetView.delegate = self;
    }
    [self.view addSubview:_frameRateSetView.view];
    [[AVFoundationHandler shareInstance] openOrCloseFilter:YES];
    if (self.frameRateSetView) {
        [self showAnimationWithView:self.frameRateSetView.view];
    }
}


- (IBAction)fliterBtnClick:(id)sender
{
    if (!self.cameraFilterSetView) {
        _cameraFilterSetView = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]]instantiateViewControllerWithIdentifier:@"CameraFilterVC"];
        _cameraFilterSetView.view.frame = CGRectMake(0, self.view.frame.size.height, 320, 100);
        _cameraFilterSetView.delegate = self;
    }
    [self.view addSubview:_cameraFilterSetView.view];
    if (self.cameraFilterSetView) {
        [self showAnimationWithView:self.cameraFilterSetView.view];
    }
}

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




#pragma mark - show Animation


- (void)showAnimationWithView:(UIView *)view
{
    
    CGPoint point = view.center;
    point.y -= 100;
    [UIView animateWithDuration:0.25 animations:^{
        view.center = point;
    } completion:^(BOOL finished) {
        
    }];
    
}

- (void)hideAnimationWithView:(UIView *)view
{
    CGPoint point = view.center;
    point.y += 100;
    [UIView animateWithDuration:0.25 animations:^{
        view.center = point;
    } completion:^(BOOL finished) {
        [view removeFromSuperview];
        
    }];
}
#pragma mark - SetVC Delegates

- (void)exposureSetVCClosed:(ExposureSetVC *)exposureVC
{
    [self hideAnimationWithView:self.exposureSetView.view];
}

- (void)frameRateSetVCClosed:(FrameRateSetVC *)frameRateSetVC
{
    [self hideAnimationWithView:self.frameRateSetView.view];
}

- (void)cameraFilterVCClosed:(UIViewController *)cameraFilterVC
{
    //[[AVFoundationHandler shareInstance] openOrCloseFilter:NO];
    [self hideAnimationWithView:self.cameraFilterSetView.view];
}

//
//#pragma mark - AVFoundationHandlerDelegate
//
//- (void)postImageData:(NSData *)imageData
//{
//   // [_AVHandler stopVideo];
//    
//    UIImage * newImage = [UIImage imageWithData:imageData];
//    [self storeImageToDiskWithImage:newImage];
//    
//    [self.preImageBtn setBackgroundImage:newImage forState:UIControlStateNormal];
//    
//   // [_AVHandler startVideo];
//}

- (void)storeImageToDiskWithImage:(UIImage *)image
{
    NSString *key = [[DateHandler shareInstance] photoDateString];
    NSString * imageName = [NSString stringWithFormat:@"%@_%@",AlbumTitle,key];
    [PhotoHandler saveInfo:@{PhotoNameKey:imageName} withAlbum:AlbumTitle];
    [[ImageCacheHandler shareInstance] storeImage:image forKey:imageName appendPath:AlbumTitle];
}






- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
