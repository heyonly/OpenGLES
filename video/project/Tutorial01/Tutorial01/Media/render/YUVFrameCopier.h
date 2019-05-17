//
//  YUVFrameCopier.h
//  Tutorial01
//
//  Created by heyonly on 2019/5/7.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "BaseEffectFilter.h"
#import "VideoFrame.h"
NS_ASSUME_NONNULL_BEGIN

@interface YUVFrameCopier : BaseEffectFilter
- (void) renderWithTexId:(VideoFrame*) videoFrame;
@end

NS_ASSUME_NONNULL_END
