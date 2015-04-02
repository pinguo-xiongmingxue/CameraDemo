//
//  AlbumHandler.h
//  CameraDemo
//
//  Created by pinguo on 15/3/25.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AlbumHandler : NSObject

/**
 *  取得某个相册所有的照片，按最新在前排序
 *
 *  @param albumTitle 相册名称
 *
 *  @return 返回照片数组
 */
+ (NSArray *)getPhotoInfosWithAlbum:(NSString *)albumTitle;

@end
