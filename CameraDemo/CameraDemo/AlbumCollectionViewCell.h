//
//  AlbumCollectionViewCell.h
//  CameraDemo
//
//  Created by pinguo on 15/3/25.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AlbumCollectionViewCell;
@protocol AlbumCollectionCellDelegate <NSObject>

- (void)albumCollectionCellDelete:(AlbumCollectionViewCell *)cell withIndexPath:(NSIndexPath *)indexPath;

@end

@class PhotoInfo;
@interface AlbumCollectionViewCell : UICollectionViewCell

@property (assign, nonatomic) id<AlbumCollectionCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;
@property (nonatomic, strong) NSIndexPath * indexPath;   //当前的index

- (void)setValueWithMode:(PhotoInfo *)photoInfo;

@end
