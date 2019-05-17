//
//  VideoFrame.h
//  Tutorial01
//
//  Created by heyonly on 2019/5/6.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "Frame.h"

NS_ASSUME_NONNULL_BEGIN

@interface VideoFrame : Frame
@property (nonatomic, assign) NSUInteger width;
@property (nonatomic, assign) NSUInteger height;
@property (nonatomic, assign) NSUInteger linesize;

@property (nonatomic, strong) NSData *luma;
@property (nonatomic, strong) NSData *chromaB;
@property (nonatomic, strong) NSData *chromaR;
@property (nonatomic, strong) id imageBuffer;
@end

NS_ASSUME_NONNULL_END
