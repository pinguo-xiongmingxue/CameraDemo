//
//  ImageCacheHandler.h
//  CameraDemo
//
//  Created by pinguo on 15/3/24.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ImageCacheHandler : NSObject

+ (ImageCacheHandler *)shareInstance;

/**
 *  存储一张特点路径的照片
 *
 *  @param image 图片
 *  @param key   照片名称
 *  @param path  相册
 */
- (void)storeImage:(UIImage *)image forKey:(NSString *)key appendPath:(NSString *)path;

/**
 *  取得某张图片
 *
 *  @param key  图片名称
 *  @param path 相册
 *
 *  @return image
 */
- (UIImage *)diskImageForKey:(NSString *)key withPath:(NSString *)path;



/**
 *  删除某个相册
 *
 *  @param path 相册名称
 *
 *  @return YES success
 */
- (BOOL)deleteImagesForPath:(NSString *)path;

/**
 *  删除单张图片
 *
 *  @param key  图片名称
 *  @param path 相册名称
 *
 *  @return YES success
 */
- (BOOL)deleteSingleImageForKey:(NSString *)key withPath:(NSString *)path;

/**
 *  清空所有的照片
 */
- (void)clearDiskCache;

@end
