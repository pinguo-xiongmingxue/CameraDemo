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



@interface ViewController ()
{
    //AVFoundationHandler * _AVHandler;
}

@property (weak, nonatomic) IBOutlet CameraView *cameraView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIButton *cameraOkBtn;
@property (weak, nonatomic) IBOutlet UIButton *directionBtn;
@property (weak, nonatomic) IBOutlet UIButton *preImageBtn;


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
    
    [[AVFoundationHandler shareInstance] stopVideo];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    //[self.cameraView setSession:[[AVFoundationHandler shareInstance] avCaptureSession]];
    [[AVFoundationHandler shareInstance] setAVFoundationHandlerWithView:self.cameraView];
   
    
    __weak __typeof(&*self)weakSelf = self;
    [[AVFoundationHandler shareInstance] setCameraOKImageBlock:^(NSData * imageData) {
        UIImage * newImage = [UIImage imageWithData:imageData];
        [weakSelf storeImageToDiskWithImage:newImage];
        
        [weakSelf.preImageBtn setBackgroundImage:newImage forState:UIControlStateNormal];
    }];
    
//    [self.cameraView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.equalTo(self.view);
//        make.left.equalTo(self.view);
//        make.right.equalTo(self.view);
//        make.bottom.equalTo(self.view).with.offset(-100);
//        make.width.equalTo(self.view);
//    
//    }];
//
//    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
//        
//    }];
    
    
//    
//    _AVHandler = [AVFoundationHandler shareInstance];
//    _AVHandler.delegate = self;
//    [_AVHandler initAVFoundationHandlerWithView:self.cameraView];
//    
//
//    
//    [_AVHandler startVideo];
    
    
    
//    [self.cameraOkBtn bk_addEventHandler:^(id sender) {
//        
//        
//        
//        
//    } forControlEvents:UIControlEventTouchUpInside];
    
    
    
    
}

#pragma mark - Button Action

- (IBAction)directionCameraBtnClick:(id)sender
{
    
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


#pragma mark - AVFoundationHandlerDelegate

- (void)postImageData:(NSData *)imageData
{
   // [_AVHandler stopVideo];
    
    UIImage * newImage = [UIImage imageWithData:imageData];
    [self storeImageToDiskWithImage:newImage];
    
    [self.preImageBtn setBackgroundImage:newImage forState:UIControlStateNormal];
    
   // [_AVHandler startVideo];
}

- (void)storeImageToDiskWithImage:(UIImage *)image
{
    NSString *key = [[DateHandler shareInstance] photoDateString];
    NSString * imageName = [NSString stringWithFormat:@"%@_%@",AlbumTitle,key];
    [PhotoHandler saveInfo:@{PhotoNameKey:imageName} withAlbum:AlbumTitle];
    [[ImageCacheHandler shareInstance] storeImage:image forKey:imageName appendPath:AlbumTitle];
}





#pragma mark - GestureRecognizer Delegate

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
