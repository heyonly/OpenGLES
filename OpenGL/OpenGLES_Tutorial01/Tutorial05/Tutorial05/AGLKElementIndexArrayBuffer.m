//
//  AGLKElementIndexArrayBuffer.m
//  Tutorial05
//
//  Created by heyonly on 2019/4/30.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "AGLKElementIndexArrayBuffer.h"

@interface AGLKElementIndexArrayBuffer ()

@end

@implementation AGLKElementIndexArrayBuffer

+ (void)drawPreparedArraysWithMode:(GLenum)mode startVertexIndex:(GLint)first numberOfVertices:(GLsizei)count {
    
}

- (id)initWithAttribStride:(GLsizei)aStride
          numberOfVertices:(GLsizei)count
                     bytes:(const GLvoid *)dataPtr
                     usage:(GLenum)usage
{
    if (self = [super init]) {
        _stride = aStride;
        _bufferSizeBytes = _stride * count;
        
        glGenBuffers(1, &_name);
        glBindBuffer(GL_ARRAY_BUFFER, self.name);
        glBufferData(GL_ARRAY_BUFFER, _bufferSizeBytes, dataPtr, usage);
    }
    return self;
}

- (void)prepareToDrawWithAttrib:(GLuint)index
            numberOfCoordinates:(GLint)count
                   attribOffset:(GLsizeiptr)offset
                   shouldEnable:(BOOL)shouldEnable
{
    glBindBuffer(GL_ARRAY_BUFFER, self.name);
    if (shouldEnable) {
        glEnableVertexAttribArray(index);
    }
    glVertexAttribPointer(index, count, GL_FLOAT, GL_FALSE, self.stride, NULL + offset);
    GLenum error = glGetError();
    
    if (GL_NO_ERROR != error) {
        NSLog(@"GL Error 0x%x",error);
    }
}

- (void)drawArrayWithMode:(GLenum)mode
         startVertexIndex:(GLint)first
         numberOfVertices:(GLsizei)count
{
    glDrawArrays(mode, first, count);
}

- (void)reinitWithAttribStride:(GLsizei)aStride
              numberOfVertices:(GLsizei)count
                         bytes:(const GLvoid *)dataPtr
{
    self.stride = aStride;
    self.bufferSizeBytes = aStride * count;
    
    glBindBuffer(GL_ARRAY_BUFFER, self.name);
    
    glBufferData(GL_ARRAY_BUFFER, _bufferSizeBytes, dataPtr, GL_DYNAMIC_DRAW);
}
@end
