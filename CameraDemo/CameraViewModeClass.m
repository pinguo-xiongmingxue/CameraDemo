//
//  CameraViewModeClass.m
//  CameraDemo
//
//  Created by pinguo on 15/3/25.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "CameraViewModeClass.h"
#import "AlbumViewController.h"
#import "DateHandler.h"
#import "ImageCacheHandler.h"
#import "PhotoHandler.h"

@implementation CameraViewModeClass

- (UIImage *)getImage
{
    PhotoInfo * photoInfo = [PhotoHandler getPhotoInfoWithAlbum:AlbumTitle];
    UIImage * image = [[ImageCacheHandler shareInstance] diskImageForKey:photoInfo.name withPath:photoInfo.address];
    return image;
}

- (void)saveImage:(UIImage *)image WithAblumTitle:(NSString *)albumTitle
{
    NSString *key = [[DateHandler shareInstance] photoDateString];
    NSString * imageName = [NSString stringWithFormat:@"%@_%@",AlbumTitle,key];
    [PhotoHandler saveInfo:@{PhotoNameKey:imageName} withAlbum:AlbumTitle];
    [[ImageCacheHandler shareInstance] storeImage:image forKey:imageName appendPath:AlbumTitle];
}

- (void)photoDetailWithViewController:(UIViewController * )superViewController
{
    AlbumViewController * av = [[UIStoryboard storyboardWithName:@"Main" bundle:nil]instantiateViewControllerWithIdentifier:@"AlbumViewController"];
    superViewController.navigationController.navigationBarHidden = NO;
    [superViewController.navigationController pushViewController:av animated:YES];
}

@end
