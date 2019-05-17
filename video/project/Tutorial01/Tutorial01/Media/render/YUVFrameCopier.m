//
//  YUVFrameCopier.m
//  Tutorial01
//
//  Created by heyonly on 2019/5/7.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "YUVFrameCopier.h"
NSString *const yuvVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 texcoord;
 uniform mat4 modelViewProjectionMatrix;
 varying vec2 v_texcoord;
 void main()
 {
     gl_Position = modelViewProjectionMatrix * position;
     v_texcoord = texcoord.xy;
 }
 );

NSString *const yuvFragmentShaderString = SHADER_STRING
(
 varying highp vec2 v_texcoord;
 uniform sampler2D inputImageTexture;
 uniform sampler2D s_texture_u;
 uniform sampler2D s_texture_v;
 
 void main()
 {
     highp float y = texture2D(inputImageTexture,v_texcoord).r;
     highp float u = texture2D(s_texture_u,v_texcoord).r - 0.5;
     highp float v = texture2D(s_texture_v,v_texcoord).r - 0.5;
     
     highp float r = y + 1.402 * v;
     highp float g = y - 0.344 * u - 0.714 * v;
     highp float b = y + 1.772 * u;
     gl_FragColor = vec4(r,g,b,1.0);
 }
 );


@interface YUVFrameCopier ()
{
    GLuint          _frameBuffer;
    GLuint          _outputTextureID;
    
    GLint           _uniformMatrix;
    GLint           _chromaBInputTextureUniform;
    GLint           _chromaRInputTextureUniform;
    
    GLuint          _inputTextures[3];
}
@end

@implementation YUVFrameCopier

- (BOOL)prepareRender:(NSInteger)frameWidth height:(NSInteger)frameHeight {

    if ([self buildProgram:yuvVertexShaderString fragmentShader:yuvFragmentShaderString]) {
        _chromaBInputTextureUniform = glGetUniformLocation(filterProgram, "s_texture_u");
        _chromaRInputTextureUniform = glGetUniformLocation(filterProgram, "s_texture_v");
        
        glUseProgram(filterProgram);
        glEnableVertexAttribArray(filterPositionAttribute);
        glEnableVertexAttribArray(filterTextureCoordinateAttribute);
        
        glGenFramebuffers(1, &_frameBuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
        
        glActiveTexture(GL_TEXTURE1);
        glGenTextures(1, &_outputTextureID);
        glBindTexture(GL_TEXTURE_2D, _outputTextureID);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)frameWidth, (int)frameHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
        
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _outputTextureID, 0);
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        if (status != GL_FRAMEBUFFER_COMPLETE) {
            NSLog(@"failed to make complete framebuffer object: %x",status);
        }
        
        glBindTexture(GL_TEXTURE_2D, 0);
        [self genInputTexture:(int)frameWidth height:(int)frameHeight];
        return  YES;
    }
    return NO;
}

- (void)genInputTexture:(int)frameWidth height:(int)frameHeight {
    glGenTextures(3, _inputTextures);
    for (int i = 0; i < 3; i++) {
        glBindTexture(GL_TEXTURE_2D, _inputTextures[i]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, frameWidth, frameHeight, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0);
    }
}

- (void)renderWithTexId:(VideoFrame *)videoFrame {
    int frameWidth = (int)[videoFrame width];
    int frameHeight = (int)[videoFrame height];
    
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glUseProgram(filterProgram);
    glViewport(0, 0, frameWidth, frameHeight);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self uploadTexture:videoFrame width:frameWidth height:frameHeight];
    
    static const GLfloat imageVertices[] = {
        -1.0f,-1.0f,
        1.0f,-1.0f,
        -1.0f,1.0f,
        1.0f,1.0f,
    };
    
    GLfloat noRotationTextureCoordinates[] = {
        0.0f,1.0f,
        1.0f,1.0f,
        0.0f,0.0f,
        1.0f,0.0f,
    };
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, imageVertices);
    glEnableVertexAttribArray(filterPositionAttribute);
    
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, noRotationTextureCoordinates);
    glEnableVertexAttribArray(filterTextureCoordinateAttribute);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _inputTextures[0]);
    glUniform1i(filterInputTextureUniform, 0);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _inputTextures[1]);
    glUniform1i(_chromaBInputTextureUniform, 1);
    
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, _inputTextures[2]);
    glUniform1i(_chromaRInputTextureUniform, 2);
    
    GLfloat modelViewProj[16];
    mat4f_LoadOrtho(-1.0f, 1.0f, -1.0f, 1.0f, -1.0f, 1.0f, modelViewProj);
    glUniformMatrix4fv(_uniformMatrix, 1, GL_FALSE, modelViewProj);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

- (void)uploadTexture:(VideoFrame *)videoFrame width:(int)frameWidth height:(int)frameHeight
{
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    const UInt8 *pixels[3] = {videoFrame.luma.bytes,videoFrame.chromaB.bytes,videoFrame.chromaB.bytes};
    
    const NSUInteger widths[3] = {frameWidth,frameWidth/2,frameWidth/2};
    const NSUInteger heights[3] = {frameHeight,frameHeight/2 ,frameHeight/2};
    for (int i = 0; i < 3; i++) {
        glBindTexture(GL_TEXTURE_2D, _inputTextures[i]);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, (int)widths[i], (int)heights[i], 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, pixels[i]);
    }
}

- (GLint)outputTextureID {
    return _outputTextureID;
}
@end
