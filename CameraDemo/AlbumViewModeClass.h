//
//  AlbumViewModeClass.h
//  CameraDemo
//
//  Created by pinguo on 15/3/25.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "ViewModelClass.h"

@class UIViewController,PhotoInfo;
@interface AlbumViewModeClass : ViewModelClass

/**
 *  取出相册里所有的照片，block回调
 *
 *  @param album 相册名称
 */
- (void)fetchPhotosWithAlbum:(NSString *)album;

/**
 *  推送到下一个viewController
 *
 *  @param superViewController
 *  @param imageArr            照片的Array
 *  @param index               推出新ViewController后显示的Array照片的index
 */
- (void)photoDetailWithViewController:(UIViewController * )superViewController withImageArray:(NSMutableArray *)imageArr atIndex:(NSUInteger)index;

/**
 *  删除某张照片
 *
 *  @param photoInfo 照片信息
 */
- (void)deletePhotoInfo:(PhotoInfo *)photoInfo;

@end
