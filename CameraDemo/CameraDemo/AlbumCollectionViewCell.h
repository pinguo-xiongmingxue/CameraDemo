//
//  AlbumCollectionViewCell.h
//  CameraDemo
//
//  Created by pinguo on 15/3/25.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoInfo.h"

@interface AlbumCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;

- (void)setValueWithMode:(PhotoInfo *)photoInfo;

@end
