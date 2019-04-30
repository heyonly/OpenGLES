//
//  AGLKVertexAttribArrayBuffer.h
//  Tutorial03
//
//  Created by heyonly on 2019/4/29.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
NS_ASSUME_NONNULL_BEGIN
typedef enum {
    AGLKVertexAttribPosition = GLKVertexAttribPosition,
    AGLKVertexAttribNormal = GLKVertexAttribNormal,
    AGLKVertexAttribColor = GLKVertexAttribColor,
    AGLKVertexAttribTexCoord0 = GLKVertexAttribTexCoord0,
    AGLKVertexAttribTexCoord1 = GLKVertexAttribTexCoord1,
} AGLKVertexAttrib;
@interface AGLKVertexAttribArrayBuffer : NSObject
{
    GLsizei                 stride;
    GLsizeiptr              bufferSizeBytes;
    GLuint                  name;
}

@property (nonatomic, assign) GLuint name;
@property (nonatomic, assign) GLsizeiptr bufferSizebytes;
@property (nonatomic, assign) GLsizei stride;

+ (void)drawPreparedArraysWithMode:(GLenum)mode startVertexIndex:(GLint)first numberOfVertices:(GLsizei)count;

- (id)initWithAttribStride:(GLsizei)aStride numberOfVertices:(GLsizei)count bytes:(const GLvoid *)dataPtr usage:(GLenum)usage;

- (void)prepareToDrawWithAttrib:(GLuint)index numberOfCoordinates:(GLuint)count attribOffset:(GLsizeiptr)offset shouldEnable:(BOOL)shouldEnable;

- (void)drawArrayWithMode:(GLenum)mode startVertexIndex:(GLint)first numberOfVertices:(GLsizei)count;

- (void)reinitWithAttribStride:(GLsizei)stride numberOfVertices:(GLsizei)count bytes:(const GLvoid *)dataPtr;

@end

NS_ASSUME_NONNULL_END
