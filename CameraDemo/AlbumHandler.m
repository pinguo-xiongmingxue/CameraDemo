//
//  AlbumHandler.m
//  CameraDemo
//
//  Created by pinguo on 15/3/25.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "AlbumHandler.h"
#import "AlbumInfo.h"
#import "CoreData+MagicalRecord.h"

@implementation AlbumHandler


+ (NSArray *)getPhotosWithAlbum:(NSString *)album
{
    AlbumInfo * albumInfo = [AlbumInfo MR_findFirstByAttribute:@"title" withValue:album];
    NSArray * arr = [[NSArray alloc] initWithArray:[albumInfo.ablumToPhoto allObjects]];
    
    
    return arr;
}

@end
