//
//  BuriedPoint.h
//  Tutorial01
//
//  Created by heyonly on 2019/5/6.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BuriedPoint : NSObject
@property (nonatomic, assign) long long beginOpen; // 开始试图去打开一个直播流的绝对时间
@property (nonatomic, assign) float successOpen; // 成功打开流花费时间
@property (nonatomic, assign) float firstScreenTimeMills; // 首屏时间
@property (nonatomic, assign) float failOpen; // 流打开失败花费时间
@property (nonatomic, assign) float failOpenType; // 流打开失败类型
@property (nonatomic, assign) float retryTimes; // 打开流重试次数
@property (nonatomic, assign) float duration; // 拉流时长
@property (nonatomic, strong) NSMutableArray *bufferStatusRecords; // 拉流状态
@end

NS_ASSUME_NONNULL_END
