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

- (NSString *)photoDateString;

@end
