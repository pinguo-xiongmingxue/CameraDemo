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

+ (PhotoInfo *)saveInfo:(NSDictionary *)infoDict withAlbum:(NSString *)ablumTitle;
+ (PhotoInfo *)getPhotoInfoWithAlbum:(NSString *)albumTitle;

@end
