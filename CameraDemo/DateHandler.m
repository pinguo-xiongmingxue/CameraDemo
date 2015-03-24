//
//  DateHandler.m
//  CameraDemo
//
//  Created by pinguo on 15/3/24.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "DateHandler.h"

@implementation DateHandler

+ (id)shareInstance
{
    static DateHandler * dh = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dh = [[self alloc] init];
    });
    return dh;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self photoDateFormat];
        
    }
    return self;
}

- (NSDateFormatter *)photoDateFormat
{
    if (!_photoDateFormatter) {
        _photoDateFormatter = [[NSDateFormatter alloc] init];
        [_photoDateFormatter setDateFormat:@"yyyyMMddHHmmssssss"];
        [_photoDateFormatter setLocale:[NSLocale currentLocale]];
    }
    return _photoDateFormatter;
}

- (NSString *)photoDateString
{
    return [_photoDateFormatter stringFromDate:[NSDate date]];
}


@end
