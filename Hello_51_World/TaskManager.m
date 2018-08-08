//
//  TaskManager.m
//  Hello_51_World
//
//  Created by chenyuebo on 2018/1/9.
//  Copyright © 2018年 chenyuebo. All rights reserved.
//

#import "TaskManager.h"
#import "Task.h"
#import "ReportOneSecond.h"

@implementation TaskManager
{
    NSInteger second; // 程序运行的时间，单位秒
    NSTimer *timer;
    NSRunLoop *runLoop;
    NSMutableArray *taskArray; // 未完成的任务列表
    NSArray *channelUrls;
    
    NSOperationQueue *operationQueue;
    NSURLSessionConfiguration * sessionConfiguration;
    NSURLSession *urlSession;
    
    // 默认的每秒最大请求数
    NSInteger defaultMaxRate;
    // 存储c1-c5，5个渠道每秒最大请求次数
    NSMutableArray *channelLimitPerSecond;
    // 下一次查询服务器是否繁忙倒计时
    NSMutableArray *channelTTL;
    // 渠道开放试运营时间
    NSInteger serverOpenTime;
    // 渠道频率设置历史
    NSArray *channelRateHistory;
}

-(instancetype) init{
    self = [super init];
    if(self){
        NSInteger rate = 20;
        channelLimitPerSecond = [[NSMutableArray alloc] initWithObjects:@(rate), @(rate), @(rate), @(rate), @(rate), nil];
        //
        channelTTL = [[NSMutableArray alloc] initWithObjects:@520, @380, @0, @0, @0, nil];
//        channelTTL = [[NSMutableArray alloc] initWithObjects:@0, @0, @0, @300, @520, nil]; // 正式比赛配置
//        channelTTL = [[NSMutableArray alloc] initWithObjects:@0, @0, @0, @60, @60, nil]; // 设置程序运行后，渠道多少秒后启用
        // 保存5个渠道的请求结果
        NSMutableDictionary *c1Dict = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *c2Dict = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *c3Dict = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *c4Dict = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *c5Dict = [[NSMutableDictionary alloc] init];
        _channelResult = [[NSArray alloc] initWithObjects:c1Dict, c2Dict, c3Dict, c4Dict, c5Dict, nil];
        // 保存5个渠道的频率设置历史
        NSMutableDictionary *c1RateHistry = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *c2RateHistry = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *c3RateHistry = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *c4RateHistry = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *c5RateHistry = [[NSMutableDictionary alloc] init];
        channelRateHistory = [[NSArray alloc] initWithObjects:c1RateHistry, c2RateHistry, c3RateHistry, c4RateHistry, c5RateHistry, nil];
    }
    return self;
}

// 设置服务器接口地址，参数host只包含ip和端口，
-(void) setUrlWithC1:(NSString *)c1 C2:(NSString *)c2 C3:(NSString *)c3 C4:(NSString *)c4 C5:(NSString *)c5
{
    channelUrls = [[NSArray alloc] initWithObjects:c1, c2, c3, c4, c5, nil];
}

// 设置默认每秒钟请求次数
-(void) setMaxRate:(NSInteger) maxRate
{
    defaultMaxRate = maxRate;
    for(int i = 0; i < [channelLimitPerSecond count]; i++){
        [channelLimitPerSecond replaceObjectAtIndex:i withObject:@(defaultMaxRate)];
    }
}

// 设置系统试运营时间
-(void) setServerOpenTime:(NSInteger) seconds
{
    serverOpenTime = seconds;
}

// 初始化任务数组，将30000个请求加入数组
-(void) initTaskList
{
    NSLog(@"初始化任务列表开始");
    taskArray = [[NSMutableArray alloc] init];
    for(int i = 1; i <= _taskNum; i++){
        Task *task = [[Task alloc] init];
        task.taskId = i;
        [taskArray addObject:task];
    }
    NSLog(@"初始化任务列表结束");
}

