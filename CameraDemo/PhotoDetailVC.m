//
//  PhotoDetailVC.m
//  CameraDemo
//
//  Created by pinguo on 15/4/2.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "PhotoDetailVC.h"
#import "CommonDefine.h"
#import "PhotoInfo.h"
#import "ImageCacheHandler.h"

@class ZoomScrollView;
@protocol ZoomScrollViewDelegate <NSObject>

- (void)didViewTapped:(ZoomScrollView *)zoomScrollView atIndex:(NSInteger)index;

@end


@interface ZoomScrollView : UIScrollView<UIScrollViewDelegate>

@property (nonatomic, assign) id<ZoomScrollViewDelegate> zoomViewDelegate;
@property (nonatomic, strong) UIImageView * imageView;

- (void)resetZoomedView;

@end

@implementation ZoomScrollView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        self.delegate = self;
        
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_imageView];
        
        _imageView.userInteractionEnabled = YES;
        
        [self setMinimumZoomScale:0.8];
        [self setMaximumZoomScale:2.];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTap:)];
        [tapGesture setNumberOfTapsRequired:1];
        [_imageView addGestureRecognizer:tapGesture];
    }
    return self;
}

- (void)handleTap:(UIGestureRecognizer *)gesture
{
    [self resetZoomedView];
    if ([_zoomViewDelegate respondsToSelector:@selector(didViewTapped:atIndex:)]) {
        [_zoomViewDelegate didViewTapped:self atIndex:0];
    }
}

- (void)resetZoomedView
{
    [UIView animateWithDuration:0.1 animations:^{
        self.zoomScale = 1;
    }];
    
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _imageView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    [scrollView setZoomScale:scale animated:YES];
}


@end





@interface PhotoDetailVC ()
{
  UIScrollView * _zoomViewContainerView;
}

@property (weak, nonatomic) IBOutlet UIScrollView *customScrollView;


@end

@implementation PhotoDetailVC

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _imageArray = [NSMutableArray new];
        self.albumTitle = AlbumTitle;
    }
    return self;
}

- (void)setImageArray:(NSMutableArray *)imageArray
{
    _imageArray = imageArray;
    CGFloat totalWidth = 0;
    CGFloat width = CGRectGetWidth(self.view.frame);
    CGFloat height = CGRectGetHeight(self.view.frame);
    for (int i = 0; i < _imageArray.count; i++) {
        ZoomScrollView * zoomScrollView = [[ZoomScrollView alloc] initWithFrame:CGRectMake(totalWidth, 0, width, height)];
        PhotoInfo * photoInfo = [self.imageArray objectAtIndex:i];
        UIImage * image = [[ImageCacheHandler shareInstance] diskImageForKey:photoInfo.name withPath:self.albumTitle];
        zoomScrollView.imageView.image = image;
        [self.customScrollView addSubview:zoomScrollView];
        totalWidth += width;
        
    }
    [self.customScrollView setContentSize:CGSizeMake(totalWidth, height)];
}

- (void)setIndex:(NSInteger)index
{
    _index = index;
    CGFloat width = CGRectGetWidth(self.view.frame);
    [self.customScrollView setContentOffset:CGPointMake(index * width, 0)];
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    
   
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
