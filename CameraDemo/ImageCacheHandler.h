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


- (void)storeImage:(UIImage *)image forKey:(NSString *)key appendPath:(NSString *)path;
- (UIImage *)diskImageForKey:(NSString *)key withPath:(NSString *)path;
- (NSString *)imagePathWithKey:(NSString *)key withPath:(NSString *)path;


- (BOOL)deleteImagesForPath:(NSString *)path;
- (BOOL)deleteSingleImageForKey:(NSString *)key withPath:(NSString *)path;
- (void)clearDiskCache;

@end