// 取下一个待处理的任务
-(Task *)getNextTask
{
    if([taskArray count] > 0){
        Task * task = [taskArray objectAtIndex:0];
        [taskArray removeObjectAtIndex:0];
        return task;
    }
    return nil;
}

// 制定策略，修改channelLimitPerSecond中每秒限流值
-(void) computePolicy{
    
    int timeLength = 7;
    NSMutableArray *recentReport = [self makeReportRecent:second timeLength:timeLength]; // 统计前7秒数据，接口5s+网络延时2s
    NSLog(@"recentReport=%@", recentReport);

    for(int channelId = 1; channelId <= 5; channelId++){
        long ttl = [channelTTL[channelId - 1] integerValue];
        NSLog(@"channelId=%d,ttl=%ld", channelId, ttl);
        if(ttl > 0){ // 渠道倒计时没有结束，渠道限流状态不变
            [channelTTL replaceObjectAtIndex:(channelId - 1) withObject:@(ttl - 1)];
            [channelLimitPerSecond replaceObjectAtIndex:(channelId - 1) withObject:@(0)];
            continue;
        }
        NSMutableArray *channelReport = recentReport[channelId - 1];
        NSMutableDictionary *channelRate = channelRateHistory[channelId - 1];
        int sumRate = 0;
        int sumResponse = 0; // 7s内收到的回复总数
        int sumServerBusy = 0; // 7s内收到的服务器繁忙总数
        for(int i = 0; i < [channelReport count]; i++){ // 根据每秒发出请求的返回值进行调控
            ReportOneSecond *report = channelReport[i];
            sumRate += [[channelRate objectForKey:@(report.timeSecond)] integerValue];
            sumResponse += report.sumResquest;
            sumServerBusy += report.code500Num;
            if(report.sumResquest > 0){
                if(report.code500Num > 0){ // 前7s数据中只要出现一次服务器繁忙，就限流，切换为查询状态
                    [channelLimitPerSecond replaceObjectAtIndex:(channelId - 1) withObject:@(0)];
                    [channelTTL replaceObjectAtIndex:(channelId - 1) withObject:@4];
                    break;
                }
            }
        }
        // 根据前几秒统计数据之和进行调控
        if(sumResponse == 0){
            if(second > timeLength){
                [channelLimitPerSecond replaceObjectAtIndex:(channelId - 1) withObject:@(1)];
            }
        }else if(sumResponse > 0){
            if(sumServerBusy == 0){
                [channelLimitPerSecond replaceObjectAtIndex:(channelId - 1) withObject:@(defaultMaxRate)];
            }
        }
    }
    
    // 打印调控后的频率
    NSMutableArray *rateArray = channelLimitPerSecond;
    NSLog(@"Rate channel_1_rate=%@,channel_2_rate=%@,channel_3_rate=%@,channel_4_rate=%@,channel_5_rate=%@"
          , rateArray[0], rateArray[1], rateArray[2], rateArray[3], rateArray[4]);
}

// 开启定时器，开启RunLoop
-(void) startTimer
{
    NSLog(@"定时器开始");
    second = 0;
    timer = [NSTimer timerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        // 记录运行时间
        second++;
        NSLog(@"运行时间(s):%ld", second);
        // 渠道限流调控
        [self computePolicy];
        
        for(int channelId = 1; channelId <= 5; channelId++){
            long channelMax = [channelLimitPerSecond[channelId - 1] integerValue];
            [channelRateHistory[channelId - 1] setObject:@(channelMax) forKey:@(second)]; // 记录调控后的渠道请求频率
            for(int i = 0; i < channelMax; i++){
                Task *task = [self getNextTask];
                if(task){
                    task.timeSecond = second;
                    task.channelId = channelId;
                    [self handleTask:task];
                }
            }
        }
    }];
    
    runLoop = [NSRunLoop currentRunLoop];
    [runLoop addTimer:timer forMode: NSDefaultRunLoopMode];
    // 当任务没有全部完成且总用时没有超过（渠道试运行时间+30秒）时，程序继续
    while(![self isAllTaskFinish] && second <= (serverOpenTime + 30)){
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    [timer fire];
}

