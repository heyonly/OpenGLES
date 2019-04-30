//
//  ViewController.m
//  Tutorial01
//
//  Created by heyonly on 2019/4/29.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "ViewController.h"
#import "AGLKView.h"
typedef struct {
    GLKVector3 positionCoords;
}SceneVertex;

static const SceneVertex vertices[] =
{
    {{-0.5f,-0.5f,0.0}},
    
    {{0.5f,-0.5f,0.0}},
    {{-0.5f,0.5f,0.0}}
};

@interface ViewController ()<AGLKViewDelegate>

@end
static const NSInteger kAGLKDefaultFramesPerSecond = 30;



@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    AGLKView *view = (AGLKView *)self.view;
    
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    view.delgate = self;
    [EAGLContext setCurrentContext:view.context];
    
    self.baseEffect = [[GLKBaseEffect alloc] init];
    
    self.baseEffect.useConstantColor = GL_TRUE;
    self.baseEffect.constantColor = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glGenBuffers(1, &vertexBufferID);
    
    glBindBuffer(GL_ARRAY_BUFFER, vertexBufferID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
}

- (void)glkView:(AGLKView *)view drawInRect:(CGRect)rect {
    [self.baseEffect prepareToDraw];
    
    glClear(GL_COLOR_BUFFER_BIT);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(SceneVertex), NULL);
    
    glDrawArrays(GL_TRIANGLES, 0, 3);
}

@end
