//
//  AGLKContext.m
//  Tutorial03
//
//  Created by heyonly on 2019/4/29.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "AGLKContext.h"

@implementation AGLKContext
@synthesize clearColor;

- (void)setClearColor:(GLKVector4)clearColorRGBA {
    clearColor = clearColorRGBA;
    glClearColor(clearColorRGBA.r, clearColorRGBA.g, clearColorRGBA.b, clearColorRGBA.a);
}


- (GLKVector4)clearColor {
    return clearColor;
}

- (void)clear:(GLbitfield)mask {
    glClear(mask);
}

- (void)enable:(GLenum)capability {
    glEnable(capability);
}

- (void)disable:(GLenum)capability {
    glDisable(capability);
}

- (void)setBlendSourceFunction:(GLenum)sfactor destinationFunction:(GLenum)dfactor {
    glBlendFunc(sfactor, dfactor);
}


@end
