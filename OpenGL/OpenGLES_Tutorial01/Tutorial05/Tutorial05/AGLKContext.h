//
//  AGLKContext.h
//  Tutorial05
//
//  Created by heyonly on 2019/4/30.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AGLKContext : EAGLContext

@property (nonatomic, assign) GLKVector4 clearColor;

- (void)clear:(GLbitfield)mask;
- (void)enable:(GLenum)capability;
- (void)disable:(GLenum)capability;
- (void)setBlendSourceFunction:(GLenum)sfactor destinationFunction:(GLenum)dfactor;
@end

NS_ASSUME_NONNULL_END
