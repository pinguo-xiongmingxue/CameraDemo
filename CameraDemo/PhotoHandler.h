//
//  PhotoHandler.h
//  CameraDemo
//
//  Created by pinguo on 15/3/24.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoInfo.h"

@interface PhotoHandler : NSObject

/**
 *  存储一张新的照片
 *
 *  @param infoDict   照片信息
 *  @param ablumTitle 相册名
 *
 *  @return 被存照片信息
 */
+ (PhotoInfo *)saveInfo:(NSDictionary *)infoDict withAlbum:(NSString *)ablumTitle;

/**
 *  取得相册最新一张照片
 *
 *  @param albumTitle 相册名称
 *
 *  @return 照片信息
 */
+ (PhotoInfo *)getPhotoInfoWithAlbum:(NSString *)albumTitle;

/**
 *  取得某个相册所有的照片，按最新排序
 *
 *  @param albumTitle 相册名称
 *
 *  @return 照片数组
 */
+ (NSArray *)getPhotoInfosWithAlbum:(NSString *)albumTitle;

/**
 *  删除某张照片
 *
 *  @param photoName 照片名称
 *  @param title     相册名称
 *
 *  @return <#return value description#>
 */
+ (BOOL)deletePhotoInfo:(NSString *)photoName  withAlbumTitle:(NSString *)title;
@end
