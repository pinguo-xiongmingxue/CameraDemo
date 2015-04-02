//
//  AlbumCollectionViewCell.m
//  CameraDemo
//
//  Created by pinguo on 15/3/25.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "AlbumCollectionViewCell.h"
#import "ImageCacheHandler.h"
#import "PhotoInfo.h"
#import "PhotoHandler.h"

@implementation AlbumCollectionViewCell

- (void)setValueWithMode:(PhotoInfo *)photoInfo
{
    UIImage * image = [[ImageCacheHandler shareInstance] diskImageForKey:photoInfo.name withPath:photoInfo.address];
    self.photoImageView.image = image;
}

- (IBAction)deleteBtnClick:(id)sender
{
    if ([_delegate respondsToSelector:@selector(albumCollectionCellDelete:withIndexPath:)]) {
        [_delegate albumCollectionCellDelete:self withIndexPath:self.indexPath];
    }
}


@end
