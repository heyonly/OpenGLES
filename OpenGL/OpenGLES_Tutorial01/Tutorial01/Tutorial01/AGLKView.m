//
//  AGLKView.m
//  Tutorial01
//
//  Created by heyonly on 2019/4/29.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "AGLKView.h"

@implementation AGLKView
@synthesize context;
@synthesize delgate;
@synthesize drawableDepthFormat;

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        
        eaglLayer.drawableProperties = @{
                                         kEAGLDrawablePropertyRetainedBacking:[NSNumber numberWithBool:NO],
                                         kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8
                                         };
    }
    return self;
}

- (void)setContext:(EAGLContext *)aContext {
    if (context != aContext) {
        [EAGLContext setCurrentContext:context];
        
        if (0 != defaultFrameBuffer) {
            glDeleteFramebuffers(1, &defaultFrameBuffer);
            defaultFrameBuffer = 0;
        }
        
        if (0 != colorRenderBuffer) {
            glDeleteRenderbuffers(1, &colorRenderBuffer);
            colorRenderBuffer = 0;
        }
        
        if (0 != depthRenderBuffer) {
            glDeleteRenderbuffers(1, &depthRenderBuffer);
            depthRenderBuffer = 0;
        }
        
        context = aContext;
        
        if (nil != context) {
            [EAGLContext setCurrentContext:context];
            glGenFramebuffers(1, &defaultFrameBuffer);
            glBindFramebuffer(GL_FRAMEBUFFER, defaultFrameBuffer);
            
            glGenRenderbuffers(1, &colorRenderBuffer);
            glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBuffer);
            
            glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderBuffer);
            
            [self layoutSubviews];
        }
    }
}

- (EAGLContext *)context {
    return context;
}

- (void)display {
    [EAGLContext setCurrentContext:self.context];
    
    glViewport(0, 0, (GLint)self.drawableWidth, (GLint)self.drawableHeight);
    
    [self drawRect:[self bounds]];
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)drawRect:(CGRect)rect {
    if (delgate) {
        [self.delgate glkView:self drawInRect:[self bounds]];
    }
}


- (void)layoutSubviews {
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    
    [EAGLContext setCurrentContext:self.context];
    
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer];
    
    if (0 != depthRenderBuffer) {
        glDeleteRenderbuffers(1, &depthRenderBuffer);
        depthRenderBuffer = 0;
    }
    
    GLint currentDrawableWidth = (GLint)self.drawableWidth;
    GLint curremtDrawableHeight = (GLint)self.drawableHeight;
    
    if (self.drawableDepthFormat != AGLKViewDrawableDepthFormatNone && 0 < currentDrawableWidth && 0 < curremtDrawableHeight) {
        glGenRenderbuffers(1, &depthRenderBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, depthRenderBuffer);
        
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, currentDrawableWidth, curremtDrawableHeight);
        
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderBuffer);
    }
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete frame buffer object %x",status);
    }
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBuffer);
}

- (NSInteger)drawableWidth {
    GLint backingWidth;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    
    return (NSInteger)backingWidth;
}

- (NSInteger)drawableHeight {
    GLint backingHeight;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    return (NSInteger)backingHeight;
}

@end
