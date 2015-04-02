//
//  PhotoInfo.h
//  CameraDemo
//
//  Created by pinguo on 15/4/2.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AlbumInfo;

@interface PhotoInfo : NSManagedObject

@property (nonatomic, retain) NSString * address;  //所属相册
@property (nonatomic, retain) NSString * name;     //照片名称
@property (nonatomic, retain) NSDate * createTime; //创建时间
@property (nonatomic, retain) AlbumInfo *photoToAlbum;

@end
