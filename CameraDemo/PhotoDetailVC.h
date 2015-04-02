//
//  PhotoDetailVC.h
//  CameraDemo
//
//  Created by pinguo on 15/4/2.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoDetailVC : UIViewController

@property (nonatomic, strong) NSString * albumTitle;
@property (nonatomic, strong) NSMutableArray * imageArray;
@property (nonatomic, assign) NSInteger index;

@end
