//
//  YUVFrameFastCopier.m
//  Tutorial01
//
//  Created by heyonly on 2019/5/7.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "YUVFrameFastCopier.h"

GLfloat kColorConversion601FullRangeDefault[] = {
    1.0,    1.0,    1.0,
    0.0,    -0.343, 1.765,
    1.4,    -0.711, 0.0,
};

GLfloat kColorConversion601FullRange[] = {
    1.0,    1.0,    1.0,
    0.0,    -0.39465, 2.03211,
    1.13983,-0.58060, 0.0,
};

NSString *const yuvFaterVertexShaderString = SHADER_STRING
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

NSString *const yuvFasterFragmentShaderString = SHADER_STRING
(
 varying highp vec2 v_texcoord;
 precision mdiump float;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D SamplerUV;
 uniform mat3 colorConversionMatrix;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     
     yuv.x = texture2D(inputImageTexture,v_texcoord).r;
     yuv.yz = texture2D(SamplerUV,v_texcoord).ra - vec2(0.5,0.5);
     
     rgb = colorConversionMatrix * yuv;
     gl_FragColor = vec4(rgb,1);
 }
 );

@interface YUVFrameFastCopier ()
{
    GLuint                      _framebuffer;
    GLuint                      _outputTextureID;
    
    GLint                       _uniformMatrix;
    GLint                       _chromaInputTextureUniform;
    GLint                       _colorConversionMatrixUniform;
    
    CVOpenGLESTextureRef        _lumaTexture;
    CVOpenGLESTextureRef        _chromaTexture;
    CVOpenGLESTextureCacheRef   _videoTextureCache;
    
    const GLfloat               *_preferredConversion;
    CVPixelBufferPoolRef        _pixelBufferPool;
}
@end

@implementation YUVFrameFastCopier
- (BOOL)prepareRender:(NSInteger)frameWidth height:(NSInteger)frameHeight {
    if ([self buildProgram:yuvFaterVertexShaderString fragmentShader:yuvFasterFragmentShaderString]) {
        _chromaInputTextureUniform = glGetUniformLocation(filterProgram, "SamplerUV");
        
        _colorConversionMatrixUniform = glGetUniformLocation(filterProgram, "colorConversionMatrix");
        
        glUseProgram(filterProgram);
        glEnableVertexAttribArray(filterPositionAttribute);
        glEnableVertexAttribArray(filterTextureCoordinateAttribute);
        
        glGenFramebuffers(1, &_framebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
        
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
            NSLog(@"failed to make complete framebuffer object %x",status);
        }
        
        glBindTexture(GL_TEXTURE_2D, 0);
        if (!_videoTextureCache) {
            EAGLContext *context = [EAGLContext currentContext];
            CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, context, NULL, &_videoTextureCache);
            if (err != noErr) {
                NSLog(@"Error at CVOpenGLESTextureCacheCreate %d",err);
                return NO;
            }
        }
        _preferredConversion = kColorConversion601FullRangeDefault;
    }
    return YES;
}

- (GLint)outputTextureID {
    return _outputTextureID;
}
@end
