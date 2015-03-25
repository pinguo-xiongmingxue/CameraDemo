//
//  AlbumViewModeClass.m
//  CameraDemo
//
//  Created by pinguo on 15/3/25.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "AlbumViewModeClass.h"
#import "AlbumHandler.h"

@implementation AlbumViewModeClass

- (void)fetchPhotosWithAlbum:(NSString *)album
{
    NSArray * arr = [[NSArray alloc] initWithArray:[AlbumHandler getPhotosWithAlbum:album]];
    self.returnBlock(arr);
}



@end