// 获取网络配置
-(NSURLSession *)getURLSession{
    
    if(!operationQueue){
        operationQueue = [NSOperationQueue mainQueue];
    }
    if(!sessionConfiguration){
        sessionConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration]; // 返回一个不适用永久持存cookie、证书、缓存的配置，最佳优化数据传输。
        sessionConfiguration.timeoutIntervalForRequest = 15;
//        sessionConfiguration.connectionProxyDictionary = @{
//            (id)kCFNetworkProxiesHTTPEnable:@YES,
//            (id)kCFNetworkProxiesHTTPProxy:@"127.0.0.1",
//            (id)kCFNetworkProxiesHTTPPort:@8888
//        };
    }
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:nil delegateQueue:operationQueue];
    return session;
}

// 进行网络请求
-(void) handleTask: (Task *) task
{
    NSURLSession *session = [self getURLSession];
    NSURL *url = [self getURLWithChannelId:task.channelId taskId:task.taskId];
    NSURLSessionTask *sessionTask = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        //TODO 数据记录，记录请求的时间second，记录服务器状态和返回值
        Task *result = task;
        if(error){
            result.errorMsg = [error localizedDescription];
            result.isSuccess = NO;
        }else{
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            result.statusCode = statusCode;
            
            if(result.statusCode == 200){
                result.timeMs = [responseStr integerValue];
                result.isSuccess = YES;
            }else{
                result.errorMsg = responseStr;
                result.isSuccess = NO;
            }
            if(result.statusCode == 200 || result.statusCode == 400){
                _finishedTaskCount++;
            }
        }
        NSLog(@"http result %@", result);
        [self saveResult:result]; // 按渠道保存接口返回结果
        [self computeSumScoreWithChannelId:result.channelId statusCode:result.statusCode];
        if(result.statusCode != 200 && result.statusCode != 400){ // 失败的请求构建新的任务添加到任务列表
            Task *newTask = [[Task alloc] init];
            newTask.taskId = task.taskId;
            [taskArray addObject:newTask];
        }
    }];
    [sessionTask resume];
}

// 分渠道，分请求开始的时间存储请求结果
-(void) saveResult:(Task *)result
{
    NSMutableDictionary *channelMap = _channelResult[result.channelId - 1];
    NSMutableArray *array = [channelMap objectForKey:@(result.timeSecond)];
    if(!array){
        array = [[NSMutableArray alloc] init];
        [channelMap setObject:array forKey:@(result.timeSecond)];
    }
    [array addObject:result];
}

// 计算总得分
-(void) computeSumScoreWithChannelId:(NSInteger) channelId statusCode:(NSInteger) statusCode{
    if(statusCode == 200){
        _sumScore += 7 + channelId;
//        switch (channelId) {
//            case 1:
//                _sumScore += 8;
//                break;
//            case 2:
//                _sumScore += 9;
//                break;
//            case 3:
//                _sumScore += 10;
//                break;
//            case 4:
//                _sumScore += 11;
//                break;
//            case 5:
//                _sumScore += 12;
//                break;
//        }
    }else if(statusCode == 400){
        _sumScore -= 20;
    }else if(statusCode == 401){
        _sumScore -= 5;
    }else if(statusCode == 403){
        _sumScore -= 10;
    }else if(statusCode == 500){
        _sumScore -= 5;
    }
}

// 根据渠道编号和reqNo拼接请求的URL
-(NSURL *) getURLWithChannelId:(NSInteger)channelId taskId:(NSInteger)taskId
{
    NSString *urlStr = [[NSString alloc] initWithFormat:@"%@?reqNo=%ld&token=%@", channelUrls[channelId - 1], taskId, _token];
    return [NSURL URLWithString:urlStr];
}

// 判断是否认为全部完成
-(BOOL) isAllTaskFinish{
    return _finishedTaskCount == _taskNum;
}

