//
//  ViewModelClass.h
//  CameraDemo
//
//  Created by pinguo on 15/3/25.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ViewModelClass : NSObject

@property (nonatomic, strong) ReturnValueBlock returnBlock;
@property (nonatomic, strong) ErrorCodeBlock errorBlock;
@property (nonatomic, strong) FailureBlock failureBlock;

// 传入交互的Block块
-(void) setBlockWithReturnBlock: (ReturnValueBlock) returnBlock
                 WithErrorBlock: (ErrorCodeBlock) errorBlock
               WithFailureBlock: (FailureBlock) failureBlock;


@end
