//
//  ReportOneSecond.h
//  Hello_51_World
//
//  Created by chenyuebo on 2018/1/16.
//  Copyright © 2018年 YacolMobile. All rights reserved.
//

#import <Foundation/Foundation.h>

// 一秒钟内请求结果统计
@interface ReportOneSecond : NSObject


// 请求的时间
@property NSInteger timeSecond;
// 一秒内请求的总数
@property NSInteger sumResquest;
// statusCode=200 的请求数
@property NSInteger code200Num;
@property NSInteger code400Num;
@property NSInteger code401Num;
@property NSInteger code403Num;
@property NSInteger code500Num;
@property NSInteger code502Num;



@end
