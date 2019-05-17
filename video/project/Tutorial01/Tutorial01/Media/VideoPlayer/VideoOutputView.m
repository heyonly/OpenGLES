//
//  VideoOutputView.m
//  Tutorial01
//
//  Created by heyonly on 2019/5/6.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "VideoOutputView.h"
#import "ContrastEnhancerFilter.h"
#import "DirectPassRenderer.h"
#import "YUVFrameCopier.h"
#import "YUVFrameFastCopier.h"

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface VideoOutputView ()
{
    EAGLContext *               _context;
    GLuint                      _displayFramebuffer;
    GLuint                      _renderbuffer;
    GLint                       _backingWidth;
    GLint                       _backingHeight;
    BOOL                        _stopping;
    
    YUVFrameCopier              *_videoFrameCopier;
    BaseEffectFilter            *_filter;
    DirectPassRenderer          *_directPassRender;
    
}

@property (nonatomic, strong) NSOperationQueue *renderOperationQueue;
@property (nonatomic, assign) BOOL shouldEnableOpenGL;
@property (atomic,  assign)   BOOL readyToRender;
@property (nonatomic, strong) NSLock *shouldEnableOpenGLLock;

@end


@implementation VideoOutputView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (id) initWithFrame:(CGRect)frame textureWidth:(NSInteger)textureWidth textureHeight:(NSInteger)textureHeight usingHWCodec: (BOOL) usingHWCodec {
    return [self initWithFrame:frame textureWidth:textureWidth textureHeight:textureHeight usingHWCodec:usingHWCodec shareGroup:nil];
}
- (id) initWithFrame:(CGRect)frame textureWidth:(NSInteger)textureWidth textureHeight:(NSInteger)textureHeight usingHWCodec: (BOOL) usingHWCodec shareGroup:(nullable EAGLSharegroup *)shareGroup {
    if (self = [super initWithFrame:frame]) {
        _shouldEnableOpenGLLock = [NSLock new];
        [_shouldEnableOpenGLLock lock];
        _shouldEnableOpenGL = ([UIApplication sharedApplication].applicationState == UIApplicationStateActive);
        [_shouldEnableOpenGLLock unlock];
        
        //app 进入后台，OpenGL ES 就不能进渲染操作
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking:@(false),kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8};
        //如果使用的是GCD 的线程模型，那么会导致DispatchQueue 里面的绘制操作越积累越多，并且不能清空，而使用NSOperationQueue，则可以检测到Queue里面的Operation 超多定义的阈值时，清空醉酒的Operation，只保留罪行的绘制操作，这样才能完成正常的播放。
        _renderOperationQueue = [[NSOperationQueue alloc] init];
        _renderOperationQueue.maxConcurrentOperationCount = 1;
        _renderOperationQueue.name = @"com.uusafe.video_player.viderRenderQueue";
        
        //在 ARC 下，当编译器自动将代码中的block从栈拷贝到堆时，block 会强引用和持有self，而 self 恰好也强引用和持有了 block，就造成了传说中的循环引用。
        //此时 __weak 就出场了，在变量声明时用 __weak修饰符修饰变量 self，让 block 不强引用 self，从而破除循环。

        __weak VideoOutputView *weakSelf = self;
        [_renderOperationQueue addOperationWithBlock:^{
            __strong VideoOutputView *strongSelf = weakSelf;
            if (shareGroup) {
                strongSelf->_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:shareGroup];
            }else {
                strongSelf->_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
            }
            
            if (!strongSelf->_context || ![EAGLContext setCurrentContext:strongSelf->_context]) {
                NSLog(@"setup EAGLContext Failed ...");
            }
            
            if (![strongSelf createDisplayFramebuffer]) {
                NSLog(@"crate Display Framebuffer failed..");
            }
            
            [strongSelf createCopierInstance:usingHWCodec];
            
            if (![strongSelf->_videoFrameCopier prepareRender:textureWidth height:textureHeight]) {
                NSLog(@"_videoFrameFastCopier prepareRender Failed..");
            }
            
            strongSelf->_filter = [self createImageProcessFilterInstance];
            if (![strongSelf->_filter prepareRender:textureWidth height:textureHeight]) {
                NSLog(@"_contrastEnhancerFilter prepareRender failed...");
            }
            
            [strongSelf->_filter setInputTexture:[strongSelf->_videoFrameCopier outputTextureID]];
            
            strongSelf->_directPassRender = [[DirectPassRenderer alloc] init];
            
            if (![strongSelf->_directPassRender prepareRender:textureWidth height:textureHeight]) {
                NSLog(@"_directPassRenderer prepareRender failed...");
            }
            
            [strongSelf->_directPassRender setInputTexture:[strongSelf->_filter outputTextureID]];
            strongSelf.readyToRender = YES;
        }];
    }
    return self;
}

