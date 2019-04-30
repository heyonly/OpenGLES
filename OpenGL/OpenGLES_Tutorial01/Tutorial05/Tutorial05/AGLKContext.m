//
//  AGLKContext.m
//  Tutorial05
//
//  Created by heyonly on 2019/4/30.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "AGLKContext.h"

@implementation AGLKContext
@synthesize clearColor = _clearColor;

- (void)setClearColor:(GLKVector4)clearColorRGBA {
    _clearColor = clearColorRGBA;
    
    glClearColor(clearColorRGBA.r, clearColorRGBA.g, clearColorRGBA.b, clearColorRGBA.a);
}

- (GLKVector4)clearColor {
    return _clearColor;
}

- (void)clear:(GLbitfield)mask {
    glClear(mask);
}

- (void)disable:(GLenum)capability {
    glDisable(capability);
}

- (void)enable:(GLenum)capability {
    glEnable(capability);
}

- (void)setBlendSourceFunction:(GLenum)sfactor destinationFunction:(GLenum)dfactor {
    glBlendFunc(sfactor, dfactor);
}

@end
