//
//  PhotoHandler.m
//  CameraDemo
//
//  Created by pinguo on 15/3/24.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "PhotoHandler.h"
#import "CoreData+MagicalRecord.h"
#import "ImageCacheHandler.h"
#import "CommonDefine.h"
#import "AlbumInfo.h"

@implementation PhotoHandler

+ (PhotoInfo *)saveInfo:(NSDictionary *)infoDict withAlbum:(NSString *)ablumTitle
{
    //如果没有这个相册，创建相册
    AlbumInfo * album = nil;
    album = [AlbumInfo MR_findFirstByAttribute:@"title" withValue:ablumTitle];
    if (!album) {
        album = [AlbumInfo MR_createEntity];
        album.title = ablumTitle;
        
    }
    PhotoInfo * photoInfo = [PhotoInfo MR_createEntity];
    photoInfo.name = [infoDict objectForKey:PhotoNameKey];
    photoInfo.address = ablumTitle;
    photoInfo.createTime = [NSDate date];
    [album addAblumToPhotoObject:photoInfo];
    
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    
    return photoInfo;
}


+ (NSArray *)getPhotoInfosWithAlbum:(NSString *)albumTitle
{
    
    AlbumInfo * albumInfo = [AlbumInfo MR_findFirstByAttribute:@"title" withValue:albumTitle];
    NSArray * arr = [[NSArray alloc] initWithArray:[albumInfo.ablumToPhoto allObjects]];
    
    NSArray * sortedArray = [arr sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        PhotoInfo * left = obj1;
        PhotoInfo * right = obj2;
        if ([left.createTime compare:right.createTime] == NSOrderedAscending) {
            return NSOrderedDescending;
        }else if ([left.createTime compare:right.createTime] == NSOrderedDescending){
            return NSOrderedAscending;
        }else{
            return NSOrderedSame;
        }
    }];
    
    
    return sortedArray;
    
}


+ (PhotoInfo *)getPhotoInfoWithAlbum:(NSString *)albumTitle
{
    NSArray * arr = [self getPhotoInfosWithAlbum:albumTitle];
    if ([arr count] != 0) {
        return [arr objectAtIndex:0];
    }
    
    return nil;
}

+ (BOOL)deletePhotoInfo:(NSString *)photoName  withAlbumTitle:(NSString *)title
{
    BOOL ret = NO;
    PhotoInfo * photo = [PhotoInfo MR_findFirstByAttribute:@"name" withValue:photoName];
    [[ImageCacheHandler shareInstance] deleteSingleImageForKey:photoName withPath:title];
    if (photo) {
        ret = [photo MR_deleteEntity];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        return ret;
    }
    
    return ret;
}


@end
