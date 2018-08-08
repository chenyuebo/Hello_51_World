//
//  ReportOneSecond.m
//  Hello_51_World
//
//  Created by chenyuebo on 2018/1/16.
//  Copyright © 2018年 YacolMobile. All rights reserved.
//

#import "ReportOneSecond.h"

@implementation ReportOneSecond


-(NSString *) description
{
    return [NSString stringWithFormat:@"timeSecond=%04ld,sumResquest=%02ld,code200=%02ld,code400=%02ld,code400=%02ld,code403=%02ld,code500=%02ld,code502=%02ld",
          _timeSecond, _sumResquest, _code200Num, _code400Num, _code401Num, _code403Num, _code500Num, _code502Num];
}


@end
