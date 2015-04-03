//
//  AlbumViewController.m
//  CameraDemo
//
//  Created by pinguo on 15/3/24.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "AlbumViewController.h"
#import "AlbumCollectionViewCell.h"
#import "AlbumViewModeClass.h"
#import "PhotoDetailVC.h"


@interface AlbumViewController ()<AlbumCollectionCellDelegate>

@property (nonatomic, strong) NSMutableArray * photosArray;

@end



@implementation AlbumViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    AlbumViewModeClass * albumViewMode = [[AlbumViewModeClass alloc] init];
    [albumViewMode setBlockWithReturnBlock:^(id returnValue) {
        _photosArray = returnValue;
    
        [self.albumCollectionView reloadData];
    } WithErrorBlock:^(id errorCode) {
        
    } WithFailureBlock:^{
        
    }];
    
    [albumViewMode fetchPhotosWithAlbum:AlbumTitle];
    
    
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.photosArray count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * collectionCellID = @"AlbumCell";
    AlbumCollectionViewCell * collectionCell = (AlbumCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:collectionCellID forIndexPath:indexPath];
    collectionCell.indexPath = indexPath;
    collectionCell.delegate = self;
    [collectionCell setValueWithMode:self.photosArray[indexPath.row]];
   
    return collectionCell;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    AlbumViewModeClass * albumViewMode = [[AlbumViewModeClass alloc] init];
    [albumViewMode photoDetailWithViewController:self withImageArray:_photosArray atIndex:indexPath.row];
}

#pragma mark - AlbumCollectionCellDelegate

- (void)albumCollectionCellDelete:(AlbumCollectionViewCell *)cell withIndexPath:(NSIndexPath *)indexPath
{
//   AlbumCollectionViewCell * ce = (AlbumCollectionViewCell *)[self.albumCollectionView cellForItemAtIndexPath:indexPath];
    NSIndexPath * indexPath1 = [self.albumCollectionView indexPathForCell:cell];
    
    
     AlbumViewModeClass * albumViewMode = [[AlbumViewModeClass alloc] init];
    
    [albumViewMode deletePhotoInfo:[self.photosArray objectAtIndex:indexPath1.row]];
    [self.photosArray removeObjectAtIndex:indexPath1.row];
    [self.albumCollectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath1]];
    [self.albumCollectionView reloadData];
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
