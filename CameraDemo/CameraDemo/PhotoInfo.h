//
//  PhotoInfo.h
//  CameraDemo
//
//  Created by pinguo on 15/3/25.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AlbumInfo;

@interface PhotoInfo : NSManagedObject

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) AlbumInfo *photoToAlbum;

@end
