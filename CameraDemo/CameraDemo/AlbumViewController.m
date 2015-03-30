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


@interface AlbumViewController ()

@property (nonatomic, strong) NSArray * photosArray;

@end



@implementation AlbumViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    AlbumViewModeClass * albumViewMode = [[AlbumViewModeClass alloc] init];
    [albumViewMode setBlockWithReturnBlock:^(id returnValue) {
        _photosArray = returnValue;
      //  NSLog(@"photoArray number: %d",_photosArray.count);
        [self.albumCollectionView reloadData];
    } WithErrorBlock:^(id errorCode) {
        
    } WithFailureBlock:^{
        
    }];
    
    [albumViewMode fetchPhotosWithAlbum:AlbumTitle];
    
    
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.photosArray count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * collectionCellID = @"AlbumCell";
    AlbumCollectionViewCell * collectionCell = (AlbumCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:collectionCellID forIndexPath:indexPath];
    
    [collectionCell setValueWithMode:self.photosArray[indexPath.row]];
   
    
    return collectionCell;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  
    
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
