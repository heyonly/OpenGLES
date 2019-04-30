//
//  AGLKVertexAttribArrayBuffer.m
//  Tutorial03
//
//  Created by heyonly on 2019/4/29.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "AGLKVertexAttribArrayBuffer.h"
@interface AGLKVertexAttribArrayBuffer ()

@end

@implementation AGLKVertexAttribArrayBuffer
@synthesize name;
@synthesize bufferSizebytes;
@synthesize stride;

+ (void)drawPreparedArraysWithMode:(GLenum)mode startVertexIndex:(GLint)first numberOfVertices:(GLsizei)count {
    glDrawArrays(mode, first, count);
}

- (id)initWithAttribStride:(GLsizei)aStride numberOfVertices:(GLsizei)count bytes:(const GLvoid *)dataPtr usage:(GLenum)usage {
    if (self = [super init]) {
        stride = aStride;
        bufferSizebytes = stride * count;
        
        glGenBuffers(1, &name);
        glBindBuffer(GL_ARRAY_BUFFER,self.name);
        glBufferData(GL_ARRAY_BUFFER, bufferSizebytes, dataPtr, usage);
    }
    return self;
}

- (void)prepareToDrawWithAttrib:(GLuint)index numberOfCoordinates:(GLuint)count attribOffset:(GLsizeiptr)offset shouldEnable:(BOOL)shouldEnable {
    glBindBuffer(GL_ARRAY_BUFFER, self.name);
    
    if (shouldEnable) {
        glEnableVertexAttribArray(index);
    }
    
    glVertexAttribPointer(index, count, GL_FLOAT, GL_FALSE, self.stride, NULL + offset);
    
#ifdef DEBUG
    {
        GLenum error = glGetError();
        if (GL_NO_ERROR != error) {
            NSLog(@"GL Error : 0x%x",error);
        }
    }
#endif
}

- (void)drawArrayWithMode:(GLenum)mode startVertexIndex:(GLint)first numberOfVertices:(GLsizei)count {
    glDrawArrays(mode, first, count);
}

- (void)reinitWithAttribStride:(GLsizei)aStride numberOfVertices:(GLsizei)count bytes:(const GLvoid *)dataPtr {
    self.stride = aStride;
    self.bufferSizebytes = aStride * count;
    
    glBufferData(GL_ARRAY_BUFFER, bufferSizebytes, dataPtr, GL_DYNAMIC_DRAW);
}
@end
