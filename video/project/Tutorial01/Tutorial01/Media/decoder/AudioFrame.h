//
//  AudioFrame.h
//  Tutorial01
//
//  Created by heyonly on 2019/5/6.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "Frame.h"

NS_ASSUME_NONNULL_BEGIN

@interface AudioFrame : Frame
@property (nonatomic, strong) NSData *samples;
@end

NS_ASSUME_NONNULL_END
