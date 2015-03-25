//
//  AlbumViewController.h
//  CameraDemo
//
//  Created by pinguo on 15/3/24.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AlbumViewController : UIViewController<UICollectionViewDataSource,UICollectionViewDelegate>


@property (weak, nonatomic) IBOutlet UICollectionView *albumCollectionView;

@end
