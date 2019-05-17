//
//  VideoOutputView.h
//  Tutorial01
//
//  Created by heyonly on 2019/5/6.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoFrame.h"
NS_ASSUME_NONNULL_BEGIN

@interface VideoOutputView : UIView
- (id) initWithFrame:(CGRect)frame textureWidth:(NSInteger)textureWidth textureHeight:(NSInteger)textureHeight usingHWCodec: (BOOL) usingHWCodec;
- (id) initWithFrame:(CGRect)frame textureWidth:(NSInteger)textureWidth textureHeight:(NSInteger)textureHeight usingHWCodec: (BOOL) usingHWCodec shareGroup:(nullable EAGLSharegroup *)shareGroup;

- (void)presentVideoFrame:(VideoFrame *)frame;
@end

NS_ASSUME_NONNULL_END
