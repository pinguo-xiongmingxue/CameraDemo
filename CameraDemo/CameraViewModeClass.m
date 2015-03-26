//
//  CameraViewModeClass.m
//  CameraDemo
//
//  Created by pinguo on 15/3/25.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "CameraViewModeClass.h"
#import "AlbumViewController.h"

@implementation CameraViewModeClass


- (void)photoDetailWithViewController:(UIViewController * )superViewController
{
    AlbumViewController * av = [[UIStoryboard storyboardWithName:@"Main" bundle:nil]instantiateViewControllerWithIdentifier:@"AlbumViewController"];
    superViewController.navigationController.navigationBarHidden = NO;
    [superViewController.navigationController pushViewController:av animated:YES];
}

@end