- (BaseEffectFilter *)createImageProcessFilterInstance {
    return [[ContrastEnhancerFilter alloc] init];
}

- (void)createCopierInstance:(BOOL)usingHWCodec {
    if (usingHWCodec) {
        _videoFrameCopier = [[YUVFrameFastCopier alloc] init];
    }else {
        _videoFrameCopier = [[YUVFrameCopier alloc] init];
    }
}

- (BOOL)createDisplayFramebuffer {

    glGenFramebuffers(1, &_displayFramebuffer);
    glGenRenderbuffers(1, &_renderbuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _displayFramebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
//    dispatch_sync(dispatch_get_main_queue(), ^{
        //为renderbuffer 分配存储空间
        [self->_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
//    });
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderbuffer);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        return false;
    }
    GLenum glError = glGetError();
    if (GL_NO_ERROR != glError) {
        NSLog(@"Failed to setup GL %x",glError);
        return false;
    }
    return true;
}

static int count = 0;

static const NSInteger kMaxOperationQueueCount = 3;

- (void)presentVideoFrame:(VideoFrame *)frame {
    if (_stopping) {
        NSLog(@"Prevent A Invalid Render >>>>");
        return;
    }
    @synchronized (self.renderOperationQueue) {
        NSInteger operationCount = _renderOperationQueue.operationCount;
        if (operationCount > kMaxOperationQueueCount) {
            [_renderOperationQueue.operations enumerateObjectsUsingBlock:^(__kindof NSOperation * _Nonnull operation, NSUInteger idx, BOOL * _Nonnull stop) {
                if (idx < operationCount - kMaxOperationQueueCount) {
                    [operation cancel];
                }else {
                    *stop = YES;
                }
            }];
        }
        __weak VideoOutputView *weakSelf = self;
        [_renderOperationQueue addOperationWithBlock:^{
            if (!weakSelf) {
                return ;
            }
            __strong VideoOutputView *strongSelf = weakSelf;
            [strongSelf.shouldEnableOpenGLLock lock];
            if (!strongSelf.readyToRender || !strongSelf.shouldEnableOpenGL) {
                glFinish();
                [strongSelf.shouldEnableOpenGLLock unlock];
                return;
            }
            [strongSelf.shouldEnableOpenGLLock unlock];
            count++;
            int frameWidth = (int)[frame width];
            int frameHeight = (int)[frame height];
            [EAGLContext setCurrentContext:strongSelf->_context];
            [strongSelf->_videoFrameCopier renderWithTexId:frame];
            [strongSelf->_filter renderWithWidth:frameWidth height:frameHeight position:frame.position];
            glBindFramebuffer(GL_FRAMEBUFFER, strongSelf->_displayFramebuffer);
            [strongSelf->_directPassRender renderWithWidth:strongSelf->_backingWidth height:strongSelf->_backingHeight position:frame.position];
            glBindRenderbuffer(GL_RENDERBUFFER, strongSelf->_renderbuffer);
            [strongSelf->_context presentRenderbuffer:GL_RENDERBUFFER];
        }];
    }
    
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    [self.shouldEnableOpenGLLock lock];
    self.shouldEnableOpenGL = NO;
    [self.shouldEnableOpenGLLock unlock];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self.shouldEnableOpenGLLock lock];
    self.shouldEnableOpenGL = YES;
    [self.shouldEnableOpenGLLock unlock];
}


@end
