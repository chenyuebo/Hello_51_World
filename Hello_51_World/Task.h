//
//  Task.h
//  Hello_51_World
//
//  Created by chenyuebo on 2018/1/12.
//  Copyright © 2018年 chenyuebo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Task : NSObject

// 任务在第多少秒启动
@property NSInteger timeSecond;

// 任务执行的渠道号，1-5
@property NSInteger channelId;

// 任务号，1-30000
@property NSInteger taskId;

// 任务返回code是否为200
@property BOOL isSuccess;

// 服务器statusCode
@property NSInteger statusCode;

// HTTP错误信息
@property NSString *errorMsg;

// 任务处理成功时服务器返回的处理时间
@property NSInteger timeMs;

@end
