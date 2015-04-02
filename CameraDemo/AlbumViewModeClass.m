//
//  AlbumViewModeClass.m
//  CameraDemo
//
//  Created by pinguo on 15/3/25.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "AlbumViewModeClass.h"
#import "AlbumHandler.h"
#import "PhotoDetailVC.h"
#import "PhotoInfo.h"
#import "PhotoHandler.h"

@implementation AlbumViewModeClass

- (void)fetchPhotosWithAlbum:(NSString *)album
{
    NSMutableArray * arr = [[NSMutableArray alloc] initWithArray:[AlbumHandler getPhotoInfosWithAlbum:album]];
    if (self.returnBlock) {
         self.returnBlock(arr);
    }
   
}

- (void)photoDetailWithViewController:(UIViewController * )superViewController withImageArray:(NSMutableArray *)imageArr atIndex:(NSUInteger)index
{
    PhotoDetailVC * av = [[UIStoryboard storyboardWithName:@"Main" bundle:nil]instantiateViewControllerWithIdentifier:@"PhotoDetailVC"];
    av.imageArray = imageArr;
    av.index = index;
    superViewController.navigationController.navigationBarHidden = NO;
    [superViewController.navigationController pushViewController:av animated:YES];
}

- (void)deletePhotoInfo:(PhotoInfo *)photoInfo
{
    [PhotoHandler deletePhotoInfo:photoInfo.name withAlbumTitle:AlbumTitle];
}

@end
