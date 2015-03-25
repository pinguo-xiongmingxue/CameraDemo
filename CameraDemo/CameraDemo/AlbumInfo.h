//
//  AlbumInfo.h
//  CameraDemo
//
//  Created by pinguo on 15/3/25.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PhotoInfo;

@interface AlbumInfo : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet *ablumToPhoto;
@end

@interface AlbumInfo (CoreDataGeneratedAccessors)

- (void)addAblumToPhotoObject:(PhotoInfo *)value;
- (void)removeAblumToPhotoObject:(PhotoInfo *)value;
- (void)addAblumToPhoto:(NSSet *)values;
- (void)removeAblumToPhoto:(NSSet *)values;

@end
