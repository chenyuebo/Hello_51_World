//
//  Task.m
//  Hello_51_World
//
//  Created by chenyuebo on 2018/1/12.
//  Copyright © 2018年 chenyuebo. All rights reserved.
//

#import "Task.h"

@implementation Task

-(NSString *) description
{
    return [NSString stringWithFormat:@"timeSecond=%03ld,channelId=%ld,taskId=%05ld,isSuccess=%@,statusCode=%ld,timeMs=%04ld,errorMsg=%@",
            _timeSecond, _channelId, _taskId, _isSuccess ? @"YES" : @"NO ", _statusCode, _timeMs, _errorMsg ? _errorMsg : @""];
}

@end
