//
//  ImageCacheHandler.m
//  CameraDemo
//
//  Created by pinguo on 15/3/24.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "ImageCacheHandler.h"
#import <CommonCrypto/CommonDigest.h>


@interface ImageCacheHandler ()

@property (nonatomic, strong) NSString * diskCachePath;
@property (nonatomic, strong) dispatch_queue_t cacheQueue;

@end

@implementation ImageCacheHandler


+ (ImageCacheHandler *)shareInstance
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = self.new;
    });
    return instance;
}

- (id)init
{
    if (self = [super init]) {
        
        _cacheQueue = dispatch_queue_create("pg.image.cache", DISPATCH_QUEUE_SERIAL);
        NSString * fullNameSpace = @"CacheImage";
        _diskCachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathExtension:fullNameSpace];
        
        
    }
    return self;
}


- (NSString *)cacheFileNameForKey:(NSString *)key
{
    const char *str = [key UTF8String];
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    
    return filename;
}


- (NSString *)cachePathForKey:(NSString *)key inPath:(NSString *)path
{
    NSString * filename = [self cacheFileNameForKey:key];
    NSString * newFilename = [filename stringByAppendingPathExtension:@"png"];
    return [path stringByAppendingPathComponent:newFilename];
}



- (NSString *)defaultCachePathForKey:(NSString *)key withPath:(NSString *)path
{
    return [self cachePathForKey:key inPath:path];
}

- (void)storeImage:(UIImage *)image forKey:(NSString *)key appendPath:(NSString *)path
{
    [self storeImage:image imageData:nil forKey:key toDisk:YES appendPath:path];
}

- (void)storeImage:(UIImage *)image imageData:(NSData *)imageData forKey:(NSString *)key toDisk:(BOOL)toDisk appendPath:(NSString *)path
{
    if (!image || !key) {
        return;
    }
    if (toDisk) {
        dispatch_async(self.cacheQueue, ^{
            NSData * data = imageData;
            if (!data) {
                if (image) {
                   // data = UIImageJPEGRepresentation(image, (CGFloat)0.8);
                    data = UIImagePNGRepresentation(image);
                }
            }
            if (data) {
                
                NSFileManager * fileManager = NSFileManager.new;
                NSString * newPath = [_diskCachePath stringByAppendingPathComponent:path];
                if (![fileManager fileExistsAtPath:newPath]) {
                    [fileManager createDirectoryAtPath:newPath withIntermediateDirectories:YES attributes:nil error:NULL];
                }
                [fileManager createFileAtPath:[self defaultCachePathForKey:key withPath:newPath] contents:data attributes:nil];
                
            }
        });
    }
    
}

- (NSString *)imagePathWithKey:(NSString *)key withPath:(NSString *)path
{
    NSString * newPath = [_diskCachePath stringByAppendingPathComponent:path];
    NSString * defaultPath = [self defaultCachePathForKey:key withPath:newPath];
    return defaultPath;
}

- (UIImage *)diskImageForKey:(NSString *)key withPath:(NSString *)path
{
    NSString * defaultPath = [self imagePathWithKey:key withPath:path];
    
    UIImage * image = [UIImage imageWithContentsOfFile:defaultPath];
    if (image) {
        return image;
    }else{
        return nil;
    }
}

- (BOOL)deleteSingleImageForKey:(NSString *)key withPath:(NSString *)path
{
    NSString * imagePath = [self imagePathWithKey:key withPath:path];
    NSFileManager * fileManager = NSFileManager.new;
    if ([fileManager fileExistsAtPath:imagePath]) {
        
        return [fileManager removeItemAtPath:imagePath error:nil];
        
    }
    return NO;
}

- (BOOL)deleteImagesForPath:(NSString *)path
{
    NSFileManager * fileManager = NSFileManager.new;
    NSString * filePath = [_diskCachePath stringByAppendingPathComponent:path];
    if ([fileManager fileExistsAtPath:filePath]) {
        return [fileManager removeItemAtPath:filePath error:nil];
    }
    return NO;
}

- (void)clearDiskCache
{
    dispatch_async(self.cacheQueue, ^{
        NSFileManager * fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:self.diskCachePath error:nil];
        [fileManager createDirectoryAtPath:self.diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
    });
}



@end
