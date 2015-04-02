//
//  AlbumHandler.m
//  CameraDemo
//
//  Created by pinguo on 15/3/25.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "AlbumHandler.h"
#import "AlbumInfo.h"
#import "PhotoInfo.h"
#import "CoreData+MagicalRecord.h"

@implementation AlbumHandler

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

@end
