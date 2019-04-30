//
//  AGLKContext.h
//  Tutorial03
//
//  Created by heyonly on 2019/4/29.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface AGLKContext : EAGLContext
{
    GLKVector4 clearColor;
}

@property (nonatomic, assign, readwrite) GLKVector4 clearColor;

- (void)clear:(GLbitfield)mask;

- (void)enable:(GLenum)capability;
- (void)disable:(GLenum)capability;
- (void)setBlendSourceFunction:(GLenum)sfactor destinationFunction:(GLenum)dfactor;
@end

NS_ASSUME_NONNULL_END
