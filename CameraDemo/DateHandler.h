//
//  DateHandler.h
//  CameraDemo
//
//  Created by pinguo on 15/3/24.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DateHandler : NSObject

@property (nonatomic, strong) NSDateFormatter * photoDateFormatter;

+ (id)shareInstance;

/**
 *  取得当前的时间字符串，用于生成照片名
 *
 *  @return 当前的时间字符串
 */
- (NSString *)photoDateString;

@end
