//
//  main.m
//  Hello_51_World
//
//  Created by chenyuebo on 2018/1/4.
//  Copyright © 2018年 chenyuebo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TaskManager.h"


void printConfig(NSDictionary *config){
    
    NSString *token = [config objectForKey:@"token"];
    NSString *c1 = [config objectForKey:@"c1"];
    NSString *c2 = [config objectForKey:@"c2"];
    NSString *c3 = [config objectForKey:@"c3"];
    NSString *c4 = [config objectForKey:@"c4"];
    NSString *c5 = [config objectForKey:@"c5"];
    NSString *rate = [config objectForKey:@"rate"]; // 每秒钟发送请求数
    NSString *serverOpenTime = [config objectForKey:@"serverOpenTime"]; // 渠道开放试运营时间，单位秒
    NSString *startDateTime = [config objectForKey:@"startDateTime"]; // 比赛开始时间
    
    NSLog(@"参数系统令牌   token=%@", token);
    NSLog(@"C1渠道地址     c1=%@", c1);
    NSLog(@"C2渠道地址     c2=%@", c2);
    NSLog(@"C3渠道地址     c3=%@", c3);
    NSLog(@"C4渠道地址     c4=%@", c4);
    NSLog(@"C5渠道地址     c5=%@", c5);
    NSLog(@"默认请求频率   rate=%@", rate);
    NSLog(@"系统试运营时间 serverOpenTime=%@", serverOpenTime);
    NSLog(@"比赛开始时间   startDateTime=%@", startDateTime);
}


void waitToStart(NSString *startDateTime){
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    while(YES){
        NSDate *currentDate = [NSDate date];
        NSLog(@"比赛开始时间：%@，当前时间：%@", startDateTime, [dateFormatter stringFromDate:currentDate]);
        NSDate *startDate = [dateFormatter dateFromString:startDateTime];
        NSComparisonResult comparisonResult = [currentDate compare:startDate];
        if(comparisonResult == NSOrderedDescending){
            break;
        }
//        [NSThread sleepUntilDate:startDate];
        [NSThread sleepForTimeInterval:1];
    }
}


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSLog(@"程序开始运行");
        
        // 从文件读取token
        NSLog(@"从文件读取配置");
        NSString *configFileName = @"/Users/cyb/workspace_xcode/Hello_51_World/Hello_51_World/config.json"; // 测试使用绝对路径
//        NSString *configFileName = @"config.json"; // 打包使用相对路径
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if([fileManager fileExistsAtPath:configFileName] == NO){
            NSLog(@"配置文件%@未找到", configFileName);
            return 0;
        }
        NSString *json = [NSString stringWithContentsOfFile:configFileName encoding:NSUTF8StringEncoding error:nil];
        NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *map = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        printConfig(map);
        
        NSString *token = [map objectForKey:@"token"];
        NSString *c1 = [map objectForKey:@"c1"];
        NSString *c2 = [map objectForKey:@"c2"];
        NSString *c3 = [map objectForKey:@"c3"];
        NSString *c4 = [map objectForKey:@"c4"];
        NSString *c5 = [map objectForKey:@"c5"];
        NSString *rate = [map objectForKey:@"rate"]; // 每秒钟发送请求数
        NSString *serverOpenTime = [map objectForKey:@"serverOpenTime"]; // 渠道开放试运营时间，单位秒
        NSString *startDateTime = [map objectForKey:@"startDateTime"]; // 比赛开始时间
        
        // 确认配置是否正确
        BOOL isConfigRight = NO;
        char buffer[1000];
        NSLog(@"请确认配置是否正确（输入'YES' or 'NO'）：");
        scanf("%s", buffer);
        NSString *input = [NSString stringWithUTF8String:buffer];
        input = [input uppercaseString];
        if([input isEqualToString:@"YES"]){
            isConfigRight = YES;
        }
        
        if(isConfigRight){
            
            waitToStart(startDateTime); // 等待
            printConfig(map);
            
            TaskManager *taskManager = [[TaskManager alloc] init];
            [taskManager setToken:token]; // 设置队伍使用的token
            [taskManager setUrlWithC1:c1 C2:c2 C3:c3 C4:c4 C5:c5];// 设置服务器地址
            [taskManager setMaxRate:[rate integerValue]]; // 设置默认每秒请求数
            [taskManager setServerOpenTime:[serverOpenTime integerValue]]; //
            [taskManager setTaskNum:30000]; // 设置总任务个数
            [taskManager initTaskList];  // 初始化任务列表
            [taskManager startTimer]; // 开启定时器
            [taskManager makeReport]; // 任务处理完毕，报告结果
            
            NSLog(@"5个渠道总分=%ld", [taskManager sumScore]);
        }else{
            NSLog(@"从配置文件加载Token和URL失败");
        }
        
        NSLog(@"程序运行结束");
        
    }
    return 0;
}
