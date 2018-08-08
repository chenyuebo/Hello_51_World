//
//  TaskManager.h
//  Hello_51_World
//
//  Created by chenyuebo on 2018/1/9.
//  Copyright © 2018年 chenyuebo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TaskManager : NSObject

@property NSString *token;

// 成功的任务个数
@property NSInteger finishedTaskCount;
// 总的任务个数
@property NSInteger taskNum;
// 总分
@property NSInteger sumScore;
// 包含5和数组，每个数组记录对应渠道的请求结果
@property NSArray *channelResult;

-(void) setUrlWithC1:(NSString *) c1 C2:(NSString *) c2 C3:(NSString *) c3 C4:(NSString *) c4 C5:(NSString *) c5;

-(void) initTaskList;

-(void) startTimer;

-(void) makeReport;

-(void) setMaxRate:(NSInteger) maxRate;

-(void) setServerOpenTime:(NSInteger) seconds;

@end