// 返回指定时间前几秒的统计
-(NSMutableArray *) makeReportRecent:(NSInteger) timeSecond timeLength:(NSInteger) timeLength
{
    NSMutableArray *allChannelReportAarray = [[NSMutableArray alloc] init]; // 5个渠道的统计数据
    for(int channelId = 1; channelId <= 5; channelId++){
        NSMutableArray *channelReportArray = [[NSMutableArray alloc] init]; // 单渠道进5s统计数据
        [allChannelReportAarray addObject:channelReportArray];
        
        NSDictionary *channelResultDict = _channelResult[channelId - 1];
        for(int s = 1; s <= timeLength; s++){
            NSMutableArray *oneSecondResultArray = [channelResultDict objectForKey:@(timeSecond - s)];
            ReportOneSecond *reportOneSecond = [[ReportOneSecond alloc] init];
            [channelReportArray addObject:reportOneSecond];
            reportOneSecond.timeSecond = timeSecond - s;
            
            if(!oneSecondResultArray){
                continue;
            }
            
            for(int i = 0; i < [oneSecondResultArray count]; i++){
                Task *result = oneSecondResultArray[i];
                reportOneSecond.sumResquest++;
                switch (result.statusCode) {
                    case 200: reportOneSecond.code200Num++; break;
                    case 400: reportOneSecond.code400Num++; break;
                    case 401: reportOneSecond.code401Num++; break;
                    case 403: reportOneSecond.code403Num++; break;
                    case 500: reportOneSecond.code500Num++; break;
                    case 502: reportOneSecond.code502Num++; break;
                }
            }
        }
        
    }
    return allChannelReportAarray;
}

// 统计结果
-(void) makeReport
{
    long allChannelSpendTimeSum = 0;
    for(int channelId = 1; channelId <= 5; channelId++){
        NSMutableDictionary *dictionary = _channelResult[channelId - 1];
        NSLog(@"渠道 c%d 报告------------------------------------------", channelId);
        int channalSumRequest = 0;
        int code200Sum = 0; // statusCode为200的数量
        int code400Sum = 0;
        int code401Sum = 0;
        int code403Sum = 0;
        int code500Sum = 0;
        int code502Sum = 0;
        int codeOtherSum = 0;
        long spendTimeSum = 0;
        for(NSNumber *key in dictionary){
            NSMutableArray *array = [dictionary objectForKey:key];
            for(int i = 0; i < [array count]; i++){
                Task *result = array[i];
                channalSumRequest++;
                switch (result.statusCode) {
                    case 200:
                        code200Sum++;
                        spendTimeSum += result.timeMs;
                        break;
                    case 400:
                        code400Sum++;
                        break;
                    case 401:
                        code401Sum++;
                        break;
                    case 403:
                        code403Sum++;
                        break;
                    case 500:
                        code500Sum++;
                        break;
                    case 502:
                        code502Sum++;
                        break;
                    default:
                        codeOtherSum++;
                        break;
                }
            }

        }
        allChannelSpendTimeSum += spendTimeSum;
        NSLog(@"总请求次数: %d", channalSumRequest);
        NSLog(@"HTTP 响应状态 200 总数: %d", code200Sum);
        NSLog(@"HTTP 响应状态 400 总数: %d", code400Sum);
        NSLog(@"HTTP 响应状态 401 总数: %d", code401Sum);
        NSLog(@"HTTP 响应状态 403 总数: %d", code403Sum);
        NSLog(@"HTTP 响应状态 500 总数: %d", code500Sum);
        NSLog(@"HTTP 响应状态 502 总数: %d", code502Sum);
        NSLog(@"HTTP 响应状态 其他 总数: %d", codeOtherSum);
        if(channalSumRequest != 0){
            NSLog(@"请求成功率: %.2f%%", 100.0 * code200Sum / channalSumRequest);
        }
        if(code200Sum != 0){
            NSLog(@"渠道平均处理时间(ms): %ld", spendTimeSum / code200Sum);
        }
    }
    NSLog(@"-----------------------------------------------------");
    NSLog(@"5个渠道总平均处理时间(ms): %ld", allChannelSpendTimeSum / _taskNum);
}

@end
