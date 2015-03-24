//
//  PhotoHandler.m
//  CameraDemo
//
//  Created by pinguo on 15/3/24.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "PhotoHandler.h"
#import "CoreData+MagicalRecord.h"
#import "ImageCacheHandler.h"
#import "CommonDefine.h"

@implementation PhotoHandler

+ (PhotoInfo *)saveInfo:(NSDictionary *)infoDict withAlbum:(NSString *)ablumTitle
{
    PhotoInfo * photoInfo = [PhotoInfo MR_createEntity];
    photoInfo.name = [infoDict objectForKey:PhotoNameKey];
    photoInfo.address = ablumTitle;
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    
    return photoInfo;
}


@end
