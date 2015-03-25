//
//  ViewModelClass.m
//  CameraDemo
//
//  Created by pinguo on 15/3/25.
//  Copyright (c) 2015年 pinguo. All rights reserved.
//

#import "ViewModelClass.h"


@implementation ViewModelClass


#pragma mark - 接收穿过来的block
-(void) setBlockWithReturnBlock: (ReturnValueBlock) returnBlock
                 WithErrorBlock: (ErrorCodeBlock) errorBlock
               WithFailureBlock: (FailureBlock) failureBlock
{
    _returnBlock = returnBlock;
    _errorBlock = errorBlock;
    _failureBlock = failureBlock;
}


@end
